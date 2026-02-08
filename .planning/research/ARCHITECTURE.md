# Architecture Integration: Complete chezmoi Migration

**Domain:** Dotfiles management completion
**Researched:** 2026-02-08
**Context:** Subsequent milestone building on existing chezmoi foundation (v1.0.0)

## Executive Summary

This architecture document defines how remaining Dotbot-managed configurations integrate with the existing chezmoi source tree established in milestone v1.0.0. The focus is on extending proven patterns rather than redesigning the foundation.

**Key Integration Points:**
- Existing chezmoi source: `~/.local/share/chezmoi` (= `/Users/stephanlv_fanaka/Projects/dotfiles-zsh`)
- Naming conventions: Already established (`dot_`, `private_`, `.tmpl` patterns)
- Data-driven config: `.chezmoidata.yaml` pattern proven in v1.0.0
- Machine detection: `.chezmoi.yaml.tmpl` handles OS and machine type
- Secrets: age encryption + Bitwarden integration working

**Migration Scope:**
- Terminal emulator configs (kitty, ghostty, wezterm)
- Window manager (aerospace)
- CLI tool configs (bat, lsd, btop, oh-my-posh)
- Dev tool configs (lazygit, atuin, psqlrc, sqliterc, aider, finicky)
- Basic dotfiles (.hushlogin, .inputrc, .editorconfig, .nanorc)
- GPG agent, karabiner
- Claude Code (.claude/ directory — large config with 50+ files)
- zsh-abbr abbreviations
- zgenom plugin manager config

**Out of Scope:**
- Nushell (to be dropped)
- Neovim (stays separate as external directory)

## Existing Architecture Foundation

From v1.0.0 milestone completion (see `.planning/milestones/v1.0.0-ROADMAP.md`):

### Current chezmoi Source Tree

```
~/.local/share/chezmoi/ (= /Users/stephanlv_fanaka/Projects/dotfiles-zsh)
├── .chezmoi.yaml.tmpl              # Machine identity (OS, machine type)
├── .chezmoidata.yaml               # Package lists + config data
├── .chezmoiignore                  # Exclusions
├── .gitleaks.toml                  # Secret scanning config
├── .pre-commit-config.yaml         # Pre-commit hooks for repo
│
├── dot_zshrc                       # Shell config (static in v1.0.0)
├── dot_zshenv                      # Shell environment
├── dot_zprofile                    # Shell profile
├── dot_zsh.d/                      # Modular shell configs
│   ├── aliases.zsh
│   ├── functions.zsh
│   ├── variables.zsh
│   ├── (... other shell modules)
│
├── dot_gitconfig                   # Global git config
├── private_dot_gitconfig_local.tmpl # Git user/email from Bitwarden
├── dot_Brewfile.tmpl               # Generated from .chezmoidata.yaml
│
├── private_dot_ssh/                # SSH keys (age-encrypted)
│   ├── encrypted_private_*.age     # Private keys
│   ├── private_*.pub               # Public keys
│   └── private_config              # SSH host config
│
├── private_dot_config/
│   ├── git/hooks/                  # Global git hooks (gitleaks)
│   └── mise/config.toml.tmpl       # Tool version management
│
└── run_*.sh.tmpl                   # Automation scripts
    ├── run_once_before_install-homebrew
    ├── run_onchange_after_01-install-packages
    ├── run_onchange_after_02-cleanup-packages
    ├── run_once_after_generate-mise-completions
    └── run_after_10-verify-permissions
```

### Proven Patterns from v1.0.0

**1. Static vs Template Decision:**
- Static files: No machine-specific values, faster processing
- Templates (`.tmpl`): Machine-specific paths, conditionals, Bitwarden secrets

**2. Directory Organization:**
- `private_dot_config/` for configs needing restricted permissions
- `dot_config/` for standard configs
- Top-level `dot_*` for home directory dotfiles

