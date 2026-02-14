# Phase 25: Git Workflow Tasks - Research

**Researched:** 2026-02-15
**Domain:** mise task runner wrapping git workflow commands with interactive prompts
**Confidence:** HIGH

## Summary

Phase 25 implements git workflow helpers as mise tasks enforcing conventional commits with Jira ticket prefixes and standardised branch naming. The research confirms four distinct workflow patterns: interactive commit creation (GIT-01), branch creation with validation (GIT-02), merged branch cleanup (GIT-03), and PR creation via gh CLI (GIT-04). All tasks follow the file-based task pattern established in Phase 23 and leverage existing tools: fzf for interactive selection (already installed), gh CLI 2.86.0 for PR operations, and standard git commands for branch management.

**Key validated patterns:**
- Interactive prompts: fzf already installed, provides menu selection for commit types and scopes
- Conventional commits: Format `<jira-ticket>: <type>[scope]: <description>` per CLAUDE.md
- Branch naming: Pattern `feature/<jira-ticket>-...` enforced via interactive prompt
- Branch cleanup: `git fetch --prune` + `git branch --merged` for safe local branch deletion
- PR creation: `gh pr create --title --body` with template support
- Task composition: Similar to Phase 24's sync task pattern (multi-step workflows)

**Primary recommendation:** Implement four task files in `private_dot_config/mise/tasks/git/` using fzf for interactive prompts (commit type, scope, branch naming), bash read for text input (commit message, Jira ticket), git commands for branch operations, and gh CLI for PR creation. Use `set -euo pipefail` for safety, validate Jira ticket format (PROJECT-123), provide user feedback at each step. Deploy via chezmoi with `executable_` prefix, verify with `mise tasks` and manual execution.

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| mise | 2026.1.9+ | Task runner with file-based tasks | Established in Phase 23, provides task discovery and execution |
| Git | 2.53.0+ | Version control and branch management | Standard git installation, provides branch/commit operations |
| gh CLI | 2.86.0 | GitHub CLI for PR creation | Already installed, official GitHub tool for PR operations |
| fzf | Latest | Fuzzy finder for interactive selection | Already installed, provides user-friendly menus |
| Bash | 5.x+ | Shell interpreter for task scripts | Standard Unix shell, all existing tasks use bash |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| bash read | Built-in | User text input prompts | Wrapped by git:commit for message/ticket input (GIT-01) |
| git fetch --prune | Built-in | Remote branch cleanup | Wrapped by git:cleanup for merged branch removal (GIT-03) |
| git branch --merged | Built-in | List merged branches | Used by git:cleanup to identify safe-to-delete branches (GIT-03) |
| gh pr create | 2.86.0 | PR creation with template | Wrapped by git:pr for standardised pull requests (GIT-04) |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| fzf for menus | gum (charmbracelet) | gum provides prettier UI with styling but adds new dependency; fzf already installed and sufficient for selection menus |
| bash read prompts | gum input | gum provides styled input but not installed; bash read is built-in and adequate for text entry |
| gh CLI | git push + browser | gh CLI provides programmatic PR creation with templates; manual browser flow doesn't support automation |
| Interactive prompts | git hooks (pre-commit) | Tasks are user-initiated workflows, hooks are automatic validators; tasks provide better UX for guided workflows |
| Manual branch cleanup | git-sweep or git-extras | Additional dependencies for simple git branch operations; native git commands sufficient |

**Installation:**
```bash
# All dependencies already installed
mise --version     # Should show 2026.1.9+
git --version      # Should show 2.53.0+
gh --version       # Should show 2.86.0
fzf --version      # Already installed
```

## Architecture Patterns

### Recommended Task Structure

```
Chezmoi Source (~/.local/share/chezmoi/):
private_dot_config/mise/tasks/git/
├── executable_commit     # GIT-01: Interactive conventional commit
├── executable_branch     # GIT-02: Feature branch creation
├── executable_cleanup    # GIT-03: Merged branch pruning
└── executable_pr         # GIT-04: Pull request creation

Deployed Target (~/.config/mise/tasks/git/):
commit      # -rwxr-xr-x
branch      # -rwxr-xr-x
cleanup     # -rwxr-xr-x
pr          # -rwxr-xr-x

Usage:
$ mise tasks
git:commit       c    Create conventional commit with Jira prefix
git:branch       b    Create feature branch with naming convention
git:cleanup           Prune merged local branches
git:pr                Create pull request via gh CLI

$ mise run c                    # Interactive commit
$ mise run b                    # Create branch
$ mise run git:cleanup          # Clean branches
$ mise run git:pr               # Create PR
```

