---
description: jira-cli quick reference for issue management
model: haiku
---

# jira-cli — Issue Management Reference

> Always use `--plain` or `--raw`. The TUI does not work in Claude Code.
> Always prefix commands with `JIRA_INSECURE=1` to handle corporate TLS certificate issues.

## Core Commands

| Command | Syntax | Example |
|---------|--------|---------|
| **list** | `jira issue list [text] [flags]` | `JIRA_INSECURE=1 jira issue list --plain` |
| **view** | `jira issue view KEY [flags]` | `JIRA_INSECURE=1 jira issue view MLE-123 --plain` |
| **create** | `jira issue create [flags]` | `JIRA_INSECURE=1 jira issue create -tBug -s"Title" --no-input` |
| **edit** | `jira issue edit KEY [flags]` | `JIRA_INSECURE=1 jira issue edit MLE-123 -s"New title" --no-input` |
| **move** | `jira issue move KEY STATE` | `JIRA_INSECURE=1 jira issue move MLE-123 "In Progress"` |
| **assign** | `jira issue assign KEY USER` | `JIRA_INSECURE=1 jira issue assign MLE-123 $(jira me)` |
| **link** | `jira issue link K1 K2 TYPE` | `JIRA_INSECURE=1 jira issue link MLE-1 MLE-2 Blocks` |
| **comment** | `jira issue comment add KEY [BODY]` | `JIRA_INSECURE=1 jira issue comment add MLE-123 "Note"` |

## List Filters

| Flag | Filter | Example |
|------|--------|---------|
| `-a` | Assignee | `-a "Jon Doe"` |
| `-s` | Status (repeatable) | `-s "In Progress"` |
| `-t` | Type | `-t Bug` |
| `-y` | Priority | `-y High` |
| `-l` | Label (repeatable) | `-l backend` |
| `-P` | Parent/epic | `-P EPIC-1` |
| `-q` | Raw JQL | `-q "sprint in openSprints()"` |
| `--created` | Created date | `--created -7d` |
| `--updated` | Updated date | `--updated today` |

## Create/Edit Flags

| Flag | Description |
|------|-------------|
| `-s` | Summary/title |
| `-b` | Body/description |
| `-t` | Type (create only) |
| `-y` | Priority |
| `-a` | Assignee |
| `-l` | Labels (repeatable; prefix `-` to remove on edit) |
| `-C` | Components |
| `-P` | Parent/epic |
| `--custom` | Custom fields (`--custom story-points=3`) |
| `--no-input` | Skip interactive prompts |

## Output Formats

| Flag | Output |
|------|--------|
| `--plain` | Plain text table |
| `--raw` | Raw JSON |
| `--csv` | CSV format |
| `--columns` | Select columns: `KEY,SUMMARY,STATUS,ASSIGNEE,PRIORITY` |
| `--no-headers` | Hide headers (with `--plain`) |

## Assign Shortcuts

| Value | Effect |
|-------|--------|
| `$(jira me)` | Assign to self |
| `default` | Default assignee |
| `x` | Unassign |

## Recipes

```bash
# My open issues
JIRA_INSECURE=1 jira issue list -a$(jira me) --plain

# My issues in current sprint
JIRA_INSECURE=1 jira issue list -q "sprint in openSprints() AND assignee = currentUser()" --plain

# Open bugs by priority
JIRA_INSECURE=1 jira issue list -t Bug -s "To Do" -s "In Progress" --plain --columns KEY,SUMMARY,PRIORITY,STATUS

# Recently created (last 7 days)
JIRA_INSECURE=1 jira issue list --created -7d --plain

# Standup view: my in-progress work
JIRA_INSECURE=1 jira issue list -a$(jira me) -s "In Progress" -s "In Review" --plain --columns KEY,SUMMARY,STATUS

# Triage view: unassigned bugs
JIRA_INSECURE=1 jira issue list -t Bug -a x --plain --columns KEY,SUMMARY,PRIORITY,CREATED

# Quick create a bug
JIRA_INSECURE=1 jira issue create -t Bug -s "Summary" -y Medium --no-input

# Move to in progress and assign to self
JIRA_INSECURE=1 jira issue move MLE-123 "In Progress" -a $(jira me)
```
