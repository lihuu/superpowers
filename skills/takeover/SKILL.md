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
| Handoff state matches workspace | Resume from `Next Immediate Action` |
| State differs materially | Report `State mismatch` and wait for confirmation |

## Locate Context

1. Prefer an explicit handoff path from the user's message.
2. If no path was provided, locate the newest `*.md` file in `docs/superpowers/handoffs/`.
3. If no handoff exists, inspect `git status --short`, recent commits, active specs/plans, and ask the user what context to use before executing.
4. Announce: `I am taking over from <handoff-path>.`

## Read Handoff

Read the handoff before executing. Extract:

- Current objective
- Work completed
- Pending tasks
- `Next Immediate Action`
- Modified files
- Git state
- Mental state and blockers

If the handoff has no `Next Immediate Action`, report `State mismatch` and ask for confirmation before continuing.

## Verify Workspace State

Run current-state verification before resuming:

```bash
bash skills/handoff/scripts/gather-state.sh .
```

If that script is unavailable, fall back to:

```bash
git status --short
git rev-parse --abbrev-ref HEAD
git rev-parse --short HEAD
```

Compare the current state to the handoff:

- Current branch matches the handoff branch.
- Current last commit matches the handoff commit, or the handoff commit is an ancestor of `HEAD`.
- Handoff modified files still exist as modified, staged, untracked, or committed.
- Current modified files are mentioned in the handoff.

## Resume Work

After verification, report exactly one status:

- `State matches. Resuming from: <next immediate action>.`
- `State mismatch. I need confirmation before continuing: <specific mismatch>.`

If state matches, reconstruct your task list from `Pending Tasks` and continue from the handoff's `Next Immediate Action`.

## State Mismatch Rules

Block execution and report `State mismatch` when:

- Current branch differs from the handoff branch.
- Current last commit differs from the handoff commit and the handoff commit is not an ancestor of `HEAD`.
- A handoff modified file is missing from the working tree and not committed.
- The working tree contains unexpected modified files not mentioned in the handoff.
- The handoff has no `Next Immediate Action`.

Proceed without asking only when:

- The only mismatch is a newer commit that contains the handoff commit.
- The handoff explicitly says a section is `none`.
- The user explicitly instructs you to continue despite the mismatch.

## Common Mistakes

- **Trusting the handoff blindly:** Always verify the workspace before executing.
- **Using "latest" when a path is available:** Prefer the exact handoff file named by the user.
- **Skipping mismatch details:** Name the exact branch, commit, or file discrepancy.
- **Re-brainstorming the task:** Takeover resumes existing work; it does not restart design unless the handoff is unusable.
