#!/bin/bash

# Script to commit and push uncommitted changes in all git repos under sources/
# Usage: ./scripts/update-repos.sh [--force]

set -e  # Exit on any error

FORCE=false
if [ "$1" == "--force" ]; then
    FORCE=true
fi

if [ ! -d "sources" ]; then
    echo "Directory 'sources' does not exist. Nothing to update."
    exit 0
fi

echo "Finding all git repositories under sources/..."

# Find all .git directories and get their parent directories (the repo roots)
repos=$(find sources/ -name .git -type d -prune | sed 's|/.git$||')

if [ -z "$repos" ]; then
    echo "No git repositories found under sources/"
    exit 0
fi

for repo in $repos; do
    echo "Processing repository: $repo"
    cd "$repo"
    
    # Check if there are uncommitted changes
    if git status --porcelain | grep -q .; then
        echo "  Found uncommitted changes."
        git status --short
        
        if [ "$FORCE" = true ]; then
            echo "  Force enabled. Committing and pushing..."
            git add .
            git commit -m "Auto-commit uncommitted changes"
            
            # Push to the current branch
            current_branch=$(git rev-parse --abbrev-ref HEAD)
            echo "  Pushing to origin/$current_branch..."
            git push origin "$current_branch"
            echo "  Pushed successfully."
        else
            echo "  Skipping auto-commit (use --force to enable)."
            echo "  Please manually commit and push changes in $repo"
        fi
    else
        echo "  No uncommitted changes. Skipping."
    fi
    
    # Go back to the original directory
    cd - > /dev/null
done

echo "All repositories processed."
