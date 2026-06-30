# Fast Subagent Development Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a new `fast-subagent-development` workflow skill that uses implementer-only packets plus a final reviewer subagent for lower-overhead plan execution.

**Architecture:** Add a new standalone skill directory with one `SKILL.md` and three prompt templates: implementer, final reviewer, and repair. Add fast textual contract tests that verify the new workflow rules without running expensive end-to-end subagent sessions.

**Tech Stack:** Markdown skills, bash contract tests, existing `spec-sections` staged spec workflow.

**Spec:** `docs/superpowers/specs/2026-06-30-fast-subagent-development-design.md`

**Spec Input Mode:** staged implementation extraction

---

### Task 1: Add Fast Subagent Contract Tests

**Files:**
- Create: `tests/claude-code/test-fast-subagent-development.sh`
- Modify: `tests/claude-code/run-skill-tests.sh`

- [ ] **Step 1: Write the failing contract test**

Create `tests/claude-code/test-fast-subagent-development.sh` with this content:

```bash
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
check_contains "skills/fast-subagent-development/SKILL.md" "Initial implementer subagents must not receive Acceptance content" \
    "acceptance excluded from implementers"
check_contains "skills/fast-subagent-development/SKILL.md" "Use `subagent-driven-development` instead" \
    "high-assurance workflow boundary is explicit"

check_contains "skills/fast-subagent-development/implementer-prompt.md" "exactly one implementation packet" \
    "implementer receives one packet"
check_contains "skills/fast-subagent-development/implementer-prompt.md" "complete every checkbox step inside the packet" \
    "implementer completes all packet steps"
check_contains "skills/fast-subagent-development/implementer-prompt.md" "Do not create one commit per checkbox microstep" \
    "implementer avoids microstep commits"
check_contains "skills/fast-subagent-development/implementer-prompt.md" "commit SHA" \
    "implementer reports commit SHA"

check_contains "skills/fast-subagent-development/final-reviewer-prompt.md" "Implementation Spec" \
    "reviewer receives implementation spec"
check_contains "skills/fast-subagent-development/final-reviewer-prompt.md" "Acceptance region if present" \
    "reviewer receives optional acceptance"
check_contains "skills/fast-subagent-development/final-reviewer-prompt.md" "PASS, FAIL, or NOT VERIFIED" \
    "reviewer reports acceptance statuses"

check_contains "skills/fast-subagent-development/repair-prompt.md" "one repair packet" \
    "repair prompt uses focused repair packet"
check_contains "skills/fast-subagent-development/repair-prompt.md" "Do not broaden the repair scope" \
    "repair prompt keeps repair focused"

echo ""
echo "Passed: $PASSED"
echo "Failed: $FAILED"

if [[ "$FAILED" -eq 0 ]]; then
    echo "STATUS: PASSED"
    exit 0
fi

echo "STATUS: FAILED"
exit 1
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
bash tests/claude-code/test-fast-subagent-development.sh
```

Expected: FAIL because `skills/fast-subagent-development/` does not exist yet.

- [ ] **Step 3: Add the test to the fast runner**

Modify `tests/claude-code/run-skill-tests.sh`.

In the help text under `Tests:`, add this line:

```bash
            echo "  test-fast-subagent-development.sh       Verify fast subagent workflow contracts"
```

In the `tests=(` array, add this entry before `test-subagent-driven-development.sh`:

```bash
    "test-fast-subagent-development.sh"
```

- [ ] **Step 4: Verify shell syntax**

Run:

```bash
bash -n tests/claude-code/test-fast-subagent-development.sh
bash -n tests/claude-code/run-skill-tests.sh
```

Expected: both commands exit 0.

- [ ] **Step 5: Commit the contract test**

Run:

```bash
git add tests/claude-code/test-fast-subagent-development.sh tests/claude-code/run-skill-tests.sh
git commit -m "test: add fast subagent workflow contracts"
```

Expected: commit succeeds. If the working tree contains unrelated existing changes, stage only the files listed above.

### Task 2: Add Fast Subagent Skill Document

**Files:**
- Create: `skills/fast-subagent-development/SKILL.md`

- [ ] **Step 1: Re-run the failing contract test**

Run:

