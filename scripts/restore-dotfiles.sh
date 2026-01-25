#!/usr/bin/env bash
# Dotfiles Recovery Script
# Interactive category-based restore from external backup
#
# Usage:
#   ./restore-dotfiles.sh
#   BACKUP_DRIVE=/Volumes/MyDrive ./restore-dotfiles.sh
#
# Each category prompts for confirmation before restore.
# Options: yes (restore), no (abort), skip (next category)

set -euo pipefail

# Configuration - override with environment variables
BACKUP_DRIVE="${BACKUP_DRIVE:-/Volumes/PortableSSD/home_backup}"
BACKUP_DIR="$BACKUP_DRIVE/dotfiles-backup"

# Colours for output (disabled if not terminal)
if [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  NC='\033[0m' # No colour
else
  RED=''
  GREEN=''
  YELLOW=''
  BLUE=''
  NC=''
fi

# Print error message and exit
die() {
  echo -e "${RED}ERROR:${NC} $*" >&2
  exit 1
}

# Print warning message
warn() {
  echo -e "${YELLOW}WARNING:${NC} $*" >&2
}

# Print info message
info() {
  echo -e "${BLUE}INFO:${NC} $*"
}

# Print success message
success() {
  echo -e "${GREEN}OK:${NC} $*"
}

# Check backup exists
check_backup_exists() {
  if [ ! -d "$BACKUP_DIR" ]; then
    cat <<EOF
${RED}ERROR: Backup not found at $BACKUP_DIR${NC}

Possible causes:
  1. External drive not mounted
  2. Backup was never created
  3. Wrong backup location

To check:
  - Verify drive is connected: ls /Volumes/
  - Check backup exists: ls "$BACKUP_DRIVE"

Expected structure:
  $BACKUP_DIR/
  ├── .config/
  ├── .zshrc
  ├── _symlinks_resolved/
  └── backup-metadata.txt
EOF
    exit 1
  fi
}

# Display backup metadata if available
show_backup_metadata() {
  local metadata_file="$BACKUP_DIR/backup-metadata.txt"

  echo ""
  echo "=== Backup Information ==="

  if [ -f "$metadata_file" ]; then
    cat "$metadata_file"
  else
    warn "No backup metadata found. Backup may be incomplete."
  fi

  echo ""
}

# Core restore function with interactive confirmation
# Arguments:
#   $1 - Category name (display)
#   $2 - Source path relative to BACKUP_DIR
#   $3 - Destination path (usually $HOME or subdirectory)
restore_category() {
  local category=$1
  local source_path=$2
  local dest_path=$3

  echo ""
  echo -e "${BLUE}=== $category ===${NC}"

  # Check if source exists in backup
  if [ ! -e "$BACKUP_DIR/$source_path" ]; then
    echo "Not found in backup: $source_path (skipping)"
    return 0
  fi

  # Show files that would be restored
  echo "Files to restore:"
  local file_list
  file_list=$(find "$BACKUP_DIR/$source_path" -type f 2>/dev/null | head -10)
  if [ -n "$file_list" ]; then
    echo "$file_list"
  fi

  local count
  count=$(find "$BACKUP_DIR/$source_path" -type f 2>/dev/null | wc -l | tr -d ' ')
  echo "... ($count files total)"

  # Check for existing files at destination
  if [ -e "$dest_path" ]; then
    warn "Destination exists: $dest_path (will be overwritten)"
  fi

  # Interactive prompt with yes/no/skip
  while true; do
    read -r -p "Restore $category? (yes/no/skip) " response
    case $response in
      yes)
        # Ensure parent directory exists
        mkdir -p "$(dirname "$dest_path")"

        # Perform restore with rsync
        rsync -av "$BACKUP_DIR/$source_path" "$dest_path"
        success "Restored $category"
        return 0
        ;;
      no)
        echo "Aborting recovery"
        exit 0
        ;;
      skip)
        echo "Skipped $category"
        return 0
        ;;
      *)
        echo "Please enter: yes, no, or skip"
        ;;
    esac
  done
}

