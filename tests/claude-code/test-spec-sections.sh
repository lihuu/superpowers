#!/usr/bin/env bash
# Test: strict staged extraction for single-file specs
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
SPEC_SECTIONS="$ROOT_DIR/skills/brainstorming/spec-sections"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

PASSED=0
FAILED=0

pass() {
    echo "  [PASS] $1"
    PASSED=$((PASSED + 1))
}

fail() {
    echo "  [FAIL] $1"
    FAILED=$((FAILED + 1))
}

run_success() {
    local description="$1"
    shift
    if "$@" >"$TMP_DIR/stdout" 2>"$TMP_DIR/stderr"; then
        pass "$description"
    else
        fail "$description"
        sed 's/^/    stderr: /' "$TMP_DIR/stderr"
    fi
}

run_failure_without_output() {
    local description="$1"
    shift
    if "$@" >"$TMP_DIR/stdout" 2>"$TMP_DIR/stderr"; then
        fail "$description (unexpected success)"
    elif [[ -s "$TMP_DIR/stdout" ]]; then
        fail "$description (leaked output on failure)"
    else
        pass "$description"
    fi
}

assert_stdout_contains() {
    local description="$1"
    local expected="$2"
    if grep -Fq "$expected" "$TMP_DIR/stdout"; then
        pass "$description"
    else
        fail "$description"
    fi
}

assert_stdout_excludes() {
    local description="$1"
    local forbidden="$2"
    if grep -Fq "$forbidden" "$TMP_DIR/stdout"; then
        fail "$description"
    else
        pass "$description"
    fi
}

assert_stderr_contains() {
    local description="$1"
    local expected="$2"
    if grep -Fq "$expected" "$TMP_DIR/stderr"; then
        pass "$description"
    else
        fail "$description"
    fi
}

write_valid_spec() {
    local path="$1"
    local newline="${2:-lf}"
    local content='<!-- IMPLEMENTATION-SPEC-BEGIN -->
# Goal
Implementation-only requirement.
<!-- IMPLEMENTATION-SPEC-BEGIN-ish -->
<!-- IMPLEMENTATION-SPEC-END -->

<!-- ACCEPTANCE-BEGIN -->
# Completion Contract
Acceptance-only secret.
<!-- ACCEPTANCE-END -->'

    if [[ "$newline" == "crlf" ]]; then
        printf '%s\n' "$content" | sed 's/$/\r/' >"$path"
    else
        printf '%s\n' "$content" >"$path"
    fi
}

echo "=== Test: staged spec sections ==="
echo ""

VALID_SPEC="$TMP_DIR/valid.md"
write_valid_spec "$VALID_SPEC"

run_success "valid spec passes validation" "$SPEC_SECTIONS" validate "$VALID_SPEC"

run_success "implementation extraction succeeds" "$SPEC_SECTIONS" implementation "$VALID_SPEC"
assert_stdout_contains "implementation output contains design content" "Implementation-only requirement."
assert_stdout_contains "similar marker text remains ordinary content" "<!-- IMPLEMENTATION-SPEC-BEGIN-ish -->"
assert_stdout_excludes "implementation output excludes acceptance content" "Acceptance-only secret."
assert_stdout_excludes "implementation output excludes exact acceptance marker" "<!-- ACCEPTANCE-BEGIN -->"

run_success "acceptance extraction succeeds" "$SPEC_SECTIONS" acceptance "$VALID_SPEC"
assert_stdout_contains "acceptance output contains acceptance content" "Acceptance-only secret."
assert_stdout_excludes "acceptance output excludes implementation content" "Implementation-only requirement."

run_success "full extraction succeeds" "$SPEC_SECTIONS" full "$VALID_SPEC"
assert_stdout_contains "full output contains implementation content" "Implementation-only requirement."
assert_stdout_contains "full output contains acceptance content" "Acceptance-only secret."
implementation_line="$(grep -nF "Implementation-only requirement." "$TMP_DIR/stdout" | cut -d: -f1 || true)"
acceptance_line="$(grep -nF "Acceptance-only secret." "$TMP_DIR/stdout" | cut -d: -f1 || true)"
if [[ -n "$implementation_line" && -n "$acceptance_line" && "$implementation_line" -lt "$acceptance_line" ]]; then
    pass "full output preserves implementation-before-acceptance order"
else
    fail "full output preserves implementation-before-acceptance order"
fi

CRLF_SPEC="$TMP_DIR/crlf.md"
write_valid_spec "$CRLF_SPEC" crlf
run_success "CRLF spec is accepted" "$SPEC_SECTIONS" validate "$CRLF_SPEC"
run_success "CRLF implementation extraction succeeds" "$SPEC_SECTIONS" implementation "$CRLF_SPEC"
assert_stdout_excludes "CRLF extraction excludes acceptance content" "Acceptance-only secret."

MISSING_BEGIN="$TMP_DIR/missing-begin.md"
printf '%s\n' \
    "# Goal" \
    "Implementation" \
    "<!-- IMPLEMENTATION-SPEC-END -->" \
    "<!-- ACCEPTANCE-BEGIN -->" \
    "Acceptance" \
    "<!-- ACCEPTANCE-END -->" >"$MISSING_BEGIN"
