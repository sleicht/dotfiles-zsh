# Roadmap: Dotfiles Stack

## Milestones

- ✅ **v1.0.0 Dotfiles Stack Migration** -- Phases 1-6 (shipped 2026-02-08)
- ✅ **v1.1 Complete Migration** -- Phases 7-12 (shipped 2026-02-12)
- ✅ **v1.2 Legacy Cleanup** -- Phases 13-18 (shipped 2026-02-14)
- 📋 **v2.0 Performance** -- Phases TBD (planned)

## Phases

<details>
<summary>✅ v1.0.0 Dotfiles Stack Migration (Phases 1-6) -- SHIPPED 2026-02-08</summary>

Complete migration from Nix/Dotbot/Zgenom/asdf to chezmoi/mise/Homebrew/Sheldon with cross-platform templating and Bitwarden secret management. See `.planning/milestones/v1.0.0-ROADMAP.md` for full details.

**Stats:** 6 phases, 25 plans, 3.10 hours total execution time

- [x] Phase 1: Nix Removal (4/4 plans) -- completed 2026-01-25
- [x] Phase 2: Chezmoi Foundation (5/5 plans) -- completed 2026-01-28
- [x] Phase 3: Runtime Management Migration (4/4 plans) -- completed 2026-01-30
- [x] Phase 4: Homebrew Automation (4/4 plans) -- completed 2026-02-02
- [x] Phase 5: Secret Management (4/4 plans) -- completed 2026-02-05
- [x] Phase 6: Security & Verification (4/4 plans) -- completed 2026-02-08

</details>

<details>
<summary>✅ v1.1 Complete Migration (Phases 7-12) -- SHIPPED 2026-02-12</summary>

Migrated all remaining Dotbot-managed configs to chezmoi and retired Dotbot entirely. 69 config files migrated with 112 automated verification checks. See `.planning/milestones/v1.1-ROADMAP.md` for full details.

**Stats:** 6 phases, 13 plans, 57 commits, 30/30 requirements satisfied

- [x] Phase 7: Preparation (2/2 plans) -- completed 2026-02-08
- [x] Phase 8: Basic Configs & CLI Tools (3/3 plans) -- completed 2026-02-11
- [x] Phase 9: Terminal Emulators (2/2 plans) -- completed 2026-02-09
- [x] Phase 10: Dev Tools with Secrets (2/2 plans) -- completed 2026-02-10
- [x] Phase 11: Claude Code (2/2 plans) -- completed 2026-02-12
- [x] Phase 12: Dotbot Retirement (2/2 plans) -- completed 2026-02-12

</details>

<details>
<summary>✅ v1.2 Legacy Cleanup (Phases 13-18) -- SHIPPED 2026-02-14</summary>

Removed all pre-chezmoi artifacts from the repository and fixed stale code in the chezmoi source. Net -16,609 lines removed. See `.planning/milestones/v1.2-ROADMAP.md` for full details.

**Stats:** 6 phases, 7 plans, 40 commits, 19/21 requirements satisfied (2 rescinded)

- [x] Phase 13: Remove Legacy Config Files (2/2 plans) -- completed 2026-02-13
- [x] Phase 14: Migrate san-proxy to chezmoi (1/1 plan) -- completed 2026-02-14
- [x] Phase 15: Fix PATH and Version Manager Code (1/1 plan) -- completed 2026-02-14
- [x] Phase 16: Fix Python 2 and Shell Utilities (1/1 plan) -- completed 2026-02-14
- [x] Phase 17: Clean Audit Scripts and Artifacts (1/1 plan) -- completed 2026-02-14
- [x] Phase 18: Clean Tech Debt from Audit (1/1 plan) -- completed 2026-02-14

</details>

### v2.0 Performance (Planned)

**Milestone Goal:** Optimise shell startup time to < 300ms and add mise task runner.

Phases TBD.

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Nix Removal | v1.0.0 | 4/4 | Complete | 2026-01-25 |
| 2. Chezmoi Foundation | v1.0.0 | 5/5 | Complete | 2026-01-28 |
| 3. Runtime Management Migration | v1.0.0 | 4/4 | Complete | 2026-01-30 |
| 4. Homebrew Automation | v1.0.0 | 4/4 | Complete | 2026-02-02 |
| 5. Secret Management | v1.0.0 | 4/4 | Complete | 2026-02-05 |
| 6. Security & Verification | v1.0.0 | 4/4 | Complete | 2026-02-08 |
| 7. Preparation | v1.1 | 2/2 | Complete | 2026-02-08 |
| 8. Basic Configs & CLI Tools | v1.1 | 3/3 | Complete | 2026-02-11 |
| 9. Terminal Emulators | v1.1 | 2/2 | Complete | 2026-02-09 |
| 10. Dev Tools with Secrets | v1.1 | 2/2 | Complete | 2026-02-10 |
| 11. Claude Code | v1.1 | 2/2 | Complete | 2026-02-12 |
| 12. Dotbot Retirement | v1.1 | 2/2 | Complete | 2026-02-12 |
| 13. Remove Legacy Config Files | v1.2 | 2/2 | Complete | 2026-02-13 |
| 14. Migrate san-proxy to chezmoi | v1.2 | 1/1 | Complete | 2026-02-14 |
| 15. Fix PATH and Version Manager Code | v1.2 | 1/1 | Complete | 2026-02-14 |
| 16. Fix Python 2 and Shell Utilities | v1.2 | 1/1 | Complete | 2026-02-14 |
| 17. Clean Audit Scripts and Artifacts | v1.2 | 1/1 | Complete | 2026-02-14 |
| 18. Clean Tech Debt from Audit | v1.2 | 1/1 | Complete | 2026-02-14 |

---
*Last updated: 2026-02-14 after v1.2 Legacy Cleanup milestone shipped*
