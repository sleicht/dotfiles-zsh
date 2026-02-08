# Phase 6: Security & Secrets - Context

**Gathered:** 2026-02-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Implement secure secret management for chezmoi-managed dotfiles. Integrate Bitwarden for secret sourcing, use age encryption for offline-critical files, prevent accidental secret commits with pre-commit hooks, and enforce correct file permissions across all sensitive configs.

</domain>

<decisions>
## Implementation Decisions

### Secret sourcing
- Bitwarden (Premium) as the sole secret manager via chezmoi's native `bw` CLI integration
- Secrets cached locally after first fetch — faster applies, manual refresh after rotation
- Starting fresh: current secrets live in config files and need migrating to Bitwarden
- Establish a Bitwarden folder/naming convention for dotfile secrets (e.g., `dotfiles/personal/github-token`, `dotfiles/client/github-token`)
- Separate Bitwarden items per machine type (client vs personal) — maps to chezmoi's `machine_type` templating
- Secret targets: git credentials, SSH keys, API tokens in shell env vars, plus Claude audits chezmoi source for additional secrets
- Auth flow: Claude's discretion on how to handle Bitwarden unlock before apply

### Encryption scope
- Bitwarden-first strategy: nothing sensitive in git by default, age encryption only for files that must be available offline
- Age encryption candidates: SSH keys and GPG keys (needed before Bitwarden is accessible), plus Claude assesses for others during research
- Age private key stored in Bitwarden (bootstrap chain: unlock Bitwarden → get age key → decrypt SSH/GPG → full access)
- Per-machine age key pairs: separate key pairs for client vs personal machines for better isolation

### Leak prevention
- Warn-then-block strictness: warning on local commit detection, hard block before push
- Both dotfiles-repo and global hooks: strict scanning in dotfiles-zsh repo + lighter global git hooks deployed via chezmoi for all repos
- Inline annotations for false positive allowlisting (e.g., `# gitleaks:allow` next to chezmoi template syntax)
- Scanner tool: Claude's discretion (gitleaks vs detect-secrets)

### Permission model
- Chezmoi native prefixes (private_, readonly_) for enforcement at apply time
- Verification script runs on every `chezmoi apply` as an after-apply hook
- Auto-fix + log: script automatically corrects wrong permissions and logs what was fixed
- Sensitive file scope: SSH keys, git credentials, cloud provider configs (AWS, GCP), kubeconfig, plus Claude audits for others

### Claude's Discretion
- Bitwarden unlock/auth flow approach
- Secret scanner tool choice (gitleaks vs detect-secrets)
- Bitwarden naming convention specifics
- Which additional files need age encryption beyond SSH/GPG
- Verification script implementation details
- Global git hook configuration and pattern set

</decisions>

<specifics>
## Specific Ideas

- Bootstrap chain: Bitwarden → age key → SSH/GPG keys → full repo access
- Per-machine isolation: separate Bitwarden items AND separate age key pairs for client vs personal
- Self-healing permissions: auto-fix on every apply with audit log
- Dual-layer leak prevention: strict in dotfiles repo, lighter globally

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 06-security-secrets*
*Context gathered: 2026-02-08*
