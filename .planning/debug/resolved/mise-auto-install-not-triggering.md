---
status: resolved
trigger: "When user creates a directory with `.tool-versions` containing `node 18.20.0` and cd's into it, mise shows `WARN missing: node@18.20.0` instead of auto-installing."
created: 2026-02-08T00:00:00Z
updated: 2026-02-08T00:07:00Z
---

## Current Focus

hypothesis: Mise hook-env (activated during cd) does NOT trigger auto-install - only mise exec and command-not-found handler do
test: Verify from documentation and actual behavior that hook-env only updates PATH without installing tools
expecting: Documentation will confirm hook-env does not auto-install, only updates environment
next_action: Document root cause and resolution

## Symptoms

expected: When cd'ing into a directory with .tool-versions containing node 18.20.0, mise should automatically install the missing tool version
actual: Mise shows "WARN missing: node@18.20.0" instead of auto-installing
errors: WARN missing: node@18.20.0
reproduction: 1. Create directory with .tool-versions containing "node 18.20.0", 2. cd into directory, 3. Observe warning instead of auto-install
started: Current issue (user reported)

## Eliminated

## Evidence

- timestamp: 2026-02-08T00:01:00Z
  checked: ~/.config/mise/config.toml
  found: Both not_found_auto_install=true and exec_auto_install=true are enabled
  implication: Auto-install settings are correctly configured

- timestamp: 2026-02-08T00:02:00Z
  checked: Mise documentation on auto-install behavior
  found: "mise can only auto-install missing versions of tools that already have at least one version installed, because mise does not have a way of knowing which binaries a tool provides unless there is already an installed version of that tool"
  implication: This is a critical limitation but NOT the issue here - node already has multiple versions installed

- timestamp: 2026-02-08T00:03:00Z
  checked: Mise settings available
  found: auto_install=true, exec_auto_install=true, not_found_auto_install=true, task_run_auto_install=true
  implication: All auto-install settings are enabled

- timestamp: 2026-02-08T00:04:00Z
  checked: Mise documentation on auto-install mechanisms
  found: "Automatically install missing tools when running `mise x`, `mise run`, or as part of the 'not found' handler"
  implication: hook-env (cd activation) is NOT listed as an auto-install trigger

- timestamp: 2026-02-08T00:05:00Z
  checked: GitHub discussion #5735 "Do I need to run mise install?"
  found: User asks if they need to manually run install. Answer: "you only need to mise install a tool once, and even that is optional because you can just mise use it instead"
  implication: Auto-install happens when you TRY TO USE the tool, not just when entering the directory

- timestamp: 2026-02-08T00:06:00Z
  checked: Created test directory with .tool-versions containing node 18.20.0
  found: mise ls shows "node 18.20.0 (missing)" but does not auto-install on cd
  implication: Confirms that hook-env does not trigger auto-install

- timestamp: 2026-02-08T00:07:00Z
  checked: Ran `mise exec -- node --version` in test directory with missing node 18.20.0
  found: Successfully auto-installed node 18.20.0 and executed command
  implication: Confirms that mise exec DOES trigger auto-install, unlike cd/hook-env

## Resolution

root_cause: Mise's hook-env (which runs when cd'ing into directories) does NOT trigger auto-install. Hook-env only updates PATH and environment variables for tools that are already installed. Auto-install only triggers in these specific contexts: (1) when running `mise exec` or `mise run`, (2) when trying to execute a command and the "command not found" handler fires, or (3) when running `mise use`. Simply cd'ing into a directory with a .tool-versions file will show "WARN missing: node@18.20.0" but will NOT auto-install the tool.

fix: This is BY DESIGN, not a bug. User has two options: (1) Run `mise install` in the directory to manually install missing tools, or (2) Try to use the tool (e.g., run `node --version`) which will trigger the command-not-found handler to auto-install it, or (3) Use `mise exec -- node --version` which will auto-install before executing.

verification: Test that running `node` command in the test directory triggers auto-install via command-not-found handler, or that `mise exec -- node --version` auto-installs the missing version.

files_changed: []
