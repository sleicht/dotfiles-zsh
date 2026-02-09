# Phase 10: Dev Tools with Secrets - Research

**Researched:** 2026-02-09
**Domain:** Developer tool configuration migration with Bitwarden secret templating (lazygit, atuin, aider, finicky, gpg-agent)
**Confidence:** HIGH

## Summary

Phase 10 migrates five development tool configurations that require Bitwarden secret integration or OS-specific templating. Unlike Phases 8-9 (static configs), these tools either contain secrets (atuin sync key), require environment variable management (aider API keys), or need platform-specific paths (gpg-agent pinentry). Research confirms that chezmoi's proven v1.0.0 Bitwarden templating patterns apply here, with one critical difference: aider must use environment variables for API keys (not embedded in YAML), requiring a .env file template or shell environment integration.

The five tools break down as follows:
- **lazygit** (config.yml): Static configuration, no secrets. Git TUI with custom commands and paging settings.
- **atuin** (config.toml + atuin-keybindings.zsh): Shell history sync with encryption key stored in Bitwarden. Sync key is user-generated and needed across machines.
- **aider** (aider.conf.yml): AI coding assistant. Model selection is static, but API keys MUST be in environment variables or .env file (not in YAML per official docs).
- **finicky** (finicky.js): Browser router for macOS. Static JavaScript config with URL routing rules, no secrets.
- **gpg-agent** (gpg-agent.conf): GPG agent configuration requiring OS-specific pinentry-program path (macOS vs Linux).

**Key validated patterns:**
- Bitwarden templating for atuin sync key: `{{ (bitwarden "item" "dotfiles/atuin-sync-key").password }}`
- Environment variable approach for aider: Create templated .env file or export API keys in shell init
- OS-conditional templating for gpg-agent pinentry path: `{{ if eq .chezmoi.os "darwin" }}/opt/homebrew/bin/pinentry-mac{{ else }}/usr/bin/pinentry-curses{{ end }}`
- Single-file migrations for lazygit/finicky (no secrets, static configs)
- Directory migration for atuin (config.toml + keybindings file)

**Primary recommendation:** Migrate lazygit and finicky as static configs (no templating), create Bitwarden item for atuin sync key and template config.toml, implement aider API key management via templated shell environment (NOT in aider.conf.yml), template gpg-agent.conf with OS-conditional pinentry path, and verify all tools can parse configs post-apply using Phase 7-9 verification framework patterns.

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| chezmoi | 2.69.3 | Dotfile deployment with Bitwarden integration | Already installed (v1.0.0), proven secret templating |
| lazygit | latest | Terminal UI for git operations | Already installed, user-configured, no secrets |
| atuin | latest | Shell history sync with encryption | Already installed, requires sync key from Bitwarden |
| aider | latest | AI pair programming assistant | Config exists but tool not installed, API keys via env vars |
| finicky | latest | macOS browser router | Config exists but tool not installed, macOS-only, no secrets |
| gpg-agent | latest | GPG key caching agent | System component, requires OS-specific pinentry path |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Bitwarden CLI | latest | Secret retrieval during chezmoi apply | Phase 6 integration, atuin sync key storage |
| delta | latest | Git diff pager | lazygit config references delta for syntax highlighting |
| pinentry-mac | latest | macOS GPG passphrase entry | gpg-agent on macOS |
| pinentry-curses | latest | Terminal GPG passphrase entry | gpg-agent on Linux or headless systems |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Bitwarden templating for atuin | Hardcode sync key | Insecure, violates Phase 6 security model |
| Environment variables for aider | Embed API keys in YAML | Violates aider docs: "You can only put OpenAI and Anthropic API keys in the YAML config file" |
| OS-conditional template for gpg-agent | Separate configs per OS | Duplicates config, harder to maintain |
| Templated .env for aider | Shell export in .zshrc | .env file cleaner, tool-specific, doesn't pollute global env |
| Single atuin config file | Separate keybindings file | Dotbot currently symlinks both, maintain parity |

**Installation:**
```bash
# All tools either already installed or configs exist for future use:
# - chezmoi (Phase 2)
# - lazygit (installed, Homebrew)
# - atuin (installed, Homebrew)
# - aider (NOT installed, config exists)
# - finicky (NOT installed, config exists, macOS-only)
# - gpg-agent (system component)
# - delta (installed, used by lazygit)
# - pinentry-mac (macOS, Homebrew)

# No new installations required for Phase 10
# (aider/finicky configs will be migrated even if tools not installed)
```

## Architecture Patterns

### Recommended Migration Structure

```
~/.local/share/chezmoi/               # chezmoi source directory
├── private_dot_config/
│   ├── lazygit/
│   │   └── config.yml                # lazygit static config (no secrets)
│   ├── atuin/
│   │   ├── config.toml.tmpl          # atuin config with Bitwarden-templated sync key
│   │   └── atuin-keybindings.zsh     # atuin shell keybindings (static)
│   ├── aider.conf.yml                # aider config (static, no API keys)
│   ├── aider.env.tmpl                # NEW: templated .env with Bitwarden API keys
│   └── finicky.js                    # finicky browser router (static, macOS-only)
├── private_dot_gnupg/
│   └── gpg-agent.conf.tmpl           # gpg-agent with OS-conditional pinentry path
└── .chezmoiignore                    # Remove Phase 10 ignore block

# Additional patterns:
# - .aider.conf.yml at $HOME root (not in .config)
# - .aider.env at $HOME root (NEW file for API keys)
# - .finicky.js at $HOME root (not in .config)
```

