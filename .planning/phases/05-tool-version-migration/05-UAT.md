---
status: diagnosed
phase: 05-tool-version-migration
source: 05-01-SUMMARY.md, 05-02-SUMMARY.md, 05-03-SUMMARY.md, 05-04-SUMMARY.md, 05-05-SUMMARY.md
started: 2026-02-08T09:00:00Z
updated: 2026-02-08T09:15:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Mise manages runtime versions
expected: Run `mise current` — shows 7 runtimes (node, python, go, rust, java, ruby, terraform) with versions
result: pass

### 2. Node available via mise
expected: Run `node --version` — returns a version (e.g., v22.x or v24.x). Run `which node` — path contains `.local/share/mise/`
result: pass

### 3. Python available via mise
expected: Run `python3 --version` — returns Python 3.12.x. Run `which python3` — path contains `.local/share/mise/`
result: pass

### 4. Tool switching with mise use
expected: Run `mise use node@20` in a temp directory. Then `node --version` shows v20.x. Afterwards run `mise use node@lts` to restore.
result: pass

### 5. Auto-install on directory entry
expected: Create a temp directory, add a `.tool-versions` file with `node 18.20.0`, cd into it. Mise should auto-install node 18 and `node --version` should show v18.20.0.
result: issue
reported: "I get this msg: mise WARN missing: node@18.20.0"
severity: minor
diagnosis: by-design

### 6. Mise tab completions
expected: Type `mise ` then press Tab in your terminal. You should see completion suggestions (install, use, current, etc.)
result: pass

### 7. Clean shell startup
expected: Open a new terminal tab/window. No error messages on startup. Shell loads cleanly.
result: pass

### 8. No Homebrew runtime conflicts
expected: Run `brew list node 2>&1` and `brew list rust 2>&1` — both should say "No formulae found" or similar (not installed via Homebrew).
result: issue
reported: "brew list node shows /opt/homebrew/Cellar/node/25.6.0 with full file listing. Homebrew node is installed alongside mise node. Rust correctly absent."
severity: minor
diagnosis: by-design

## Summary

total: 8
passed: 6
issues: 2 (both by-design, no fix required)
pending: 0
skipped: 0

## Gaps

- truth: "Mise auto-installs missing tools when entering a directory with .tool-versions"
  status: by-design
  reason: "User reported: I get this msg: mise WARN missing: node@18.20.0"
  severity: minor
  test: 5
  root_cause: "Mise hook-env (cd trigger) does NOT auto-install by design. Auto-install only triggers on: mise exec, mise run, or command-not-found handler. The warning is informational. Running the tool (e.g. node --version) or mise install will install the missing version."
  artifacts:
    - path: "~/.config/mise/config.toml"
      issue: "Settings are correct (auto_install=true, exec_auto_install=true). This is a design limitation of hook-env, not a config issue."
  missing: []
  debug_session: ".planning/debug/resolved/mise-auto-install-not-triggering.md"

- truth: "Homebrew node is removed so mise has exclusive runtime control"
  status: by-design
  reason: "User reported: brew list node shows /opt/homebrew/Cellar/node/25.6.0 with full file listing. Homebrew node is installed alongside mise node. Rust correctly absent."
  severity: minor
  test: 8
  root_cause: "Node was reinstalled as a transitive dependency of phantom and firebase-cli (both in .chezmoidata.yaml). Homebrew automatically installs node as a dependency. However, mise's node takes precedence in PATH — which node points to mise, not Homebrew."
  artifacts:
    - path: "~/.local/share/chezmoi/.chezmoidata.yaml"
      issue: "phantom (line 79, common_brews) and firebase-cli (line 185, fanaka_brews) depend on Homebrew node"
  missing: []
  debug_session: ".planning/debug/homebrew-node-still-installed.md"
