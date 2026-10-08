# preflight.ps1: Windows check for the "Hello, Check-in" workshop.
#
# Solana programs are built inside WSL (Ubuntu) on Windows, so this script only checks that WSL and a Linux
# distribution are installed, then tells you to run ./preflight.sh inside Ubuntu. It installs nothing and
# runs nothing else.
#
#   powershell -ExecutionPolicy Bypass -File .\preflight.ps1

$ErrorActionPreference = 'Continue'
# wsl.exe prints UTF-16 unless this is set.
$env:WSL_UTF8 = '1'

Write-Host 'Hello, Check-in preflight: Windows'
Write-Host ''

$wsl = Get-Command wsl.exe -ErrorAction SilentlyContinue
if (-not $wsl) {
    Write-Host '[X]  WSL             wsl.exe not found'
    Write-Host '    fix: open PowerShell as Administrator, run:  wsl --install   then restart Windows'
    exit 1
}

$null = & wsl.exe --status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host '[X]  WSL             installed but not set up (wsl --status failed)'
    Write-Host '    fix: open PowerShell as Administrator, run:  wsl --install   then restart Windows'
    exit 1
}
Write-Host '[OK] WSL             wsl --status ok'

$distros = (& wsl.exe -l -v 2>&1 | Out-String) -replace "`0", ''
if ($distros -match 'Ubuntu') {
    Write-Host '[OK] Ubuntu          found in wsl -l -v'
} else {
    Write-Host '[X]  Ubuntu          no Ubuntu distribution in wsl -l -v'
    Write-Host '    fix: wsl --install -d Ubuntu'
    Write-Host ''
    Write-Host $distros
    exit 1
}

Write-Host ''
Write-Host 'Next: everything else happens inside Ubuntu, not in Windows.'
Write-Host '  1. Open Ubuntu (Start menu, or run:  wsl -d Ubuntu)'
Write-Host '  2. cd ~   (keep the repo in the Linux filesystem, not under /mnt/c: builds there are slow)'
Write-Host '  3. git clone <this repo> hello-checkin && cd hello-checkin'
Write-Host '  4. ./preflight.sh   then, at home:  ./preflight.sh --warm'
exit 0
