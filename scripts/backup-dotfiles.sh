#!/usr/bin/env bash
# Dotfiles Backup Script
# Creates a complete, browsable backup of dotfiles to an external drive
#
# Usage:
#   ./backup-dotfiles.sh           # Dry-run mode (safe preview)
#   ./backup-dotfiles.sh --execute # Actually perform the backup
#   BACKUP_DRIVE=/Volumes/MyDrive ./backup-dotfiles.sh --execute
#
# Features:
#   - Pre-flight checks: mount detection, large file scan
#   - Dry-run by default for safety
#   - Symlinks preserved in main backup
#   - Dereferenced symlinks in separate _symlinks_resolved/ directory
#   - Metadata capture for recovery verification

set -euo pipefail

# Configuration - override with environment variables
BACKUP_DRIVE="${BACKUP_DRIVE:-/Volumes/PortableSSD/home_backup}"
BACKUP_DIR="$BACKUP_DRIVE/dotfiles-backup"
SOURCE_DIR="$HOME"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXCLUSIONS="$SCRIPT_DIR/dotfiles-backup-exclusions"

# Size threshold for large file warning (100MB in bytes)
LARGE_FILE_THRESHOLD=$((100 * 1024 * 1024))

# Parse arguments
DRY_RUN=true
for arg in "$@"; do
  case $arg in
    --execute)
      DRY_RUN=false
      ;;
    --help|-h)
      echo "Usage: $0 [--execute]"
      echo ""
      echo "Options:"
      echo "  --execute    Actually perform the backup (default is dry-run)"
      echo "  --help       Show this help message"
      echo ""
      echo "Environment variables:"
      echo "  BACKUP_DRIVE   Target drive path (default: /Volumes/PortableSSD/home_backup)"
      exit 0
      ;;
  esac
done