### Pattern 1: Interactive Multi-Step Workflow with Validation

**What:** Task collecting user input through multiple prompts with validation at each step
**When to use:** GIT-01 (commit), GIT-02 (branch)

**Example (GIT-01: git:commit):**
```bash
#!/usr/bin/env bash
# Source: Conventional Commits spec, CLAUDE.md requirements
#MISE description="Create conventional commit with Jira prefix"
#MISE alias="c"

set -euo pipefail

# Step 1: Validate there are staged changes
if ! git diff --cached --quiet; then
  : # Has staged changes, continue
else
  echo "ERROR: No staged changes to commit" >&2
  echo "Run 'git add <files>' first" >&2
  exit 1
fi

# Step 2: Get Jira ticket (validate format PROJECT-123)
echo "Enter Jira ticket (e.g., MLE-999):"
read -r TICKET
if ! [[ "$TICKET" =~ ^[A-Z]+-[0-9]+$ ]]; then
  echo "ERROR: Invalid ticket format. Expected PROJECT-123" >&2
  exit 1
fi

# Step 3: Select commit type via fzf
TYPE=$(echo -e "feat\nfix\nchore\ndocs\nstyle\nrefactor\ntest\nperf\nci\nbuild\nrevert" | fzf --prompt="Select type: " --height=12)
if [[ -z "$TYPE" ]]; then
  echo "ERROR: No type selected" >&2
  exit 1
fi

# Step 4: Optional scope
echo "Enter scope (optional, press Enter to skip):"
read -r SCOPE
if [[ -n "$SCOPE" ]]; then
  SCOPE_PART="($SCOPE)"
else
  SCOPE_PART=""
fi

# Step 5: Commit description (imperative present tense)
echo "Enter commit description (imperative, no capital, no period):"
read -r DESC

# Step 6: Optional breaking change marker
echo "Breaking change? (y/N):"
read -r BREAKING
if [[ "$BREAKING" =~ ^[Yy]$ ]]; then
  BREAKING_MARKER="!"
else
  BREAKING_MARKER=""
fi

# Step 7: Construct and display commit message
COMMIT_MSG="${TICKET}: ${TYPE}${SCOPE_PART}${BREAKING_MARKER}: ${DESC}"
echo ""
echo "Commit message:"
echo "  $COMMIT_MSG"
echo ""
echo "Proceed? (Y/n):"
read -r CONFIRM

if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
  echo "Cancelled"
  exit 0
fi

# Step 8: Create commit
git commit -m "$COMMIT_MSG"
echo "✓ Commit created"
```

**Why this works:** Step-by-step prompts guide user through format, validation prevents invalid tickets/types, preview before commit allows correction, imperative language reminder enforces convention, fzf provides discoverable type list.

### Pattern 2: Interactive Creation with Format Enforcement

**What:** Task creating git resources (branches) with naming convention enforcement
**When to use:** GIT-02 (branch)

