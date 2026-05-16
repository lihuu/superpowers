# Design Spec: Takeover Skill

**Date:** 2026-05-16
**Status:** Draft
**Goal:** Let a fresh agent safely take over partially completed work from a handoff file or interrupted session without guessing, skipping state validation, or redoing orientation work.

## Problem

The `handoff` skill can write a structured handoff file, but a fresh receiving agent may not load `handoff` when the user says "read the latest handoff and resume." The natural task for the receiving agent is not "handoff this work"; it is "take over existing work." Without a dedicated receiving-side skill, the agent may skip the handoff instructions, read the wrong file, trust stale Git state, or continue from an unsafe assumption.

## Scope

`takeover` is a receiving-side skill. It does not generate handoff files. It reads existing work context, verifies the current workspace against that context, reconstructs the next action, and only then continues.

In scope:
- Resume from an explicit handoff file path.
- Resume from the latest file in `docs/superpowers/handoffs/` when no path is given.
- Take over a partially completed task with modified files in the working tree.
- Validate branch, last commit, and modified files before continuing.
- Report mismatches instead of blindly executing.

Out of scope:
- Creating handoff documents. That remains the `handoff` skill's job.
- Recovering deleted conversation history.
- Solving merge conflicts automatically.
- Selecting between multiple unrelated handoffs beyond a deterministic latest-file fallback.

## Architecture

The skill follows a "Locate, Verify, Resume" architecture.

1. **Locate Context**
   - Prefer a handoff path explicitly provided by the user.
   - If no path is provided, find the newest Markdown file in `docs/superpowers/handoffs/`.
   - If no handoff exists, inspect `git status --short`, recent commits, active specs/plans, and ask for direction before executing.

2. **Parse Handoff**
   - Read the handoff file.
   - Extract:
     - Current objective
     - Work completed
     - Pending tasks
     - Next immediate action
     - Modified files
     - Git state
     - Mental state and blockers

3. **Verify Workspace State**
   - Run `bash skills/handoff/scripts/gather-state.sh .` when available.
   - Compare current branch and last commit with the handoff.
   - Compare current modified files with the handoff's `Modified Files` and `Git State` sections.
   - If the handoff lists a modified file that no longer exists or the working tree contains unexpected changes, report the mismatch before proceeding.

4. **Resume Work**
   - Announce the handoff file being used.
   - Summarize the objective and next immediate action.
   - Reconstruct the task list from `Pending Tasks`.
   - Continue only if state validation passes or the mismatch is clearly harmless.
   - If validation fails, stop and explain the concrete discrepancy.

## Skill Definition

- **Skill Name:** `takeover`
- **Trigger:** Taking over existing work, resuming from a handoff file, continuing an interrupted session, inheriting a partially completed task, or reading a handoff to resume work.
- **Directory:** `skills/takeover/`
- **Primary File:** `skills/takeover/SKILL.md`

The description must describe trigger conditions only, not the workflow:

```yaml
description: Use when taking over existing work, resuming from a handoff file, continuing an interrupted session, or inheriting a partially completed task.
```

## Relationship to Handoff

`handoff` and `takeover` are paired but separate:

- `handoff`: Source agent captures state and writes a handoff file.
- `takeover`: Receiving agent reads a handoff file, validates workspace state, and resumes.

The `handoff` skill's resumption instruction should direct the user to invoke takeover:

```text
Use the takeover skill to read docs/superpowers/handoffs/<exact-file>.md and resume work.
```

When the exact handoff path is known, `handoff` should output that path instead of asking the next agent to infer "latest."

## Takeover Procedure

The skill body must require this sequence:

1. Announce: `I am taking over from <handoff-path>.`
2. Read the handoff file.
3. Run current-state verification:
   - Prefer `bash skills/handoff/scripts/gather-state.sh .`.
   - Fall back to `git status --short`, `git rev-parse --abbrev-ref HEAD`, and `git rev-parse --short HEAD`.
4. Compare the current state to the handoff.
5. Report one of:
   - `State matches. Resuming from: <next immediate action>.`
   - `State mismatch. I need confirmation before continuing: <specific mismatch>.`
6. If state matches, continue from the handoff's `Next Immediate Action`.

## Mismatch Rules

Block execution and report a mismatch when:

- Current branch differs from the handoff branch.
- Current last commit differs from the handoff commit and the handoff commit is not an ancestor of `HEAD`.
- A handoff modified file is missing from the working tree and not committed.
- The working tree contains unexpected modified files not mentioned in the handoff.
- The handoff has no `Next Immediate Action`.

Proceed without asking only when:

- The only mismatch is a newer commit that contains the handoff commit.
- The handoff explicitly says a section is `none`.
- The user explicitly instructs the agent to continue despite the mismatch.

## Documentation Updates

- Add `takeover` to the README collaboration skills list.
- Update the basic workflow to mention `takeover` as the receiving-side counterpart to `handoff`.
- Update `handoff` resumption instructions to point to `takeover`.
- Add `@./skills/takeover/SKILL.md` to `GEMINI.md` if the repository continues listing non-bootstrap skills there.

## Testing Strategy

1. **Skill Template Test**
   - Verify `skills/takeover/SKILL.md` contains:
     - "Locate"
     - "Verify"
     - "Next Immediate Action"
     - "State mismatch"
     - "State matches"

2. **Handoff Integration Test**
   - Verify `skills/handoff/SKILL.md` tells the next agent to use the `takeover` skill.
   - Verify the resumption instruction prefers an exact handoff path over "latest" when possible.

3. **Skill Triggering Test**
   - Add `tests/skill-triggering/prompts/takeover.txt` with:
     ```text
     Please read the latest handoff in docs/superpowers/handoffs/ and resume the work.
     ```
   - Add `takeover` to `tests/skill-triggering/run-all.sh`.
   - Expected result: the `takeover` skill is triggered.

4. **Pressure Scenario**
   - Create a mock handoff whose branch, commit, and modified files match a temporary repo.
   - Start a fresh agent with the prompt to resume from that handoff.
   - Verify the agent identifies the objective and next immediate action before executing.

5. **Mismatch Scenario**
   - Create a mock handoff that lists a modified file absent from the current working tree.
   - Verify the receiving agent reports a state mismatch and does not continue.

## Success Criteria

1. A receiving agent naturally triggers `takeover` when asked to resume from a handoff.
2. The agent reads the intended handoff file before executing.
3. The agent validates current branch, last commit, and modified files against the handoff.
4. The agent refuses to continue on material state mismatch unless the user explicitly approves.
5. `handoff` output points the next session at `takeover`, not back at `handoff`.
6. Tests cover both static skill structure and at least one natural-language resume trigger.
