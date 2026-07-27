---
name: acceptance-review
description: "Use after implementation to independently verify work against staged Acceptance Criteria. Extracts Implementation Spec and Acceptance regions separately, dispatches a fresh reviewer, and runs a minimal repair loop for failures."
---

# Acceptance Review

Independently verify completed work against the spec's Acceptance Criteria. This skill enforces information isolation: the reviewer sees design and acceptance separately from the implementation, and the repair agent sees only failed criteria.

## When to Use

Use this skill after implementation is complete and you need independent acceptance verification:

- After `subagent-driven-development` completes its tasks and final code review
- After `executing-plans` completes its tasks
- After `spec-driven-implementation` completes its work
- After `fast-subagent-development` completes its final review
- Any time you need independent, evidence-backed acceptance verification

Do not use this skill when:
- Implementation is not yet complete
- There is no spec file with staged markers
- You only need code quality review (use `requesting-code-review` instead)

## Prerequisites

- A spec file containing `IMPLEMENTATION-SPEC-BEGIN/END` and `ACCEPTANCE-BEGIN/END` markers
- The `spec-sections` script, located at `skills/brainstorming/spec-sections`
- `BASE_SHA` recorded before implementation started
- All implementation tasks complete and committed

If the spec has no staged markers, this skill cannot run. Use `requesting-code-review` for code quality review instead.

## The Process

### Stage 1: Extract Review Inputs

Resolve `spec-sections` relative to the brainstorming skill directory. Extract to files so validation completes before any spec content is loaded:

```bash
SPEC_SECTIONS="<brainstorming-skill-directory>/spec-sections"
LEGACY_POLICY="${SUPERPOWERS_SPEC_LEGACY_POLICY:-reject}"
# Equivalent CLI: spec-sections implementation <spec>
"$SPEC_SECTIONS" --legacy "$LEGACY_POLICY" implementation "$SPEC_PATH" > /tmp/review-implementation.md
# Equivalent CLI: spec-sections acceptance <spec>
"$SPEC_SECTIONS" --legacy "$LEGACY_POLICY" acceptance "$SPEC_PATH" > /tmp/review-acceptance.md
```

Do not read the original spec file. If either extraction fails, stop without dispatching review. Never recover by reading or sending the complete file.

Then prepare the implementation evidence:

```bash
BASE_SHA="<recorded before implementation>"
HEAD_SHA=$(git rev-parse HEAD)
git diff "$BASE_SHA..$HEAD_SHA" > /tmp/review.diff
<project test command> > /tmp/review-tests.txt 2>&1
```

**If no staged spec exists:** Use the supplied plan or requirements as the Implementation Spec input and set the Acceptance Contract to `Not provided: code quality review only`. The reviewer may assess quality and requirement alignment but must not claim formal acceptance.

### Stage 2: Dispatch Acceptance Reviewer

Dispatch a `general-purpose` subagent using the template at [reviewer-prompt.md](reviewer-prompt.md).

Populate the template in this exact order:

1. **Implementation Spec** — complete extracted Implementation Spec from `/tmp/review-implementation.md`
2. **Acceptance Contract** — complete extracted Acceptance region from `/tmp/review-acceptance.md`
3. **Implementation Diff** — the actual diff content from `/tmp/review.diff`
4. **Test Results** — fresh test command and output from `/tmp/review-tests.txt`
5. **BASE_SHA** and **HEAD_SHA**

The reviewer must:
- Read the complete Implementation Spec before reading the Acceptance Contract
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
- Only the Implementation Spec sections referenced by the failed criteria
- Only the related implementation diff

**Do not include:** the full Acceptance region, previously passed criteria, unrelated design sections, or unrelated diffs.

After repair:
1. Re-verify the failed criteria
2. Keep previously passed criteria closed unless the repair touches their referenced design area or produces regression evidence
3. After all targeted failures pass, **freshly extract both complete regions** and rerun every Acceptance Criterion and Rollout Acceptance check
4. Continue only when all are PASS

If the platform cannot provide a fresh agent/session for review or repair, stop and hand off the minimal packet. Do not collapse the stages into one context.

## Information Isolation Rules

These rules are mandatory and apply across the entire workflow:

- **Implementers** must never receive Acceptance content. They get only the Implementation Spec.
- **Planners** must never receive Acceptance content. They plan from the Implementation Spec only.
- **Acceptance reviewers** receive both regions but in a defined order: Implementation Spec first, then Acceptance Contract, then diff, then tests.
- **Repair agents** receive only failed criteria and their referenced design sections — never the complete Acceptance region or previously passed criteria.
- **Final acceptance** requires freshly extracting both complete regions. Do not reuse earlier extractions.

## Completion Contract

Work is accepted only when **every** Acceptance Criterion and **every** Rollout Acceptance check is PASS.

- NOT VERIFIED is not PASS
- Missing required evidence means NOT VERIFIED, not PASS
- A passing full test suite does not replace required source, boundary, or runtime semantic checks
- Test success does not replace required evidence for any criterion

## Relationship to Other Skills

- **brainstorming** — produces the staged spec with markers that this skill consumes
- **subagent-driven-development** — call this skill after its final code review completes
- **executing-plans** — call this skill after all tasks complete
- **spec-driven-implementation** — call this skill after implementation slices finish
- **fast-subagent-development** — call this skill after its final review
- **requesting-code-review** — complementary; use that for code quality review, this for formal acceptance