#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract current working directory from JSON
current_dir=$(echo "$input" | jq -r '.workspace.current_dir')

# Get the basename of the current directory
dir_name=$(basename "$current_dir")

# Check if we're in a git repository
if git -C "$current_dir" rev-parse --git-dir > /dev/null 2>&1; then
    # Get the current git branch
    branch=$(git -C "$current_dir" branch --show-current 2>/dev/null)
    if [[ -z "$branch" ]]; then
        # Fallback for detached HEAD
        branch=$(git -C "$current_dir" rev-parse --short HEAD 2>/dev/null)
        branch="($branch)"
    fi
    
    # Check for uncommitted changes
    if ! git -C "$current_dir" diff --quiet 2>/dev/null || ! git -C "$current_dir" diff --cached --quiet 2>/dev/null; then
        status_indicator="*"
    else
        status_indicator=""
    fi
    
    printf "%s [%s%s]" "$dir_name" "$branch" "$status_indicator"
else
    printf "%s" "$dir_name"
fi