run_failure_without_output "missing BEGIN fails without leaking the file" "$SPEC_SECTIONS" full "$MISSING_BEGIN"

MISSING_END="$TMP_DIR/missing-end.md"
printf '%s\n' \
    "<!-- IMPLEMENTATION-SPEC-BEGIN -->" \
    "Implementation" \
    "<!-- ACCEPTANCE-BEGIN -->" \
    "Acceptance" \
    "<!-- ACCEPTANCE-END -->" >"$MISSING_END"
run_failure_without_output "missing END fails without leaking the file" "$SPEC_SECTIONS" implementation "$MISSING_END"

DUPLICATE="$TMP_DIR/duplicate.md"
printf '%s\n' \
    "<!-- IMPLEMENTATION-SPEC-BEGIN -->" \
    "Implementation" \
    "<!-- IMPLEMENTATION-SPEC-END -->" \
    "<!-- ACCEPTANCE-BEGIN -->" \
    "Acceptance" \
    "<!-- ACCEPTANCE-END -->" \
    "<!-- ACCEPTANCE-END -->" >"$DUPLICATE"
run_failure_without_output "duplicate marker fails without output" "$SPEC_SECTIONS" acceptance "$DUPLICATE"

WRONG_ORDER="$TMP_DIR/wrong-order.md"
printf '%s\n' \
    "<!-- ACCEPTANCE-BEGIN -->" \
    "Acceptance" \
    "<!-- ACCEPTANCE-END -->" \
    "<!-- IMPLEMENTATION-SPEC-BEGIN -->" \
    "Implementation" \
    "<!-- IMPLEMENTATION-SPEC-END -->" >"$WRONG_ORDER"
run_failure_without_output "wrong region order fails without output" "$SPEC_SECTIONS" full "$WRONG_ORDER"

NESTED="$TMP_DIR/nested.md"
printf '%s\n' \
    "<!-- IMPLEMENTATION-SPEC-BEGIN -->" \
    "Implementation" \
    "<!-- ACCEPTANCE-BEGIN -->" \
    "Acceptance" \
    "<!-- ACCEPTANCE-END -->" \
    "<!-- IMPLEMENTATION-SPEC-END -->" >"$NESTED"
run_failure_without_output "nested regions fail without output" "$SPEC_SECTIONS" validate "$NESTED"

EMPTY_IMPLEMENTATION="$TMP_DIR/empty-implementation.md"
printf '%s\n' \
    "<!-- IMPLEMENTATION-SPEC-BEGIN -->" \
    "" \
    "<!-- IMPLEMENTATION-SPEC-END -->" \
    "<!-- ACCEPTANCE-BEGIN -->" \
    "Acceptance" \
    "<!-- ACCEPTANCE-END -->" >"$EMPTY_IMPLEMENTATION"
run_failure_without_output "empty implementation region fails" "$SPEC_SECTIONS" validate "$EMPTY_IMPLEMENTATION"

EMPTY_ACCEPTANCE="$TMP_DIR/empty-acceptance.md"
printf '%s\n' \
    "<!-- IMPLEMENTATION-SPEC-BEGIN -->" \
    "Implementation" \
    "<!-- IMPLEMENTATION-SPEC-END -->" \
    "<!-- ACCEPTANCE-BEGIN -->" \
    "" \
    "<!-- ACCEPTANCE-END -->" >"$EMPTY_ACCEPTANCE"
run_failure_without_output "empty acceptance region fails" "$SPEC_SECTIONS" validate "$EMPTY_ACCEPTANCE"

LEGACY="$TMP_DIR/legacy.md"
printf '%s\n' "# Legacy Spec" "Complete legacy content." >"$LEGACY"
run_failure_without_output "legacy spec is rejected by default" "$SPEC_SECTIONS" implementation "$LEGACY"
run_success "legacy full mode explicitly restores old behavior" "$SPEC_SECTIONS" --legacy full implementation "$LEGACY"
assert_stdout_contains "legacy full mode outputs complete legacy content" "Complete legacy content."
assert_stderr_contains "legacy mode logs that isolation is disabled" "isolation disabled"
run_success "legacy full command succeeds" "$SPEC_SECTIONS" --legacy full full "$LEGACY"
legacy_count="$(grep -Fc "Complete legacy content." "$TMP_DIR/stdout" || true)"
if [[ "$legacy_count" -eq 1 ]]; then
    pass "legacy full command outputs the old spec exactly once"
else
    fail "legacy full command outputs the old spec exactly once"
fi

PARTIAL_LEGACY="$TMP_DIR/partial-legacy.md"
printf '%s\n' \
    "# Partial Spec" \
    "<!-- IMPLEMENTATION-SPEC-BEGIN -->" \
    "Content without remaining markers" >"$PARTIAL_LEGACY"
run_failure_without_output "legacy mode does not bypass partial marker errors" "$SPEC_SECTIONS" --legacy full full "$PARTIAL_LEGACY"

echo ""
echo "Passed: $PASSED"
echo "Failed: $FAILED"

if [[ "$FAILED" -eq 0 ]]; then
    echo "STATUS: PASSED"
    exit 0
fi

echo "STATUS: FAILED"
exit 1
