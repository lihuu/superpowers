---
name: fast-subagent-development
description: Use when executing an existing implementation plan quickly with subagent help and final review, without high-assurance review after every task
---

# Fast Subagent Development

Execute an existing implementation plan with implementer subagents first, then one final review. This is the fast path for ordinary planned development.

**Core principle:** implementer-only packets + consolidated final review = subagent isolation without per-task review overhead.

Use `subagent-driven-development` instead for strict mode, high confidence, PR-ready review gates, high-risk changes, security-sensitive work, migration-heavy work, or review after every task.

**Narration:** between tool calls, narrate at most one short line — the
ledger and the tool results carry the record.

**Continuous execution:** Do not pause to check in with your human partner between packets. Execute all packets from the plan without stopping. The only reasons to stop are the four named below, or all packets complete. "Should I continue?" prompts and progress summaries waste their time — they asked you to execute the plan, so execute it.

**Rulings, not stalls.** A running plan does not wait on a human. Conflicts,
ambiguities, plan defects, a cap you would have asked to exceed — decide
them. The plan is the binding authority and your judgment settles what it
does not answer. Record every decision in the ledger as
`Ruling: <what you decided> — <why> — <what it costs if wrong>`, and keep
going. A wrong ruling costs rework your human partner can see and undo; a
session parked on a question costs their whole day and buys nothing.

Four things stop you, and only these: an irreversible or destructive
operation; a security-sensitive action; a side effect outside this worktree
that norms say you ask about first (a merge, a push to a shared branch, a
publish); and a plan so broken that every path forward is a guess. For those,
stop and ask.

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

## Setup

Prefer an isolated workspace: use `superpowers:using-git-worktrees` or run on a dedicated feature branch.

Record the branch base before dispatching Packet 1:
```bash
BASE_SHA=$(git rev-parse HEAD)
```

## Model Selection

Use fast, lightweight models where possible to conserve cost and maximize speed.

- **Mechanical / straightforward packets** (isolated functions, clear specs, 1-2 files): use a fast/cheap model.
- **Integration / multi-file packets**: use a standard model.
- **Final review**: use a standard or capable model.

Always specify the `model` explicitly when dispatching a subagent.

## Packetization (Aggressive Merging)

Convert plan tasks into implementation packets before dispatching subagents.

**Default to aggressive merging.**
- For most small-to-medium plans, **merge all tasks into 1 or at most 2 packets**.
- A single implementer executing 3-4 cohesive tasks in one flow is dramatically faster than 3-4 separate subagents cold-starting and exploring the repo from scratch.
- Only split packets when:
  1. The tasks belong to completely different modules/directories (and can run in parallel).
  2. The total scope exceeds ~400 lines of changes.

## Execution Mode & Parallelism

- **Active Parallelism:** If packets modify disjoint directories/files, dispatch them **in parallel immediately**.
- **Serial Execution:** Only serialize when packets directly modify the exact same source files or migration sequences.

## Implementer Subagents

Keep dispatches lean and action-oriented. Use `./implementer-prompt.md`.

- **Inline Requirements:** If the packet scope is concise (<50 lines), provide requirements directly in the prompt instead of generating intermediate brief files.
- **Direct Return:** Implementers test, commit once, and return status directly (Status, Commit SHA, Test Summary). No need to write intermediate report files to disk.
- Never let implementers spawn subagents or reviewers.

Everything you paste into a dispatch prompt — and everything a subagent
prints back — stays resident in your context for the rest of the session
and is re-read on every later turn. Hand artifacts over as files.

**Waiting on dispatched subagents:** never poll a wait interface with
short timeouts, and never sit in one silent, open-ended wait either.
While you have local work — ledger updates, packaging the next packet
brief, reading reports — keep working; child results arrive on their
own. When you are genuinely idle, wait in bounded stretches (five to
ten minutes, where your platform allows), and between stretches post
one line of status and reconcile your live children: list them, and
chase any that finished without reporting. A bounded stretch keeps
nearly all of a long wait's efficiency while guaranteeing a stuck or
lost child is noticed within minutes, not at the end of the session.

Each implementer subagent receives exactly one implementation packet.

Use `./implementer-prompt.md`.

Before dispatching a packet:
- Run `scripts/packet-brief PLAN_FILE N` — it writes the packet's full text
  to `<workspace>/packet-N-brief.md` and prints the path. The brief is the
  single source of requirements for that packet.
- Compose the dispatch so the brief stays the single source of
  requirements. Your dispatch should contain: (1) one line on where this
  packet fits in the project; (2) the brief path, introduced as "read this
  first — it is your requirements, with the exact values to use verbatim";
  (3) interfaces and decisions from earlier packets that the brief cannot
  know; (4) your resolution of any ambiguity you noticed in the brief;
  (5) the report-file path (`<workspace>/packet-N-report.md`) and the
  report contract. Exact values (numbers, magic strings, signatures, test
  cases) appear only in the brief. Never make a subagent read the whole
  plan file.
- Record the packet's BASE (`git rev-parse HEAD`) before dispatching — the
  final review diff needs it.
- Record the implementer's agent identity from the dispatch result — repair
  round 1 resumes this agent.
- Specify the model explicitly (see Model Selection).

