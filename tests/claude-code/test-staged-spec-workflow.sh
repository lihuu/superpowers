#!/usr/bin/env bash
# Test: skills enforce staged spec context isolation via separate files
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT_DIR"

PASSED=0
FAILED=0

check_contains() {
    local file="$1"
    local text="$2"
    local description="$3"

    if grep -Fqi "$text" "$file"; then
        echo "  [PASS] $description"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] $description"
        echo "         missing in $file: $text"
        FAILED=$((FAILED + 1))
    fi
}

check_excludes() {
    local file="$1"
    local text="$2"
    local description="$3"

    if grep -Fqi "$text" "$file"; then
        echo "  [FAIL] $description"
        echo "         forbidden in $file: $text"
        FAILED=$((FAILED + 1))
    else
        echo "  [PASS] $description"
        PASSED=$((PASSED + 1))
    fi
}

check_order() {
    local file="$1"
    local first="$2"
    local second="$3"
    local description="$4"
    local first_line
    local second_line

    first_line="$(grep -nF "$first" "$file" | head -1 | cut -d: -f1 || true)"
    second_line="$(grep -nF "$second" "$file" | head -1 | cut -d: -f1 || true)"

    if [[ -n "$first_line" && -n "$second_line" && "$first_line" -lt "$second_line" ]]; then
        echo "  [PASS] $description"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] $description"
        FAILED=$((FAILED + 1))
    fi
}

echo "=== Test: staged spec workflow contracts (separate files) ==="
echo ""

# brainstorming: upstream original + companion acceptance mention
check_contains "skills/brainstorming/SKILL.md" "YYYY-MM-DD-<topic>-design.md" \
    "brainstorming writes design spec"
check_contains "skills/brainstorming/SKILL.md" "acceptance-review" \
    "brainstorming mentions acceptance-review skill"
check_contains "skills/brainstorming/SKILL.md" "companion file" \
    "brainstorming describes companion acceptance file"
check_excludes "skills/brainstorming/SKILL.md" "spec-sections" \
    "brainstorming does not reference spec-sections"
check_excludes "skills/brainstorming/SKILL.md" "IMPLEMENTATION-SPEC-BEGIN" \
    "brainstorming does not use region markers"

# acceptance-review: the independent skill — must read files directly, no extraction
check_contains "skills/acceptance-review/SKILL.md" "design spec" \
    "acceptance review reads design spec"
check_contains "skills/acceptance-review/SKILL.md" "companion acceptance file" \
    "acceptance review reads companion acceptance file"
check_contains "skills/acceptance-review/SKILL.md" "PASS, FAIL, or NOT VERIFIED" \
    "acceptance review requires per-criterion status"
check_contains "skills/acceptance-review/SKILL.md" "Information Isolation Rules" \
    "acceptance review enforces information isolation"
check_contains "skills/acceptance-review/SKILL.md" "Rollout Acceptance" \
    "acceptance review executes rollout acceptance checks"
check_contains "skills/acceptance-review/SKILL.md" "Acceptance Criteria Format" \
    "acceptance review defines acceptance criteria format"
check_contains "skills/acceptance-review/SKILL.md" "Verification Protocol" \
    "acceptance review defines verification protocol"
check_excludes "skills/acceptance-review/SKILL.md" "spec-sections" \
    "acceptance review does not reference spec-sections"
check_excludes "skills/acceptance-review/SKILL.md" "IMPLEMENTATION-SPEC-BEGIN" \
    "acceptance review does not use region markers"
check_order "skills/acceptance-review/reviewer-prompt.md" "## Implementation Spec" "## Acceptance Contract" \
    "reviewer loads design before acceptance"
check_order "skills/acceptance-review/reviewer-prompt.md" "## Acceptance Contract" "## Implementation Diff" \
    "reviewer loads acceptance before diff"
check_order "skills/acceptance-review/reviewer-prompt.md" "## Implementation Diff" "## Test Results" \
    "reviewer loads diff before test results"
check_contains "skills/acceptance-review/reviewer-prompt.md" "PASS, FAIL, or NOT VERIFIED" \
    "reviewer reports status per acceptance criterion"
check_contains "skills/acceptance-review/reviewer-prompt.md" "Rollout Acceptance" \
    "reviewer executes rollout acceptance checks"

check_contains "skills/acceptance-review/repair-prompt.md" "[FAILED_ACCEPTANCE_CRITERIA]" \
    "repair packet contains only failed criteria"
check_contains "skills/acceptance-review/repair-prompt.md" "[FAILURE_EVIDENCE]" \
    "repair packet contains failure evidence"

# spec-driven-implementation: fork-unique — must reference acceptance-review, not spec-sections
check_contains "skills/spec-driven-implementation/SKILL.md" "acceptance-review" \
    "lightweight execution delegates to acceptance-review skill"
check_contains "skills/spec-driven-implementation/SKILL.md" "BASE_SHA" \
    "lightweight execution records the pre-implementation diff base"
check_excludes "skills/spec-driven-implementation/SKILL.md" "spec-sections" \
    "lightweight execution does not reference spec-sections"

# fast-subagent-development: fork-unique — must reference acceptance-review, not spec-sections
check_contains "skills/fast-subagent-development/SKILL.md" "Initial implementer subagents must not receive Acceptance content" \
    "fast subagent implementers exclude acceptance"
check_contains "skills/fast-subagent-development/final-reviewer-prompt.md" "Acceptance region if present" \
    "fast subagent final reviewer accepts optional acceptance"
check_contains "skills/fast-subagent-development/SKILL.md" "acceptance-review" \
    "fast subagent development references acceptance-review for strict mode"
check_excludes "skills/fast-subagent-development/SKILL.md" "spec-sections" \
    "fast subagent development does not reference spec-sections"

# Shared skills: must NOT reference spec-sections (they are upstream original)
check_excludes "skills/writing-plans/SKILL.md" "spec-sections" \
    "writing-plans does not reference spec-sections"
check_excludes "skills/executing-plans/SKILL.md" "spec-sections" \
    "executing-plans does not reference spec-sections"
check_excludes "skills/subagent-driven-development/SKILL.md" "spec-sections" \
    "subagent-driven-development does not reference spec-sections"
check_excludes "skills/requesting-code-review/SKILL.md" "spec-sections" \
    "requesting-code-review does not reference spec-sections"

# spec-sections script must not exist
if [[ ! -f "skills/brainstorming/spec-sections" ]]; then
    echo "  [PASS] spec-sections script removed"
    PASSED=$((PASSED + 1))
else
    echo "  [FAIL] spec-sections script still exists"
    FAILED=$((FAILED + 1))
fi

if [[ ! -f "skills/brainstorming/spec-sections.md" ]]; then
    echo "  [PASS] spec-sections.md removed"
    PASSED=$((PASSED + 1))
else
    echo "  [FAIL] spec-sections.md still exists"
    FAILED=$((FAILED + 1))
fi

echo ""
echo "Passed: $PASSED"
echo "Failed: $FAILED"

if [[ "$FAILED" -eq 0 ]]; then
    echo "STATUS: PASSED"
    exit 0
fi

echo "STATUS: FAILED"
exit 1