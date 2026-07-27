---
name: acceptance-review
description: "Use after implementation to independently verify work against staged Acceptance Criteria. Reads the design spec and a companion acceptance file separately, dispatches a fresh reviewer, and runs a minimal repair loop for failures."
---

# Acceptance Review

Independently verify completed work against the spec's Acceptance Criteria. This skill uses physical file separation: the design spec and acceptance criteria live in separate files, so information isolation is achieved without extraction tooling.

## When to Use

Use this skill after implementation is complete and you need independent acceptance verification:

- After `subagent-driven-development` completes its tasks and final code review
- After `executing-plans` completes its tasks
- After `spec-driven-implementation` completes its work
- After `fast-subagent-development` completes its final review
- Any time you need independent, evidence-backed acceptance verification

Do not use this skill when:
- Implementation is not yet complete
- There is no design spec file
- You only need code quality review (use `requesting-code-review` instead)

## Prerequisites

- A design spec file (e.g., `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`)
- A companion acceptance file (e.g., `docs/superpowers/specs/YYYY-MM-DD-<topic>-acceptance.md`) — **optional**
- `BASE_SHA` recorded before implementation started
- All implementation tasks complete and committed

If no companion acceptance file exists, the reviewer can still assess code quality and requirement alignment, but cannot perform formal acceptance (no Acceptance Criteria to execute).

## File Convention

| File | Content |
|------|---------|
| `YYYY-MM-DD-<topic>-design.md` | Complete normative design: Goal, Non-Goals, Architecture, Detailed Design, Error Handling, Testing Strategy |
| `YYYY-MM-DD-<topic>-acceptance.md` | Completion contract: Verification Protocol, Acceptance Criteria, Rollout Acceptance |

The design file is the single source of truth for product behavior. The acceptance file translates those requirements into executable review cases; it MUST NOT introduce new product behavior or widen scope.

## The Process

### Stage 1: Prepare Review Inputs

Read the design spec and companion acceptance file directly. No extraction tooling needed — they are already separate files.

```bash
SPEC_PATH="docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md"
ACCEPTANCE_PATH="docs/superpowers/specs/YYYY-MM-DD-<topic>-acceptance.md"
BASE_SHA="<recorded before implementation>"
HEAD_SHA=$(git rev-parse HEAD)

git diff "$BASE_SHA..$HEAD_SHA" > /tmp/review.diff
<project test command> > /tmp/review-tests.txt 2>&1
```

If the acceptance file does not exist, set the Acceptance Contract to `Not provided: code quality review only`. The reviewer may assess quality and requirement alignment but must not claim formal acceptance.

### Stage 2: Dispatch Acceptance Reviewer

Dispatch a `general-purpose` subagent using the template at [reviewer-prompt.md](reviewer-prompt.md).

Populate the template in this exact order:

1. **Implementation Spec** — complete design spec content from `SPEC_PATH`
2. **Acceptance Contract** — complete acceptance file content from `ACCEPTANCE_PATH`, or the no-formal-acceptance notice
3. **Implementation Diff** — the actual diff content from `/tmp/review.diff`
4. **Test Results** — fresh test command and output from `/tmp/review-tests.txt`
5. **BASE_SHA** and **HEAD_SHA**

The reviewer must:
- Read the complete design spec before reading the Acceptance Contract
- Execute every Acceptance Criterion independently
- Report PASS, FAIL, or NOT VERIFIED for each criterion with Required Evidence
- Execute every Rollout Acceptance check with the same status and evidence rules
- Not claim formal acceptance if no Acceptance Contract was provided

**Read-only review:** The reviewer must not mutate the working tree, index, HEAD, or branch state.

### Stage 3: Repair Loop

If the reviewer reports any FAIL or NOT VERIFIED criteria, dispatch a repair subagent using the template at [repair-prompt.md](repair-prompt.md).

The repair agent receives the **minimum context** needed for the failed items:

- Failed Acceptance Criteria (including failed Rollout Acceptance checks)
- Failure evidence from the reviewer
- Only the design spec sections referenced by the failed criteria
- Only the related implementation diff

