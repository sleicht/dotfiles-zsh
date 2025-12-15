# Git Conventional Commits Plugin

A Claude Code plugin that provides git commit and merge request helpers following the Conventional Commits specification with Jira ticket prefixes.

## Features

This plugin provides four powerful slash commands for managing git commits and GitLab merge requests:

- **`/commit_message`** - Generate improved commit messages following Conventional Commits
- **`/rewrite_commit_message`** - Rewrite commit messages in git history
- **`/merge_request_md`** - Generate merge request title and description
- **`/create_merge_request`** - Create and submit GitLab merge requests

All commands enforce:
- Jira ticket prefixes (e.g., MLE-999, TE-222)
- Conventional Commits specification
- Consistent commit message style
- Maximum 10 bullet points in commit body

## Installation

### From Dotfiles Repository

If this plugin is part of your dotfiles setup, it should be automatically installed via Dotbot configuration.

### Manual Installation

```bash
# Create plugins directory if it doesn't exist
mkdir -p ~/.claude/plugins

# Clone or symlink the plugin
ln -s /path/to/dotfiles/.config/claude/plugins/git-conventional-commits ~/.claude/plugins/git-conventional-commits
```

### Installation in Other Projects

To use this plugin in other projects:

```bash
# Option 1: Copy the plugin directory
cp -r /path/to/dotfiles/.config/claude/plugins/git-conventional-commits ~/.claude/plugins/

# Option 2: Create a symlink (recommended)
ln -s /path/to/dotfiles/.config/claude/plugins/git-conventional-commits ~/.claude/plugins/git-conventional-commits
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
Displays the improved commit message without modifying git history.

**Example Output:**
```
MLE-999: feat(auth): add JWT token validation

Implement token expiry checking and signature verification to enhance
authentication security.

- Add token expiry validation middleware
- Implement signature verification using RS256
- Add comprehensive error handling for invalid tokens
- Update tests to cover new validation logic
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

### `/merge_request_md`

Generates a comprehensive merge request title and description, writing it to `MERGE_REQUEST.md`.

**Usage:**
```bash
/merge_request_md HEAD              # Generate MR for current changes
/merge_request_md develop..HEAD     # Generate MR comparing branches
/merge_request_md develop           # Generate MR for feature branch
```

**Output:**
Creates `MERGE_REQUEST.md` with:
- Title following Jira ticket convention
- Summary of changes
- Test plan
- Checklist

### `/create_merge_request`

Generates merge request description, pushes changes, and creates a GitLab merge request.

**Usage:**
```bash
/create_merge_request HEAD           # Create MR for current changes
/create_merge_request develop..HEAD  # Create MR comparing branches
```

**Requirements:**
- `glab` CLI tool installed and configured
- GitLab repository with appropriate permissions

**Output:**
- Creates and pushes branch to remote
- Generates comprehensive MR description
- Creates merge request in GitLab
- Opens MR in browser
- Returns MR number and URL

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

## Requirements

### MCP Git Server

This plugin uses Model Context Protocol (MCP) git tools for safe and consistent git operations. Ensure the git MCP server is configured in your Claude Code settings.

### GitLab CLI (for MR commands)

The merge request commands require the GitLab CLI (`glab`):

```bash
# macOS
brew install glab

# Configure authentication
glab auth login
```

## Configuration

### Jira Ticket Prefix

By default, the plugin expects Jira ticket prefixes matching patterns like:
- `MLE-999`
- `TE-222`

If your project uses different ticket prefixes, you may need to customise the command prompts.

### GitLab Templates

The `/merge_request_md` and `/create_merge_request` commands can use GitLab merge request templates if available:

```
.gitlab/merge_request_templates/Feature_to_Develop.md
```

## Development

### Plugin Structure

```
.config/claude/plugins/git-conventional-commits/
├── plugin.json                 # Plugin manifest
├── README.md                   # This file
├── commands/                   # Slash commands
│   ├── commit_message.md
│   ├── rewrite_commit_message.md
│   ├── merge_request_md.md
│   └── create_merge_request.md
└── docs/                       # Documentation
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

### GitLab commands failing

1. Verify `glab` is installed: `glab --version`
2. Check authentication: `glab auth status`
3. Ensure you have push permissions to the repository
4. Verify you're working with a GitLab repository

## License

This plugin is part of the dotfiles repository and follows the same license.

## Contributing

To contribute improvements:
1. Test changes in your local environment
2. Update documentation as needed
3. Follow existing commit message conventions
4. Submit changes via the standard contribution process
