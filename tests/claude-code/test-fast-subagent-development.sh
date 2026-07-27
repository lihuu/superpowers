#!/usr/bin/env bash
# Test: fast-subagent-development skill contracts
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

check_file_exists() {
    local file="$1"
    local description="$2"

    if [[ -f "$file" ]]; then
        echo "  [PASS] $description"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] $description"
        echo "         missing file: $file"
        FAILED=$((FAILED + 1))
    fi
}

echo "=== Test: fast-subagent-development contracts ==="
echo ""

check_file_exists "skills/fast-subagent-development/SKILL.md" \
    "skill file exists"
check_file_exists "skills/fast-subagent-development/implementer-prompt.md" \
    "implementer prompt exists"
check_file_exists "skills/fast-subagent-development/final-reviewer-prompt.md" \
    "final reviewer prompt exists"
check_file_exists "skills/fast-subagent-development/repair-prompt.md" \
    "repair prompt exists"

check_contains "skills/fast-subagent-development/SKILL.md" "Auto is the default execution mode" \
    "Auto is the default"
check_contains "skills/fast-subagent-development/SKILL.md" "Parallel mode must not mean forced parallelism" \
    "parallel conflict downgrade is explicit"
check_contains "skills/fast-subagent-development/SKILL.md" "Run packets serially when independence is uncertain" \
    "unclear independence falls back to serial"
check_contains "skills/fast-subagent-development/SKILL.md" "automatically merges adjacent tasks" \
    "packetization merges adjacent implementation-chain tasks"
check_contains "skills/fast-subagent-development/SKILL.md" "Checkbox steps are TDD execution checkpoints, not subagent boundaries" \
    "checkbox steps are not dispatch boundaries"
check_contains "skills/fast-subagent-development/SKILL.md" "one final reviewer subagent by default" \
    "final review defaults to reviewer subagent"
check_contains "skills/fast-subagent-development/SKILL.md" "Do not provide the companion acceptance file to initial implementer" \
    "acceptance excluded from implementers"
check_contains "skills/fast-subagent-development/SKILL.md" 'Use `subagent-driven-development` instead' \
    "high-assurance workflow boundary is explicit"

check_contains "skills/fast-subagent-development/implementer-prompt.md" "one implementation packet" \
    "implementer receives one packet"
check_contains "skills/fast-subagent-development/implementer-prompt.md" "Checkbox steps inside the packet" \
    "implementer completes all packet steps"
check_contains "skills/fast-subagent-development/implementer-prompt.md" "not one commit per checkbox microstep" \
    "implementer avoids microstep commits"
check_contains "skills/fast-subagent-development/implementer-prompt.md" "commit SHA" \
    "implementer reports commit SHA"

check_contains "skills/fast-subagent-development/final-reviewer-prompt.md" "Design Spec" \
    "reviewer receives implementation spec"
check_contains "skills/fast-subagent-development/final-reviewer-prompt.md" "Acceptance File (If Present)" \
    "reviewer receives optional acceptance"
check_contains "skills/fast-subagent-development/final-reviewer-prompt.md" "PASS, FAIL, or NOT VERIFIED" \
    "reviewer reports acceptance statuses"

check_contains "skills/fast-subagent-development/repair-prompt.md" "repairing review findings in one packet" \
    "repair prompt uses focused repair packet"
check_contains "skills/fast-subagent-development/repair-prompt.md" "Do not broaden the repair scope" \
    "repair prompt keeps repair focused"

check_contains "skills/fast-subagent-development/SKILL.md" "acceptance-review" \
    "skill references acceptance-review for strict mode"

echo ""
echo "Passed: $PASSED"
echo "Failed: $FAILED"

if [[ "$FAILED" -eq 0 ]]; then
    echo "STATUS: PASSED"
    exit 0
fi

echo "STATUS: FAILED"
exit 1
