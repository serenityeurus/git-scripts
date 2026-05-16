#!/usr/bin/env bash
#
# pull-repos-latest.sh
# --------------------------------------------------------------
# Usage:   ./pull-repos-latest.sh <target-directory>
#
# For each immediate sub‑directory that is a Git repository, the script:
#   1. Determines the repository’s default branch (remote HEAD, or falls back
#      to "main"/"master").
#   2. Checks out that branch.
#   3. Fetches all remotes and hard‑resets to the latest commit on the
#      default branch.
#   4. Continues processing even if a repository fails, logging the error.
#
# At the end a **summary** is printed showing how many repos succeeded
# and which ones failed.
# --------------------------------------------------------------

set -uo pipefail   # keep -e off so we can handle errors per repo

# ------------------------------------------------------------------
# Helper: print usage and exit
# ------------------------------------------------------------------
usage() {
    echo "Error: Target directory argument missing."
    echo "Usage: $0 <target-directory>"
    exit 1
}

# ------------------------------------------------------------------
# Argument validation
# ------------------------------------------------------------------
if [[ $# -lt 1 ]]; then
    usage
fi

target_dir="$1"

if [[ ! -d "$target_dir" ]]; then
    echo "Error: '$target_dir' is not a directory."
    exit 1
fi

# ------------------------------------------------------------------
# Counters and status tracking for the final summary
# ------------------------------------------------------------------
success_count=0
failure_count=0
failed_repos=()
success_repos=()

# ------------------------------------------------------------------
# Process each immediate sub‑directory
# ------------------------------------------------------------------
for dir in "$target_dir"/*; do
    # Only consider entries that are directories and contain a .git folder
    if [[ -d "$dir" && -d "$dir/.git" ]]; then
        echo "--------------------------------------------------"
        echo "Processing repository: $dir"
        pushd "$dir" > /dev/null

        # --------------------------------------------------------------
        # Determine the default branch (remote HEAD)
        # --------------------------------------------------------------
        default_branch=$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null | sed 's@origin/@@')
        if [[ -z "$default_branch" ]]; then
            # Fallback to common defaults
            if git show-ref --verify --quiet refs/heads/main; then
                default_branch="main"
            elif git show-ref --verify --quiet refs/heads/master; then
                default_branch="master"
            else
                echo "Warning: Could not determine default branch for $dir. Skipping."
                popd > /dev/null
                ((failure_count++))
                failed_repos+=( "$dir (undetectable default branch)" )
                continue
            fi
        fi

        # --------------------------------------------------------------
        # Checkout the default branch (ignore errors – we’ll still try to fetch)
        # --------------------------------------------------------------
        git checkout "$default_branch" >/dev/null 2>&1 || true

        # --------------------------------------------------------------
        # Pull the latest changes
        # --------------------------------------------------------------
        local repo_status=""
        if git fetch --all --prune; then
            if git reset --hard "origin/$default_branch"; then
                echo "✅  $dir updated to latest commit on '$default_branch'"
                ((success_count++))
                success_repos+=("$dir (updated)")
                repo_status="updated"
            else
                echo "❌  $dir failed to reset to 'origin/$default_branch'"
                repo_status="reset_failed"
                ((failure_count++))
                failed_repos+=( "$dir (reset failed)" )
            fi
        else
            echo "❌  $dir failed to fetch remote"
            repo_status="fetch_failed"
            ((failure_count++))
            failed_repos+=( "$dir (fetch failed)" )
        fi

        # Track repo status for later summary
        case "$repo_status" in
            "updated") ;;
            "reset_failed") ;;
            "fetch_failed") ;;
            *)  # default for unexpected cases
                ;;
        esac

        popd > /dev/null
    fi
done

# ------------------------------------------------------------------
# Detailed summary
# ------------------------------------------------------------------
echo "--------------------------------------------------"
echo "Repository Status Summary"
echo "--------------------------------------------------"
echo "✅  Successes: $success_count"
echo "❌  Failures : $failure_count"
echo ""

# Show all repositories with their status
if (( success_count > 0 )); then
    echo "✅  Successfully updated:"
    for repo in "${success_repos[@]}"; do
        echo "  - $repo"
    done
    echo ""
fi

if (( failure_count > 0 )); then
    echo "❌  Failed repositories:"
    for repo in "${failed_repos[@]}"; do
        echo "  - $repo"
    done
    echo ""
fi

echo "Processing complete."