---
description: Create and submit GitLab merge request
model: sonnet
---

# Create and Submit GitLab Merge Request

Creates a GitLab merge request by analysing changes, generating the MR description, pushing the branch, and creating the MR via `glab` CLI.

## Execution Instructions

Follow these steps in order:

### 1. Analyse Changes

Based on `$ARGUMENTS` (defaults to HEAD if not specified), use `Bash` tool:

- **If empty or "HEAD"**:
  ```bash
  git show HEAD
  ```
- **If commit range**:
  ```bash
  git diff <range>
  ```
- **If branch name**:
  ```bash
  git diff <branch>..HEAD
  ```

Additionally, review recent commits for context:
```bash
git log --oneline -10
```

### 2. Check for MR Template

Use `Read` tool to:
- Check if `.gitlab/merge_request_templates/Feature_to_Develop.md` exists
- Read the template if available
- Follow the template structure in the generated description

### 3. Generate MR Description

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

### 4. Push Branch to Remote

Check if push is needed and execute using `Bash` tool:

```bash
# Check if branch has upstream
git rev-parse --abbrev-ref @{upstream} 2>/dev/null

# If no upstream, push with set-upstream
git push --set-upstream origin <current-branch>

# If upstream exists but behind, just push
git push
```

### 5. Create Merge Request

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

### 6. Verify and Report

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

`$ARGUMENTS` (default: HEAD) — can be empty/HEAD, a branch name, a commit hash, or a range like `<ref1>..<ref2>`.

## Important Notes

- The `--web` flag automatically opens the MR in browser
- Do NOT call `glab mr view` after creation — MR is already opened
- Use `glab mr list` with `--per-page 1` to limit output
- If branch is already pushed, skip the push step
- Handle errors gracefully (e.g., if glab is not installed or authenticated)

Here are the changes: $ARGUMENTS
