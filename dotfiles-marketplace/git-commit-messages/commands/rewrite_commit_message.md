---
description: Rewrite git commit message in history following Conventional Commits
model: haiku
---

# Rewrite Git Commit Message Command

Analyzes a commit, creates an improved message following Conventional Commits with Jira ticket prefix, and rewrites the commit message in git history using git filter-branch.

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

### 3. Get Target Commit Hash

Use `Bash` tool with `git rev-parse`:
```bash
git rev-parse <commit-ref>
```

### 4. Generate Improved Message

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

### 5. Determine Commit Range

Calculate the appropriate range for filter-branch:
- `HEAD` → Range: `HEAD~1..HEAD`
- `HEAD~1` → Range: `HEAD~2..HEAD~1`
- `HEAD~2` → Range: `HEAD~3..HEAD~2`
- `<commit-hash>` → Range determined by position from HEAD

### 6. Rewrite the Commit Message

Use `Bash` tool with `git filter-branch`:

```bash
FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -f --msg-filter 'if [ "$GIT_COMMIT" = "<TARGET_COMMIT_HASH>" ]; then echo "<NEW_MESSAGE>"; else cat; fi' <RANGE>
```

**Important Notes:**
- Always use `FILTER_BRANCH_SQUELCH_WARNING=1` to suppress warnings
- Use `-f` flag to force overwrite refs
- The range should start one commit before the target and end at HEAD
- Multi-line commit messages require proper shell escaping (use `echo -e` or heredoc)

**For multi-line messages, use this pattern:**
```bash
FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -f --msg-filter 'if [ "$GIT_COMMIT" = "<TARGET_COMMIT_HASH>" ]; then cat <<EOF
<line 1>
<line 2>
<line 3>
EOF
else cat; fi' <RANGE>
```

### 7. Verify the Change

Use `Bash` tool to verify:
```bash
git log --oneline -5
git show HEAD
```
- Confirm the commit message was updated successfully
- Check that only the intended commit was modified

### 8. Report Results

Show the user:
- The old commit message
- The new commit message
- Confirmation of successful rewrite
- Warning about force-push if already pushed to remote

## Important Warnings

This command rewrites git history!
- If the commit has been pushed to remote, you'll need to force-push
- Force-pushing can affect other developers working on the same branch
- Only use on commits that haven't been shared, or coordinate with your team

Here is the commit reference: $ARGUMENTS
