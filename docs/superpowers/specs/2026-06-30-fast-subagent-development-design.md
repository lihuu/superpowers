<!-- IMPLEMENTATION-SPEC-BEGIN -->

# Goal

Create a new `fast-subagent-development` skill for executing existing implementation plans with lower coordination overhead than `subagent-driven-development`.

The skill preserves subagent isolation for implementation work, but removes the per-task spec-review and code-quality-review gates. Instead, implementer subagents complete grouped implementation packets, then a single final reviewer checks the completed work. Repair subagents are dispatched only when the final review finds issues.

# Non-Goals

- Do not replace or weaken `subagent-driven-development`; that skill remains the high-assurance workflow for high-risk changes, strict PR preparation, and situations requiring review after every task.
- Do not change `writing-plans` task or checkbox granularity. TDD microsteps in plans remain valid execution checkpoints.
- Do not require user confirmation for every packet grouping decision.
- Do not force parallel execution. Parallelism is allowed only when independence is clear.
- Do not implement a new harness, runtime tool, or external dependency.

# Architecture

The new skill is a workflow skill beside `subagent-driven-development`.

It uses four conceptual roles:

1. **Controller**: the main agent running the skill. It reads the plan, extracts implementation context, builds packets, chooses execution ordering, dispatches subagents, and coordinates review/repair.
2. **Implementer subagent**: implements exactly one implementation packet and commits its work before reporting.
3. **Final reviewer subagent**: reviews the complete implementation after all packets are done. This is the default review mode.
4. **Repair subagent**: fixes issues reported by final review. The controller dispatches one repair subagent by default, or multiple focused repair subagents when issues span independent areas.

The skill should reuse existing concepts and prompt structure where practical:

- Use `spec-sections implementation` to provide implementation-only context to implementers when the plan references a single-file spec.
- Use `spec-sections acceptance` only during final review, not during initial implementation.
- Use the existing requesting-code-review review vocabulary for severity and evidence, but calibrate the review as a final consolidated review rather than per-task review.
- Use the existing repair-prompt pattern from `subagent-driven-development` when acceptance failures need focused repair context.

# Detailed Design

## Trigger Conditions

Use `fast-subagent-development` when the user wants to execute an existing implementation plan quickly with subagent help, and the work does not require high-assurance review after every task.

Use `subagent-driven-development` instead when the user explicitly asks for strict mode, high confidence, PR-ready review gates, high-risk changes, security-sensitive work, migration-heavy work, or per-task review loops.

## Plan and Spec Intake

The controller reads the plan once at the start.

If the plan header references a single-file spec, the controller extracts the Implementation Spec using:

```bash
SPEC_SECTIONS="<brainstorming-skill-directory>/spec-sections"
LEGACY_POLICY="${SUPERPOWERS_SPEC_LEGACY_POLICY:-reject}"
"$SPEC_SECTIONS" --legacy "$LEGACY_POLICY" implementation "$SPEC_PATH" > /tmp/implementation-spec.md
BASE_SHA=$(git rev-parse HEAD)
```

Initial implementer subagents receive:

- the complete implementation packet text,
- relevant extracted Implementation Spec sections,
- relevant architectural/context notes,
- file ownership and expected test commands.

Initial implementer subagents must not receive Acceptance content.

## Packetization

The controller converts plan tasks into implementation packets before dispatching subagents.

A packet may contain one or more adjacent plan tasks. Checkbox steps inside a plan task are TDD execution checkpoints inside the packet; they are not separate subagent tasks.

The controller automatically merges adjacent tasks when they are part of the same implementation chain:

- setup plus implementation,
- helper plus wiring,
- tests plus the behavior they verify,
- documentation for the same behavior,
- tightly dependent tasks that modify the same files or test surface.

The controller does not merge tasks when they are independently implementable or risky to combine:

- different subsystems,
- different risk domains such as authentication, security, persistence, migrations, or release automation,
- tasks that can be independently verified and reverted,
- tasks whose combined context would be too large for a focused implementer.

Packetization is automatic and does not require user confirmation. The controller should still summarize the packet list before execution so progress is understandable.

## Execution Mode

The default execution mode is **Auto** and does not ask the user for confirmation.

Auto mode uses conservative parallelism:

