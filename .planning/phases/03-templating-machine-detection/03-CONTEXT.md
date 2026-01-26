# Phase 3: Templating & Machine Detection - Context

**Gathered:** 2026-01-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Enable cross-platform support (macOS/Linux) and machine-specific configurations (client/personal/server) through chezmoi templating. Files adapt based on OS and machine identity. Does not include secret management (Phase 6) or package installation automation (Phase 4).

</domain>

<decisions>
## Implementation Decisions

### Machine Identity
- Detection via interactive prompt during `chezmoi init`
- Three machine types: client, personal, server
- Stored permanently in local config (edit manually to change)
- Default to "personal" if prompt skipped

### OS Differences
- Minimal differences expected (mostly paths)
- Use inline conditionals: `{{ if eq .chezmoi.os "darwin" }}...{{ end }}`
- Support multiple Linux distros (detect distro family)
- Fail loudly on unsupported OS/distro — forces explicit support

### Template Scope
- Convert to template only when file actually needs OS/machine logic
- Audit existing configs first to discover differences
- Known templating needs:
  - Git email (work vs personal)
  - Homebrew paths (/opt/homebrew vs /usr/local vs /home/linuxbrew)
- All template outputs include header: `# Managed by chezmoi - do not edit directly`

### Data Organisation
- Two-tier structure:
  - `.chezmoidata.yaml` (committed): package lists, tool configs, shared values
  - `.chezmoi.yaml.tmpl` (per-machine): machine type, email addresses
- Work email prompted during init (flexible for different clients)
- Personal email prompted during init

### Claude's Discretion
- Package list structure in .chezmoidata.yaml (flat vs nested)
- Exact distro detection approach
- Which additional configs need templating (discovered during audit)

</decisions>

<specifics>
## Specific Ideas

- Machine type prompt should be clear: "Is this a client (work), personal, or server machine?"
- Template header should be consistent across all generated files
- Homebrew path detection should work for Apple Silicon, Intel Mac, and Linuxbrew

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 03-templating-machine-detection*
*Context gathered: 2026-01-26*
