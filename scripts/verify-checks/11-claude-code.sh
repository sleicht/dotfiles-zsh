#!/usr/bin/env bash
# =============================================================================
# 11-claude-code.sh — Phase 11 verification checks
# =============================================================================
# Verifies that Claude Code selective sync is correctly configured:
# - Synced files (settings.json, CLAUDE.md, agents/, commands/, skills/) deployed
# - Local state (cache/, debug/, etc.) excluded from chezmoi tracking
# - Performance constraints met (chezmoi diff < 2 seconds)
#
# Checks:
# - File existence (synced configs at deployed locations)
# - chezmoi managed (synced files tracked)
# - Local state exclusion (cache/state NOT managed)
# - Performance (chezmoi diff under 2 seconds)
# - Managed file count sanity (10-60 files)
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

# --- Phase 11 config paths ---

declare -a CLAUDE_SYNCED_CONFIGS=(
  "$HOME/.claude/settings.json"
  "$HOME/.claude/CLAUDE.md"
  "$HOME/.claude/agents"
  "$HOME/.claude/commands"
  "$HOME/.claude/commands/gsd"
  "$HOME/.claude/skills"
  "$HOME/.claude/skills/commit-message"
)

# Local state directories/files that should NOT be managed
declare -a CLAUDE_LOCAL_STATE=(
  ".claude/cache"
  ".claude/debug"
  ".claude/downloads"
  ".claude/history.jsonl"
  ".claude/__store.db"
  ".claude/session-env"
  ".claude/settings.local.json"
  ".claude/get-shit-done"
  ".claude/plugins"
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
echo "Phase 11: Claude Code"
echo "====================="
echo ""

# Check 1: File existence (synced configs)
echo "Check 1: File existence (synced configs)..."
for path in "${CLAUDE_SYNCED_CONFIGS[@]}"; do
  if [ -e "$path" ]; then
    check_pass
  else
    check_fail "Missing: $path"
  fi
done

# Check 2: chezmoi managed (only synced files tracked)
echo "Check 2: chezmoi managed (synced files tracked)..."

if command -v chezmoi &>/dev/null; then
  MANAGED_OUTPUT=$(chezmoi managed --include=files 2>/dev/null || echo "")

  # Verify key synced files are managed
  declare -a EXPECTED_MANAGED=(
    ".claude/settings.json"
    ".claude/CLAUDE.md"
  )

  for file in "${EXPECTED_MANAGED[@]}"; do
    if echo "$MANAGED_OUTPUT" | grep -q "$file"; then
      check_pass
    else
      check_fail "Not managed by chezmoi: $file"
    fi
  done

  # Count agents/ files (expect at least 10)
  AGENTS_COUNT=$(echo "$MANAGED_OUTPUT" | grep ".claude/agents/" | wc -l | tr -d ' ')
  if [ "$AGENTS_COUNT" -ge 10 ]; then
    check_pass
  else
    check_fail "Too few agents/ files managed: $AGENTS_COUNT (expected >= 10)"
  fi

  # Count commands/ files (expect at least 5)
  COMMANDS_COUNT=$(echo "$MANAGED_OUTPUT" | grep ".claude/commands/" | wc -l | tr -d ' ')
  if [ "$COMMANDS_COUNT" -ge 5 ]; then
    check_pass
  else
    check_fail "Too few commands/ files managed: $COMMANDS_COUNT (expected >= 5)"
  fi

  # Verify skills/commit-message/SKILL.md is managed
  if echo "$MANAGED_OUTPUT" | grep -q ".claude/skills/commit-message/SKILL.md"; then
    check_pass
  else
    check_fail "Not managed by chezmoi: .claude/skills/commit-message/SKILL.md"
  fi
else
  echo "    (chezmoi not found, skipping managed check)"
fi

# Check 3: Local state exclusion (cache/state NOT managed)
echo "Check 3: Local state exclusion (cache/state NOT managed)..."

if command -v chezmoi &>/dev/null; then
  MANAGED_OUTPUT=$(chezmoi managed --include=files 2>/dev/null || echo "")

  for state_path in "${CLAUDE_LOCAL_STATE[@]}"; do
    if echo "$MANAGED_OUTPUT" | grep -q "$state_path"; then
      check_fail "Local state incorrectly managed: $state_path"
    else
      check_pass
    fi
  done
else
  echo "    (chezmoi not found, skipping exclusion check)"
fi

# Check 4: Performance (chezmoi diff under 2 seconds)
echo "Check 4: Performance (chezmoi diff under 2 seconds)..."

if command -v chezmoi &>/dev/null; then
  # Use nanosecond timing if available (macOS date doesn't support %N)
  if date +%s%N &>/dev/null 2>&1; then
    # Linux: nanosecond precision
    START_NS=$(date +%s%N)
    chezmoi diff &>/dev/null || true
    END_NS=$(date +%s%N)
    DURATION_MS=$(( (END_NS - START_NS) / 1000000 ))
  else
    # macOS: second precision, use sub-second timing via gdate if available
    if command -v gdate &>/dev/null; then
      START_NS=$(gdate +%s%N)
      chezmoi diff &>/dev/null || true
      END_NS=$(gdate +%s%N)
      DURATION_MS=$(( (END_NS - START_NS) / 1000000 ))
    else
      # Fallback: second-level timing
      START_S=$(date +%s)
      chezmoi diff &>/dev/null || true
      END_S=$(date +%s)
      DURATION_MS=$(( (END_S - START_S) * 1000 ))
    fi
  fi

  echo "    chezmoi diff completed in ${DURATION_MS}ms"

  if [ "$DURATION_MS" -lt 2000 ]; then
    check_pass
  else
    check_fail "chezmoi diff took ${DURATION_MS}ms (threshold: 2000ms)"
  fi
else
  echo "    (chezmoi not found, skipping performance check)"
fi

# Check 5: Managed file count sanity (10-60 files)
echo "Check 5: Managed file count sanity..."

if command -v chezmoi &>/dev/null; then
  MANAGED_OUTPUT=$(chezmoi managed --include=files 2>/dev/null || echo "")
  CLAUDE_FILE_COUNT=$(echo "$MANAGED_OUTPUT" | grep "\.claude" | wc -l | tr -d ' ')

  echo "    .claude managed files: $CLAUDE_FILE_COUNT"

  if [ "$CLAUDE_FILE_COUNT" -ge 10 ] && [ "$CLAUDE_FILE_COUNT" -le 60 ]; then
    check_pass
  elif [ "$CLAUDE_FILE_COUNT" -gt 60 ]; then
    check_fail "Too many .claude files managed: $CLAUDE_FILE_COUNT (expected 10-60, cache/state may have leaked)"
  else
    check_fail "Too few .claude files managed: $CLAUDE_FILE_COUNT (expected >= 10)"
  fi
else
  echo "    (chezmoi not found, skipping count check)"
fi

# --- Results ---

echo ""
echo "Results: $PASSED_CHECKS/$TOTAL_CHECKS passed"
echo ""

if [ "$FAILED_CHECKS" -gt 0 ]; then
  echo -e "${RED}Phase 11 verification FAILED${NC}"
  exit 1
else
  echo -e "${GREEN}Phase 11 verification PASSED${NC}"
  exit 0
fi
