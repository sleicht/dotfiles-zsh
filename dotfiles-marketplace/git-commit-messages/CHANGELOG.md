# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-02-10

### Changed

- Migrate from MCP git tools (`mcp__git__*`) to standard git commands via Bash
- Remove mandatory `git_set_working_dir` initialisation step
- Simplify command instructions by removing MCP-specific guidance and troubleshooting

## [1.0.0] - Initial release

### Added

- `commit_message` command to generate improved commit messages following Conventional Commits
- `rewrite_commit_message` command to rewrite commit messages in git history
- Conventional Commits specification reference documentation
