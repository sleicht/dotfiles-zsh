# Dotfiles

ZSH dotfiles for macOS, managed by **chezmoi** with cross-platform templating, **mise** for runtime versions, and **Bitwarden** for secrets.

## Quick Reference

```bash
chezmoi apply                   # Apply dotfiles changes
chezmoi edit ~/.zshrc           # Edit a managed file
chezmoi diff                    # Preview what would change
chezmoi add ~/.config/foo/bar   # Add a new file to chezmoi
chezmoi init                    # Re-initialise (after config changes)
```

## Fresh Machine Setup

```bash
# 1. Install chezmoi and clone
sh -c "$(curl -fsLS get.chezmoi.io)" -- init sleicht/dotfiles-zsh

# 2. Answer prompts (machine type, email)

# 3. Get age key from Bitwarden (needed to decrypt SSH keys)
mkdir -p ~/.config/age
bw login
export BW_SESSION="$(bw unlock --raw)"
bw get notes "dotfiles/personal/age-private-key" > ~/.config/age/key-personal.txt
chmod 600 ~/.config/age/key-personal.txt

# 4. Apply everything
chezmoi apply

# 5. Open a new terminal — done
```

## Architecture

```
chezmoi source (~/.local/share/chezmoi/)
├── .chezmoi.yaml.tmpl          # Config: machine type, encryption, Bitwarden
├── .chezmoidata.yaml           # Package lists (Homebrew taps, brews, casks)
├── .chezmoiignore              # Files excluded from chezmoi management
├── .gitleaks.toml              # Secret scanning allowlists
├── .pre-commit-config.yaml     # Pre-commit hooks for this repo
│
├── dot_zshrc                   # Shell config
├── dot_zshenv                  # Shell environment
├── dot_zprofile                # Shell profile
├── dot_zsh.d/                  # Modular shell configs (aliases, functions, etc.)
│
├── dot_gitconfig               # Global git config (aliases, core.hooksPath)
├── private_dot_gitconfig_local.tmpl  # Git user/email from Bitwarden
├── dot_Brewfile.tmpl           # Generated Homebrew bundle
│
├── private_dot_ssh/            # SSH keys (encrypted) + config
│   ├── encrypted_private_*.age # Age-encrypted private keys
│   ├── private_*.pub           # Public keys (unencrypted)
│   └── private_config          # SSH host config
│
├── private_dot_config/
│   ├── git/hooks/              # Global git hooks (gitleaks)
│   └── mise/config.toml.tmpl   # Runtime version management
│
└── run_*.sh.tmpl               # Automation scripts
```

## Tools

### chezmoi — Dotfiles Manager

chezmoi manages dotfiles via a source directory under git. Files are templated and deployed to `$HOME` on `chezmoi apply`.

**File naming conventions:**

| Prefix/Suffix | Meaning |
|---------------|---------|
| `dot_` | Deployed as `.` (e.g. `dot_zshrc` → `~/.zshrc`) |
| `private_` | Deployed with `600` permissions |
| `encrypted_` | Decrypted with age before deploying |
| `executable_` | Deployed with execute permission |
| `.tmpl` suffix | Processed as Go template |

**Workflow:**

```bash
# Option A: edit in source, then apply
chezmoi edit ~/.zshrc
chezmoi diff
chezmoi apply

# Option B: edit target directly, then sync back
vim ~/.zshrc
chezmoi re-add ~/.zshrc
```

Changes to the source directory are **auto-committed** to git but NOT auto-pushed. Push manually:

```bash
cd ~/.local/share/chezmoi && git push
```

### mise — Runtime Version Manager

mise replaces asdf/nvm/pyenv/rbenv. Global config is chezmoi-managed at `~/.config/mise/config.toml`.

**Global runtimes:**

| Runtime | Version |
|---------|---------|
| Node.js | LTS |
| Python | 3.12 |
| Go | 1.22 |
| Rust | stable |
| Java | temurin-25 |
| Ruby | 3 |
| Terraform | 1.9 |

**Usage:**

```bash
mise use --global node@22       # Change global version
mise use node@20                # Use version in current project
mise install                    # Install all versions from config
mise ls                         # List installed runtimes
```

mise reads `.tool-versions`, `.nvmrc`, and `.python-version` files automatically.

### Bitwarden — Secret Management

Secrets live in Bitwarden and are pulled into chezmoi templates at apply time. No secrets are committed to git.

**Naming convention:**

```
dotfiles/shared/git-config        # Shared across machine types
dotfiles/personal/age-private-key # Personal machine only
dotfiles/client/...               # Client/work machine only
```

**Using secrets in templates:**

```
{{ (bitwarden "item" "dotfiles/shared/git-config").login.username }}
{{ (bitwardenFields "item" "dotfiles/shared/git-config").personal_email.value }}
```

**Before applying templates that use Bitwarden:**

