# glab Reference

Complete command reference for GitLab CLI (glab).

> **Important:** Use non-interactive output flags. The default TUI does not work in Claude Code.

## Global Flags

| Flag | Description |
|------|-------------|
| `-R, --repo` | Override repository (OWNER/REPO) |
| `-g, --group` | Override group |
| `-o, --output` | Output format: `text`, `json` |
| `--no-pager` | Disable paging |

## mr list

List merge requests.

```
glab mr list [flags]
```

### Filter Flags

| Flag | Description | Example |
|------|-------------|---------|
| `--mine` | MRs created by me | |
| `--assignee` | Filter by assignee (`@me` for self) | `--assignee=@me` |
| `--reviewer` | Filter by reviewer | `--reviewer=@me` |
| `--author` | Filter by author | `--author=jdoe` |
| `-l, --label` | Filter by label (repeatable) | `-l bug -l critical` |
| `-M, --milestone` | Filter by milestone | `-M v2.0` |
| `--target-branch` | Filter by target branch | `--target-branch develop` |
| `--source-branch` | Filter by source branch | `--source-branch feature/x` |
| `--search` | Search in title/description | `--search "login"` |
| `--draft` | Show only draft MRs | |
| `--not-draft` | Exclude draft MRs | |
| `--merged` | Show merged MRs | |
| `--closed` | Show closed MRs | |
| `--all` | Show all states | |
| `-p, --per-page` | Results per page (max 100) | `-p 50` |
| `-P, --page` | Page number | `-P 2` |
| `-o, --output` | Output format: `text`, `json` | `-o json` |

## mr view

Display merge request details.

```
glab mr view <id> [flags]
```

| Flag | Description |
|------|-------------|
| `-c, --comments` | Show comments |
| `-s, --system-logs` | Show system notes |
| `-w, --web` | Open in browser |
| `-o, --output` | Output format: `text`, `json` |

## mr create

Create a new merge request.

```
glab mr create [flags]
```

| Flag | Description | Example |
|------|-------------|---------|
| `-t, --title` | MR title | `--title "feat: add auth"` |
| `-d, --description` | MR description | `--description "Details..."` |
| `-b, --target-branch` | Target branch | `--target-branch develop` |
| `-H, --source-branch` | Source branch (default: current) | `--source-branch feat/x` |
| `-a, --assignee` | Assignee (repeatable) | `--assignee @me` |
| `--reviewer` | Reviewer (repeatable) | `--reviewer jdoe` |
| `-l, --label` | Labels (repeatable) | `-l enhancement` |
| `-M, --milestone` | Milestone | `-M v2.0` |
| `--squash` | Squash commits on merge | |
| `--remove-source-branch` | Delete source branch after merge | |
| `--draft` | Create as draft/WIP | |
| `--fill` | Fill title/description from commits | |
| `--fill-commit-body` | Fill description with commit bodies | |
| `--yes` | Skip confirmation prompt | |
| `--push` | Push source branch before creating | |
| `--web` | Open creation page in browser | |
| `--allow-collaboration` | Allow maintainer edits | |
| `--no-editor` | Don't open editor | |

## mr approve

Approve a merge request.

```
glab mr approve [id] [flags]
```

| Flag | Description |
|------|-------------|
| `--sha` | Approve only if HEAD matches SHA |

## mr merge

Merge a merge request.

```
glab mr merge [id] [flags]
```

| Flag | Description |
|------|-------------|
| `--squash` | Squash commits |
| `--squash-message` | Custom squash commit message |
| `--remove-source-branch` | Delete source branch |
| `--when-pipeline-succeeds` | Merge when pipeline passes |
| `--sha` | Merge only if HEAD matches SHA |
| `--yes` | Skip confirmation |
| `--auto-merge` | Enable auto-merge |

## mr update

Update an existing merge request.

```
glab mr update <id> [flags]
```

| Flag | Description | Example |
|------|-------------|---------|
| `--title` | Update title | `--title "new title"` |
| `--description` | Update description | |
| `--target-branch` | Change target branch | |
| `--assignee` | Update assignee | |
| `--reviewer` | Update reviewer | |
| `-l, --label` | Add labels (repeatable) | |
| `--unlabel` | Remove labels | |
| `-M, --milestone` | Set milestone | |
| `--draft` | Mark as draft | |
| `--ready` | Mark as ready (undraft) | |
| `--squash` | Enable squash on merge | |
| `--remove-source-branch` | Delete source after merge | |

## mr diff

Show merge request diff.

```
glab mr diff <id>
```

## mr note

Add a comment to a merge request.

```
glab mr note <id> [flags]
```

| Flag | Description |
|------|-------------|
| `-m, --message` | Comment text |

## mr rebase

Rebase a merge request.

```
glab mr rebase <id>
```

## mr checkout

Check out a merge request locally.

```
glab mr checkout <id> [flags]
```

