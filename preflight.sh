#!/usr/bin/env bash
# preflight.sh: check (and, with --warm, pre-download) everything the "Hello, Check-in" workshop needs.
#
#   ./preflight.sh          checks only, one line per tool, prints the fix command for anything missing
#   ./preflight.sh --warm   also does the heavy one-time work at home: cargo fetch, cargo build-sbf
#                           (downloads Solana platform-tools, about 415 MB), cargo test
#
# Works on macOS, Linux and Ubuntu under WSL. It never installs anything, never changes your Solana config,
# never prints key material and never waits for input.

set -u

warm=0
for arg in "$@"; do
  case "$arg" in
    --warm) warm=1 ;;
    -h|--help)
      sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "unknown option: $arg (try --help)"
      exit 2
      ;;
  esac
done

repo_dir="$(cd "$(dirname "$0")" && pwd)"
fails=0
warns=0

ok()   { printf '✅ %-16s %s\n' "$1" "$2"; }
bad()  { printf '❌ %-16s %s\n    fix: %s\n' "$1" "$2" "$3"; fails=$((fails + 1)); }
warn() { printf '⚠️  %-16s %s\n    fix: %s\n' "$1" "$2" "$3"; warns=$((warns + 1)); }
has()  { command -v "$1" >/dev/null 2>&1; }

# Run a command with a time limit and no stdin (perl is on every macOS and Ubuntu).
bounded() {
  local seconds="$1"
  shift
  perl -e 'alarm shift; exec @ARGV' "$seconds" "$@" </dev/null
}

# ---------------------------------------------------------------- operating system
os="$(uname -s)"
arch="$(uname -m)"
is_wsl=0
case "$os" in
  Darwin)
    case "$arch" in
      arm64) os_label="macOS, Apple Silicon" ;;
      *)     os_label="macOS, Intel ($arch)" ;;
    esac
    ;;
  Linux)
    if [ -r /proc/version ] && grep -qi microsoft /proc/version; then
      is_wsl=1
      os_label="Linux under WSL ($arch)"
    else
      os_label="Linux ($arch)"
    fi
    ;;
  *) os_label="$os ($arch), not supported: use macOS, Linux, or Ubuntu under WSL on Windows" ;;
esac
intel_mac=0
[ "$os" = "Darwin" ] && [ "$arch" != "arm64" ] && intel_mac=1

echo "Hello, Check-in preflight: $os_label"
echo

if [ "$is_wsl" = 1 ]; then
  case "$repo_dir" in
    /mnt/*) warn "repo location" "$repo_dir is on the Windows drive (slow builds)" \
                 "clone it inside Ubuntu instead: cd ~ && git clone <this repo>" ;;
    *)      ok "repo location" "$repo_dir (inside the Linux filesystem)" ;;
  esac
fi

# ---------------------------------------------------------------- C toolchain (the Rust linker needs it)
if has cc; then
  ok "C compiler" "$(cc --version 2>/dev/null | sed -n 1p)"
else
  case "$os" in
    Darwin) bad "C compiler" "cc not found" "xcode-select --install" ;;
    *)      bad "C compiler" "cc not found" "sudo apt-get install -y build-essential pkg-config libudev-dev" ;;
  esac
fi

# ---------------------------------------------------------------- Rust
rustup_fix="curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
if has rustup; then
  ok "rustup" "$(rustup --version 2>/dev/null | sed -n 1p)"
else
  bad "rustup" "not found" "$rustup_fix"
fi
if has cargo; then
  ok "cargo" "$(cargo --version 2>/dev/null)"
else
  bad "cargo" "not found" "$rustup_fix   (then open a new shell)"
fi

# ---------------------------------------------------------------- Solana CLI with SBPF support
# shellcheck disable=SC2016 # printed literally, for the user to run

solana_fix='sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)"   then add ~/.local/share/solana/install/active_release/bin to PATH'
if has solana; then
  ok "solana" "$(solana --version 2>/dev/null)"
else
  bad "solana" "not found" "$solana_fix"
fi
platform_tools=""
if has cargo && sbf_version="$(cargo build-sbf --version 2>/dev/null)"; then
  platform_tools="$(printf '%s\n' "$sbf_version" | sed -n 's/^platform-tools \(v[0-9.]*\).*/\1/p')"
  ok "cargo build-sbf" "$(printf '%s' "$sbf_version" | tr '\n' ' ')"
else
  bad "cargo build-sbf" "not found (it ships with the Solana CLI)" "$solana_fix"
fi
if [ -n "$platform_tools" ]; then
  tools_dir="$HOME/.cache/solana/$platform_tools/platform-tools"
  if [ -d "$tools_dir" ]; then
    ok "platform-tools" "$platform_tools downloaded ($tools_dir)"
  else
    warn "platform-tools" "$platform_tools not downloaded yet (about 415 MB, 1.3 GB on disk)" "./preflight.sh --warm   (at home, not on venue Wi-Fi)"
  fi
