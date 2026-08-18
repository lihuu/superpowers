---
name: takeover
description: Use when taking over existing work, resuming from a handoff file, continuing an interrupted session, or inheriting a partially completed task.
---

# Takeover

## Overview

Take over partially completed work by locating the existing context, verifying the current workspace state, and resuming only when the next action is grounded in that evidence.

## When to Use

- You are asked to resume from a handoff file.
- You are taking over work from another agent or session.
- The user says to continue interrupted work, pick up where another agent left off, or read the latest handoff.
- The workspace already has modified files and the next step is not obvious.

## Quick Reference

| Situation | Action |
| :--- | :--- |
| User provides a handoff path | Read that file first |
| No path is provided | Find the newest Markdown file in `docs/superpowers/handoffs/` |
| Handoff references a transcript | Treat it as evidence, not the primary handoff |
| No handoff exists but transcript exists | Use Transcript Fallback |
| Handoff state matches workspace | Resume from `Next Immediate Action` |
| State differs materially | Report `State mismatch` and wait for confirmation |

## Locate Context

1. Prefer an explicit handoff path from the user's message.
2. If no path was provided, locate the newest `*.md` file in `docs/superpowers/handoffs/`.
3. If no handoff exists but the user provided a raw transcript, conversation, or session path, use Transcript Fallback.
4. If no handoff or transcript exists, inspect `git status --short`, recent commits, active specs/plans, and ask the user what context to use before executing.
5. Announce: `I am taking over from <handoff-path>.`

## Read Handoff

Read the handoff before executing. Extract:

- Current objective
- Decision state
- What was tried
- Work completed
- Pending tasks
- `Next Immediate Action`
- Modified files
- Git state
- Mental state and blockers
- Source transcript, if present

If the handoff has no `Next Immediate Action`, report `State mismatch` and ask for confirmation before continuing.

## Transcript Fallback

Do not read raw transcripts first when a handoff file is available. Raw transcripts are evidence, not the execution entry point.

Use Transcript Fallback only when:

- No handoff file exists.
- The handoff is incomplete and points to a transcript.
- State verification fails and the transcript may explain the mismatch.
- The user explicitly instructs you to reconstruct the handoff from the original conversation.

When using Transcript Fallback:

1. Read only the transcript sections needed to reconstruct the current objective, completed work, decisions, modified files, blockers, and next action.
2. Build a temporary handoff summary in your working context before executing.
3. Run workspace-state verification.
4. Resume only after the reconstructed next action is grounded in both transcript evidence and current workspace state.

## Verify Workspace State

Run current-state verification before resuming:

```bash
git status --short
git rev-parse --abbrev-ref HEAD
git rev-parse --short HEAD
git log -n 3 --oneline
```
(Or run `bash skills/handoff/scripts/gather-state.sh .` if available.)

Compare the current state to the handoff:

- Current branch matches the handoff branch.
- Current last commit matches the handoff commit, or the handoff commit is an ancestor of `HEAD`.
- Handoff modified files still exist as modified, staged, untracked, or committed.
- Current modified files are consistent with the handoff.

## Resume Work

After verification, report exactly one status:

- `State matches. Resuming from: <next immediate action>.`
- `State mismatch. I need confirmation before continuing: <specific mismatch>.`

If state matches, reconstruct your task list from `Pending Tasks` and continue from the handoff's `Next Immediate Action` (or the first item under `Pending Tasks` if not explicitly specified).

## State Mismatch Rules

Block execution and report `State mismatch` only when:

- Current branch differs from the handoff branch.
- Current last commit differs from the handoff commit and the handoff commit is not an ancestor of `HEAD`.
- A handoff modified source file is missing from the working tree and not committed.
- The working tree contains unexpected modified source/business logic files that conflict with the handoff scope (ignore innocuous IDE files, `.DS_Store`, log files, or build caches).

Proceed without asking when:

- The only mismatch is a newer commit that contains the handoff commit.
- Unmentioned files are non-source temporary files, caches, or logs.
- The handoff explicitly says a section is `none`.
- The user explicitly instructs you to continue despite the mismatch.

## Common Mistakes

- **Trusting the handoff blindly:** Always verify the workspace before executing.
- **Using "latest" when a path is available:** Prefer the exact handoff file named by the user.
- **Reading transcripts first:** Do not read raw transcripts first when a handoff exists; use them only to resolve gaps or mismatches.
- **Skipping mismatch details:** Name the exact branch, commit, or file discrepancy.
- **Re-brainstorming the task:** Takeover resumes existing work; it does not restart design unless the handoff is unusable.
