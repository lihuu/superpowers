#!/usr/bin/env bash
# Test: skills enforce staged single-file spec context isolation
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

echo "=== Test: staged spec workflow contracts ==="
echo ""

# brainstorming: spec producer — must have markers, validation, and acceptance format
check_contains "skills/brainstorming/SKILL.md" "<!-- IMPLEMENTATION-SPEC-BEGIN -->" \
    "new specs contain implementation begin marker"
check_contains "skills/brainstorming/SKILL.md" "<!-- ACCEPTANCE-END -->" \
    "new specs contain acceptance end marker"
check_contains "skills/brainstorming/SKILL.md" "spec-sections validate" \
    "spec writing validates marker structure mechanically"
check_contains "skills/brainstorming/SKILL.md" "Acceptance Criteria Format" \
    "spec writing defines acceptance criteria format"
check_contains "skills/brainstorming/SKILL.md" "Verification Protocol" \
    "spec writing includes verification protocol"
check_contains "skills/brainstorming/spec-document-reviewer-prompt.md" "[FULL_EXTRACTED_SPEC]" \
    "spec reviewer receives extracted full spec content"

# acceptance-review: the new independent skill — must have extraction, reviewer, repair
check_contains "skills/acceptance-review/SKILL.md" "spec-sections implementation" \
    "acceptance review extracts implementation region"
check_contains "skills/acceptance-review/SKILL.md" "spec-sections acceptance" \
    "acceptance review extracts acceptance region"
check_contains "skills/acceptance-review/SKILL.md" "Do not read the original spec file" \
    "acceptance review forbids loading the complete spec"
check_contains "skills/acceptance-review/SKILL.md" "PASS, FAIL, or NOT VERIFIED" \
    "acceptance review requires per-criterion status"
check_contains "skills/acceptance-review/SKILL.md" "Information Isolation Rules" \
    "acceptance review enforces information isolation"
check_contains "skills/acceptance-review/SKILL.md" "Rollout Acceptance" \
    "acceptance review executes rollout acceptance checks"
check_contains "skills/acceptance-review/SKILL.md" "freshly extract both complete regions" \
    "acceptance review requires fresh final extraction"
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
check_contains "skills/acceptance-review/repair-prompt.md" "[REFERENCED_IMPLEMENTATION_SPEC_SECTIONS]" \
    "repair packet contains referenced design sections"
check_contains "skills/acceptance-review/repair-prompt.md" "[RELATED_IMPLEMENTATION_DIFF]" \
    "repair packet contains related diff"

# spec-driven-implementation: fork-unique — must reference acceptance-review and extract implementation
check_contains "skills/spec-driven-implementation/SKILL.md" "spec-sections implementation" \
    "lightweight spec execution extracts implementation region"
check_contains "skills/spec-driven-implementation/SKILL.md" 'BASE_SHA=$(git rev-parse HEAD)' \
    "lightweight execution records the pre-implementation diff base"
check_contains "skills/spec-driven-implementation/SKILL.md" "acceptance-review" \
    "lightweight execution delegates to acceptance-review skill"

# fast-subagent-development: fork-unique — must reference acceptance-review for strict mode
check_contains "skills/fast-subagent-development/SKILL.md" "spec-sections implementation" \
    "fast subagent implementation uses implementation extraction"
check_contains "skills/fast-subagent-development/SKILL.md" "spec-sections acceptance" \
    "fast subagent review uses acceptance only at final review"
check_contains "skills/fast-subagent-development/SKILL.md" "Initial implementer subagents must not receive Acceptance content" \
    "fast subagent implementers exclude acceptance"
check_contains "skills/fast-subagent-development/final-reviewer-prompt.md" "Acceptance region if present" \
    "fast subagent final reviewer accepts optional acceptance"
check_contains "skills/fast-subagent-development/SKILL.md" "acceptance-review" \
    "fast subagent development references acceptance-review for strict mode"

echo ""
echo "Passed: $PASSED"
echo "Failed: $FAILED"

if [[ "$FAILED" -eq 0 ]]; then
    echo "STATUS: PASSED"
    exit 0
fi

echo "STATUS: FAILED"
exit 1
