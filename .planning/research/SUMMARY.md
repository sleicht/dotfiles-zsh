# Project Research Summary

**Project:** ZSH Dotfiles Migration (Nix/Dotbot/asdf → chezmoi/mise)
**Domain:** Dotfiles Management & Development Environment
**Researched:** 2026-01-25
**Confidence:** HIGH

## Executive Summary

This research covers migrating from a complex multi-tool setup (Dotbot symlinks, Nix packages, asdf version management) to a modern, streamlined approach using chezmoi for dotfiles templating and mise for tool version management. The migration involves shifting from symlink-based file management to template-based file generation, consolidating package management around Homebrew, and replacing asdf with its faster Rust-based successor mise.

The recommended approach is an incremental, phase-based migration that maintains safety nets at each step. Start with chezmoi's core file management capabilities, migrate shell configurations first, then layer in cross-platform templating, and finally transition from asdf to mise. This allows verification at each checkpoint and provides clear rollback points if issues arise.

Key risks center around workflow paradigm shifts (editing source files instead of live configs), accidental secret leakage during migration, and shell startup performance regressions. These can be mitigated through comprehensive backups, pre-commit secret scanning, incremental migration with Git checkpoints, and performance profiling at each phase. The payoff is a unified, faster, and more maintainable dotfiles system with excellent cross-platform support.

## Key Findings

### Recommended Stack

The modern dotfiles stack for 2025+ centers on chezmoi for dotfiles management and mise for tool versioning, both written in performance-focused languages (Go and Rust respectively) and actively maintained with strong community adoption.

**Core technologies:**
- **chezmoi 2.69.3**: Dotfiles management with templating — mature (since 2018), excellent cross-platform support, template-based instead of symlinks, built-in secret management
- **mise 2026.1.6 or 2025.12.x**: Tool version management — 10-50x faster than asdf, backward compatible with .tool-versions, Rust-based with modern security features
- **Homebrew (latest)**: Package management — de facto standard for macOS, good Linux support via Linuxbrew, declarative with brew bundle
- **Sheldon 0.4.3+**: ZSH plugin manager — Rust-based and significantly faster than Oh My Zsh, TOML configuration integrates cleanly with chezmoi templates

### Expected Features

**Must have (table stakes):**
- Import existing Dotbot symlinks with `chezmoi add --follow` — preserves git history, enables incremental migration
- asdf compatibility via .tool-versions files — mise reads them natively, zero-downtime migration possible
- Basic templating for OS detection — `{{ if eq .chezmoi.os "darwin" }}` conditionals for macOS/Linux differences
- Machine-specific configuration — `.chezmoidata/*.toml` for static data, `.chezmoi.toml.tmpl` for dynamic detection
- Automated package installation — `run_onchange_` scripts with embedded Brewfiles re-run when package lists change

**Should have (competitive):**
- Secret management integration — 1Password template functions (recommended for existing users) or age encryption (simpler than GPG)
- Cross-platform file variants — `_darwin` and `_linux` suffixes for platform-specific configs, cleaner than large conditional blocks
- Script execution system — `run_once_before_` for bootstrap, `run_onchange_` for declarative package management
- mise environment variable management — consolidates direnv functionality into single tool
- Shell startup optimization — lazy loading, eval caching, zsh-defer for non-critical initializations

**Defer (v2+):**
- mise task runner features — alternative to make/just, stable in 2025 but less battle-tested than dedicated tools
- External file inclusion from URLs — share configs across repos, useful for team-wide standards but not essential for migration
- Hooks system for chezmoi events — medium complexity, low immediate value for solo setup
- Advanced mise backends (aqua, ubi) — automatic selection works fine, manual backend choice unnecessary for migration

### Architecture Approach

The architecture shifts from symlink-based file distribution to template-based file generation, with a clear separation between source state (`~/.local/share/chezmoi`) and target state (`~/`). Files are organized with naming conventions that convey permissions and processing rules (`dot_` for dotfiles, `.tmpl` for templates, `private_` for 600 permissions, `run_onchange_` for conditional execution). Machine-specific variation is handled through a three-tier data system: built-in variables (OS, arch, hostname), static configuration (`.chezmoidata/`), and dynamic detection (`.chezmoi.toml.tmpl`).

**Major components:**
1. **chezmoi source directory** (`~/.local/share/chezmoi`) — Git repository containing templates, scripts, and data; files named with prefixes that determine target location and permissions
2. **Template data layer** — `.chezmoidata/packages*.toml` for declarative package lists, `.chezmoi.toml.tmpl` for hostname-based machine type detection, templates access via `{{ .variableName }}`
3. **Script execution system** — `run_once_before_` for bootstrapping (Homebrew, mise), `run_onchange_before_` for package installation (triggers on Brewfile changes), execution order controlled by numeric prefixes
4. **mise global configuration** (`~/.config/mise/config.toml`) — managed by chezmoi as template, defines tool versions and settings, activated via `eval "$(mise activate zsh)"` in .zshrc
5. **Package management layer** — Homebrew for system packages, mise for language toolchains, all declaratively defined in chezmoi source with OS-specific variants

### Critical Pitfalls