| Flag | Description |
|------|-------------|
| `-b, --branch` | Custom local branch name |
| `-t, --track` | Track the remote branch |

## mr close / reopen

```
glab mr close <id>
glab mr reopen <id>
```

## issue list

List project issues.

```
glab issue list [flags]
```

| Flag | Description | Example |
|------|-------------|---------|
| `--mine` | Issues created by me | |
| `--assignee` | Filter by assignee | `--assignee=@me` |
| `--author` | Filter by author | `--author=jdoe` |
| `-l, --label` | Filter by label (repeatable) | `-l bug` |
| `-M, --milestone` | Filter by milestone | `-M v2.0` |
| `--search` | Search in title/description | `--search "crash"` |
| `--confidential` | Confidential issues only | |
| `--closed` | Show closed issues | |
| `--all` | Show all states | |
| `-p, --per-page` | Results per page | `-p 50` |
| `-o, --output` | Output format: `text`, `json` | `-o json` |

## issue view

Display issue details.

```
glab issue view <id> [flags]
```

| Flag | Description |
|------|-------------|
| `-c, --comments` | Show comments |
| `-w, --web` | Open in browser |
| `-o, --output` | Output format: `text`, `json` |

## issue create

Create a new issue.

```
glab issue create [flags]
```

| Flag | Description | Example |
|------|-------------|---------|
| `-t, --title` | Issue title | `--title "Bug report"` |
| `-d, --description` | Issue description | `--description "Steps..."` |
| `-l, --label` | Labels (repeatable) | `-l bug -l critical` |
| `-M, --milestone` | Milestone | `-M v2.0` |
| `-a, --assignee` | Assignee | `--assignee @me` |
| `--confidential` | Mark as confidential | |
| `--weight` | Issue weight | `--weight 3` |
| `--yes` | Skip confirmation | |
| `--no-editor` | Don't open editor | |

## issue close / reopen

```
glab issue close <id>
glab issue reopen <id>
```

## issue note

Add a comment to an issue.

```
glab issue note <id> [flags]
```

| Flag | Description |
|------|-------------|
| `-m, --message` | Comment text |

## issue update

Update an issue.

```
glab issue update <id> [flags]
```

| Flag | Description |
|------|-------------|
| `--title` | Update title |
| `--description` | Update description |
| `-l, --label` | Add labels |
| `--unlabel` | Remove labels |
| `-a, --assignee` | Update assignee |
| `-M, --milestone` | Set milestone |
| `--confidential` | Mark confidential |
| `--unconfidential` | Remove confidential flag |

## ci list

List CI/CD pipelines.

```
glab ci list [flags]
```

| Flag | Description | Example |
|------|-------------|---------|
| `--status` | Filter by status | `--status running` |
| `-p, --per-page` | Results per page | `-p 20` |
| `-o, --output` | Output format | `-o json` |

Pipeline statuses: `running`, `pending`, `success`, `failed`, `canceled`, `skipped`, `manual`

## ci status

Show pipeline status for current branch.

```
glab ci status [flags]
```

| Flag | Description |
|------|-------------|
| `-b, --branch` | Branch name (default: current) |
| `-l, --live` | Live update (don't use in Claude Code) |
| `--compact` | Compact view |
| `-o, --output` | Output format |

## ci view

View pipeline details.

```
glab ci view [branch/tag] [flags]
```

| Flag | Description |
|------|-------------|
| `-b, --branch` | Branch name |
| `-w, --web` | Open in browser |

## ci trace

View CI job logs/trace.

```
glab ci trace [branch] [job-name] [flags]
```

| Flag | Description |
|------|-------------|
| `-b, --branch` | Branch name |

## ci run

Trigger a new pipeline.

```
glab ci run [flags]
```

| Flag | Description | Example |
|------|-------------|---------|
| `-b, --branch` | Branch to run on | `-b main` |
| `--variables` | Pipeline variables | `--variables KEY:value` |

## ci retry

Retry a failed pipeline.

```
glab ci retry <pipeline-id>
```

## ci cancel

Cancel a running pipeline.

```
glab ci cancel <pipeline-id>
```

## ci lint

Validate `.gitlab-ci.yml`.

```
glab ci lint [flags]
```

## ci get

Get details of a specific pipeline.

```
glab ci get <pipeline-id> [flags]
```

| Flag | Description |
|------|-------------|
| `-o, --output` | Output format: `text`, `json` |

## repo

Repository operations.

```bash
glab repo view                  # View repo info
glab repo clone OWNER/REPO      # Clone a repo
glab repo fork                  # Fork current repo
glab repo archive [flags]       # Download repo archive
```

## auth

Authentication management.

```bash
glab auth status                # Check auth status
glab auth login                 # Login interactively
glab auth login --token TOKEN   # Login with token
```

## Other Useful Commands

```bash
glab alias list                 # List aliases
glab config get editor          # View config
glab label list                 # List project labels
glab release list               # List releases
glab snippet create             # Create a snippet
```
