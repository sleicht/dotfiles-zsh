---
description: "MUST use this skill whenever the user mentions Jira tickets, issue keys like MLE-123 or PROJ-456, or asks anything about Jira issues. This includes: checking ticket status, viewing issue details, creating bugs/stories/tasks, listing open or assigned issues, moving issues between states, assigning tickets, adding comments, linking issues, querying sprints, or any request involving jira-cli. This skill contains essential jira-cli command syntax and flags (like --plain, --no-input) that are required for correct usage in Claude Code — do not attempt jira commands without consulting this skill first. Also trigger for phrases like 'my tickets', 'open issues', 'current sprint', 'standup tickets', 'backlog', or any mention of Jira workflow states like 'In Progress', 'To Do', 'Done'. Critically, ANY message containing a ticket key pattern (2-5 uppercase letters followed by a dash and digits, e.g. SPPO-26353, MLE-123, TE-789) MUST trigger this skill, even if the message also discusses code, requirements, or other topics — the ticket key means Jira context is relevant."
model: haiku
---

# Jira Issue Management Skill

You help users manage Jira issues using the `jira` CLI tool (jira-cli).

## Key Rules

1. **Always use `--plain` or `--raw` output** — the default TUI/interactive mode does not work in Claude Code
2. **Always use `--no-input`** on create/edit commands to skip interactive prompts
3. **Confirm before write operations** — before creating, editing, moving, assigning, or commenting on issues, show the user what you plan to do and ask for confirmation
4. **Present results readably** — format command output into clean tables or summaries for the user
5. **Use the Bash tool** to execute all jira commands
6. **Always prefix commands with `JIRA_INSECURE=1`** to handle corporate TLS certificate verification issues (e.g. `JIRA_INSECURE=1 jira issue view ...`)

## Reference

For full command syntax, flags, and options, see: `${CLAUDE_PLUGIN_ROOT}/docs/jira-cli-reference.md`

## Common Patterns

### Viewing Issues

```bash
JIRA_INSECURE=1 jira issue view MLE-123 --plain
JIRA_INSECURE=1 jira issue view MLE-123 --plain --comments 5
```

### Listing Issues

```bash
# My open issues
JIRA_INSECURE=1 jira issue list -a$(jira me) --plain

# Issues by status
JIRA_INSECURE=1 jira issue list -s "In Progress" --plain

# Filtered by type and priority
JIRA_INSECURE=1 jira issue list -t Bug -y High --plain

# Custom columns
JIRA_INSECURE=1 jira issue list --plain --columns KEY,SUMMARY,STATUS,ASSIGNEE

# JQL query
JIRA_INSECURE=1 jira issue list -q "sprint in openSprints() AND assignee = currentUser()" --plain
```

### Creating Issues

```bash
JIRA_INSECURE=1 jira issue create -t Story -s "Summary here" -b "Description" -y Medium --no-input
JIRA_INSECURE=1 jira issue create -t Bug -s "Bug title" -y High -l bug --no-input
```

### Editing Issues

```bash
JIRA_INSECURE=1 jira issue edit MLE-123 -s "Updated summary" --no-input
JIRA_INSECURE=1 jira issue edit MLE-123 -y High -l urgent --no-input
```

### Moving Issues

```bash
JIRA_INSECURE=1 jira issue move MLE-123 "In Progress"
JIRA_INSECURE=1 jira issue move MLE-123 Done
```

### Assigning Issues

```bash
JIRA_INSECURE=1 jira issue assign MLE-123 $(jira me)    # assign to self
JIRA_INSECURE=1 jira issue assign MLE-123 x              # unassign
JIRA_INSECURE=1 jira issue assign MLE-123 "Jon Doe"      # assign to someone
```

### Commenting

```bash
JIRA_INSECURE=1 jira issue comment add MLE-123 "Comment text" --no-input
```

### Linking Issues

```bash
JIRA_INSECURE=1 jira issue link MLE-1 MLE-2 Blocks
JIRA_INSECURE=1 jira issue link MLE-1 MLE-2 Duplicate
```

## Interpreting User Intent

- "what's the status of MLE-123" -> view the issue
- "show me my tickets" / "list my issues" -> list with assignee filter
- "create a bug for..." -> create with type Bug
- "move MLE-123 to done" -> move command
- "assign MLE-123 to me" -> assign with $(jira me)
- "add a comment on MLE-123" -> comment add
- "what's in the current sprint" -> list with JQL sprint filter
