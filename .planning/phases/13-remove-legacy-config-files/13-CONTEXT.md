# Phase 13: Remove Legacy Config Files - Context

**Gathered:** 2026-02-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Clean Dotbot-era artifacts from the repository: 10 .config/ directories, 17 .config/ flat files, the redundant zsh.d/ directory, and 3 legacy Brewfiles. After this phase, the repository reflects only chezmoi-managed reality.

</domain>

<decisions>
## Implementation Decisions

### Dependency verification
- Full scan before any deletion: grep the entire repo and chezmoi source for references to each legacy file
- Check both symlinks AND text references (source statements, PATH entries, config paths)
- Explicitly check sheldon plugins.toml for zsh.d/ references
- Generate a written scan report in .planning/ before any deletions happen
- If a reference is found to a legacy file: block removal of that file, flag for manual review

### Backup approach
- Git history is sufficient — no pre-deletion archive needed
- One commit per category: directories, flat files, zsh.d/, Brewfiles (4 separate commits)
- Smoke test after each deletion commit: verify shell loads and chezmoi apply succeeds
- If smoke test fails: fix forward (keep deletion, fix what broke, commit fix separately)

### zsh.d/ handling
- Trust the Phase 8 migration — no diff comparison needed between zsh.d/ and dot_zsh.d/
- Explicitly verify sheldon plugins.toml doesn't reference zsh.d/ paths (part of scan)
- If zsh.d/ contains files NOT present in dot_zsh.d/: block removal until resolved
- Add zsh.d/ to .gitignore after removal to prevent accidental re-creation

### Brewfile consolidation
- Trust the Phase 4 migration — no cross-reference against .chezmoidata.yaml needed
- Add Brewfile, Brewfile_Client, Brewfile_Fanaka to .gitignore after removal
- Clean up any install script or steps/ yaml references to legacy Brewfiles
- Root Brewfile: remove from repo AND gitignore (prevents accidental `brew bundle dump` commits)

### Claude's Discretion
- Exact order of file removal within each category
- Scan report format and level of detail
- Smoke test specifics (which commands to run)

</decisions>

<specifics>
## Specific Ideas

- Scan report should be created before any deletions, serving as both verification and documentation
- .gitignore updates should be part of the same commit as the corresponding removals
- Install script cleanup (Brewfile references) bundled with Brewfile removal commit

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 13-remove-legacy-config-files*
*Context gathered: 2026-02-13*