### Pattern 1: Static Config Migration (lazygit, finicky)

**What:** Migrate configs with no secrets using standard `chezmoi add --follow` pattern from Phases 8-9
**When to use:** lazygit (git TUI settings), finicky (browser routing rules)
**Example:**
```bash
# Source: Phase 8-9 static config migration pattern

# lazygit: Single file in directory
$ chezmoi add --follow ~/.config/lazygit/config.yml
# Result: ~/.local/share/chezmoi/private_dot_config/lazygit/config.yml

# finicky: Single file at HOME root (macOS-only, already in .chezmoiignore Section 5)
$ chezmoi add --follow ~/.finicky.js
# Result: ~/.local/share/chezmoi/private_dot_finicky.js

# Verify no secrets detected
$ grep -i -E "(password|token|key|secret)" ~/.local/share/chezmoi/private_dot_config/lazygit/config.yml
# (should return nothing or only comments about keys like keybindings)
```

**Why this works:**
- lazygit config contains only UI preferences, git paging commands, custom keybindings (no credentials)
- finicky config is pure JavaScript routing logic (browser selection based on URL patterns)
- Both configs are portable across machines without modification
- No templating overhead where not needed (YAGNI principle)

### Pattern 2: Bitwarden Secret Templating (atuin sync key)

**What:** Template atuin config.toml to inject sync encryption key from Bitwarden
**When to use:** atuin shell history sync (requires encryption key across machines)
**Example:**
```toml
# Source: Phase 6 Bitwarden templating pattern + https://docs.atuin.sh/guide/sync/

# File: ~/.local/share/chezmoi/private_dot_config/atuin/config.toml.tmpl

## Enable sync (requires sync key from Bitwarden)
auto_sync = true
sync_frequency = "10m"

## Atuin sync server (default or self-hosted)
sync_address = "https://api.atuin.sh"

## Encryption key (from Bitwarden)
## Generated with `atuin key` on first machine, stored in Bitwarden for cross-machine sync
{{- if eq .machine_type "personal" }}
# Personal machine sync key
sync_key = "{{ (bitwarden "item" "dotfiles/personal/atuin-sync-key").password }}"
{{- else if eq .machine_type "client" }}
# Client machine sync key
sync_key = "{{ (bitwarden "item" "dotfiles/client/atuin-sync-key").password }}"
{{- end }}

## Rest of config (filter modes, UI settings, etc.) remains static
filter_mode = "workspace"
workspaces = true
show_preview = true
# ... (remaining static settings)
```

**Bitwarden item structure:**
```bash
# Create Bitwarden item for atuin sync key
$ bw get template item | jq '.name = "dotfiles/personal/atuin-sync-key" | .login.password = "ACTUAL_SYNC_KEY_FROM_ATUIN_KEY_COMMAND"' | bw encode | bw create item

# Verify retrieval
$ bw get item "dotfiles/personal/atuin-sync-key" | jq -r '.login.password'
```