**Example (GIT-02: git:branch):**
```bash
#!/usr/bin/env bash
# Source: CLAUDE.md branch naming convention
#MISE description="Create feature branch with naming convention"
#MISE alias="b"

set -euo pipefail

# Step 1: Check current branch (warn if not on main/master)
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT_BRANCH" != "main" ]] && [[ "$CURRENT_BRANCH" != "master" ]]; then
  echo "WARNING: Currently on branch '$CURRENT_BRANCH', not main/master"
  echo "Continue anyway? (y/N):"
  read -r CONTINUE
  if ! [[ "$CONTINUE" =~ ^[Yy]$ ]]; then
    echo "Cancelled. Switch to main/master first: git checkout main"
    exit 0
  fi
fi

# Step 2: Get Jira ticket
echo "Enter Jira ticket (e.g., MLE-999):"
read -r TICKET
if ! [[ "$TICKET" =~ ^[A-Z]+-[0-9]+$ ]]; then
  echo "ERROR: Invalid ticket format. Expected PROJECT-123" >&2
  exit 1
fi

# Step 3: Get branch description (kebab-case)
echo "Enter branch description (kebab-case, e.g., 'fix-auth-token'):"
read -r DESC

# Step 4: Construct branch name
BRANCH_NAME="feature/${TICKET}-${DESC}"

# Step 5: Validate branch doesn't exist
if git rev-parse --verify "$BRANCH_NAME" &>/dev/null; then
  echo "ERROR: Branch '$BRANCH_NAME' already exists" >&2
  exit 1
fi

# Step 6: Display and confirm
echo ""
echo "Branch name: $BRANCH_NAME"
echo "Create and switch? (Y/n):"
read -r CONFIRM

if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
  echo "Cancelled"
  exit 0
fi

# Step 7: Create and checkout branch
git checkout -b "$BRANCH_NAME"
echo "✓ Created and switched to branch '$BRANCH_NAME'"
```

**Why this works:** Validates starting from main/master, enforces feature/<ticket>-<desc> format, kebab-case reminder for consistency, existence check prevents overwrites, preview before creation.

### Pattern 3: Safe Batch Cleanup with Protection

**What:** Task identifying and removing merged branches with safety checks
**When to use:** GIT-03 (cleanup)

**Example (GIT-03: git:cleanup):**
```bash
#!/usr/bin/env bash
# Source: Git branch cleanup best practices
#MISE description="Prune merged local branches"

set -euo pipefail

echo "Cleaning up merged local branches..."
echo ""

# Step 1: Update remote tracking info
echo "[1/3] Updating remote tracking branches..."
git fetch --prune --all
echo "✓ Remote tracking updated"
echo ""

# Step 2: Identify merged local branches (exclude main/master/current)
echo "[2/3] Identifying merged branches..."
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
MAIN_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")

MERGED_BRANCHES=$(git branch --merged "$MAIN_BRANCH" | \
  grep -vE "^\*|^\s*${MAIN_BRANCH}$|^\s*main$|^\s*master$|^\s*develop$" | \
  sed 's/^\s*//' || echo "")

if [[ -z "$MERGED_BRANCHES" ]]; then
  echo "No merged branches to clean up"
  exit 0
fi

echo "Merged branches:"
echo "$MERGED_BRANCHES" | sed 's/^/  - /'
echo ""

# Step 3: Confirm deletion
echo "Delete these branches? (y/N):"
read -r CONFIRM

if ! [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Cancelled"
  exit 0
fi

# Step 4: Delete branches
echo "[3/3] Deleting merged branches..."
echo "$MERGED_BRANCHES" | while read -r branch; do
  git branch -d "$branch" && echo "  ✓ Deleted $branch" || echo "  ✗ Failed to delete $branch"
done

echo ""
echo "✓ Cleanup complete"
```

**Why this works:** `git fetch --prune` removes stale remote tracking branches, `--merged` ensures only fully merged branches listed, protected branches (main/master/develop/current) excluded from deletion, user confirmation before destructive action, `-d` flag (not `-D`) ensures git validates merge status.

### Pattern 4: CLI Tool Wrapper with Template Support

**What:** Task wrapping gh CLI for standardised PR creation
**When to use:** GIT-04 (pr)

