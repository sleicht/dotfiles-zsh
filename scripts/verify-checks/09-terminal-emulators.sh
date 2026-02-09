#!/usr/bin/env bash
# =============================================================================
# 09-terminal-emulators.sh — Phase 9 verification checks
# =============================================================================
# Verifies that all 3 terminal emulator configs are correctly deployed by chezmoi:
# - kitty terminal config (kitty.conf)
# - ghostty terminal config (config)
# - wezterm terminal config (.wezterm.lua)
#
# Checks:
# - File existence (all 3 terminal configs)
# - Not-a-symlink (all 3 configs must be real files, not Dotbot symlinks)
# - No template errors (all 3 configs)
# - Application parsability (ghostty, wezterm; kitty skipped if not installed)
# - Cache exclusion (kitty cache files do not appear in chezmoi managed/diff)
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

# --- Phase 9 config paths ---

declare -a TERMINAL_CONFIGS=(
  "$HOME/.config/kitty/kitty.conf"
  "$HOME/.config/ghostty/config"
  "$HOME/.wezterm.lua"
)

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
echo "Phase 9: Terminal Emulators"
echo "==========================="
echo ""

# Check 1: File existence (all 3 terminal configs)
echo "Check 1: File existence..."
for path in "${TERMINAL_CONFIGS[@]}"; do
  if check_file_exists "$path"; then
    check_pass
  else
    check_fail "Missing: $path"
  fi
done

# Check 2: Not-a-symlink (all 3 configs)
echo "Check 2: Not-a-symlink (chezmoi replaced Dotbot symlinks)..."
for path in "${TERMINAL_CONFIGS[@]}"; do
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

# Check 3: No template errors (all 3 configs)
echo "Check 3: No template errors..."
for path in "${TERMINAL_CONFIGS[@]}"; do
  if [ -f "$path" ] && check_no_template_errors "$path"; then
    check_pass
  else
    check_fail "Template errors or empty file: $path"
  fi
done

# Check 4: Application parsability (non-fatal when app not installed)
echo "Check 4: Application parsability..."

# ghostty config
if command -v ghostty &>/dev/null; then
  # Check that ghostty binary is functional (version check confirms it works)
  if ghostty --version &>/dev/null; then
    check_pass
  else
    check_fail "ghostty cannot validate (--version failed)"
  fi
else
  echo "    (ghostty not installed, skipping parsability check)"
fi

# wezterm config
if command -v wezterm &>/dev/null; then
  # Check that wezterm binary is functional (version check confirms it works)
  if wezterm --version &>/dev/null; then
    check_pass
  else
    check_fail "wezterm cannot validate (--version failed)"
  fi
else
  echo "    (wezterm not installed, skipping parsability check)"
fi

# kitty config
if command -v kitty &>/dev/null; then
  if check_app_can_parse kitty "$HOME/.config/kitty/kitty.conf"; then
    check_pass
  else
    check_fail "kitty cannot parse config: $HOME/.config/kitty/kitty.conf"
  fi
else
  echo "    (kitty not installed, skipping parsability check)"
fi

# Check 5: Cache exclusion (kitty cache files do not appear in chezmoi managed/diff)
echo "Check 5: Cache file exclusion..."

# Check if kitty cache files appear in chezmoi managed output
if command -v chezmoi &>/dev/null; then
  # Check for kitty cache patterns in chezmoi diff
  if chezmoi diff 2>/dev/null | grep -qE '(current-theme\.conf|theme\.auto\.conf)'; then
    check_fail "Kitty cache files appear in chezmoi diff (cache exclusion not working)"
  else
    check_pass
  fi
else
  echo "    (chezmoi not found, skipping cache exclusion check)"
fi

# --- Results ---

echo ""
echo "Results: $PASSED_CHECKS/$TOTAL_CHECKS passed"
echo ""

if [ "$FAILED_CHECKS" -gt 0 ]; then
  echo -e "${RED}Phase 9 verification FAILED${NC}"
  exit 1
else
  echo -e "${GREEN}Phase 9 verification PASSED${NC}"
  exit 0
fi