**3. Machine Detection:**
```yaml
# .chezmoi.yaml.tmpl
data:
  machineType: "personal" | "client"
  os: "darwin" | "linux"
```

**4. Data-Driven Config:**
```yaml
# .chezmoidata.yaml
darwin:
  common_brews: [...]
  client_brews: [...]
  fanaka_brews: [...]
```

## Recommended Integration Architecture

### Directory Layout Extension

Building on existing structure, add:

```
~/.local/share/chezmoi/
│
├── [EXISTING v1.0.0 FILES...]
│
├── dot_hushlogin                   # NEW: Basic dotfile (static)
├── dot_inputrc                     # NEW: Basic dotfile (static)
├── dot_editorconfig                # NEW: Basic dotfile (static)
├── dot_nanorc                      # NEW: Basic dotfile (static)
├── dot_psqlrc                      # NEW: DB CLI config (static)
├── dot_sqliterc                    # NEW: DB CLI config (static)
├── dot_aider.conf.yml              # NEW: Aider config (static or .tmpl if API keys)
├── dot_finicky.js                  # NEW: macOS browser picker (static)
├── dot_wezterm.lua                 # NEW: Terminal config (static or .tmpl)
│
├── dot_gnupg/                      # NEW: GPG directory
│   └── gpg-agent.conf              # GPG agent config
│
├── dot_config/                     # EXTEND: XDG config directory
│   ├── aerospace/                  # NEW: macOS window manager
│   │   └── aerospace.toml          # (static, macOS-only via .chezmoiignore)
│   │
│   ├── bat/                        # NEW: cat replacement
│   │   └── config                  # (static)
│   │
│   ├── lsd/                        # NEW: ls replacement
│   │   └── config.yaml             # (static)
│   │
│   ├── btop/                       # NEW: System monitor
│   │   └── btop.conf               # (static)
│   │
│   ├── oh-my-posh/                 # NEW: Shell prompt (if used)
│   │   └── config.omp.json         # (static or .tmpl for machine-specific themes)
│   │
│   ├── kitty/                      # NEW: Terminal emulator
│   │   └── kitty.conf              # (static or .tmpl for font paths)
│   │
│   ├── ghostty/                    # NEW: Terminal emulator
│   │   └── config                  # (static)
│   │
│   ├── wezterm/                    # Alternative: if using directory structure
│   │   └── wezterm.lua             # (vs top-level dot_wezterm.lua)
│   │
│   ├── karabiner/                  # NEW: Keyboard remapping (macOS)
│   │   └── karabiner.json          # (static, complex JSON)
│   │
│   ├── lazygit/                    # NEW: Git TUI
│   │   └── config.yml              # (static)
│   │
│   ├── atuin/                      # NEW: Shell history
│   │   ├── config.toml.tmpl        # (template for sync key/server)
│   │   └── encrypted_private_key.age # (if storing key)
│   │
│   ├── zsh-abbr/                   # NEW: ZSH abbreviations
│   │   └── user-abbreviations      # (static)
│   │
│   ├── zgenom/                     # NEW: ZSH plugin manager
│   │   └── zgenomrc.zsh            # (static plugin list)
│   │
│   └── claude/                     # NEW: Large directory structure
│       ├── CLAUDE.md               # (static global instructions)
│       ├── settings.json           # (static or .tmpl for auth)
│       ├── agents/                 # (directory with ~10+ files)
│       ├── commands/               # (directory with ~10+ files)
│       ├── skills/                 # (directory with ~30+ files)
│       └── [...other subdirs]
│
└── [REMOVE when complete:]
    ├── install                     # Dotbot entry point
    ├── steps/                      # Dotbot YAML configs
    ├── dotbot/                     # Dotbot submodule
    ├── dotbot-brew/                # Plugin submodule
    └── dotbot-asdf/                # Plugin submodule
```

### File-by-File Integration Map

