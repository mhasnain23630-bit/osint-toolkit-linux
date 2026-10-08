#!/usr/bin/env bash
#
# bootstrap.sh — one-shot OSINT toolchain bootstrap for Debian / Ubuntu / Kali
#
# READ THIS SCRIPT BEFORE RUNNING IT. Never pipe a remote script straight
# into a shell. Review each step, then run:
#
#     chmod +x scripts/bootstrap.sh
#     ./scripts/bootstrap.sh
#
# Authorised, ethical security testing and educational use only. Only run
# OSINT tools against systems you own or have written permission to test.
#
set -euo pipefail

log()  { printf '\n\033[1;36m[*] %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[!] %s\033[0m\n' "$*"; }

if [ "$(id -u)" -eq 0 ]; then
  warn "Running as root. Consider a non-root user with sudo instead."
fi

# ---------------------------------------------------------------------------
# 1. Base toolchain
# ---------------------------------------------------------------------------
log "Installing base packages (apt)"
sudo apt update
sudo apt install -y \
  git curl wget jq \
  python3 python3-pip python3-venv \
  pipx golang-go \
  whois dnsutils \
  libimage-exiftool-perl

# ---------------------------------------------------------------------------
# 2. pipx — isolated Python CLI installs (avoids PEP 668 headaches)
# ---------------------------------------------------------------------------
log "Configuring pipx"
pipx ensurepath

PIPX_TOOLS=(
  sherlock-project
  shodan
  ghunt
  holehe
  dnsrecon
)

for t in "${PIPX_TOOLS[@]}"; do
  log "pipx install ${t}"
  pipx install "${t}" || warn "pipx install ${t} failed — install manually if needed"
done

# ---------------------------------------------------------------------------
# 3. Go-based tool
# ---------------------------------------------------------------------------
if command -v go >/dev/null 2>&1; then
  log "Installing amass via Go (fallback: apt/snap)"
  go install -v github.com/owasp-amass/amass/v4/...@master || \
    warn "go install amass failed — try: sudo apt install -y amass"
else
  warn "Go not found; skipping amass go-install"
fi

# ---------------------------------------------------------------------------
# 4. Working directories for output / evidence
# ---------------------------------------------------------------------------
log "Creating ~/osint workspace"
mkdir -p "$HOME/osint/tools" "$HOME/osint/output"

# ---------------------------------------------------------------------------
# 5. Summary
# ---------------------------------------------------------------------------
log "Bootstrap complete"
warn "Reload your shell so ~/.local/bin is on PATH:  source ~/.bashrc"
echo
echo "Next steps:"
echo "  1. source ~/.bashrc"
echo "  2. shodan init <YOUR_API_KEY>        # optional, for Shodan queries"
echo "  3. ghunt login                       # optional, only for authorised cases"
echo "  4. Read the ethics section in README.md before scanning anything."