# Colours for output (disabled if not terminal)
if [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  BOLD='\033[1m'
  NC='\033[0m' # No colour
else
  RED=''
  GREEN=''
  YELLOW=''
  BLUE=''
  BOLD=''
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

# Print section header
section() {
  echo ""
  echo -e "${BOLD}=== $* ===${NC}"
  echo ""
}

# Check if external drive is mounted
check_drive_mounted() {
  section "Pre-flight: Mount Detection"

  if [ ! -d "$BACKUP_DRIVE" ]; then
    cat <<EOF
${RED}ERROR: External drive not mounted at $BACKUP_DRIVE${NC}

To fix:
  1. Connect your external backup drive
  2. Verify it appears in Finder
  3. Check mount point: ls /Volumes/

If your drive has a different name, set BACKUP_DRIVE:
  BACKUP_DRIVE=/Volumes/YourDriveName $0

Common drive names:
  /Volumes/Backup
  /Volumes/ExternalHD
  /Volumes/TimeMachine
EOF
    exit 1
  fi

  success "Drive mounted at $BACKUP_DRIVE"

  # Check available space
  local available_space
  available_space=$(df -h "$BACKUP_DRIVE" | tail -1 | awk '{print $4}')
  info "Available space: $available_space"
}

# Check exclusions file exists
check_exclusions_file() {
  if [ ! -f "$EXCLUSIONS" ]; then
    die "Exclusions file not found: $EXCLUSIONS"
  fi

  local pattern_count
  pattern_count=$(grep -v '^#' "$EXCLUSIONS" | grep -v '^$' | wc -l | tr -d ' ')
  success "Exclusions file found: $pattern_count patterns"
}

# Scan for large files that might slow backup
scan_large_files() {
  section "Pre-flight: Large File Scan"

  info "Scanning for files larger than 100MB..."
  info "(This helps identify unexpected large files)"
  echo ""

  # Find large files, excluding obvious large directories
  # Use a subshell to handle potential errors gracefully
  local large_files
  large_files=$(find "$SOURCE_DIR" \
    -maxdepth 4 \
    -type f \
    -size +${LARGE_FILE_THRESHOLD}c \
    ! -path "$SOURCE_DIR/Library/*" \
    ! -path "$SOURCE_DIR/Applications/*" \
    ! -path "$SOURCE_DIR/Downloads/*" \
    ! -path "$SOURCE_DIR/Movies/*" \
    ! -path "$SOURCE_DIR/Music/*" \
    ! -path "$SOURCE_DIR/Pictures/*" \
    ! -path "$SOURCE_DIR/.docker/*" \
    ! -path "$SOURCE_DIR/.orbstack/*" \
    ! -path "$SOURCE_DIR/.cargo/*" \
    ! -path "$SOURCE_DIR/.rustup/*" \
    ! -path "$SOURCE_DIR/.gradle/*" \
    ! -path "$SOURCE_DIR/.m2/*" \
    ! -path "$SOURCE_DIR/.Trash/*" \
    ! -path "$SOURCE_DIR/.cache/*" \
    ! -path "*/.git/objects/*" \
    ! -path "*/node_modules/*" \
    2>/dev/null | head -20 || true)

  if [ -n "$large_files" ]; then
    echo -e "${YELLOW}Large files found (>100MB):${NC}"
    echo ""
    echo "$large_files" | while read -r file; do
      if [ -f "$file" ]; then
        local size
        size=$(du -h "$file" 2>/dev/null | cut -f1)
        printf "  %8s  %s\n" "$size" "${file#$SOURCE_DIR/}"
      fi
    done
    echo ""
    warn "Review these files. They will be included in backup unless excluded."
    echo ""
  else
    success "No unexpected large files found"
  fi
}

# Display backup plan
show_backup_plan() {
  section "Backup Plan"

  echo "Source:      $SOURCE_DIR"
  echo "Destination: $BACKUP_DIR"
  echo "Exclusions:  $EXCLUSIONS"
  echo ""

  if $DRY_RUN; then
    echo -e "${YELLOW}MODE: DRY-RUN (no changes will be made)${NC}"
    echo "Run with --execute to perform actual backup"
  else
    echo -e "${GREEN}MODE: EXECUTE (backup will be performed)${NC}"
  fi
  echo ""
}

# Prompt user to continue
confirm_continue() {
  if $DRY_RUN; then
    return 0
  fi

  read -r -p "Continue with backup? (yes/no) " response
  if [ "$response" != "yes" ]; then
    echo "Backup cancelled."
    exit 0
  fi
}

# Perform main backup (preserving symlinks)
run_main_backup() {
  section "Main Backup (symlinks preserved)"

  local rsync_opts="-av --progress --stats --exclude-from=$EXCLUSIONS"

  if $DRY_RUN; then
    rsync_opts="$rsync_opts --dry-run"
  fi

  info "Running rsync with archive mode (symlinks preserved)..."
  echo ""

  # shellcheck disable=SC2086
  rsync $rsync_opts "$SOURCE_DIR/" "$BACKUP_DIR/"

  if ! $DRY_RUN; then
    success "Main backup complete"
  fi
}

# Backup symlink targets (dereferenced copy)
run_symlink_backup() {
  section "Symlink Resolution Backup"

  local symlink_dir="$BACKUP_DIR/_symlinks_resolved"
  local rsync_opts="-avL --progress --stats --exclude-from=$EXCLUSIONS"

  if $DRY_RUN; then
    rsync_opts="$rsync_opts --dry-run"
  fi

  info "Running rsync with -L (following symlinks)..."
  info "Destination: $symlink_dir"
  echo ""

  # Only backup directories that commonly contain symlinks we care about
  local symlink_sources=(
    "$SOURCE_DIR/.zshrc"
    "$SOURCE_DIR/.zshenv"
    "$SOURCE_DIR/.zprofile"
    "$SOURCE_DIR/.config"
  )

  for source in "${symlink_sources[@]}"; do
    if [ -e "$source" ]; then
      local relative_path="${source#$SOURCE_DIR/}"
      local dest="$symlink_dir/$relative_path"

      if ! $DRY_RUN; then
        mkdir -p "$(dirname "$dest")"
      fi

      # shellcheck disable=SC2086
      rsync $rsync_opts "$source" "$dest" 2>/dev/null || true
    fi
  done

  if ! $DRY_RUN; then
    success "Symlink resolution backup complete"
  fi
}

# Write backup metadata
write_metadata() {
  if $DRY_RUN; then
    info "Skipping metadata write (dry-run mode)"
    return 0
  fi

  section "Writing Metadata"

  local metadata_file="$BACKUP_DIR/backup-metadata.txt"

  cat > "$metadata_file" <<EOF
Dotfiles Backup Metadata
========================

Backup Date: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
Hostname:    $(hostname)
Username:    $(whoami)
Source:      $SOURCE_DIR
Destination: $BACKUP_DIR

macOS Version: $(sw_vers -productVersion 2>/dev/null || echo "N/A")
Kernel:        $(uname -r)

Exclusions Used: $EXCLUSIONS

Backup Contents:
  Main backup:       $BACKUP_DIR/
  Symlinks resolved: $BACKUP_DIR/_symlinks_resolved/

To restore, use: restore-dotfiles.sh

Git Status (if in dotfiles repo):
$(cd "$SOURCE_DIR/.dotfiles" 2>/dev/null && git log --oneline -5 2>/dev/null || echo "  (not a git repo or not found)")

EOF

  success "Metadata written to $metadata_file"
}

# Display completion summary
show_summary() {
  section "Backup Summary"

  if $DRY_RUN; then
    echo -e "${YELLOW}DRY-RUN COMPLETE${NC}"
    echo ""
    echo "No files were copied. Review the output above."
    echo "To perform actual backup, run:"
    echo ""
    echo "  $0 --execute"
    echo ""
  else
    echo -e "${GREEN}BACKUP COMPLETE${NC}"
    echo ""
    echo "Backup location: $BACKUP_DIR"
    echo ""
    echo "Contents:"
    ls -la "$BACKUP_DIR" 2>/dev/null | head -15
    echo ""
    echo "To verify backup:"
    echo "  cat $BACKUP_DIR/backup-metadata.txt"
    echo ""
    echo "To restore later:"
    echo "  ./restore-dotfiles.sh"
  fi
}

# Main execution
main() {
  echo ""
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}       DOTFILES BACKUP TOOL            ${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""

  # Pre-flight checks
  check_drive_mounted
  check_exclusions_file
  scan_large_files

  # Show plan and confirm
  show_backup_plan
  confirm_continue

  # Perform backups
  run_main_backup
  run_symlink_backup

  # Write metadata
  write_metadata

  # Show summary
  show_summary
}

main "$@"