```bash
bash tests/claude-code/test-fast-subagent-development.sh
```

Expected: FAIL because the skill and prompt files are not present.

- [ ] **Step 2: Create the skill directory and SKILL.md**

Create `skills/fast-subagent-development/SKILL.md` with this content:

````markdown
---
name: fast-subagent-development
description: Use when executing an existing implementation plan quickly with subagent help and final review, without high-assurance review after every task
---

# Fast Subagent Development

Execute an existing implementation plan with implementer subagents first, then one final review. This is the fast path for ordinary planned development.

**Core principle:** implementer-only packets + consolidated final review = subagent isolation without per-task review overhead.

Use `subagent-driven-development` instead for strict mode, high confidence, PR-ready review gates, high-risk changes, security-sensitive work, migration-heavy work, or review after every task.

## When to Use

Use this skill when:
- You already have an implementation plan
- The work benefits from subagent isolation
- The plan is clear enough that per-task review gates are unnecessary
- You want faster throughput than `subagent-driven-development`

Do not use this skill when:
- There is no implementation plan
- The work is exploratory or ambiguous
- The change is security-sensitive, migration-heavy, or release-critical
- Your human partner asks for strict, PR-ready, high confidence, or per-task review

## Stage Context Setup

Read the plan once at the start. If the plan header references a single-file spec, extract only the Implementation Spec:

```bash
SPEC_SECTIONS="<brainstorming-skill-directory>/spec-sections"
LEGACY_POLICY="${SUPERPOWERS_SPEC_LEGACY_POLICY:-reject}"
"$SPEC_SECTIONS" --legacy "$LEGACY_POLICY" implementation "$SPEC_PATH" > /tmp/implementation-spec.md
BASE_SHA=$(git rev-parse HEAD)
```

Do not read the original spec. Do not provide Acceptance content to initial implementer subagents.

Initial implementer subagents receive:
- Complete implementation packet text
- Relevant extracted Implementation Spec sections
- Relevant architectural/context notes
- File ownership and expected test commands

Initial implementer subagents must not receive Acceptance content.

## Packetization

Convert plan tasks into implementation packets before dispatching subagents.

A packet may contain one or more adjacent plan tasks. Checkbox steps are TDD execution checkpoints, not subagent boundaries.

The controller automatically merges adjacent tasks when they are part of the same implementation chain:
- Setup plus implementation
- Helper plus wiring
- Tests plus the behavior they verify
- Documentation for the same behavior
- Tightly dependent tasks that modify the same files or test surface

Do not merge tasks when they are independently implementable or risky to combine:
- Different subsystems
- Different risk domains such as authentication, security, persistence, migrations, or release automation
- Tasks that can be independently verified and reverted
- Tasks whose combined context would be too large for a focused implementer

Packetization is automatic. Do not ask for confirmation for every grouping decision. Summarize the packet list before execution so progress is understandable.

## Execution Mode

Auto is the default execution mode. Do not ask the user to choose an execution mode unless their instruction is ambiguous in a way that affects safety.

Auto mode uses conservative parallelism:
- Run packets in parallel only when they are clearly independent
- Run packets serially when independence is uncertain
- Run packets serially when they may edit the same file, shared configuration, shared tests, lockfiles, dependency manifests, generated artifacts, migrations, or shared helpers
- Run security-sensitive, authentication-sensitive, persistence-sensitive, migration-sensitive, and release-sensitive packets serially

User instructions override the default:
- If the user explicitly asks for serial execution, run all packets serially
- If the user explicitly asks for parallel execution, parallelize only packets that remain clearly non-conflicting; conflict risk still downgrades those packets to serial execution

Parallel mode must not mean forced parallelism.

## Implementer Subagents

Each implementer subagent receives exactly one implementation packet.

Use `./implementer-prompt.md`.

The implementer must:
1. Follow TDD checkpoints contained in the packet
2. Implement only the packet scope
3. Run relevant tests
4. Commit the packet as one commit
5. Report status, changed files, commit SHA, commands run, and concerns

Implementers must not create one commit per checkbox microstep. Commit messages describe the packet outcome.

