#!/usr/bin/env bash
# =============================================================================
# 08-basic-configs.sh — Phase 8 verification checks
# =============================================================================
# Verifies that all 13 Phase 8 configs are correctly deployed by chezmoi:
# - 6 basic dotfiles (hushlogin, inputrc, editorconfig, nanorc, psqlrc, sqliterc)
# - 7 CLI tool configs (bat, lsd, btop, oh-my-posh, aerospace, karabiner, zsh-abbr)
#
# Checks:
# - File existence (all 13 configs)
# - Not-a-symlink (all 13 configs must be real files, not Dotbot symlinks)
# - No template errors (all 13 configs)
# - Application parsability (bat, lsd, btop only)
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

# --- Phase 8 config paths ---

declare -a BASIC_DOTFILES=(
  "$HOME/.hushlogin"
  "$HOME/.inputrc"
  "$HOME/.editorconfig"
  "$HOME/.nanorc"
  "$HOME/.psqlrc"
  "$HOME/.sqliterc"
)

declare -a CLI_TOOL_CONFIGS=(
  "$HOME/.config/bat/config"
  "$HOME/.config/lsd/config.yaml"
  "$HOME/.config/btop/btop.conf"
  "$HOME/.config/oh-my-posh.omp.json"
  "$HOME/.config/karabiner/karabiner.json"
  "$HOME/.config/zsh-abbr/user-abbreviations"
)

# AeroSpace is macOS-only
if [[ "$OSTYPE" == darwin* ]]; then
  CLI_TOOL_CONFIGS+=("$HOME/.config/aerospace/aerospace.toml")
fi

# Combine all configs
ALL_CONFIGS=("${BASIC_DOTFILES[@]}" "${CLI_TOOL_CONFIGS[@]}")

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
echo "Phase 8: Basic Configs & CLI Tools"
echo "==================================="
echo ""

# Check 1: File existence (all 13 configs)
echo "Check 1: File existence..."
for path in "${ALL_CONFIGS[@]}"; do
  if check_file_exists "$path"; then
    check_pass
  else
    check_fail "Missing: $path"
  fi
done

# Check 2: Not-a-symlink (all 13 configs)
echo "Check 2: Not-a-symlink (chezmoi replaced Dotbot symlinks)..."
for path in "${ALL_CONFIGS[@]}"; do
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

# Check 3: No template errors (all 13 configs)
echo "Check 3: No template errors..."
for path in "${ALL_CONFIGS[@]}"; do
  if [ -f "$path" ] && check_no_template_errors "$path"; then
    check_pass
  else
    check_fail "Template errors or empty file: $path"
  fi
done

# Check 4: Application parsability (bat, lsd, btop only)
echo "Check 4: Application parsability..."

# bat config
if command -v bat &>/dev/null; then
  if check_app_can_parse bat "$HOME/.config/bat/config"; then
    check_pass
  else
    check_fail "bat cannot parse config: $HOME/.config/bat/config"
  fi
else
  check_fail "bat not installed (app installation is Homebrew's domain)"
fi

# lsd config
if command -v lsd &>/dev/null; then
  if check_app_can_parse lsd "$HOME/.config/lsd/config.yaml"; then
    check_pass
  else
    check_fail "lsd cannot parse config: $HOME/.config/lsd/config.yaml"
  fi
else
  check_fail "lsd not installed (app installation is Homebrew's domain)"
fi

# btop config
if command -v btop &>/dev/null; then
  if check_app_can_parse btop "$HOME/.config/btop/btop.conf"; then
    check_pass
  else
    check_fail "btop cannot parse config: $HOME/.config/btop/btop.conf"
  fi
else
  check_fail "btop not installed (app installation is Homebrew's domain)"
fi

# --- Results ---

echo ""
echo "Results: $PASSED_CHECKS/$TOTAL_CHECKS passed"
echo ""

if [ "$FAILED_CHECKS" -gt 0 ]; then
  echo -e "${RED}Phase 8 verification FAILED${NC}"
  exit 1
else
  echo -e "${GREEN}Phase 8 verification PASSED${NC}"
  exit 0
fi
