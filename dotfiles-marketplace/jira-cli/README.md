# Jira CLI Plugin

A Claude Code plugin for managing Jira issues using [jira-cli](https://github.com/ankitpokhrel/jira-cli).

## Features

- **`/jira`** slash command — quick reference for jira-cli issue commands
- **`jira-issues`** auto-triggering skill — automatically activates when you mention ticket keys (MLE-123), ask to create/view/edit issues, or manage sprint work

All commands use `--plain` or `--raw` output since the default TUI does not work in Claude Code.

## Prerequisites

- [jira-cli](https://github.com/ankitpokhrel/jira-cli) installed and configured (`jira init`)

## Installation

### From Dotfiles Marketplace

```bash
ln -s /path/to/dotfiles-marketplace/jira-cli ~/.claude/plugins/jira-cli
```

### Manual Installation

```bash
mkdir -p ~/.claude/plugins
cp -r /path/to/jira-cli ~/.claude/plugins/
```

## Usage

### Slash Command

```
/jira
```

Displays a concise reference of jira-cli issue commands, flags, and output formats.

### Auto-triggering Skill

The skill activates automatically when you:
- Mention ticket keys like `MLE-123` or `PROJ-456`
- Ask to create, view, edit, move, or assign issues
- Request issue listings or sprint information

The skill confirms before any write operations (create, edit, move, assign, comment).

## Plugin Structure

```
jira-cli/
├── .claude-plugin/
│   └── plugin.json
├── README.md
├── CHANGELOG.md
├── commands/
│   └── jira.md
├── skills/
│   └── jira-issues.md
└── docs/
    └── jira-cli-reference.md
```

## Related

- [jira-cli documentation](https://github.com/ankitpokhrel/jira-cli)
