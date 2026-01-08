---
description: Rewrite git commit message in history following Conventional Commits
---

# Rewrite Git Commit Message Command

This command will analyze the specified commit, create an improved commit message following Conventional Commits specification, and then actually rewrite the commit message in git history using git filter-branch.

## Overview

This command analyzes a commit, creates an improved message following Conventional Commits specification, and rewrites the commit message in git history. See "Execution Instructions" below for detailed steps.

The message should be concise and focus on business value, not implementation details.

For the complete Conventional Commits specification, see: `${CLAUDE_PLUGIN_ROOT}/docs/conventional-commits-spec.md`

## Key Requirements

1. Commits MUST be prefixed with the Jira ticket number (e.g., MLE-999 or TE-222)
2. Commits MUST follow Conventional Commits format: `<jira-ticket>: <type>[optional scope]: <description>`
3. Types include: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`
4. Maximum 10 bullet points in the body (prefer 2-3 high-level points)
5. Breaking changes MUST be indicated with an exclamation mark (!) after type/scope OR as BREAKING CHANGE: in footer
6. Focus on WHY and business value, not HOW (implementation details are in the diff)
7. Avoid listing low-level code changes (e.g., "add method X", "update function Y")
8. Keep body concise - explain the problem solved and user impact

## Execution Instructions

After analyzing the commit and creating an improved message following the specification above, you MUST follow these steps:

### 1. Initialize Repository Context (REQUIRED FIRST)

Use **`mcp__git__git_set_working_dir`**:
- Pass `path: "."`
- Pass `includeMetadata: true`
- This validates the git repository and sets the session working directory
- Returns repository metadata (current branch, status, recent commits)

### 2. Analyze the Commit

Use **`mcp__git__git_show`** with the commit reference:
- Pass `object: $ARGUMENTS` parameter
- Do NOT pass `path` parameter (uses session working directory)
- Examines commit metadata (author, date, hash)
- Shows the full diff of changes
- Displays the current commit message

### 3. Understand Context

Use **`mcp__git__git_log`**:
- Pass `maxCount: 10` to limit results
- Do NOT pass `path` parameter (uses session working directory)
- Review recent commit messages for style consistency
- Understand the project's commit message patterns
- Ensure new message fits repository conventions

### 4. Get Target Commit Hash

Use `Bash` tool with `git rev-parse`:

```bash
git rev-parse <commit-ref>
```

This resolves the reference (HEAD, HEAD~1, etc.) to the actual commit hash needed for filter-branch.

### 5. Generate Improved Message

Create an improved commit message that:
- Follows the Conventional Commits specification exactly
- Includes the Jira ticket prefix (MLE-999 or TE-222)
- Uses appropriate type (feat, fix, docs, etc.)
- Provides concise description in imperative mood
- **Body should focus on WHY, not WHAT**:
  - Explain the business reason or problem being solved
  - Describe user impact or benefit
  - Avoid listing implementation details visible in the diff
  - Prefer 2-3 high-level bullet points over detailed lists
- Maintains consistency with the project's commit style

### 6. Determine Commit Range

Calculate the appropriate range for filter-branch based on the commit reference:

**Examples of commit references and ranges:**
- `HEAD`: Most recent commit → Range: `HEAD~1..HEAD`
- `HEAD~1`: One commit back → Range: `HEAD~2..HEAD~1`
- `HEAD~2`: Two commits back → Range: `HEAD~3..HEAD~2`
- `<commit-hash>`: Specific commit → Range determined by position from HEAD

### 7. Rewrite the Commit Message

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

### 8. Verify the Change

Use **`mcp__git__git_log`** or **`mcp__git__git_show`** (path parameter omitted) to:
- Confirm the commit message was updated successfully
- Show the new message to verify correctness
- Check that only the intended commit was modified

### 9. Report Results

Show the user:
- The old commit message
- The new commit message
- Confirmation of successful rewrite
- Warning about force-push if already pushed to remote

## Input Format

The commit reference (`$ARGUMENTS`) can be:
- `HEAD` - Most recent commit
- `HEAD~1`, `HEAD~2` - Previous commits
- `<commit-hash>` - Specific commit by hash
- `<branch-name>` - Latest commit on a branch

## Usage Examples

**Example 1: Rewrite most recent commit**
```
/rewrite_commit_message HEAD
```

**Example 2: Rewrite specific commit**
```
/rewrite_commit_message abc1234
```

**Example 3: Rewrite commit from two commits back**
```
/rewrite_commit_message HEAD~2
```

## Important Warnings

⚠️ **This command rewrites git history!**
- If the commit has been pushed to remote, you'll need to force-push
- Force-pushing can affect other developers working on the same branch
- Only use on commits that haven't been shared, or coordinate with your team

Here is the commit reference: $ARGUMENTS