1. **Workflow paradigm shift from symlinks to templates** — Dotbot allows editing files directly in `~/`, but chezmoi requires editing in `~/.local/share/chezmoi` first then applying. Use `chezmoi edit ~/.zshrc` instead of `vim ~/.zshrc` to avoid destroying templates. Set up git pre-commit hooks to detect accidental template removal. Always verify with `chezmoi diff` before `chezmoi apply`.

2. **Accidental secret leakage to Git during migration** — Most common security mistake is running `chezmoi add` on files containing API keys, AWS credentials, or SSH private keys. Create `.chezmoiignore` with patterns like `.env`, `.aws/credentials`, `.ssh/*_rsa` BEFORE adding any files. Use gitleaks or trufflehog to scan before first push. Prefer 1Password template functions or age encryption over committing secrets.

3. **Shell startup performance regression** — Each tool (Homebrew, mise, Starship, etc.) adds 50-200ms initialization time. Combined, shell startup can go from 50ms to 2-5 seconds. Profile with `zmodload zsh/zprof`, lazy load non-essential tools, cache eval outputs, use `zsh-defer` for non-critical initializations. Target < 300ms total startup time.

4. **asdf and mise compatibility breaking with asdf 0.16+** — mise was designed for asdf ≤0.15 (bash). The asdf 0.16+ rewrite (Go) introduced command conflicts. Do complete cut-over, not gradual: uninstall asdf entirely before activating mise in shell. mise reads existing .tool-versions files but does NOT reuse asdf installation directories — plan for full reinstallation time.

5. **Incomplete migration creating two sources of truth** — Migrating some files to chezmoi but leaving others in Dotbot creates inconsistent state. Complete migration in phases but finish each phase fully: (1) import ALL Dotbot files, (2) verify with `chezmoi diff`, (3) remove Dotbot symlinks, (4) delete Dotbot installation script. Use Git tags for rollback points between phases.

## Implications for Roadmap

Based on research, suggested phase structure follows the principle of "foundation first, complexity later" with clear verification and rollback points at each step.

### Phase 1: Preparation & Safety Net
**Rationale:** Migration without backups is catastrophic if shell breaks. This phase creates recovery mechanisms before touching any live configs.
**Delivers:** Complete backup of current state, emergency recovery scripts, migration test environment
**Addresses:** Risk mitigation from PITFALLS.md (shell lockout, lost work)
**Avoids:** "No backup before migration" pitfall — enables rollback to working state

### Phase 2: chezmoi Foundation
**Rationale:** Establish core dotfiles management without complexity. Start with minimal working configuration to verify workflow before adding templates.
**Delivers:** chezmoi initialized with Git remote, basic shell configs migrated, verification that new shell works
**Uses:** chezmoi 2.69.3 with basic `add --follow` import pattern
**Implements:** Source directory structure (`.chezmoi.toml.tmpl`, `.chezmoiignore`, `.chezmoidata/`)
**Avoids:** "Incomplete migration" pitfall by migrating shell core completely before proceeding

### Phase 3: Templating & Machine Detection
**Rationale:** Once basic chezmoi works, add cross-platform support and machine-specific configuration. Dependencies from Phase 2 (working shell) required.
**Delivers:** Platform-specific conditionals (macOS/Linux), machine type detection (client/fanaka), templated configurations
**Addresses:** Cross-platform support from FEATURES.md
**Implements:** Template data layer from ARCHITECTURE.md (`.chezmoidata/packages*.toml`, hostname detection)
**Avoids:** "Template syntax errors" pitfall via incremental testing with `chezmoi execute-template`

### Phase 4: Package Management Migration
**Rationale:** With templating working, migrate declarative package management. Requires working templates (Phase 3) to support OS-specific Brewfiles.
**Delivers:** Automated package installation via `run_onchange_` scripts, Nix removal, consolidated Homebrew management
**Uses:** Homebrew with `brew bundle --file=/dev/stdin` pattern from STACK.md
**Implements:** Script execution system from ARCHITECTURE.md
**Avoids:** "Package manager differences" pitfall with OS-specific package lists in `.chezmoidata/`

### Phase 5: Tool Version Migration (mise)
**Rationale:** Final major component. Kept separate from earlier phases because asdf→mise is independent of dotfiles management and has distinct failure modes.
**Delivers:** mise installed and activated, all project .tool-versions working, asdf removed
**Uses:** mise 2026.1.6 or 2025.12.x with global config templated by chezmoi
**Implements:** mise global configuration component from ARCHITECTURE.md
**Avoids:** "asdf/mise running simultaneously" pitfall with parallel installation then clean cut-over
**Addresses:** Performance requirements from FEATURES.md (10-50x faster than asdf)

### Phase 6: Secrets & Security Hardening
**Rationale:** After migration working, address security. Kept late because requires stable foundation and can use various strategies based on preference.
**Delivers:** Secret management strategy implemented (1Password or age), file permissions verified, pre-commit hooks installed
**Addresses:** Secret management from FEATURES.md (should have)
**Avoids:** "Secret leakage" and "insecure permissions" pitfalls from PITFALLS.md

