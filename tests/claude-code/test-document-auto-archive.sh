#!/bin/bash
# tests/claude-code/test-document-auto-archive.sh
set -e

TEST_DIR="temp-test-archive"
rm -rf $TEST_DIR
mkdir -p $TEST_DIR/docs/superpowers/specs
mkdir -p $TEST_DIR/docs/superpowers/plans

# Create mock files
echo "Spec with link to [Plan](../plans/2026-05-16-test-feat.md)" > $TEST_DIR/docs/superpowers/specs/2026-05-16-test-feat-design.md
echo "Plan content" > $TEST_DIR/docs/superpowers/plans/2026-05-16-test-feat.md

# Run archive script (simulating feature name 'test-feat')
bash skills/finishing-a-development-branch/archive-docs.sh $TEST_DIR "test-feat" "completed"

# Verify files moved
if [ ! -f "$TEST_DIR/docs/superpowers/specs/archive/2026-05-16-test-feat-design.md" ]; then
    echo "FAIL: Spec not archived"
    exit 1
fi

# Verify link updated
if ! grep -q "\[Plan\](2026-05-16-test-feat.md)" "$TEST_DIR/docs/superpowers/specs/archive/2026-05-16-test-feat-design.md"; then
    echo "FAIL: Link not updated correctly"
    exit 1
fi

echo "PASS"
