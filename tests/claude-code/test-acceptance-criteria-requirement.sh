#!/usr/bin/env bash
# Test: Acceptance criteria format and verification protocol requirements
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT_DIR"

FAILED=0

echo "=== Test: Acceptance criteria requirement ==="
echo ""

check_file() {
    local file="$1"
    local pattern="$2"
    local description="$3"

    echo "Checking: $description"
    if grep -Fqi "$pattern" "$file"; then
        echo "  [PASS] $file"
    else
        echo "  [FAIL] $file missing pattern: $pattern"
        FAILED=$((FAILED + 1))
    fi
    echo ""
}

# Acceptance Criteria Format and Verification Protocol now live in acceptance-review/SKILL.md
check_file \
    "skills/acceptance-review/SKILL.md" \
    "## Acceptance Criteria Format" \
    "acceptance-review defines a structured acceptance criteria format"

for field in \
    "**Requirement:**" \
    "**Verification Steps:**" \
    "**Pass Conditions:**" \
    "**Fail Conditions:**" \
    "**Required Evidence:**"
do
    check_file \
        "skills/acceptance-review/SKILL.md" \
        "$field" \
        "acceptance criteria include $field"
done

check_file \
    "skills/acceptance-review/SKILL.md" \
    "one criterion verifies one semantic requirement" \
    "acceptance criteria are atomic"

check_file \
    "skills/acceptance-review/SKILL.md" \
    "inline the requirements that determine the result" \
    "acceptance criteria do not rely on implicit references"

check_file \
    "skills/acceptance-review/SKILL.md" \
    "A field, function, test, or stage name merely existing is not sufficient evidence" \
    "acceptance criteria forbid existence-only shortcuts"

check_file \
    "skills/acceptance-review/SKILL.md" \
    "A passing full test suite does not replace semantic source or runtime verification" \
    "acceptance criteria forbid test-suite-only semantic approval"

check_file \
    "skills/acceptance-review/SKILL.md" \
    "## Verification Protocol" \
    "acceptance-review requires a verification protocol"

check_file \
    "skills/acceptance-review/SKILL.md" \
    "PASS, FAIL, or NOT VERIFIED" \
    "verification reports a status for every criterion"

check_file \
    "skills/acceptance-review/SKILL.md" \
    "Missing required evidence means the criterion is NOT VERIFIED" \
    "missing evidence cannot pass"

check_file \
    "skills/acceptance-review/SKILL.md" \
    "Only when every criterion and every Rollout Acceptance check is PASS may the task and automated loop stop" \
    "the loop stops only after all criteria and rollout checks pass"

check_file \
    "skills/acceptance-review/reviewer-prompt.md" \
    "verification steps, pass conditions, fail conditions, and required evidence" \
    "acceptance review preserves each criterion's verification contract"

check_file \
    "skills/acceptance-review/SKILL.md" \
    "Information Isolation" \
    "acceptance-review addresses acceptance content isolation"

if [ "$FAILED" -eq 0 ]; then
    echo "STATUS: PASSED"
    exit 0
else
    echo "STATUS: FAILED ($FAILED checks failed)"
    exit 1
fi