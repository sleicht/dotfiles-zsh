# DEPRECATED: git-conventional-commits Plugin

⚠️ **This plugin has been split into two focused plugins and is no longer maintained.**

## Why the Split?

The original `git-conventional-commits` plugin combined two distinct workflows:
1. **Local git operations** - Commit message generation and history rewriting
2. **GitLab collaboration** - Merge request creation and documentation

These have been separated into focused plugins with clear responsibilities.

## Migration Guide

### New Plugins

The functionality has been split into:

1. **@dotfiles-marketplace/git-commit-messages** - Commit message tools
   - `/commit_message` - Generate improved commit messages
   - `/rewrite_commit_message` - Rewrite commit messages in git history
   - Platform-agnostic (works with any git repository)
   - No external dependencies

2. **@dotfiles-marketplace/gitlab-merge-requests** - GitLab MR tools
   - `/merge_request_md` - Generate MR description to file
   - `/create_merge_request` - Create MR in GitLab
   - GitLab-specific functionality
   - Requires `glab` CLI

### Command Mapping

| Old Command | New Plugin | New Command |
|------------|------------|-------------|
| `/commit_message` | `git-commit-messages` | `/commit_message` |
| `/rewrite_commit_message` | `git-commit-messages` | `/rewrite_commit_message` |
| `/merge_request_md` | `gitlab-merge-requests` | `/merge_request_md` |
| `/create_merge_request` | `gitlab-merge-requests` | `/create_merge_request` |

### Installation

#### If you use both workflows:

```bash
# Install commit message tools
ln -s /path/to/dotfiles/dotfiles-marketplace/git-commit-messages ~/.claude/plugins/git-commit-messages

# Install GitLab MR tools
ln -s /path/to/dotfiles/dotfiles-marketplace/gitlab-merge-requests ~/.claude/plugins/gitlab-merge-requests
```

#### If you only use commit messages:

```bash
# Install just the commit message tools
ln -s /path/to/dotfiles/dotfiles-marketplace/git-commit-messages ~/.claude/plugins/git-commit-messages
```

#### If you only use GitLab MRs:

```bash
# Install just the GitLab MR tools
ln -s /path/to/dotfiles/dotfiles-marketplace/gitlab-merge-requests ~/.claude/plugins/gitlab-merge-requests
```

### Documentation Location

| Resource | Old Location | New Location |
|----------|-------------|--------------|
| Conventional Commits Spec | `docs/conventional-commits-spec.md` | `git-commit-messages/docs/conventional-commits-spec.md` |
| Overview | `README.md` | Split between both plugins' READMEs |
| Commit Commands | `commands/commit_message.md`, `commands/rewrite_commit_message.md` | `git-commit-messages/commands/` |
| MR Commands | `commands/merge_request_md.md`, `commands/create_merge_request.md` | `gitlab-merge-requests/commands/` |

## Benefits of the Split

1. **Clear separation of concerns** - Local git operations vs GitLab collaboration
2. **Platform flexibility** - Commit tools work with any git host (GitHub, GitLab, Gitea, etc.)
3. **Reduced dependencies** - Commit plugin has no external deps; MR plugin requires only `glab`
4. **User choice** - Install only what you need
5. **Easier maintenance** - Smaller, focused plugins are simpler to update and test
6. **Better discoverability** - Plugin names clearly indicate purpose

## Timeline

- **Deprecated**: 2026-01-08
- **Archived**: This directory is now `.archive` and will not receive updates
- **Removal**: This archived plugin may be removed in a future dotfiles update

## Questions?

For issues or questions about the new plugins, please file an issue in the dotfiles repository.

## Original README

The original README for this plugin has been preserved below for reference.

---