- Run packets in parallel only when they are clearly independent.
- Run packets serially when independence is uncertain.
- Run packets serially when they may edit the same file, shared configuration, shared tests, lockfiles, dependency manifests, generated artifacts, migrations, or shared helpers.
- Run security-sensitive, authentication-sensitive, persistence-sensitive, migration-sensitive, and release-sensitive packets serially.

User instructions override the default:

- If the user explicitly asks for serial execution, run all packets serially.
- If the user explicitly asks for parallel execution, parallelize only packets that remain clearly non-conflicting; conflict risk still downgrades those packets to serial execution.

Parallel mode must not mean forced parallelism.

## Implementer Subagents

Each implementer subagent receives exactly one implementation packet.

The implementer must:

1. follow TDD checkpoints contained in the packet,
2. implement only the packet scope,
3. run relevant tests,
4. commit the packet as one commit,
5. report status, changed files, commit SHA, commands run, and concerns.

Implementers must not create one commit per checkbox microstep. Commit messages describe the packet outcome.

Implementer statuses:

- `DONE`: packet implemented and committed.
- `DONE_WITH_CONCERNS`: packet committed but the implementer has doubts or notable risks.
- `NEEDS_CONTEXT`: missing information prevents safe implementation.
- `BLOCKED`: implementation cannot proceed without changing the plan, packet boundary, model capability, or user decision.

The controller handles `NEEDS_CONTEXT` and `BLOCKED` before continuing dependent work.

## Final Review

After all implementation packets are complete, the controller dispatches one final reviewer subagent by default.

The final reviewer receives:

1. Implementation Spec,
2. Acceptance region if present,
3. complete implementation diff from `BASE_SHA` to `HEAD_SHA`,
4. packet summary with commit SHAs,
5. relevant test results,
6. implementer concerns.

The final reviewer checks:

- spec alignment,
- code quality,
- integration between packets,
- test quality and coverage,
- missing or extra behavior,
- implementation concerns raised by implementers.

If Acceptance content exists, the reviewer performs a lightweight Acceptance check:

- report `PASS`, `FAIL`, or `NOT VERIFIED` for each Acceptance Criterion and Rollout Acceptance check,
- include concrete evidence for each status,
- do not require the full high-assurance acceptance repair loop unless the user asked for strict, PR-ready, high confidence, or full acceptance mode.

If the user explicitly says the main agent should review without a reviewer subagent, the controller may perform the final review itself.

## Repair Loop

If final review finds issues, the controller dispatches repair work.

Default repair behavior:

- Dispatch one repair subagent with the review findings, relevant Implementation Spec sections, relevant Acceptance criteria when applicable, related diff, and failing evidence.
- The repair subagent fixes root causes, runs targeted tests, commits the repair, and reports changed files, commands, results, and evidence.

Split repair behavior:

- If review findings span independent areas, dispatch multiple focused repair subagents.
- Do not run focused repair subagents in parallel when they may touch the same files, tests, configuration, or shared helpers.

After repair:

- Re-review affected areas.
- Re-run failed or unverified Acceptance checks when Acceptance was part of the final review.
- Run a second final review when repair touched broad architecture, multiple packets, shared interfaces, or previously passing acceptance areas.

# Error Handling

If spec extraction fails, stop and report the extraction error. Do not fall back to reading the complete spec.

If packetization is ambiguous, choose the safer execution boundary:

- smaller packet instead of oversized packet,
- serial execution instead of parallel execution,
- explicit user escalation when the ambiguity changes scope or risk.

If an implementer commits unintended scope or edits unrelated files, the controller stops dependent execution, reviews the diff, and either dispatches a repair/revert task or asks the user if the scope change should be kept.

If parallel packets conflict, the controller stops parallel continuation for the affected packets and resolves them serially. Do not ask implementers to race on the same files.

If final review produces unclear findings, the controller asks the reviewer for clarification or verifies the finding before dispatching repair.

# Testing Strategy

Add fast contract tests that verify the skill document contains the required workflow rules:

- Auto is the default execution mode.
- Parallelism downgrades to serial on file or shared-test conflicts.
- Packetization merges adjacent small tasks in the same implementation chain.
- Checkbox steps are TDD checkpoints, not subagent boundaries.
- Implementer subagents commit one packet per commit.
- Final review defaults to a reviewer subagent.
- Acceptance content is excluded from initial implementers and used only at final review.
- Repair is default-one-subagent and splits only across independent areas.