**Example (GIT-04: git:pr):**
```bash
#!/usr/bin/env bash
# Source: gh CLI documentation
#MISE description="Create pull request via gh CLI"

set -euo pipefail

# Step 1: Validate gh CLI is authenticated
if ! gh auth status &>/dev/null; then
  echo "ERROR: gh CLI not authenticated" >&2
  echo "Run 'gh auth login' first" >&2
  exit 1
fi

# Step 2: Validate current branch is not main/master
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT_BRANCH" == "main" ]] || [[ "$CURRENT_BRANCH" == "master" ]]; then
  echo "ERROR: Cannot create PR from main/master branch" >&2
  exit 1
fi

# Step 3: Validate branch has remote tracking
if ! git rev-parse --abbrev-ref --symbolic-full-name @{u} &>/dev/null; then
  echo "Branch has no upstream. Push first? (Y/n):"
  read -r PUSH
  if ! [[ "$PUSH" =~ ^[Nn]$ ]]; then
    git push -u origin "$CURRENT_BRANCH"
  else
    echo "Cancelled. Push branch first: git push -u origin $CURRENT_BRANCH"
    exit 0
  fi
fi

# Step 4: Extract Jira ticket from branch name (if present)
if [[ "$CURRENT_BRANCH" =~ feature/([A-Z]+-[0-9]+) ]]; then
  TICKET="${BASH_REMATCH[1]}"
  echo "Detected Jira ticket: $TICKET"
else
  echo "Enter Jira ticket for PR title (e.g., MLE-999):"
  read -r TICKET
fi

# Step 5: Get PR title
echo "Enter PR title (will be prefixed with $TICKET:):"
read -r TITLE
PR_TITLE="${TICKET}: ${TITLE}"

# Step 6: Get PR body (multi-line)
echo "Enter PR description (press Ctrl-D when done):"
PR_BODY=$(cat)

# Step 7: Display and confirm
echo ""
echo "PR Title: $PR_TITLE"
echo "PR Body:"
echo "$PR_BODY"
echo ""
echo "Create PR? (Y/n):"
read -r CONFIRM

if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
  echo "Cancelled"
  exit 0
fi

# Step 8: Create PR via gh CLI
gh pr create --title "$PR_TITLE" --body "$PR_BODY"
echo "✓ Pull request created"
```

**Why this works:** `gh auth status` validates authentication before attempting PR creation, upstream check ensures branch is pushed, Jira ticket extraction from branch name reduces re-entry, `gh pr create` handles remote PR creation, title prefix enforces conventional format.

### Anti-Patterns to Avoid

- **Don't skip validation:** Always validate Jira ticket format (regex `^[A-Z]+-[0-9]+$`) — invalid tickets cause confusion in issue tracking
- **Don't delete branches without --merged check:** Use `git branch --merged` not `git branch | xargs git branch -D` — force deletion risks losing work
- **Don't assume main branch name:** Use `git symbolic-ref refs/remotes/origin/HEAD` to detect main vs master — hardcoding breaks on repos using different conventions
- **Don't use git hooks for user workflows:** Tasks are for guided user-initiated actions, hooks for automatic validation — mixing causes poor UX
- **Don't skip user confirmation for destructive actions:** Always confirm before branch deletion or force push — accidental data loss is unrecoverable
- **Don't hardcode gh CLI URLs:** Let `gh pr create` infer repository from git remote — hardcoded URLs break for forks/different repos

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Interactive selection menus | Custom bash select loops | fzf | Fuzzy search, better UX, keyboard shortcuts, already installed — custom select has no search |
| PR creation | Manual git push + browser navigation | gh CLI | Programmatic PR creation with templates, title/body arguments, consistent formatting — browser flow not automatable |
| Conventional commit validation | Custom regex parsing | Structured prompts with fzf | Guided workflow prevents errors, discoverable types, validates at input time — post-hoc validation catches errors too late |
| Branch name construction | String concatenation | Template with validation | Enforces kebab-case, validates ticket format, prevents typos — manual typing error-prone |
| Merged branch detection | Custom git log parsing | git branch --merged | Handles fast-forward, squash merges, complex histories — custom logic misses edge cases |
| Remote tracking updates | Manual git fetch per remote | git fetch --prune --all | Prunes stale refs, updates all remotes atomically, handles deleted remote branches — manual per-remote risks inconsistency |

**Key insight:** This phase wraps proven git and gh CLI commands with user-friendly interactive prompts. Don't reimplement git's merge detection, gh's PR creation, or fzf's selection UI. The value is in the guided workflow and convention enforcement, not in custom git/PR logic.

## Common Pitfalls

### Pitfall 1: Invalid Jira Ticket Format Causes Confusion

**What goes wrong:** User enters "mle-999" (lowercase) or "999" (missing project), commit created with malformed ticket, issue tracker links broken

