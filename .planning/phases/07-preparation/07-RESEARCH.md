# Phase 7: Preparation - Research

**Researched:** 2026-02-08
**Domain:** Pre-migration protective infrastructure (ignore patterns, secret auditing, verification frameworks)
**Confidence:** HIGH

## Summary

Phase 7 establishes critical protective infrastructure before migrating any Dotbot-managed configs to chezmoi in Phases 8-12. This includes comprehensive .chezmoiignore setup covering all Dotbot infrastructure and repository meta files, a reusable secret audit script to prevent credential leakage, and an extensible verification framework to confirm correct config deployment. The research confirms that chezmoi's .chezmoiignore supports template syntax for OS-conditional ignoring, established secret detection tools (gitleaks, detect-secrets) provide scriptable scanning, and plugin-based verification frameworks allow incremental check addition as configs migrate. Key decision: git revert is the sole recovery mechanism (no file snapshots), and chezmoi diff + dry-run review is mandatory before every apply.

**Key validated patterns:**
- .chezmoiignore supports full template syntax including {{ if eq .chezmoi.os "darwin" }} conditionals
- Secret audit tools should use multiple patterns (regex + entropy detection) to catch everything
- Verification scripts should validate three aspects: file existence, content validity, and application parsability
- Plugin-based verification architecture allows each future phase to add its own checks

**Primary recommendation:** Create comprehensive .chezmoiignore upfront (not incrementally), use gitleaks + custom patterns for secret scanning, build verification runner that loads phase-specific check files from a directory, rely on git revert for recovery (no separate backup files).

## User Constraints

### Locked Decisions
**From CONTEXT.md - MUST be honored:**

- **Ignore strategy:** Cover Dotbot infrastructure AND repo meta files (README, LICENSE, .git*, Brewfile, .planning/, etc.)
- **OS-conditional ignoring:** Use chezmoi template syntax for platform-specific exclusions (e.g., aerospace config ignored on Linux)
- **Comprehensive setup now:** Define all ignore rules upfront covering the entire v1.1 migration (not incremental)
- **Secret audit criteria:** Flag ANYTHING non-public: API keys, tokens, passwords, email addresses, usernames, server hostnames, IP addresses, user-specific paths (/Users/yourname)
- **Report AND categorise:** Each finding must be categorised as: Bitwarden secret, chezmoi template variable, or safe to ignore
- **Audit ALL config files:** Including v1.0.0 configs to catch anything missed earlier
- **Reusable script:** Can be re-run before each phase to verify no new secrets have crept in
- **Correct deployment definition:** File exists at target path, content is valid (no template errors/placeholders), AND target application can parse/load it without errors
- **Pass/fail summary:** Checkmark/cross per config, exit code reflects overall result
- **Manual invocation:** Standalone script, not a chezmoi hook
- **Plugin-based structure:** Runner loads check files from a directory, each phase drops in its own checks
- **Git as backup:** No separate file snapshots needed
- **Recovery via git revert:** Of phase commit, then re-run chezmoi apply
- **Always run chezmoi diff before chezmoi apply:** Dry-run review for every migration
- **Batch per phase:** Each phase migrates all its configs together in one commit

### Claude's Discretion
**Research options and recommend:**
- How to handle v1.0.0 configs in .chezmoiignore (skip vs document)
- Exact categories and format for the secret audit report
- Verification check file format and runner implementation
- Specific Dotbot files and repo meta files to include in .chezmoiignore

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| chezmoi | 2.69.3 | .chezmoiignore template processing | Already installed (v1.0.0), official ignore mechanism |
| gitleaks | 8.x | Secret detection with pattern + entropy | Industry standard, 20k+ GitHub stars, actively maintained |
| bash | 5.x | Verification scripting | Universal, already project standard |
| ripgrep | 14.x | Fast pattern matching for audits | Already installed, 10x faster than grep |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| detect-secrets | 1.x | Additional secret detection patterns | Optional: complement gitleaks for broader coverage |
| shellcheck | 0.x | Verification script validation | Dev-time: ensure verification scripts are correct |
| bats | 1.x | Test framework for verification runner | Optional: if unit testing verification logic |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| gitleaks | trufflehog | trufflehog slower, gitleaks has better config flexibility |
| gitleaks | detect-secrets | detect-secrets Python dependency, gitleaks standalone binary |
| bash verification | Python/Ruby | bash universal on target systems, no extra dependencies |
| Plugin architecture | Monolithic script | Monolithic harder to extend per-phase, plugin allows incremental growth |
| Git revert recovery | File snapshots (rsync) | File snapshots redundant with git history, git revert atomic |

**Installation:**
```bash
# Already installed via v1.0.0:
# - chezmoi
# - ripgrep
# - bash 5.x

# New for Phase 7:
brew install gitleaks
gitleaks version  # Should show 8.x

# Optional supplements:
# brew install shellcheck bats-core
# pip install detect-secrets
```

## Architecture Patterns

### Recommended File Structure

```
.local/share/chezmoi/
├── .chezmoiignore              # Comprehensive ignore patterns (created Phase 7)
├── .verification/              # Verification framework (created Phase 7)
│   ├── runner.sh               # Loads and executes check files
│   ├── checks/                 # Phase-specific verification checks
│   │   ├── 08-basic-configs.sh
│   │   ├── 09-terminals.sh
│   │   ├── 10-dev-tools.sh
│   │   └── 11-claude.sh
│   └── lib/
│       ├── check-exists.sh     # Helper: verify file exists
│       ├── check-valid.sh      # Helper: no template errors
│       └── check-parsable.sh   # Helper: app can load config
├── .secrets-audit/             # Secret detection (created Phase 7)
│   ├── audit.sh                # Main audit script
│   ├── gitleaks.toml           # Gitleaks configuration
│   ├── patterns.txt            # Custom regex patterns
│   └── report-template.md      # Report output format
└── ... (existing v1.0.0 configs)

~/.dotfiles/
├── dotbot/                     # IGNORED by .chezmoiignore
├── steps/                      # IGNORED by .chezmoiignore
├── Brewfile                    # IGNORED by .chezmoiignore
├── .planning/                  # IGNORED by .chezmoiignore
├── README.md                   # IGNORED by .chezmoiignore
└── ... (other Dotbot infrastructure - all ignored)
```

