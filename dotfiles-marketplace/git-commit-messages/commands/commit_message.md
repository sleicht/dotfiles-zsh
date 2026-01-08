---
description: Generate improved commit messages following Conventional Commits
---

# Write Git Commit Message Command

This command will analyze the specified commit, create an improved commit message following Conventional Commits specification.

## Overview

This command analyzes git commits and generates improved commit messages following the Conventional Commits specification. See the "Execution Instructions" section below for detailed steps.

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

**CRITICAL**: This command uses ONLY MCP git tools. Do NOT use Bash git commands.

You MUST follow these steps using ONLY the MCP tools:

1. **Initialize Repository Context** (REQUIRED FIRST): Use **`mcp__git__git_set_working_dir`**:
   - Pass `path: "."`
   - Pass `includeMetadata: true`
   - This validates the git repository and sets the session working directory
   - Returns repository metadata (current branch, status, recent commits)

2. **Analyze the Commit**: Use **`mcp__git__git_show`** (NOT git show) with the commit reference:
   - Pass `object: $ARGUMENTS` parameter
   - Do NOT pass `path` parameter (uses session working directory)
   - Examines commit metadata (author, date, hash)
   - Shows the full diff of changes
   - Displays the current commit message

3. **Understand Context**: Use **`mcp__git__git_log`** (NOT git log):
   - Pass `maxCount: 10` to limit results
   - Do NOT pass `path` parameter (uses session working directory)
   - Review recent commit messages for style consistency
   - Understand the project's commit message patterns
   - Ensure new message fits repository conventions

4. **Generate Message**: Create an improved commit message that:
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

5. **Write to File**: Use the **Write tool** to save the commit message:
   - Write to `.commit-message.txt` in the current directory
   - This will overwrite the file if it already exists
   - Format the message as:
   ```
   MLE-999: <type>[optional scope]: <description>

   [optional body paragraphs]

   [optional footers]
   ```
   - After writing, inform the user that the message has been saved to `.commit-message.txt`

**PROHIBITED**: Do NOT use:
- Bash for git show commands
- Bash for git log commands
- Bash for git diff commands
- Any other git commands via Bash tool

**REQUIRED**: You MUST use:
- `mcp__git__git_set_working_dir` FIRST to initialize
- `mcp__git__git_show` for analyzing commits
- `mcp__git__git_log` for reviewing history
- `Write` tool to save the commit message to `.commit-message.txt`

## Correct MCP Tool Usage

**Step 1: Initialize working directory (REQUIRED FIRST)**

```typescript
// CORRECT - Initialize repository context
mcp__git__git_set_working_dir({
  path: ".",
  includeMetadata: true
})
```

**Step 2: Analyze commit**

```typescript
// CORRECT - Using MCP git tool (path omitted after init)
mcp__git__git_show({
  object: "HEAD~1"
  // Note: path parameter OMITTED - uses session working directory
})

// WRONG - Using Bash
Bash({
  command: "git show HEAD~1"
}) // ❌ DO NOT USE
```

**Step 3: Review commit history**

```typescript
// CORRECT - Using MCP git tool (path omitted after init)
mcp__git__git_log({
  maxCount: 10
  // Note: path parameter OMITTED - uses session working directory
})

// WRONG - Using Bash
Bash({
  command: "git log -10"
}) // ❌ DO NOT USE
```

## Input Format

After calling `mcp__git__git_set_working_dir`, the commit reference (`$ARGUMENTS`) is passed to `mcp__git__git_show`:

```typescript
// First: Initialize (path required)
mcp__git__git_set_working_dir({
  path: ".",
  includeMetadata: true
})

// Then: Analyze commit (path omitted)
mcp__git__git_show({
  object: $ARGUMENTS  // e.g., "HEAD", "HEAD~1", "abc1234"
  // Note: path parameter OMITTED
})
```

Valid values for `$ARGUMENTS`:
- `HEAD` - Most recent commit
- `HEAD~1`, `HEAD~2` - Previous commits
- `<commit-hash>` - Specific commit by full or short hash
- `<branch-name>` - Latest commit on a branch

## Usage Examples

**Example 1: Analyze most recent commit**
```
/commit_message HEAD
```

**Example 2: Analyze specific commit**
```
/commit_message abc1234
```

**Example 3: Analyze commit from two commits back**
```
/commit_message HEAD~2
```

## Expected Output

The command will write the commit message to `.commit-message.txt` and inform the user:

**File: `.commit-message.txt`**
```
MLE-999: feat(auth): add JWT token validation

Enhance authentication security to prevent unauthorized access from
expired or tampered tokens.

- Validates token expiry and signature using RS256
- Adds comprehensive error handling for edge cases
```

**Console Output:**
```
Commit message has been written to .commit-message.txt
```

## Troubleshooting

**If you find yourself using Bash for git commands:**
1. STOP immediately
2. Review the "Execution Instructions" section
3. Use the corresponding MCP git tool instead:
   - `git show` → `mcp__git__git_show`
   - `git log` → `mcp__git__git_log`
   - `git diff` → `mcp__git__git_diff`

**Remember**: This command is designed to work with MCP tools for better integration and error handling.

Here is the commit reference: $ARGUMENTS
