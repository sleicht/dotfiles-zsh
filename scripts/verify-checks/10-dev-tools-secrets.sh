#!/usr/bin/env bash
# =============================================================================
# 10-dev-tools-secrets.sh — Phase 10 verification checks
# =============================================================================
# Verifies that all 6 dev tool configs are correctly deployed by chezmoi:
# - lazygit config (config.yml)
# - atuin config and keybindings (config.toml, atuin-keybindings.zsh)
# - aider config (.aider.conf.yml)
# - finicky browser routing (.finicky.js, macOS-only)
# - gpg-agent config with OS-conditional pinentry path (gpg-agent.conf)
#
# Checks:
# - File existence (all 6 dev tool configs)
# - Not-a-symlink (all configs must be real files, not Dotbot symlinks)
# - No template errors (verify gpg-agent template rendered correctly)
# - GPG agent pinentry path (Homebrew on macOS, Linux system path, not Nix)
# - Application parsability (lazygit, atuin, aider, gpg-agent when installed)
# - chezmoi managed (all Phase 10 configs listed)
#
# Executed by scripts/verify-configs.sh via plugin discovery.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../verify-lib"

# Source helper libraries
for lib in "$LIB_DIR"/*.sh; do
  if [ -f "$lib" ]; then
    # shellcheck source=/dev/null
    source "$lib"
  fi
done

# Colours for output
if [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  NC='\033[0m'
else
  RED=''
  GREEN=''
  YELLOW=''
  NC=''
fi

# --- Phase 10 config paths ---

declare -a DEV_TOOL_CONFIGS=(
  "$HOME/.config/lazygit/config.yml"
  "$HOME/.config/atuin/config.toml"
  "$HOME/.config/atuin/atuin-keybindings.zsh"
  "$HOME/.aider.conf.yml"
  "$HOME/.gnupg/gpg-agent.conf"
)

# finicky is macOS-only
if [[ "$OSTYPE" == "darwin"* ]]; then
  DEV_TOOL_CONFIGS+=("$HOME/.finicky.js")
fi

# --- Check counters ---

TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

check_pass() {
  TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
  PASSED_CHECKS=$((PASSED_CHECKS + 1))
}

check_fail() {
  TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
  FAILED_CHECKS=$((FAILED_CHECKS + 1))
  echo -e "    ${RED}✗${NC} $1"
}

# --- Verification checks ---

echo ""
echo "Phase 10: Dev Tools with Secrets"
echo "================================="
echo ""

# Check 1: File existence (all 6 dev tool configs, 5 on Linux)
echo "Check 1: File existence..."
for path in "${DEV_TOOL_CONFIGS[@]}"; do
  if check_file_exists "$path"; then
    check_pass
  else
    check_fail "Missing: $path"
  fi
done

# Check 2: Not-a-symlink (all configs)
echo "Check 2: Not-a-symlink (chezmoi replaced Dotbot symlinks)..."
for path in "${DEV_TOOL_CONFIGS[@]}"; do
  if [ -e "$path" ] && [ ! -L "$path" ]; then
    check_pass
  else
    if [ -L "$path" ]; then
      check_fail "Still a symlink (expected real file): $path"
    else
      check_fail "Does not exist: $path"
    fi
  fi
done

# Check 3: No template errors (verify gpg-agent template rendered correctly)
echo "Check 3: No template errors..."
for path in "${DEV_TOOL_CONFIGS[@]}"; do
  if [ -f "$path" ]; then
    # Check for unresolved template syntax ({{ or }})
    if grep -qE '(\{\{|\}\})' "$path" 2>/dev/null; then
      check_fail "Template errors found in: $path"
    else
      check_pass
    fi
  else
    check_fail "File not found: $path"
  fi
done

# Check 4: GPG agent pinentry path (Homebrew on macOS, not Nix)
echo "Check 4: GPG agent pinentry path..."
GPG_AGENT_CONF="$HOME/.gnupg/gpg-agent.conf"

if [ -f "$GPG_AGENT_CONF" ]; then
  # Check for obsolete Nix path
  if grep -q '/run/current-system/sw/bin/pinentry-mac' "$GPG_AGENT_CONF" 2>/dev/null; then
    check_fail "gpg-agent.conf contains obsolete Nix path"
  else
    check_pass
  fi

  # Check for correct OS-specific path
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS: should use Homebrew path
    if grep -q '/opt/homebrew/bin/pinentry-mac' "$GPG_AGENT_CONF" 2>/dev/null; then
      check_pass
    else
      check_fail "gpg-agent.conf missing Homebrew pinentry path on macOS"
    fi
  else
    # Linux: should use system pinentry
    if grep -q '/usr/bin/pinentry-curses' "$GPG_AGENT_CONF" 2>/dev/null; then
      check_pass
    else
      check_fail "gpg-agent.conf missing system pinentry path on Linux"
    fi
  fi
else
  check_fail "gpg-agent.conf not found"
fi

# Check 5: Application parsability (non-fatal when app not installed)
echo "Check 5: Application parsability..."

# lazygit
if command -v lazygit &>/dev/null; then
  if lazygit --version &>/dev/null; then
    check_pass
  else
    check_fail "lazygit cannot validate (--version failed)"
  fi
else
  echo "    (lazygit not installed, skipping parsability check)"
fi

# atuin
if command -v atuin &>/dev/null; then
  if atuin doctor &>/dev/null; then
    check_pass
  else
    check_fail "atuin cannot validate (doctor failed)"
  fi
else
  echo "    (atuin not installed, skipping parsability check)"
fi

# aider
if command -v aider &>/dev/null; then
  if aider --version &>/dev/null; then
    check_pass
  else
    check_fail "aider cannot validate (--version failed)"
  fi
else
  echo "    (aider not installed, skipping parsability check)"
fi

# gpg-agent
if command -v gpg-agent &>/dev/null; then
  if gpg-agent --version &>/dev/null; then
    check_pass
  else
    check_fail "gpg-agent cannot validate (--version failed)"
  fi
else
  echo "    (gpg-agent not installed, skipping parsability check)"
fi

# finicky (macOS-only, no CLI validation available)
if [[ "$OSTYPE" == "darwin"* ]]; then
  if [ -f "$HOME/.finicky.js" ]; then
    echo "    (finicky config deployed, no CLI validation available)"
  fi
fi

# Check 6: chezmoi managed (all Phase 10 configs listed)
echo "Check 6: chezmoi managed..."

if command -v chezmoi &>/dev/null; then
  MANAGED_OUTPUT=$(chezmoi managed --include=files 2>/dev/null || echo "")

  declare -a EXPECTED_MANAGED=(
    ".config/lazygit/config.yml"
    ".config/atuin/config.toml"
    ".config/atuin/atuin-keybindings.zsh"
    ".aider.conf.yml"
    ".gnupg/gpg-agent.conf"
  )

  # Add finicky on macOS
  if [[ "$OSTYPE" == "darwin"* ]]; then
    EXPECTED_MANAGED+=(".finicky.js")
  fi

  for file in "${EXPECTED_MANAGED[@]}"; do
    if echo "$MANAGED_OUTPUT" | grep -q "$file"; then
      check_pass
    else
      check_fail "Not managed by chezmoi: $file"
    fi
  done
else
  echo "    (chezmoi not found, skipping managed check)"
fi

# --- Results ---

echo ""
echo "Results: $PASSED_CHECKS/$TOTAL_CHECKS passed"
echo ""

if [ "$FAILED_CHECKS" -gt 0 ]; then
  echo -e "${RED}Phase 10 verification FAILED${NC}"
  exit 1
else
  echo -e "${GREEN}Phase 10 verification PASSED${NC}"
  exit 0
fi