The implementer must:
1. Follow TDD checkpoints contained in the packet
2. Implement only the packet scope
3. Run relevant tests
4. Commit the packet as one commit
5. Report status, changed files, commit SHA, commands run, and concerns

The dispatch carries the no-subagents contract (it is in the implementer
template): the implementer never dispatches subagents — not helpers, and
never a reviewer. In real sessions, every reviewer a worker spawned
duplicated the final review the controller dispatches anyway — a full extra
review seat per packet.

Implementers must not create one commit per checkbox microstep. Commit messages describe the packet outcome.

Implementer statuses:
- **DONE:** packet implemented and committed
- **DONE_WITH_CONCERNS:** packet committed but the implementer has doubts or notable risks
- **NEEDS_CONTEXT:** missing information prevents safe implementation
- **BLOCKED:** implementation cannot proceed without changing the plan, packet boundary, model capability, or user decision

Handle `NEEDS_CONTEXT` and `BLOCKED` before continuing dependent work.

On **DONE** or **DONE_WITH_CONCERNS**, append the completion line to the
ledger in the same message as your other bookkeeping:
- `Packet <N>: complete (commits <base7>..<head7>)`
- `Packet <N>: complete (commits <base7>..<head7>, concerns: <one-liner>)` when concerns were reported

Then mark the todo complete and move on.

**Context slimming after completion:** once the ledger line is written and
the todo is marked complete, that packet's dispatch prompt and status
report are dead weight — do not re-read them on later turns. The only
artifacts you need going forward are the ledger line (for recovery) and
the report-file path (for the final review and repair). A 10-packet run
accumulates 20+ message pairs in your context; treating completed packets
as read-only history keeps your context lean for coordination work.

## Final Review

After implementation packets complete, dispatch one consolidated final reviewer subagent:
- Use `./final-reviewer-prompt.md`.
- Check diff: `git diff BASE_SHA..HEAD`.
- Ensure tests pass and all plan items are implemented.
- If the branch is clean and tests pass, proceed to finish immediately.

## Repair Loop (If Needed)

If the final review finds Critical/Important defects:
1. Dispatch one repair subagent (`./repair-prompt.md`) with the exact defect list.
2. Verify with test suite.
3. Keep repairs capped at 1-2 rounds.

## Finish

When review/tests pass:
1. Run final verification.
2. Use `superpowers:finishing-a-development-branch`.

## Error Handling

If spec extraction fails, stop and report the extraction error. Do not fall back to reading the complete spec.

If packetization is ambiguous, choose the safer execution boundary:
- Smaller packet instead of oversized packet
- Serial execution instead of parallel execution
- User escalation when ambiguity changes scope or risk

If an implementer commits unintended scope or edits unrelated files, stop dependent execution, review the diff, and either dispatch repair/revert work or ask whether the scope change should be kept.

If parallel packets conflict, stop parallel continuation for the affected packets and resolve them serially. Do not ask implementers to race on the same files.

If final review produces unclear findings, ask the reviewer for clarification or verify the finding before dispatching repair.

After compaction, trust the ledger and `git log` over your own
recollection. Re-dispatching a completed packet is the most expensive
failure this skill has — the ledger exists to prevent it.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Dispatch without a model, it'll use the default" | The default is the most expensive model. Specifying the model is the single biggest speed lever. |
| "I'll paste the packet text into the dispatch" | It bloats your context for the rest of the session. Use the brief file. |
| "Ledger bookkeeping is overhead" | The ledger is what survives compaction. Controllers without one have re-dispatched entire completed packet sequences. |
| "One more repair round will converge" | Past round 2, rounds don't converge — the failure is structural. Adjudicate and route. |
| "This finding is obviously wrong, I'll drop it" | You adjudicate only at the cap, and every ruling is a ledger entry. Silent discards are forbidden. |
| "The fix was small, skip the re-review" | Unreviewed fixes are how regressions land. Every round ends with a scoped re-review. |
| "Skip final review, implementers reported DONE" | Implementer self-review never replaces the final review. |
| "Final review can run its own git diff" | That wastes reviewer turns and puts the diff in its context. Hand it the review-package file. |
| "Pre-flight is overhead, the plan looked fine" | One turn of scanning vs. a whole run wasted on a plan conflict. A conflict caught at final review cost the entire implementation. |
| "I should ask my human partner about this plan conflict" | Rule on it and keep going — the plan is the authority, your judgment settles what it doesn't answer, and the ledger records the ruling. A parked question costs their whole day; a wrong ruling costs rework they can see and undo. |

## Red Flags

Never:
- Dispatch one implementer per checkbox microstep
- Dispatch any subagent without an explicit `model:` field
- Paste packet text, spec text, or diff text into a dispatch prompt — hand over file paths
- Provide Acceptance content to initial implementers
- Force parallelism when files or tests may conflict
- Skip the pre-flight packet review — a plan conflict caught now costs one turn; caught at final review it costs the whole run
- Skip final review because implementers reported DONE
- Let repair broaden beyond review findings
- Run repair past round 2 — adjudicate instead
- Skip the ledger — compaction will make you re-dispatch completed packets
- Use this skill for strict high-risk work that belongs in `subagent-driven-development`