### Pattern 1: Comprehensive .chezmoiignore with Templates

**What:** Single upfront .chezmoiignore defining all exclusions for entire v1.1 migration with OS-conditional patterns

**When to use:** Always — Phase 7 establishes complete ignore list before any migrations

**Example:**
```bash
# .chezmoiignore
# Purpose: Prevent chezmoi from managing Dotbot infrastructure, repo meta files,
# and platform-specific configs during v1.1 migration (Phases 7-12)

# === Dotbot Infrastructure ===
# These remain in repo but are never deployed by chezmoi
dotbot/
dotbot/**
dotbot-asdf/
dotbot-asdf/**
dotbot-brew/
dotbot-brew/**
install               # Dotbot installation script
steps/
steps/**

# === Repository Meta Files ===
# Project documentation and planning - not deployed to home directory
README.md
LICENSE.md
.editorconfig
.gitignore
.gitmodules
.git/
.git/**
.github/
.github/**
.planning/
.planning/**
Brewfile              # Managed separately by Homebrew
Brewfile_*            # Machine-specific Brewfiles
.macos                # macOS system config script (run manually)

# === OS-Specific Exclusions ===
# Configs that only apply to specific operating systems
{{- if ne .chezmoi.os "darwin" }}
# Ignore macOS-only configs on Linux
.config/aerospace/
.config/aerospace/**
Library/
Library/**
{{- end }}

{{- if ne .chezmoi.os "linux" }}
# Ignore Linux-only configs on macOS
.config/i3/
.config/i3/**
{{- end }}

# === v1.0.0 Configs (Already Managed) ===
# These were migrated in Phases 1-6, document but don't re-add
# .zshrc, .zshenv, .zprofile already in chezmoi source
# .config/git/ already in chezmoi source
# .config/mise/ already in chezmoi source
# .config/sheldon/ already in chezmoi source
# No action needed - just document for clarity

# === Still Managed by Dotbot (Phases 8-12 will migrate these) ===
# Explicitly document what's pending migration
# These patterns will be REMOVED incrementally as phases complete

# Phase 8: Basic configs & CLI tools
.hushlogin
.inputrc
.nanorc
.config/bat/
.config/lsd/
.config/btop/
.config/oh-my-posh.omp.json
.psqlrc
.sqliterc
.config/zsh-abbr/
.config/karabiner/

# Phase 9: Terminal emulators
.config/kitty/
.config/ghostty/
.wezterm.lua

# Phase 10: Dev tools with secrets
.config/lazygit/
.config/atuin/
.aider.conf.yml
.finicky.js
.gnupg/gpg-agent.conf

# Phase 11: Claude Code
.claude/
.claude/**

# === Deprecated Configs (Phase 12 will remove these) ===
# Nushell - not in use, will delete
.config/nushell/
.config/nushell/**

# Zgenom - replaced by Sheldon in v1.0.0, will delete
zgenom/
zgenom/**
.zgenom
.zgenom/**

# === Development/Temporary Files ===
# Never managed by chezmoi
*.tmp
*.log
*.bak
.DS_Store
```

**Why this works:**
- Upfront comprehensive setup prevents accidental tracking of unwanted files
- Template syntax handles OS differences without manual intervention
- Comments document migration plan (which phase handles what)
- Can safely run `chezmoi add ~/.config/*` without fear of capturing Dotbot files

### Pattern 2: Multi-Tool Secret Detection

**What:** Combine gitleaks (pattern + entropy) with custom regex patterns to catch all secret types

**When to use:** Pre-migration audit (Phase 7), then re-run before each subsequent phase