| Current Location | chezmoi Source Path | Type | Notes |
|------------------|---------------------|------|-------|
| **Basic Dotfiles** |
| `.config/hushlogin` | `dot_hushlogin` | static | Suppress login message |
| `.config/inputrc` | `dot_inputrc` | static | Readline config |
| `.config/editorconfig` | `dot_editorconfig` | static | Editor config |
| `.config/nanorc` | `dot_nanorc` | static | Nano config |
| **Database Tools** |
| `.config/psqlrc` | `dot_psqlrc` | static | PostgreSQL CLI |
| `.config/sqliterc` | `dot_sqliterc` | static | SQLite CLI |
| **Dev Tools** |
| `.config/aider.conf.yml` | `dot_aider.conf.yml` OR `.tmpl` | depends | Check for API keys |
| `.config/finicky.js` | `dot_finicky.js` | static | macOS browser picker |
| `.config/lazygit.yml` | `dot_config/lazygit/config.yml` | static | Git TUI config |
| **Terminal Emulators** |
| `.config/kitty.conf` | `dot_config/kitty/kitty.conf` | static/tmpl | Check font paths |
| `.config/ghostty/config` | `dot_config/ghostty/config` | static | Terminal config |
| `.config/wezterm.lua` | `dot_wezterm.lua` | static/tmpl | Terminal config |
| **Window/Input Management** |
| `.config/aerospace/aerospace.toml` | `dot_config/aerospace/aerospace.toml` | static | macOS-only (add to .chezmoiignore for Linux) |
| `.config/karabiner/karabiner.json` | `dot_config/karabiner/karabiner.json` | static | macOS-only, large JSON |
| **CLI Tools** |
| `.config/bat/config` | `dot_config/bat/config` | static | cat replacement |
| `.config/lsd/config.yaml` | `dot_config/lsd/config.yaml` | static | ls replacement |
| `.config/btop/btop.conf` | `dot_config/btop/btop.conf` | static | System monitor |
| `.config/oh-my-posh.omp.json` | `dot_config/oh-my-posh/config.omp.json` | static | Shell prompt |
| **Shell Plugins** |
| `.config/zsh-abbr/user-abbreviations` | `dot_config/zsh-abbr/user-abbreviations` | static | ZSH abbreviations |
| `.config/zgenom/zgenomrc.zsh` | `dot_config/zgenom/zgenomrc.zsh` | static | Plugin manager config |
| **Security/Crypto** |
| `.config/gpgagent` | `dot_gnupg/gpg-agent.conf` | static | GPG agent config |
| **Atuin (History)** |
| `.config/atuin/config.toml` | `dot_config/atuin/config.toml.tmpl` | template | Sync server/key from Bitwarden |
| **Claude Code** |
| `.config/claude/CLAUDE.md` | `dot_config/claude/CLAUDE.md` | static | Global instructions |
| `.config/claude/settings.json` | `dot_config/claude/settings.json` | static/tmpl | Check for auth tokens |
| `.config/claude/agents/*` | `dot_config/claude/agents/` | directory | ~10 files |
| `.config/claude/commands/*` | `dot_config/claude/commands/` | directory | ~10 files |
| `.config/claude/skills/*` | `dot_config/claude/skills/` | directory | ~30 files |
| **External (NOT in chezmoi)** |
| `.config/nushell/*` | — | DROP | Not in use |
| `nvim/*` | — | EXTERNAL | Stays separate, symlinked manually |
| `zgenom/*` | — | EXTERNAL | Plugin manager cache, not tracked |

### Static vs Template Decision Matrix

