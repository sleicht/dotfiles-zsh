# External Integrations

**Analysis Date:** 2026-01-25

## APIs & External Services

**Cloud Platforms:**
- Google Cloud Platform (GCP)
  - CLI: `gcloud-cli` cask
  - Auth: Configured via `gcloud auth login`

**AI/LLM Services:**
- Anthropic Claude (via Vertex AI)
  - SDK: Claude Code (cask), Aider
  - Config: `.config/aider.conf.yml`
  - Model: `vertex_ai/claude-sonnet-4-5@20250929` (main), `vertex_ai/claude-haiku-4-5@20251001` (weak model)
  - Auth: Vertex AI credentials (environment variable)

**Git Hosting:**
- GitHub
  - CLI: `gh` (GitHub command-line tool)
  - Auth: SSH key or git-credential-manager
  - Integration: Git aliases in `zsh.d/aliases.zsh`, commit message templates

- GitLab
  - CLI: `glab` (GitLab command-line tool)
  - Auth: `glab auth login`
  - Integration: Merge request automation via Claude plugin at `.config/claude/plugins/git-conventional-commits/`

**Image Registry:**
- JFrog Artifactory
  - CLI: `jfrog-cli`
  - Auth: Environment variables (JFROG_CLI_USER, JFROG_CLI_PASSWORD)

## Data Storage

**Local Databases:**
- SQLite
  - Config: `~/.sqliterc` (symlinked from `.config/sqliterc`)
  - Used by: Atuin (shell history), various local tools

- PostgreSQL
  - Config: `~/.psqlrc` (symlinked from `.config/psqlrc`)
  - Client: Built into coreutils/findutils

**Shell History:**
- Atuin
  - Storage: SQLite local database (`~/.local/share/atuin/history.db`)
  - Encryption: AES-256-GCM with key stored at `~/.local/share/atuin/key`
  - Config: `.config/atuin/config.toml`
  - Features:
    - Workspace-aware filtering (default filter_mode)
    - Session filtering
    - Command chaining support
    - Secrets filtering (AWS keys, GitHub tokens, Slack, Stripe keys)
    - Fuzzy search, fulltext search, prefix search modes

**File Storage:**
- Local filesystem only
- macOS-integrated options:
  - iCloud via Mackup backup
  - Dropbox (cask installed)
  - Google Drive (cask installed)
  - Synology Drive Client (configured in AeroSpace startup)
  - kDrive (Infomaniak, configured in AeroSpace startup)

**Caching:**
- Fzf - In-memory fuzzy search cache
- Mise - Runtime version cache
- Sheldon - Plugin cache
- No explicit Redis or distributed cache

## Authentication & Identity

**SSH:**
- Primary authentication method
- 1Password SSH agent support (configured in README)
- git-credential-manager cask for fallback
- SSH config: Not managed by dotbot (commented out in `steps/terminal.yml`)
- Key files: Users bring their own SSH keys

**GPG:**
- gnupg (GPG) installed via Homebrew
- Agent config: `~/.gnupg/gpg-agent.conf` (symlinked from `.config/gpgagent`)
- Git integration: Configured for commit signing

**Git Credentials:**
- GitHub: SSH key or git-credential-manager
- GitLab: SSH key or glab CLI authentication
- API access: Via personal access tokens in environment

**macOS-specific:**
- Bitwarden - Password manager (cask installed)
- 1Password - Password manager and SSH agent

## Monitoring & Observability

**Error Tracking:**
- Not detected (no Sentry, Rollbar, or similar)

**Logging:**
- Shell history: Atuin (encrypted, synced)
- Firebase debug logs: `firebase-debug.log` (present but not actively configured in dotfiles)
- Command history filtering in Atuin for secrets protection

**System Monitoring:**
- `bottom` - System resource monitor
- `glances` - Multi-platform system monitor
- `istat-menus` - Advanced macOS system monitoring (cask)
- `ncdu` - Disk usage analyzer

## CI/CD & Deployment

**Hosting:**
- GitHub - Code hosting
- GitLab - Code hosting and CI/CD
- macOS local machine - Primary development environment

**CI Pipeline:**
- GitHub Actions - Git repository workflows
- GitLab CI - GitLab repository pipelines
- Integration: Via `gh` and `glab` CLI tools

