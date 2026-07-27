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
# Equivalent CLI: spec-sections implementation <spec>
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

If the plan references a single-file spec, extract Acceptance only for final review:

```bash
# Equivalent CLI: spec-sections acceptance <spec>
"$SPEC_SECTIONS" --legacy "$LEGACY_POLICY" acceptance "$SPEC_PATH" > /tmp/acceptance.md
```

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

## Independent Acceptance (Optional)

If the user asked for strict, PR-ready, high confidence, or full acceptance mode, invoke `superpowers:acceptance-review` after the final review completes. It performs the full high-assurance acceptance repair loop: separate extraction, independent reviewer, minimal repair packets, and a fresh full re-verification.

Do not invoke `acceptance-review` for the default fast path — the final reviewer's lightweight Acceptance check is sufficient.

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
