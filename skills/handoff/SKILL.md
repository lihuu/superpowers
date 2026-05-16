---
name: handoff
description: Use when you need to hand off the current task to another agent or session.
---

# Handoff

Capture your current progress, reasoning, and pending tasks into a human-readable Markdown file.

## When to Use
- You are hitting context limits and need a fresh session.
- You need to pass the work to a human or another specialized agent.
- You are stopping for the day and want to ensure a clean resumption.

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

## For the Receiving Agent

When you see a resumption instruction:
1. **Announce:** "I am resuming work from the latest handoff in docs/superpowers/handoffs/".
2. **Read:** Locate the most recent file in `docs/superpowers/handoffs/` and read it.
3. **Sync:** Update your internal task list and verify modified files.
4. **Execute:** Continue from the "Next Immediate Action" in the handoff.