**GitOps:**
- ArgoCD - GitOps continuous delivery platform
  - CLI: `argocd` installed
  - Integration: Kubernetes cluster management

**Container Platforms:**
- Docker - Container runtime
- Docker Compose - Multi-container orchestration
- Podman - Alternative OCI container runtime
- LazyDocker - Docker TUI client

**Infrastructure as Code:**
- OpenTofu - Terraform-compatible IaC (installed)
- Helm - Kubernetes package manager (installed)
- Nix - Declarative system configuration (feature/nix branch)

## Environment Configuration

**Required env vars:**
- `DOTFILES` - Path to dotfiles repository
- `FZF_*` - Fzf configuration (FZF_DEFAULT_COMMAND, FZF_CTRL_T_COMMAND, etc.)
- `JFROG_CLI_USER`, `JFROG_CLI_PASSWORD` - JFrog Artifactory credentials
- Cloud provider credentials (GCP, AWS)
- Vertex AI API credentials for Aider/Claude Code

**Secrets location:**
- 1Password vault (recommended for SSH keys)
- macOS Keychain (git-credential-manager)
- Environment files (`.env` - not tracked)
- Atuin filters secrets automatically from history (AWS keys, GitHub PAT, Slack tokens, Stripe keys)

**Dotfiles-managed configs:**
- `.config/aider.conf.yml` - Aider configuration with model specifications
- `.config/atuin/config.toml` - History sync settings (auto_sync: false by default)
- `.config/aerospace/aerospace.toml` - Window manager startup apps

## Webhooks & Callbacks

**Incoming:**
- AeroSpace window manager callbacks - Application launch hooks
  - Location: `.config/aerospace/aerospace.toml`
  - Functions: Auto-layout detection for specific apps (Spark, Fantastical, IntelliJ, WhatsApp, Ghostty, Chrome, Zen)

**Outgoing:**
- Git hooks framework - Dotbot can run shell commands
- Aider git hooks - Auto-commit integration (disabled in config)
- No explicit webhook endpoints

## Development Environment Integrations

**Code Analysis:**
- Trivy - Vulnerability and misconfiguration scanner
  - Config: Installed via Homebrew
  - Integration: CI/CD pipelines

**Code Quality:**
- Vale - Documentation/prose linter
  - Installed via Homebrew
  - Integration: Optional linting in Aider

**IDE Integrations:**
- Claude Code (cask) - Anthropic IDE integration
  - Custom agents: `.config/claude/agents/` (linked to `~/.claude/agents/`)
  - Custom commands: `.config/claude/commands/` (linked to `~/.claude/commands/`)
  - Custom skills: `.config/claude/skills/` (linked to `~/.claude/skills/`)
  - Settings: `.config/claude/settings.json` (MCP Server configuration)

- Jetbrains Toolbox (cask) - IDE installer
  - IntelliJ IDEA integration in AeroSpace (workspace-managed)

- Neovim - Text editor
  - Config symlinked from `.config/nvim` via Dotbot
  - Integration: System-wide `nvim` command

**Git Workflow:**
- GitFlow plugin (`git-flow-cjs`) - Branching model CLI
- LazyGit - Interactive git client with TUI
- Git Delta - Enhanced diff viewer
- Custom commit message template via Claude plugin
- Conventional Commits enforcement with Jira ticket prefixes

**Language Runtime Management:**
- asdf - Version manager via dotbot-asdf plugin
- Mise - Activated in `zsh.d/external.zsh`, manages multiple language versions
  - Supports: Python, Node.js, Go, Rust, Ruby, etc.

## Integration Patterns

**Symbol Links Management:**
- Dotbot creates symlinks from `~/.dotfiles/.config/*` to `~/.config/*`
- Location: `steps/terminal.yml` defines all symlinks
- Home Manager (Nix) provides alternative declarative approach

**Plugin Architecture:**
- Sheldon manages Zsh plugins (not Oh My Zsh)
- Custom Zsh modules in `zsh.d/` directory
- Carapace provides shell completions across shells

**Configuration Distribution:**
- User-specific configs: `Brewfile_Fanaka`
- Machine-specific configs: `Brewfile_Client`
- Global shared configs: `Brewfile`

---

*Integration audit: 2026-01-25*