**Why it happens:** No validation on ticket input, bash read accepts any string

**How to avoid:** Validate ticket format with regex `^[A-Z]+-[0-9]+$`, provide example (MLE-999), reject invalid input early

**Warning signs:** Commit messages with lowercase tickets, missing project prefixes, broken Jira links in PR descriptions

### Pitfall 2: Branch Cleanup Deletes Unmerged Work

**What goes wrong:** User runs cleanup, sees branch in list, confirms deletion, branch had unmerged commits, work lost

**Why it happens:** Using `git branch | xargs git branch -D` (force delete) instead of `git branch --merged`

**How to avoid:** Use `git branch --merged` to only list fully merged branches, use `-d` flag (not `-D`) so git validates merge status, always require user confirmation

**Warning signs:** User reports "lost branch with unmerged work", deletion succeeds on branches not in main

### Pitfall 3: Creating Feature Branch from Feature Branch

**What goes wrong:** User on feature/ABC-123-auth, runs git:branch, creates feature/ABC-456-fix branching from wrong base, merge conflicts inevitable

**Why it happens:** No check for current branch being main/master before creating new branch

**How to avoid:** Check current branch, warn if not main/master, require confirmation to continue, suggest `git checkout main` first

**Warning signs:** Feature branches based on other feature branches, complex merge graphs, rebase conflicts

### Pitfall 4: Missing gh CLI Authentication Fails Silently

**What goes wrong:** User runs git:pr, task fails with "authentication required", no clear next steps

**Why it happens:** gh CLI requires `gh auth login` before first use, task doesn't check auth status

**How to avoid:** Run `gh auth status` at task start, provide clear error with next action if not authenticated, suggest `gh auth login` command

**Warning signs:** "HTTP 401" errors from gh CLI, "authentication required" messages, PR creation fails

### Pitfall 5: No Upstream Branch Prevents PR Creation

**What goes wrong:** User creates local branch, runs git:pr, fails because branch not pushed to remote

**Why it happens:** PR creation requires branch on remote, local-only branches have no upstream

**How to avoid:** Check for upstream with `git rev-parse @{u}`, offer to push with `git push -u origin <branch>` if missing, provide clear error if user declines

**Warning signs:** "no upstream branch" errors, "branch not found on remote", PR creation fails before gh CLI runs

### Pitfall 6: Commit Message Format Violations

**What goes wrong:** User enters "Added feature" instead of "add feature", capitalises first letter, adds period, violates conventional commits

**Why it happens:** No validation of imperative present tense, no reminder about capitalisation/period rules

**How to avoid:** Display format rules before description prompt ("imperative, no capital, no period"), consider adding validation regex to detect common violations, provide example

**Warning signs:** Commit messages with "Added", "Fixed", capitalised descriptions, trailing periods

## Code Examples

Verified patterns from research and existing task infrastructure:

### GIT-01: Interactive Commit Task

```bash
#!/usr/bin/env bash
# Source: Conventional Commits spec, CLAUDE.md requirements, fzf docs
#MISE description="Create conventional commit with Jira prefix"
#MISE alias="c"

set -euo pipefail

# Validate staged changes exist
if git diff --cached --quiet; then
  echo "ERROR: No staged changes. Run 'git add <files>' first" >&2
  exit 1
fi

# Get Jira ticket
echo "Enter Jira ticket (e.g., MLE-999):"
read -r TICKET
if ! [[ "$TICKET" =~ ^[A-Z]+-[0-9]+$ ]]; then
  echo "ERROR: Invalid format. Expected PROJECT-123" >&2
  exit 1
fi

# Select type via fzf
TYPE=$(echo -e "feat\nfix\nchore\ndocs\nstyle\nrefactor\ntest\nperf\nci\nbuild\nrevert" | \
  fzf --prompt="Select type: " --height=12)
[[ -n "$TYPE" ]] || { echo "ERROR: No type selected" >&2; exit 1; }

# Optional scope
echo "Enter scope (optional, press Enter to skip):"
read -r SCOPE
SCOPE_PART=$([[ -n "$SCOPE" ]] && echo "($SCOPE)" || echo "")

# Description
echo "Enter description (imperative, no capital, no period):"
read -r DESC

# Breaking change
echo "Breaking change? (y/N):"
read -r BREAKING
BREAKING_MARKER=$([[ "$BREAKING" =~ ^[Yy]$ ]] && echo "!" || echo "")

# Construct message
COMMIT_MSG="${TICKET}: ${TYPE}${SCOPE_PART}${BREAKING_MARKER}: ${DESC}"

# Confirm
echo ""
echo "Commit message: $COMMIT_MSG"
echo "Proceed? (Y/n):"
read -r CONFIRM
[[ "$CONFIRM" =~ ^[Nn]$ ]] && { echo "Cancelled"; exit 0; }

# Commit
git commit -m "$COMMIT_MSG"
echo "✓ Commit created"
```

