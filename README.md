# Hello, Check-in

**AI the Rust way, on Solana**: a 20–30 minute hands-on workshop by Solana Developer Thailand.
เวิร์กช็อปลงมือทำ 20–30 นาที โดย Solana Developer Thailand

One small Solana program (Pinocchio) with one rule: a check-in is accepted only until a deadline.
Every step is a git tag. If you fall behind: `git checkout step-N`.

[ภาษาไทย](#ภาษาไทย) · [English](#english)

## ภาษาไทย

เราจะเขียนโปรแกรม Solana ตัวเล็ก ๆ หนึ่งตัวด้วย Pinocchio มีกฎข้อเดียว คือเช็กอินได้จนถึงเวลา deadline เท่านั้น
โค้ดเขียนโดย agent ของคุณเอง (Claude Code, Codex, Copilot, Goose, Gemini หรืออื่น ๆ) โดยใช้ skill ที่ติดตั้งในขั้นที่ 2
แต่ละขั้นเป็น git tag ถ้าตามไม่ทันให้ `git checkout step-N` (ถ้ามีไฟล์ที่แก้ไว้ ให้ `git stash` ก่อน)

| ขั้น | tag | ทำอะไร | ใคร |
|---|---|---|---|
| 0 | `step-0` | ติดตั้งเครื่องมือ, `./preflight.sh`, `./preflight.sh --warm` | ทุกคน ที่บ้าน |
| 1 | `step-1` | โปรเจกต์ Rust แบบ lib ที่เป็นโปรแกรม Solana | ทุกคน |
| 2 | `step-2` | ติดตั้ง skill ให้ agent | ทุกคน |
| 3 | `step-3` | ให้ agent เขียน `check_in` | ทุกคน |
| 4 | `step-4` | เทสต์ที่ `deadline - 1`, `deadline`, `deadline + 1` | ทุกคน |
| 5 | `step-5` | ส่ง `check_in` บน devnet ก่อนและหลัง deadline | ผู้บรรยายสาธิต |

### ขั้นที่ 0: ที่บ้าน ก่อนวันงาน

ทุกอย่างที่ต้องดาวน์โหลดหนัก ๆ ทำที่บ้าน ไม่ใช่บน Wi-Fi ในงาน

| ระบบ | ทำอย่างไร |
|---|---|
| Windows | เปิด PowerShell แบบ Administrator รัน `wsl --install` แล้วรีสตาร์ต จากนั้นรัน `powershell -ExecutionPolicy Bypass -File .\preflight.ps1` ขั้นตอนที่เหลือทั้งหมดทำใน Ubuntu (solana.com: การพัฒนาโปรแกรม Solana บน Windows ต้องใช้ WSL) |
| Linux | ตามด้านล่าง |
| macOS, Apple Silicon | ตามด้านล่าง |
| macOS, Intel | ตามด้านล่าง แต่ใช้ `cargo install symposium` แทน `cargo binstall symposium` (ไม่มี binary สำเร็จรูป ต้องคอมไพล์เอง ช้า) |

สิ่งที่ต้องมี: Rust (rustup), Solana CLI (`sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)"` แล้วเพิ่มลง PATH),
Node 20 ขึ้นไป, Symposium (`cargo binstall symposium`), agent หนึ่งตัวที่รันใน shell นั้นได้ และ devnet SOL
(ไม่บังคับ: ในห้องผู้บรรยายเป็นคน deploy)

```sh
cd hello-checkin                 # repo นี้ (Windows: clone ไว้ใน ~ ของ Ubuntu ไม่ใช่ /mnt/c)
./preflight.sh                   # ตรวจ: หนึ่งบรรทัดต่อเครื่องมือ ✅/❌ พร้อมคำสั่งแก้
./preflight.sh --warm            # ครั้งเดียว: cargo fetch, cargo build-sbf (โหลด platform-tools ~415 MB), cargo test
cargo agents init --add-agent <agent ของคุณ> --hook-scope project   # ครั้งเดียว ดูชื่อ agent ได้จาก cargo agents init --help
```

`preflight.sh` ไม่ติดตั้งอะไรเอง ไม่แก้ config ของ Solana ไม่พิมพ์ private key และไม่รอรับ input
`--warm` ต้องรันบน `main` (มีโค้ดครบทุกขั้น) ถ้าอยู่ที่ `step-0` ให้ `git checkout main` ก่อน

## English

We write one small Solana program with Pinocchio. It has one rule: a check-in is accepted only until a deadline.
Your own agent (Claude Code, Codex, Copilot, Goose, Gemini or another) writes the code, using the skills installed
in step 2. Every step is a git tag; if you fall behind, `git checkout step-N` (run `git stash` first if you have
local edits).

| Step | Tag | What | Who |
|---|---|---|---|
| 0 | `step-0` | install the tools, `./preflight.sh`, `./preflight.sh --warm` | everyone, at home |
| 1 | `step-1` | a Rust lib project that is a Solana program | everyone |
| 2 | `step-2` | install skills for your agent | everyone |
| 3 | `step-3` | the agent writes `check_in` | everyone |
| 4 | `step-4` | tests at `deadline - 1`, `deadline`, `deadline + 1` | everyone |
| 5 | `step-5` | send `check_in` on devnet before and after the deadline | presenter shows it |

### Step 0: at home, before the day

Every heavy download happens at home, not on the venue Wi-Fi.

| OS | Do this |
|---|---|
| Windows | In PowerShell as Administrator: `wsl --install`, restart, then `powershell -ExecutionPolicy Bypass -File .\preflight.ps1`. Everything else happens inside Ubuntu (solana.com: developing Solana programs on Windows requires WSL). |
| Linux | as below |
| macOS, Apple Silicon | as below |
| macOS, Intel | as below, but `cargo install symposium` instead of `cargo binstall symposium` (no prebuilt binary; it compiles, slowly) |

You need: Rust (rustup), the Solana CLI (`sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)"`, then
add it to PATH), Node 20 or newer, Symposium (`cargo binstall symposium`), one agent that runs in that shell, and
devnet SOL (optional: the presenter deploys in the room).

```sh
cd hello-checkin                 # this repo (Windows: clone it into your Ubuntu home, not /mnt/c)
./preflight.sh                   # checks: one line per tool, ✅/❌ and the fix command
./preflight.sh --warm            # once: cargo fetch, cargo build-sbf (downloads platform-tools, ~415 MB), cargo test
cargo agents init --add-agent <your agent> --hook-scope project   # once; agent names: cargo agents init --help
```

`preflight.sh` installs nothing, never changes your Solana config, never prints key material and never waits for
input. `--warm` needs the full code, so run it on `main`; on `step-0`, `git checkout main` first.

_Steps 1 to 5 arrive with their tags. / ขั้นที่ 1 ถึง 5 จะมาพร้อม tag ของขั้นนั้น_

## Tested / ทดสอบแล้ว

- Tested on macOS, Apple Silicon (8 Oct 2026; rustc 1.97.1, Solana CLI 3.1.10, platform-tools v1.52, Node 24):
  `./preflight.sh`, `./preflight.sh --warm`, and at every tag what that step promises (build at 1 and 3, tests at 4).
  ทดสอบบน macOS Apple Silicon แล้ว: `preflight.sh`, `--warm` และทุก tag
- **Not tested**: `preflight.ps1` (no Windows machine), Ubuntu under WSL, native Linux, Intel Mac, a clean machine.
  If anything fails there, please tell the presenter.
  **ยังไม่ได้ทดสอบ**: `preflight.ps1` (ไม่มีเครื่อง Windows), Ubuntu ใน WSL, Linux, Intel Mac, เครื่องใหม่เปล่า ๆ
  ถ้าเจอปัญหาบอกผู้บรรยายได้เลย
- Versions are pinned by the committed `Cargo.lock` (pinocchio 0.11.2, mollusk-svm 0.16.0) and
  `client/package-lock.json` (@solana/web3.js 1.x).
