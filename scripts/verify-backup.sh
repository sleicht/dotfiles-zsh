#!/usr/bin/env bash
# Backup Verification Script
# Validates backup completeness before starting migration
#
# Usage:
#   ./verify-backup.sh
#   BACKUP_DRIVE=/Volumes/MyDrive ./verify-backup.sh
#
# Exit codes:
#   0 - All critical files present
#   1 - Missing critical files or backup not found

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

# Critical files that MUST exist in backup
CRITICAL_FILES=(
  # Git configuration (symlinks in home directory)
  ".gitconfig"
  ".gitignore_global"
  # Shell plugin manager (zgenom)
  ".config/zgenom/zgenomrc.zsh"
  ".zgenom"
  # Shell customisations
  ".zsh.d"
  # Dotfiles repository itself
  ".dotfiles"
)

# Key directories to validate
KEY_DIRECTORIES=(
  ".config"
  ".zsh.d"
)

# Counters
MISSING_CRITICAL=0
TOTAL_CRITICAL=${#CRITICAL_FILES[@]}
WARNINGS=0

# Print error message
error() {
  echo -e "${RED}ERROR:${NC} $*" >&2
}

# Print warning message
warn() {
  echo -e "${YELLOW}WARNING:${NC} $*"
  ((WARNINGS++)) || true
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
  echo ""
  echo -e "${BLUE}=== Backup Existence ===${NC}"

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

Run backup first: ./scripts/backup-dotfiles.sh
EOF
    exit 1
  fi

  success "Backup directory exists: $BACKUP_DIR"
}

# Check and display metadata
check_metadata() {
  echo ""
  echo -e "${BLUE}=== Backup Metadata ===${NC}"

  local metadata_file="$BACKUP_DIR/backup-metadata.txt"

  if [ ! -f "$metadata_file" ]; then
    warn "No backup-metadata.txt found. Backup may be incomplete or created manually."
    return 0
  fi

  # Display metadata
  echo "Metadata contents:"
  cat "$metadata_file"
  echo ""

  # Parse and check backup age
  local backup_date
  backup_date=$(grep -E "^Date:" "$metadata_file" | sed 's/Date: //' || true)

  if [ -n "$backup_date" ]; then
    # Check if backup is older than 7 days
    local backup_epoch current_epoch age_days
    backup_epoch=$(date -j -f "%Y-%m-%d %H:%M:%S" "$backup_date" +%s 2>/dev/null || echo "0")
    current_epoch=$(date +%s)

    if [ "$backup_epoch" != "0" ]; then
      age_days=$(( (current_epoch - backup_epoch) / 86400 ))
      if [ "$age_days" -gt 7 ]; then
        warn "Backup is $age_days days old. Consider creating a fresh backup."
      else
        success "Backup is $age_days days old."
      fi
    fi
  fi
}

# Check critical files
check_critical_files() {
  echo ""
  echo -e "${BLUE}=== Critical Files ===${NC}"

  for file in "${CRITICAL_FILES[@]}"; do
    if [ -e "$BACKUP_DIR/$file" ]; then
      success "Found: $file"
    else
      error "Missing: $file"
      ((MISSING_CRITICAL++)) || true
    fi
  done
}

# Check directory structure
check_directory_structure() {
  echo ""
  echo -e "${BLUE}=== Directory Structure ===${NC}"

  for dir in "${KEY_DIRECTORIES[@]}"; do
    if [ -d "$BACKUP_DIR/$dir" ]; then
      local count
      count=$(find "$BACKUP_DIR/$dir" -type f 2>/dev/null | wc -l | tr -d ' ')
      success "Found: $dir/ ($count files)"
    else
      warn "Directory not found: $dir/"
    fi
  done
}

# Check symlinks resolved directory
check_symlinks_resolved() {
  echo ""
  echo -e "${BLUE}=== Symlinks Resolved ===${NC}"

  local symlinks_dir="$BACKUP_DIR/_symlinks_resolved"

  if [ -d "$symlinks_dir" ]; then
    local count
    count=$(find "$symlinks_dir" -type f 2>/dev/null | wc -l | tr -d ' ')
    success "Dereferenced symlinks directory exists ($count files)"
  else
    warn "No _symlinks_resolved/ directory. Symlinks may not have been dereferenced."
  fi
}

# Count total files
count_total_files() {
  echo ""
  echo -e "${BLUE}=== Total Files ===${NC}"

  local total
  total=$(find "$BACKUP_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')
  info "Total files in backup: $total"
}

# Print summary
print_summary() {
  echo ""
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}       VERIFICATION SUMMARY            ${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""

  local critical_present=$((TOTAL_CRITICAL - MISSING_CRITICAL))

  echo "Critical files: $critical_present/$TOTAL_CRITICAL present"
  echo "Warnings: $WARNINGS"

  if [ -f "$BACKUP_DIR/backup-metadata.txt" ]; then
    local backup_date
    backup_date=$(grep -E "^Date:" "$BACKUP_DIR/backup-metadata.txt" | sed 's/Date: //' || echo "Unknown")
    echo "Last backup: $backup_date"
  fi

  local total_files
  total_files=$(find "$BACKUP_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')
  echo "Total files: $total_files"

  echo ""

  if [ "$MISSING_CRITICAL" -gt 0 ]; then
    echo -e "${RED}VERIFICATION FAILED${NC}"
    echo "$MISSING_CRITICAL critical file(s) missing."
    echo "Create a fresh backup before proceeding with migration."
    exit 1
  else
    echo -e "${GREEN}VERIFICATION PASSED${NC}"
    echo "All critical files present. Safe to proceed with migration."
    if [ "$WARNINGS" -gt 0 ]; then
      echo "Note: $WARNINGS warning(s) issued. Review above for details."
    fi
    exit 0
  fi
}

# Main execution
main() {
  echo ""
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}      BACKUP VERIFICATION TOOL         ${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""
  info "Checking backup at: $BACKUP_DIR"

  check_backup_exists
  check_metadata
  check_critical_files
  check_directory_structure
  check_symlinks_resolved
  count_total_files
  print_summary
}

main "$@"
