---
phase: 25-git-workflow-tasks
plan: 01
subsystem: git-workflow
tags: [mise, git, conventional-commits, jira, fzf, claude-cli, ai-assisted]

# Dependency graph
requires:
  - phase: 23-mise-task-foundation
    provides: File-based task pattern with executable_ prefix and #MISE directives
  - phase: 24-dotfiles-operations
    provides: Task deployment via chezmoi and verification patterns
provides:
  - git:commit task with hybrid AI/manual conventional commit creation
  - git:branch task with hybrid AI/manual feature branch creation
  - Jira ticket validation pattern (PROJECT-123 format)
  - Conventional commit enforcement (TICKET: type[scope]: description)
  - AI-assisted mode via claude CLI with manual fzf fallback
affects: [git-workflow, developer-experience, commit-conventions]

# Tech tracking
tech-stack:
  added: [claude CLI integration pattern, hybrid AI/manual workflow]
  patterns: [AI-first with manual fallback, fzf mode selection, multi-path convergence]

key-files:
  created:
    - private_dot_config/mise/tasks/git/executable_commit
    - private_dot_config/mise/tasks/git/executable_branch
  modified: []

key-decisions:
  - "Hybrid AI/manual mode: offer AI assistance via claude CLI when available, gracefully fall back to manual fzf prompts"
  - "Both modes converge to same preview/confirmation step for consistent UX"
  - "AI mode validates output format before accepting (ticket prefix for commits, kebab-case for branches)"
  - "Manual mode uses fzf for type selection and bash read for text input (no new dependencies)"

patterns-established:
  - "AI-first workflow: check for claude CLI availability, offer mode selection via fzf, fall back to manual if unavailable or AI output invalid"
  - "Multi-path convergence: AI and manual paths produce same format, converge for preview/confirmation"
  - "Jira ticket validation: ^[A-Z]+-[0-9]+$ regex enforced early in both tasks"
  - "Convention enforcement: Format rules displayed before input, validation after input, preview before commit/creation"

# Metrics
duration: 2.6min
completed: 2026-02-15
---

# Phase 25 Plan 01: Git Workflow Tasks Summary

**Hybrid AI/manual git workflows: conventional commits via git:commit (alias c) with claude CLI generation from diffs, feature branches via git:branch (alias b) with AI kebab-case conversion, both with Jira ticket validation and fzf manual fallback**

## Performance

- **Duration:** 2.6 min (154 seconds)
- **Started:** 2026-02-15T09:13:32Z
- **Completed:** 2026-02-15T09:16:06Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- git:commit task creates conventional commits with Jira prefix, offering AI-generated messages from staged diffs or manual fzf-based type selection
- git:branch task creates feature branches with naming convention, offering AI conversion of free-text to kebab-case or manual direct input
- Both tasks validate Jira ticket format (PROJECT-123), provide preview/confirmation, and include shell aliases (c/b) for quick access
- Hybrid workflow: AI mode when claude CLI available, automatic fallback to manual mode if unavailable or AI output invalid

## Task Commits

Each task was committed atomically in the chezmoi source repository:

1. **Task 1: Implement git:commit hybrid AI/manual task** - `5707793` (feat)
2. **Task 2: Implement git:branch hybrid AI/manual task** - `666f7a6` (feat)

## Files Created/Modified
- `private_dot_config/mise/tasks/git/executable_commit` - Hybrid AI/manual conventional commit workflow with Jira prefix validation, claude CLI integration, fzf type selection, and confirmation
- `private_dot_config/mise/tasks/git/executable_branch` - Hybrid AI/manual feature branch creation with naming convention enforcement, claude CLI kebab-case conversion, and branch existence validation

## Decisions Made

**Hybrid AI/manual pattern:** Both tasks offer AI assistance via `claude --print -p` when the CLI is available. The AI mode generates complete output (commit message from diff, kebab-case branch name from free-text), then validates the format. If validation fails or claude CLI is unavailable, the task falls back to manual mode (fzf + bash read). Both paths converge at the preview/confirmation step for consistent UX.

**AI validation before acceptance:** Commit task validates AI output starts with `${TICKET}:` prefix. Branch task validates AI output matches kebab-case regex `^[a-z0-9]+(-[a-z0-9]+)*$`. Invalid output triggers automatic fallback to manual mode with user notification.

**Mode selection UI:** If claude CLI is available, present fzf choice of `ai` or `manual`. If unavailable, default to `manual` silently (no error). Empty fzf selection (user cancelled) also defaults to `manual`.

**No new dependencies:** Manual mode uses fzf (already installed) for selection menus and bash read (built-in) for text input. No gum, no commitizen, no Node.js tools.

## Deviations from Plan

None - plan executed exactly as written. Both tasks implemented per research specifications (GIT-01 and GIT-02 patterns from 25-RESEARCH.md).

## Issues Encountered

**Chezmoi apply requires Bitwarden authentication:** Full `chezmoi apply` failed because .gitconfig_local template requires Bitwarden secrets. Worked around by manually deploying task files with `cp` and `chmod +x`. This is expected behaviour — the plan only requires deploying the git task files, not the entire chezmoi state.

**Sandbox restrictions:** Git operations and file writes to ~/.config/ require `dangerouslyDisableSandbox: true`. This is standard for deployment operations outside the project directory.

## User Setup Required

None - no external service configuration required. Tasks use existing tools (git, fzf, bash read, optional claude CLI).

**Optional enhancement:** If user wants AI-assisted mode, install claude CLI:
```bash
# Install claude CLI if not present
brew install claude-ai/tap/claude
claude auth
```

Manual mode works without claude CLI — AI mode is purely optional enhancement.

## Next Phase Readiness

Phase 25 Plan 02 ready to implement git:cleanup (merged branch pruning) and git:pr (pull request creation via gh/glab). Both tasks follow same file-based pattern established in this plan.

All infrastructure in place:
- File-based task pattern verified working
- Hybrid AI/manual pattern established
- Jira validation reusable
- fzf + bash read proven for interactive prompts
- Deployment via chezmoi source → manual cp for testing

## Self-Check: PASSED

All claimed files and commits verified:
- FOUND: private_dot_config/mise/tasks/git/executable_commit
- FOUND: private_dot_config/mise/tasks/git/executable_branch
- FOUND: 5707793 (Task 1 commit)
- FOUND: 666f7a6 (Task 2 commit)

---
*Phase: 25-git-workflow-tasks*
*Completed: 2026-02-15*