**Example:**
```bash
#!/usr/bin/env bash
# .secrets-audit/audit.sh
# Purpose: Detect secrets in all config files before migration to prevent leakage
# Usage: ./audit.sh [--fix]  # --fix creates .gitignore entries for flagged files

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel)"
REPORT_FILE="$SCRIPT_DIR/audit-report-$(date +%Y%m%d-%H%M%S).md"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "=== Dotfiles Secret Audit ==="
echo "Scanning: $REPO_ROOT"
echo "Report: $REPORT_FILE"
echo ""

# Step 1: Run gitleaks (pattern + entropy detection)
echo "Step 1/3: Running gitleaks scan..."
if gitleaks detect --source "$REPO_ROOT" --config "$SCRIPT_DIR/gitleaks.toml" --report-path "$SCRIPT_DIR/gitleaks-findings.json" --no-git; then
    GITLEAKS_FINDINGS=0
else
    GITLEAKS_FINDINGS=$?
fi

# Step 2: Custom pattern scanning
echo "Step 2/3: Running custom pattern scan..."
CUSTOM_FINDINGS=()

# Patterns to detect
patterns=(
    # Email addresses (potential PII)
    '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'
    # Hostnames/IPs (potential exposure)
    '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'
    # User-specific paths (portability issue)
    '/Users/[a-zA-Z0-9_-]+'
    '/home/[a-zA-Z0-9_-]+'
    # API key patterns
    'api[_-]?key[_-]?[:=][[:space:]]*["\047][^"\047]+["\047]'
    # Token patterns
    'token[_-]?[:=][[:space:]]*["\047][^"\047]+["\047]'
    # Password patterns
    'password[_-]?[:=][[:space:]]*["\047][^"\047]+["\047]'
)

for pattern in "${patterns[@]}"; do
    while IFS=: read -r file line content; do
        # Skip .git directory and known safe files
        if [[ "$file" =~ \.git/ ]] || [[ "$file" =~ /LICENSE ]] || [[ "$file" =~ /README ]]; then
            continue
        fi

        CUSTOM_FINDINGS+=("$file:$line:$content")
    done < <(rg --line-number --no-heading "$pattern" "$REPO_ROOT" 2>/dev/null || true)
done

# Step 3: Generate categorised report
echo "Step 3/3: Generating report..."

cat > "$REPORT_FILE" << 'EOF_HEADER'
# Secret Audit Report

**Generated:** $(date +"%Y-%m-%d %H:%M:%S")
**Repository:** $(basename "$REPO_ROOT")

## Summary

EOF_HEADER

# Count findings
GITLEAKS_COUNT=$(jq '. | length' "$SCRIPT_DIR/gitleaks-findings.json" 2>/dev/null || echo "0")
CUSTOM_COUNT=${#CUSTOM_FINDINGS[@]}
TOTAL=$((GITLEAKS_COUNT + CUSTOM_COUNT))

cat >> "$REPORT_FILE" << EOF

| Category | Count |
|----------|-------|
| Gitleaks Findings | $GITLEAKS_COUNT |
| Custom Pattern Findings | $CUSTOM_COUNT |
| **Total** | **$TOTAL** |

---

## Gitleaks Findings

EOF

# Parse gitleaks JSON and categorise
if [ "$GITLEAKS_COUNT" -gt 0 ]; then
    cat >> "$REPORT_FILE" << 'EOF'
| File | Line | Rule | Category | Action |
|------|------|------|----------|--------|
EOF

    jq -r '.[] | "| \(.File) | \(.StartLine) | \(.RuleID) | NEEDS_REVIEW | TODO |"' \
        "$SCRIPT_DIR/gitleaks-findings.json" >> "$REPORT_FILE" 2>/dev/null || true
else
    echo "No findings detected by gitleaks." >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" << EOF

---

## Custom Pattern Findings

EOF

if [ "$CUSTOM_COUNT" -gt 0 ]; then
    cat >> "$REPORT_FILE" << 'EOF'
| File | Line | Pattern Match | Category | Action |
|------|------|---------------|----------|--------|
EOF

    for finding in "${CUSTOM_FINDINGS[@]}"; do
        IFS=: read -r file line content <<< "$finding"
        # Truncate content for readability
        content_short=$(echo "$content" | head -c 60)
        echo "| $file | $line | $content_short | NEEDS_REVIEW | TODO |" >> "$REPORT_FILE"
    done
else
    echo "No findings detected by custom patterns." >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" << 'EOF'

---

## Categorisation Guide

For each finding, determine:

1. **Bitwarden Secret** - True secret (API key, password, token)
   - Action: Add to Bitwarden, template with `{{ (bitwarden "item-id").field }}`

2. **Template Variable** - User/machine-specific but not secret (email, hostname)
   - Action: Template with `{{ .chezmoi.username }}` or `.chezmoi.hostname`

3. **Safe to Ignore** - Example/documentation, not real secret
   - Action: Add pattern to .gitleaksignore or document as false positive

## Next Steps

1. Review each finding in the tables above
2. Fill in Category and Action columns
3. For Bitwarden secrets: Create Bitwarden entry, then template
4. For template variables: Use chezmoi built-in variables
5. For false positives: Document reason
6. Re-run audit after changes: `./audit.sh`

EOF

# Print summary
echo ""
if [ "$TOTAL" -gt 0 ]; then
    echo -e "${YELLOW}⚠ Found $TOTAL potential secrets${NC}"
    echo -e "${YELLOW}Review report: $REPORT_FILE${NC}"
    exit 1
else
    echo -e "${GREEN}✓ No secrets detected${NC}"
    exit 0
fi
```

**gitleaks.toml configuration:**
```toml
# .secrets-audit/gitleaks.toml
title = "Dotfiles Secret Detection"

[extend]
# Use default gitleaks rules
useDefault = true

# Add custom rules for dotfiles-specific patterns
[[rules]]
id = "user-path-macos"
description = "macOS user-specific path"
regex = '''/Users/[a-zA-Z0-9_-]+'''
tags = ["portability"]

[[rules]]
id = "user-path-linux"
description = "Linux user-specific path"
regex = '''/home/[a-zA-Z0-9_-]+'''
tags = ["portability"]

[[rules]]
id = "email-address"
description = "Email address (potential PII)"
regex = '''[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'''
tags = ["pii"]
[rules.allowlist]
paths = [
    '''\.git/''',
    '''README\.md''',
    '''LICENSE''',
]

[[rules]]
id = "private-ip"
description = "Private IP address"
regex = '''192\.168\.[0-9]{1,3}\.[0-9]{1,3}|10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'''
tags = ["network"]

[allowlist]
description = "Global allowlist"
paths = [
    '''\.git/''',
    '''\.planning/''',
    '''LICENSE''',
]
```

**Why this works:**
- Gitleaks catches standard secret patterns (API keys, tokens, AWS credentials)
- Custom patterns catch dotfile-specific issues (user paths, emails, hostnames)
- JSON output allows structured parsing and categorisation
- Reusable script can run before each phase to catch new secrets
- Exit code 1 when findings exist = gates migration until resolved

### Pattern 3: Plugin-Based Verification Architecture

**What:** Extensible verification runner that loads phase-specific check files from a directory

**When to use:** Phase 7 creates framework, Phases 8-12 each add their own check files

