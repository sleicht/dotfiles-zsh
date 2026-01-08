# GitLab Merge Requests Plugin

A Claude Code plugin that creates GitLab merge requests with comprehensive descriptions following Conventional Commits philosophy.

## Features

This plugin provides two powerful slash commands for managing GitLab merge requests:

- **`/merge_request_md`** - Generate merge request title and description to file
- **`/create_merge_request`** - Create and submit GitLab merge requests

All commands enforce:
- Jira ticket prefixes (e.g., MLE-999, TE-222)
- Conventional Commits philosophy (business value focus)
- Comprehensive MR descriptions
- Focus on "WHY" over implementation details
- Clear test plans and checklists

## Prerequisites

This plugin requires the GitLab CLI (`glab`):

```bash
# macOS
brew install glab

# Configure authentication
glab auth login
```

You must also:
- Be working in a GitLab repository
- Have appropriate push permissions
- Have the git MCP server configured in Claude Code settings

## Installation

### From Dotfiles Repository

If this plugin is part of your dotfiles setup, it should be automatically installed via Dotbot configuration.

### Manual Installation

```bash
# Create plugins directory if it doesn't exist
mkdir -p ~/.claude/plugins

# Clone or symlink the plugin
ln -s /path/to/dotfiles/dotfiles-marketplace/gitlab-merge-requests ~/.claude/plugins/gitlab-merge-requests
```

### Installation in Other Projects

To use this plugin in other projects:

```bash
# Option 1: Copy the plugin directory
cp -r /path/to/dotfiles/dotfiles-marketplace/gitlab-merge-requests ~/.claude/plugins/

# Option 2: Create a symlink (recommended)
ln -s /path/to/dotfiles/dotfiles-marketplace/gitlab-merge-requests ~/.claude/plugins/gitlab-merge-requests
```

## Commands

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
- Summary focused on business value and user impact
- Test plan
- Checklist

**Example Output:**
```markdown
# MLE-999: feat(auth): implement JWT token validation

## Summary

Enhance authentication security to prevent unauthorised access from expired or tampered tokens.

- Validates token expiry and signature using RS256
- Adds comprehensive error handling for edge cases
- Improves user experience with clear error messages

## Test Plan

- [ ] Verify valid tokens are accepted
- [ ] Verify expired tokens are rejected
- [ ] Verify tampered tokens are rejected
- [ ] Test error message clarity
```

### `/create_merge_request`

Generates merge request description, pushes changes, and creates a GitLab merge request.

**Usage:**
```bash
/create_merge_request HEAD           # Create MR for current changes
/create_merge_request develop..HEAD  # Create MR comparing branches
```

**Output:**
- Creates and pushes branch to remote
- Generates comprehensive MR description focused on business value
- Creates merge request in GitLab (default target: `develop`)
- Opens MR in browser
- Returns MR number and URL

**Example:**
```bash
$ /create_merge_request HEAD
✓ Pushed branch feature/MLE-999-jwt-validation
✓ Created merge request !123
→ https://gitlab.com/org/project/-/merge_requests/123
```

## Conventional Commits Philosophy

This plugin follows the Conventional Commits philosophy with Jira ticket prefixes. Merge request descriptions emphasise:

- **Business value** over implementation details
- **User impact** and problem solving
- **WHY** changes were made, not just WHAT changed
- **Concise, clear communication** (2-3 high-level bullet points preferred)

### Message Format

```
<jira-ticket>: <type>[optional scope]: <description>

[Summary focused on business value and user impact]

[Test plan and checklist]
```

For the complete Conventional Commits specification, see the companion plugin:
- **@dotfiles-marketplace/git-commit-messages** - Full specification and commit message tools

For a brief overview, see: [docs/conventional-commits-overview.md](docs/conventional-commits-overview.md)

## Configuration

### Jira Ticket Prefix

By default, the plugin expects Jira ticket prefixes matching patterns like:
- `MLE-999`
- `TE-222`

If your project uses different ticket prefixes, you may need to customise the command prompts.

### GitLab Templates

The commands can use GitLab merge request templates if available:

```
.gitlab/merge_request_templates/Feature_to_Develop.md
```

If a template exists, the plugin will read it and incorporate relevant sections into the generated MR description.

### Target Branch

By default, merge requests target the `develop` branch. You can modify this in the command execution if your project uses a different default branch (e.g., `main`, `master`).

## Development

### Plugin Structure

```
dotfiles-marketplace/gitlab-merge-requests/
├── .claude-plugin/
│   └── plugin.json                 # Plugin manifest
├── README.md                        # This file
├── commands/                        # Slash commands
│   ├── merge_request_md.md
│   └── create_merge_request.md
└── docs/                            # Documentation
    └── conventional-commits-overview.md
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
4. Verify you're working with a GitLab repository (not GitHub, etc.)
5. Check that your branch is up to date with remote

### Permission errors

If you encounter permission errors:
1. Verify you have push access to the repository
2. Check that you're authenticated: `glab auth status`
3. Ensure your SSH keys or tokens are properly configured

## Related Plugins

For git commit message functionality, see the companion plugin:
- **@dotfiles-marketplace/git-commit-messages** - Generate and rewrite commit messages following Conventional Commits

## Licence

This plugin is part of the dotfiles repository and follows the same licence.

## Contributing

To contribute improvements:
1. Test changes in your local environment
2. Update documentation as needed
3. Follow existing commit message conventions
4. Submit changes via the standard contribution process
