# Milestones

## v1.0.0 Dotfiles Stack Migration (Shipped: 2026-02-08)

**Delivered:** Complete migration from Nix/Dotbot/Zgenom/asdf to chezmoi/mise/Homebrew/Sheldon with cross-platform templating and Bitwarden secret management.

**Phases completed:** 1-6 (25 plans total)

**Key accomplishments:**
- chezmoi managing all dotfiles with cross-platform templates (macOS/Linux), machine-specific config (client/personal), and interactive setup prompts
- mise managing 7 runtime versions (node, python, go, rust, java, ruby, terraform) with auto-install and directory-based version switching
- Homebrew automation via chezmoi run scripts: 171+ packages consolidated from 5 sources into single .chezmoidata.yaml, change-triggered installation, automated cleanup with audit trail
- Bitwarden secret management with age encryption for SSH keys, per-machine age key pairs, and bootstrap chain (Bitwarden -> age key -> SSH keys -> full access)
- Global gitleaks scanning for all git repos via chezmoi-deployed hooks (warn on commit, block on push) with pre-commit framework delegation
- Automated permission verification on every chezmoi apply (13 sensitive file patterns, cross-platform stat detection, audit logging)

**Stats:**
- 6 phases, 25 plans
- 15 days from start to ship (2026-01-25 to 2026-02-08)
- 3.10 hours total execution time (average 7.4 min/plan)

**Git range:** feature/nix branch

**What's next:** v2 -- Performance optimisation, mise task runner

---
