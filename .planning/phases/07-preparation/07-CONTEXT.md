# Phase 7: Preparation - Context

**Gathered:** 2026-02-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish protective infrastructure before any config migration begins. This includes .chezmoiignore setup, secret auditing, and a verification framework. No configs are migrated in this phase — it prepares the ground for Phases 8-12.

</domain>

<decisions>
## Implementation Decisions

### Ignore strategy
- Cover Dotbot infrastructure AND repo meta files (README, LICENSE, .git*, Brewfile, .planning/, etc.)
- Use chezmoi template syntax for OS-conditional ignoring (e.g., aerospace config ignored on Linux)
- Comprehensive setup now — define all ignore rules upfront covering the entire v1.1 migration
- Claude's discretion on handling already-managed v1.0.0 configs in .chezmoiignore

### Secret audit criteria
- Flag ANYTHING non-public: API keys, tokens, passwords, email addresses, usernames, server hostnames, IP addresses, user-specific paths (/Users/yourname)
- Report findings AND categorise each as: Bitwarden secret, chezmoi template variable, or safe to ignore
- Audit ALL config files in the repo — including v1.0.0 configs — to catch anything missed earlier
- Reusable script that can be re-run before each phase to verify no new secrets have crept in

### Verification approach
- "Correct deployment" means: file exists at target path, content is valid (no template errors/placeholders), AND target application can parse/load it without errors
- Pass/fail summary output: checkmark/cross per config, exit code reflects overall result
- Manual invocation — standalone script, not a chezmoi hook
- Plugin-based structure: a runner that loads check files from a directory, each phase drops in its own checks

### Migration safety net
- Git is the backup strategy — no separate file snapshots needed
- Recovery via git revert of phase commit, then re-run chezmoi apply
- Always run chezmoi diff before chezmoi apply — dry-run review for every migration
- Batch per phase — each phase migrates all its configs together in one commit

### Claude's Discretion
- How to handle v1.0.0 configs in .chezmoiignore (skip vs document)
- Exact categories and format for the secret audit report
- Verification check file format and runner implementation
- Specific Dotbot files and repo meta files to include in .chezmoiignore

</decisions>

<specifics>
## Specific Ideas

- Verification script should be extensible — each future phase (8-12) adds its own check file to a checks directory
- Secret audit script should be reusable as a pre-migration gate throughout v1.1
- .chezmoiignore should be comprehensive from the start, not built incrementally
- Dotbot stays non-functional (no explicit fallback) — git revert is the sole recovery path

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 07-preparation*
*Context gathered: 2026-02-08*