fi

# ---------------------------------------------------------------- Node (npx skills, the client)
if has node; then
  node_version="$(node --version 2>/dev/null)"
  node_major="$(printf '%s' "$node_version" | sed 's/^v\([0-9]*\).*/\1/')"
  if [ -n "$node_major" ] && [ "$node_major" -ge 20 ] 2>/dev/null; then
    ok "node" "$node_version (>= 20)"
  else
    bad "node" "$node_version is older than 20" "install Node 20 or newer: https://nodejs.org (or fnm / nvm)"
  fi
else
  bad "node" "not found (needed for npx skills and the client)" "install Node 20 or newer: https://nodejs.org (or fnm / nvm)"
fi

# ---------------------------------------------------------------- Symposium (cargo agents)
if [ "$intel_mac" = 1 ]; then
  symposium_fix="cargo install symposium   (Intel Mac: there is no prebuilt binary, so it compiles; slow)"
elif has cargo-binstall; then
  symposium_fix="cargo binstall symposium"
else
  symposium_fix="cargo install cargo-binstall && cargo binstall symposium"
fi
if has cargo-agents; then
  ok "cargo-agents" "$(cargo-agents --version 2>/dev/null)"
  if [ -f "$HOME/.symposium/config.toml" ]; then
    ok "symposium init" "$HOME/.symposium/config.toml exists"
  else
    warn "symposium init" "cargo agents init has not run" "cargo agents init --add-agent <your agent> --hook-scope project"
  fi
else
  bad "cargo-agents" "not found (Symposium)" "$symposium_fix"
fi

# ---------------------------------------------------------------- an agent CLI (any one)
agents_found=""
for agent in claude codex copilot goose gemini; do
  has "$agent" && agents_found="$agents_found $agent"
done
if [ -n "$agents_found" ]; then
  ok "agent CLI" "found:$agents_found"
else
  bad "agent CLI" "none of claude, codex, copilot, goose, gemini on PATH" "install any one, e.g. Claude Code: https://claude.com/claude-code"
fi

# ---------------------------------------------------------------- devnet balance (warn only)
if has solana; then
  balance="$(bounded 20 solana balance -u devnet 2>&1 | sed -n 1p)"
  case "$balance" in
    *" SOL")
      amount="${balance%% SOL}"
      if awk -v a="$amount" 'BEGIN { exit !(a >= 0.05) }'; then
        ok "devnet SOL" "$balance (default keypair)"
      else
        warn "devnet SOL" "$balance; 0.05 SOL covers one deploy" "solana airdrop 1 -u devnet   (or https://faucet.solana.com), at home: the faucet limits per IP"
      fi
      ;;
    *"No default signer"*|*"No such file"*|*"not found"*|*"Keypair"*|*"keypair"*)
      warn "devnet SOL" "no default keypair" "solana-keygen new --no-bip39-passphrase   (creates ~/.config/solana/id.json)"
      ;;
    *)
      warn "devnet SOL" "could not read the balance (offline or RPC busy)" "solana balance -u devnet"
      ;;
  esac
fi

# ---------------------------------------------------------------- --warm: the heavy one-time work
if [ "$warm" = 1 ]; then
  echo
  echo "--warm: one-time downloads and builds in $repo_dir"
  if [ ! -f "$repo_dir/Cargo.toml" ]; then
    bad "warm" "no Cargo.toml here (this checkout is step-0)" "git checkout main && ./preflight.sh --warm && git checkout step-0"
  elif ! has cargo; then
    bad "warm" "cargo is missing" "$rustup_fix"
  else
    # A local target dir: Mollusk loads target/deploy/hello_checkin.so relative to the repo, which breaks
    # if your cargo config points target-dir somewhere shared.
    export CARGO_TARGET_DIR="$repo_dir/target"
    cd "$repo_dir" || exit 1
    for step in "cargo fetch" "cargo build-sbf" "cargo test"; do
      echo
      echo "\$ $step"
      start=$SECONDS
      # shellcheck disable=SC2086
      if $step </dev/null; then
        ok "$step" "done in $((SECONDS - start)) s"
      else
        bad "$step" "failed after $((SECONDS - start)) s (output above)" "fix the first error above, then run ./preflight.sh --warm again"
        break
      fi
    done
  fi
fi

echo
if [ "$fails" -eq 0 ]; then
  echo "Ready: 0 missing, $warns warning(s)."
  [ "$warm" = 0 ] && echo "Next, at home: ./preflight.sh --warm"
  exit 0
fi
echo "Not ready: $fails missing, $warns warning(s). Run each fix above, then ./preflight.sh again."
exit 1