| Config Type | Template? | Rationale |
|-------------|-----------|-----------|
| **Basic dotfiles** (hushlogin, inputrc, editorconfig, nanorc) | NO | No machine-specific values |
| **DB CLI** (psqlrc, sqliterc) | NO | Standard config, no secrets in file |
| **Terminal emulators** (kitty, ghostty, wezterm) | DEPENDS | Template if font paths differ by OS or machine |
| **CLI tools** (bat, lsd, btop) | NO | Tool defaults work across machines |
| **Window manager** (aerospace) | NO | Static config, macOS-only via .chezmoiignore |
| **Keyboard** (karabiner) | NO | Large static JSON, macOS-only |
| **Git TUI** (lazygit) | NO | Standard config |
| **Shell plugins** (zsh-abbr, zgenom) | NO | Plugin lists same across machines |
| **Atuin** | YES | Sync server + key from Bitwarden |
| **Aider** | DEPENDS | Template if API keys present, otherwise static |
| **Claude Code** | DEPENDS | Template if auth tokens, otherwise static |
| **GPG** | NO | Standard agent config |
| **Finicky** | NO | Browser rules same across machines |

### Template Examples

**1. Atuin with Bitwarden Secrets**

```toml
# dot_config/atuin/config.toml.tmpl
{{- if (bitwarden "item" "dotfiles/shared/atuin-sync") }}
sync_address = "{{ (bitwardenFields "item" "dotfiles/shared/atuin-sync").server.value }}"
sync_key = "{{ (bitwardenFields "item" "dotfiles/shared/atuin-sync").key.value }}"
{{- end }}

auto_sync = true
update_check = false
```

**2. Conditional macOS-only Config**

```lua
-- dot_wezterm.lua.tmpl
local wezterm = require 'wezterm'

return {
  font = wezterm.font 'JetBrains Mono',
  {{- if eq .chezmoi.os "darwin" }}
  font_size = 14.0,
  {{- else }}
  font_size = 12.0,
  {{- end }}
}
```

**3. Machine-Type Specific Values**

```toml
# dot_config/aerospace/aerospace.toml
# Static file, but excluded for Linux via .chezmoiignore
```

```
# .chezmoiignore
{{- if ne .chezmoi.os "darwin" }}
.config/aerospace
.config/karabiner
{{- end }}
```

## Large Directory Handling: Claude Code

### Challenge

`.claude/` contains ~50+ files across multiple subdirectories:
- `agents/` — ~10 Python agent scripts
- `commands/` — ~10 custom command definitions
- `skills/` — ~30 skill modules
- Top-level: `CLAUDE.md`, `settings.json`, other config files

### Integration Strategy

**Option 1: Mirror Directory Structure (RECOMMENDED)**

```
dot_config/claude/
├── CLAUDE.md                    # Static global instructions
├── settings.json                # Static or .tmpl if contains auth
├── agents/
│   ├── agent1.py
│   ├── agent2.py
│   └── [...]
├── commands/
│   ├── command1.yaml
│   ├── command2.yaml
│   └── [...]
└── skills/
    ├── skill1.py
    ├── skill2.py
    └── [...]
```

**Add to chezmoi:**
```bash
chezmoi add --follow ~/.config/claude
# OR add recursively
chezmoi add --recursive ~/.config/claude
```

**Pros:**
- Preserves directory structure
- Easy to maintain
- Matches other tool configs

**Cons:**
- Many files in source tree
- Potential for large git commits

**Option 2: Selective Addition**

Only track critical files, ignore generated/cache:

```
# .chezmoiignore
.config/claude/cache/
.config/claude/*.log
.config/claude/temp/
```

**Option 3: External Directory (NOT RECOMMENDED)**

Keep `.claude/` as external symlink like nvim:

**Cons:**
- Doesn't align with "everything in chezmoi" goal
- Loses cross-machine sync benefits
- Requires separate versioning

### Recommendation

Use **Option 1** (mirror structure) with selective ignores. Claude Code configs are valuable to version and sync across machines.

## Build Order and Dependencies

### Migration Phases

Based on dependencies between configs:

**Phase 1: Basic Dotfiles (No Dependencies)**
```
Priority: High
Files:
  - dot_hushlogin
  - dot_inputrc
  - dot_editorconfig
  - dot_nanorc
  - dot_psqlrc
  - dot_sqliterc
  - dot_finicky.js

Dependencies: None
Verification: File presence, content match
```