```bash
export BW_SESSION="$(bw unlock --raw)"
chezmoi apply
```

### age — File Encryption

SSH private keys are encrypted with age and stored safely in git. The age private key is the "root of trust" — it exists only on the local filesystem and in Bitwarden, never in the repo.

**Bootstrap chain:** Bitwarden → age key → SSH keys → full access

```bash
chezmoi add --encrypt ~/.ssh/id_ed25519   # Encrypt and add a key
chezmoi diff ~/.ssh/id_ed25519            # Verify decryption (no diff = OK)
```

Age key location: `~/.config/age/key-personal.txt` (or `key-client.txt`)

### gitleaks — Secret Scanning

gitleaks prevents accidentally committing secrets. It runs at two levels:

**Global git hooks** (all repos via `core.hooksPath = ~/.config/git/hooks`):
- **Pre-commit**: Warns about detected secrets, allows commit
- **Pre-push**: Blocks push if secrets detected

**Handling false positives:**

```bash
# Inline suppression
password = {{ (bitwarden "item" "x").login.password }} # gitleaks:allow

# Skip for one command
SKIP=gitleaks git commit -m "message"
SKIP=gitleaks git push
```

If a repo has its own `.git/hooks/pre-commit` (e.g. pre-commit framework), the global hooks delegate to it instead.

## Automation Scripts

These run automatically during `chezmoi apply`:

| Script | When | What |
|--------|------|------|
| `run_once_before_install-homebrew` | First apply | Installs Homebrew if missing |
| `run_onchange_after_01-install-packages` | Package list changes | Runs `brew bundle --global` |
| `run_onchange_after_02-cleanup-packages` | Package list changes | Removes stale packages |
| `run_once_after_generate-mise-completions` | First apply | Generates mise ZSH completions |
| `run_after_10-verify-permissions` | Every apply | Fixes permissions on sensitive files |

## Machine Types

chezmoi prompts for a machine type during `chezmoi init`:

| Type | Git email | Packages | Age key |
|------|-----------|----------|---------|
| `personal` | Personal email | common + fanaka | `key-personal.txt` |
| `client` | Work email | common + client | `key-client.txt` |

## Package Management

Packages are defined in `.chezmoidata.yaml` and installed via Homebrew:

```bash
chezmoi edit ~/.local/share/chezmoi/.chezmoidata.yaml   # Edit package list
chezmoi apply                                            # Triggers install if changed
brew bundle check --global                               # Verify everything installed
```

**Structure in `.chezmoidata.yaml`:**

```yaml
darwin:
  taps: [...]
  common_brews: [...]     # All machines
  common_casks: [...]
  client_brews: [...]     # Client machines only
  client_casks: [...]
  fanaka_brews: [...]     # Personal machines only
  fanaka_casks: [...]
```

## Common Tasks

### Add a new package

```bash
chezmoi edit ~/.local/share/chezmoi/.chezmoidata.yaml
# Add to common_brews, common_casks, etc.
chezmoi apply
```

### Add a new dotfile

```bash
chezmoi add ~/.config/tool/config.toml
# For sensitive files:
chezmoi add --encrypt ~/.config/tool/secrets.conf
```

### Rotate a secret

1. Update the value in Bitwarden
2. `export BW_SESSION="$(bw unlock --raw)"`
3. `chezmoi apply`

### Update runtime versions

```bash
chezmoi edit ~/.local/share/chezmoi/.chezmoidata.yaml
# Change tool versions under the tools section
chezmoi apply && mise install
```

### Run gitleaks manually

```bash
cd ~/.local/share/chezmoi
pre-commit run gitleaks --all-files
```

## File Permissions

The permission verification script runs on every `chezmoi apply` and ensures:

| Path | Permission |
|------|-----------|
| `~/.ssh/id_*` | 600 |
| `~/.ssh/config` | 600 |
| `~/.config/age/key-*.txt` | 600 |
| `~/.kube/config` | 600 |
| `~/.aws/credentials` | 600 |
| `~/.docker/config.json` | 600 |
| `~/.gnupg/private-keys-v1.d` | 700 |
| `~/.gitconfig_local` | 600 |

Fixes are logged to `~/.local/state/chezmoi/permission-fixes.log`.

## Claude Code Plugin

This repository includes a custom Claude Code plugin for git commits and GitLab merge requests following Conventional Commits with Jira ticket prefixes.

**Commands:** `/commit_message`, `/rewrite_commit_message`, `/merge_request_md`, `/create_merge_request`

Plugin location: `.config/claude/plugins/git-conventional-commits/`

## Credits

Inspired by [GitHub does dotfiles](https://dotfiles.github.io/), [Zach Holman](https://github.com/holman/dotfiles), [Mathias Bynens](https://github.com/mathiasbynens/dotfiles), and [Sourabh Bajaj's Mac Setup Guide](http://sourabhbajaj.com/mac-setup/).
