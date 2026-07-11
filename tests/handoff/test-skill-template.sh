#!/bin/bash
# tests/handoff/test-skill-template.sh
set -e

SKILL_FILE="skills/handoff/SKILL.md"

for required in \
    "Default to Rich Handoff" \
    "Use Emergency Handoff only" \
    "## Handoff Template" \
    "## Current Objective" \
    "## Decision State" \
    "## What Was Tried" \
    "## Work Completed" \
    "## Pending Tasks" \
    "Next Immediate Action" \
    "## Modified Files" \
    "## Mental State & Blockers" \
    "## Source Transcript" \
    "## Emergency Handoff Template"; do
    if ! grep -q "$required" "$SKILL_FILE"; then
        echo "FAIL: Missing required template text: $required"
        exit 1
    fi
done

rich_line=$(grep -n "Default to Rich Handoff" "$SKILL_FILE" | head -n1 | cut -d: -f1)
emergency_line=$(grep -n "Use Emergency Handoff only" "$SKILL_FILE" | head -n1 | cut -d: -f1)

if [ "$rich_line" -ge "$emergency_line" ]; then
    echo "FAIL: Rich handoff must be the default before emergency fallback"
    exit 1
fi

echo "PASS"
