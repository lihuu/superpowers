#!/bin/bash
# tests/handoff/test-gather-state-error-handling.sh
set -e

WORKSPACE_ROOT=$(pwd)
# Use a temporary directory
TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

# Run gather script in a non-git directory
SCRIPT_PATH="$WORKSPACE_ROOT/skills/handoff/scripts/gather-state.sh"
cd "$TEST_DIR"

if "$SCRIPT_PATH" "$TEST_DIR" 2> "$TEST_DIR/error.txt"; then
    echo "FAIL: Script should have failed in non-git directory"
    exit 1
fi

if grep -q "is not a git repository" "$TEST_DIR/error.txt"; then
    echo "PASS: Non-git repository error handling"
else
    echo "FAIL: Wrong or missing error message"
    cat "$TEST_DIR/error.txt"
    exit 1
fi
