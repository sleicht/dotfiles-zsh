# Codebase Concerns

**Analysis Date:** 2026-01-25

## Tech Debt

**Deprecated Configuration System:**
- Issue: `.config/zshrc` is heavily commented out with legacy Oh-My-Zsh configuration that is no longer used
- Files: `~/.config/zshrc` (lines 1-93)
- Impact: Creates confusion about which configuration system is active; zgenom is now the primary plugin manager but commented OMZ code suggests uncertainty
- Fix approach: Remove all commented OMZ configuration and consolidate to zgenom-only setup. Update documentation to reflect current plugin management strategy.

**Hardcoded Machine Identity:**
- Issue: `.macos` file hardcodes specific machine name and user details (`MacBook Fanaka Stephan`)
- Files: `.macos` (lines 21-24)
- Impact: Cannot be reused across machines or shared with other users; requires manual editing before running
- Fix approach: Replace hardcoded names with environment variables or interactive prompts; make `.macos` adaptable to any user/machine.

**Disabled Dependency Installation:**
- Issue: `steps/dependencies.yml` is commented out in install script, dependencies are never actually installed
- Files: `install` (line 37), `steps/dependencies.yml`
- Impact: Brewfile dependencies are not automatically installed during setup; users must manually run `brew bundle`
- Fix approach: Either enable the dependencies.yml step or document the manual Brew installation requirement clearly in README.

**Stale Firebase Debug Log:**
- Issue: `firebase-debug.log` is committed to repository (11,410 bytes) with authentication details and timestamps
- Files: `firebase-debug.log` (root directory)
- Impact: Sensitive debugging information (scopes, email addresses) in version control; potential credential leak
- Fix approach: Add `firebase-debug.log` to `.gitignore` and remove from history using `git filter-branch`.

**Submodule Management Complexity:**
- Issue: Multiple dotbot plugins (dotbot, dotbot-asdf, dotbot-brew, zgenom) are git submodules that require recursive updates
- Files: `install` (lines 18-22), `.gitmodules`
- Impact: Installation requires careful submodule initialization; easy to forget recursive flag; updates can be tedious
- Fix approach: Consider vendoring critical plugins or using single plugin manager; simplify to fewer dependencies.

## Security Considerations

**Dangerous Aliases:**
- Risk: Several aliases execute destructive commands without confirmation
- Files: `zsh.d/aliases.zsh` (lines 43, 82, 85, 123-126, 129-136, 145-148)
- Current mitigation: None; aliases are directly executable
- Recommendations:
  - Add confirmation prompts to destructive aliases like `nuke` (line 43: `git clean -df && git reset --hard`)
  - Add confirmation to system cleanup alias (line 85: `lsregister -kill -r`)
  - Add confirmation to trash emptying (line 126: `rm -rfv` on system directories)
  - Document which aliases are dangerous and require caution

**Hardcoded SSH Key Path:**
- Risk: Alias references hardcoded SSH key location that may not exist on all machines
- Files: `zsh.d/aliases.zsh` (line 18: `cat ~/.ssh/id_rsa.pub`)
- Current mitigation: None
- Recommendations: Update to use modern key format (ed25519) and check for key existence before trying to read it.

**Unrestricted System Modification:**
- Risk: `.macos` script is designed to make extensive system modifications via `sudo` without validation
- Files: `.macos` (entire 951-line script)
- Current mitigation: Script asks for sudo password upfront, then maintains sudo session
- Recommendations:
  - Add explicit confirmation before major system modifications (keyboard layout, accessibility, display settings)
  - Document all changes the script makes
  - Consider breaking into smaller, modular scripts by category
  - Add dry-run option to preview changes

**Unverified Homebrew Tap Sources:**
- Risk: Brewfile includes taps from third-party sources without verification
- Files: `Brewfile` (lines 2-9)
- Current mitigation: None
- Recommendations:
  - Verify legitimacy of taps regularly (some may become unmaintained)
  - Document the purpose of each tap
  - Monitor for security updates of tap sources

## Performance Bottlenecks

**ZSH Syntax Highlighting Limits:**
- Problem: Syntax highlighting is disabled for lines longer than 200 characters
- Files: `zsh.d/variables.zsh` (line 143: `export ZSH_HIGHLIGHT_MAXLENGTH=200`)
- Cause: Highlighting long lines causes shell lag; 200 character limit is conservative
- Improvement path: Profile shell startup time with different thresholds; document why this limit exists.

**gpg-agent Initialization in Shell Startup:**
- Problem: GPG agent is forked in shell startup variables, runs even when not needed
- Files: `zsh.d/variables.zsh` (line 70: `eval "$(gpg-agent --daemon ...)`)
- Cause: Initializes daemon on every shell session regardless of usage
- Improvement path: Lazy-load gpg-agent only when needed (e.g., when git signs commits).

**Multiple Compiler Flag Invocations:**
- Problem: Homebrew is called multiple times during startup to get paths
- Files: `zsh.d/variables.zsh` (lines 16-17: `brew --prefix` called three times)
- Cause: Each `brew --prefix` invocation is a subprocess
- Improvement path: Cache the result in a variable or use environment variables set by Homebrew.

