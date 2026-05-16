#!/bin/bash
# tests/handoff/test-gather-state.sh
set -e

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
cd /Users/lihu/MyFiles/Workspace/research/superpowers
bash skills/handoff/scripts/gather-state.sh "$TEST_DIR" > "$TEST_DIR/output.txt"

# Verify output contains git info
if ! grep -qi "modified files" "$TEST_DIR/output.txt"; then
    echo "FAIL: Missing git info"
    cat "$TEST_DIR/output.txt"
    exit 1
fi

echo "PASS"