**Do not include:** the full acceptance file, previously passed criteria, unrelated design sections, or unrelated diffs.

After repair:
1. Re-verify the failed criteria
2. Keep previously passed criteria closed unless the repair touches their referenced design area or produces regression evidence
3. After all targeted failures pass, re-read both complete files and rerun every Acceptance Criterion and Rollout Acceptance check
4. Continue only when all are PASS

If the platform cannot provide a fresh agent/session for review or repair, stop and hand off the minimal packet. Do not collapse the stages into one context.

## Information Isolation Rules

These rules are mandatory and apply across the entire workflow:

- **Implementers** must never receive the acceptance file. They get only the design spec.
- **Planners** must never receive the acceptance file. They plan from the design spec only.
- **Acceptance reviewers** receive both files but in a defined order: design spec first, then acceptance file, then diff, then tests.
- **Repair agents** receive only failed criteria and their referenced design sections — never the complete acceptance file or previously passed criteria.
- **Final acceptance** requires re-reading both complete files. Do not reuse earlier reads.

## Completion Contract

Work is accepted only when **every** Acceptance Criterion and **every** Rollout Acceptance check is PASS.

- NOT VERIFIED is not PASS
- Missing required evidence means NOT VERIFIED, not PASS
- A passing full test suite does not replace required source, boundary, or runtime semantic checks
- Test success does not replace required evidence for any criterion

## Acceptance Criteria Format

Acceptance Criteria are executable review cases, not summaries of the requirements. They translate the spec's complete semantics into repeatable checks that cannot pass through superficial inspection.

Write each criterion in the companion acceptance file in this form:

```markdown
### AC-01: <Acceptance goal>

**Requirement:** <One complete, outcome-determining semantic requirement>

**Verification Steps:**
1. <Inspect a named source location, run a named test/command, or exercise a specific runtime behavior>

**Pass Conditions:** <The exact observable result required for PASS>

**Fail Conditions:** <Specific results, omissions, misclassification, duplication, or shortcuts that require FAIL>

**Required Evidence:** <Files and line numbers, test names and output, logs, screenshots, or other concrete artifacts>
```

Rules for every criterion:

- Make it atomic: one criterion verifies one semantic requirement. Split independently failing requirements into separate criteria.
- Make it independently decidable. The verifier must not need to guess what success means.
- Do not use `exactly`, `all`, `only`, or `as defined above` as substitutes for detail. When a referenced definition determines the result, inline the requirements that determine the result in the criterion.
- Name the source, test, command, or runtime behavior that must be inspected and state both pass and fail outcomes.
- Require evidence specific enough for another reviewer to reproduce the decision.
- A field, function, test, or stage name merely existing is not sufficient evidence that its semantics are correct.
- A passing full test suite does not replace semantic source or runtime verification.
- Cover every implementation-significant requirement in the spec. Acceptance Criteria do not narrow or replace the detailed requirements.

## Verification Protocol

Include this protocol in every acceptance file:

```markdown
- Verify each Acceptance Criterion independently; do not approve from aggregate test results alone.
- When a criterion references another spec definition, read and compare the complete definition.
- Report PASS, FAIL, or NOT VERIFIED for every criterion.
- A PASS must include all Required Evidence named by the criterion.
- Missing required evidence means the criterion is NOT VERIFIED, not PASS.
- Test success does not replace required source, boundary, or runtime semantic checks.
- Execute Rollout Acceptance checks with the same evidence rules.
- Only when every criterion and every Rollout Acceptance check is PASS may the task and automated loop stop.
```

## Relationship to Other Skills

- **brainstorming** — produces the design spec; optionally produces the companion acceptance file
- **subagent-driven-development** — call this skill after its final code review completes
- **executing-plans** — call this skill after all tasks complete
- **spec-driven-implementation** — call this skill after implementation slices finish
- **fast-subagent-development** — call this skill after its final review
- **requesting-code-review** — complementary; use that for code quality review, this for formal acceptance