### Phase 7: Performance Optimization
**Rationale:** Final phase focuses on polish. Only after everything works should we optimize startup time.
**Delivers:** Shell startup < 300ms, lazy loading for non-critical tools, eval caching
**Addresses:** Performance requirements from FEATURES.md
**Avoids:** "Slow startup" pitfall with profiling (zprof) and targeted optimizations

### Phase Ordering Rationale

- **Foundation → Complexity**: Start with working shell (Phase 2), add templates (Phase 3), then advanced features (Phases 4-5)
- **Independent failures**: mise migration (Phase 5) separated from dotfiles migration (Phases 2-4) so failure in one doesn't block the other
- **Verification points**: Each phase ends with working system and Git tag for rollback
- **Dependencies respected**: Templates (Phase 3) required before package scripts (Phase 4); working chezmoi (Phase 2) required before templates (Phase 3)
- **Risk mitigation**: Backups and recovery (Phase 1) before any changes; secrets (Phase 6) after stable foundation; performance (Phase 7) as final polish

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 4 (Package Management)**: Machine-specific Brewfile patterns need validation — Brewfile_Client and Brewfile_Fanaka have real packages that need mapping to .chezmoidata format
- **Phase 5 (mise Migration)**: Verify asdf plugin compatibility — some current .tool-versions entries may use plugins not available in mise
- **Phase 6 (Secrets)**: 1Password integration testing required — existing secrets need catalog before deciding encryption strategy

Phases with standard patterns (skip research-phase):
- **Phase 1 (Preparation)**: Backup and recovery scripts follow documented patterns
- **Phase 2 (chezmoi Foundation)**: Basic import documented in official chezmoi migration guide
- **Phase 3 (Templating)**: OS detection and machine types are well-documented chezmoi patterns
- **Phase 7 (Performance)**: Shell profiling and optimization techniques are established

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | **HIGH** | All tools have official documentation, active maintenance, and production usage examples; version recommendations based on current stable releases |
| Features | **HIGH** | Feature requirements derived from official docs and real-world migration examples; must-have vs should-have distinction clear from migration complexity analysis |
| Architecture | **HIGH** | Directory structure and integration patterns validated against official chezmoi architecture docs and multiple real-world examples (shunk031/dotfiles, mizchi/chezmoi-dotfiles) |
| Pitfalls | **HIGH** | All pitfalls sourced from documented migration issues, community discussions, and specific GitHub issues; prevention strategies tested in production by community |

**Overall confidence:** **HIGH**

All four research documents are backed by official documentation, real-world examples, and community consensus. The migration path is well-trodden with documented solutions to common issues.

### Gaps to Address

- **Machine-specific package lists**: Current Brewfile_Client and Brewfile_Fanaka need audit during Phase 4 planning to ensure all packages map correctly to .chezmoidata format
- **Secret inventory**: Existing dotfiles may contain undocumented secrets; need comprehensive scan with gitleaks before Phase 2 to prevent accidental leakage
- **mise plugin availability**: Some asdf plugins may not have mise equivalents; need to verify all .tool-versions entries during Phase 5 planning
- **Shell startup baseline**: Current startup time unmeasured; need to profile existing shell during Phase 1 to set optimization targets for Phase 7
- **Cross-platform testing environment**: Need Linux VM or Docker container for Phase 3 validation (macOS testing easy, Linux testing requires setup)

## Sources

### Primary (HIGH confidence)
- [chezmoi Official Documentation](https://www.chezmoi.io/) — all core features, migration guide, templating, architecture
- [mise Official Documentation](https://mise.jdx.dev/) — configuration, asdf comparison, migration path
- [chezmoi GitHub Repository](https://github.com/twpayne/chezmoi) — issues, discussions, migration patterns
- [mise GitHub Repository](https://github.com/jdx/mise) — issues, discussions, asdf compatibility notes
- [Homebrew Official Documentation](https://docs.brew.sh/) — brew bundle, declarative package management

### Secondary (MEDIUM confidence)
- [shunk031/dotfiles](https://github.com/shunk031/dotfiles) — production example of chezmoi + mise + sheldon integration
- [mizchi/chezmoi-dotfiles](https://github.com/mizchi/chezmoi-dotfiles) — chezmoi + sheldon patterns
- [Managing dotfiles with Chezmoi - Nathaniel Landau](https://natelandau.com/managing-dotfiles-with-chezmoi/) — comprehensive tutorial
- [Mise vs asdf - Better Stack](https://betterstack.com/community/guides/scaling-nodejs/mise-vs-asdf/) — performance comparison
- [Why I switched from asdf to mise](https://medium.com/@nidhivya18_77320/why-i-switched-from-asdf-to-mise-and-you-should-too-8962bf6a6308) — migration experience

### Tertiary (LOW confidence)
- [Migrating from asdf to mise without the headaches](https://dev.to/0xkoji/migrating-from-asdf-to-mise-without-the-headaches-1jp3) — migration walkthrough (single source)
- Various GitHub issue discussions on secret management, shell performance, cross-platform patterns — validated against official docs

---
*Research completed: 2026-01-25*
*Ready for roadmap: yes*
