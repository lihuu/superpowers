#!/bin/bash
set -e

SKILL_FILE="skills/handoff/SKILL.md"

if ! grep -q "takeover skill" "$SKILL_FILE"; then
    echo "FAIL: Handoff resumption instruction does not mention takeover skill"
    exit 1
fi

if ! grep -q "<exact-handoff-file>" "$SKILL_FILE"; then
    echo "FAIL: Handoff resumption instruction does not prefer exact handoff file path"
    exit 1
fi

echo "PASS"