**Phase 2: CLI Tool Configs (Depends on Homebrew packages)**
```
Priority: High
Files:
  - dot_config/bat/config
  - dot_config/lsd/config.yaml
  - dot_config/btop/btop.conf
  - dot_config/lazygit/config.yml

Dependencies:
  - Homebrew packages installed (bat, lsd, btop, lazygit)
  - run_onchange_after_01-install-packages.sh completed

Verification: Tools work with configs
```

**Phase 3: Terminal Emulators (Depends on CLI tools)**
```
Priority: Medium
Files:
  - dot_config/kitty/kitty.conf
  - dot_config/ghostty/config
  - dot_wezterm.lua

Dependencies:
  - Fonts installed (via Homebrew casks)
  - CLI tools configured (bat, lsd for shell integration)

Verification: Launch terminal, check theme/fonts
```

**Phase 4: Shell Plugin Configs (Depends on plugin managers)**
```
Priority: Medium
Files:
  - dot_config/zsh-abbr/user-abbreviations
  - dot_config/zgenom/zgenomrc.zsh
  - dot_config/oh-my-posh/config.omp.json (if used)

Dependencies:
  - zsh-abbr installed via Homebrew
  - zgenom directory exists (external)
  - oh-my-posh installed

Verification: Source shell, test abbreviations
```

**Phase 5: Security/Secrets (Depends on Bitwarden + age)**
```
Priority: High
Files:
  - dot_config/atuin/config.toml.tmpl
  - dot_aider.conf.yml.tmpl (if secrets present)
  - dot_gnupg/gpg-agent.conf

Dependencies:
  - Bitwarden CLI installed + authenticated
  - age key present (~/.config/age/key-*.txt)
  - BW_SESSION environment variable set

Verification:
  - chezmoi apply works without errors
  - atuin sync works
  - gpg-agent starts
```

**Phase 6: macOS-Specific (Depends on OS detection)**
```
Priority: Low (macOS only)
Files:
  - dot_config/aerospace/aerospace.toml
  - dot_config/karabiner/karabiner.json

Dependencies:
  - .chezmoiignore excludes on Linux
  - aerospace/karabiner-elements installed

Verification: Window manager/keyboard remapping works
```

**Phase 7: Large Directories (Depends on structure setup)**
```
Priority: Medium
Files:
  - dot_config/claude/* (50+ files)

Dependencies:
  - Directory structure verified
  - .chezmoiignore patterns set

Verification:
  - Claude Code loads config
  - All agents/commands/skills present
```

**Phase 8: Dev Tool Configs (Low Priority)**
```
Priority: Low
Files:
  - dot_aider.conf.yml (if no secrets)

Dependencies:
  - Tool installed via pipx or Homebrew

Verification: Tool works with config
```

### Dependency Graph

```
run_onchange (Homebrew packages)
  ↓
CLI Tool Configs (bat, lsd, btop, lazygit)
  ↓
Terminal Emulators (kitty, ghostty, wezterm)
  ↓
Shell Plugins (zsh-abbr, zgenom)

Parallel branch:
Bitwarden + age setup
  ↓
Security/Secrets (atuin, gpg, aider if needed)

Parallel branch:
OS detection (.chezmoiignore)
  ↓
macOS-specific (aerospace, karabiner)

Independent:
Basic Dotfiles (hushlogin, inputrc, etc.)
Large Directories (claude)
Dev Tools (aider)
```

## Dotbot Retirement Strategy

### Option 1: Gradual Migration (RECOMMENDED)

**Approach:** Migrate configs in phases, remove Dotbot files at end

**Process:**
1. **Phase 1-7**: Migrate configs one phase at a time
2. **After each phase**: Verify both systems work (Dotbot + chezmoi in parallel)
3. **After Phase 7 complete**: Test full chezmoi-only setup
4. **Final cleanup**: Remove Dotbot infrastructure

**Timeline:**
- Migration: 2-3 weeks (allows for validation)
- Cleanup: 1 day

