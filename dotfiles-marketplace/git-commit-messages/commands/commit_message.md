---
description: Generate improved commit messages following Conventional Commits
model: haiku
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

You MUST follow these steps:

1. **Analyze the Commit**: Use `Bash` tool to run `git show` with the commit reference:
   ```bash
   git show $ARGUMENTS
   ```
   - Examines commit metadata (author, date, hash)
   - Shows the full diff of changes
   - Displays the current commit message

2. **Understand Context**: Use `Bash` tool to run `git log`:
   ```bash
   git log --oneline -10
   ```
   - Review recent commit messages for style consistency
   - Understand the project's commit message patterns
   - Ensure new message fits repository conventions

3. **Generate Message**: Create an improved commit message that:
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

4. **Write to File**: Use the **Write tool** to save the commit message:
   - Write to `.commit-message.txt` in the current directory
   - This will overwrite the file if it already exists
   - Format the message as:
   ```
   MLE-999: <type>[optional scope]: <description>

   [optional body paragraphs]

   [optional footers]
   ```
   - After writing, inform the user that the message has been saved to `.commit-message.txt`

## Input Format

The commit reference (`$ARGUMENTS`) is passed to `git show`:

```bash
git show $ARGUMENTS  # e.g., HEAD, HEAD~1, abc1234
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

Here is the commit reference: $ARGUMENTS