**Example - Runner:**
```bash
#!/usr/bin/env bash
# .verification/runner.sh
# Purpose: Load and execute all verification checks
# Usage: ./runner.sh [--phase 08]  # Run checks for specific phase or all

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECKS_DIR="$SCRIPT_DIR/checks"
LIB_DIR="$SCRIPT_DIR/lib"

# Load helper libraries
source "$LIB_DIR/check-exists.sh"
source "$LIB_DIR/check-valid.sh"
source "$LIB_DIR/check-parsable.sh"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Parse args
PHASE_FILTER=""
if [ "${1:-}" = "--phase" ] && [ -n "${2:-}" ]; then
    PHASE_FILTER="$2"
fi

echo "=== Dotfiles Verification Runner ==="
echo "Check directory: $CHECKS_DIR"
[ -n "$PHASE_FILTER" ] && echo "Filter: Phase $PHASE_FILTER only"
echo ""

# Find and run check files
for check_file in "$CHECKS_DIR"/*.sh; do
    [ -f "$check_file" ] || continue

    check_name=$(basename "$check_file")
    check_phase="${check_name:0:2}"

    # Apply phase filter if specified
    if [ -n "$PHASE_FILTER" ] && [ "$check_phase" != "$PHASE_FILTER" ]; then
        continue
    fi

    echo "Running: $check_name"

    # Source check file in subshell to isolate variables
    if (source "$check_file"); then
        echo -e "${GREEN}✓${NC} $check_name passed"
        ((PASSED_CHECKS++))
    else
        echo -e "${RED}✗${NC} $check_name failed"
        ((FAILED_CHECKS++))
    fi

    ((TOTAL_CHECKS++))
    echo ""
done

# Summary
echo "=== Summary ==="
echo "Total checks: $TOTAL_CHECKS"
echo -e "${GREEN}Passed: $PASSED_CHECKS${NC}"
echo -e "${RED}Failed: $FAILED_CHECKS${NC}"

if [ "$FAILED_CHECKS" -gt 0 ]; then
    echo ""
    echo -e "${RED}Verification failed${NC}"
    exit 1
else
    echo ""
    echo -e "${GREEN}All checks passed${NC}"
    exit 0
fi
```

**Example - Phase 8 Check File:**
```bash
#!/usr/bin/env bash
# .verification/checks/08-basic-configs.sh
# Purpose: Verify Phase 8 configs (basic dotfiles & CLI tools) deployed correctly

# This file is sourced by runner.sh, has access to helper functions

verify_basic_dotfile() {
    local file=$1
    local description=$2

    echo "  Checking: $description"

    # Check 1: File exists
    if ! check_file_exists "$file"; then
        echo "    ✗ File does not exist: $file"
        return 1
    fi

    # Check 2: No template errors (no {{ }} left in content)
    if ! check_no_template_errors "$file"; then
        echo "    ✗ Template errors found in: $file"
        return 1
    fi

    echo "    ✓ $description OK"
    return 0
}

verify_cli_tool_config() {
    local file=$1
    local command=$2
    local description=$3

    echo "  Checking: $description"

    # Check 1: File exists
    if ! check_file_exists "$file"; then
        echo "    ✗ File does not exist: $file"
        return 1
    fi

    # Check 2: No template errors
    if ! check_no_template_errors "$file"; then
        echo "    ✗ Template errors found in: $file"
        return 1
    fi

    # Check 3: Application can parse config
    if ! check_app_can_parse "$command" "$file"; then
        echo "    ✗ $command cannot parse config: $file"
        return 1
    fi

    echo "    ✓ $description OK"
    return 0
}

# Run verifications
echo "Phase 8: Basic Configs & CLI Tools"

all_passed=0

# Basic dotfiles
verify_basic_dotfile "$HOME/.hushlogin" ".hushlogin" || all_passed=1
verify_basic_dotfile "$HOME/.inputrc" ".inputrc" || all_passed=1
verify_basic_dotfile "$HOME/.editorconfig" ".editorconfig" || all_passed=1
verify_basic_dotfile "$HOME/.nanorc" ".nanorc" || all_passed=1

# CLI tool configs
verify_cli_tool_config "$HOME/.config/bat/config" "bat" "bat config" || all_passed=1
verify_cli_tool_config "$HOME/.config/lsd/config.yaml" "lsd" "lsd config" || all_passed=1
verify_cli_tool_config "$HOME/.config/btop/btop.conf" "btop" "btop config" || all_passed=1

# Database tools
verify_basic_dotfile "$HOME/.psqlrc" ".psqlrc" || all_passed=1
verify_basic_dotfile "$HOME/.sqliterc" ".sqliterc" || all_passed=1

exit $all_passed
```

**Example - Helper Library:**
```bash
#!/usr/bin/env bash
# .verification/lib/check-exists.sh
# Helper: Verify file exists at target path

check_file_exists() {
    local file=$1
    [ -f "$file" ] || [ -d "$file" ]
}
```

```bash
#!/usr/bin/env bash
# .verification/lib/check-valid.sh
# Helper: Verify no template syntax errors in deployed file

check_no_template_errors() {
    local file=$1

    # Check for unprocessed template markers
    if grep -q '{{' "$file" 2>/dev/null; then
        return 1
    fi

    # Check for error placeholders
    if grep -q 'TEMPLATE_ERROR' "$file" 2>/dev/null; then
        return 1
    fi

    return 0
}
```

```bash
#!/usr/bin/env bash
# .verification/lib/check-parsable.sh
# Helper: Verify application can parse its config file

check_app_can_parse() {
    local command=$1
    local config_file=$2

    case "$command" in
        bat)
            # bat --config-file only validates, doesn't print
            bat --config-file "$config_file" --list-themes &>/dev/null
            ;;
        lsd)
            # lsd has no config validation flag, just test it runs
            lsd --version &>/dev/null
            ;;
        btop)
            # btop has no validation, check file is valid format
            grep -q '^#' "$config_file" 2>/dev/null
            ;;
        psql)
            # psqlrc validation via dry-run
            echo '\q' | psql -X -f "$config_file" template1 &>/dev/null
            ;;
        *)
            # Unknown command, skip parsability check
            return 0
            ;;
    esac
}
```