**Pros:**
- Low risk — can rollback to Dotbot if issues
- Time to discover edge cases
- Both systems work during migration

**Cons:**
- Longer timeline
- Some configs duplicated temporarily

**Dotbot Removal Steps:**
```bash
# After all migrations verified
cd ~/.local/share/chezmoi

# Remove Dotbot files
rm install
rm -rf steps/
git rm --cached install steps/

# Remove submodules
git submodule deinit dotbot
git submodule deinit dotbot-brew
git submodule deinit dotbot-asdf
git rm dotbot dotbot-brew dotbot-asdf
rm -rf .git/modules/dotbot*

# Archive old Brewfiles (reference only)
mkdir -p archive
git mv Brewfile Brewfile_Client Brewfile_Fanaka archive/

# Update .gitmodules
rm .gitmodules  # if no other submodules

# Commit
git add -A
git commit -m "chore: retire Dotbot infrastructure, complete chezmoi migration"
```

### Option 2: All-at-Once Migration (NOT RECOMMENDED)

**Approach:** Migrate everything, delete Dotbot same day

**Pros:**
- Clean, fast cutover
- No hybrid state

**Cons:**
- High risk — no rollback path
- Discover issues in production
- Requires extensive pre-testing

**Only use if:**
- Full dry-run on VM successful
- Backup ready
- Comfortable with potential downtime

### Recommendation

Use **Option 1** (Gradual Migration):
1. Migrate Phase 1 (basic dotfiles)
2. Live with hybrid for 1-2 days, verify no issues
3. Migrate Phase 2 (CLI tools)
4. Continue through phases
5. After Phase 7, verify everything works via chezmoi
6. Remove Dotbot in single commit

**Verification before Dotbot removal:**
```bash
# 1. Check all files managed by chezmoi
chezmoi managed | wc -l  # Should cover all configs

# 2. Fresh apply test
chezmoi apply --dry-run --verbose  # No errors

# 3. Compare managed vs Dotbot symlinks
# Should be no overlap
```

## Integration Patterns

### Pattern 1: Simple Static Migration

```bash
# For basic dotfiles (hushlogin, inputrc, etc.)
chezmoi add ~/.hushlogin
chezmoi add ~/.inputrc

# Verify
chezmoi diff
```

### Pattern 2: Directory Migration

```bash
# For tool config directories
chezmoi add --recursive ~/.config/bat
chezmoi add --recursive ~/.config/lsd

# Verify structure preserved
ls -la ~/.local/share/chezmoi/dot_config/bat/
```

### Pattern 3: Template Conversion

```bash
# Add file first
chezmoi add ~/.config/atuin/config.toml

# Convert to template
chezmoi chattr +template ~/.config/atuin/config.toml

# Edit to add Bitwarden integration
chezmoi edit ~/.config/atuin/config.toml

# Apply and verify
chezmoi apply --dry-run --verbose
```

### Pattern 4: macOS-Only Exclusion

```bash
# Add config
chezmoi add ~/.config/aerospace/aerospace.toml

# Add to .chezmoiignore
echo '{{- if ne .chezmoi.os "darwin" }}' >> .chezmoiignore
echo '.config/aerospace' >> .chezmoiignore
echo '{{- end }}' >> .chezmoiignore
```

### Pattern 5: Large Directory with Ignores

```bash
# Add entire directory
chezmoi add --recursive ~/.config/claude

# Add selective ignores
cat >> .chezmoiignore <<EOF
.config/claude/cache/
.config/claude/*.log
.config/claude/temp/
EOF

# Verify what's tracked
chezmoi managed | grep claude
```

## File Modification vs New Files

### Existing Files That Need Updates

| File | Change Required | Why |
|------|----------------|-----|
| `.chezmoiignore` | Add macOS-only exclusions | aerospace, karabiner |
| `.chezmoidata.yaml` | No change needed | Packages already defined for bat, lsd, etc. |
| `dot_zshrc` | Possibly add zgenom init | If not present |
| `dot_zsh.d/variables.zsh` | Possibly template | If machine-specific paths |

