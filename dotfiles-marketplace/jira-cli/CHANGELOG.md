# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-03-11

### Fixed

- Add `JIRA_INSECURE=1` prefix to all jira commands to handle corporate TLS certificate verification issues

### Changed

- Downgrade jira-issues skill model from sonnet to haiku (sufficient for command lookup and execution)

## [1.0.0] - 2026-03-06

### Added

- `/jira` slash command for quick jira-cli reference
- `jira-issues` auto-triggering skill for issue management
- Comprehensive jira-cli reference documentation