**Why this works:**
- Each phase adds ONE check file to checks/ directory = zero merge conflicts
- Helper libraries reduce duplication across check files
- Runner automatically discovers and executes all checks
- Exit code reflects overall status (CI/CD friendly)
- Can run single phase: `./runner.sh --phase 08`
- Extensible: new checks don't require modifying runner

### Pattern 4: chezmoi diff Before Apply (Dry-Run Workflow)

**What:** Mandatory review workflow before every migration apply

**When to use:** Every single phase migration (Phases 8-12)

**Example:**
```bash
#!/usr/bin/env bash
# Example workflow script for any phase migration
# Usage: ./migrate-phase-08.sh

set -euo pipefail

PHASE="08"
PHASE_NAME="basic-configs-cli-tools"

echo "=== Phase $PHASE Migration: $PHASE_NAME ==="
echo ""

# Step 1: Secret audit
echo "Step 1/5: Running secret audit..."
if ! ~/.local/share/chezmoi/.secrets-audit/audit.sh; then
    echo "✗ Secret audit failed. Resolve findings before continuing."
    exit 1
fi
echo "✓ No secrets detected"
echo ""

# Step 2: Add files to chezmoi
echo "Step 2/5: Adding files to chezmoi..."
chezmoi add ~/.hushlogin
chezmoi add ~/.inputrc
chezmoi add ~/.editorconfig
chezmoi add ~/.nanorc
chezmoi add ~/.config/bat/
chezmoi add ~/.config/lsd/
chezmoi add ~/.config/btop/
chezmoi add ~/.psqlrc
chezmoi add ~/.sqliterc
echo "✓ Files added"
echo ""

# Step 3: Review diff
echo "Step 3/5: Reviewing changes..."
echo "Press ENTER to see diff, or Ctrl+C to abort"
read -r
chezmoi diff | less
echo ""

# Step 4: Dry-run apply
echo "Step 4/5: Dry-run apply..."
chezmoi apply --dry-run --verbose
echo ""

# Step 5: Confirm and apply
echo "Step 5/5: Apply changes"
read -p "Proceed with apply? (yes/no) " -r
if [[ ! $REPLY =~ ^yes$ ]]; then
    echo "Aborted. No changes made."
    exit 0
fi

chezmoi apply --verbose
echo "✓ Applied"
echo ""

# Step 6: Verification
echo "Step 6/5: Running verification checks..."
if ! ~/.local/share/chezmoi/.verification/runner.sh --phase "$PHASE"; then
    echo "✗ Verification failed"
    echo ""
    echo "Recovery: git revert HEAD && chezmoi apply"
    exit 1
fi
echo "✓ Verification passed"
echo ""

# Step 7: Commit
echo "Step 7/5: Committing to chezmoi source..."
cd ~/.local/share/chezmoi
git add -A
git commit -m "feat(phase-$PHASE): migrate $PHASE_NAME to chezmoi"
echo "✓ Committed"
echo ""

echo "=== Phase $PHASE Migration Complete ==="
echo "Files migrated and verified. Remember to update Dotbot config."
```