Add a prompt-template test for implementer instructions:

- implementer receives one packet,
- follows all included checkbox steps,
- commits once,
- reports status, commit SHA, changed files, commands, and concerns.

Add a prompt-template test for final reviewer instructions:

- reviewer receives implementation spec, optional acceptance, complete diff, packet summary, tests, and concerns,
- reviewer checks spec alignment, code quality, integration, and tests,
- reviewer reports Acceptance statuses when Acceptance content exists.

Full end-to-end subagent integration testing is useful but not required for the first implementation because it is slow and costly. The initial implementation should rely on fast textual contract tests plus manual review of the skill content.

<!-- IMPLEMENTATION-SPEC-END -->

<!-- ACCEPTANCE-BEGIN -->

# Completion Contract

The feature is complete when a new `fast-subagent-development` skill exists, includes prompt templates needed by its workflow, and fast tests verify its core behavior contracts.

The implementation must not alter `writing-plans` TDD step granularity and must not weaken `subagent-driven-development`.

# Verification Protocol

- Verify each Acceptance Criterion independently; do not approve from aggregate test results alone.
- When a criterion references another spec definition, read and compare the complete definition.
- Report PASS, FAIL, or NOT VERIFIED for every criterion.
- A PASS must include all Required Evidence named by the criterion.
- Missing required evidence means the criterion is NOT VERIFIED, not PASS.
- Test success does not replace required source, boundary, or runtime semantic checks.
- Execute Rollout Acceptance checks with the same evidence rules.
- Only when every criterion and every Rollout Acceptance check is PASS may the task and automated loop stop.

# Acceptance Criteria

### AC-01: New skill is distinct from high-assurance workflow

**Requirement:** The implementation adds a separate `fast-subagent-development` skill and does not replace `subagent-driven-development` or remove its per-task review behavior.

**Verification Steps:**
1. Inspect the skills directory for the new skill file.
2. Inspect `skills/subagent-driven-development/SKILL.md` for the existing per-task spec review and code quality review workflow.
3. Inspect the new skill text for an explicit boundary between fast mode and high-assurance mode.

**Pass Conditions:** A new skill exists, `subagent-driven-development` still documents per-task review gates, and the new skill states that strict or high-risk work should use the high-assurance workflow.

**Fail Conditions:** The implementation replaces the existing skill, removes per-task review gates from high-assurance workflow, or fails to distinguish the workflows.

**Required Evidence:** New skill path, relevant lines from `skills/subagent-driven-development/SKILL.md`, and relevant lines from the new skill.

### AC-02: Auto execution mode is default and conservative

**Requirement:** The new skill defaults to Auto mode without asking the user, and Auto mode parallelizes only clearly independent packets while downgrading uncertain or conflicting work to serial execution.

**Verification Steps:**
1. Inspect the new skill's execution mode section.
2. Inspect tests for coverage of default Auto and conflict downgrade behavior.

**Pass Conditions:** The skill says Auto is default, no prompt is required by default, unclear independence uses serial execution, and file/shared-test/configuration conflicts downgrade to serial.

**Fail Conditions:** The skill asks the user every time, treats parallel mode as forced parallelism, or lacks downgrade rules for conflicts.

**Required Evidence:** Skill lines defining Auto behavior and test lines asserting those rules.

### AC-03: Packetization merges implementation chains

**Requirement:** The controller automatically merges adjacent small plan tasks into implementation packets when they are part of the same behavior chain, while preserving separate packets for independent or risky work.

**Verification Steps:**
1. Inspect the packetization section of the new skill.
2. Inspect tests for merge and no-merge rules.

**Pass Conditions:** The skill includes merge rules for setup/helper/wiring/tests/docs in one behavior chain and no-merge rules for different subsystems, risk domains, independently revertible work, and oversized context.

**Fail Conditions:** The skill dispatches strictly one subagent per plan task, requires user confirmation for every merge, or permits risky unrelated merges.

**Required Evidence:** Skill lines defining packetization and tests covering merge/no-merge behavior.

### AC-04: Checkbox steps are not subagent boundaries

**Requirement:** Checkbox steps inside a plan task or packet are treated as TDD execution checkpoints, not separate subagent dispatch or review boundaries.

