# Conventional Commits Overview

This document provides a brief overview of the Conventional Commits philosophy used by this plugin. For the complete specification, see the **@dotfiles-marketplace/git-commit-messages** plugin.

## Core Philosophy

The Conventional Commits specification provides a lightweight convention for commit and merge request messages. This plugin applies those principles to GitLab merge requests with additional requirements:

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

### Examples

```
MLE-999: feat(auth): implement JWT token validation

Enhance authentication security to prevent unauthorised access from expired or tampered tokens.

- Validates token expiry and signature using RS256
- Adds comprehensive error handling for edge cases
- Improves user experience with clear error messages
```

```
TE-222: fix(checkout): resolve payment processing timeout

Prevent user frustration and lost sales from checkout failures during peak traffic.

- Increases timeout threshold for payment gateway API
- Adds retry logic for transient network errors
- Improves error messages to guide users
```

## Commit Types

Common types used in merge request titles:

- **feat** - New feature for users
- **fix** - Bug fix that resolves user issues
- **perf** - Performance improvement that enhances user experience
- **refactor** - Code improvement that enables future features
- **docs** - Documentation that helps users or developers
- **test** - Testing improvements for reliability
- **chore** - Maintenance tasks

## Breaking Changes

Indicate breaking changes with `!` after type/scope:

```
MLE-999: feat(api)!: change authentication endpoint response format

BREAKING CHANGE: Response now includes additional security metadata. Clients must update to handle new fields.
```

## Why This Matters

Following Conventional Commits philosophy helps:

1. **Team Communication** - Clear, consistent messages improve collaboration
2. **Change Understanding** - Business value focus helps stakeholders understand impact
3. **Release Management** - Structured messages enable automated changelogs
4. **Code Review** - Focused descriptions improve review quality
5. **Historical Context** - Future developers understand why decisions were made

## Full Specification

For the complete Conventional Commits specification with detailed examples and rules, install and refer to:

**@dotfiles-marketplace/git-commit-messages**

That plugin includes:
- Complete specification document
- Detailed type descriptions
- Extensive examples
- Commit message generation tools
- Git history rewriting tools

## References

- Official Conventional Commits Specification: https://www.conventionalcommits.org/
- Semantic Versioning: https://semver.org/