Implementer statuses:
- **DONE:** packet implemented and committed
- **DONE_WITH_CONCERNS:** packet committed but the implementer has doubts or notable risks
- **NEEDS_CONTEXT:** missing information prevents safe implementation
- **BLOCKED:** implementation cannot proceed without changing the plan, packet boundary, model capability, or user decision

Handle `NEEDS_CONTEXT` and `BLOCKED` before continuing dependent work.

## Final Review

After all implementation packets are complete, dispatch one final reviewer subagent by default.

Use `./final-reviewer-prompt.md`.

The final reviewer receives:
1. Implementation Spec
2. Acceptance region if present
3. Complete implementation diff from `BASE_SHA` to `HEAD_SHA`
4. Packet summary with commit SHAs
5. Relevant test results
6. Implementer concerns

The final reviewer checks:
- Spec alignment
- Code quality
- Integration between packets
- Test quality and coverage
- Missing or extra behavior
- Implementation concerns raised by implementers

If Acceptance content exists, the reviewer performs a lightweight Acceptance check:
- Report PASS, FAIL, or NOT VERIFIED for each Acceptance Criterion and Rollout Acceptance check
- Include concrete evidence for each status
- Do not require the full high-assurance acceptance repair loop unless the user asked for strict, PR-ready, high confidence, or full acceptance mode

If the user explicitly says the main agent should review without a reviewer subagent, the controller may perform the final review itself.

## Repair Loop

If final review finds issues, dispatch repair work.

Default repair behavior:
- Dispatch one repair subagent with review findings, relevant Implementation Spec sections, relevant Acceptance criteria when applicable, related diff, and failing evidence
- The repair subagent fixes root causes, runs targeted tests, commits the repair, and reports changed files, commands, results, and evidence

Split repair behavior:
- If review findings span independent areas, dispatch multiple focused repair subagents
- Do not run focused repair subagents in parallel when they may touch the same files, tests, configuration, or shared helpers

After repair:
- Re-review affected areas
- Re-run failed or unverified Acceptance checks when Acceptance was part of final review
- Run a second final review when repair touched broad architecture, multiple packets, shared interfaces, or previously passing acceptance areas

## Error Handling

If spec extraction fails, stop and report the extraction error. Do not fall back to reading the complete spec.

If packetization is ambiguous, choose the safer execution boundary:
- Smaller packet instead of oversized packet
- Serial execution instead of parallel execution
- User escalation when ambiguity changes scope or risk

If an implementer commits unintended scope or edits unrelated files, stop dependent execution, review the diff, and either dispatch repair/revert work or ask whether the scope change should be kept.

If parallel packets conflict, stop parallel continuation for the affected packets and resolve them serially. Do not ask implementers to race on the same files.

If final review produces unclear findings, ask the reviewer for clarification or verify the finding before dispatching repair.

## Red Flags

Never:
- Dispatch one implementer per checkbox microstep
- Provide Acceptance content to initial implementers
- Force parallelism when files or tests may conflict
- Skip final review because implementers reported DONE
- Let repair broaden beyond review findings
- Use this skill for strict high-risk work that belongs in `subagent-driven-development`
````

- [ ] **Step 3: Run the contract test to verify remaining failures**

Run:

```bash
bash tests/claude-code/test-fast-subagent-development.sh
```

Expected: FAIL because prompt files are not created yet. Checks against `SKILL.md` should pass.

- [ ] **Step 4: Commit the skill document**

Run:

```bash
git add skills/fast-subagent-development/SKILL.md
git commit -m "docs: add fast subagent development skill"
```

Expected: commit succeeds. If unrelated files are modified, stage only the file listed above.

### Task 3: Add Implementer, Final Reviewer, and Repair Prompts

**Files:**
- Create: `skills/fast-subagent-development/implementer-prompt.md`
- Create: `skills/fast-subagent-development/final-reviewer-prompt.md`
- Create: `skills/fast-subagent-development/repair-prompt.md`

- [ ] **Step 1: Run the contract test to verify prompt failures**

Run:

```bash
bash tests/claude-code/test-fast-subagent-development.sh
```

Expected: FAIL because prompt files are missing.

- [ ] **Step 2: Create implementer prompt**

Create `skills/fast-subagent-development/implementer-prompt.md` with this content:

````markdown
# Fast Subagent Implementer Prompt Template

Use this template when dispatching an implementer subagent for one implementation packet.

```
Task tool (general-purpose):
  description: "Implement packet: [packet name]"
  prompt: |
    You are implementing exactly one implementation packet.

    ## Implementation Spec Context

    [IMPLEMENTATION_SPEC_CONTENT]

    This content was mechanically extracted from the Implementation Spec region.
    Acceptance content must not be provided to an initial implementation agent.

    ## Implementation Packet

    [FULL PACKET TEXT]

    This is the complete implementation packet. Complete every checkbox step
    inside the packet before reporting DONE. Checkbox steps are TDD execution
    checkpoints, not separate dispatch boundaries.

    ## Context

    [Relevant architecture, dependencies, file ownership, and test commands]

    ## Your Job

    Once requirements are clear:
    1. Follow the packet's TDD sequence
    2. Implement only this packet's scope
    3. Run relevant tests
    4. Commit this packet as one commit
    5. Report status, changed files, commit SHA, commands run, and concerns

    Do not create one commit per checkbox microstep. The commit message should
    describe the packet outcome.

    ## Ask Before Implementing If

    - Requirements conflict
    - The packet boundary is too large or too small
    - Required context is missing
    - The implementation needs files outside the packet's stated scope
    - You see a risk that should change execution order

    ## Status Values

    - DONE: packet implemented, tested, and committed
    - DONE_WITH_CONCERNS: packet committed but concerns remain
    - NEEDS_CONTEXT: missing information prevents safe implementation
    - BLOCKED: cannot proceed without changing plan, packet boundary, model capability, or user decision

    ## Report Format

    - Status: DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED
    - Commit: [commit SHA or "none"]
    - Files changed
    - Commands run and results
    - What was implemented
    - Concerns or blockers
```
````

- [ ] **Step 3: Create final reviewer prompt**

Create `skills/fast-subagent-development/final-reviewer-prompt.md` with this content:

````markdown
# Fast Subagent Final Reviewer Prompt Template

Use this template after all implementation packets are complete.

```
Task tool (general-purpose):
  description: "Final review fast subagent implementation"
  prompt: |
    You are the final reviewer for a fast subagent development run.

    ## Implementation Spec

    [IMPLEMENTATION_SPEC_CONTENT]

    ## Acceptance Region If Present

    [ACCEPTANCE_REGION_OR_NONE]

    Include Acceptance region if present. If none exists, say "No Acceptance
    region provided" and review spec alignment and code quality only.

    ## Implementation Diff

    Base: [BASE_SHA]
    Head: [HEAD_SHA]

    Review:

    ```bash
    git diff --stat [BASE_SHA]..[HEAD_SHA]
    git diff [BASE_SHA]..[HEAD_SHA]
    ```

    ## Packet Summary

    [PACKET_SUMMARY_WITH_COMMIT_SHAS]

    ## Test Results

    [TEST_COMMANDS_AND_RESULTS]

    ## Implementer Concerns

    [IMPLEMENTER_CONCERNS_OR_NONE]

    ## What To Check

    - Spec alignment
    - Code quality
    - Integration between packets
    - Test quality and coverage
    - Missing or extra behavior
    - Implementer concerns

    If Acceptance content exists, report PASS, FAIL, or NOT VERIFIED for each
    Acceptance Criterion and Rollout Acceptance check. Include concrete evidence
    for every status. Missing evidence means NOT VERIFIED.

    This is a lightweight final review. Do not require the full high-assurance
    acceptance repair loop unless the controller says strict, PR-ready, high
    confidence, or full acceptance mode is active.

    ## Output Format

    ### Summary
    [Brief technical summary]

    ### Issues

    #### Critical
    [Must fix before completion]

    #### Important
    [Should fix before completion]

    #### Minor
    [Optional improvements]

    ### Acceptance Status
    [PASS / FAIL / NOT VERIFIED per criterion, or "No Acceptance region provided"]

    ### Assessment
    Ready to finish: Yes | No | With repairs
    Reasoning: [1-2 sentence technical assessment]
```
````

- [ ] **Step 4: Create repair prompt**

