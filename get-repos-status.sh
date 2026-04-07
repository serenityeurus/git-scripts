#!/bin/bash

# get-repos-status.sh
# Analyze git repositories in a directory and report their status

set -e

# Parse arguments
TARGET_DIR="${1:-.}"

# Validate directory exists
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory '$TARGET_DIR' does not exist." >&2
    exit 1
fi

# Get absolute path
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

echo "Scanning for git repositories in: $TARGET_DIR"
echo "=============================================="
echo ""

# Track if any repos found
FOUND_REPOS=0

# Find all .git directories
while IFS= read -r -d '' gitdir; do
    repo_dir="$(dirname "$gitdir")"
    repo_name="$(basename "$repo_dir")"
    FOUND_REPOS=1
    
    # Navigate to repo
    pushd "$repo_dir" > /dev/null 2>&1
    
    # Get current branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "DETACHED")
    
    # Check for detached HEAD
    if [ "$branch" = "DETACHED" ]; then
        commit=$(git rev-parse --short HEAD 2>/dev/null)
        branch="HEAD at $commit"
    fi
    
    # Check working tree status
    status="clean"
    staged=0
    unstaged=0
    untracked=0
    
    staged=$(git diff --cached --numstat 2>/dev/null | wc -l)
    unstaged=$(git diff --numstat 2>/dev/null | wc -l)
    untracked=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l)
    
    if [ "$staged" -gt 0 ] || [ "$unstaged" -gt 0 ]; then
        status="dirty"
    fi
    if [ "$untracked" -gt 0 ]; then
        if [ "$status" = "clean" ]; then
            status="untracked"
        fi
    fi
    
    # Build status details
    details=""
    [ "$staged" -gt 0 ] && details="${details}+${staged} staged "
    [ "$unstaged" -gt 0 ] && details="${details}~${unstaged} modified "
    [ "$untracked" -gt 0 ] && details="${details}?${untracked} untracked"
    details="$(echo "$details" | xargs)"  # trim whitespace
    
    # Check sync status with remote
    sync_status="no remote"
    remote_branch=$(git rev-parse --abbrev-ref @{upstream} 2>/dev/null || echo "")
    
    if [ -n "$remote_branch" ]; then
        ahead=$(git rev-list --count @{upstream}..HEAD 2>/dev/null || echo 0)
        behind=$(git rev-list --count HEAD..{upstream} 2>/dev/null || echo 0)
        
        if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
            sync_status="diverged (↑${ahead} ↓${behind})"
        elif [ "$ahead" -gt 0 ]; then
            sync_status="ahead ${ahead}"
        elif [ "$behind" -gt 0 ]; then
            sync_status="behind ${behind}"
        else
            sync_status="synced"
        fi
    fi
    
    # Output
    echo "📦 $repo_name"
    echo "   Path: $repo_dir"
    echo "   Branch: $branch"
    echo "   Status: $status${details:+ ($details)}"
    echo "   Sync: $sync_status"
    echo ""
    
    popd > /dev/null 2>&1
    
done < <(find "$TARGET_DIR" -maxdepth 2 -name ".git" -type d -print0 2>/dev/null)

if [ "$FOUND_REPOS" = "0" ]; then
    echo "No git repositories found in '$TARGET_DIR'"
    exit 0
fi

echo "=============================================="
echo "Done."