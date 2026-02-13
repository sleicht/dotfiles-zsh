# Conventional Commits 1.0.0

A lightweight convention on top of commit messages. Claude already knows the full spec — this file captures only the project-specific customisations.

## Format

```
<jira-ticket>: <type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## Custom Rules

1. Commits MUST be prefixed with a Jira ticket number (e.g., MLE-999, TE-222)
2. Body: max 10 bullet points; focus on WHY, not WHAT
3. Imperative present tense, no capitalised first letter, no trailing period

## Example

```
MLE-999: feat: allow provided config object to extend other configs

BREAKING CHANGE: `extends` key in config file is now used for extending other config files
```
