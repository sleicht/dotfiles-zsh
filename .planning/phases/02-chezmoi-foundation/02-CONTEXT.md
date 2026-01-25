# Phase 2: chezmoi Foundation - Context

**Gathered:** 2026-01-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish core dotfiles management with chezmoi — initialize chezmoi, migrate shell configuration (.zshrc, .zshenv, .zprofile, zsh.d/*.zsh) and git config to chezmoi's source directory, enable `chezmoi apply` workflow, and set up Git version control with remote. Dotbot continues managing unmigrated files during transition.

</domain>

<decisions>
## Implementation Decisions

### Migration approach
- Incremental migration: start with core shell files, verify working, then add more
- Dotbot remains active until fully migrated — manages unmigrated files
- Phase 2 scope: core shell files (.zshrc, .zshenv, .zprofile, zsh.d/*.zsh) plus git config
- chezmoi overwrites when migrating: remove Dotbot symlink first, then chezmoi manages real file

### Source directory structure
- Flatten structure where sensible — let chezmoi conventions simplify where appropriate
- Use chezmoi naming: `dot_zsh.d/` for zsh.d files (follows chezmoi patterns)
- Preserve familiar layout where possible — easier mental mapping to current setup
- Single `dot_config/` directory for all .config contents

### Git workflow
- Fork/migrate approach: fork existing repo, migrate to chezmoi structure, keep histories connected
- chezmoi source at default location: `~/.local/share/chezmoi`
- Atomic commits per file group: separate commits for shell files, git config, etc.
- Easy rollback per component

### Daily editing workflow
- IDE/editor project workflow: open chezmoi source as project, full IDE features
- No chezmoi-specific aliases — use full commands for clarity
- Quick reference in README for workflow summary
- Shell message on first use (removable after comfortable)

### Claude's Discretion
- Remote repository timing: determine when to push based on safety/workflow
- Auto-apply behaviour: determine safest default for IDE editing workflow
- Exact file groupings for atomic commits
- Shell reminder implementation details

</decisions>

<specifics>
## Specific Ideas

- Mental model: chezmoi source should feel familiar enough that knowledge of current structure transfers
- The fork/migrate approach preserves git history while enabling clean chezmoi structure
- IDE workflow means manual `chezmoi apply` is expected (no auto-apply surprises)

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 02-chezmoi-foundation*
*Context gathered: 2026-01-25*