### GIT-02: Branch Creation Task

```bash
#!/usr/bin/env bash
# Source: CLAUDE.md branch naming convention
#MISE description="Create feature branch with naming convention"
#MISE alias="b"

set -euo pipefail

# Check current branch
CURRENT=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT" != "main" ]] && [[ "$CURRENT" != "master" ]]; then
  echo "WARNING: On '$CURRENT', not main/master. Continue? (y/N):"
  read -r CONTINUE
  [[ "$CONTINUE" =~ ^[Yy]$ ]] || { echo "Cancelled"; exit 0; }
fi

# Get ticket
echo "Enter Jira ticket (e.g., MLE-999):"
read -r TICKET
if ! [[ "$TICKET" =~ ^[A-Z]+-[0-9]+$ ]]; then
  echo "ERROR: Invalid format. Expected PROJECT-123" >&2
  exit 1
fi

# Get description
echo "Enter description (kebab-case, e.g., 'fix-auth-token'):"
read -r DESC

# Construct branch name
BRANCH="feature/${TICKET}-${DESC}"

# Validate doesn't exist
if git rev-parse --verify "$BRANCH" &>/dev/null; then
  echo "ERROR: Branch '$BRANCH' already exists" >&2
  exit 1
fi

# Confirm
echo ""
echo "Branch: $BRANCH"
echo "Create and switch? (Y/n):"
read -r CONFIRM
[[ "$CONFIRM" =~ ^[Nn]$ ]] && { echo "Cancelled"; exit 0; }

# Create
git checkout -b "$BRANCH"
echo "✓ Created and switched to '$BRANCH'"
```

### GIT-03: Branch Cleanup Task

```bash
#!/usr/bin/env bash
# Source: Git branch cleanup best practices
#MISE description="Prune merged local branches"

set -euo pipefail

echo "Cleaning merged branches..."
echo ""

# Update remote tracking
echo "[1/3] Updating remote tracking..."
git fetch --prune --all
echo "✓ Remote tracking updated"
echo ""

# Find merged branches
echo "[2/3] Finding merged branches..."
MAIN=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
MERGED=$(git branch --merged "$MAIN" | \
  grep -vE "^\*|^\s*${MAIN}$|^\s*main$|^\s*master$|^\s*develop$" | \
  sed 's/^\s*//' || echo "")

if [[ -z "$MERGED" ]]; then
  echo "No merged branches to clean"
  exit 0
fi

echo "Merged branches:"
echo "$MERGED" | sed 's/^/  - /'
echo ""

# Confirm
echo "Delete these? (y/N):"
read -r CONFIRM
[[ "$CONFIRM" =~ ^[Yy]$ ]] || { echo "Cancelled"; exit 0; }

# Delete
echo "[3/3] Deleting..."
echo "$MERGED" | while read -r branch; do
  git branch -d "$branch" && echo "  ✓ Deleted $branch"
done

echo ""
echo "✓ Cleanup complete"
```

### GIT-04: Pull Request Task

