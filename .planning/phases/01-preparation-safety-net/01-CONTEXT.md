# Phase 1: Preparation & Safety Net - Context

**Gathered:** 2026-01-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish backup infrastructure, recovery mechanisms, and test environments before modifying live dotfiles. This phase creates the safety net — no dotfiles are migrated yet, but all recovery paths are in place.

</domain>

<decisions>
## Implementation Decisions

### Backup scope & format
- Full home directory snapshot (~/. files and key directories)
- Use rsync to mirror backup directory structure — browsable, incremental-capable
- Backup location: external drive (must be mounted, fail if not present)
- Symlink handling: preserve symlinks AND copy dereferenced targets separately (maximum recoverability)
- Single backup (overwrite previous) — no timestamped versioning
- Standard exclusions: caches, node_modules, .Trash, large binaries — Claude builds sensible list
- Pre-flight check: scan for files >100MB, alert about unexpected directories before proceeding

### Recovery workflow
- Interactive with confirmations — shows what will be restored, asks before overwriting
- Post-restore: just restore files, no automatic shell verification

### Claude's Discretion
- Restore granularity (category-based vs file-level vs all-or-nothing)
- Conflict handling strategy when files exist at restore target
- Exact exclusion list for backups
- Test environment approach (Docker vs VM, pre-built vs build from scratch)
- Verification scripts for backup completeness

</decisions>

<specifics>
## Specific Ideas

- External drive requirement is strict — script fails with clear message if drive not mounted
- Pre-backup warning allows cancellation if something unexpected is found
- Backup should be browsable (rsync mirror, not archive) so files can be manually extracted if needed

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-preparation-safety-net*
*Context gathered: 2026-01-25*
