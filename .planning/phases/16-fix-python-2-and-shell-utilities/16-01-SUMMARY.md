---
phase: 16-fix-python-2-and-shell-utilities
plan: 01
subsystem: shell-utilities
tags: [modernisation, python3, chezmoi, cleanup]

dependencies:
  requires: []
  provides:
    - "CHEZFIX-05: reloadshell uses exec shell reload"
    - "CHEZFIX-06: server() uses Python 3 http.server"
    - "CHEZFIX-07: urlencode uses Python 3 urllib.parse"
    - "CHEZFIX-08: update alias has no npm/gem commands"
  affects:
    - "~/.zsh.d/aliases.zsh"
    - "~/.zsh.d/functions.zsh"

tech_stack:
  added: []
  patterns:
    - "Python 3 standard library modules"
    - "exec shell reload pattern"
    - "mise-first runtime management"

key_files:
  created: []
  modified:
    - path: "dot_zsh.d/aliases.zsh"
      purpose: "Modernised Python 2 aliases and removed stale commands"
    - path: "dot_zsh.d/functions.zsh"
      purpose: "Updated server() to use Python 3 http.server"

decisions: []

metrics:
  duration_seconds: 80
  tasks_completed: 2
  files_modified: 2
  commits: 2
  completed_at: "2026-02-14T08:20:42Z"
---

# Phase 16 Plan 01: Fix Python 2 and Shell Utilities Summary

**One-liner:** Modernised shell utilities to use Python 3 and removed stale omz/npm/gem commands from aliases and functions

## What Was Done

Fixed four stale shell utilities in chezmoi source files:

1. **aliases.zsh modernisation:**
   - Replaced `omz reload` with `exec ${SHELL} -l` in reloadshell alias (matches existing reload alias pattern)
   - Updated urlencode alias from Python 2 `urllib` to Python 3 `urllib.parse`
   - Removed stale npm and gem commands from update alias (mise manages these runtimes now)

2. **functions.zsh modernisation:**
   - Replaced Python 2 `SimpleHTTPServer` with Python 3 `http.server` module in server() function
   - Removed unnecessary Content-Type monkey-patching (Python 3 handles this correctly by default)
   - Simplified implementation while maintaining auto-open browser behaviour

All changes made in chezmoi source directory (`~/.local/share/chezmoi/dot_zsh.d/`) and applied to target files.

## Deviations from Plan

None - plan executed exactly as written.

## Auth Gates / Human Actions

None required.

## Commits

| Commit  | Type | Description                                        |
|---------|------|----------------------------------------------------|
| 2998dfd | fix  | Modernise aliases.zsh - remove omz, Python 2, npm/gem |
| cb7261e | fix  | Modernise server() function to use Python 3        |

## Verification Results

All verification checks passed:

```bash
# No Python 2 SimpleHTTPServer references
$ grep -c 'SimpleHTTPServer' ~/.local/share/chezmoi/dot_zsh.d/functions.zsh
0

# No omz reload references
$ grep -c 'omz reload' ~/.local/share/chezmoi/dot_zsh.d/aliases.zsh
0

# No Python 2 urllib references
$ grep -c 'urllib as ul' ~/.local/share/chezmoi/dot_zsh.d/aliases.zsh
0

# No npm/gem commands in update alias
$ grep 'alias update=' ~/.local/share/chezmoi/dot_zsh.d/aliases.zsh | grep -c 'npm\|gem'
0
```

Applied changes with `chezmoi apply ~/.zsh.d/aliases.zsh ~/.zsh.d/functions.zsh`

## Files Changed

### Modified

**dot_zsh.d/aliases.zsh**
- Line 15: `alias reloadshell="exec ${SHELL} -l"` (was: `"omz reload"`)
- Line 67: `alias update='sudo softwareupdate -i -a; brew update; brew upgrade; brew cleanup'` (removed: npm/gem commands)
- Line 140: `alias urlencode='python3 -c "import sys, urllib.parse; print(urllib.parse.quote_plus(sys.argv[1]))"'` (was: Python 2 urllib)

**dot_zsh.d/functions.zsh**
- Lines 104-110: Simplified server() function to use `python3 -m http.server "$port"`

## Success Criteria Met

- [x] CHEZFIX-05: reloadshell alias uses exec shell reload
- [x] CHEZFIX-06: server() uses python3 -m http.server
- [x] CHEZFIX-07: urlencode uses python3 urllib.parse
- [x] CHEZFIX-08: update alias has no npm/gem commands
- [x] All changes in chezmoi source (dot_zsh.d/), not target files

## Self-Check

Verifying claimed files and commits exist.

```bash
# Check modified files exist
$ [ -f "/Users/stephanlv_fanaka/.local/share/chezmoi/dot_zsh.d/aliases.zsh" ] && echo "FOUND: dot_zsh.d/aliases.zsh" || echo "MISSING: dot_zsh.d/aliases.zsh"
FOUND: dot_zsh.d/aliases.zsh

$ [ -f "/Users/stephanlv_fanaka/.local/share/chezmoi/dot_zsh.d/functions.zsh" ] && echo "FOUND: dot_zsh.d/functions.zsh" || echo "MISSING: dot_zsh.d/functions.zsh"
FOUND: dot_zsh.d/functions.zsh

# Check commits exist in chezmoi repo
$ cd ~/.local/share/chezmoi && git log --oneline --all | grep -q "2998dfd" && echo "FOUND: 2998dfd" || echo "MISSING: 2998dfd"
FOUND: 2998dfd

$ cd ~/.local/share/chezmoi && git log --oneline --all | grep -q "cb7261e" && echo "FOUND: cb7261e" || echo "MISSING: cb7261e"
FOUND: cb7261e
```

## Self-Check: PASSED
