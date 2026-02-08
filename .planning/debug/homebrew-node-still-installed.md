---
status: diagnosed
trigger: "Homebrew node v25.6.0 still installed despite Phase 5 cleanup"
created: 2026-02-08T00:00:00Z
updated: 2026-02-08T00:06:45Z
symptoms_prefilled: true
goal: find_root_cause_only
---

## Current Focus

hypothesis: Homebrew node was reinstalled as a dependency of another formula
test: Check .chezmoidata.yaml and Brewfile for node references and dependencies
expecting: Find either direct node reference or a formula that depends on node
next_action: Read .chezmoidata.yaml and check for node references

## Symptoms

expected: Homebrew node should not be installed after Phase 5 Plan 03 cleanup
actual: brew list node shows /opt/homebrew/Cellar/node/25.6.0 is present
errors: None - just unexpected presence of package
reproduction: Run 'brew list node' - shows installed
started: Noticed after Phase 5 Plan 03 execution

## Eliminated

## Evidence

- timestamp: 2026-02-08T00:05:00Z
  checked: .chezmoidata.yaml packages list
  found: node is NOT listed in any brew package list (common_brews, client_brews, fanaka_brews)
  implication: node was successfully removed from package definitions

- timestamp: 2026-02-08T00:05:30Z
  checked: brew uses --installed node
  found: Two packages depend on node: firebase-cli and phantom
  implication: node was reinstalled as a dependency when these packages were installed

- timestamp: 2026-02-08T00:06:00Z
  checked: .chezmoidata.yaml for firebase-cli
  found: firebase-cli is in fanaka_brews (line 185)
  implication: firebase-cli is explicitly installed and pulls in node as dependency

- timestamp: 2026-02-08T00:06:30Z
  checked: .chezmoidata.yaml for phantom
  found: phantom is in common_brews (line 79)
  implication: phantom is on all machines and pulls in node as dependency

- timestamp: 2026-02-08T00:07:00Z
  checked: mise ls node and which node
  found: mise manages multiple node versions (18.20.8, 20.19.0, 20.19.6, 22.21.1, 24.13.0). Active node is v22.21.1 from mise at ~/.local/share/mise/installs/node/22.21.1/bin/node
  implication: mise has exclusive control of node in PATH. Homebrew's node v25.6.0 is installed but not in use

## Resolution

root_cause: Homebrew node was reinstalled as a transitive dependency. Two packages depend on node: firebase-cli (in fanaka_brews) and phantom (in common_brews). When Homebrew installs these packages, it automatically installs their dependencies, including node. This is expected Homebrew behavior - dependencies are managed automatically and cannot be excluded.
fix: N/A - This is not actually a bug, it's expected behavior
verification: N/A
files_changed: []