# Main execution
main() {
  echo ""
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}       DOTFILES RECOVERY TOOL          ${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""

  # Verify backup exists
  check_backup_exists

  # Show backup information
  show_backup_metadata

  # Safety warning
  echo -e "${YELLOW}WARNING: This will overwrite existing files.${NC}"
  echo "Each category will prompt for confirmation."
  echo "Options: yes (restore), no (abort all), skip (next category)"
  echo ""

  read -r -p "Ready to begin? (yes/no) " ready
  if [ "$ready" != "yes" ]; then
    echo "Recovery cancelled."
    exit 0
  fi

  # Category-based restore
  # Order matters: core shell first, then tools, then catch-all

  # 1. Shell configs (most critical)
  restore_category "Shell configs (.zshrc, .zshenv, .zprofile)" \
    ".zshrc" "$HOME/.zshrc"

  if [ -e "$BACKUP_DIR/.zshenv" ]; then
    restore_category "Shell environment (.zshenv)" \
      ".zshenv" "$HOME/.zshenv"
  fi

  if [ -e "$BACKUP_DIR/.zprofile" ]; then
    restore_category "Shell profile (.zprofile)" \
      ".zprofile" "$HOME/.zprofile"
  fi

  if [ -d "$BACKUP_DIR/zsh.d" ]; then
    restore_category "ZSH modules (zsh.d/)" \
      "zsh.d" "$HOME/zsh.d"
  fi

  # 2. Git configs
  if [ -d "$BACKUP_DIR/.config/git" ]; then
    restore_category "Git configs (.config/git/)" \
      ".config/git" "$HOME/.config/git"
  fi

  if [ -f "$BACKUP_DIR/.gitconfig" ]; then
    restore_category "Git config (.gitconfig)" \
      ".gitconfig" "$HOME/.gitconfig"
  fi

  # 3. Editor configs
  if [ -d "$BACKUP_DIR/.config/nvim" ]; then
    restore_category "Neovim config (.config/nvim/)" \
      ".config/nvim" "$HOME/.config/nvim"
  fi

  if [ -f "$BACKUP_DIR/.vimrc" ]; then
    restore_category "Vim config (.vimrc)" \
      ".vimrc" "$HOME/.vimrc"
  fi

  # 4. Tool configs
  if [ -d "$BACKUP_DIR/.config/mise" ]; then
    restore_category "Mise config (.config/mise/)" \
      ".config/mise" "$HOME/.config/mise"
  fi

  if [ -d "$BACKUP_DIR/.config/sheldon" ]; then
    restore_category "Sheldon config (.config/sheldon/)" \
      ".config/sheldon" "$HOME/.config/sheldon"
  fi

  if [ -d "$BACKUP_DIR/.config/atuin" ]; then
    restore_category "Atuin config (.config/atuin/)" \
      ".config/atuin" "$HOME/.config/atuin"
  fi

  # 5. Terminal configs
  if [ -d "$BACKUP_DIR/.config/ghostty" ]; then
    restore_category "Ghostty config (.config/ghostty/)" \
      ".config/ghostty" "$HOME/.config/ghostty"
  fi

  if [ -d "$BACKUP_DIR/.config/kitty" ]; then
    restore_category "Kitty config (.config/kitty/)" \
      ".config/kitty" "$HOME/.config/kitty"
  fi

  if [ -f "$BACKUP_DIR/.config/wezterm.lua" ]; then
    restore_category "WezTerm config (.config/wezterm.lua)" \
      ".config/wezterm.lua" "$HOME/.config/wezterm.lua"
  fi

  # 6. Dotfiles repository
  if [ -d "$BACKUP_DIR/.dotfiles" ]; then
    restore_category "Dotfiles repository (.dotfiles/)" \
      ".dotfiles" "$HOME/.dotfiles"
  fi

  # 7. Remaining .config directories (catch-all)
  if [ -d "$BACKUP_DIR/.config" ]; then
    restore_category "All remaining .config/" \
      ".config" "$HOME/.config"
  fi

  # Completion message
  echo ""
  echo -e "${GREEN}========================================${NC}"
  echo -e "${GREEN}       RECOVERY COMPLETE               ${NC}"
  echo -e "${GREEN}========================================${NC}"
  echo ""
  echo "Next steps:"
  echo "  1. Test your shell: exec zsh"
  echo "  2. Verify key commands work"
  echo "  3. Check git config: git config --list"
  echo ""
}

main "$@"
