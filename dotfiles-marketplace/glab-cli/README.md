# glab CLI Plugin

A Claude Code plugin for managing GitLab merge requests, issues, and CI/CD pipelines using [glab](https://gitlab.com/gitlab-org/cli).

## Features

- **`/glab`** slash command — quick reference for glab commands
- **`glab`** auto-triggering skill — automatically activates when you mention merge requests, pipelines, GitLab issues, or use patterns like `!123`

All commands use non-interactive output (`--output json` or plain flags) since the default TUI does not work in Claude Code.

## Prerequisites

- [glab](https://gitlab.com/gitlab-org/cli) installed and authenticated (`glab auth login`)

## Installation

### From Dotfiles Marketplace

```bash
ln -s /path/to/dotfiles-marketplace/glab-cli ~/.claude/plugins/glab-cli
```

### Manual Installation

```bash
mkdir -p ~/.claude/plugins
cp -r /path/to/glab-cli ~/.claude/plugins/
```

## Usage

### Slash Command

```
/glab
```

Displays a concise reference of glab commands grouped by category (MR, Issues, CI/CD).

### Auto-triggering Skill

The skill activates automatically when you:
- Mention merge requests, MRs, or patterns like `!123`
- Ask about pipeline status, CI/CD logs, or CI lint
- Request GitLab issue management
- Use phrases like "my MRs", "approve MR", "pipeline status"

The skill confirms before any write operations (create, approve, merge, close, comment).

## Relationship to gitlab-merge-requests Plugin

This plugin provides full glab coverage including MR creation with Conventional Commits formatting. It supersedes the `gitlab-merge-requests` plugin — you can disable that plugin once satisfied with this one.

## Plugin Structure

```
glab-cli/
├── .claude-plugin/
│   └── plugin.json
├── README.md
├── CHANGELOG.md
├── commands/
│   └── glab.md
├── skills/
│   └── glab/
│       └── SKILL.md
└── docs/
    └── glab-reference.md
```

## Related

- [glab documentation](https://gitlab.com/gitlab-org/cli)
- [glab command reference](https://gitlab.com/gitlab-org/cli/-/blob/main/docs/source/mr/index.md)
