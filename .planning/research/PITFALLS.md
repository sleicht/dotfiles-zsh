# Pitfalls Analysis: chezmoi + mise Migration

## Executive Summary

This document identifies critical mistakes and gotchas when migrating from Nix/Dotbot/asdf to chezmoi/mise. Based on real-world migration experiences and community-reported issues, these pitfalls are organized by migration phase with early warning signs and prevention strategies.

**Migration Context:**
- **Source:** Dotbot (symlinks), asdf (version management), Nix (package management)
- **Target:** chezmoi (templates), mise (version management)
- **Platforms:** macOS + Linux cross-platform support
- **Type:** Brownfield migration of working setup

---

## 1. chezmoi Migration Pitfalls

### 1.1 Workflow Paradigm Shift

**Problem:** Dotbot uses symlinks from `~/.dotfiles` to `~/`, allowing direct editing in home directory. chezmoi uses templates in source directory (`~/.local/share/chezmoi`) that must be edited first, then applied.

**Common Mistake:**
```bash
# User edits file in home directory
vim ~/.zshrc

# Runs chezmoi add, loses template logic
chezmoi add ~/.zshrc  # DESTROYS TEMPLATES!
```

**Warning Signs:**
- Template syntax (`{{ }}`) disappearing from source files
- Platform-specific logic being removed
- Having to manually re-add conditional blocks

**Prevention:**
1. **ALWAYS** edit in source directory: `chezmoi edit ~/.zshrc`
2. Use `chezmoi diff` before `chezmoi apply`
3. Set up editor integration: `export EDITOR=vim` in shell RC
4. Consider adding a pre-commit hook to detect accidental template removal

**Recovery:**
```bash
# If you accidentally overwrote templates
cd ~/.local/share/chezmoi
git log --all -- dot_zshrc.tmpl  # Find last good version
git checkout <commit> -- dot_zshrc.tmpl
```

