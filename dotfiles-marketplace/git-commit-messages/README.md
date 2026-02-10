# Git Commit Messages Plugin

A Claude Code plugin that generates and rewrites git commit messages following the Conventional Commits specification with Jira ticket prefixes.

## Features

This plugin provides two powerful slash commands for managing git commit messages:

- **`/commit_message`** - Generate improved commit messages following Conventional Commits
- **`/rewrite_commit_message`** - Rewrite commit messages in git history

All commands:
- Use Haiku model for fast, cost-effective commit message generation
- Enforce Jira ticket prefixes (e.g., MLE-999, TE-222)
- Follow Conventional Commits specification
- Maintain consistent commit message style
- Focus on business value and "WHY" over implementation details
- Generate concise messages (prefer 2-3 high-level bullet points)

## Installation

### From Dotfiles Repository

If this plugin is part of your dotfiles setup, it should be automatically installed via Dotbot configuration.

### Manual Installation

```bash
# Create plugins directory if it doesn't exist
mkdir -p ~/.claude/plugins

# Clone or symlink the plugin
ln -s /path/to/dotfiles/dotfiles-marketplace/git-commit-messages ~/.claude/plugins/git-commit-messages
```

### Installation in Other Projects

To use this plugin in other projects:

```bash
# Option 1: Copy the plugin directory
cp -r /path/to/dotfiles/dotfiles-marketplace/git-commit-messages ~/.claude/plugins/

# Option 2: Create a symlink (recommended)
ln -s /path/to/dotfiles/dotfiles-marketplace/git-commit-messages ~/.claude/plugins/git-commit-messages
```

## Commands

### `/commit_message`

Analyses a commit and generates an improved commit message following Conventional Commits specification.

**Usage:**
```bash
/commit_message HEAD          # Analyze most recent commit
/commit_message HEAD~1        # Analyze previous commit
/commit_message abc1234       # Analyze specific commit by hash
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

**⚠️ Warning:** This command rewrites git history!
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

## Model Selection

This plugin uses the **Haiku** model for all commands, optimized for:

- **Fast execution** - Haiku processes commit messages ~5x faster than Sonnet
- **Cost efficiency** - Significantly lower API costs for high-frequency operations
- **Quality** - More than sufficient for structured commit message generation following well-defined patterns

The Conventional Commits format is a well-defined specification that Haiku handles excellently. For tasks requiring deeper reasoning or complex context analysis, consider using the companion GitLab merge requests plugin which uses Sonnet.

## Configuration

### Jira Ticket Prefix

By default, the plugin expects Jira ticket prefixes matching patterns like:
- `MLE-999`
- `TE-222`

If your project uses different ticket prefixes, you may need to customise the command prompts.

## Development

### Plugin Structure

```
dotfiles-marketplace/git-commit-messages/
├── .claude-plugin/
│   └── plugin.json                 # Plugin manifest
├── README.md                        # This file
├── commands/                        # Slash commands
│   ├── commit_message.md
│   └── rewrite_commit_message.md
└── docs/                            # Documentation
    └── conventional-commits-spec.md
```

### Updating Commands

To modify a command:
1. Edit the corresponding `.md` file in `commands/`
2. Commands use YAML frontmatter for configuration (allowed-tools, description)
3. Use `${CLAUDE_PLUGIN_ROOT}` to reference plugin resources

## Troubleshooting

### Commands not appearing

1. Verify plugin is installed in `~/.claude/plugins/`
2. Check that `plugin.json` is valid JSON
3. Restart Claude Code if necessary

### MCP git tools not working

1. Ensure git MCP server is configured in Claude Code settings
2. Verify you're in a git repository
3. Check that you have appropriate git permissions

## Related Plugins

For GitLab merge request functionality, see the companion plugin:
- **@dotfiles-marketplace/gitlab-merge-requests** - Create GitLab merge requests following Conventional Commits philosophy

## License

This plugin is part of the dotfiles repository and follows the same licence.

## Contributing

To contribute improvements:
1. Test changes in your local environment
2. Update documentation as needed
3. Follow existing commit message conventions
4. Submit changes via the standard contribution process
