---
allowed-tools: Bash(git log:*), Bash(git show:*), mcp__git-mcp-server__git_set_working_dir, mcp__git-mcp-server__git_log, mcp__git-mcp-server__git_show, mcp__git-mcp-server__git_diff, mcp__git-mcp-server__git_branch, mcp__git-mcp-server__git_status, Read
description: Create and submit GitLab merge request
---
Create a GitLab merge request by:
1. Writing a comprehensive merge request description to `MERGE_REQUEST.md` following the template at `.gitlab/merge_request_templates/Feature_to_Develop.md` if it exists
2. Pushing the current branch to remote with upstream tracking if not already pushed
3. Creating the merge request in GitLab using `glab mr create` with the description from MERGE_REQUEST.md
4. Opening the merge request in the browser

**Requirements:**
- Target branch should be `develop` unless otherwise specified
- Use the current branch as source branch
- Include comprehensive summary, test instructions, and checklist items
- Handle the case where the branch is already pushed
- Return the merge request URL and number

**Changes to include:** $ARGUMENTS (default: HEAD if not specified)

**Steps:**
1. Check git status and current branch
2. Generate comprehensive MR description following the template
3. Write to MERGE_REQUEST.md
4. Push branch to remote if needed (with --set-upstream)
5. Create MR using: `glab mr create --title "<title>" --description "$(cat MERGE_REQUEST.md)" --target-branch develop --source-branch <current-branch> --web`
6. Report the MR number and URL to the user