### New Files to Create

All files listed in "File-by-File Integration Map" above are NEW to chezmoi source.

## Cross-Cutting Concerns

### .chezmoiignore Extensions

```
# .chezmoiignore additions

# macOS-only configs
{{- if ne .chezmoi.os "darwin" }}
.config/aerospace
.config/karabiner
.finicky.js
{{- end }}

# Linux-only configs (if any added later)
{{- if eq .chezmoi.os "darwin" }}
# (none currently)
{{- end }}

# Cache/generated files
.config/claude/cache/
.config/claude/*.log
.config/atuin/history.db
.config/atuin/records.db

# External directories not managed by chezmoi
.config/nvim
.zgenom
```

### Permission Verification Script Updates

`run_after_10-verify-permissions.sh` may need extension:

```bash
# Add to permission checks
check_file_permission "$HOME/.gnupg/gpg-agent.conf" 600
check_file_permission "$HOME/.config/atuin/config.toml" 600
# (if contains secrets)
```

### Secrets Management

**Files requiring Bitwarden integration:**
- `dot_config/atuin/config.toml.tmpl` — sync key/server
- `dot_aider.conf.yml.tmpl` — API keys (if present)
- `dot_config/claude/settings.json.tmpl` — auth tokens (if present)

**Pattern:**
```yaml
{{- if (bitwarden "item" "dotfiles/shared/tool-name") }}
api_key = "{{ (bitwardenFields "item" "dotfiles/shared/tool-name").api_key.value }}"
{{- end }}
```

## Testing Strategy

### Pre-Migration Verification

```bash
# 1. Document current Dotbot symlinks
cd ~/.dotfiles
./install --dry-run  # (if supported)
# OR manually verify:
ls -la ~ | grep "^l" > /tmp/dotbot-symlinks.txt

# 2. Backup current state
tar -czf ~/dotfile-backup-$(date +%Y%m%d).tar.gz ~/.dotfiles
tar -czf ~/home-backup-$(date +%Y%m%d).tar.gz \
  ~/.zshrc ~/.config ~/.claude ~/.gnupg ~/.inputrc ~/.hushlogin ~/.psqlrc ~/.sqliterc
```

### Per-Phase Verification

```bash
# After adding configs to chezmoi
chezmoi managed | grep "config-name"  # Verify tracked

# Dry run
chezmoi apply --dry-run --verbose

# Apply
chezmoi apply

# Verify tool works
<tool> --version
<tool> --help  # Check config loaded

# Compare with original
diff ~/.config/tool/config ~/.dotfiles/.config/tool/config
```

### Post-Migration Verification

```bash
# 1. Check all expected files present
chezmoi managed | wc -l  # Should match migration count

# 2. Fresh machine test (VM or Docker)
docker run -it ubuntu:latest /bin/bash
# Install chezmoi + dependencies
# chezmoi init --apply <repo>
# Verify everything applied

# 3. Shell functionality test
# Start new shell
zsh -l
# Test abbreviations, aliases, functions
# Test tool integrations (bat, lsd, atuin, lazygit)

# 4. Check no Dotbot remnants
ls -la ~ | grep "^l" | grep -v ".local/share/chezmoi"
# Should be minimal/none
```

## Rollback Strategy

### If Migration Issues Discovered

**Option 1: Revert Individual File**
```bash
# Remove from chezmoi
chezmoi forget ~/.config/tool/config

# Restore Dotbot symlink
cd ~/.dotfiles
./install  # Re-creates symlink
```

**Option 2: Full Rollback (Nuclear)**
```bash
# 1. Restore from backup
cd ~
tar -xzf ~/home-backup-YYYYMMDD.tar.gz

# 2. Re-run Dotbot
cd ~/.dotfiles
./install

# 3. Remove chezmoi-applied files (if needed)
chezmoi managed | xargs rm

# 4. Investigate issue before retry
```

