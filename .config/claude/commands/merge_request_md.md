---
allowed-tools: mcp__git__git_set_working_dir, mcp__git__git_log, mcp__git__git_show, mcp__git__git_diff, mcp__git__git_branch, mcp__git__git_status, Read, Write(MERGE_REQUEST.md)
description: Create merge request title&description
---

# Create GitLab Merge Request Title & Description

This command generates a comprehensive GitLab merge request title and description, then writes it to `MERGE_REQUEST.md`.

## Execution Instructions

Follow these steps to create the merge request documentation:

1. **Initialize Repository Context** (REQUIRED FIRST): Use `mcp__git__git_set_working_dir`:
   - Pass `path: "."`
   - Pass `includeMetadata: true`
   - This validates the git repository, sets the session working directory, and returns repository metadata
   - The metadata includes current branch, status, and recent commits

2. **Analyze Changes**: Based on `$ARGUMENTS` (path parameter omitted - uses session working directory):
   - If `$ARGUMENTS` is "HEAD" or empty: Use `mcp__git__git_show` to analyze the latest commit
   - If `$ARGUMENTS` is a commit range: Use `mcp__git__git_diff` to see the full diff
   - If `$ARGUMENTS` is a branch: Use `mcp__git__git_diff` comparing against the target branch

3. **Review Commit History**: Use `mcp__git__git_log` (path parameter omitted):
   - See recent commits on the current branch
   - Understand the scope of changes
   - Extract commit messages for context
   - Pass `maxCount: 10` to limit results

4. **Check for Template**: Use `Read` tool to:
   - Check if `.gitlab/merge_request_templates/Feature_to_Develop.md` exists
   - Read the template structure if available
   - Follow the template format

5. **Generate MR Content**: Create a title and description that:
   - Follows the Jira ticket prefix pattern (MLE-999 or TE-222)
   - Uses format: `<TICKET>: <type>: <concise description>`
   - Includes comprehensive summary of changes
   - Provides test instructions
   - Lists checklist items

6. **Write Output**: Use `Write` tool to:
   - Write the complete MR content to `MERGE_REQUEST.md`
   - Ensure proper markdown formatting
   - Include all required sections

## Input Format

The changes reference (`$ARGUMENTS`) can be:
- Empty or "HEAD" - Use the latest commit
- `<branch-name>` - Compare current branch against specified branch
- `<commit-hash>` - Specific commit
- `<ref1>..<ref2>` - Range of commits
- `develop..HEAD` - All changes from develop to current HEAD

## Output Format

The `MERGE_REQUEST.md` file should contain:

```markdown
# <TICKET>: <type>: <title>

## Summary
- Bullet point summary of key changes
- What problem this solves
- Important implementation details

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

**Example 1: Generate MR for current changes**
```
/merge_request_md HEAD
```

**Example 2: Generate MR comparing branches**
```
/merge_request_md develop..HEAD
```

**Example 3: Generate MR for feature branch**
```
/merge_request_md develop
```

Here are the changes: $ARGUMENTS