## Fragile Areas

**Architecture-Specific Configuration:**
- Files: `zsh.d/variables.zsh` (lines 40-60)
- Why fragile: Separate configuration for x86_64 and arm64 architectures; requires maintenance for both
- Safe modification: Add comprehensive comments explaining why each arch flag exists; test on both architectures
- Test coverage: No test cases for architecture-specific paths; relies on manual testing

**Custom Shell Functions with Limited Error Handling:**
- Files: `zsh.d/functions.zsh` (e.g., lines 16-24: `mc` function, lines 28-35: `mkd` function)
- Why fragile: Simple functions lack comprehensive error checking; `cd` failures are caught with `|| return` but not all edge cases
- Safe modification: Add input validation and edge case handling (empty arguments, permission errors)
- Test coverage: No unit tests for shell functions; only tested interactively

**Dependency on External Commands:**
- Files: `zsh.d/aliases.zsh` and `zsh.d/functions.zsh`
- Why fragile: Many aliases and functions depend on tools installed via Homebrew that may be missing
- Safe modification: Add `command -v` checks before using tools; provide fallback aliases
- Test coverage: Installation script doesn't validate that all expected tools are available post-install

**Gitconfig Management:**
- Files: `steps/terminal.yml` (line 81-83)
- Why fragile: Gitconfig is force-linked, could overwrite user's local git configuration
- Safe modification: Make gitconfig link less aggressive; offer to merge rather than force; preserve existing config
- Test coverage: No test for git configuration conflicts

## Scaling Limits

**Manual Brewfile Management:**
- Current capacity: Single Brewfile with ~60 brew packages and ~40 cask applications
- Limit: When > 100+ applications, file becomes difficult to maintain and navigate
- Scaling path: Break into multiple Brewfiles by category (development, productivity, system); use `brew bundle` with multiple taps

**Single Codebase for Multiple Users:**
- Current capacity: Personal dotfiles repository with user-specific configuration
- Limit: Adding another user requires forking or duplicating configuration files
- Scaling path: Implement user-agnostic configuration templates; separate personal customization into overrides; support multiple profiles

**Nested Submodule Hierarchy:**
- Current capacity: 4 git submodules (dotbot, dotbot-asdf, dotbot-brew, zgenom)
- Limit: Adding more submodules increases complexity of recursive updates; easy to have stale submodules
- Scaling path: Reduce to 1-2 core submodules; vendor remaining dependencies or use monorepo approach

## Missing Critical Features

**No Offline Installation Support:**
- Problem: Installation script requires internet access to clone submodules and download packages
- Blocks: Cannot set up new machines without network; breaks in isolated environments
- Approach: Add offline mode that uses pre-cached packages or provides clear failure messages

**No Configuration Backup/Export:**
- Problem: When updating `.config/*` files, previous versions are lost; no easy way to save user customizations
- Blocks: Experimenting with new configurations is risky; rolling back is manual
- Approach: Add automatic backup of overwritten config files with timestamp; provide `dotfiles export` command

**No Installation Verification:**
- Problem: Install script completes silently even if some steps fail
- Blocks: User doesn't know which configuration steps succeeded/failed; troubleshooting is difficult
- Approach: Add post-install verification script that validates all symlinks and installed packages

**No User Profile Support:**
- Problem: Dotfiles are personal; cannot easily select which subset of tools/configuration to install
- Blocks: Corporate users cannot use without significant modifications; difficult to share with team
- Approach: Add profile selection during install (minimal, development, full); conditionally install based on profile

## Test Coverage Gaps

**Shell Scripts Not Tested:**
- What's not tested: `install` script, all `.zsh` files, `.macos` system configuration script
- Files: `install`, `zsh.d/*.zsh`, `.macos`, `steps/*.yml`
- Risk: Breaking changes to shell configuration only discovered when shells start failing
- Priority: High - users depend on these scripts working correctly

**Dotbot Configuration Not Validated:**
- What's not tested: YAML structure of `steps/terminal.yml`; symlink creation; path expansion
- Files: `steps/terminal.yml`, `steps/dependencies.yml`
- Risk: Silent failures (symlinks not created, wrong paths) that break shell environment
- Priority: High - dotbot misconfiguration breaks entire installation

**Submodule Updates Not Tested:**
- What's not tested: Submodule initialization, recursive updates, compatibility between versions
- Files: `.gitmodules`, `install` submodule update logic
- Risk: Submodule version mismatch causes install failures
- Priority: Medium - affects clean installs and upgrades

**Brewfile Package Availability Not Tested:**
- What's not tested: Whether all listed packages still exist in Homebrew; whether taps are valid
- Files: `Brewfile`, `Brewfile_Client`, `Brewfile_Fanaka`
- Risk: Install fails midway when package is no longer available
- Priority: Medium - packages get deprecated/moved; requires periodic maintenance

---

*Concerns audit: 2026-01-25*
