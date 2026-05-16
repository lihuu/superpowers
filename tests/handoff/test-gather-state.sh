#!/bin/bash
# tests/handoff/test-gather-state.sh
set -e

WORKSPACE_ROOT=$(pwd)
# Use a temporary directory
TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

# Unset any git environment variables that might interfere
unset GIT_DIR
unset GIT_WORK_TREE
unset GIT_INDEX_FILE

cd "$TEST_DIR"
git init -q
git config user.email "test@example.com"
git config user.name "Test"

# Create mock state
git checkout -b feature-branch -q
echo "mock commit" > mock.txt
git add mock.txt
git commit -m "initial commit" -q --no-verify
echo "modified" >> mock.txt

# Run gather script
SCRIPT_PATH="$WORKSPACE_ROOT/skills/handoff/scripts/gather-state.sh"
cd "$TEST_DIR"
"$SCRIPT_PATH" "$TEST_DIR" > "$TEST_DIR/output.txt"

# Verify output
if ! grep -q "feature-branch" "$TEST_DIR/output.txt"; then
    echo "FAIL: Missing branch info"
    cat "$TEST_DIR/output.txt"
    exit 1
fi

if ! grep -q "mock.txt" "$TEST_DIR/output.txt"; then
    echo "FAIL: Missing modified file info"
    cat "$TEST_DIR/output.txt"
    exit 1
fi

if ! grep -q "initial commit" "$TEST_DIR/output.txt"; then
    echo "FAIL: Missing recent commit info"
    cat "$TEST_DIR/output.txt"
    exit 1
fi

EMPTY_REPO_DIR=$(mktemp -d)
git -C "$EMPTY_REPO_DIR" init -q
git -C "$EMPTY_REPO_DIR" checkout -b empty-branch -q

"$SCRIPT_PATH" "$EMPTY_REPO_DIR" > "$EMPTY_REPO_DIR/output.txt" 2> "$EMPTY_REPO_DIR/error.txt"

if grep -q "fatal:" "$EMPTY_REPO_DIR/error.txt"; then
    echo "FAIL: Empty repository emitted fatal error"
    cat "$EMPTY_REPO_DIR/error.txt"
    exit 1
fi

if ! grep -Fq -- "- **Branch:** empty-branch" "$EMPTY_REPO_DIR/output.txt"; then
    echo "FAIL: Missing empty repository branch info"
    cat "$EMPTY_REPO_DIR/output.txt"
    exit 1
fi

if ! grep -Fq -- "- **Last Commit:** none" "$EMPTY_REPO_DIR/output.txt"; then
    echo "FAIL: Missing empty repository last commit fallback"
    cat "$EMPTY_REPO_DIR/output.txt"
    exit 1
fi

echo "PASS"
