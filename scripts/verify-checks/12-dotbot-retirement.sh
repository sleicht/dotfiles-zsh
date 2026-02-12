#!/usr/bin/env bash
# =============================================================================
# 12-dotbot-retirement.sh — Phase 12 verification checks
# =============================================================================
# Verifies that Phase 12 (Dotbot Retirement) has successfully completed all
# migration requirements and that chezmoi is now the sole dotfile manager.
#
# Checks:
# 1. No Dotbot symlinks remain (except intentional nvim and .dotfiles)
# 2. Dotbot infrastructure removed from repository
# 3. Deprecated configs removed from repository
# 4. Deprecated configs removed from target (home directory)
# 5. chezmoi is sole dotfile manager (sanity checks)
#
# Executed by scripts/verify-configs.sh via plugin discovery.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
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
echo "Phase 12: Dotbot Retirement"
echo "============================"
echo ""

# Check 1: No Dotbot symlinks remain (except nvim and .dotfiles)
echo "Check 1: No Dotbot symlinks remain..."

# Find all symlinks in home directory (max depth 3)
DOTBOT_SYMLINKS=0
while IFS= read -r link; do
  # Get symlink target
  target=$(readlink "$link" 2>/dev/null || echo "")

  # Check if target contains "dotfiles-zsh"
  if [[ "$target" == *"dotfiles-zsh"* ]]; then
    # Exclude intentional exceptions
    if [[ "$link" == *"/nvim" ]] || [[ "$link" == *"/.dotfiles" ]]; then
      # Intentional exception - skip
      continue
    fi

    # Exclude internal repo references (.planning, .git)
    if [[ "$link" == *"/.planning"* ]] || [[ "$link" == *"/.git"* ]]; then
      # Internal repo reference - skip
      continue
    fi

    # Found an unexpected Dotbot symlink
    check_fail "Dotbot symlink found: $link -> $target"
    DOTBOT_SYMLINKS=$((DOTBOT_SYMLINKS + 1))
  fi
done < <(find ~ -maxdepth 3 -type l 2>/dev/null || true)

if [ "$DOTBOT_SYMLINKS" -eq 0 ]; then
  check_pass
fi

# Check 2: Dotbot infrastructure removed from repository
echo "Check 2: Dotbot infrastructure removed from repository..."

INFRASTRUCTURE_ITEMS=(
  "$REPO_DIR/install"
  "$REPO_DIR/steps"
  "$REPO_DIR/dotbot"
  "$REPO_DIR/dotbot-asdf"
  "$REPO_DIR/dotbot-brew"
  "$REPO_DIR/.gitmodules"
)

INFRASTRUCTURE_FOUND=0
for item in "${INFRASTRUCTURE_ITEMS[@]}"; do
  if [ -e "$item" ]; then
    check_fail "Dotbot infrastructure still exists: $item"
    INFRASTRUCTURE_FOUND=$((INFRASTRUCTURE_FOUND + 1))
  fi
done

if [ "$INFRASTRUCTURE_FOUND" -eq 0 ]; then
  check_pass
fi

# Check 3: Deprecated configs removed from repository
echo "Check 3: Deprecated configs removed from repository..."

REPO_DEPRECATED=(
  "$REPO_DIR/.config/nushell"
  "$REPO_DIR/.config/zgenom"
  "$REPO_DIR/zgenom"
)

REPO_DEPRECATED_FOUND=0
for item in "${REPO_DEPRECATED[@]}"; do
  if [ -e "$item" ]; then
    check_fail "Deprecated config still in repository: $item"
    REPO_DEPRECATED_FOUND=$((REPO_DEPRECATED_FOUND + 1))
  fi
done

if [ "$REPO_DEPRECATED_FOUND" -eq 0 ]; then
  check_pass
fi

# Check 4: Deprecated configs removed from target (home directory)
echo "Check 4: Deprecated configs removed from target..."

TARGET_DEPRECATED=(
  "$HOME/.config/nushell"
  "$HOME/.config/zgenom"
  "$HOME/.zgenom"
)

TARGET_DEPRECATED_FOUND=0
for item in "${TARGET_DEPRECATED[@]}"; do
  if [ -e "$item" ]; then
    check_fail "Deprecated config still exists: $item"
    TARGET_DEPRECATED_FOUND=$((TARGET_DEPRECATED_FOUND + 1))
  fi
done

if [ "$TARGET_DEPRECATED_FOUND" -eq 0 ]; then
  check_pass
fi

# Check 5: chezmoi is sole dotfile manager
echo "Check 5: chezmoi is sole dotfile manager..."

# 5a: chezmoi managed files count (sanity check)
if command -v chezmoi &>/dev/null; then
  MANAGED_COUNT=$(chezmoi managed --include=files 2>/dev/null | wc -l | tr -d ' ')

  if [ "$MANAGED_COUNT" -ge 10 ]; then
    check_pass
  else
    check_fail "chezmoi managing only $MANAGED_COUNT files (expected at least 10)"
  fi
else
  check_fail "chezmoi command not found"
fi

# 5b: chezmoi source directory exists and is valid
if command -v chezmoi &>/dev/null; then
  SOURCE_DIR=$(chezmoi source-path 2>/dev/null || echo "")
  if [ -n "$SOURCE_DIR" ] && [ -d "$SOURCE_DIR" ] && [ -d "$SOURCE_DIR/.git" ]; then
    check_pass
  else
    check_fail "chezmoi source directory not found or invalid"
  fi
else
  check_fail "chezmoi command not found"
fi

# --- Results ---

echo ""
echo "Results: $PASSED_CHECKS/$TOTAL_CHECKS passed"
echo ""

if [ "$FAILED_CHECKS" -gt 0 ]; then
  echo -e "${RED}Phase 12 verification FAILED${NC}"
  exit 1
else
  echo -e "${GREEN}Phase 12 verification PASSED${NC}"
  exit 0
fi