**Verification Steps:**
1. Inspect the new skill.
2. Inspect implementer prompt templates.
3. Inspect tests covering checkbox-step behavior.

**Pass Conditions:** The skill and implementer prompt both state that checkbox steps remain inside the packet, and tests assert this contract.

**Fail Conditions:** The workflow dispatches separate subagents or final reviews for individual checkbox steps.

**Required Evidence:** Skill lines, implementer prompt lines, and test lines.

### AC-05: Implementer commits once per packet

**Requirement:** Each implementer subagent commits its completed implementation packet as one commit and does not create one commit per TDD microstep.

**Verification Steps:**
1. Inspect implementer instructions.
2. Inspect tests covering commit behavior.

**Pass Conditions:** Implementer instructions require one packet commit and prohibit one commit per checkbox microstep.

**Fail Conditions:** Commit behavior is unspecified, delegated entirely to implementer preference, or encourages microstep commits.

**Required Evidence:** Implementer prompt lines and test lines.

### AC-06: Final review defaults to reviewer subagent

**Requirement:** After all implementation packets complete, final review defaults to dispatching one reviewer subagent unless the user explicitly requested main-agent review.

**Verification Steps:**
1. Inspect the final review section of the new skill.
2. Inspect reviewer prompt template if present.
3. Inspect tests covering default review behavior and user override behavior.

**Pass Conditions:** The skill defaults to one final reviewer subagent, allows explicit main-agent review override, and defines reviewer inputs.

**Fail Conditions:** The skill defaults to main-agent review, omits review, or requires the user to choose review mode every time.

**Required Evidence:** Skill lines, reviewer prompt lines if applicable, and test lines.

### AC-07: Acceptance is final-review-only by default

**Requirement:** Initial implementers do not receive Acceptance content. If Acceptance content exists, final review checks it lightly by reporting `PASS`, `FAIL`, or `NOT VERIFIED`, without forcing the full high-assurance acceptance loop unless requested.

**Verification Steps:**
1. Inspect implementer prompt instructions.
2. Inspect final reviewer instructions.
3. Inspect tests for Acceptance exclusion and final-review inclusion.

**Pass Conditions:** Acceptance content is excluded from implementer prompts, included only at final review, and checked with status plus evidence when present.

**Fail Conditions:** Implementers receive Acceptance content by default, final review ignores Acceptance content, or the fast workflow always forces the full high-assurance acceptance loop.

**Required Evidence:** Implementer prompt lines, reviewer prompt lines, and test lines.

### AC-08: Repair loop is delayed and focused

**Requirement:** Repair subagents are dispatched only after final review finds issues. The default is one repair subagent, with multiple focused repair subagents only when issues span independent areas.

**Verification Steps:**
1. Inspect the repair section of the new skill.
2. Inspect repair prompt template if present.
3. Inspect tests covering default repair and split repair behavior.

**Pass Conditions:** The workflow delays repair until after final review, defaults to one repair subagent, splits independent issue areas, and re-reviews affected areas after repair.

**Fail Conditions:** The workflow runs repair loops after every packet, never dispatches repair, or splits repairs without independence constraints.

**Required Evidence:** Skill lines, repair prompt lines if applicable, and test lines.

# Rollout Acceptance

### RA-01: Fast tests pass

**Requirement:** Fast non-integration tests covering the new skill contracts pass locally.

**Verification Steps:**
1. Run the relevant fast test script or scripts for the new skill.
2. Run any existing staged spec workflow test that references the new skill if one is updated.

**Pass Conditions:** All selected fast tests exit with status 0.

**Fail Conditions:** Any selected fast test fails, hangs, or requires slow integration-only tooling for basic contract coverage.

**Required Evidence:** Commands run and their pass output.

### RA-02: Spec validates mechanically

**Requirement:** This spec file validates with the repository's `spec-sections` tool.

**Verification Steps:**
1. Run `skills/brainstorming/spec-sections validate docs/superpowers/specs/2026-06-30-fast-subagent-development-design.md`.

**Pass Conditions:** The command exits with status 0.

**Fail Conditions:** The command reports missing, duplicate, nested, empty, malformed, or out-of-order regions.

**Required Evidence:** Validation command and output.

<!-- ACCEPTANCE-END -->
