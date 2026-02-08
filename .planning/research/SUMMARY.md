# Project Research Summary

**Project:** dotfiles-zsh v1.1 Complete Migration
**Domain:** Dotfiles management - completing Dotbot-to-chezmoi migration
**Researched:** 2026-02-08
**Confidence:** HIGH

## Executive Summary

This milestone completes the migration from Dotbot symlink management to chezmoi-native management for all remaining configuration files. The foundation is already solid: v1.0.0 successfully migrated core dotfiles (ZSH, git, SSH keys, mise, Brewfile) to chezmoi with proven patterns for templating, encryption, and cross-platform support. The challenge now is extending these patterns to ~30 additional config types including terminal emulators, window managers, CLI tools, development tools, and a large Claude Code directory (~50 files).

The recommended approach leverages existing chezmoi features exclusively—no new tools or dependencies required. Use `exact_` directories for complete ownership, `.chezmoiignore` for selective exclusions, machine-specific templates for cross-platform differences, and careful pattern matching to prevent accidental secret exposure. The critical risk is the repository-as-source architecture: the dotfiles-zsh repo IS the chezmoi source directory, so removing Dotbot infrastructure files requires careful `.chezmoiignore` setup to prevent chezmoi from misinterpreting deletions.

Key risks centre on data loss and secret exposure. The `exact_` attribute can silently delete files not in source (documented incident in Issue #3414). Large directories like `.claude/` risk committing local settings with API tokens or absolute paths. The mitigation strategy is defensive: establish comprehensive `.chezmoiignore` patterns before ANY config additions, avoid `exact_` entirely during migration, always dry-run before applying, and never enable auto-push to git. Gradual phase-by-phase migration with validation at each step provides rollback points if issues arise.

## Key Findings

### Recommended Stack

The existing chezmoi stack from v1.0.0 requires no additions for v1.1 completion. All migrations use proven chezmoi features: `exact_` directories for complete directory management, `.chezmoiignore` for pattern-based exclusions, machine-specific templates (`.tmpl`) extending the existing `.chezmoidata.yaml` patterns, `private_` attribute for permission control, and `.chezmoiremove`/`remove_` for cleanup of deprecated configs.

**Core technologies (unchanged from v1.0.0):**
- **chezmoi** — Dotfile management with templates, encryption, Bitwarden integration — proven in v1.0.0, extending patterns to new configs
- **mise** — Runtime version management (7 runtimes) — no changes needed
- **Homebrew** — CLI tool packages via .chezmoidata.yaml — package definitions already exist for target configs
- **Sheldon** — ZSH plugin management — already migrated
- **Bitwarden** — Secret provider for chezmoi templates — will extend to atuin sync keys
- **age** — SSH key encryption — proven pattern for any new secrets

**Features NOT needed:**
- symlink_ (breaks encryption/templates)
- create_ (templates handle variability)
- modify_ (not applicable to static configs)
- run_once_ (run_onchange_ already in use)

### Expected Features

The migration encompasses three tiers of functionality:

**Must have (table stakes):**
- Static config file migration — Terminal emulators (kitty, ghostty, wezterm), window manager (aerospace), CLI tools (bat, lsd, btop, oh-my-posh), dev tools (lazygit, atuin, aider, finicky), basic dotfiles (.hushlogin, .inputrc, .editorconfig, .nanorc)
- Directory structure preservation — Tools expect configs in specific XDG locations
- Machine-specific templating — OS differences (Darwin vs Linux), machine type (client vs personal), path variations
- GPG agent config migration — Simple config with OS-specific pinentry path
- Dotbot retirement — Clean removal of install script, steps/, submodules
- Drop deprecated configs — Remove nushell (unused), zgenom (replaced by sheldon)

**Should have (differentiators):**
- Claude Code directory with selective encryption — Share commands/skills across machines (~50 files), protect settings.json with potential tokens
- Per-machine ignore patterns — .chezmoiignore templates exclude machine-specific state (caches, logs, local settings)
- zsh-abbr abbreviations templating — Machine-specific abbreviations (work vs personal)
- Karabiner config templating — Different keyboard mappings per machine (if needed)
- Terminal emulator theme templating — Consistent theming across tools (if desired)
- Private directory modifiers — Automatic permission protection for sensitive configs

**Defer (anti-features):**
- Migrating nushell configs — Not in use, drop entirely
- Migrating zgenom — Replaced by sheldon, drop entirely
- Keeping Dotbot alongside chezmoi — Dual systems create confusion
- Templating every config — Over-engineering static files
- Committing .chezmoi.toml to repo — Machine-specific, keep local only
- Syncing Claude Code local state — Only sync shared config, ignore local settings
- Exact directory modifiers on tool-modified configs — Tools like karabiner write state back

### Architecture Approach

The migration extends v1.0.0's proven directory structure within the existing chezmoi source tree (`~/.local/share/chezmoi` = `/Users/stephanlv_fanaka/Projects/dotfiles-zsh`). New configs integrate into `dot_config/` using established naming conventions (`dot_`, `private_`, `.tmpl` suffixes) and the existing data-driven templating system (`.chezmoidata.yaml` for static data, `chezmoi.toml` for machine-specific values).

**Major components:**
1. **Static config migration** — Direct addition of ~20 config files/directories to chezmoi source using `chezmoi add --follow` to convert existing Dotbot symlinks to regular files
2. **Template conversion layer** — Selective `.tmpl` extension for configs with OS-specific paths (gpg-agent pinentry), machine-type routing (finicky browser rules), or secret integration (atuin sync keys from Bitwarden)
3. **Selective ignore system** — Extended `.chezmoiignore` patterns for Dotbot infrastructure (install, steps/, dotbot/), macOS-only configs (aerospace, karabiner), local state (`.claude/settings.local.json`, cache directories), and deprecated tools (nushell, zgenom remnants)
4. **Large directory handling** — Mirror full `.claude/` structure (~50 files across agents/, commands/, skills/) with ignore patterns for caches/logs rather than attempting selective tracking
5. **Gradual retirement workflow** — Phase-by-phase migration validates each config type before proceeding, keeping both Dotbot and chezmoi operational until final phase, then atomic removal of Dotbot infrastructure via proper git submodule cleanup

### Critical Pitfalls

Research identified 12 pitfalls spanning critical (data loss/security) to minor (maintainability). The top 5 requiring immediate mitigation:

1. **Repo-is-Source Deletion Cascade (CRITICAL)** — Removing Dotbot infrastructure (install, steps/, dotbot submodule) from repo = removing from chezmoi source. chezmoi may interpret as "delete from target" or track unwanted files. Mitigation: Add all Dotbot infrastructure to `.chezmoiignore` BEFORE any removal attempts. Validate with `chezmoi managed | grep -E "install|steps|dotbot"` returning nothing. Commit `.chezmoiignore` separately before cleanup phase.

2. **Accidental Local Settings Exposure (.claude/ Risk) (CRITICAL)** — Large directory addition with `chezmoi add ~/.claude/` captures ALL 50+ files including `.claude/settings.local.json` with potential API tokens, absolute paths like `/Users/stephanlv_fanaka/`, and machine-specific state. Committed to public repo = secret leak requiring git history rewrite. Mitigation: Establish `.chezmoiignore` patterns for `**/*local*`, `**/*secret*`, `.claude/cache/` BEFORE adding directory. Add subdirectories selectively rather than entire tree. Always `git diff --staged | grep -E "token|key|password"` before pushing. Never enable auto-push.

3. **exact_ Directory Data Loss (CRITICAL)** — Using `exact_` attribute tells chezmoi to DELETE any files not in source. External tools writing cache/state to managed directories = silent file deletion on next apply. Documented data loss in Issue #3414. Mitigation: Avoid `exact_` entirely during migration. Use `.chezmoiignore` for dynamic files instead. Only reconsider `exact_` after 1+ month stability.

4. **Orphaned Symlink Accumulation (HIGH)** — After migrating configs, Dotbot symlinks remain in filesystem. If Dotbot install script runs accidentally, symlinks overwrite chezmoi-managed files. If files removed from repo before chezmoi manages them, symlinks break. Mitigation: Audit symlinks before migration with `find ~ -type l | grep dotfiles-zsh > ~/symlink-inventory.txt`. For each config: verify `--follow` flag converted symlink to file with `ls -la` showing no `->`. Never run `./install` after migration begins.

5. **Permission Mismatch After Symlink Conversion (HIGH)** — Dotbot symlinks preserve target permissions. chezmoi copies files with default umask (644), losing execute bits on scripts and privacy on sensitive configs unless explicit `executable_`/`private_` prefixes used. Mitigation: Audit permissions before migration with `find ~/.config -type f -executable` and `find ~/.config -type f -perm 600`. Use `chezmoi add` with correct prefixes. Create `run_after_verify-permissions.sh` script to validate critical file modes.

## Implications for Roadmap

Based on research, the migration should follow a defensive, incremental approach with clear phase boundaries:

### Phase 0: Preparation (Foundation)
**Rationale:** Repo-as-source architecture demands protective measures BEFORE any config changes
**Delivers:** Comprehensive `.chezmoiignore` patterns preventing accidental infrastructure tracking or secret exposure
**Addresses:** Pitfall 1 (repo-as-source), Pitfall 2 (secret exposure), Pitfall 3 (exact_ prevention)
**Tasks:**
- Create `.chezmoiignore` with Dotbot infrastructure (install, steps/, dotbot/), local settings (`**/*local*`, `**/*secret*`, `.env`), macOS exclusions template
- Validate with `chezmoi managed` showing no unwanted files
- Create symlink inventory baseline
- Audit existing permissions and template syntax
- Set machine_type in chezmoi config
- Commit `.chezmoiignore` separately before proceeding

### Phase 1: Low-Risk Static Configs
**Rationale:** Establish migration workflow with simplest configs (no secrets, no templating, no large directories)
**Delivers:** Basic dotfiles and simple CLI tools validated under chezmoi management
**Addresses:** Table stakes static config migration
**Avoids:** Pitfall 4 (orphaned symlinks) via `--follow` validation
**Configs:** .hushlogin, .inputrc, .editorconfig, .nanorc, .psqlrc, .sqliterc, bat, lsd, btop, lazygit
**Pattern:** `chezmoi add --follow`, verify symlink→file transition, test tool functionality

### Phase 2: Terminal Emulators & Window Manager
**Rationale:** Moderate complexity (cache files, OS-specific), tests `.chezmoiignore` patterns and cross-platform handling
**Delivers:** Terminal configs with selective cache exclusion, macOS-only window manager correctly ignored on Linux
**Uses:** `.chezmoiignore` templates for OS detection, cache exclusion patterns
**Addresses:** Pitfall 8 (cross-platform paths) via OS-specific ignores
**Configs:** kitty, ghostty, wezterm (check for `.tmpl` need), aerospace (macOS-only), karabiner (macOS-only)
**Research flag:** Investigate terminal emulator cache locations before adding

### Phase 3: Dev Tools with Secrets
**Rationale:** Requires Bitwarden integration and careful secret handling before large directory migration
**Delivers:** Development tools with template-based secret injection, validates password manager workflow
**Uses:** Bitwarden templating pattern from v1.0.0 (git config), `private_` attribute for GPG
**Implements:** Secret management architecture extension
**Addresses:** Pitfall 2 (secret exposure) via Bitwarden templates and permission verification
**Configs:** atuin (Bitwarden sync key), aider (check for API keys), finicky, gpg-agent (OS-specific pinentry), zsh-abbr
**Research flag:** Audit dev tool configs for embedded secrets before adding

### Phase 4: Large Directory (.claude/)
**Rationale:** Highest risk due to size (~50 files) and mixed shared/local content, deferred until patterns proven
**Delivers:** Claude Code configs synced across machines with local state properly excluded
**Addresses:** Pitfall 2 (local settings exposure), Pitfall 7 (performance degradation)
**Avoids:** Pitfall 3 (exact_ data loss) by using ignore patterns instead
**Pattern:** Selective subdirectory addition (agents/, commands/, skills/), `.chezmoiignore` for settings.local.json and cache/
**Research flag:** Audit .claude/ contents to categorize shared vs local files before migration
**Performance check:** Monitor `time chezmoi diff` before/after, should stay <2s

### Phase 5: Dotbot Retirement (Cleanup)
**Rationale:** Only safe after ALL configs migrated and validated, atomic removal with no rollback
**Delivers:** Clean chezmoi-only repository with Dotbot infrastructure removed
**Addresses:** Pitfall 9 (submodule removal), Pitfall 12 (dead references)
**Validation:** Compare symlink inventory (should be empty), verify `chezmoi managed` covers all configs, test fresh apply on clean machine
**Tasks:**
- Verify no Dotbot symlinks remain: `find ~ -type l | grep dotfiles-zsh`
- Remove nushell/zgenom configs and references
- Proper git submodule removal (deinit, rm, clean .git/modules)
- Remove install script and steps/
- Archive old Brewfiles
- Update README with chezmoi-only workflow

### Phase Ordering Rationale

- **Phase 0 first:** Repository structure requires protective `.chezmoiignore` before ANY file operations to prevent infrastructure tracking
- **Phases 1-2 build confidence:** Simple configs validate workflow, OS detection, permission handling without secret/size risks
- **Phase 3 before 4:** Secret management patterns must be proven before handling large directory with potential embedded tokens
- **Phase 4 isolated:** Largest risk surface isolated from other migrations, can rollback without affecting proven configs
- **Phase 5 last:** Point of no return, only execute after extensive validation confirms full migration success

### Research Flags

Phases needing deeper research during planning:

- **Phase 2 (Terminal emulators):** LOW priority — Need to investigate cache file locations for kitty/ghostty/wezterm to ensure `.chezmoiignore` patterns are complete. Standard pattern likely works, but validate before applying.

- **Phase 3 (zsh-abbr):** MEDIUM priority — Storage format unknown, may contain shell syntax (`${}`, `$()`) conflicting with chezmoi templates. Investigate format with `cat ~/.config/zsh-abbr/user-abbreviations` before migration to determine if `.tmpl` extension needed.

- **Phase 4 (.claude/ directory):** HIGH priority — Requires full file audit to categorize shared vs local. Run `tree ~/.claude/` and categorize each file/directory. Confirm settings.local.json location and any other machine-specific state. Map out exact `.chezmoiignore` patterns needed.

- **Phase 3 (Dev tools):** MEDIUM priority — Audit each tool config for embedded secrets: `grep -ri "token\|key\|password" ~/.config/{atuin,aider,lazygit,finicky}`. Determine which need Bitwarden templating vs encryption vs simple ignore.

Phases with standard patterns (skip research-phase):

- **Phase 1 (Static configs):** Well-documented pattern, basic `chezmoi add --follow` workflow, no special handling required

- **Phase 5 (Dotbot retirement):** Standard git submodule removal, documented in git documentation and chezmoi FAQ

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All features exist in chezmoi, no new tools needed, patterns proven in v1.0.0 |
| Features | HIGH | Clear inventory from Dotbot steps/ configs, MVP vs nice-to-have well-defined |
| Architecture | HIGH | Extends proven v1.0.0 patterns, file mapping clear from existing symlinks |
| Pitfalls | MEDIUM-HIGH | Critical pitfalls well-documented (official docs + GitHub issues), config-specific gaps require investigation |

**Overall confidence:** HIGH

### Gaps to Address

Areas requiring validation during implementation:

- **Terminal emulator cache behavior:** Need to identify exact cache file locations/patterns for `.chezmoiignore`. Low risk — likely follows standard XDG cache patterns, but validate before migration to prevent cache churn.

- **zsh-abbr storage format:** Unknown file format/syntax. Could break abbreviations if templated incorrectly. Investigate format before migration, test expansion after apply. Medium risk — may require template escaping.

- **.claude/ file categorization:** Need complete inventory of which files are shared vs machine-local. High risk if local settings accidentally committed. Requires manual audit with `tree ~/.claude/` and file-by-file review.

- **Dev tool secret locations:** Need to confirm which configs (atuin, aider, lazygit, finicky) contain secrets requiring Bitwarden templating vs simple static files. Medium risk — audit with `grep` before adding.

- **Performance with 50+ files:** Theoretical concern about `chezmoi diff` slowdown with large .claude/ directory. Low risk — benchmark before/after, likely acceptable given modern hardware. Mitigation via `.chezmoiignore` if needed.

- **Karabiner machine-specificity:** Unknown if keyboard mappings differ per machine/keyboard. If yes, needs templating. If no, static file works. Low risk — can migrate as static first, convert to template later if needed.

## Sources

### Primary (HIGH confidence)

**chezmoi Official Documentation:**
- [Migrating from another dotfile manager](https://www.chezmoi.io/migrating-from-another-dotfile-manager/) — Symlink conversion, workflow changes
- [Target types](https://www.chezmoi.io/reference/target-types/) — File attributes (exact_, private_, executable_)
- [.chezmoiignore](https://www.chezmoi.io/reference/special-files/chezmoiignore/) — Pattern syntax, templating
- [Manage machine-to-machine differences](https://www.chezmoi.io/user-guide/manage-machine-to-machine-differences/) — OS detection, machine types
- [Templating](https://www.chezmoi.io/user-guide/templating/) — Go template syntax, variables
- [Manage different types of file](https://www.chezmoi.io/user-guide/manage-different-types-of-file/) — Permissions, encrypted files
- [Customize your source directory](https://www.chezmoi.io/user-guide/advanced/customize-your-source-directory/) — Repository-as-source architecture
- [Design FAQ](https://www.chezmoi.io/user-guide/frequently-asked-questions/design/) — Philosophy, edge cases
- [Usage FAQ](https://www.chezmoi.io/user-guide/frequently-asked-questions/usage/) — Common migration issues

**Existing Project Documentation:**
- `/Users/stephanlv_fanaka/Projects/dotfiles-zsh/README.md` — Current chezmoi setup from v1.0.0
- `.planning/milestones/v1.0.0-ROADMAP.md` — Foundation milestone showing proven patterns

### Secondary (MEDIUM confidence)

**Real-world Migration Experiences:**
- [Migrating a pre-existing dotfiles repository · Discussion #2330](https://github.com/twpayne/chezmoi/discussions/2330) — Community migration strategies
- [How To Manage Dotfiles With Chezmoi](https://jerrynsh.com/how-to-manage-dotfiles-with-chezmoi/) — Tutorial covering templating, secrets
- [Managing dotfiles with Chezmoi](https://natelandau.com/managing-dotfiles-with-chezmoi/) — Cross-platform patterns
- [Taking Control of My Dotfiles with chezmoi](https://blog.cmmx.de/2026/01/13/taking-control-of-my-dotfiles-with-chezmoi/) — Recent migration experience

**Documented Pitfalls:**
- [Chezmoi confused with exact_ and externals · Issue #3414](https://github.com/twpayne/chezmoi/issues/3414) — Data loss incident, exact_ danger
- [Persist file permissions for group and other · Issue #769](https://github.com/twpayne/chezmoi/issues/769) — Permission model limitations

**Claude Code Integration:**
- [Sync Claude Code commands and hooks across machines](https://www.arun.blog/sync-claude-code-with-chezmoi-and-age/) — .claude/ sync patterns with age encryption
- [claude-code-mastery/docs/guides/dotfiles-sync.md](https://github.com/NovaAI-innovation/claude-code-mastery/blob/main/docs/guides/dotfiles-sync.md) — Community guide for Claude Code dotfiles
- [.claude - Your Claude Code Directory](https://dotclaude.com/) — Directory structure reference

### Tertiary (LOW confidence, needs validation)

**Terminal/Window Manager Configuration:**
- [The Modern Terminals Showdown](https://blog.codeminer42.com/modern-terminals-alacritty-kitty-and-ghostty/) — Terminal emulator comparison (cache behavior not specified)
- [Choosing a Terminal on macOS (2025)](https://medium.com/@dynamicy/choosing-a-terminal-on-macos-2025-iterm2-vs-ghostty-vs-wezterm-vs-kitty-vs-alacritty-d6a5e42fd8b3) — Feature comparison (config structure not detailed)
- [AeroSpace Tiling Window Manager](https://github.com/nikitabobko/AeroSpace) — Documentation confirms macOS-only, config structure
- [How To Setup And Use The Aerospace Tiling Window Manager](https://www.josean.com/posts/how-to-setup-aerospace-tiling-window-manager) — Configuration tutorial

**Gaps requiring direct investigation:**
- zsh-abbr storage format — No documentation found, requires `cat ~/.config/zsh-abbr/user-abbreviations` inspection
- Exact .claude/ file inventory — Needs `tree ~/.claude/` output and per-file categorization
- Terminal emulator cache locations — Needs per-tool investigation in `~/.config/{kitty,ghostty}` and `~/.cache/`

---

*Research completed: 2026-02-08*
*Ready for roadmap: yes*
*Recommended approach: Gradual 5-phase migration with defensive .chezmoiignore setup, extensive validation, Dotbot retirement only after full verification*
