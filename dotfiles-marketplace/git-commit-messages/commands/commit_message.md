---
description: Generate improved commit messages following Conventional Commits
model: haiku
---

# Write Git Commit Message Command

Analyzes a git commit and generates an improved commit message following Conventional Commits with Jira ticket prefix. The message should be concise and focus on business value, not implementation details.

For the project-specific conventions, see: `${CLAUDE_PLUGIN_ROOT}/docs/conventional-commits-spec.md`

## Execution Instructions

Follow these steps in order:

### 1. Analyze the Commit

Use `Bash` tool to run:
```bash
git show $ARGUMENTS
```

### 2. Understand Context

Use `Bash` tool to run:
```bash
git log --oneline -10
```

### 3. Generate Message

Create an improved commit message that:
- Follows the Conventional Commits specification exactly
- Includes the Jira ticket prefix (e.g., MLE-999 or TE-222)
- Uses appropriate type (feat, fix, docs, etc.)
- Provides concise description in imperative mood
- **Body should focus on WHY, not WHAT**:
  - Explain the business reason or problem being solved
  - Describe user impact or benefit
  - Avoid listing implementation details visible in the diff
  - Prefer 2-3 high-level bullet points over detailed lists
- Maintains consistency with the project's commit style

### 4. Write to File

Use the **Write tool** to save to `.commit-message.txt`:
```
<jira-ticket>: <type>[optional scope]: <description>

[optional body paragraphs]

[optional footers]
```

Inform the user that the message has been saved to `.commit-message.txt`.

Here is the commit reference: $ARGUMENTS
