---
description: glab CLI quick reference for GitLab management
model: haiku
---

# glab — GitLab CLI Reference

> Use non-interactive output. The TUI does not work in Claude Code.

## Merge Requests

| Command | Syntax | Example |
|---------|--------|---------|
| **list** | `glab mr list [flags]` | `glab mr list --mine` |
| **view** | `glab mr view <id> [flags]` | `glab mr view 123` |
| **create** | `glab mr create [flags]` | `glab mr create --fill --yes` |
| **checkout** | `glab mr checkout <id>` | `glab mr checkout 123` |
| **approve** | `glab mr approve <id>` | `glab mr approve 123` |
| **merge** | `glab mr merge <id> [flags]` | `glab mr merge 123 --squash` |
| **close** | `glab mr close <id>` | `glab mr close 123` |
| **reopen** | `glab mr reopen <id>` | `glab mr reopen 123` |
| **diff** | `glab mr diff <id>` | `glab mr diff 123` |
| **note** | `glab mr note <id> -m "msg"` | `glab mr note 123 -m "LGTM"` |
| **rebase** | `glab mr rebase <id>` | `glab mr rebase 123` |
| **update** | `glab mr update <id> [flags]` | `glab mr update 123 --title "new"` |

### MR List Filters

| Flag | Filter | Example |
|------|--------|---------|
| `--mine` | My MRs | `glab mr list --mine` |
| `--reviewer=@me` | Where I'm reviewer | `glab mr list --reviewer=@me` |
| `--assignee=@me` | Assigned to me | `glab mr list --assignee=@me` |
| `-l` | Label (repeatable) | `-l bug -l urgent` |
| `-M` | Milestone | `-M v2.0` |
| `--draft` | Draft MRs | `--draft` |
| `--merged` | Merged MRs | `--merged` |
| `--target-branch` | Filter by target | `--target-branch develop` |

### MR Create Flags

| Flag | Description |
|------|-------------|
| `--fill` | Use commit info for title/description |
| `--title` | MR title |
| `--description` | MR description |
| `--target-branch` | Target branch (default: main) |
| `--source-branch` | Source branch (default: current) |
| `--assignee` | Assignee |
| `--reviewer` | Reviewer |
| `-l` | Labels |
| `--squash` | Squash on merge |
| `--remove-source-branch` | Delete source after merge |
| `--draft` | Create as draft |
| `--yes` | Skip confirmation |

## Issues

| Command | Syntax | Example |
|---------|--------|---------|
| **list** | `glab issue list [flags]` | `glab issue list --mine` |
| **view** | `glab issue view <id>` | `glab issue view 42` |
| **create** | `glab issue create [flags]` | `glab issue create --title "Bug"` |
| **close** | `glab issue close <id>` | `glab issue close 42` |
| **reopen** | `glab issue reopen <id>` | `glab issue reopen 42` |
| **note** | `glab issue note <id> -m "msg"` | `glab issue note 42 -m "Fixed"` |
| **update** | `glab issue update <id> [flags]` | `glab issue update 42 --title "new"` |

### Issue List Filters

| Flag | Filter |
|------|--------|
| `--mine` | My issues |
| `--assignee=@me` | Assigned to me |
| `-l` | Label (repeatable) |
| `-M` | Milestone |
| `--confidential` | Confidential issues |

## CI/CD

| Command | Syntax | Example |
|---------|--------|---------|
| **list** | `glab ci list` | `glab ci list` |
| **status** | `glab ci status` | `glab ci status` |
| **view** | `glab ci view [branch/tag]` | `glab ci view main` |
| **trace** | `glab ci trace [branch] [job]` | `glab ci trace main build` |
| **run** | `glab ci run [flags]` | `glab ci run -b main` |
| **retry** | `glab ci retry <pipeline-id>` | `glab ci retry 12345` |
| **cancel** | `glab ci cancel <pipeline-id>` | `glab ci cancel 12345` |
| **lint** | `glab ci lint` | `glab ci lint` |
| **get** | `glab ci get <pipeline-id>` | `glab ci get 12345` |

## Recipes

```bash
# My open MRs
glab mr list --mine

# MRs awaiting my review
glab mr list --reviewer=@me

# Create MR from current branch to develop
glab mr create --fill --target-branch develop --yes

# View pipeline status for current branch
glab ci status

# View CI job logs
glab ci trace

# Lint .gitlab-ci.yml
glab ci lint
```
