#!/usr/bin/env bash
# =============================================================================
# audit-secrets.sh — Secret and sensitive data scanner for dotfiles-zsh
# =============================================================================
# Scans ALL config files in the dotfiles-zsh repo for secrets, PII, and
# portability issues.
#
# Uses:
#   - gitleaks with custom rules (audit-gitleaks.toml)
#   - ripgrep for additional custom patterns
#
# Output: Categorised Markdown report at scripts/audit-report-YYYYMMDD-HHMMSS.md
# Exit code: 0 if clean, 1 if findings exist
#
# Usage:
#   ./scripts/audit-secrets.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && git rev-parse --show-toplevel)"
GITLEAKS_CONFIG="$SCRIPT_DIR/audit-gitleaks.toml"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
REPORT_FILE="$SCRIPT_DIR/audit-report-${TIMESTAMP}.md"
GITLEAKS_JSON="/tmp/claude/gitleaks-findings-${TIMESTAMP}.json"
CUSTOM_FINDINGS="/tmp/claude/custom-findings-${TIMESTAMP}.txt"

# Colours for output (disabled if not terminal)
if [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  BOLD='\033[1m'
  NC='\033[0m'
else
  RED=''
  GREEN=''
  YELLOW=''
  BLUE=''
  BOLD=''
  NC=''
fi

info() { echo -e "${BLUE}INFO:${NC} $*"; }
warn() { echo -e "${YELLOW}WARNING:${NC} $*"; }
success() { echo -e "${GREEN}OK:${NC} $*"; }
die() { echo -e "${RED}ERROR:${NC} $*" >&2; exit 2; }

# --- Pre-flight checks ---

check_dependencies() {
  if ! command -v gitleaks &>/dev/null; then
    die "gitleaks is not installed. Install via: brew install gitleaks"
  fi
  if ! command -v rg &>/dev/null; then
    die "ripgrep (rg) is not installed. Install via: brew install ripgrep"
  fi
  if ! command -v jq &>/dev/null; then
    die "jq is not installed. Install via: brew install jq"
  fi
}

# --- Gitleaks scan ---

run_gitleaks() {
  info "Running gitleaks scan..."

  # --no-git scans all files, not just git-tracked
  # Exit code 1 = findings, 0 = clean, other = error
  local exit_code=0
  gitleaks detect \
    --source "$REPO_ROOT" \
    --config "$GITLEAKS_CONFIG" \
    --report-path "$GITLEAKS_JSON" \
    --report-format json \
    --no-git \
    --exit-code 0 2>/dev/null || exit_code=$?

  if [ "$exit_code" -gt 1 ]; then
    warn "gitleaks exited with unexpected code $exit_code"
  fi

  # Count findings
  if [ -f "$GITLEAKS_JSON" ]; then
    GITLEAKS_COUNT=$(jq 'length' "$GITLEAKS_JSON" 2>/dev/null || echo "0")
  else
    GITLEAKS_COUNT=0
  fi

  info "gitleaks findings: $GITLEAKS_COUNT"
}

# --- Custom ripgrep patterns ---

run_custom_patterns() {
  info "Running custom pattern scan..."

  # Directories and files to exclude from scanning
  local exclude_args=(
    --glob '!.git/'
    --glob '!.planning/'
    --glob '!LICENSE.md'
    --glob '!README.md'
    --glob '!AGENTS.md'
    --glob '!AIDER.md'
    --glob '!CLAUDE.md'
    --glob '!*.md'
    --glob '!scripts/audit-gitleaks.toml'
    --glob '!scripts/audit-secrets.sh'
    --glob '!scripts/audit-report-*.md'
    --glob '!node_modules/'
    --glob '!logs/'
    --glob '!dotfiles-marketplace/'
    --glob '!nvim/'
    --glob '!art/'
  )

  > "$CUSTOM_FINDINGS"

  # Pattern: Email addresses
  rg --no-heading --line-number \
    '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' \
    "${exclude_args[@]}" "$REPO_ROOT" >> "$CUSTOM_FINDINGS" 2>/dev/null || true

  # Pattern: macOS user paths
  rg --no-heading --line-number \
    '/Users/[a-zA-Z0-9_-]+' \
    "${exclude_args[@]}" "$REPO_ROOT" >> "$CUSTOM_FINDINGS" 2>/dev/null || true

  # Pattern: Linux user paths
  rg --no-heading --line-number \
    '/home/[a-zA-Z0-9_-]+' \
    "${exclude_args[@]}" "$REPO_ROOT" >> "$CUSTOM_FINDINGS" 2>/dev/null || true

  # Pattern: IP addresses
  rg --no-heading --line-number \
    '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' \
    "${exclude_args[@]}" "$REPO_ROOT" >> "$CUSTOM_FINDINGS" 2>/dev/null || true

  # Pattern: API key assignments
  rg --no-heading --line-number -i \
    'api[_-]?key.*[:=]' \
    "${exclude_args[@]}" "$REPO_ROOT" >> "$CUSTOM_FINDINGS" 2>/dev/null || true

  # Pattern: Token assignments
  rg --no-heading --line-number -i \
    'token.*[:=]' \
    "${exclude_args[@]}" "$REPO_ROOT" >> "$CUSTOM_FINDINGS" 2>/dev/null || true

  # Pattern: Password assignments
  rg --no-heading --line-number -i \
    'password.*[:=]' \
    "${exclude_args[@]}" "$REPO_ROOT" >> "$CUSTOM_FINDINGS" 2>/dev/null || true

  # Deduplicate findings (same file:line may match multiple patterns)
  if [ -s "$CUSTOM_FINDINGS" ]; then
    sort -u "$CUSTOM_FINDINGS" -o "$CUSTOM_FINDINGS"
    CUSTOM_COUNT=$(wc -l < "$CUSTOM_FINDINGS" | tr -d ' ')
  else
    CUSTOM_COUNT=0
  fi

  info "Custom pattern findings: $CUSTOM_COUNT"
}

# --- Report generation ---

generate_report() {
  local total=$((GITLEAKS_COUNT + CUSTOM_COUNT))

  cat > "$REPORT_FILE" <<EOF
# Secret Audit Report

**Generated:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")
**Repository:** dotfiles-zsh
**Scanner:** audit-secrets.sh (gitleaks + custom ripgrep patterns)

## Summary

| Source | Findings |
|--------|----------|
EOF

  cat >> "$REPORT_FILE" <<EOF
| gitleaks | $GITLEAKS_COUNT |
| Custom patterns | $CUSTOM_COUNT |
| **Total** | **$total** |

---

## Gitleaks Findings

EOF

  if [ "$GITLEAKS_COUNT" -gt 0 ] && [ -f "$GITLEAKS_JSON" ]; then
    echo "| File | Line | Rule | Match (truncated) | Category | Action |" >> "$REPORT_FILE"
    echo "|------|------|------|-------------------|----------|--------|" >> "$REPORT_FILE"

    jq -r '.[] | [
      .File,
      (.StartLine | tostring),
      .RuleID,
      (.Match | if length > 40 then .[:40] + "..." else . end),
      "TODO",
      "TODO"
    ] | "| " + join(" | ") + " |"' "$GITLEAKS_JSON" >> "$REPORT_FILE" 2>/dev/null || true

    echo "" >> "$REPORT_FILE"
  else
    echo "_No gitleaks findings._" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
  fi

  cat >> "$REPORT_FILE" <<'EOF'
## Custom Pattern Findings

EOF

  if [ "$CUSTOM_COUNT" -gt 0 ] && [ -s "$CUSTOM_FINDINGS" ]; then
    echo "| File | Line | Match (truncated) | Category | Action |" >> "$REPORT_FILE"
    echo "|------|------|-------------------|----------|--------|" >> "$REPORT_FILE"

    while IFS= read -r line; do
      # Format: filepath:line:match
      local file line_num match
      file="$(echo "$line" | cut -d: -f1 | sed "s|^$REPO_ROOT/||")"
      line_num="$(echo "$line" | cut -d: -f2)"
      match="$(echo "$line" | cut -d: -f3-)"
      # Truncate match
      if [ "${#match}" -gt 50 ]; then
        match="${match:0:50}..."
      fi
      # Escape pipe characters in match
      match="${match//|/\\|}"
      echo "| $file | $line_num | $match | TODO | TODO |" >> "$REPORT_FILE"
    done < "$CUSTOM_FINDINGS"

    echo "" >> "$REPORT_FILE"
  else
    echo "_No custom pattern findings._" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
  fi

  cat >> "$REPORT_FILE" <<'EOF'
---

## Categorisation Guide

For each finding, assign one of the following categories:

| Category | Description | Action Required |
|----------|-------------|-----------------|
| **Bitwarden Secret** | API key, token, password, or other credential | Create Bitwarden entry; use chezmoi template with `bitwarden` function |
| **Template Variable** | User-specific value (path, email, hostname) | Use chezmoi template variable (e.g., `{{ .chezmoi.homeDir }}`) |
| **Safe to Ignore** | Example value, documentation, or non-sensitive default | No action needed |

## Next Steps

1. Review each finding and assign a category
2. For **Bitwarden Secret** items: create Bitwarden entries before migrating the config
3. For **Template Variable** items: plan the chezmoi template during the relevant phase
4. Re-run this audit before each phase migration to catch new issues
EOF

  info "Report written to: $REPORT_FILE"
}

# --- Cleanup ---

cleanup() {
  rm -f "$GITLEAKS_JSON" "$CUSTOM_FINDINGS"
}

# --- Main ---

main() {
  echo ""
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}       DOTFILES SECRET AUDIT            ${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""

  check_dependencies

  # Ensure temp directory exists
  mkdir -p /tmp/claude

  run_gitleaks
  run_custom_patterns
  generate_report
  cleanup

  local total=$((GITLEAKS_COUNT + CUSTOM_COUNT))

  echo ""
  echo -e "${BOLD}=== Audit Summary ===${NC}"
  echo ""
  echo "  gitleaks findings:       $GITLEAKS_COUNT"
  echo "  Custom pattern findings: $CUSTOM_COUNT"
  echo "  Total:                   $total"
  echo ""
  echo "  Report: $REPORT_FILE"
  echo ""

  if [ "$total" -gt 0 ]; then
    warn "Findings detected — review the report and categorise each item."
    exit 1
  else
    success "No findings detected — repo is clean."
    exit 0
  fi
}

main "$@"