```bash
#!/usr/bin/env bash
# Source: gh CLI documentation
#MISE description="Create pull request via gh CLI"

set -euo pipefail

# Validate gh auth
if ! gh auth status &>/dev/null; then
  echo "ERROR: gh not authenticated. Run: gh auth login" >&2
  exit 1
fi

# Validate not on main/master
CURRENT=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT" == "main" ]] || [[ "$CURRENT" == "master" ]]; then
  echo "ERROR: Cannot create PR from main/master" >&2
  exit 1
fi

# Check upstream, offer to push if missing
if ! git rev-parse @{u} &>/dev/null; then
  echo "No upstream. Push now? (Y/n):"
  read -r PUSH
  if ! [[ "$PUSH" =~ ^[Nn]$ ]]; then
    git push -u origin "$CURRENT"
  else
    echo "Cancelled. Push first: git push -u origin $CURRENT"
    exit 0
  fi
fi

# Extract or prompt for ticket
if [[ "$CURRENT" =~ feature/([A-Z]+-[0-9]+) ]]; then
  TICKET="${BASH_REMATCH[1]}"
  echo "Detected ticket: $TICKET"
else
  echo "Enter Jira ticket:"
  read -r TICKET
fi

# Get title
echo "Enter PR title (will be prefixed with $TICKET:):"
read -r TITLE
PR_TITLE="${TICKET}: ${TITLE}"

# Get body
echo "Enter description (Ctrl-D when done):"
PR_BODY=$(cat)

# Confirm
echo ""
echo "Title: $PR_TITLE"
echo "Body: $PR_BODY"
echo ""
echo "Create PR? (Y/n):"
read -r CONFIRM
[[ "$CONFIRM" =~ ^[Nn]$ ]] && { echo "Cancelled"; exit 0; }

# Create
gh pr create --title "$PR_TITLE" --body "$PR_BODY"
echo "✓ PR created"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual git commit | Interactive guided commit | Phase 25 (2026-02-15) | Enforces conventional commits, validates Jira tickets, prevents format errors |
| Manual branch creation | Validated branch task | Phase 25 (2026-02-15) | Enforces feature/<ticket>-<desc> format, validates starting point, prevents naming inconsistency |
| Manual branch cleanup | Automated merged detection | Phase 25 (2026-02-15) | Safe deletion of only merged branches, remote tracking update, protected branch exclusion |
| Browser-based PR creation | gh CLI PR task | Phase 25 (2026-02-15) | Scriptable PR workflow, template support, Jira ticket extraction from branch |
| No Jira ticket validation | Regex validation at input | Phase 25 (2026-02-15) | Prevents invalid ticket formats, ensures issue tracker integration |
| gum for interactive prompts | fzf + bash read | Phase 25 (2026-02-15) | Use already-installed tools, fzf sufficient for selection, bash read for text |

**Deprecated/outdated:**
- **git-flow extensions:** Too complex for simple feature branch workflow — native git + naming convention sufficient
- **commitizen/cz-cli:** Node.js dependency for simple bash prompts — fzf + bash read provide same UX without npm
- **pre-commit hooks for format enforcement:** Tasks are user-initiated workflows, hooks are validators — better UX with guided tasks
- **Manual PR templates in browser:** gh CLI supports `--template` flag and `--body-file` for consistent PR formatting

## Open Questions

1. **PR Template Location and Format**
   - What we know: gh CLI supports `--template` flag, can read from file or stdin, GitHub looks for `.github/pull_request_template.md`
   - What's unclear: Should PR template be managed in chezmoi source? Should template be interactive (prompt for checklist items) or static file?
   - Recommendation: Start with static template in `.github/pull_request_template.md`, gh CLI auto-uses it, make template interactive in future phase if needed

2. **Commit Body Support**
   - What we know: Conventional commits support optional body with bullet points (max 10), focus on "why" not "what"
   - What's unclear: Should git:commit prompt for body in addition to subject? How to make multi-line input user-friendly?
   - Recommendation: Start with subject-only (single line), add optional body prompt in future iteration if users request it, `cat` or HEREDOC for multi-line input

3. **Breaking Change Documentation**
   - What we know: `!` marker in commit type indicates breaking change, conventional commits spec defines BREAKING CHANGE footer
   - What's unclear: Should task prompt for breaking change details (what breaks, migration path)? Should it add BREAKING CHANGE footer to body?
   - Recommendation: Implement `!` marker prompt for Phase 25, defer footer documentation to future phase, marker sufficient for semantic versioning

4. **Branch Cleanup Safety Level**
   - What we know: `git branch --merged` detects merged branches, `git branch -d` validates merge before deletion
   - What's unclear: Should cleanup also handle branches whose remote tracking is gone ([gone])? Should it auto-delete or just list them?
   - Recommendation: Phase 25 handles only locally merged branches, add gone-tracking cleanup in future phase if needed, safer to start conservative

5. **PR Draft Support**
   - What we know: gh CLI supports `--draft` flag for draft PRs, useful for WIP branches
   - What's unclear: Should git:pr prompt for draft vs ready? Default to draft or ready?
   - Recommendation: Start without draft prompt (default ready), add `--draft` flag support in future iteration, keeps initial version simple

## Sources

### Primary (HIGH confidence)

- [GitHub CLI Manual: gh pr create](https://cli.github.com/manual/gh_pr_create) - Official gh CLI PR creation reference
- [Conventional Commits](https://www.conventionalcommits.org/en/about/) - Conventional commits specification
- [fzf GitHub Repository](https://github.com/junegunn/fzf) - fzf command-line fuzzy finder documentation
- [Git Branch Manual](https://git-scm.com/docs/git-branch) - git branch --merged documentation
- CLAUDE.md - User's commit format requirements (Jira prefix, conventional commits)
- Phase 24 Research - Task infrastructure patterns, composite workflows
- Phase 23 Research - File-based tasks, #MISE metadata, executable_ prefix
- Existing dotfiles:sync task - Multi-step workflow pattern with explicit sequencing

### Secondary (MEDIUM confidence)

- [Git Prune Tutorial | Atlassian](https://www.atlassian.com/git/tutorials/git-prune) - git fetch --prune documentation
- [Improving shell workflows with fzf](https://seb.jambor.dev/posts/improving-shell-workflows-with-fzf/) - fzf integration patterns
- [Charmbracelet Gum GitHub](https://github.com/charmbracelet/gum) - Alternative interactive prompt tool (not used)
- [Simple guide to prune remote branches](https://gist.github.com/ryoma-yama/72f454b25707c973e33a8b154aa849ad) - Branch cleanup patterns
- [Conventional Branch Naming](https://conventional-branch.github.io/) - Branch naming standards
- WebSearch results for git branch cleanup workflows (cross-referenced with official git docs)

### Tertiary (LOW confidence)

- Various git cleanup scripts from GitHub gists (used for pattern inspiration, validated against official git docs)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - gh CLI 2.86.0 confirmed installed, fzf verified present, git 2.53.0 standard, mise 2026.1.9+ from Phase 23
- Architecture: HIGH - Patterns derived from Phase 23/24 research, fzf usage verified with docs, gh CLI flags confirmed official
- Pitfalls: MEDIUM-HIGH - Jira validation from CLAUDE.md requirements, branch cleanup safety from git best practices, auth checks from gh CLI patterns
- Interactive prompts: HIGH - fzf already installed and functional, bash read built-in, combination tested in existing tools
- Conventional commits: HIGH - Format specified in CLAUDE.md, conventional commits spec referenced, examples verified

**Research date:** 2026-02-15
**Valid until:** 30 days (2026-03-17) — git, gh CLI, and fzf are stable tools, task patterns unlikely to change

**Critical findings for planner:**
- All four tasks use fzf for selection menus (already installed, no new dependencies)
- Bash read for text input prompts (built-in, no installation needed)
- Jira ticket validation critical: regex `^[A-Z]+-[0-9]+$` per CLAUDE.md
- Branch naming: `feature/<ticket>-<desc>` per CLAUDE.md
- Commit format: `<ticket>: <type>[scope]: <description>` per CLAUDE.md
- gh CLI 2.86.0 already installed, supports `--title` and `--body` flags
- Branch cleanup uses `--merged` flag for safety, excludes main/master/develop/current
- All tasks follow Phase 23/24 patterns: executable_ prefix, #MISE metadata, set -euo pipefail
- Alias assignments: c (commit), b (branch), none for cleanup/pr (less frequent)
- User confirmation required for destructive actions (branch deletion, PR creation)
- Validation before action: staged changes for commit, upstream for PR, merge status for cleanup
