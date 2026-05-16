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
echo "- **Branch:** $(git -C "$PROJECT_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")"
echo "- **Last Commit:** $(git -C "$PROJECT_ROOT" rev-parse --short HEAD 2>/dev/null || echo "none")"

echo ""
echo "### Modified Files"
git -C "$PROJECT_ROOT" status --short | sed 's/^/- /'

echo ""
echo "### Recent Commits (Last 3)"
git -C "$PROJECT_ROOT" log -n 3 --oneline | sed 's/^/- /'
