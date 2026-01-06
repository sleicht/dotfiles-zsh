---
description: Generate GitLab merge request title and description
---

# Create GitLab Merge Request Title & Description

This command generates a comprehensive GitLab merge request title and description, then writes it to `MERGE_REQUEST.md`.

## Overview

Generates merge request documentation by:
1. Analyzing changes using MCP git tools
2. Writing a comprehensive MR description to `MERGE_REQUEST.md`

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
- **Summary**: Bullet points focused on WHY:
  - Explain the business reason or problem being solved
  - Describe user impact or benefit
  - Avoid listing low-level implementation details
  - Keep summary concise and focused on value
- **Test Plan**: Step-by-step testing instructions
- **Checklist**: Tasks for reviewers

Use `Write` tool to:
- Write the complete content to `MERGE_REQUEST.md`
- Ensure proper markdown formatting

## Input Format

**Changes to include:** `$ARGUMENTS` (default: HEAD if not specified)

The argument can be:
- Empty or "HEAD" - Latest commit
- `<branch-name>` - Compare against branch
- `<commit-hash>` - Specific commit
- `<ref1>..<ref2>` - Range of commits

## Output Format

The `MERGE_REQUEST.md` file should contain:

```markdown
# <TICKET>: <type>: <title>

## Summary
- Business reason or problem being solved
- User impact and benefits
- High-level approach (avoid implementation details)

## Test Plan
- Step-by-step testing instructions
- Expected outcomes
- Edge cases to verify

## Checklist
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No breaking changes (or documented)
- [ ] Code reviewed
```

## Usage Examples

**Example 1: Generate MR for current branch**
```
/merge_request_md HEAD
```

**Example 2: Generate MR with all changes since develop**
```
/merge_request_md develop..HEAD
```

**Example 3: Generate MR (default to HEAD)**
```
/merge_request_md
```

Here are the changes: $ARGUMENTS
