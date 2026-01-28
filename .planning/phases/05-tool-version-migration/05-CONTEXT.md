# Phase 5: Tool Version Migration - Context

**Gathered:** 2026-01-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Replace asdf with mise for runtime version management. Manage node, python, go, rust, java, ruby, and terraform versions through mise. Remove asdf completely. Does not include project-specific version file changes outside dotfiles.

</domain>

<decisions>
## Implementation Decisions

### Migration strategy
- Clean cutover — remove asdf completely, mise takes over immediately
- Keep existing .tool-versions files as-is — mise reads them natively
- Delete ~/.asdf entirely — no backup needed, clean slate
- No compatibility shims — asdf commands simply won't exist

### Tool scope
- Mise manages: node, python, go, rust, java, ruby, terraform
- Mise exclusive — remove any Homebrew-installed versions of these runtimes
- Prompt to install when tool not configured (rather than silent fallback)

### Shell integration
- Config location: ~/.config/mise/config.toml (XDG standard, chezmoi-managed)
- Auto-install enabled — cd into project, missing tools install automatically
- Completions managed via chezmoi (not Homebrew)

### Global vs project versions
- Global defaults set for all managed runtimes (LTS/stable versions)
- Project .tool-versions always wins over global config
- Global versions synced via chezmoi (same on all machines)
- Prefix matching — "node 22" means latest 22.x.x

### Claude's Discretion
- Activation method (mise activate vs shims) — choose based on shell startup time
- Specific global version numbers for each runtime
- Order of mise activation in shell config

</decisions>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 05-tool-version-migration*
*Context gathered: 2026-01-28*
