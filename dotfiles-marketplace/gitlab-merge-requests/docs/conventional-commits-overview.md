# Conventional Commits Overview

This plugin applies Conventional Commits principles to GitLab merge requests. Claude already knows the full spec — this file captures only the project-specific philosophy.

## Core Philosophy

1. **Jira Ticket Prefix** - All messages must start with a Jira ticket (e.g., MLE-999, TE-222)
2. **Business Value Focus** - Emphasise WHY changes were made over WHAT was changed
3. **Clear Communication** - Use concise, high-level descriptions (prefer 2-3 bullet points)
4. **User Impact** - Highlight how changes benefit users or solve problems

## Message Format

```
<jira-ticket>: <type>[optional scope]: <description>

[Summary focused on business value and user impact]

[Test plan and checklist]
```
