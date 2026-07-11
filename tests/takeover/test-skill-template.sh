#!/bin/bash
set -e

SKILL_FILE="skills/takeover/SKILL.md"

for required in \
    "Locate" \
    "Verify" \
    "Resume" \
    "Transcript Fallback" \
    "Do not read raw transcripts first" \
    "Next Immediate Action" \
    "State mismatch" \
    "State matches"; do
    if ! grep -q "$required" "$SKILL_FILE"; then
        echo "FAIL: Missing required takeover text: $required"
        exit 1
    fi
done

echo "PASS"
