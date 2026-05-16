#!/bin/bash
# skills/handoff/scripts/gather-state.sh
# Gathers git state and basic project info for handoff summary.

PROJECT_ROOT="${1:-.}"

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "Error: git command not found." >&2
    exit 1
fi

# Check if we are inside a git work tree
if ! git -C "$PROJECT_ROOT" rev-parse --is-inside-work-tree &> /dev/null; then
    echo "Error: $PROJECT_ROOT is not a git repository." >&2
    exit 1
fi

echo "### Git State"
BRANCH=$(git -C "$PROJECT_ROOT" symbolic-ref --quiet --short HEAD 2>/dev/null || git -C "$PROJECT_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
LAST_COMMIT=$(git -C "$PROJECT_ROOT" rev-parse --verify --short HEAD 2>/dev/null || echo "none")
echo "- **Branch:** $BRANCH"
echo "- **Last Commit:** $LAST_COMMIT"

echo ""
echo "### Modified Files"
git -C "$PROJECT_ROOT" status --short | sed 's/^/- /'

echo ""
echo "### Recent Commits (Last 3)"
if git -C "$PROJECT_ROOT" rev-parse --verify HEAD >/dev/null 2>&1; then
    git -C "$PROJECT_ROOT" log -n 3 --oneline | sed 's/^/- /'
else
    echo "- none"
fi