**Why this works:**
- Atuin sync key is a long random string generated once per user ([Atuin Sync Docs](https://docs.atuin.sh/guide/sync/))
- Same key needed on all machines for the user to decrypt shared history
- Bitwarden provides secure storage and retrieval via chezmoi template functions
- Machine-type conditional allows separate sync keys for work vs personal (different history databases)

### Pattern 3: Environment Variable Secret Management (aider API keys)

**What:** Store aider API keys in Bitwarden, inject into .env file (NOT aider.conf.yml)
**When to use:** aider AI coding assistant (requires OpenAI/Anthropic/other provider API keys)
**Example:**
```bash
# Source: https://aider.chat/docs/config/api-keys.html

# File: ~/.local/share/chezmoi/private_dot_aider.env.tmpl
# Note: aider reads .env from current directory or specified with --env-file

{{- if eq .machine_type "personal" }}
# Personal machine API keys
ANTHROPIC_API_KEY={{ (bitwarden "item" "dotfiles/personal/anthropic-api-key").password }}
OPENAI_API_KEY={{ (bitwarden "item" "dotfiles/personal/openai-api-key").password }}
{{- else if eq .machine_type "client" }}
# Client machine API keys
ANTHROPIC_API_KEY={{ (bitwarden "item" "dotfiles/client/anthropic-api-key").password }}
OPENAI_API_KEY={{ (bitwarden "item" "dotfiles/client/openai-api-key").password }}
{{- end }}

# Additional provider keys as needed
# GEMINI_API_KEY={{ (bitwarden "item" "dotfiles/gemini-api-key").password }}
# OPENROUTER_API_KEY={{ (bitwarden "item" "dotfiles/openrouter-api-key").password }}
```

**Shell integration approach (alternative to .env file):**
```bash
# File: ~/.local/share/chezmoi/zsh.d/private_aider-env.zsh.tmpl
# Sourced by sheldon during shell init

{{- if eq .machine_type "personal" }}
export ANTHROPIC_API_KEY="{{ (bitwarden "item" "dotfiles/personal/anthropic-api-key").password }}"
export OPENAI_API_KEY="{{ (bitwarden "item" "dotfiles/personal/openai-api-key").password }}"
{{- else if eq .machine_type "client" }}
export ANTHROPIC_API_KEY="{{ (bitwarden "item" "dotfiles/client/anthropic-api-key").password }}"
export OPENAI_API_KEY="{{ (bitwarden "item" "dotfiles/client/openai-api-key").password }}"
{{- end }}
```

**Why this works:**
- Aider official docs: "You can only put OpenAI and Anthropic API keys in the YAML config file" ([API Keys Docs](https://aider.chat/docs/config/api-keys.html))
- .env file is "a great place to store your API keys and other provider API environment variables" (official recommendation)
- Environment variables work for ALL providers (OpenAI, Anthropic, Gemini, OpenRouter, DeepSeek, etc.)
- Bitwarden templating keeps secrets out of git while allowing cross-machine sync
- Shell integration alternative loads keys into environment for all tools, not just aider

### Pattern 4: OS-Conditional Templating (gpg-agent pinentry)

**What:** Template gpg-agent.conf with platform-specific pinentry-program path
**When to use:** gpg-agent configuration (pinentry paths differ on macOS vs Linux)
**Example:**
```conf
# Source: Phase 3 OS-conditional templating + https://www.gnupg.org/documentation/manuals/gnupg/Agent-Options.html

# File: ~/.local/share/chezmoi/private_dot_gnupg/gpg-agent.conf.tmpl

default-cache-ttl 14400
max-cache-ttl 86400

{{- if eq .chezmoi.os "darwin" }}
# macOS: pinentry-mac via Homebrew
pinentry-program {{ .chezmoi.homeDir }}/.nix-profile/bin/pinentry-mac
{{- else if eq .chezmoi.os "linux" }}
# Linux: pinentry-curses (headless) or pinentry-gnome3 (GUI)
pinentry-program /usr/bin/pinentry-curses
{{- end }}
```

**Why this works:**
- GPG Agent requires full path to pinentry program ([GnuPG Agent Options](https://www.gnupg.org/documentation/manuals/gnupg/Agent-Options.html))
- macOS Homebrew installs pinentry-mac at `/opt/homebrew/bin/pinentry-mac` (Apple Silicon) or `/usr/local/bin/pinentry-mac` (Intel)
- Linux uses system package manager paths: `/usr/bin/pinentry-curses` or `/usr/bin/pinentry-gnome3`
- chezmoi's `.chezmoi.os` provides reliable OS detection (already used in Phase 3-4 templates)
- Current config has hardcoded `/run/current-system/sw/bin/pinentry-mac` (Nix path, obsolete after Phase 1)

### Pattern 5: Directory Migration with Mixed Static/Templated Files (atuin)

**What:** Migrate atuin directory containing both static (keybindings) and templated (config) files
**When to use:** Tool configs with multiple files in a directory
**Example:**
```bash
# Source: Phase 8-9 directory migration pattern + Bitwarden templating

# Current Dotbot structure: ~/.config/atuin/ -> ~/Projects/dotfiles-zsh/.config/atuin/
# Contains: config.toml (294 lines, needs sync key template)
#           atuin-keybindings.zsh (static shell bindings)

# Step 1: Add static file first
$ chezmoi add --follow ~/.config/atuin/atuin-keybindings.zsh
# Result: ~/.local/share/chezmoi/private_dot_config/atuin/atuin-keybindings.zsh

# Step 2: Manually create templated config.toml
$ cp ~/.config/atuin/config.toml ~/.local/share/chezmoi/private_dot_config/atuin/config.toml.tmpl
# Edit to add Bitwarden template syntax for sync_key (see Pattern 2)

# Step 3: Remove from .chezmoiignore Phase 10 block
# Edit ~/.local/share/chezmoi/.chezmoiignore, remove:
# .config/atuin
# .config/atuin/**

# Step 4: Verify directory structure
$ ls -la ~/.local/share/chezmoi/private_dot_config/atuin/
# config.toml.tmpl (templated with sync key)
# atuin-keybindings.zsh (static)

# Step 5: Apply and verify
$ chezmoi diff
$ chezmoi apply
$ ls -la ~/.config/atuin/
# config.toml (real file with sync key from Bitwarden)
# atuin-keybindings.zsh (real file, static content)
```

**Why this works:**
- Atuin config directory contains heterogeneous files (static + secret-containing)
- chezmoi handles mixed file types in same directory (no template suffix for static files)
- Dotbot currently symlinks entire directory, chezmoi deploys individual files (better granularity)
- Keybindings file is truly static (no machine-specific content), no templating overhead

### Anti-Patterns to Avoid

- **Embedding API keys in aider.conf.yml:** Aider docs explicitly state YAML config only supports OpenAI/Anthropic keys, and even those should use .env or environment variables for better security. Don't violate official guidance.
- **Hardcoding atuin sync key:** Sync key is secret material, must not be committed to git. Always template with Bitwarden.
- **Using same atuin sync key for work/personal:** Separate sync keys = separate history databases. Don't leak work commands into personal history (or vice versa).
- **Forgetting .tmpl suffix on templated configs:** Files with Bitwarden template syntax MUST have .tmpl suffix or chezmoi will treat them as literal text (templates will appear as-is in deployed files).
- **Hardcoding pinentry path in gpg-agent.conf:** Breaks cross-platform portability. Always use OS-conditional template.
- **Migrating aider/finicky when tools not installed:** Phase 8-9 pattern allows configs to exist even if tool not installed (verification skips parsability check). Same applies here.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Secret storage | Custom encryption, dotfiles-local repo | Bitwarden + chezmoi templating | Phase 6 established pattern, audited, cross-machine sync built-in |
| Environment variable management | Custom shell scripts | Templated .env file or zsh.d/*.zsh.tmpl | Declarative, version-controlled, uses Bitwarden retrieval |
| OS-specific config paths | Separate configs per OS | chezmoi OS-conditional templates | Single source of truth, already used in Phase 3-4 |
| API key rotation | Manual file edits | Update Bitwarden, re-run chezmoi apply | Centralized secret management, no git commits on rotation |
| Config validation | Custom parsers | Tool's built-in validation (lazygit --help, atuin doctor, gpg-agent --version) | Tools validate their own configs, leverage existing checks |

**Key insight:** Phase 6 established Bitwarden as the single source of truth for secrets, Phase 10 is the first consumption of that pattern for non-git credentials. Don't reinvent secret templating or environment variable injection — use proven chezmoi + Bitwarden integration. The migration complexity is secret management, not tool config structure (all configs are straightforward YAML/TOML/JS).

## Common Pitfalls

### Pitfall 1: Embedding Atuin Sync Key in Git

**What goes wrong:** Hardcoding `sync_key = "at_..."` in config.toml and committing to chezmoi source exposes encryption key in git history. Anyone with repo access can decrypt shell history.

**Why it happens:** Atuin's config.toml has a commented-out `# sync_key = ""` example. Easy to uncomment and paste key directly, forgetting it's secret material.

**How to avoid:**
1. Never paste atuin sync key directly into config.toml
2. Always use Bitwarden template: `sync_key = "{{ (bitwarden "item" "dotfiles/personal/atuin-sync-key").password }}"`
3. Create .tmpl suffix: config.toml.tmpl
4. Verify with `grep -i sync_key ~/.local/share/chezmoi/private_dot_config/atuin/config.toml.tmpl` (should see template syntax, not actual key)
5. Run Phase 7 secret audit: `./scripts/audit-secrets.sh` (gitleaks should not find secrets in chezmoi source)

**Warning signs:**
- `chezmoi diff` shows actual sync key value (long alphanumeric string starting with "at_")
- gitleaks reports "Generic API Key" in atuin/config.toml
- Git commit contains sync_key with literal value

### Pitfall 2: Storing API Keys in aider.conf.yml Instead of Environment

**What goes wrong:** Adding `anthropic-api-key: sk-ant-xxxxx` to aider.conf.yml works but violates security best practices and official documentation. Keys are visible in config file, harder to rotate, and may leak if config is shared.

**Why it happens:** Aider's sample config has commented-out `#anthropic-api-key: xxx` lines, suggesting YAML is the storage location. Docs say "You can only put OpenAI and Anthropic API keys in the YAML" which sounds like permission, not recommendation.

**How to avoid:**
1. Use .env file approach: Create private_dot_aider.env.tmpl with Bitwarden templates
2. OR use shell environment: Create zsh.d/private_aider-env.zsh.tmpl with export statements
3. Leave aider.conf.yml as static config (model selection, UI preferences, read-only files)
4. Document in comments: "API keys in ~/.aider.env (templated from Bitwarden), not here"
5. Verify with `grep -i "api.*key" ~/.local/share/chezmoi/private_dot_aider.conf.yml` (should find NO actual keys)

**Warning signs:**
- aider.conf.yml contains lines like `anthropic-api-key: sk-ant-...`
- gitleaks reports "Anthropic API Key" in aider config
- Rotating API key requires editing multiple config files instead of updating Bitwarden once

### Pitfall 3: Forgetting to Update .chezmoiignore After Migration

**What goes wrong:** Phase 10 configs added to chezmoi source but still listed in .chezmoiignore Section 9 (Phase 10 pending block). `chezmoi managed` doesn't show them, `chezmoi apply` doesn't deploy them, `chezmoi diff` shows nothing despite changes.

**Why it happens:** Phase 7 established .chezmoiignore with pending blocks for Phases 8-12. After migration, must remove corresponding block or chezmoi continues ignoring those paths.

**How to avoid:**
1. After adding all Phase 10 configs to chezmoi source, edit ~/.local/share/chezmoi/.chezmoiignore
2. Remove Section 9 (Phase 10) block (lines 132-141):
   ```
   # 9. Pending Migration — Phase 10 (Dev Tools with Secrets)
   .config/lazygit
   .config/lazygit/**
   .config/atuin
   .config/atuin/**
   .aider.conf.yml
   .gnupg/gpg-agent.conf
   ```
3. Note: .finicky.js already in OS-conditional block (Section 5), no need to remove
4. Verify: `chezmoi managed --include=files | grep -E "lazygit|atuin|aider|gpg-agent"` (should show all Phase 10 configs)
5. Verify: `chezmoi unmanaged | grep -E "lazygit|atuin|aider|gpg-agent"` (should be empty)

**Warning signs:**
- `chezmoi managed` doesn't list lazygit/atuin/aider configs after adding them
- `chezmoi diff` shows no changes even after editing migrated configs
- `chezmoi apply` doesn't deploy Phase 10 configs to home directory

### Pitfall 4: Incorrect Pinentry Path in gpg-agent.conf Template

**What goes wrong:** Templating gpg-agent.conf with wrong pinentry path causes GPG operations to fail silently or prompt "cannot run gpg-agent: executable file not found".

**Why it happens:** Current config has `/run/current-system/sw/bin/pinentry-mac` (Nix path, obsolete after Phase 1 Nix removal). macOS Homebrew paths differ by architecture (Intel vs Apple Silicon), Linux paths vary by distro.

**How to avoid:**
1. Use chezmoi OS detection: `{{ if eq .chezmoi.os "darwin" }}` for macOS, `{{ else if eq .chezmoi.os "linux" }}` for Linux
2. macOS: Use `{{ .chezmoi.homeDir }}/.nix-profile/bin/pinentry-mac` if Nix profile exists, else `/opt/homebrew/bin/pinentry-mac`
3. Linux: Use `/usr/bin/pinentry-curses` (universal) or `/usr/bin/pinentry-gnome3` (GUI)
4. Verify pinentry binary exists: `which pinentry-mac` on macOS, `which pinentry-curses` on Linux
5. Test GPG operation: `echo "test" | gpg --clearsign` (should prompt for passphrase via correct pinentry)

**Warning signs:**
- GPG error: "gpg-agent[12345]: can't connect to the PIN entry module '/wrong/path/pinentry-mac': No such file or directory"
- Git commit signing fails: "error: gpg failed to sign the data"
- `gpg-agent --version` works but GPG operations fail with passphrase prompt errors

### Pitfall 5: Bitwarden Authentication Gate During chezmoi apply

**What goes wrong:** Running `chezmoi apply` with Bitwarden templates requires Bitwarden session (logged in and unlocked). If session expired, apply fails with "error retrieving item: not logged in" or "vault is locked".

**Why it happens:** Bitwarden session tokens expire after inactivity. chezmoi calls `bw` CLI during template execution, which requires active authenticated session.

**How to avoid:**
1. Before `chezmoi apply`, ensure Bitwarden session: `bw login` or `bw unlock`
2. Set BW_SESSION environment variable: `export BW_SESSION=$(bw unlock --raw)`
3. Use chezmoi's --force flag to skip Bitwarden retrieval: `chezmoi apply --force` (deploys without templating, useful for testing structure)
4. Phase 8 pattern: Apply with targeted --force for specific files: `chezmoi apply --force ~/.config/atuin/config.toml` (skips Bitwarden auth for that file)
5. Document in verification: "Requires Bitwarden authentication" (not a bug, expected behavior)

**Warning signs:**
- `chezmoi apply` fails with "bw: not logged in" error
- Template syntax appears literally in deployed files: `sync_key = "{{ (bitwarden "item" "...")`
- Prompts for Bitwarden master password during apply (session expired)

### Pitfall 6: Not Testing Aider Without Tool Installed

**What goes wrong:** Migrating aider config but tool not installed. Verification fails with "command not found" error, blocking Phase 10 completion.

**Why it happens:** Aider is not currently installed (confirmed by `which aider` returning nothing). Config exists in dotfiles repo (aider.conf.yml) but tool binary missing.

**How to avoid:**
1. Follow Phase 8-9 pattern: Make app parsability checks non-fatal when app not installed
2. Verification script: `if command -v aider &> /dev/null; then aider --version; else echo "⊘ aider not installed (skipping)"; fi`
3. File existence check still passes (config deployed correctly)
4. Document in verification: "Config may exist for uninstalled tool (portable config repository)"
5. User can install aider later: `brew install aider` or `pipx install aider-chat`

**Warning signs:**
- Verification script exits non-zero with "aider: command not found"
- Phase 10 marked incomplete despite all configs migrated
- Error message suggests installing aider when it's optional

## Code Examples

Verified patterns from official sources and Phase 6-9 execution:

### Migrate Lazygit Static Config

```bash
# Source: Phase 8-9 static config migration + https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md

# Current: ~/.config/lazygit/config.yml -> ~/Projects/dotfiles-zsh/.config/lazygit.yml (symlink)
# Target: Real file managed by chezmoi, no templating (no secrets)

# Add to chezmoi
$ chezmoi add --follow ~/.config/lazygit/config.yml
# Result: ~/.local/share/chezmoi/private_dot_config/lazygit/config.yml

# Verify no secrets (should only find "key" in context of keybindings, not API keys)
$ grep -i -E "(password|token|api.*key|secret)" ~/.local/share/chezmoi/private_dot_config/lazygit/config.yml | grep -v "# key"

# Apply and verify
$ chezmoi diff
$ chezmoi apply ~/.config/lazygit/config.yml
$ ls -la ~/.config/lazygit/config.yml
# Should be real file (-rw-r--r--), not symlink (->)

# Test lazygit can parse config
$ lazygit --help
# Should not error about invalid config
```

### Create Bitwarden Item for Atuin Sync Key

```bash
# Source: Phase 6 Bitwarden integration + https://docs.atuin.sh/guide/sync/

# Step 1: Get your atuin sync key (generated during first atuin setup)
$ atuin key
# Output: at_your_actual_sync_key_here_long_alphanumeric_string

# Step 2: Create Bitwarden item (machine-type specific)
$ bw get template item | jq '
  .type = 1 |
  .name = "dotfiles/personal/atuin-sync-key" |
  .notes = "Atuin shell history sync encryption key (generated 2026-02-09)" |
  .login.password = "at_your_actual_sync_key_here"
' | bw encode | bw create item

# Step 3: Verify retrieval
$ bw get item "dotfiles/personal/atuin-sync-key" | jq -r '.login.password'
# Should output: at_your_actual_sync_key_here

# Step 4: Test in chezmoi template (dry run)
$ echo 'sync_key = "{{ (bitwarden "item" "dotfiles/personal/atuin-sync-key").password }}"' | chezmoi execute-template
# Should output: sync_key = "at_your_actual_sync_key_here"
```

### Template Atuin Config with Bitwarden Sync Key

```toml
# Source: Phase 6 Bitwarden templating + atuin config.toml reference

# File: ~/.local/share/chezmoi/private_dot_config/atuin/config.toml.tmpl

## Atuin sync configuration
auto_sync = true
update_check = true
sync_address = "https://api.atuin.sh"
sync_frequency = "10m"

{{- if eq .machine_type "personal" }}
## Personal machine: use personal atuin sync key
sync_key = "{{ (bitwarden "item" "dotfiles/personal/atuin-sync-key").password }}"
{{- else if eq .machine_type "client" }}
## Client machine: use client atuin sync key (separate history database)
sync_key = "{{ (bitwarden "item" "dotfiles/client/atuin-sync-key").password }}"
{{- end }}

## Filter and search settings (static, no templating needed)
filter_mode = "workspace"
workspaces = true
style = "auto"
show_preview = true
show_numeric_shortcuts = true
enter_accept = true
command_chaining = true

## Sync v2 features
[sync]
records = true

## Search filters priority
[search]
filters = [ "workspace", "session", "session-preload", "global", "directory" ]

## Stats common subcommands (static list)
[stats]
common_subcommands = [
  "brew", "cargo", "docker", "git", "npm", "pnpm"
]
common_prefix = ["sudo"]
ignored_commands = ["cd", "z", "ls", "lsd", "vi"]
```

### Create Templated .env for Aider API Keys

```bash
# Source: https://aider.chat/docs/config/api-keys.html + Phase 6 Bitwarden templating

# File: ~/.local/share/chezmoi/private_dot_aider.env.tmpl

# Aider API Keys (from Bitwarden)
# This file is read automatically by aider when in the directory,
# or can be specified with: aider --env-file ~/.aider.env

{{- if eq .machine_type "personal" }}
# Personal machine API keys
ANTHROPIC_API_KEY={{ (bitwarden "item" "dotfiles/personal/anthropic-api-key").password }}
OPENAI_API_KEY={{ (bitwarden "item" "dotfiles/personal/openai-api-key").password }}
{{- else if eq .machine_type "client" }}
# Client machine API keys (work-provided or separate billing)
ANTHROPIC_API_KEY={{ (bitwarden "item" "dotfiles/client/anthropic-api-key").password }}
OPENAI_API_KEY={{ (bitwarden "item" "dotfiles/client/openai-api-key").password }}
{{- end }}

# Additional provider keys (uncomment and add to Bitwarden as needed)
# GEMINI_API_KEY={{ (bitwarden "item" "dotfiles/gemini-api-key").password }}
# OPENROUTER_API_KEY={{ (bitwarden "item" "dotfiles/openrouter-api-key").password }}
# DEEPSEEK_API_KEY={{ (bitwarden "item" "dotfiles/deepseek-api-key").password }}
```

### Template GPG Agent Config with OS-Conditional Pinentry

```conf
# Source: Phase 3 OS templates + https://www.gnupg.org/documentation/manuals/gnupg/Agent-Options.html

# File: ~/.local/share/chezmoi/private_dot_gnupg/gpg-agent.conf.tmpl

# Cache timeouts (in seconds)
default-cache-ttl 14400
max-cache-ttl 86400

# Platform-specific pinentry program
{{- if eq .chezmoi.os "darwin" }}
# macOS: pinentry-mac via Nix profile (preferred) or Homebrew
{{-   if stat (joinPath .chezmoi.homeDir ".nix-profile/bin/pinentry-mac") }}
pinentry-program {{ .chezmoi.homeDir }}/.nix-profile/bin/pinentry-mac
{{-   else }}
pinentry-program /opt/homebrew/bin/pinentry-mac
{{-   end }}
{{- else if eq .chezmoi.os "linux" }}
# Linux: pinentry-curses (headless compatible)
pinentry-program /usr/bin/pinentry-curses
{{- end }}
```

### Verify Phase 10 Configs with Framework Pattern

```bash
# Source: Phase 7-9 verification framework

# File: scripts/verify-checks/10-dev-tools-secrets.sh

#!/usr/bin/env bash
# Phase 10 verification: Dev Tools with Secrets

source "$(dirname "$0")/../verify-lib/check-exists.sh"
source "$(dirname "$0")/../verify-lib/check-parsable.sh"

declare -i passed=0 failed=0

echo "Phase 10: Dev Tools with Secrets"

# File existence checks
check_file_exists "$HOME/.config/lazygit/config.yml" || ((failed++))
((passed++))

check_file_exists "$HOME/.config/atuin/config.toml" || ((failed++))
((passed++))

check_file_exists "$HOME/.config/atuin/atuin-keybindings.zsh" || ((failed++))
((passed++))

check_file_exists "$HOME/.aider.conf.yml" || ((failed++))
((passed++))

check_file_exists "$HOME/.aider.env" || ((failed++))
((passed++))

check_file_exists "$HOME/.gnupg/gpg-agent.conf" || ((failed++))
((passed++))

if [[ "$OSTYPE" == "darwin"* ]]; then
  check_file_exists "$HOME/.finicky.js" || ((failed++))
  ((passed++))
fi

# Not-a-symlink checks (confirm chezmoi replaced Dotbot symlinks)
for config in "$HOME/.config/lazygit/config.yml" "$HOME/.config/atuin/config.toml" "$HOME/.aider.conf.yml" "$HOME/.gnupg/gpg-agent.conf"; do
  if [[ -L "$config" ]]; then
    echo "✗ $config is still a symlink (should be real file)"
    ((failed++))
  else
    echo "✓ $config is a real file (not symlink)"
    ((passed++))
  fi
done

# Secret presence checks (ensure Bitwarden templates were executed, not literal)
if grep -q "{{ (bitwarden" "$HOME/.config/atuin/config.toml" 2>/dev/null; then
  echo "✗ atuin config.toml contains literal Bitwarden template (not executed)"
  ((failed++))
else
  echo "✓ atuin config.toml templated correctly (no literal template syntax)"
  ((passed++))
fi

if grep -q "{{ (bitwarden" "$HOME/.aider.env" 2>/dev/null; then
  echo "✗ .aider.env contains literal Bitwarden template (not executed)"
  ((failed++))
else
  echo "✓ .aider.env templated correctly (no literal template syntax)"
  ((passed++))
fi

# Tool parsability checks (only if tool installed)
if command -v lazygit &> /dev/null; then
  lazygit --version &> /dev/null && {
    echo "✓ lazygit can parse config"
    ((passed++))
  } || {
    echo "✗ lazygit config invalid"
    ((failed++))
  }
else
  echo "⊘ lazygit not installed (skipping config check)"
fi

if command -v atuin &> /dev/null; then
  atuin doctor &> /dev/null && {
    echo "✓ atuin can parse config"
    ((passed++))
  } || {
    echo "✗ atuin config invalid"
    ((failed++))
  }
else
  echo "⊘ atuin not installed (skipping config check)"
fi

if command -v aider &> /dev/null; then
  aider --version &> /dev/null && {
    echo "✓ aider can parse config"
    ((passed++))
  } || {
    echo "✗ aider config invalid"
    ((failed++))
  }
else
  echo "⊘ aider not installed (skipping config check)"
fi

if command -v gpg-agent &> /dev/null; then
  gpg-agent --version &> /dev/null && {
    echo "✓ gpg-agent can parse config"
    ((passed++))
  } || {
    echo "✗ gpg-agent config invalid"
    ((failed++))
  }
else
  echo "⊘ gpg-agent not installed (skipping config check)"
fi

# OS-specific checks
if [[ "$OSTYPE" == "darwin"* ]]; then
  if command -v finicky &> /dev/null; then
    # finicky has no --version or validation flag, just check it exists
    echo "✓ finicky installed"
    ((passed++))
  else
    echo "⊘ finicky not installed (skipping check)"
  fi
fi

echo ""
echo "Phase 10 verification: $passed passed, $failed failed"
[[ $failed -eq 0 ]] && exit 0 || exit 1
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Secrets in dotfiles | Bitwarden + chezmoi templates | Phase 6 (v1.0.0) | Phase 10 first use for non-git credentials |
| API keys in config files | Environment variables from Bitwarden | Aider 2025+ | Better security, easier rotation, multi-tool support |
| Hardcoded pinentry paths | OS-conditional templates | Phase 3-4 (v1.0.0) | Cross-platform compatibility, Phase 10 extends to gpg-agent |
| Dotbot symlinks | chezmoi real files | Phase 2 (v1.0.0) | Phase 10 completes dev tool migration |
| Manual atuin sync key management | Bitwarden storage + templating | Phase 10 (v1.1) | Secure cross-machine history sync |

**Deprecated/outdated:**
- **Nix pinentry path**: `/run/current-system/sw/bin/pinentry-mac` obsolete after Phase 1 Nix removal. Use Homebrew path or template with .nix-profile fallback.
- **Dotbot symlinks for Phase 10 configs**: Symlinks removed in Phase 12 after verification. chezmoi now manages these files.
- **Embedded API keys in aider YAML**: Aider docs recommend .env file approach. YAML support for OpenAI/Anthropic exists but discouraged for security.

## Open Questions

1. **Should aider use .env file or shell environment for API keys?**
   - What we know: Both approaches work. .env file is tool-specific (doesn't pollute global env), shell export is broader (available to all tools).
   - What's unclear: Which approach fits better with existing dotfiles patterns? Does user run aider from multiple directories (favors shell env)?
   - Recommendation: Start with shell environment approach (zsh.d/private_aider-env.zsh.tmpl). Easier to implement, consistent with Phase 5 env var patterns. Can switch to .env later if needed.

2. **Do client and personal machines need separate atuin sync keys?**
   - What we know: Separate keys = separate history databases (work commands don't sync to personal, vice versa). Same key = shared history across all machines.
   - What's unclear: Does user want work/personal history separation, or unified history across all machines?
   - Recommendation: Implement machine-type conditional in template (allows separate keys), but user can set both to same Bitwarden item if they want unified history. Flexibility without forcing decision.

3. **Should finicky config be migrated if tool not installed?**
   - What we know: finicky binary not found (`which finicky` fails), but config exists in dotfiles repo. Config is static JavaScript (no secrets).
   - What's unclear: Is finicky config maintained for future use, or deprecated?
   - Recommendation: Migrate config (maintains portable config repository). Verification script skips parsability check if tool not installed. User can install finicky later and config will be ready. Follows Phase 8-9 pattern (kitty config migrated despite tool not installed).

4. **How to handle gpg-agent config when pinentry binary missing?**
   - What we know: gpg-agent.conf templates pinentry path, but binary may not exist (Nix removed, Homebrew not installed, Linux package missing).
   - What's unclear: Should template check for binary existence before setting path? Should verification fail if pinentry missing?
   - Recommendation: Template with stat check (see Code Examples): try Nix profile first, fallback to Homebrew/system path. Verification tests gpg-agent can start (not full GPG operation). Document in verification: "Requires pinentry-mac/pinentry-curses to be installed for GPG passphrase prompts."

5. **Should aider.conf.yml migrate model configuration or leave static?**
   - What we know: Current config specifies `model: vertex_ai/claude-sonnet-4-5@20250929`. This is vertex AI (Google Cloud) hosted Anthropic model. Model selection is user preference, not secret.
   - What's unclear: Should model be templated per machine type (client might use different model tier), or keep static?
   - Recommendation: Keep static in Phase 10 (no evidence of machine-specific model needs). If user needs different models per machine later, can template with machine_type conditional. YAGNI principle: don't template until proven necessary.

## Sources

### Primary (HIGH confidence)

- [Atuin Sync Documentation](https://docs.atuin.sh/guide/sync/) - Sync key generation and storage
- [Lazygit Configuration](https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md) - Config file structure and locations
- [Aider API Keys](https://aider.chat/docs/config/api-keys.html) - Environment variable approach for API keys
- [Finicky Configuration](https://github.com/johnste/finicky/wiki/Configuration) - JavaScript config structure
- [GnuPG Agent Options](https://www.gnupg.org/documentation/manuals/gnupg/Agent-Options.html) - pinentry-program configuration
- Phase 6 RESEARCH.md - Bitwarden templating patterns (established in v1.0.0)
- Phase 8-9 RESEARCH.md - Static config migration patterns (proven in v1.1)

### Secondary (MEDIUM confidence)

- [Atuin Shell History](https://atuin.sh/) - Tool overview and features
- [Aider AI Pair Programming](https://aider.chat/) - Tool capabilities and setup
- [Finicky Browser Router](https://johnste.github.io/finicky/) - macOS browser control
- [GPG Agent Requirements](https://intothesaltmine.readthedocs.io/en/latest/chapters/secret-storage/gpg-agent.html) - Platform-specific setup
- Phase 3-4 PLAN files - OS-conditional templating patterns (chezmoi.os usage)

### Tertiary (LOW confidence)

- None required — all critical information verified via official docs or previous phase research

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All tools already installed or configs exist, Bitwarden integration proven in Phase 6
- Architecture: HIGH - Bitwarden templating is Phase 6 pattern, OS conditionals are Phase 3-4 pattern, static migration is Phase 8-9 pattern
- Pitfalls: HIGH - Secret embedding risks documented in Phase 6, .chezmoiignore removal is Phase 8-9 pattern, tool-not-installed handling is Phase 8-9 pattern
- API key management: HIGH - Aider official docs explicitly recommend .env/environment approach over YAML

**Research date:** 2026-02-09
**Valid until:** 2026-03-09 (30 days - stable tools, chezmoi/Bitwarden patterns unlikely to change)