## Success Criteria

Migration complete when:

- [ ] All files from `steps/terminal.yml` migrated to chezmoi source
- [ ] All configs in `.config/` migrated (except nvim, nushell)
- [ ] Claude Code directory fully tracked (~/.claude/)
- [ ] Basic dotfiles tracked (hushlogin, inputrc, etc.)
- [ ] macOS-only configs properly excluded on Linux
- [ ] Security configs use Bitwarden templates
- [ ] All phases verified working
- [ ] Dotbot infrastructure removed (install, steps/, submodules)
- [ ] Old Brewfiles archived
- [ ] README updated with chezmoi-only instructions
- [ ] Fresh machine test successful

## Architecture Decision Records

### ADR-1: Mirror Directory Structure for Large Configs

**Context:** `.claude/` has 50+ files across subdirectories

**Decision:** Mirror entire structure in chezmoi source as `dot_config/claude/`

**Rationale:**
- Preserves organization
- Easier to maintain
- Consistent with other tool configs
- chezmoi handles directories efficiently

**Alternatives Considered:**
- External symlink: Loses sync benefits
- Selective tracking: Too manual, error-prone

### ADR-2: Gradual Dotbot Retirement

**Context:** Risk of breaking working setup

**Decision:** Migrate in phases, run both systems in parallel, remove Dotbot at end

**Rationale:**
- Low risk — can rollback per phase
- Time to discover issues
- Validates each integration independently

**Alternatives Considered:**
- All-at-once: Too risky, no rollback

### ADR-3: Static Configs Unless Machine-Specific

**Context:** Template processing has overhead

**Decision:** Keep configs static unless they contain machine-specific values or secrets

**Rationale:**
- Faster chezmoi apply
- Simpler to maintain
- Follows principle of least complexity

**Identified Templates:**
- atuin config (sync secrets)
- wezterm (font size by OS)
- aider (API keys if present)
- claude settings (auth tokens if present)

### ADR-4: Use .chezmoiignore for macOS-Only Configs

**Context:** aerospace, karabiner are macOS-only

**Decision:** Add to chezmoi source, exclude on Linux via `.chezmoiignore` template

**Rationale:**
- Single source tree for all platforms
- Automatic exclusion based on OS detection
- Follows chezmoi best practices

**Alternatives Considered:**
- Separate branches: Too complex
- Manual exclusion: Error-prone

## References

### Existing Documentation
- `/Users/stephanlv_fanaka/Projects/dotfiles-zsh/README.md` — Current chezmoi setup
- `.planning/milestones/v1.0.0-ROADMAP.md` — Foundation milestone
- `.planning/research/ARCHITECTURE.md` — Previous research (v1.0.0)

### chezmoi Documentation
- [chezmoi Architecture](https://www.chezmoi.io/developer-guide/architecture/)
- [Manage Machine Differences](https://www.chezmoi.io/user-guide/manage-machine-to-machine-differences/)
- [Use Scripts](https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/)
- [Templating Guide](https://www.chezmoi.io/user-guide/templating/)
- [Customize Source Directory](https://www.chezmoi.io/user-guide/advanced/customize-your-source-directory/)

### Confidence Level

| Area | Confidence | Notes |
|------|------------|-------|
| Directory structure | HIGH | Extends proven v1.0.0 patterns |
| File mapping | HIGH | Clear from steps/terminal.yml |
| Template decisions | MEDIUM | Some configs may need templating discovered during migration |
| Build order | HIGH | Clear dependency graph |
| Dotbot retirement | HIGH | Low-risk gradual approach |
| Large directory handling | MEDIUM | Claude Code structure confirmed but not tested |

## Next Steps

1. Review this architecture with milestone orchestrator
2. Use this document to inform roadmap creation
3. Create detailed per-phase plans referencing these patterns
4. Begin Phase 1 (basic dotfiles) migration
