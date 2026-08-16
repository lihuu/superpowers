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

**Continuous execution:** Do not pause to check in with your human partner between packets. Execute all packets from the plan without stopping. The only reasons to stop are: BLOCKED status you cannot resolve, ambiguity that genuinely prevents progress, or all packets complete. "Should I continue?" prompts and progress summaries waste their time — they asked you to execute the plan, so execute it.

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

Prefer an isolated workspace: use superpowers:using-git-worktrees to create
one or verify the existing one. Fast does not force a worktree the way
`subagent-driven-development` does, but running on a feature branch (never
main/master without your human partner's explicit consent) is still
required.

Conversation memory does not survive compaction. In real sessions,
controllers that lost their place have re-dispatched entire completed packet
sequences — the single most expensive failure observed. Track progress in
a ledger file, not only in todos.

- Each plan owns a workspace: at skill start, run this skill's
  `scripts/sdd-workspace PLAN_FILE` — it prints the plan's git-ignored
  directory (`<repo-root>/.superpowers/sdd/<plan-basename>/`), home to
  every artifact for THIS plan: ledger, packets list, briefs, reports,
  review packages. Another plan's directory is never yours to read or
  write. (The directory is shared with `subagent-driven-development` when
  the same plan runs under both skills; fast artifacts use the `packet-N-*`
  prefix, SDD uses `task-N-*`, so they never collide.)
- Check for this plan's ledger at `<workspace>/progress.md`. If its first
  line names your plan file, packets with a `Packet <N>: complete` line are
  DONE — do not re-dispatch them; resume at the first packet without one.
  A packet whose last line is a repair round is mid-loop: resume the loop at
  the next round. A ledger whose first line names a different plan file is
  another plan's progress: leave it in place and start your own, fresh.
- Create the ledger with its identity as the first line:
  `# SDD-fast ledger — plan: <plan file path>`.
- The ledger is your recovery map: the commits it names exist in git even
  when your context no longer remembers creating them. After compaction,
  trust the ledger and `git log` over your own recollection.
- `git clean -fdx` will destroy the workspace (it's git-ignored scratch); if
  that happens, recover from `git log`.

Read the plan once, note its context and Global Constraints, and create a
todo per packet (after Packetization below).

After the Pre-Flight Packet Review comes back clean, record the branch base
before dispatching Packet 1:

```bash
BASE_SHA=$(git rev-parse HEAD)
```

Do not provide the companion acceptance file to initial implementer
subagents.

## Model Selection

Use the least powerful model that can handle each role to conserve cost and increase speed.

**Mechanical implementation packets** (isolated functions, clear specs, 1-2 files): use a fast, cheap model. Most implementation packets are mechanical when the plan is well-specified.

**Integration and judgment packets** (multi-file coordination, pattern matching, debugging): use a standard model.

**Architecture and design packets**: use the most capable available model.

**Final review**: choose the model with the same judgment as a
`subagent-driven-development` task reviewer, scaled to the branch diff's
size, complexity, and risk. A small mechanical branch does not need the
most capable model; a subtle concurrency change does.

**Auto-downgrade rule:** before dispatching the final review, check the
branch diff size (`git diff --stat <BASE>..<HEAD>`). If the total is under
~300 changed lines AND every implementer packet ran on a cheap or standard
model (no architecture packets), dispatch the final review on a mid-tier
model — the most capable model is overkill for a mechanical branch. If any
packet required architecture-level judgment, or the diff exceeds ~300 lines,
or the branch touches security, concurrency, or migration paths, use the
most capable available model. When in doubt, take the heavier tier — but
defaulting the most expensive model on every run is the single biggest
resource drain in a fast run.

**Repair packets**: round 1 uses the same tier as the implementer that
produced the code (or one tier up if that implementer was cheap). Round 2
uses a model at least one tier above round 1 — a loop that survives one
round usually means the implementer cannot see its own problem.

**Scoped re-reviews**: take a cheap-to-mid tier. They verify fixes against a
findings list, not reason about new design.

**Always specify the model explicitly when dispatching a subagent.** An
omitted model inherits your session's model — often the most capable and
most expensive — which silently defeats this section and is the single
biggest source of slow runs. On harnesses that accept a reasoning-effort
parameter (e.g. Codex), set **both** `model` and `reasoning_effort`
explicitly on every spawn — setting `model` alone silently resets effort
to that model's default, not yours, which can either over-spend on a
trivial task or under-power a judgment task.

**Turn count beats token price.** Wall-clock and context cost scale with how
many turns a subagent takes, and the cheapest models routinely take 2-3× the
turns on multi-step work — costing more overall. Use a mid-tier model as the
floor for reviewers and for implementers working from prose descriptions.
When the packet's plan text contains the complete code to write, the
implementation is transcription plus testing: use the cheapest tier for
that implementer. Single-file mechanical fixes also take the cheapest tier.

**Packet complexity signals (implementation packets):**
- Touches 1-2 files with a complete spec → cheap model
- Touches multiple files with integration concerns → standard model
- Requires design judgment or broad codebase understanding → most capable model

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

After packetization, write every packet's full text to
`<workspace>/packets.md`, one section per packet, each starting with
`## Packet N: <name>`. This file is the single source of packet text —
`scripts/packet-brief PLAN_FILE N` slices section N out of it into a brief
file, so packet text never has to be pasted through your context.

## Pre-Flight Packet Review

Before dispatching Packet 1, spend one turn scanning the packetized plan
for conflicts. This is cheap insurance: a conflict caught now costs one
turn; the same conflict caught at final review costs the whole run. Scan
for three classes:

1. **Packets that contradict each other or the plan's Global Constraints.**
   Two packets that assert opposite behavior, or a packet that violates a
   stated constraint (a global "no new dependencies" rule vs a packet that
   adds one).
2. **Packets whose file or test surfaces overlap in a way the packetizer
   missed.** Two packets both editing the same function, the same config
   block, the same test file's setup, or the same migration number. The
   packetization rules try to keep such tasks in one packet, but a missed
   merge means two implementers race on the same lines — exactly what the
   Execution Mode serial rule exists to prevent, caught one step earlier.
3. **Anything the plan explicitly mandates that the review rubric treats as
   a defect.** A test the plan says to write that asserts nothing, a
   verbatim duplication of a logic block the plan calls for, a "just copy
   this" step. These will fail final review no matter how faithfully
   implemented — better to surface the plan contradiction now than after
   the implementer did exactly what was asked.

**Rule on everything you find, then keep going.** A running plan does not
wait on a human. For each finding, weigh it against the plan text that
mandates it, decide, and record the ruling in the ledger as
`Ruling: <what you decided> — <why> — <what it costs if wrong>` before
dispatching Packet 1. A wrong ruling costs rework your human partner can see
and undo; a session parked on a question costs their whole day and buys
nothing.

Four things stop you, and only these: an irreversible or destructive
operation; a security-sensitive action; a side effect outside this worktree
that norms say you ask about first (a merge, a push to a shared branch, a
publish); and a plan so broken that every path forward is a guess. For
those, stop and ask. Everything else — including pre-flight conflicts,
ambiguous packet boundaries, and constraint tensions — gets a ruling and
continues.

If the scan is clean, proceed without comment. Do not dispatch a subagent
for this scan — you hold the whole packet list and the plan's Global
Constraints; reading them once is the whole job. The final review remains
the net for conflicts that only emerge from implementation.

## Execution Mode

Auto is the default execution mode. Do not ask the user to choose an execution mode unless their instruction is ambiguous in a way that affects safety.

Auto mode uses conservative parallelism:
- Run packets in parallel only when they are clearly independent
- Run packets serially when independence is uncertain
- Run packets serially when they may edit the same file, shared configuration, shared tests, lockfiles, dependency manifests, generated artifacts, migrations, or shared helpers
- Run security-sensitive, authentication-sensitive, persistence-sensitive, migration-sensitive, and release-sensitive packets serially

**Disjoint-file heuristic:** the strongest independence signal is
verifiable from the plan itself. If two packets' file sets are completely
disjoint — no shared source, no shared test, no shared config, no shared
manifest — they are safe to parallelize regardless of other factors. Check
this before falling back to "uncertain → serial." Most well-packetized
plans produce several disjoint pairs that conservative serial logic
needlessly queues.

User instructions override the default:
- If the user explicitly asks for serial execution, run all packets serially
- If the user explicitly asks for parallel execution, parallelize only packets that remain clearly non-conflicting; conflict risk still downgrades those packets to serial execution

Parallel mode must not mean forced parallelism.

## Implementer Subagents

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

After all implementation packets are complete, dispatch one final reviewer subagent by default.

Use `./final-reviewer-prompt.md`.

If the plan references a design spec, load the design spec for the final reviewer. If a companion acceptance file exists, load it for the final reviewer as well.

Before dispatching the reviewer, run
`scripts/review-package PLAN_FILE BASE_SHA HEAD_SHA` (BASE_SHA is the
branch base you recorded before Packet 1). It writes the commit list, stat
summary, and full diff with context to a uniquely named file and prints the
path. Hand the reviewer that path — the diff never enters your own context,
and the reviewer reads one file instead of re-deriving the branch diff with
git commands.

The final reviewer receives:
1. Design spec (path)
2. Companion acceptance file path if present
3. The review-package diff file path
4. Packet summary with commit SHAs
5. Relevant test results (from implementer reports)
6. Implementer concerns

The final reviewer checks:
- Spec alignment
- Code quality
- Integration between packets
- Test quality and coverage
- Missing or extra behavior
- Implementation concerns raised by implementers

If a companion acceptance file exists, the reviewer performs a lightweight Acceptance check:
- Report PASS, FAIL, or NOT VERIFIED for each Acceptance Criterion and Rollout Acceptance check
- Include concrete evidence for each status
- Do not require the full high-assurance acceptance repair loop unless the user asked for strict, PR-ready, high confidence, or full acceptance mode

If the user explicitly says the main agent should review without a reviewer subagent, the controller may perform the final review itself.

Point the reviewer at the ledger's deferred-minor lines (if any) so it can
triage which must be fixed before merge.

## Independent Acceptance (Optional)

If the user asked for strict, PR-ready, high confidence, or full acceptance mode, invoke `superpowers:acceptance-review` after the final review completes. It performs the full high-assurance acceptance repair loop: separate extraction, independent reviewer, minimal repair packets, and a fresh full re-verification.

Do not invoke `acceptance-review` for the default fast path — the final reviewer's lightweight Acceptance check is sufficient.

## Repair Loop

If final review finds no Critical/Important issues, finish (see Finish). If it does, enter the repair loop.

**Minor findings never enter the loop.** Record them in the ledger as you
go (`Packet <N>: minor (deferred): <one-liner>`) and point the final
re-review at that list so it can triage. A roll-up nobody reads is a silent
discard.

The loop is capped at **2 rounds**. Each round is one repair dispatch plus
one scoped re-review. The implementer's report file is the persistent
memory either path starts from.

**Round 1 — resume the original implementer** with the review findings.
Its context is intact: it knows the packet, the code, and its own choices,
so it does not have to rebuild understanding from the report file. Send
the findings verbatim, the diff file path, and the failing evidence. If
your harness cannot send another message to a live subagent, dispatch a
fresh repair subagent (via `./repair-prompt.md`) carrying the brief path,
the report-file path, and the findings — the report file is the persistent
memory either way. The implementer fixes root causes, runs targeted tests,
commits the repair, and appends its fix report to
`<workspace>/packet-N-report.md` (repair shares the implementer's report
file). Specify the model explicitly (see Model Selection).

If review findings span independent areas, you may dispatch multiple
focused repair subagents. Do not run focused repair subagents in parallel
when they may touch the same files, tests, configuration, or shared helpers.

Then run `scripts/review-package PLAN_FILE FIX_BASE HEAD` (FIX_BASE is the
head the final review saw) and dispatch the scoped re-review with
`./re-review-prompt.md`, the findings list, the brief, the report file, and
the printed diff path. The re-reviewer verdicts each finding ADDRESSED or
NOT ADDRESSED and flags new breakage in the fix diff only.

If the re-review comes back clean (all findings addressed, no new
Critical/Important breakage), append
`Packet <N>: repair round 1/2 (all addressed; commits <fixbase7>..<head7>)`
to the ledger and finish.

**Round 2 — only if round 1 left findings open.** Dispatch a **fresh**
repair subagent (via `./repair-prompt.md`) on a model at least one tier
above round 1, with the brief path, the report-file path (which now
contains the round-1 fix report), and the open findings. Frame it: "A
prior repair attempted this; you own it now. Read the report file for what
was tried." A loop that survives round 1 usually means the implementer
cannot see its own problem — fresh eyes and a capability bump in one move.
Then run one scoped re-review as above.

**After round 2,** append
`Packet <N>: repair round 2/2 (<X> addressed, <Y> open — <finding one-liners>; commits <a7>..<b7>)`
to the ledger.

**The cap.** When round 2's re-review still leaves findings open, stop
dispatching. Adjudicate each open finding yourself — you hold the plan and
the cross-packet context the reviewer lacks:

- **The reviewer is wrong, or the point is contestable:** park it —
  `Packet <N>: parked — <finding> — ruling: <why the code stands>`.
- **Real, but nothing downstream builds on it:** park it the same way, with
  a ruling that says it's real and deferred.
- **Real and load-bearing** — a later packet builds on it, or it reveals a
  plan defect: STOP. Append `Packet <N>: BLOCKED — <reason>` and report to
  your human partner with the finding, the plan text it collides with, and
  the fix history. Parking a structural failure hands every dependent
  packet a problem it cannot fix either.

Adjudicate only at the cap. Adjudicating earlier to end a loop is
pre-judging with a different name. Every adjudication is a ledger entry —
a silent discard is forbidden.

Never fix findings yourself in the controller session — your context stays
clean for coordination, and controller fixes skip review.

## Finish

When the final review is clean and its fixes (if any) are merged, delete
this plan's workspace (`rm -rf <workspace>`) — the git history is the
record now. Sibling directories belong to other plans; leave them alone.

Use superpowers:finishing-a-development-branch.

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