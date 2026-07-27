#!/usr/bin/env bash
# Test: Specs require explicit acceptance criteria
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

check_file \
    "skills/brainstorming/SKILL.md" \
    "### Acceptance Criteria Format" \
    "brainstorming defines a structured acceptance criteria format"

for field in \
    "**Requirement:**" \
    "**Verification Steps:**" \
    "**Pass Conditions:**" \
    "**Fail Conditions:**" \
    "**Required Evidence:**"
do
    check_file \
        "skills/brainstorming/SKILL.md" \
        "$field" \
        "acceptance criteria include $field"
done

check_file \
    "skills/brainstorming/SKILL.md" \
    "one criterion verifies one semantic requirement" \
    "acceptance criteria are atomic"

check_file \
    "skills/brainstorming/SKILL.md" \
    "inline the requirements that determine the result" \
    "acceptance criteria do not rely on implicit references"

check_file \
    "skills/brainstorming/SKILL.md" \
    "A field, function, test, or stage name merely existing is not sufficient evidence" \
    "acceptance criteria forbid existence-only shortcuts"

check_file \
    "skills/brainstorming/SKILL.md" \
    "A passing full test suite does not replace semantic source or runtime verification" \
    "acceptance criteria forbid test-suite-only semantic approval"

check_file \
    "skills/brainstorming/SKILL.md" \
    "## Verification Protocol" \
    "brainstorming requires a verification protocol"

check_file \
    "skills/brainstorming/SKILL.md" \
    "Keep Acceptance Criteria and the Verification Protocol in the same spec" \
    "acceptance rules stay with the spec by default"

check_file \
    "skills/brainstorming/SKILL.md" \
    "PASS, FAIL, or NOT VERIFIED" \
    "verification reports a status for every criterion"

check_file \
    "skills/brainstorming/SKILL.md" \
    "Missing required evidence means the criterion is NOT VERIFIED" \
    "missing evidence cannot pass"

check_file \
    "skills/brainstorming/SKILL.md" \
    "Only when every criterion and every Rollout Acceptance check is PASS may the task and automated loop stop" \
    "the loop stops only after all criteria and rollout checks pass"

check_file \
    "skills/brainstorming/spec-document-reviewer-prompt.md" \
    "Requirement, Verification Steps, Pass Conditions, Fail Conditions, and Required Evidence" \
    "spec reviewer checks the complete acceptance criteria structure"

check_file \
    "skills/brainstorming/spec-document-reviewer-prompt.md" \
    "existence checks or a passing test suite" \
    "spec reviewer rejects shortcut-verifiable criteria"

check_file \
    "skills/brainstorming/spec-document-reviewer-prompt.md" \
    "Verification Protocol" \
    "spec reviewer checks the verification protocol"

check_file \
    "skills/acceptance-review/reviewer-prompt.md" \
    "verification steps, pass conditions, fail conditions, and required evidence" \
    "acceptance review preserves each criterion's verification contract"

check_file \
    "skills/acceptance-review/SKILL.md" \
    "Acceptance content" \
    "acceptance-review addresses acceptance content isolation"

if [ "$FAILED" -eq 0 ]; then
    echo "STATUS: PASSED"
    exit 0
else
    echo "STATUS: FAILED ($FAILED checks failed)"
    exit 1
fi
