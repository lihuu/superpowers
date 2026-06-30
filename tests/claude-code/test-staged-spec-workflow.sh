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

check_contains "skills/brainstorming/SKILL.md" "<!-- IMPLEMENTATION-SPEC-BEGIN -->" \
    "new specs contain implementation begin marker"
check_contains "skills/brainstorming/SKILL.md" "<!-- ACCEPTANCE-END -->" \
    "new specs contain acceptance end marker"
check_contains "skills/brainstorming/SKILL.md" "spec-sections validate" \
    "spec writing validates marker structure mechanically"
check_contains "skills/brainstorming/spec-document-reviewer-prompt.md" "[FULL_EXTRACTED_SPEC]" \
    "spec reviewer receives extracted full spec content"

check_contains "skills/writing-plans/SKILL.md" "spec-sections implementation" \
    "plan generation extracts implementation region"
check_contains "skills/writing-plans/SKILL.md" "Acceptance content MUST NOT enter the planning agent's context" \
    "plan generation excludes acceptance context"
check_contains "skills/writing-plans/plan-document-reviewer-prompt.md" "[IMPLEMENTATION_SPEC_CONTENT]" \
    "plan reviewer receives implementation content"
check_excludes "skills/writing-plans/plan-document-reviewer-prompt.md" "[SPEC_FILE_PATH]" \
    "plan reviewer is not told to read the original spec"

check_contains "skills/executing-plans/SKILL.md" "spec-sections implementation" \
    "inline plan execution extracts implementation region"
check_contains "skills/executing-plans/SKILL.md" "Do not read the original spec file" \
    "inline execution forbids loading the complete spec"
check_contains "skills/executing-plans/SKILL.md" 'BASE_SHA=$(git rev-parse HEAD)' \
    "inline execution records the pre-implementation diff base"
check_contains "skills/executing-plans/SKILL.md" "spec-sections acceptance" \
    "inline execution extracts acceptance only after implementation"
check_contains "skills/executing-plans/SKILL.md" "rerun every Acceptance Criterion" \
    "inline execution performs fresh final acceptance"
check_contains "skills/spec-driven-implementation/SKILL.md" "spec-sections implementation" \
    "lightweight spec execution extracts implementation region"
check_contains "skills/spec-driven-implementation/SKILL.md" 'BASE_SHA=$(git rev-parse HEAD)' \
    "lightweight execution records the pre-implementation diff base"
check_contains "skills/spec-driven-implementation/SKILL.md" "spec-sections acceptance" \
    "lightweight execution extracts acceptance only for review"
check_contains "skills/spec-driven-implementation/SKILL.md" "rerun every Acceptance Criterion" \
    "lightweight execution performs final full acceptance"

check_contains "skills/subagent-driven-development/SKILL.md" "spec-sections implementation" \
    "subagent implementation uses implementation extraction"
check_contains "skills/subagent-driven-development/SKILL.md" 'BASE_SHA=$(git rev-parse HEAD)' \
    "subagent workflow records the pre-implementation diff base"
check_contains "skills/subagent-driven-development/implementer-prompt.md" "[IMPLEMENTATION_SPEC_CONTENT]" \
    "implementer prompt accepts implementation-only content"
check_contains "skills/subagent-driven-development/implementer-prompt.md" "Acceptance content must not be provided" \
    "implementer prompt explicitly rejects acceptance context"
check_contains "skills/subagent-driven-development/SKILL.md" '### Task N' \
    "subagent execution dispatches plan task sections"
check_contains "skills/subagent-driven-development/SKILL.md" "Checkbox steps are TDD execution checkpoints, not subagent boundaries" \
    "subagent execution does not dispatch per checkbox step"
check_contains "skills/subagent-driven-development/implementer-prompt.md" "complete all of them before reporting DONE" \
    "implementer completes all checkbox steps inside a task"

check_contains "skills/fast-subagent-development/SKILL.md" "spec-sections implementation" \
    "fast subagent implementation uses implementation extraction"
check_contains "skills/fast-subagent-development/SKILL.md" "spec-sections acceptance" \
    "fast subagent review uses acceptance only at final review"
check_contains "skills/fast-subagent-development/SKILL.md" "Initial implementer subagents must not receive Acceptance content" \
    "fast subagent implementers exclude acceptance"
check_contains "skills/fast-subagent-development/final-reviewer-prompt.md" "Acceptance region if present" \
    "fast subagent final reviewer accepts optional acceptance"

check_contains "skills/requesting-code-review/SKILL.md" "spec-sections acceptance" \
    "independent review extracts acceptance region"
check_order "skills/requesting-code-review/code-reviewer.md" "## Implementation Spec" "## Acceptance Contract" \
    "reviewer loads design before acceptance"
check_order "skills/requesting-code-review/code-reviewer.md" "## Acceptance Contract" "## Implementation Diff" \
    "reviewer loads acceptance before diff"
check_order "skills/requesting-code-review/code-reviewer.md" "## Implementation Diff" "## Test Results" \
    "reviewer loads diff before test results"
check_order "skills/requesting-code-review/code-reviewer.md" "## Test Results" "## Implementer Summary" \
    "reviewer sees implementer claims only after required evidence inputs"
check_contains "skills/requesting-code-review/code-reviewer.md" "PASS, FAIL, or NOT VERIFIED" \
    "reviewer reports status per acceptance criterion"
check_contains "skills/requesting-code-review/code-reviewer.md" "Rollout Acceptance" \
    "reviewer executes rollout acceptance checks"

check_contains "skills/subagent-driven-development/repair-prompt.md" "[FAILED_ACCEPTANCE_CRITERIA]" \
    "repair packet contains only failed criteria"
check_contains "skills/subagent-driven-development/repair-prompt.md" "[FAILURE_EVIDENCE]" \
    "repair packet contains failure evidence"
check_contains "skills/subagent-driven-development/repair-prompt.md" "[REFERENCED_IMPLEMENTATION_SPEC_SECTIONS]" \
    "repair packet contains referenced design sections"
check_contains "skills/subagent-driven-development/repair-prompt.md" "[RELATED_IMPLEMENTATION_DIFF]" \
    "repair packet contains related diff"
check_contains "skills/subagent-driven-development/SKILL.md" "Previously passed criteria remain closed" \
    "repair loop does not reopen passed criteria"
check_contains "skills/subagent-driven-development/SKILL.md" "rerun every Acceptance Criterion" \
    "final acceptance rechecks all criteria"
check_contains "skills/subagent-driven-development/SKILL.md" "every Rollout Acceptance check" \
    "final acceptance rechecks rollout conditions"

echo ""
echo "Passed: $PASSED"
echo "Failed: $FAILED"

if [[ "$FAILED" -eq 0 ]]; then
    echo "STATUS: PASSED"
    exit 0
fi

echo "STATUS: FAILED"
exit 1
