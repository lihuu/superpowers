#!/bin/bash
# skills/handoff/scripts/gather-state.sh
# Gathers git state and basic project info for handoff summary.

PROJECT_ROOT=$1
if [ -z "$PROJECT_ROOT" ]; then PROJECT_ROOT="."; fi

echo "### Git State"
echo "- **Branch:** $(git -C "$PROJECT_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")"
echo "- **Last Commit:** $(git -C "$PROJECT_ROOT" rev-parse --short HEAD 2>/dev/null || echo "none")"

echo ""
echo "### Modified Files"
git -C "$PROJECT_ROOT" status --short | sed 's/^/- /'

echo ""
echo "### Recent Commits (Last 3)"
git -C "$PROJECT_ROOT" log -n 3 --oneline | sed 's/^/- /'