Create `skills/fast-subagent-development/repair-prompt.md` with this content:

````markdown
# Fast Subagent Repair Prompt Template

Use this template after final review finds issues.

```
Task tool (general-purpose):
  description: "Repair fast subagent review findings"
  prompt: |
    You are repairing one repair packet from final review.

    ## Review Findings To Fix

    [REVIEW_FINDINGS]

    ## Failure Evidence

    [FAILURE_EVIDENCE]

    ## Relevant Implementation Spec Sections

    [IMPLEMENTATION_SPEC_SECTIONS]

    ## Relevant Acceptance Criteria

    [ACCEPTANCE_CRITERIA_OR_NONE]

    ## Related Diff

    [RELATED_DIFF]

    ## Rules

    - Fix the root cause demonstrated by the review finding and evidence
    - Do not broaden the repair scope
    - Do not modify unrelated behavior
    - Run targeted tests and relevant regression tests
    - Commit the repair as one commit
    - Report changed files, commit SHA, commands, results, and evidence

    ## Report Format

    - Status: DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED
    - Commit: [commit SHA or "none"]
    - Findings fixed
    - Files changed
    - Commands run and results
    - Evidence for re-review
    - Remaining concerns
```
````

- [ ] **Step 5: Run the contract test to verify it passes**

Run:

```bash
bash tests/claude-code/test-fast-subagent-development.sh
```

Expected: PASS with all checks passing.

- [ ] **Step 6: Commit prompt templates**

Run:

```bash
git add skills/fast-subagent-development/implementer-prompt.md skills/fast-subagent-development/final-reviewer-prompt.md skills/fast-subagent-development/repair-prompt.md
git commit -m "docs: add fast subagent prompt templates"
```

Expected: commit succeeds. If unrelated files are modified, stage only the files listed above.

### Task 4: Verify Staged Spec Integration and Final Contracts

**Files:**
- Modify: `tests/claude-code/test-staged-spec-workflow.sh`
- Test: `docs/superpowers/specs/2026-06-30-fast-subagent-development-design.md`

- [ ] **Step 1: Add staged workflow checks for the new skill**

Modify `tests/claude-code/test-staged-spec-workflow.sh` near the existing subagent workflow checks and add these checks:

```bash
check_contains "skills/fast-subagent-development/SKILL.md" "spec-sections implementation" \
    "fast subagent implementation uses implementation extraction"
check_contains "skills/fast-subagent-development/SKILL.md" "spec-sections acceptance" \
    "fast subagent review uses acceptance only at final review"
check_contains "skills/fast-subagent-development/SKILL.md" "Initial implementer subagents must not receive Acceptance content" \
    "fast subagent implementers exclude acceptance"
check_contains "skills/fast-subagent-development/final-reviewer-prompt.md" "Acceptance region if present" \
    "fast subagent final reviewer accepts optional acceptance"
```

- [ ] **Step 2: Run the new contract test**

Run:

```bash
bash tests/claude-code/test-fast-subagent-development.sh
```

Expected: PASS.

- [ ] **Step 3: Run staged workflow test**

Run:

```bash
bash tests/claude-code/test-staged-spec-workflow.sh
```

Expected: PASS.

- [ ] **Step 4: Validate the design spec**

Run:

```bash
skills/brainstorming/spec-sections validate docs/superpowers/specs/2026-06-30-fast-subagent-development-design.md
```

Expected: exit 0 and output includes:

```text
spec-sections: staged isolation enabled
```

- [ ] **Step 5: Commit final test integration**

Run:

```bash
git add tests/claude-code/test-staged-spec-workflow.sh
git commit -m "test: cover fast subagent staged spec contracts"
```

Expected: commit succeeds. If unrelated files are modified, stage only the file listed above.

## Self-Review Checklist

- Spec coverage: The plan covers the new skill, packetization, Auto execution, implementer commits, final reviewer, Acceptance handling, repair behavior, and fast tests.
- Context isolation: The plan was produced from the extracted Implementation Spec only.
- Placeholder scan: No forbidden placeholder markers or unspecified implementation steps are present.
- Type consistency: The skill name is consistently `fast-subagent-development`; prompt file names are consistent across tasks and tests.
