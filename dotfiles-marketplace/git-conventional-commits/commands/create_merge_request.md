---
description: Create and submit GitLab merge request
---

# Create and Submit GitLab Merge Request

This command creates a comprehensive merge request in GitLab by generating the MR description, pushing the branch, and creating the MR via `glab` CLI.

## Overview

Creates a GitLab merge request by:
1. Analyzing changes using MCP git tools
2. Writing a comprehensive MR description to `MERGE_REQUEST.md`
3. Pushing the current branch to remote if needed
4. Creating the merge request using `glab mr create`
5. Opening the MR in the browser

## Execution Instructions

Follow these steps in order:

### 1. Initialize Repository Context (REQUIRED FIRST)

Use **`mcp__git__git_set_working_dir`**:
- Pass `path: "."`
- Pass `includeMetadata: true`
- This validates the git repository, sets the session working directory, and returns repository metadata
- The metadata includes current branch, status, and recent commits - use this context for subsequent operations

### 2. Analyze Changes

Based on `$ARGUMENTS` (defaults to HEAD if not specified). Note: path parameter omitted - uses session working directory:

- **If empty or "HEAD"**: Use `mcp__git__git_show` to analyze the latest commit
- **If commit range**: Use `mcp__git__git_diff` to see full changes
- **If branch name**: Use `mcp__git__git_diff` comparing against target branch

Additionally:
- **`mcp__git__git_log`**: Review recent commits for context (path parameter omitted)
  - Pass `maxCount: 10` to limit results
  - Understand the full scope of changes
  - Extract commit messages
  - Identify patterns and related work

### 3. Check for MR Template

Use `Read` tool to:
- Check if `.gitlab/merge_request_templates/Feature_to_Develop.md` exists
- Read the template if available
- Follow the template structure in the generated description

### 4. Generate MR Description

Create comprehensive content including:
- **Title**: `<TICKET>: <type>: <concise description>` (e.g., "MLE-999: feat: add user authentication")
- **Summary**: Bullet points explaining the changes
- **Test Plan**: Step-by-step testing instructions
- **Checklist**: Tasks for reviewers

Use `Write` tool to:
- Write the complete content to `MERGE_REQUEST.md`
- Ensure proper markdown formatting

### 5. Push Branch to Remote

Check if push is needed and execute:

```bash
# Check if branch has upstream
git rev-parse --abbrev-ref @{upstream} 2>/dev/null

# If no upstream, push with set-upstream
git push --set-upstream origin <current-branch>

# If upstream exists but behind, just push
git push
```

Use `Bash` tool for git push operations.

Alternatively, use **`mcp__git__git_push`** with:
- `setUpstream: true` if branch not yet tracked
- `branch: <current-branch>`
- `remote: "origin"`

### 6. Create Merge Request

Use `Bash` tool to run `glab mr create`:

```bash
glab mr create \
  --title "<title>" \
  --description "$(cat MERGE_REQUEST.md)" \
  --target-branch develop \
  --source-branch <current-branch> \
  --web
```

**Important**: The `--web` flag automatically opens the MR in browser.

### 7. Verify and Report

Use `Bash` tool to verify MR creation:

```bash
glab mr list --source-branch <current-branch> --per-page 1
```

Report to the user:
- MR number
- MR URL
- Confirmation that browser was opened

## Requirements

- **Target branch**: `develop` (unless otherwise specified)
- **Source branch**: Current branch
- **Content**: Comprehensive summary, test instructions, checklist items
- **Output**: MR URL and number

## Input Format

**Changes to include:** `$ARGUMENTS` (default: HEAD if not specified)

The argument can be:
- Empty or "HEAD" - Latest commit
- `<branch-name>` - Compare against branch
- `<commit-hash>` - Specific commit
- `<ref1>..<ref2>` - Range of commits

## Usage Examples

**Example 1: Create MR for current branch**
```
/create_merge_request HEAD
```

**Example 2: Create MR with all changes since develop**
```
/create_merge_request develop..HEAD
```

**Example 3: Create MR (default to HEAD)**
```
/create_merge_request
```

## Important Notes

- The `--web` flag automatically opens the MR in browser
- Do NOT call `glab mr view` after creation - MR is already opened
- Use `glab mr list` with `--per-page 1` to limit output
- If branch is already pushed, skip the push step
- Handle errors gracefully (e.g., if glab is not installed or authenticated)
