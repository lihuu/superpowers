#!/bin/bash
# tests/handoff/test-skill-template.sh
set -e

SKILL_FILE="skills/handoff/SKILL.md"

for required in \
    "## Handoff Template" \
    "## Current Objective" \
    "## Work Completed" \
    "## Pending Tasks" \
    "Next Immediate Action" \
    "## Modified Files" \
    "## Mental State & Blockers"; do
    if ! grep -q "$required" "$SKILL_FILE"; then
        echo "FAIL: Missing required template text: $required"
        exit 1
    fi
done

echo "PASS"
