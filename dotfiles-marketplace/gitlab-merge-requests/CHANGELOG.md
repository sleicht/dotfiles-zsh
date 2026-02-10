# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2025-02-10

### Changed

- Configure commands to use Sonnet model for comprehensive MR descriptions and workflow orchestration
- Add `model: sonnet` to command frontmatter for `/merge_request_md` and `/create_merge_request`
- Update README with model selection rationale and quality characteristics

## [1.1.0] - 2025-02-10

### Changed

- Migrate from MCP git tools (`mcp__git__*`) to standard git commands via Bash
- Remove mandatory `git_set_working_dir` initialisation step
- Consolidate push instructions to use only standard git commands

## [1.0.0] - Initial release

### Added

- `create_merge_request` command to create and submit GitLab merge requests
- `merge_request_md` command to generate MR title and description
- Conventional Commits overview documentation
