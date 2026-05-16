---
name: handoff
description: Use when you need to hand off the current task, especially when hitting token limits, context saturation, or preparing for session expiration.
---

# Handoff

## Overview

Capture your current progress, reasoning, and pending tasks into a human-readable Markdown file to ensure a seamless transition between sessions or agents.

## When to Use
- You are hitting context limits and need a fresh session.
- You need to pass the work to a human or another specialized agent.
- You are stopping for the day and want to ensure a clean resumption.

## Quick Reference

| Item | Path / Command |
| :--- | :--- |
| **Gather Script** | `bash skills/handoff/scripts/gather-state.sh .` |
| **Handoff Directory** | `docs/superpowers/handoffs/` |
| **Filename Format** | `YYYY-MM-DD-<feature>-handoff.md` |

## The Process

1. **Gather Automated State:** Run `bash skills/handoff/scripts/gather-state.sh .` to get git and file info.
2. **Draft the Summary:**
   - **Current Objective:** What were you just trying to do?
   - **Work Completed:** List specific steps finished.
   - **Pending Tasks:** List exactly what remains in the plan/TODO.
   - **Mental State:** Document your current reasoning, blockers, and "gotchas".
3. **Save the Handoff:**
   - Create the directory if it doesn't exist: `docs/superpowers/handoffs/`
   - Save to: `docs/superpowers/handoffs/YYYY-MM-DD-<feature>-handoff.md`
4. **Resumption Instruction:** End your session by telling the user:
   > "I have performed a handoff. Please tell the next agent: 'Read the latest handoff in docs/superpowers/handoffs/ and resume work.'"

## Common Mistakes

- **Omitting "Mental State":** Forgetting to document the "why" behind decisions, leaving the next agent to guess your reasoning.
- **Forgetting Modified Files:** Not explicitly listing files you've changed but haven't committed.
- **Outdated Task Status:** Failing to update the task status or TODO list before generating the handoff.
- **Vague Next Steps:** Leaving the "Next Immediate Action" unclear, causing the next agent to waste time re-orienting.

## For the Receiving Agent

When you see a resumption instruction:
1. **Announce:** "I am resuming work from the latest handoff in docs/superpowers/handoffs/".
2. **Read:** Locate the most recent file in `docs/superpowers/handoffs/` and read it.
3. **Sync:** Update your internal task list and verify modified files.
4. **Execute:** Continue from the "Next Immediate Action" in the handoff.
