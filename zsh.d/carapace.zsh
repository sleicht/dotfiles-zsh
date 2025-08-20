#!/usr/bin/env zsh

# === multi-shell multi-command argument complete ===
if command -v carapace > /dev/null; then
  export CARAPACE_BRIDGES='bat,zsh,fish,bash,inshellisense,tofu' # optional
  zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
  # shellcheck disable=SC1090
  source <(carapace _carapace)
fi