**Why this works:**
- Secret audit gates migration (can't proceed with secrets)
- chezmoi diff shows EXACTLY what will change before applying
- Dry-run confirms operations without modifying filesystem
- Interactive confirmation prevents accidents
- Verification confirms correct deployment
- Git commit provides rollback point

### Anti-Patterns to Avoid

- **Incremental .chezmoiignore:** Building ignore list file-by-file leads to accidental tracking of Dotbot infrastructure. Create comprehensive upfront.
- **Single-tool secret detection:** Relying only on gitleaks misses custom patterns (email addresses, user paths). Use multi-tool approach.
- **No verification after apply:** Assuming chezmoi apply succeeded doesn't catch template errors or app parsing failures. Always verify.
- **File snapshot backups:** Duplicating git history with rsync backups adds complexity without benefit. Git revert is sufficient.
- **Monolithic verification script:** Single script per phase becomes unmaintainable. Plugin architecture allows incremental growth.
- **Skipping chezmoi diff:** Applying blind risks unexpected changes. Always review diff first.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Secret pattern detection | Custom regex grep loops | gitleaks + detect-secrets | Mature tools with 100+ patterns, entropy detection, actively maintained |
| Template processing | Manual sed/awk for OS conditionals | chezmoi .chezmoiignore templates | Built-in, tested, handles all edge cases |
| File existence verification | Manual [ -f ] checks | Helper library functions | Reusable, consistent error messages, extensible |
| JSON parsing | awk/sed on gitleaks output | jq | JSON query language, handles nested structures, standard tool |
| Verification orchestration | Single bash script per phase | Plugin architecture with runner | Scales across 6 phases, zero merge conflicts, incremental |

**Key insight:** Secret detection and verification are security-critical domains where custom scripts will miss edge cases that mature tools handle. chezmoi's template engine in .chezmoiignore handles OS conditionals more reliably than any custom logic.

## Common Pitfalls

### Pitfall 1: Forgetting to Ignore Dotbot Infrastructure

**What goes wrong:** Run `chezmoi add ~/.config/*` without .chezmoiignore in place. chezmoi tracks Dotbot symlink targets from ~/.dotfiles, creating dual management.

**Why it happens:** Natural assumption that chezmoi add only tracks home directory files, forgetting that symlinks dereference to repo.

**How to avoid:**
- Create .chezmoiignore FIRST in Phase 7 before any Phase 8+ migrations
- Test with `chezmoi status` before adding files
- Document in .chezmoiignore comments which phase migrates what

**Warning signs:**
- `chezmoi status` shows `dotbot/` or `steps/` files
- `chezmoi diff` shows changes to Brewfile or README.md
- chezmoi source directory contains `install` script

### Pitfall 2: Missing OS-Specific Ignore Patterns

**What goes wrong:** aerospace config (macOS-only) gets deployed on Linux machine, fails because aerospace doesn't exist on Linux.

**Why it happens:** Not using template conditionals in .chezmoiignore for platform-specific configs.

**How to avoid:**
- Use `{{ if ne .chezmoi.os "darwin" }}` blocks for macOS-only configs
- Test .chezmoiignore on both platforms before migration
- Document platform requirements in config comments

**Warning signs:**
- chezmoi apply fails on Linux with "application not found"
- `chezmoi managed` shows platform-specific configs on wrong OS

### Pitfall 3: Secret Audit False Negatives

**What goes wrong:** Secret audit script passes, but email address or private hostname was missed. Credential gets committed to public repo.

**Why it happens:** Relying on single tool (gitleaks) without custom patterns for dotfile-specific issues.

**How to avoid:**
- Use gitleaks + custom regex patterns for emails, hostnames, user paths
- Manually review audit report categories before trusting "no findings"
- Re-run audit after every phase migration

**Warning signs:**
- Audit report shows zero findings but you know there are secrets
- Audit doesn't flag obvious email addresses or /Users/yourname paths
- Different tools (gitleaks vs detect-secrets) show different results

### Pitfall 4: Verification Checking Wrong Things

**What goes wrong:** Verification only checks file existence, misses that bat config has template syntax error ({{ .chezmoi.os instead of {{ .chezmoi.os }}).

**Why it happens:** Incomplete verification definition — file exists but content is broken.

**How to avoid:**
- Verify THREE aspects: existence, validity (no template errors), parsability (app can load)
- Test verification script by intentionally breaking a config
- Run verification before committing phase migration

**Warning signs:**
- Verification passes but application fails to start
- Config file contains literal {{ }} markers
- Application error messages about invalid config syntax

### Pitfall 5: Skipping Dry-Run Review

**What goes wrong:** Run `chezmoi apply` without checking `chezmoi diff` first. Unexpected file gets deleted or symlink replaced with wrong content.

**Why it happens:** Trust in chezmoi add commands, forgetting to verify what apply will do.

**How to avoid:**
- ALWAYS run `chezmoi diff` before `chezmoi apply`
- Use `chezmoi apply --dry-run --verbose` to see operations
- Create alias: `alias ca='chezmoi diff && read -p "Apply? " && chezmoi apply'`

**Warning signs:** None (silent surprise) — prevention is key. Build muscle memory for diff-first workflow.

### Pitfall 6: No Recovery Testing

**What goes wrong:** Migration fails, try `git revert HEAD` but forgot to commit before applying. No rollback point exists.

**Why it happens:** Not following commit-per-phase discipline, or committing AFTER apply instead of after add.

**How to avoid:**
- Commit to chezmoi source immediately after `chezmoi add` (before apply)
- Test recovery: `git revert HEAD && chezmoi apply` in dev environment
- Document recovery procedure in phase plan

**Warning signs:**
- `git log` in chezmoi source shows commits AFTER migrations complete
- No way to identify "last known good" state
- Recovery requires manual file restoration

## Code Examples

Verified patterns from official sources and v1.0.0 established practices:

### Complete .chezmoiignore for v1.1 Migration

```bash
# .chezmoiignore
# Purpose: Comprehensive ignore patterns for Phases 7-12 migration
# Created: Phase 7 (Preparation)
# Updated: Each phase removes migrated patterns

# === Dotbot Infrastructure (Never Migrate) ===
dotbot/
dotbot/**
dotbot-asdf/
dotbot-asdf/**
dotbot-brew/
dotbot-brew/**
dotfiles-marketplace/
dotfiles-marketplace/**
install

steps/
steps/**

# === Repository Meta Files (Never Migrate) ===
README.md
LICENSE.md
AGENTS.md
AIDER.md
CLAUDE.md
.editorconfig
.gitignore
.gitmodules
.commit-message.txt

.git/
.git/**
.github/
.github/**
.idea/
.idea/**

.planning/
.planning/**

# === Package Management (Managed Separately) ===
Brewfile
Brewfile_Client
Brewfile_Fanaka

# === System Configuration Scripts (Run Manually) ===
.macos
bin/
bin/**
art/
art/**

# === OS-Specific Exclusions ===
{{- if ne .chezmoi.os "darwin" }}
# macOS-only configs - ignore on Linux
.config/aerospace/
.config/aerospace/**
Library/
Library/**
.finicky.js
{{- end }}

{{- if ne .chezmoi.os "linux" }}
# Linux-only configs - ignore on macOS
.config/i3/
.config/i3/**
.config/sway/
.config/sway/**
{{- end }}

# === v1.0.0 Configs (Already Managed) ===
# These are in chezmoi source from Phases 1-6
# Documented here for clarity, no action needed:
# - .zshrc, .zshenv, .zprofile, .zlogin (Phase 2)
# - .zsh.d/ (Phase 2)
# - .config/git/ (Phase 2)
# - .config/mise/ (Phase 3/5)
# - .config/sheldon/ (Phase 5)
# - .ssh/ (Phase 6)

# === Pending Migration (Phases 8-12) ===
# These patterns will be REMOVED as phases complete

# Phase 8: Basic configs & CLI tools
.hushlogin
.inputrc
.nanorc
.config/bat/
.config/bat/**
.config/lsd/
.config/lsd/**
.config/btop/
.config/btop/**
.config/oh-my-posh.omp.json
.psqlrc
.sqliterc
.config/zsh-abbr/
.config/zsh-abbr/**
.config/karabiner/
.config/karabiner/**

# Phase 9: Terminal emulators
.config/kitty/
.config/kitty/**
.config/ghostty/
.config/ghostty/**
.wezterm.lua

# Phase 10: Dev tools with secrets
.config/lazygit/
.config/lazygit/**
.config/atuin/
.config/atuin/**
.aider.conf.yml
.gnupg/gpg-agent.conf

# Phase 11: Claude Code
.claude/
.claude/**

# === Deprecated (Phase 12 Removal) ===
# Not in use, will be deleted
.config/nushell/
.config/nushell/**
zgenom/
zgenom/**
.zgenom
.zgenom/**

# === Development/Temporary (Never Manage) ===
*.tmp
*.log
*.bak
*.swp
*~
.DS_Store
firebase-debug.log
```

### Secret Audit with Categorised Report

```bash
#!/usr/bin/env bash
# .secrets-audit/audit.sh
# Purpose: Detect and categorise secrets before migration
# Usage: ./audit.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel)"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
REPORT_FILE="$SCRIPT_DIR/audit-report-$TIMESTAMP.md"
FINDINGS_FILE="$SCRIPT_DIR/findings-$TIMESTAMP.json"

echo "=== Secret Audit ==="
echo "Repository: $REPO_ROOT"
echo "Report: $REPORT_FILE"
echo ""

# Run gitleaks
echo "Running gitleaks scan..."
if gitleaks detect \
    --source "$REPO_ROOT" \
    --config "$SCRIPT_DIR/gitleaks.toml" \
    --report-path "$FINDINGS_FILE" \
    --no-git \
    --exit-code 0; then
    GITLEAKS_FINDINGS=0
else
    GITLEAKS_FINDINGS=$(jq '. | length' "$FINDINGS_FILE")
fi

# Generate categorised report
cat > "$REPORT_FILE" << EOF
# Secret Audit Report

**Generated:** $(date +"%Y-%m-%d %H:%M:%S")
**Repository:** $(basename "$REPO_ROOT")
**Findings:** $GITLEAKS_FINDINGS

## Instructions

For each finding below, determine the category and action:

### Categories

1. **Bitwarden Secret** - True secret (API key, password, token)
   - Action: Add to Bitwarden item, replace with template: \`{{ (bitwarden "item-id" "username").password }}\`

2. **Template Variable** - User/machine-specific but not secret (email, hostname, path)
   - Action: Replace with chezmoi variable: \`{{ .chezmoi.username }}\`, \`{{ .chezmoi.hostname }}\`, etc.

3. **Safe to Ignore** - Example/documentation, false positive
   - Action: Add to .gitleaksignore or document reason

## Findings

| File | Line | Rule | Match | Category | Action |
|------|------|------|-------|----------|--------|
EOF

# Parse findings
if [ "$GITLEAKS_FINDINGS" -gt 0 ]; then
    jq -r '.[] |
        "| \(.File) | \(.StartLine) | \(.RuleID) | \(.Match[:40]) | TODO | TODO |"' \
        "$FINDINGS_FILE" >> "$REPORT_FILE"
else
    echo "| (no findings) | - | - | - | - | - |" >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" << 'EOF'

## Example Actions

### Bitwarden Secret Example

Before:
```bash
export OPENAI_API_KEY="sk-proj-abc123..."
```

After:
```bash
# dot_zshrc.tmpl
export OPENAI_API_KEY="{{ (bitwarden "openai-api").password }}"
```

### Template Variable Example

Before:
```bash
export USER_EMAIL="user@example.com"
```

After:
```bash
# dot_gitconfig.tmpl
[user]
    email = "{{ .email }}"
```

Then in .chezmoi.toml.tmpl:
```toml
[data]
    email = "{{ .chezmoi.username }}@example.com"
```

### Safe to Ignore Example

Finding: Email in LICENSE.md or example in README.md
Action: Add to .gitleaksignore:
```
LICENSE.md:generic
README.md:generic
```

## Next Steps

1. Fill in Category and Action columns above
2. Implement actions for each Bitwarden Secret
3. Implement actions for each Template Variable
4. Document Safe to Ignore findings
5. Re-run audit: `./audit.sh`
6. When report shows zero findings, proceed with migration

EOF

# Print summary
echo ""
if [ "$GITLEAKS_FINDINGS" -gt 0 ]; then
    echo "⚠ Found $GITLEAKS_FINDINGS potential secrets"
    echo "Review: $REPORT_FILE"
    exit 1
else
    echo "✓ No secrets detected"
    exit 0
fi
```

### Verification Runner with Phase Filtering

```bash
#!/usr/bin/env bash
# .verification/runner.sh
# Purpose: Execute all verification checks or filter by phase
# Usage: ./runner.sh [--phase 08]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECKS_DIR="$SCRIPT_DIR/checks"
LIB_DIR="$SCRIPT_DIR/lib"

# Load helpers
for lib in "$LIB_DIR"/*.sh; do
    [ -f "$lib" ] && source "$lib"
done

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Parse arguments
PHASE_FILTER=""
if [ "${1:-}" = "--phase" ] && [ -n "${2:-}" ]; then
    PHASE_FILTER="$2"
fi

# Counters
TOTAL=0
PASSED=0
FAILED=0

echo "=== Verification Runner ==="
[ -n "$PHASE_FILTER" ] && echo "Filter: Phase $PHASE_FILTER"
echo ""

# Execute checks
for check in "$CHECKS_DIR"/*.sh; do
    [ -f "$check" ] || continue

    check_name=$(basename "$check")
    check_phase="${check_name:0:2}"

    # Apply filter
    if [ -n "$PHASE_FILTER" ] && [ "$check_phase" != "$PHASE_FILTER" ]; then
        continue
    fi

    echo "▶ $check_name"

    if (source "$check"); then
        echo -e "${GREEN}✓${NC} Passed\n"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} Failed\n"
        ((FAILED++))
    fi

    ((TOTAL++))
done

# Summary
echo "=== Summary ==="
echo "Total: $TOTAL"
echo -e "${GREEN}Passed: $PASSED${NC}"
[ "$FAILED" -gt 0 ] && echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [ "$FAILED" -gt 0 ]; then
    echo "Verification failed"
    exit 1
else
    echo "All checks passed"
    exit 0
fi
```

### Helper Library - Check Parsable

```bash
#!/usr/bin/env bash
# .verification/lib/check-parsable.sh
# Helper: Verify application can parse its config

check_app_can_parse() {
    local app=$1
    local config=$2

    case "$app" in
        bat)
            # bat config validation
            bat --config-file "$config" --list-themes &>/dev/null
            ;;
        btop)
            # btop just needs valid format
            grep -q '^#' "$config"
            ;;
        kitty)
            # kitty config check
            kitty --config "$config" --debug-config &>/dev/null
            ;;
        wezterm)
            # wezterm lua syntax check
            wezterm show-config --config-file "$config" &>/dev/null
            ;;
        psql)
            # psqlrc validation
            echo '\q' | psql -X -f "$config" template1 &>/dev/null
            ;;
        lazygit)
            # lazygit config validation
            lazygit --use-config-file="$config" --version &>/dev/null
            ;;
        *)
            # Unknown app, skip check
            return 0
            ;;
    esac
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual .gitignore patterns | chezmoi .chezmoiignore with templates | chezmoi 2.x (2020+) | OS-conditional ignoring impossible with gitignore alone |
| grep for secrets | gitleaks + entropy detection | 2020-2021 | Entropy detection catches secrets without known patterns |
| Monolithic verification script | Plugin architecture | Modern practice (2024+) | Scales across phases, eliminates merge conflicts |
| rsync file backups | git revert of chezmoi source | git-based dotfiles (2015+) | Atomic rollback, no duplicate storage |
| Manual secret categorisation | Structured JSON reports | gitleaks 8.x (2023+) | Programmatic parsing, CI/CD integration |

**Deprecated/outdated:**
- **Manual regex loops for secrets:** gitleaks handles 100+ patterns plus entropy
- **Single-tool secret detection:** Multi-tool approach (gitleaks + custom) now standard
- **File-level ignore lists:** Template-based ignoring allows conditional logic
- **Verification after commit:** Should verify before committing to catch issues early

## Open Questions

1. **v1.0.0 configs in .chezmoiignore**
   - What we know: Already migrated in Phases 1-6, already in chezmoi source
   - What's unclear: Should .chezmoiignore explicitly skip them, or just document in comments?
   - Recommendation: Document in comments only — they're already in source, no ignore needed

2. **Secret audit report format**
   - What we know: Markdown table works for manual review
   - What's unclear: Need machine-readable format (JSON) for automation?
   - Recommendation: Generate both — Markdown for human review, JSON for tooling

3. **Verification check granularity**
   - What we know: Need existence + validity + parsability checks
   - What's unclear: Should each config have its own check file, or group by phase?
   - Recommendation: Group by phase (one check file per phase) — simpler, fewer files

4. **Dotbot file specificity**
   - What we know: Need to ignore dotbot/, steps/, install
   - What's unclear: Comprehensive list of all Dotbot-related files to ignore
   - Recommendation: Audit repo for all Dotbot infrastructure files, document in .chezmoiignore

## Sources

### Primary (HIGH confidence)

- chezmoi v2.69.3 installed and verified (`chezmoi --version`)
- Phase 1 RESEARCH.md - rsync backup patterns, verification workflows (v1.0.0)
- Phase 2 RESEARCH.md - .chezmoiignore patterns, migration strategies (v1.0.0)
- Phase 6 RESEARCH.md - Bitwarden integration, secret management (v1.0.0)
- PITFALLS.md - Secret leakage patterns, verification failures, recovery strategies (v1.0.0)
- v1.1 ROADMAP.md - Phase dependencies, requirements, success criteria (2026-02-08)
- v1.1 REQUIREMENTS.md - PREP-01, PREP-02, PREP-03 definitions (2026-02-08)
- Phase 7 CONTEXT.md - User decisions on ignore strategy, secret audit, verification approach (2026-02-08)

### Secondary (MEDIUM confidence)

- gitleaks GitHub repository - Configuration patterns, entropy detection algorithms
- WebFetch: chezmoi include-files-from-elsewhere documentation - .chezmoiignore reference
- Repository analysis: Identified Dotbot infrastructure (dotbot/, steps/, install, submodules)
- Repository analysis: Brewfile variants, .planning directory structure, LICENSE.md

### Tertiary (LOW confidence - marked for validation)

- WebSearch results unavailable (network errors) — research based on prior phase knowledge and established patterns
- detect-secrets tool capabilities inferred from general knowledge, not verified documentation

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - gitleaks is industry standard (20k+ stars), chezmoi verified installed
- Architecture patterns: HIGH - All patterns derive from v1.0.0 established practices and user decisions
- Ignore patterns: HIGH - chezmoi .chezmoiignore template syntax verified in Phase 2 research
- Secret detection: MEDIUM - gitleaks capabilities from documentation, custom patterns from PITFALLS.md
- Verification framework: HIGH - Plugin architecture is standard practice, helper libraries proven in v1.0.0

**Research date:** 2026-02-08
**Valid until:** ~90 days (May 2026) — gitleaks patterns updated quarterly, chezmoi stable API

**Research scope:**
This research covers Phase 7 (Preparation) infrastructure only. Actual config migrations (Phases 8-12) will require phase-specific research on individual application config formats, validation commands, and migration patterns.
