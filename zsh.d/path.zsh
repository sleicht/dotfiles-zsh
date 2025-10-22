# Add directories to the PATH and prevent to add the same directory multiple times upon shell reload.
add_to_path() {
  if [[ -d "$1" ]] && [[ ":$PATH:" != *":$1:"* ]]; then
    export PATH="$1:$PATH"
  fi
}

# Load gnubin
add_to_path "/opt/homebrew/opt/findutils/libexec/gnubin"
add_to_path "/opt/homebrew/opt/grep/libexec/gnubin"
add_to_path "/opt/homebrew/opt/gnu-sed/libexec/gnubin"

# Load dotfiles binaries
add_to_path "$DOTFILES/bin"

# Ruby
add_to_path "/opt/homebrew/opt/ruby/bin"
add_to_path "$HOME/.rbenv/bin"

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
add_to_path "$PNPM_HOME"

# bun
export BUN_INSTALL="$HOME/.bun"
add_to_path "$BUN_INSTALL/bin"

# volta
export VOLTA_HOME="$HOME/.volta"
add_to_path "$VOLTA_HOME/bin"

# Load home bins
add_to_path "$HOME/.bin"
add_to_path "$HOME/.local/.bin"
add_to_path "$HOME/.rd/bin"
