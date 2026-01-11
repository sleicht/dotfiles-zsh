---
name: conventional-commits
description: Conventional Commits specification with Jira ticket prefixes for git commit messages and merge requests
---

# Conventional Commits 1.0.0

## Summary

The Conventional Commits specification is a lightweight convention on top of commit messages.
It provides an easy set of rules for creating an explicit commit history;
which makes it easier to write automated tools on top of.
This convention dovetails with [SemVer](http://semver.org),
by describing the features, fixes, and breaking changes made in commit messages.

The commit message should be structured as follows:

```
<jira-ticket>: <type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## Key Requirements

1. Commits MUST be prefixed with the Jira ticket number (e.g., MLE-999 or TE-222)
2. Commits MUST follow Conventional Commits format: `<jira-ticket>: <type>[optional scope]: <description>`
3. Types include: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`
4. Maximum 10 bullet points in the body (prefer 2-3 high-level points)
5. Breaking changes MUST be indicated with an exclamation mark (!) after type/scope OR as BREAKING CHANGE: in footer
6. Focus on WHY and business value, not HOW (implementation details are in the diff)
7. Avoid listing low-level code changes (e.g., "add method X", "update function Y")
8. Keep body concise - explain the problem solved and user impact

## Structural Elements

1. **fix:** a commit of the _type_ `fix` patches a bug in your codebase (correlates with `PATCH` in Semantic Versioning).
2. **feat:** a commit of the _type_ `feat` introduces a new feature to the codebase (correlates with `MINOR` in Semantic Versioning).
3. **BREAKING CHANGE:** a commit that has a footer `BREAKING CHANGE:`, or appends a ! after the type/scope, introduces a breaking API change (correlates with `MAJOR` in Semantic Versioning).
4. Other types allowed: `build:`, `chore:`, `ci:`, `docs:`, `style:`, `refactor:`, `perf:`, `test:`

## Examples

### Commit message with description and breaking change footer
```
MLE-999: feat: allow provided config object to extend other configs

BREAKING CHANGE: `extends` key in config file is now used for extending other config files
```

### Commit message with ! to draw attention to breaking change
```
MLE-999: feat!: send an email to the customer when a product is shipped
```

### Commit message with scope and ! to draw attention to breaking change
```
MLE-999: feat(api)!: send an email to the customer when a product is shipped
```

### Commit message with no body
```
MLE-999: docs: correct spelling of CHANGELOG
```

### Commit message with scope
```
MLE-999: feat(lang): add Polish language
```

### Commit message with multi-paragraph body and multiple footers
```
MLE-999: fix: prevent racing of requests

Introduce a request id and a reference to latest request. Dismiss
incoming responses other than from latest request.

Remove timeouts which were used to mitigate the racing issue but are
obsolete now.

Reviewed-by: Z
Refs: #123
```

## Specification Rules

1. Commits MUST be prefixed with the Jira ticket number (MLE-999 or TE-222)
2. Commits MUST be prefixed with a type, followed by OPTIONAL scope, OPTIONAL !, and REQUIRED terminal colon and space
3. The type `feat` MUST be used when a commit adds a new feature
4. The type `fix` MUST be used when a commit represents a bug fix
5. A scope MAY be provided after a type, surrounded by parenthesis (e.g., `fix(parser):`)
6. A description MUST immediately follow the colon and space after the type/scope prefix
7. A longer commit body MAY be provided after the short description, beginning one blank line after
8. One or more footers MAY be provided one blank line after the body
9. Breaking changes MUST be indicated in the type/scope prefix or as a footer entry

## Why Use Conventional Commits

- Automatically generating CHANGELOGs
- Automatically determining semantic version bump
- Communicating the nature of changes to teammates and stakeholders
- Triggering build and publish processes
- Making it easier for people to contribute with structured commit history