**References:**
- [Dotfiles Management with Dotbot and Chezmoi](https://myhomelab.gr/automation/2025/06/26/dotfiles-management.html)
- [How to modify a dotfile not through chezmoi?](https://github.com/twpayne/chezmoi/discussions/1598)

---

### 1.2 Template Syntax Errors

**Problem:** chezmoi uses Go's `text/template` with strict error handling (`missingkey=error`). Common errors break entire apply process.

**Common Mistakes:**

1. **Misspelled template variables:**
```go
{{ .chezmoi.os }}        # Correct
{{ .chezmoi.operating }} # ERROR: missing key
```

2. **Whitespace pollution:**
```go
# Before - leaves blank lines
{{ if eq .chezmoi.os "darwin" }}
export HOMEBREW_PREFIX="/opt/homebrew"
{{ end }}

# After - clean output
{{- if eq .chezmoi.os "darwin" }}
export HOMEBREW_PREFIX="/opt/homebrew"
{{- end }}
```

3. **Missing template functions in `.chezmoitemplates/`:**
```go
# This won't work in .chezmoitemplates files (historical limitation)
{{ lookPath "brew" }}
```

**Warning Signs:**
- `chezmoi apply` fails with template parsing errors
- Extra blank lines in generated files
- "missing key" errors during apply

**Prevention:**
1. Test templates before applying:
```bash
chezmoi execute-template '{{ .chezmoi.os }}'
chezmoi execute-template < ~/.local/share/chezmoi/dot_zshrc.tmpl
```

2. Use `{{-` and `-}}` for whitespace control
3. Set explicit defaults:
```go
{{ .mykey | default "fallback_value" }}
```

4. Debug with verbose mode:
```bash
chezmoi apply --verbose --dry-run
```

**References:**
- [Templating - chezmoi](https://www.chezmoi.io/user-guide/templating/)
- [Template clutter · Issue #2608](https://github.com/twpayne/chezmoi/issues/2608)
- [chezmoi templating errors common mistakes](https://github.com/twpayne/chezmoi/discussions/1670)

---

### 1.3 Incomplete Initial Migration

**Problem:** Migrating some files but not others creates inconsistent state. Symlinks and chezmoi-managed files coexist, causing confusion.

**Common Mistake:**
```bash
# Dotbot still managing some files
~/.zshrc -> ~/.dotfiles/zshrc  # Symlink from Dotbot

# chezmoi managing others
~/.config/git/config  # Managed by chezmoi

# Result: Two sources of truth, merge conflicts
```

**Warning Signs:**
- Mix of symlinks and regular files in home directory
- Changes applied in wrong tool
- `ls -la ~/.*` shows inconsistent file types
- Dotbot installation still running on machine

**Prevention:**
1. **Complete migration in phases:**
   - Phase 1: Import all Dotbot-managed files to chezmoi
   - Phase 2: Verify with `chezmoi diff`
   - Phase 3: Remove Dotbot symlinks
   - Phase 4: Delete old Dotbot installation script

2. **Migration checklist:**
```bash
# 1. Initialize chezmoi
chezmoi init

# 2. Import ALL dotbot files
for file in $(dotbot-list-files); do
    chezmoi add "$file"
done

# 3. Verify import
chezmoi status

# 4. Remove dotbot symlinks ONLY after verification
./dotbot-uninstall  # If you have this script

# 5. First commit to chezmoi repo
cd ~/.local/share/chezmoi
git add -A
git commit -m "feat: initial migration from dotbot"
```

3. **Document migration status** in `.planning/progress.md`

**Recovery:**
If you have partial migration:
```bash
# List what chezmoi manages
chezmoi managed

# List what dotbot manages
grep -r "link:" ~/.dotfiles/steps/

# Resolve conflicts manually
```

**References:**
- [Migrating from another dotfile manager - chezmoi](https://www.chezmoi.io/migrating-from-another-dotfile-manager/)

---

### 1.4 Git History Confusion

**Problem:** chezmoi creates its own Git repository in `~/.local/share/chezmoi`. Users confuse this with their dotfiles repo, or fail to version control it.

**Common Mistakes:**
1. Editing files in chezmoi source but not committing
2. Pushing to wrong repository
3. Losing work during `chezmoi init --apply` on new machine

**Warning Signs:**
- `git status` in `~/` shows nothing despite chezmoi changes
- Unable to pull dotfiles on new machine
- `~/.local/share/chezmoi/.git` doesn't exist or has no remotes

**Prevention:**
1. **Set up Git remote immediately after init:**
```bash
chezmoi cd
git remote add origin git@github.com:user/dotfiles.git
git branch -M main
git push -u origin main
```

2. **Use chezmoi's Git integration:**
```bash
chezmoi git status        # Instead of cd + git status
chezmoi git add .
chezmoi git commit -m "message"
chezmoi git push
```

3. **Verify remote before applying on new machine:**
```bash
# On new machine
chezmoi init git@github.com:user/dotfiles.git
chezmoi diff  # Review before applying
chezmoi apply
```

**Recovery:**
```bash
# If you lost uncommitted changes
chezmoi cd
git reflog  # May find lost work

# If you never set up remote
chezmoi cd
git remote add origin <your-repo-url>
git push -u origin main
```

**References:**
- [After use "chezmoi -v apply", can I recovery my file?](https://github.com/twpayne/chezmoi/issues/1779)
- [Why use chezmoi?](https://www.chezmoi.io/why-use-chezmoi/)

---

## 2. mise Migration Pitfalls

### 2.1 asdf 0.16+ Compatibility Breaking

**Problem:** mise was designed for asdf ≤0.15 (bash). asdf 0.16+ (Go rewrite) introduced `asdf set` command that conflicts with mise's `mise set`, breaking command compatibility.

**Common Mistakes:**
1. Running both asdf and mise simultaneously
2. Expecting 100% command parity
3. Using new asdf 0.16+ workflows with mise

**Warning Signs:**
- Commands like `asdf global` work in asdf but fail in mise
- `.tool-versions` file not being respected
- WARN messages during `mise activate`

**Prevention:**
1. **Complete cut-over, not gradual:**
```bash
# DON'T: Run both tools
eval "$(asdf activate)"  # ❌
eval "$(mise activate zsh)"  # ❌

# DO: Complete migration
asdf uninstall --all     # Remove all asdf-managed tools
rm -rf ~/.asdf           # Remove asdf
eval "$(mise activate zsh)"  # ✓
```

2. **Migrate data before removing asdf:**
```bash
# Backup asdf state
cp ~/.tool-versions ~/.tool-versions.backup

# Let mise read existing .tool-versions
mise install  # Installs versions from .tool-versions

# Verify installation
mise ls

# Only then remove asdf
```

3. **Update CI/CD and team documentation:**
- Update `.gitlab-ci.yml`, GitHub Actions, etc.
- Document breaking change for team members
- Set migration deadline (e.g., GitLab dropped asdf by July 31, 2025)

**Recovery:**
```bash
# If mise activation shows warnings
mise upgrade  # Migrates data

# If both tools installed
which asdf mise  # Verify paths
# Remove asdf from PATH in shell RC files
```

**References:**
- [Comparison to asdf | mise-en-place](https://mise.jdx.dev/dev-tools/comparison-to-asdf.html)
- [Migrating from asdf to mise without the headaches](https://dev.to/0xkoji/migrating-from-asdf-to-mise-without-the-headaches-1jp3)
- [Could not ignore warning from mise activate](https://github.com/jdx/mise/discussions/4789)

---

### 2.2 Plugin Reinstallation Required

**Problem:** mise does NOT reuse asdf installation directories. All tools must be reinstalled, even if asdf versions are already present.

**Common Mistake:**
```bash
# User assumes mise will find asdf installations
mise install node@20.0.0  # Downloads and installs again!

# Old asdf directory left behind
~/.asdf/installs/node/20.0.0  # Still taking disk space
```

**Warning Signs:**
- Disk usage doubles during migration
- Long download/compile times despite having tools installed
- Two copies of same tool version

**Prevention:**
1. **Plan for reinstallation time:**
   - Node.js with native modules: 5-10 minutes per version
   - Python with compiled extensions: 10-20 minutes per version
   - Ruby: 15-30 minutes per version

2. **Migrate during low-usage period:**
```bash
# Install all tools before switching shell activation
mise install  # Read from .tool-versions, install all

# Verify everything installed
mise ls

# Only then activate mise in shell
```

3. **Clean up asdf directories after migration:**
```bash
# After successful mise migration
du -sh ~/.asdf/installs/*  # See disk usage
rm -rf ~/.asdf  # Frees significant disk space
```

**Optional: Manual Directory Move** (advanced, not officially supported):
```bash
# If you want to avoid reinstallation (NOT RECOMMENDED)
# mise installations go to ~/.local/share/mise/installs/
mv ~/.asdf/installs/node/20.0.0 ~/.local/share/mise/installs/node/20.0.0
mise reshim node@20.0.0
```

**References:**
- [FAQs | mise-en-place](https://mise.jdx.dev/faq.html)
- [Migrating from asdf to mise (en place)](https://christiantietze.de/posts/2025/07/migrating-asdf-to-mise-en-place/)

---

### 2.3 Shell Activation Performance Regression

**Problem:** `eval "$(mise activate zsh)"` can add 100-200ms to shell startup, noticeable compared to asdf.

**Common Mistakes:**
1. Not using lazy loading for non-interactive shells
2. Running activation in wrong shell init file
3. Not using shims for IDE/script usage

**Warning Signs:**
```bash
# Measure startup time
time zsh -i -c exit
# Before: 50ms
# After mise: 250ms  # ⚠️ 5x slower
```

**Prevention:**

1. **Use shims for non-interactive contexts:**
```bash
# .zshrc
if [[ -o interactive ]]; then
    eval "$(mise activate zsh)"
else
    # Use shims for scripts/IDE
    export PATH="$HOME/.local/share/mise/shims:$PATH"
fi
```

2. **Cache activation output** (advanced):
```bash
# Use evalcache or similar
_mise_cache="${XDG_CACHE_HOME:-$HOME/.cache}/mise_activation.zsh"
if [[ ! -f "$_mise_cache" ]] || [[ ~/.config/mise/config.toml -nt "$_mise_cache" ]]; then
    mise activate zsh > "$_mise_cache"
fi
source "$_mise_cache"
```

3. **Profile startup to identify culprit:**
```bash
# Add to top of .zshrc
zmodload zsh/zprof

# Add to bottom of .zshrc
zprof
```

4. **Consider mise alternatives for specific tools:**
```bash
# If only using Node.js, consider fnm (faster)
# If only using Python, consider uv (faster)
# mise excels with multiple language ecosystems
```

**Comparison:**
- **mise activate:** ~60-100ms (generally acceptable)
- **nvm:** ~1500ms (mise is 15x faster)
- **asdf:** ~80-120ms (similar to mise)

**References:**
- [Is it normal that eval "$(mise activate zsh)" is adding ~100-200ms delay?](https://github.com/jdx/mise/discussions/4821)
- [Optimizing Zsh Init with ZProf](https://www.mikekasberg.com/blog/2025/05/29/optimizing-zsh-init-with-zprof.html)
- [Speeding Up Zsh](https://www.joshyin.cc/blog/speeding-up-zsh)

---

### 2.4 Command Syntax Differences

**Problem:** mise commands differ slightly from asdf, breaking muscle memory and scripts.

**Common Mistakes:**
```bash
# asdf syntax
asdf install node 20.0.0      # Space-separated
asdf global node 20.0.0

# mise syntax (preferred)
mise install node@20.0.0      # @ separator
mise use --global node@20.0.0

# mise also supports asdf-style for compatibility
mise install node 20.0.0      # Works but not idiomatic
```

**Warning Signs:**
- Typing `asdf` commands in mise shell
- Scripts using old syntax
- Team members confused by syntax differences

**Prevention:**

1. **Use mise aliases for asdf commands:**
```bash
# .zshrc
alias asdf="mise"  # Temporary during migration
```

2. **Update all scripts before migration:**
```bash
# Find all asdf usage in scripts
rg "asdf (install|global|local)" ~/bin ~/scripts

# Update to mise syntax
sed -i 's/asdf install \([^ ]*\) \([^ ]*\)/mise install \1@\2/g' script.sh
```

3. **Document syntax mapping for team:**
```markdown
| asdf Command | mise Equivalent |
|--------------|----------------|
| asdf install node 20.0.0 | mise install node@20.0.0 |
| asdf global node 20.0.0 | mise use --global node@20.0.0 |
| asdf local node 20.0.0 | mise use node@20.0.0 |
| asdf current | mise ls --current |
| asdf list all node | mise ls-remote node |
```

**References:**
- [Mise vs asdf: Which Version Manager Should You Choose?](https://betterstack.com/community/guides/scaling-nodejs/mise-vs-asdf/)
- [Dev Tools | mise-en-place](https://mise.jdx.dev/dev-tools/)

---

## 3. Cross-Platform Gotchas

### 3.1 Path Differences Between macOS and Linux

**Problem:** macOS and Linux use different standard paths for applications and configuration.

**Common Mistakes:**

1. **Hardcoding macOS paths:**
```bash
# ❌ Won't work on Linux
export HOMEBREW_PREFIX="/opt/homebrew"

# ✓ Platform-specific
{{ if eq .chezmoi.os "darwin" }}
export HOMEBREW_PREFIX="/opt/homebrew"
{{ else if eq .chezmoi.os "linux" }}
export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
{{ end }}
```

2. **Application support directories:**
```bash
# macOS
~/Library/Application Support/app/config

# Linux
~/.config/app/config

# chezmoi solution: use .chezmoiignore
# .chezmoiignore
{{ if ne .chezmoi.os "darwin" }}
Library/
{{ end }}

{{ if ne .chezmoi.os "linux" }}
.config/app/
{{ end }}
```

3. **Tool availability:**
```bash
# ❌ Assumes GNU tools
sed -i 's/old/new/g' file  # Fails on macOS (BSD sed)

# ✓ Platform-aware
{{ if eq .chezmoi.os "darwin" }}
sed -i '' 's/old/new/g' file
{{ else }}
sed -i 's/old/new/g' file
{{ end }}
```

**Warning Signs:**
- Templates work on one OS but fail on another
- `chezmoi apply` errors about missing directories
- Scripts failing with "command not found" on one platform

**Prevention:**

1. **Use chezmoi's OS detection:**
```go
{{ if eq .chezmoi.os "darwin" }}macOS-specific{{ end }}
{{ if eq .chezmoi.os "linux" }}Linux-specific{{ end }}
{{ if eq .chezmoi.osRelease.id "ubuntu" }}Ubuntu-specific{{ end }}
```

2. **Test on both platforms before committing:**
```bash
# Use VM or Docker for testing
docker run -it ubuntu:latest /bin/bash
chezmoi init --apply https://github.com/user/dotfiles.git
```

3. **Document platform-specific requirements:**
```markdown
# README.md
## Platform Notes

### macOS
- Requires Homebrew at /opt/homebrew (Apple Silicon) or /usr/local (Intel)

### Linux
- Tested on Ubuntu 22.04+, Fedora 38+
- Requires linuxbrew or system package manager
```

**Path Reference Table:**

| Purpose | macOS | Linux |
|---------|-------|-------|
| Homebrew | `/opt/homebrew` (ARM)<br>`/usr/local` (Intel) | `/home/linuxbrew/.linuxbrew` |
| Config | `~/Library/Application Support/` | `~/.config/` |
| Cache | `~/Library/Caches/` | `~/.cache/` |
| Data | `~/Library/Application Support/` | `~/.local/share/` |

**References:**
- [Cross-Platform Dotfiles with Chezmoi, Nix, Brew, and Devpod](https://alfonsofortunato.com/posts/dotfile/)
- [Manage machine-to-machine differences - chezmoi](https://www.chezmoi.io/user-guide/manage-machine-to-machine-differences/)

---

### 3.2 Package Manager Differences

**Problem:** Homebrew package names and availability differ between macOS and Linux. Some packages don't exist on Linux.

**Common Mistakes:**

1. **Assuming identical package names:**
```bash
# macOS Brewfile
brew "fd"       # fd-find on macOS

# Linux
brew "fd-find"  # Different name!
```

2. **Using macOS-only casks on Linux:**
```bash
# Brewfile
cask "rectangle"  # macOS-only, fails on Linux
```

3. **Not handling missing packages gracefully:**
```bash
# Script assumes tool exists
fd --type f  # Fails if fd not installed
```

**Warning Signs:**
- `brew bundle` fails on one platform
- Different tool versions between platforms
- Missing commands after applying dotfiles

**Prevention:**

1. **Use platform-specific Brewfiles with chezmoi:**
```bash
# .chezmoidata.yaml
brewfiles:
  common: "Brewfile"
  darwin: "Brewfile.darwin"
  linux: "Brewfile.linux"

# Brewfile.darwin.tmpl
{{ if eq .chezmoi.os "darwin" }}
cask "rectangle"
cask "iterm2"
{{ end }}

# Brewfile.linux.tmpl
{{ if eq .chezmoi.os "linux" }}
brew "fd-find"
tap "homebrew/linux-fonts"
{{ end }}

# Brewfile.tmpl (common)
brew "git"
brew "zsh"
brew "ripgrep"
```

2. **Use package aliases in scripts:**
```bash
# Detect correct command name
if command -v fd >/dev/null; then
    alias fd-find=fd
fi

# Now use fd-find consistently
fd-find --type f
```

3. **Document platform-specific package decisions:**
```markdown
# .planning/decisions/package-managers.md

## Package Manager Strategy

- **Common packages:** Defined in Brewfile.tmpl
- **macOS-specific:** Brewfile.darwin.tmpl (casks, macOS-only tools)
- **Linux-specific:** Brewfile.linux.tmpl (alternatives to casks)
- **Fallbacks:** Use apt/dnf for Linux-only tools not in Homebrew
```

**Alternative Approach: Nix for Cross-Platform**
```bash
# If you want truly identical packages
# Consider keeping Nix for package management
# Use chezmoi for dotfiles only

# .config/nixpkgs/home.nix
{ pkgs, ... }: {
  home.packages = with pkgs; [
    fd  # Same name on macOS and Linux
    ripgrep
    bat
  ];
}
```

**References:**
- [Cross-Platform Dotfiles with Chezmoi, Nix, Brew, and Devpod](https://medium.com/@alfor93/cross-platform-dotfiles-with-chezmoi-nix-brew-and-devpod-0fdb478e40ce)

---

### 3.3 Shell Configuration File Differences

**Problem:** Different shells and platforms load different startup files in different orders.

**Common Mistakes:**

1. **Putting PATH in wrong file:**
```bash
# ❌ .zshrc - loaded after PATH is already set
export PATH="/usr/local/bin:$PATH"

# ✓ .zshenv - loaded first for all shells
export PATH="/usr/local/bin:$PATH"
```

2. **Interactive-only config in non-interactive file:**
```bash
# ❌ .zshenv - runs for all shells, even scripts
eval "$(mise activate zsh)"  # Slows down scripts!

# ✓ .zshrc - only for interactive shells
if [[ -o interactive ]]; then
    eval "$(mise activate zsh)"
fi
```

3. **Not understanding load order:**
```
Login shell: .zshenv → .zprofile → .zshrc → .zlogin
Non-login: .zshenv → .zshrc
Script: .zshenv only
```

**Warning Signs:**
- Environment variables not available in scripts
- PATH includes duplicate entries
- Shell startup extremely slow

**Prevention:**

1. **Follow file purpose convention:**
```bash
# .zshenv - Environment variables, PATH (minimal, always loaded)
export XDG_CONFIG_HOME="$HOME/.config"
export EDITOR="vim"
export PATH="$HOME/.local/bin:$PATH"

# .zprofile - Login shell setup (once per login)
eval "$(/opt/homebrew/bin/brew shellenv)"

# .zshrc - Interactive configuration (aliases, prompts, plugins)
if [[ -o interactive ]]; then
    eval "$(mise activate zsh)"
    eval "$(starship init zsh)"
    source ~/.config/zsh/aliases.zsh
fi

# .zlogin - Post-setup tasks (rarely used)
```

2. **Use chezmoi templates for shell detection:**
```bash
# dot_zshrc.tmpl
{{ if eq .chezmoi.shell "zsh" }}
# ZSH-specific config
{{ else if eq .chezmoi.shell "bash" }}
# Bash-specific config
{{ end }}
```

3. **Test both login and non-login shells:**
```bash
# Login shell
zsh --login -c 'echo $PATH'

# Non-login interactive
zsh -i -c 'echo $PATH'

# Script (non-interactive)
zsh -c 'echo $PATH'
```

**Shell Load Order Reference:**

| Shell Type | Files Loaded (in order) |
|------------|------------------------|
| **zsh login** | `.zshenv` → `.zprofile` → `.zshrc` → `.zlogin` |
| **zsh non-login interactive** | `.zshenv` → `.zshrc` |
| **zsh script** | `.zshenv` only |
| **bash login** | `.bash_profile` OR `.bash_login` OR `.profile` |
| **bash interactive** | `.bashrc` |

**References:**
- [Zsh/Bash startup files loading order](https://medium.com/@rajsek/zsh-bash-startup-files-loading-order-bashrc-zshrc-etc-e30045652f2e)
- [Shell Startup Order](https://gist.github.com/ChristopherA/396fd161e4462597cae8a9dc8c0c58e3)
- [Sebastian Hoß – chezmoi & shell init scripts](https://seb.xn--ho-hia.de/posts/shell-init/)

---

## 4. Shell Startup Risks

### 4.1 Catastrophic Syntax Errors

**Problem:** A single syntax error in `.zshrc` can prevent all new shells from starting, locking you out of terminal.

**Common Mistakes:**
```bash
# Typo in .zshrc
export PATH="$HOME/bin:$PATH  # Missing closing quote

# Result: Shell won't start, can't fix the file!
```

**Warning Signs:**
- Terminal windows fail to open
- SSH sessions immediately disconnect
- Error messages about parsing before shell prompt

**Prevention:**

1. **ALWAYS test before applying:**
```bash
# Test zsh syntax without executing
zsh -n ~/.zshrc  # Dry-run syntax check

# Test in subshell before committing
zsh -c 'source ~/.zshrc && echo "OK"'

# Use chezmoi's dry-run
chezmoi apply --dry-run --verbose
```

2. **Keep emergency access:**
```bash
# Before migration, create recovery script
cat > ~/recover-shell.sh << 'EOF'
#!/bin/sh
# Uses /bin/sh (POSIX shell, always available)
mv ~/.zshrc ~/.zshrc.broken
mv ~/.zshrc.backup ~/.zshrc
echo "Shell recovered. Check ~/.zshrc.broken for errors."
EOF
chmod +x ~/recover-shell.sh

# If locked out, can run: sh ~/recover-shell.sh
```

3. **Use chezmoi's backup feature:**
```bash
# .chezmoi.toml.tmpl
[edit]
  command = "vim"

[apply]
  keepBackup = true  # Saves backups before applying
```

4. **Incremental migration:**
```bash
# Don't migrate everything at once
# Start with minimal .zshrc that sources old config
cat >> ~/.zshrc << 'EOF'
# Temporary during migration
if [ -f ~/.zshrc.old ]; then
    source ~/.zshrc.old
fi

# New chezmoi-managed config below
EOF
```

**Recovery:**

If you're locked out:

```bash
# Method 1: Use /bin/sh (fallback shell)
/bin/sh
export HOME=/Users/username
mv ~/.zshrc ~/.zshrc.broken
cp ~/.zshrc.backup ~/.zshrc

# Method 2: Use another terminal (if GUI works)
# Open Terminal.app preferences
# Set shell to /bin/bash temporarily

# Method 3: Single user mode (macOS)
# Reboot and hold Cmd+S
# mount -uw /
# cd /Users/username
# mv .zshrc .zshrc.broken

# Method 4: SSH from another machine
ssh -t user@host /bin/sh
```

**References:**
- [Debugging Shell Startup Performance](https://jannismain.github.io/posts/pyenv-shell-performance-issues/)
- [DotFiles - Greg's Wiki](https://mywiki.wooledge.org/DotFiles)

---

### 4.2 PATH Pollution and Order Issues

**Problem:** Multiple tools (Homebrew, mise, Nix, system) prepending to PATH causes:
1. Wrong tool versions executing
2. Duplicate PATH entries
3. Performance degradation (searching many paths)

**Common Mistakes:**

1. **Duplicate PATH additions:**
```bash
# .zshenv
export PATH="/opt/homebrew/bin:$PATH"

# .zprofile (mistake)
export PATH="/opt/homebrew/bin:$PATH"

# .zshrc (mistake)
export PATH="/opt/homebrew/bin:$PATH"

# Result: PATH has tripled entries!
echo $PATH
# /opt/homebrew/bin:/opt/homebrew/bin:/opt/homebrew/bin:...
```

2. **Wrong precedence order:**
```bash
# Intended: Use mise-managed Node.js
# Actual PATH order:
/usr/bin                              # System Node (v16) ⚠️ USED
/opt/homebrew/bin                     # Homebrew Node (v18)
~/.local/share/mise/installs/node/20  # mise Node (v20) - intended!

# Result: Wrong Node version!
which node
# /usr/bin/node
```

3. **Not cleaning up old tool paths:**
```bash
# Migrated from asdf, but old path still present
export PATH="$HOME/.asdf/shims:$PATH"        # Dead path
export PATH="$HOME/.local/share/mise/shims:$PATH"  # Current
```

**Warning Signs:**
```bash
# Check for issues
echo $PATH | tr ':' '\n' | nl  # See order and duplicates

# Find duplicates
echo $PATH | tr ':' '\n' | sort | uniq -d

# Check which binary is used
which -a node  # Shows all matches in PATH

# PATH is suspiciously long
echo $PATH | wc -c  # > 2000 chars is problematic
```

**Prevention:**

1. **Idempotent PATH additions:**
```bash
# Function to add to PATH only if not present
path_prepend() {
    case ":$PATH:" in
        *:"$1":*) ;;
        *) export PATH="$1:$PATH" ;;
    esac
}

path_prepend "$HOME/.local/bin"
path_prepend "/opt/homebrew/bin"
```

2. **Establish clear precedence order:**
```bash
# .zshenv - Set PATH in correct priority order
# Highest priority first!

# 1. User local binaries (highest priority)
export PATH="$HOME/.local/bin:$PATH"

# 2. mise shims (managed tool versions)
export PATH="$HOME/.local/share/mise/shims:$PATH"

# 3. Homebrew
export PATH="/opt/homebrew/bin:$PATH"

# 4. System paths (already in PATH)
# /usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
```

3. **Clean PATH before setting:**
```bash
# Advanced: Start with minimal PATH, build up
# .zshenv
typeset -U path  # ZSH: Unique values only in $path array

path=(
    $HOME/.local/bin
    $HOME/.local/share/mise/shims
    /opt/homebrew/bin
    /usr/local/bin
    /usr/bin
    /bin
    /usr/sbin
    /sbin
)
export PATH
```

4. **Document PATH strategy:**
```markdown
# .planning/decisions/path-strategy.md

## PATH Precedence Order

1. `~/.local/bin` - User scripts (highest priority)
2. `~/.local/share/mise/shims` - Version-managed tools
3. `/opt/homebrew/bin` - Homebrew packages
4. `/usr/local/bin` - Legacy Homebrew (Intel Mac)
5. `/usr/bin` - System binaries
6. `/bin` - Essential system binaries
7. `/usr/sbin` - System admin binaries
8. `/sbin` - Essential system admin binaries
```

5. **Regular PATH audits:**
```bash
# Add to .zshrc (development only)
if [[ -n "$DEBUG_PATH" ]]; then
    echo "=== PATH Audit ==="
    echo $PATH | tr ':' '\n' | nl
    echo "=== Checking for duplicates ==="
    echo $PATH | tr ':' '\n' | sort | uniq -d
fi

# Use: DEBUG_PATH=1 zsh
```

**Recovery:**
```bash
# If PATH is completely broken
export PATH="/usr/bin:/bin:/usr/sbin:/sbin"  # Minimal working PATH

# Reload shell config to rebuild PATH
source ~/.zshenv
source ~/.zprofile
source ~/.zshrc
```

**References:**
- [The PATH Environment Variable, Dotfiles and Shell Configuration Files](https://jamesdonnelly.dev/blog/path-environment-dotfiles-shell-config/)
- [Change order of PATH entries on Mac OS X](https://daniel.hepper.net/blog/2011/02/change-order-of-path-entries-on-mac-os-x/)

---

### 4.3 Slow Startup Time (Death by a Thousand Cuts)

**Problem:** Each tool (Homebrew, mise, Starship, etc.) adds initialization time. Combined, shell startup can go from 50ms to 2-5 seconds.

**Common Mistakes:**

1. **Running expensive commands on every shell:**
```bash
# ❌ Each adds 50-200ms
eval "$(brew shellenv)"           # ~50ms
eval "$(mise activate zsh)"       # ~100ms
eval "$(starship init zsh)"       # ~80ms
eval "$(direnv hook zsh)"         # ~60ms
eval "$(zoxide init zsh)"         # ~40ms
# Total: ~330ms JUST for these 5 lines!
```

2. **No lazy loading:**
```bash
# ❌ Loads nvm on every shell start
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # ~1500ms!
```

3. **Compinit called multiple times:**
```bash
# .zshrc runs compinit
autoload -Uz compinit && compinit  # ~100ms

# Oh-My-Zsh ALSO runs compinit
source $ZSH/oh-my-zsh.sh  # Another ~100ms
```

**Warning Signs:**
```bash
# Profile shell startup
time zsh -i -c exit
# Good: < 100ms
# Acceptable: 100-300ms
# Poor: 300-1000ms
# Terrible: > 1000ms

# Use zprof to identify culprits
# Add to top of .zshrc:
zmodload zsh/zprof

# Add to bottom of .zshrc:
zprof | head -20
```

**Prevention:**

1. **Lazy load non-essential tools:**
```bash
# Instead of immediate loading
eval "$(nvm init)"

# Lazy load on first use
nvm() {
    unfunction nvm  # Remove this function
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm "$@"  # Call real nvm with original args
}
```

2. **Cache eval outputs:**
```bash
# Cache expensive evals
_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
mkdir -p "$_cache_dir"

_cached_eval() {
    local cache_file="$_cache_dir/$1.zsh"
    local source_file="$2"

    if [[ ! -f "$cache_file" ]] || [[ "$source_file" -nt "$cache_file" ]]; then
        eval "$3" > "$cache_file"
    fi
    source "$cache_file"
}

# Usage
_cached_eval "starship" "$HOME/.config/starship.toml" "starship init zsh"
_cached_eval "mise" "$HOME/.config/mise/config.toml" "mise activate zsh"
```

3. **Use compile-once strategies:**
```bash
# Compile .zshrc for faster loading
zcompile ~/.zshrc

# Auto-recompile when changed
if [[ ! -f ~/.zshrc.zwc ]] || [[ ~/.zshrc -nt ~/.zshrc.zwc ]]; then
    zcompile ~/.zshrc
fi
```

4. **Optimize compinit:**
```bash
# Run once daily, not every shell
autoload -Uz compinit
setopt EXTENDEDGLOB
for dump in ~/.zcompdump(N.mh+24); do
    compinit
done
unsetopt EXTENDEDGLOB
compinit -C  # Use cached .zcompdump
```

5. **Defer non-critical initialization:**
```bash
# Use zsh-defer or similar
source ~/zsh-defer/zsh-defer.plugin.zsh

# Defer slow initializations
zsh-defer eval "$(direnv hook zsh)"
zsh-defer eval "$(zoxide init zsh)"
```

**Performance Targets:**

| Category | Time | Status |
|----------|------|--------|
| Excellent | < 100ms | Immediate feel |
| Good | 100-200ms | Barely noticeable |
| Acceptable | 200-500ms | Slight delay |
| Poor | 500-1000ms | Noticeable lag |
| Unacceptable | > 1000ms | User frustration |

**Profiling Tools:**
```bash
# 1. Simple timing
time zsh -i -c exit

# 2. Detailed profiling
zmodload zsh/zprof
# (add to .zshrc, reload shell)
zprof | head -20

# 3. Trace execution
zsh -x -i -c exit 2>&1 | less

# 4. Third-party tools
# zinit-profiling: https://github.com/zdharma-continuum/zinit
# zsh-bench: https://github.com/romkatv/zsh-bench
```

**References:**
- [Debugging Shell Startup Performance](https://jannismain.github.io/posts/pyenv-shell-performance-issues/)
- [Speeding Up Zsh](https://www.joshyin.cc/blog/speeding-up-zsh)
- [Optimizing Zsh Init with ZProf](https://www.mikekasberg.com/blog/2025/05/29/optimizing-zsh-init-with-zprof.html)
- [Slow startup performance on nvm and rvm](https://github.com/webpro/dotfiles/issues/8)

---

## 5. Secret and Credential Migration Risks

### 5.1 Accidental Secret Leakage to Git

**Problem:** During migration, secrets from old dotfiles get committed to public Git repository. This is the #1 security mistake in dotfiles.

**Common Mistakes:**

1. **Not reviewing files before `chezmoi add`:**
```bash
# ❌ Blindly adding all files
chezmoi add ~/.aws/credentials  # LEAKS AWS KEYS!
chezmoi add ~/.netrc            # LEAKS API TOKENS!
chezmoi add ~/.ssh/id_rsa       # LEAKS PRIVATE KEY!

cd ~/.local/share/chezmoi
git add -A
git commit -m "Initial migration"
git push  # ⚠️ SECRETS NOW PUBLIC!
```

2. **Secrets in `.env` files:**
```bash
# .env (accidentally committed)
OPENAI_API_KEY=sk-proj-abc123...
DATABASE_PASSWORD=hunter2
GITHUB_TOKEN=ghp_xyz789...
```

3. **API keys in shell history:**
```bash
# .zsh_history (if managed by chezmoi)
export STRIPE_SECRET_KEY=sk_live_...
curl -H "Authorization: Bearer ghp_..."
```

**Warning Signs:**
```bash
# Check for potential secrets before committing
cd ~/.local/share/chezmoi
git diff --cached | grep -E '(api[_-]?key|password|secret|token|private[_-]?key)'

# Scan with specialized tools
gitleaks detect --source .
trufflehog git file://.
```

**Prevention:**

1. **Use `.chezmoiignore` for secret files:**
```bash
# .chezmoiignore
.env
.env.local
.env.*.local
.netrc
.aws/credentials
.ssh/*_rsa
.ssh/*_ed25519
**/*_secret*
**/*.key
```

2. **Use chezmoi's template for secrets:**
```bash
# Store secret keys in encrypted file
chezmoi add --encrypt ~/.aws/credentials

# Use template to inject secrets
# dot_config/github/token.tmpl
{{ (onepasswordRead "op://Personal/GitHub/token").value }}

# Use chezmoi's secret management
{{ (secret "github_token") }}
```

3. **Pre-commit hooks to prevent leaks:**
```bash
# .git/hooks/pre-commit (in chezmoi source dir)
#!/bin/bash
if git diff --cached | grep -E '(sk-|ghp_|sk_live_)'; then
    echo "ERROR: Potential secret detected in commit!"
    echo "Review changes and use encrypted templates instead."
    exit 1
fi

# Automated secret scanning
gitleaks protect --staged || exit 1
```

4. **Separate secret files with naming convention:**
```bash
# Pattern: .local or _secret suffix
.zshrc.local       # Not managed by chezmoi
.env.secret        # Not managed by chezmoi

# Load in main config
# .zshrc
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
```

5. **Review migration with security focus:**
```bash
# Before first push, audit all files
cd ~/.local/share/chezmoi
find . -type f -not -path './.git/*' | while read file; do
    echo "=== Reviewing $file ==="
    grep -E '(password|secret|key|token)' "$file" || echo "OK"
done
```

**Most Commonly Leaked Credentials:**
1. GitHub API keys (most common)
2. AWS credentials
3. SSH private keys
4. Twitter/X API tokens
5. OpenAI API keys
6. Database passwords

**Recovery (if secrets already leaked):**

```bash
# 1. IMMEDIATELY rotate all leaked credentials
# - GitHub: https://github.com/settings/tokens
# - AWS: https://console.aws.amazon.com/iam/
# - SSH: ssh-keygen -t ed25519 (new key)

# 2. Remove from Git history (BFG Repo-Cleaner)
brew install bfg
bfg --delete-files credentials ~/.local/share/chezmoi
cd ~/.local/share/chezmoi
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# 3. Force push (WARNING: Destructive)
git push --force

# 4. Notify anyone who forked/cloned
# Their copies still have secrets!
```

**References:**
- [Dotfiles Security: How to Stop Leaking Secrets on GitHub](https://instatunnel.my/blog/why-your-public-dotfiles-are-a-security-minefield)
- [Why Your Public Dotfiles are a Security Minefield](https://medium.com/@instatunnel/why-your-public-dotfiles-are-a-security-minefield-fc9bdff62403)
- [Manage Sensitive API Keys in Public Dotfiles Using PGP and SOPS](https://dev.to/wiresurfer/manage-sensitive-api-keys-in-public-dotfiles-using-pgp-and-sops-5mn)
- [Keep sensitive data encrypted in dotfiles](https://www.outcoldman.com/en/archive/2015/09/17/keep-sensitive-data-encrypted-in-dotfiles/)

---

### 5.2 Insecure File Permissions

**Problem:** Secrets stored with wrong permissions allow unauthorized access from other users, processes, or compromised scripts on the same system.

**Common Mistakes:**

1. **World-readable secret files:**
```bash
# After chezmoi apply
ls -la ~/.ssh/id_rsa
-rw-r--r-- 1 user user 2602 Jan 25 12:00 /home/user/.ssh/id_rsa
#    ↑↑↑ ❌ Anyone can read private key!

# Correct:
chmod 600 ~/.ssh/id_rsa
-rw------- 1 user user 2602 Jan 25 12:00 /home/user/.ssh/id_rsa
#    ↑↑↑ ✓ Only owner can read
```

2. **Not setting permissions in chezmoi:**
```bash
# chezmoi resets permissions on every apply
chmod 600 ~/.ssh/id_rsa
chezmoi apply  # Resets back to 644!
```

3. **Group/other readable credentials:**
```bash
# ❌ Environment files
-rw-r--r-- .env              # 644: Other users can read!
-rw-rw-r-- .aws/credentials  # 664: Group can read!

# ✓ Correct
-rw------- .env              # 600: Owner only
-rw------- .aws/credentials  # 600: Owner only
```

**Warning Signs:**
```bash
# Find world-readable files in home directory
find ~ -type f -perm -004 -name '.*' 2>/dev/null

# Find files with group read permissions
find ~ -type f -perm -040 -name '.*' 2>/dev/null

# Check specific sensitive files
ls -la ~/.ssh ~/.aws ~/.gnupg ~/.config/**/credentials
```

**Prevention:**

1. **Set permissions in chezmoi source:**
```bash
# Mark file as private (600 permissions)
chezmoi add --private ~/.ssh/id_rsa

# Creates: private_dot_ssh/private_id_rsa
# Result after apply: -rw------- ~/.ssh/id_rsa

# Mark as executable and private (700)
chezmoi add --private --executable ~/bin/secret-script

# Mark as read-only (444)
chezmoi add --readonly ~/.config/app/immutable-config
```

2. **Use chezmoi attributes:**
```bash
# In chezmoi source directory
cd ~/.local/share/chezmoi

# File naming conventions set permissions:
private_dot_ssh/private_id_rsa              # 600
private_dot_aws/private_credentials         # 600
executable_dot_local/bin/executable_script  # 755
readonly_dot_config/readonly_file           # 444

# Combine attributes:
private_executable_dot_local/bin/private_script  # 700
```

3. **Verify permissions after apply:**
```bash
# .chezmoiscripts/run_after_verify-permissions.sh
#!/bin/bash
check_perms() {
    local file="$1"
    local expected="$2"
    local actual=$(stat -f "%Lp" "$file" 2>/dev/null || stat -c "%a" "$file" 2>/dev/null)

    if [ "$actual" != "$expected" ]; then
        echo "WARNING: $file has permissions $actual, expected $expected"
        chmod "$expected" "$file"
    fi
}

check_perms "$HOME/.ssh/id_rsa" "600"
check_perms "$HOME/.ssh/id_ed25519" "600"
check_perms "$HOME/.aws/credentials" "600"
check_perms "$HOME/.gnupg" "700"
```

4. **Document permission requirements:**
```markdown
# .planning/security/file-permissions.md

## Required File Permissions

| File/Directory | Permissions | Reason |
|----------------|-------------|--------|
| `~/.ssh/id_*` (private keys) | 600 | SSH refuses to use keys with wrong perms |
| `~/.ssh/` (directory) | 700 | Prevent unauthorized key additions |
| `~/.aws/credentials` | 600 | AWS credentials should be private |
| `~/.gnupg/` | 700 | GPG private keyring protection |
| `~/.env*` files | 600 | Environment secrets |
```

**Permission Reference:**

| Numeric | Symbolic | Meaning | Use Case |
|---------|----------|---------|----------|
| 600 | `-rw-------` | Owner read/write only | Private keys, credentials |
| 644 | `-rw-r--r--` | Owner write, all read | Public config files |
| 700 | `-rwx------` | Owner all, others none | Private executables, `.ssh/` |
| 755 | `-rwxr-xr-x` | Owner all, others read+exec | Public executables |
| 400 | `-r--------` | Owner read-only | Immutable secrets |

**Security Impact:**

- **644 on private key:** Any user/process on system can steal key
- **664 on credentials:** Users in same group can steal credentials
- **777 on executable:** Anyone can modify script (backdoor risk)

**References:**
- [Connecting the .dotfiles: Checked-In Secret](https://pure.mpg.de/rest/items/item_3505626/component/file_3505627/content)
- [Managing .env Files And Secrets On A VPS Safely](https://www.dchost.com/blog/en/managing-env-files-and-secrets-on-a-vps-safely/)

---

### 5.3 Secrets in Git History

**Problem:** Even if you fix secret leakage and remove from current commit, secrets remain in Git history forever (unless explicitly removed).

**Common Mistake:**
```bash
# Day 1: Accidentally commit secret
echo "API_KEY=secret123" > .env
chezmoi add .env
cd ~/.local/share/chezmoi
git add dot_env
git commit -m "Add environment"
git push

# Day 2: Realize mistake, add to .chezmoiignore
echo ".env" >> .chezmoiignore
chezmoi forget .env
cd ~/.local/share/chezmoi
git rm dot_env
git commit -m "Remove secrets"
git push

# ❌ Secret STILL in history!
git log --all --full-history -- dot_env  # Shows old commit
git show <commit-hash>:dot_env           # Secret visible!
```

**Warning Signs:**
```bash
# Search Git history for secrets
cd ~/.local/share/chezmoi

# Find removed files (potential secrets)
git log --all --diff-filter=D --summary | grep delete

# Search for secret patterns in history
git log -S "api_key" --all
git log -S "password" --all
git grep -i "secret" $(git rev-list --all)

# Check for large files removed (could be keys/certs)
git rev-list --objects --all | sort -k 2 | uniq -cf 1
```

**Prevention:**

1. **NEVER commit secrets in first place** (see 5.1)

2. **Pre-commit scan catches before entering history:**
```bash
# .git/hooks/pre-commit
#!/bin/bash
# Prevent secrets from entering Git history
gitleaks protect --staged --verbose || {
    echo "Blocked: Secrets detected. They will NOT enter Git history."
    exit 1
}
```

3. **Regular history audits:**
```bash
# Weekly: Scan entire history
cd ~/.local/share/chezmoi
gitleaks detect --source . --verbose
```

**Recovery (Remove from History):**

⚠️ **WARNING: Destructive operation. Requires force push. Coordinate with team.**

**Method 1: BFG Repo-Cleaner (Recommended)**
```bash
# Install
brew install bfg

# Backup first!
cp -r ~/.local/share/chezmoi ~/chezmoi-backup

# Remove specific file from all history
cd ~/.local/share/chezmoi
bfg --delete-files dot_env
bfg --delete-files 'private_*.key'

# Clean up
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Verify secret removed
git log --all -- dot_env  # Should be empty

# Force push (⚠️ Destructive!)
git push --force
```

**Method 2: git-filter-repo (More Control)**
```bash
# Install
brew install git-filter-repo

# Backup
cp -r ~/.local/share/chezmoi ~/chezmoi-backup

# Remove specific file
cd ~/.local/share/chezmoi
git filter-repo --path dot_env --invert-paths

# Remove lines matching pattern
git filter-repo --replace-text <(echo 'API_KEY=.*==>API_KEY=REDACTED')

# Force push
git push --force
```

**Method 3: GitHub Secret Scanning (Detection)**
```bash
# If using GitHub, enable secret scanning
# Settings → Security → Secret scanning → Enable

# GitHub automatically:
# - Scans all commits (including history)
# - Alerts on known secret patterns
# - Blocks pushes with secrets (if push protection enabled)

# View alerts:
# https://github.com/user/repo/security/secret-scanning
```

**Post-Recovery Checklist:**
- [ ] Rotate ALL leaked credentials (even if removed from history)
- [ ] Force push to all remotes (`git push --force --all`)
- [ ] Notify collaborators to re-clone (`git clone`, not `git pull`)
- [ ] Check forks (secrets may persist in forks)
- [ ] Enable GitHub secret scanning
- [ ] Add pre-commit hooks to prevent recurrence

**Why Removal Isn't Enough:**
Even after removing from Git history:
- Secrets may be cached in GitHub/GitLab
- Forks still have the secret
- Clones on other machines retain history
- **Solution: Always rotate credentials**

**References:**
- [Connecting the .dotfiles: Checked-In Secret](https://pure.mpg.de/rest/items/item_3505626/component/file_3505627/content)
- [Keeping your open source credentials closed | Snyk](https://snyk.io/blog/leaked-credentials-in-packages/)

---

## 6. Recovery Strategies

### 6.1 Pre-Migration Safety Net

**Strategy:** Create comprehensive backups and rollback mechanisms BEFORE starting migration.

**Implementation:**

1. **Full system backup:**
```bash
# Create timestamped backup
BACKUP_DIR="$HOME/dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup all current dotfiles
rsync -av \
    ~/.zshrc ~/.zshenv ~/.zprofile ~/.zlogin \
    ~/.config/ \
    ~/.local/ \
    "$BACKUP_DIR/"

# Backup current tool installations
mise ls > "$BACKUP_DIR/mise-tools.txt"      || true
asdf current > "$BACKUP_DIR/asdf-tools.txt" || true
brew bundle dump --file="$BACKUP_DIR/Brewfile" --force

# Archive backup
tar -czf "$HOME/dotfiles-backup-$(date +%Y%m%d).tar.gz" "$BACKUP_DIR"
echo "Backup: $BACKUP_DIR"
```

2. **Version control current state:**
```bash
# Commit current Dotbot setup before migration
cd ~/.dotfiles
git add -A
git commit -m "checkpoint: pre-chezmoi migration state"
git tag pre-chezmoi-migration
git push origin pre-chezmoi-migration
```

3. **Document current working state:**
```bash
# Capture current environment
cat > "$BACKUP_DIR/system-state.txt" << EOF
=== Shell ===
$SHELL
$(zsh --version)

=== Tools ===
$(which node python ruby | xargs -I {} sh -c 'echo {}: $(${} --version 2>&1 | head -1)')

=== PATH ===
$PATH

=== Environment ===
$(env | grep -E '(EDITOR|LANG|LC_|XDG_)')

=== Homebrew ===
$(brew --version)
$(brew list --versions | wc -l) packages installed

=== asdf/mise ===
$(asdf --version 2>/dev/null || echo "asdf not found")
$(mise --version 2>/dev/null || echo "mise not found")
EOF
```

4. **Test restoration procedure:**
```bash
# Create restoration script BEFORE migration
cat > ~/restore-dotfiles.sh << 'EOF'
#!/bin/bash
set -e

BACKUP_DIR="$HOME/dotfiles-backup-20260125-120000"  # Update with actual

echo "Restoring dotfiles from $BACKUP_DIR..."

# Stop using chezmoi
mv ~/.local/share/chezmoi ~/.local/share/chezmoi.disabled 2>/dev/null || true

# Restore files
rsync -av "$BACKUP_DIR/" ~/

# Restore Dotbot
cd ~/.dotfiles
git checkout pre-chezmoi-migration
./install

# Restore tools
if [ -f "$BACKUP_DIR/Brewfile" ]; then
    brew bundle --file="$BACKUP_DIR/Brewfile"
fi

echo "Restoration complete. Restart shell."
EOF
chmod +x ~/restore-dotfiles.sh

# TEST the restoration script in a VM/container!
```

**References:**
- [PBS 123: Backing up Dot Files](https://pbs.bartificer.net/pbs123)
- [Dotfiles Backup using chezmoi](https://dev.to/mainendra/dotfiles-backup-using-chezmoi-macos-2n3c)

---

### 6.2 Incremental Migration with Rollback Points

**Strategy:** Migrate in small chunks with Git checkpoints after each successful phase.

**Migration Phases:**

```bash
# Phase 1: Initialize chezmoi (no files yet)
chezmoi init
cd ~/.local/share/chezmoi
git remote add origin git@github.com:user/dotfiles.git
git commit --allow-empty -m "feat: initialize chezmoi migration"
git push -u origin main
git tag phase-1-init
# ✓ Rollback point 1

# Phase 2: Migrate shell config files only
chezmoi add ~/.zshrc ~/.zshenv ~/.zprofile
chezmoi diff
chezmoi apply --dry-run  # Verify
chezmoi apply
# Test: Open new shell, verify it works
git add -A
git commit -m "feat: migrate shell config files"
git tag phase-2-shell
git push
# ✓ Rollback point 2

# Phase 3: Migrate tool configs (.config/)
chezmoi add ~/.config/git
chezmoi add ~/.config/starship.toml
chezmoi apply --dry-run
chezmoi apply
# Test: Run git commands, verify starship prompt
git add -A
git commit -m "feat: migrate tool configurations"
git tag phase-3-tools
git push
# ✓ Rollback point 3

# Phase 4: Add platform-specific logic
# Edit templates to add {{ if eq .chezmoi.os "darwin" }} blocks
chezmoi edit ~/.zshrc
chezmoi apply --dry-run
chezmoi apply
# Test: Verify on both macOS and Linux
git add -A
git commit -m "feat: add cross-platform support"
git tag phase-4-cross-platform
git push
# ✓ Rollback point 4

# Phase 5: Migrate to mise
# (see mise migration phases below)

# Phase 6: Remove Dotbot
# Only after ALL previous phases successful!
cd ~/.dotfiles
./dotbot-uninstall  # Remove symlinks
git add -A
git commit -m "chore: remove dotbot after successful migration"
git tag phase-6-complete
git push
# ✓ Migration complete
```

**Rollback Process:**
```bash
# If phase N fails, rollback to phase N-1
cd ~/.local/share/chezmoi
git reset --hard phase-3-tools  # Example: rollback to phase 3
chezmoi apply

# Verify restoration
zsh  # Test shell
git status  # Verify state
```

**References:**
- [How to reset chezmoi](https://github.com/twpayne/chezmoi/discussions/3247)

---

### 6.3 Emergency Shell Recovery

**Strategy:** Always maintain a fallback shell and recovery scripts.

**Implementation:**

1. **Keep emergency .zshrc:**
```bash
# ~/.zshrc.emergency (NEVER managed by chezmoi)
# Minimal working shell config
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export EDITOR=vim
alias ll='ls -la'

# Source if emergency
emergency_mode() {
    cp ~/.zshrc ~/.zshrc.broken
    cp ~/.zshrc.emergency ~/.zshrc
    echo "Emergency mode activated. Check ~/.zshrc.broken for errors."
}
```

2. **Create recovery script in root:**
```bash
# ~/recover.sh (uses POSIX sh, always works)
#!/bin/sh
set -e

echo "=== Dotfiles Recovery ==="

# Backup broken state
BROKEN_DIR="$HOME/broken-dotfiles-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BROKEN_DIR"
cp -r "$HOME/.zshrc" "$HOME/.zshenv" "$HOME/.config" "$BROKEN_DIR/" 2>/dev/null || true

# Restore from last backup
if [ -d "$HOME/dotfiles-backup-latest" ]; then
    echo "Restoring from backup..."
    rsync -av "$HOME/dotfiles-backup-latest/" "$HOME/"
else
    echo "No backup found. Using emergency config..."
    cp "$HOME/.zshrc.emergency" "$HOME/.zshrc"
fi

echo "Recovery complete. Broken files saved to: $BROKEN_DIR"
echo "Start new shell to test."
```

3. **Set up shell safety wrapper:**
```bash
# ~/.zshrc (top of file, before anything else)
# Safety wrapper: catch errors and provide recovery instructions
if ! source ~/.zshrc.d/init.zsh 2>/tmp/zshrc-error.log; then
    echo "ERROR: Shell initialization failed!"
    echo "Error log: /tmp/zshrc-error.log"
    echo ""
    echo "Recovery options:"
    echo "  1. Run: sh ~/recover.sh"
    echo "  2. Fix errors and source ~/.zshrc"
    echo "  3. Use emergency mode: cp ~/.zshrc.emergency ~/.zshrc"
    echo ""
    cat /tmp/zshrc-error.log
    return 1
fi
```

4. **External monitoring (for remote servers):**
```bash
# Cron job: verify shell health
# */5 * * * * /home/user/check-shell-health.sh

# ~/check-shell-health.sh
#!/bin/bash
if ! timeout 5 zsh -i -c exit 2>/dev/null; then
    echo "ALERT: Shell broken on $(hostname)"
    # Send alert (email, Slack, etc.)
    # Auto-restore
    sh ~/recover.sh
fi
```

**Recovery Scenarios:**

| Scenario | Recovery Method |
|----------|----------------|
| **Syntax error in .zshrc** | `zsh -n ~/.zshrc` to find error, fix, or restore from backup |
| **PATH broken** | `export PATH=/usr/bin:/bin` then fix .zshenv |
| **Can't open terminal** | SSH from another machine, or boot single-user mode |
| **chezmoi apply broke everything** | `chezmoi cd && git reset --hard HEAD~1 && chezmoi apply` |
| **mise activation fails** | Remove `eval "$(mise activate)"`, use shims temporarily |
| **Complete lockout** | Boot recovery mode, restore from backup |

**References:**
- [DotFiles - Greg's Wiki](https://mywiki.wooledge.org/DotFiles)

---

### 6.4 mise Migration Rollback

**Strategy:** Parallel installation, verification, then cut-over.

**Implementation:**

1. **Parallel installation (both tools coexist):**
```bash
# Keep asdf installed but inactive
# Install mise alongside
curl https://mise.run | sh
~/.local/bin/mise --version

# DO NOT add mise to shell yet!
# Manually install tools in mise
~/.local/bin/mise install node@20.0.0
~/.local/bin/mise install python@3.11.0

# Verify mise installations work
~/.local/bin/mise exec node@20.0.0 -- node --version
~/.local/bin/mise exec python@3.11.0 -- python --version
```

2. **Verification phase:**
```bash
# Create test environment
cat > ~/test-mise.sh << 'EOF'
#!/bin/bash
# Test mise in isolated shell

export PATH="$HOME/.local/share/mise/shims:$PATH"
eval "$($HOME/.local/bin/mise activate bash)"

echo "=== Testing mise ==="
echo "Node: $(node --version)"
echo "Python: $(python --version)"
echo "npm: $(npm --version)"

# Run your typical workflow
cd ~/projects/myapp
npm install
npm test

echo "=== Tests passed ==="
EOF

chmod +x ~/test-mise.sh
./test-mise.sh  # Verify BEFORE switching shell
```

3. **Conditional shell activation:**
```bash
# .zshrc - allow toggling between asdf and mise
if [ -n "$USE_MISE" ]; then
    # New: mise
    eval "$(mise activate zsh)"
else
    # Old: asdf (fallback)
    . "$HOME/.asdf/asdf.sh"
fi

# Test mise:
# USE_MISE=1 zsh

# Rollback to asdf:
# unset USE_MISE; zsh
```

4. **Gradual cut-over:**
```bash
# Week 1: Optional mise
# .zshrc
if [ -n "$USE_MISE" ]; then
    eval "$(mise activate zsh)"
else
    . "$HOME/.asdf/asdf.sh"
fi

# Week 2: Default mise, optional asdf
# .zshrc
if [ -n "$USE_ASDF" ]; then
    . "$HOME/.asdf/asdf.sh"
else
    eval "$(mise activate zsh)"
fi

# Week 3: mise only (remove asdf)
# .zshrc
eval "$(mise activate zsh)"
```

5. **Rollback procedure:**
```bash
# If mise fails in production
cat > ~/rollback-to-asdf.sh << 'EOF'
#!/bin/bash
set -e

echo "Rolling back to asdf..."

# Disable mise in shell
sed -i.bak 's/eval.*mise activate/# &/' ~/.zshrc

# Re-enable asdf
if ! grep -q 'asdf.sh' ~/.zshrc; then
    echo '. "$HOME/.asdf/asdf.sh"' >> ~/.zshrc
fi

# Verify asdf tools
asdf current

echo "Rollback complete. Start new shell."
EOF

chmod +x ~/rollback-to-asdf.sh
```

**References:**
- [Migrating from asdf to mise without the headaches](https://koji-kanao.medium.com/migrating-from-asdf-to-mise-without-the-headaches-fad759f33dce)
- [Migrate to mise for dependency management –GitLab](https://gitlab-org.gitlab.io/gitlab-development-kit/howto/mise/)

---

## 7. Migration Checklist

### Pre-Migration

- [ ] Create full backup of current dotfiles
- [ ] Document current working state (tool versions, environment)
- [ ] Tag current Git state (`pre-chezmoi-migration`)
- [ ] Test backup restoration procedure
- [ ] Create emergency recovery scripts
- [ ] Set up VM/container for testing migration
- [ ] Review all dotfiles for secrets (scan with gitleaks)
- [ ] Document team dependencies (CI/CD, shared scripts)

### chezmoi Migration

- [ ] Initialize chezmoi with Git remote
- [ ] Add `.chezmoiignore` for secrets before adding files
- [ ] Migrate shell configs first (minimal set)
- [ ] Test in new shell before committing
- [ ] Add platform detection templates
- [ ] Test on both macOS and Linux (if applicable)
- [ ] Migrate application configs (.config/)
- [ ] Set up secret management (encryption, 1Password, etc.)
- [ ] Remove Dotbot symlinks (only after verification)
- [ ] Document chezmoi workflow for team

### mise Migration

- [ ] Install mise alongside asdf (parallel)
- [ ] Verify mise installs tools correctly
- [ ] Test mise in isolated environment
- [ ] Benchmark shell startup time (before/after)
- [ ] Add mise activation to shell (conditional)
- [ ] Test all project `.tool-versions` files
- [ ] Update CI/CD to use mise
- [ ] Remove asdf (only after team cut-over)
- [ ] Clean up old asdf installations (disk space)
- [ ] Document mise workflow and syntax differences

### Post-Migration

- [ ] Verify shell startup time (< 300ms acceptable)
- [ ] Test on fresh machine (new install)
- [ ] Verify all projects build/run correctly
- [ ] Update team documentation
- [ ] Remove backup files (after stability period)
- [ ] Archive old dotfiles repo (don't delete)
- [ ] Set up pre-commit hooks to prevent regressions
- [ ] Schedule regular dotfiles review (quarterly)

---

## 8. Early Warning Signs

### Shell Issues
- [ ] Shell takes > 500ms to start
- [ ] Commands not found (PATH issues)
- [ ] Environment variables missing
- [ ] Syntax errors on new shell
- [ ] Different behavior login vs non-login shell

### chezmoi Issues
- [ ] `chezmoi diff` shows unexpected changes
- [ ] Templates generating blank lines
- [ ] Files disappearing after `chezmoi apply`
- [ ] Template syntax errors
- [ ] Platform-specific configs on wrong OS

### mise Issues
- [ ] WARN messages during activation
- [ ] Wrong tool versions being used
- [ ] `mise ls` shows empty
- [ ] Commands not found despite installation
- [ ] Duplicate installations (asdf + mise)

### Security Issues
- [ ] Secrets visible in `git log`
- [ ] Files world-readable (`ls -la ~ | grep -- '---'`)
- [ ] GitHub secret scanning alerts
- [ ] API keys in shell history
- [ ] Unencrypted credentials in repo

---

## Summary: Top 10 Critical Mistakes

1. **Editing files in ~/ instead of chezmoi source** → Templates destroyed
2. **Not testing before `chezmoi apply`** → Broken shell, lockout
3. **Committing secrets to Git** → Credential leakage, security breach
4. **Running asdf + mise simultaneously** → Version conflicts, confusion
5. **Wrong file permissions on secrets** → Unauthorized access
6. **Not using `.chezmoiignore`** → Secrets in version control
7. **PATH pollution/wrong order** → Wrong tool versions executing
8. **No backup before migration** → No rollback possible
9. **Incomplete migration (half Dotbot, half chezmoi)** → Two sources of truth
10. **Slow shell startup (no profiling)** → User frustration, ignored issue

---

## Migration Risk Matrix

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Secret leakage | **Critical** | High | Pre-commit hooks, .chezmoiignore |
| Shell lockout | **High** | Medium | Emergency recovery script |
| Wrong tool versions | **Medium** | High | PATH order, mise verification |
| Slow startup | **Low** | High | Profiling, lazy loading |
| Cross-platform breakage | **Medium** | Medium | Testing on both OSes |
| Lost work (no backup) | **Critical** | Low | Mandatory pre-migration backup |
| asdf/mise conflict | **Medium** | High | Complete cut-over, not parallel |
| Template syntax errors | **Low** | High | `chezmoi execute-template` testing |

---

**Document Version:** 1.0
**Last Updated:** 2026-01-25
**Migration Context:** Nix/Dotbot/asdf → chezmoi/mise (macOS + Linux)
