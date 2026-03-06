# jira-cli Reference

Complete command reference for jira-cli issue management.

> **Important:** Always use `--plain` or `--raw` flags. The default TUI/interactive mode does not work in Claude Code.

## Global Flags

| Flag | Description |
|------|-------------|
| `-p, --project` | Override default project |
| `-c, --config` | Override config file path |
| `--debug` | Enable debug output |

## issue list

List issues in a project with filters.

```
jira issue list [search text] [flags]
```

### Filter Flags

| Flag | Description | Example |
|------|-------------|---------|
| `-t, --type` | Filter by type | `-t Bug` |
| `-s, --status` | Filter by status (repeatable) | `-s "In Progress"` |
| `-y, --priority` | Filter by priority | `-y High` |
| `-a, --assignee` | Filter by assignee (email/name) | `-a "Jon Doe"` |
| `-r, --reporter` | Filter by reporter | `-r jon@example.com` |
| `-l, --label` | Filter by label (repeatable) | `-l backend -l urgent` |
| `-C, --component` | Filter by component | `-C Backend` |
| `-P, --parent` | Filter by parent issue | `-P EPIC-1` |
| `-R, --resolution` | Filter by resolution | `-R Done` |
| `-w, --watching` | Issues you are watching | |
| `--history` | Recently accessed issues | |
| `-q, --jql` | Raw JQL query | `-q "sprint in openSprints()"` |

### Date Filters

| Flag | Description | Values |
|------|-------------|--------|
| `--created` | Filter by created date | `today`, `week`, `month`, `year`, `yyyy-mm-dd`, `-10d`, `-2w` |
| `--updated` | Filter by updated date | Same as above |
| `--created-after` | Created after date | `yyyy-mm-dd` |
| `--created-before` | Created before date | `yyyy-mm-dd` |
| `--updated-after` | Updated after date | `yyyy-mm-dd` |
| `--updated-before` | Updated before date | `yyyy-mm-dd` |

### Output Flags

| Flag | Description |
|------|-------------|
| `--plain` | Plain text table output |
| `--raw` | Raw JSON output |
| `--csv` | CSV format output |
| `--no-headers` | Hide table headers (with `--plain`) |
| `--no-truncate` | Show all columns (with `--plain`) |
| `--columns` | Comma-separated columns: `TYPE, KEY, SUMMARY, STATUS, ASSIGNEE, REPORTER, PRIORITY, RESOLUTION, CREATED, UPDATED, LABELS` |
| `--delimiter` | Custom column delimiter (with `--plain`, default: tab) |

### Pagination

| Flag | Description | Example |
|------|-------------|---------|
| `--paginate` | Format: `<from>:<limit>` (max 100) | `--paginate 0:50` |
| `--order-by` | Order field (default: `created`) | `--order-by status` |
| `--reverse` | Reverse order (default: DESC) | |

## issue view

Display issue details.

```
jira issue view ISSUE-KEY [flags]
```

| Flag | Description |
|------|-------------|
| `--plain` | Plain text output |
| `--raw` | Raw JSON output |
| `--comments N` | Show N comments (default: 1) |

## issue create

Create a new issue.

```
jira issue create [flags]
```

| Flag | Description | Example |
|------|-------------|---------|
| `-t, --type` | Issue type | `-t Bug` |
| `-s, --summary` | Title/summary | `-s "Fix login bug"` |
| `-b, --body` | Description | `-b "Detailed description"` |
| `-y, --priority` | Priority | `-y High` |
| `-a, --assignee` | Assignee (email/name) | `-a jon@example.com` |
| `-r, --reporter` | Reporter | `-r jon@example.com` |
| `-l, --label` | Labels (repeatable) | `-l bug -l urgent` |
| `-C, --component` | Components (repeatable) | `-C Backend` |
| `-P, --parent` | Parent/epic key | `-P EPIC-1` |
| `-e, --original-estimate` | Time estimate | `-e 2h` |
| `--custom` | Custom fields | `--custom story-points=3` |
| `--fix-version` | Fix version (repeatable) | `--fix-version v2.0` |
| `-T, --template` | Description from file | `-T /path/to/file` |
| `--no-input` | Skip interactive prompts | |
| `--raw` | JSON output | |

## issue edit

Edit an existing issue.

```
jira issue edit ISSUE-KEY [flags]
```

| Flag | Description | Example |
|------|-------------|---------|
| `-s, --summary` | Update title | `-s "New title"` |
| `-b, --body` | Update description | `-b "New description"` |
| `-y, --priority` | Update priority | `-y Low` |
| `-a, --assignee` | Update assignee | `-a jon@example.com` |
| `-l, --label` | Append label (prefix `-` to remove) | `-l new` or `-l -old` |
| `-C, --component` | Replace components (prefix `-` to remove) | `-C Frontend` |
| `-P, --parent` | Link to parent | `-P EPIC-2` |
| `--custom` | Edit custom fields | `--custom story-points=5` |
| `--fix-version` | Add fix version (prefix `-` to remove) | `--fix-version v2.1` |
| `--no-input` | Skip interactive prompts | |
| `--skip-notify` | Don't notify watchers | |

## issue move

Transition an issue to a different state.

```
jira issue move ISSUE-KEY STATE [flags]
```

| Flag | Description |
|------|-------------|
| `--comment` | Add comment with transition |
| `-a, --assignee` | Assign during transition |
| `-R, --resolution` | Set resolution |

Common states: `"To Do"`, `"In Progress"`, `"In Review"`, `"Done"`

## issue assign

Assign an issue to a user.

```
jira issue assign ISSUE-KEY ASSIGNEE
```

Special values:
- `$(jira me)` — assign to self
- `default` — assign to default assignee
- `x` — unassign

## issue link

Link two issues together.

```
jira issue link INWARD_KEY OUTWARD_KEY LINK_TYPE
```

Common link types: `Blocks`, `Duplicate`, `Relates`, `Clones`

## issue comment add

Add a comment to an issue.

```
jira issue comment add ISSUE-KEY [COMMENT_BODY] [flags]
```

| Flag | Description |
|------|-------------|
| `--internal` | Make comment internal |
| `--no-input` | Skip interactive prompts |
| `-T, --template` | Read comment from file |

Multi-line: use `$'Line 1\n\nLine 2'`

## issue clone

Duplicate an issue.

```
jira issue clone ISSUE-KEY [flags]
```

## issue delete

Delete an issue.

```
jira issue delete ISSUE-KEY
```

## issue unlink

Disconnect two linked issues.

```
jira issue unlink INWARD_KEY OUTWARD_KEY
```

## issue watch

Add a user to issue watchers.

```
jira issue watch ISSUE-KEY
```

## Other Useful Commands

```bash
jira me                    # Show current user
jira project list --plain  # List available projects
jira sprint list --plain   # List sprints
jira board list --plain    # List boards
```
