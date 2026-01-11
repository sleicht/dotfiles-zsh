# Git Commit Messages Plugin

An OpenCode plugin that generates and rewrites git commit messages following the Conventional Commits specification with Jira ticket prefixes.

## Features

This plugin provides two powerful slash commands for managing git commit messages:

- **`/commit_message`** - Generate improved commit messages following Conventional Commits
- **`/rewrite_commit_message`** - Rewrite commit messages in git history

All commands enforce:
- Jira ticket prefixes (e.g., MLE-999, TE-222)
- Conventional Commits specification
- Consistent commit message style
- Focus on business value and "WHY" over implementation details
- Concise messages (prefer 2-3 high-level bullet points)

## Installation

### From Dotfiles Repository

If this plugin is part of your dotfiles setup, it should be automatically installed via Dotbot configuration.

### Manual Installation

```bash
# Create OpenCode directories if they don't exist
mkdir -p ~/.config/opencode/command
mkdir -p ~/.config/opencode/skill

# Symlink the commands
ln -s /path/to/dotfiles/dotfiles-marketplace/git-commit-messages/.opencode/command/commit_message.md ~/.config/opencode/command/
ln -s /path/to/dotfiles/dotfiles-marketplace/git-commit-messages/.opencode/command/rewrite_commit_message.md ~/.config/opencode/command/

# Symlink the skill
ln -s /path/to/dotfiles/dotfiles-marketplace/git-commit-messages/.opencode/skill/conventional-commits ~/.config/opencode/skill/
```

### Project-Level Installation

To use this plugin in a specific project:

```bash
# Create project-level OpenCode directories
mkdir -p .opencode/command
mkdir -p .opencode/skill

# Copy or symlink the commands and skill
cp -r /path/to/dotfiles/dotfiles-marketplace/git-commit-messages/.opencode/* .opencode/
```

## Commands

### `/commit_message`

Analyses a commit and generates an improved commit message following Conventional Commits specification.

**Usage:**
```bash
/commit_message HEAD          # Analyse most recent commit
/commit_message HEAD~1        # Analyse previous commit
/commit_message abc1234       # Analyse specific commit by hash
```

**Output:**
Writes the improved commit message to `.commit-message.txt` without modifying git history.

**Example Output:**
```
MLE-999: feat(auth): add JWT token validation

Enhance authentication security to prevent unauthorised access from
expired or tampered tokens.

- Validates token expiry and signature using RS256
- Adds comprehensive error handling for edge cases
```

### `/rewrite_commit_message`

Analyses a commit, generates an improved message, and rewrites the commit message in git history.

**Usage:**
```bash
/rewrite_commit_message HEAD          # Rewrite most recent commit
/rewrite_commit_message HEAD~1        # Rewrite previous commit
/rewrite_commit_message abc1234       # Rewrite specific commit
```

**Warning:** This command rewrites git history!
- If the commit has been pushed to remote, you'll need to force-push
- Force-pushing can affect other developers
- Only use on commits that haven't been shared, or coordinate with your team

## Conventional Commits Specification

This plugin enforces the Conventional Commits specification with additional Jira ticket prefix requirement.

### Commit Message Format

```
<jira-ticket>: <type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types

- **feat** - New feature (MINOR in SemVer)
- **fix** - Bug fix (PATCH in SemVer)
- **docs** - Documentation changes
- **style** - Code style changes (formatting, etc.)
- **refactor** - Code refactoring
- **perf** - Performance improvements
- **test** - Adding or updating tests
- **build** - Build system or dependency changes
- **ci** - CI/CD configuration changes
- **chore** - Other changes
- **revert** - Reverting a previous commit

### Breaking Changes

Indicate breaking changes with:
- `!` after type/scope: `feat(api)!: change response format`
- Footer: `BREAKING CHANGE: description of breaking change`

### Examples

```
MLE-999: feat: allow provided config object to extend other configs

MLE-999: fix(auth): correct token validation logic

MLE-999: feat(api)!: send email to customer when product is shipped

BREAKING CHANGE: API endpoint response format has changed

MLE-999: docs: correct spelling of CHANGELOG
```

For the complete specification, see: [docs/conventional-commits-spec.md](docs/conventional-commits-spec.md)

## Skill: conventional-commits

This plugin includes a skill that provides the complete Conventional Commits specification. The skill is automatically available when using the commands and can also be invoked directly for reference.

## Configuration

### Jira Ticket Prefix

By default, the plugin expects Jira ticket prefixes matching patterns like:
- `MLE-999`
- `TE-222`

If your project uses different ticket prefixes, you may need to customise the command prompts.

## Plugin Structure

```
dotfiles-marketplace/git-commit-messages/
├── .opencode/
│   ├── command/
│   │   ├── commit_message.md
│   │   └── rewrite_commit_message.md
│   └── skill/
│       └── conventional-commits/
│           └── SKILL.md
├── .claude-plugin/               # Legacy Claude Code format
│   └── plugin.json
├── commands/                     # Legacy Claude Code format
│   ├── commit_message.md
│   └── rewrite_commit_message.md
├── docs/
│   └── conventional-commits-spec.md
└── README.md
```

## Troubleshooting

### Commands not appearing

1. Verify commands are in `~/.config/opencode/command/` (global) or `.opencode/command/` (project)
2. Check that the markdown files have valid frontmatter
3. Restart OpenCode if necessary

### Skill not loading

1. Verify skill is in `~/.config/opencode/skill/conventional-commits/` (global) or `.opencode/skill/conventional-commits/` (project)
2. Check that `SKILL.md` exists and has valid frontmatter
3. Skill name must match directory name (lowercase, hyphenated)

## Related Plugins

For GitLab merge request functionality, see the companion plugin:
- **@dotfiles-marketplace/gitlab-merge-requests** - Create GitLab merge requests following Conventional Commits philosophy

## Licence

This plugin is part of the dotfiles repository and follows the same licence.

## Contributing

To contribute improvements:
1. Test changes in your local environment
2. Update documentation as needed
3. Follow existing commit message conventions
4. Submit changes via the standard contribution process
