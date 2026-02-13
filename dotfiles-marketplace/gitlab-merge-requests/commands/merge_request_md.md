---
description: Generate GitLab merge request title and description
model: sonnet
---

# Create GitLab Merge Request Title & Description

Generates a comprehensive GitLab merge request title and description, then writes it to `MERGE_REQUEST.md`.

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

## Input Format

`$ARGUMENTS` (default: HEAD) — can be empty/HEAD, a branch name, a commit hash, or a range like `<ref1>..<ref2>`.

Here are the changes: $ARGUMENTS
