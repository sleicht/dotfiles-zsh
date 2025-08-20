#!/usr/bin/env zsh

# === Advanced History ===
if command -v atuin > /dev/null; then
#  export ATUIN_NOBIND="true"
  eval "$(atuin init zsh)"
fi
