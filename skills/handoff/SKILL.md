---
name: handoff
description: Use when you need to hand off the current task, especially when hitting token limits, context saturation, or preparing for session expiration.
---

# Handoff

## Overview

Capture the current objective, reasoning, workspace state, and next action into a human-readable Markdown file so another agent can continue without reconstructing the session from raw chat history.

## When to Use
- You are hitting context limits and need a fresh session.
- You need to pass the work to a human or another specialized agent.
- You are stopping for the day and want to ensure a clean resumption.
- The user asks for a handoff, transfer, continuation note, or session summary for another agent.

## Quick Reference

| Item | Path / Command |
| :--- | :--- |
| **Gather Script** | `bash skills/handoff/scripts/gather-state.sh .` |
| **Handoff Directory** | `docs/superpowers/handoffs/` |
| **Filename Format** | `YYYY-MM-DD-<feature>-handoff.md` |

## The Process

1. **Choose Mode:**
   - **Default to Rich Handoff** when the user asks for a normal handoff, transfer, or continuation note.
   - **Use Emergency Handoff only** when the user explicitly says context, tokens, quota, time, or remaining budget is too low for a normal handoff.
   - Do not ask which mode to use unless the user's instruction is contradictory. Asking wastes the same scarce budget the handoff is meant to preserve.
2. **Gather Automated State:** For Rich Handoff, run `bash skills/handoff/scripts/gather-state.sh .` to get git and file info. For Emergency Handoff, run it only if doing so will not prevent completing the handoff.
3. **Draft the Summary:**
   - **Current Objective:** What were you just trying to do?
   - **Decision State:** What decisions were made, rejected, or still open, and why.
   - **What Was Tried:** Commands, files, investigations, and failed paths that matter for the next agent.
   - **Work Completed:** List specific steps finished.
   - **Pending Tasks:** List exactly what remains in the plan/TODO.
   - **Mental State:** Document your current reasoning, blockers, and "gotchas".
   - **Source Transcript:** Link or name the source conversation/session if available; write `unknown` if not.
   - Use the Handoff Template below. Do not omit sections; write `none` when a section has no content.
4. **Save the Handoff:**
   - Create the directory if it doesn't exist: `docs/superpowers/handoffs/`
   - Save to: `docs/superpowers/handoffs/YYYY-MM-DD-<feature>-handoff.md`
5. **Resumption Instruction:** End your session by telling the user:
   > "I have performed a handoff. Please tell the next agent: 'Use the takeover skill to read docs/superpowers/handoffs/<exact-handoff-file>.md and resume work.'"

## Handoff Template

```markdown
# Task Handoff: [Feature/Task Name]

- **Date:** YYYY-MM-DD
- **Source Agent:** [Agent/model name or unknown]
- **Current Branch:** `[branch from gather-state]`
- **Last Commit:** `[short SHA or none]`
- **Handoff File:** `docs/superpowers/handoffs/YYYY-MM-DD-<feature>-handoff.md`

## Current Objective
[One sentence describing the user-visible goal.]

## Decision State
- **Chosen Approach:** [What approach is currently being followed and why.]
- **Rejected Alternatives:** [Approaches considered and why they were rejected, or `none`.]
- **Open Decisions:** [Decisions still unresolved, or `none`.]

## What Was Tried
- **Commands Run:** [Important commands and results, or `none`.]
- **Files Inspected:** [Important files and what was learned, or `none`.]
- **Dead Ends:** [Failed paths the next agent should not repeat, or `none`.]

## Work Completed
- [x] [Specific completed step]

## Pending Tasks
1. **Next Immediate Action:** [Exact next command, file edit, or decision the receiving agent should take.]
2. **Remaining Steps:**
   - [ ] [Specific remaining step]

## Modified Files
- `[path]`: [What changed and whether it is staged, unstaged, or untracked.]

## Git State
[Paste the output from `bash skills/handoff/scripts/gather-state.sh .`.]

## Mental State & Blockers
- **Reasoning:** [Why this approach was chosen.]
- **Blockers:** [Current issues, or `none`.]
- **Gotchas:** [Risks, assumptions, or `none`.]

## Source Transcript
- **Source:** [Codex thread/session/path or `unknown`.]
- **Use For:** Evidence only. The receiving agent should read this only if the handoff is incomplete, state verification fails, or more detail is needed.
```

## Emergency Handoff Template

Use this only when the user explicitly indicates low remaining quota, low context, low time, or asks for a quick/emergency handoff. Prefer a short complete handoff over a long partial one.

```markdown
# Emergency Task Handoff: [Feature/Task Name]

- **Date:** YYYY-MM-DD
- **Source Agent:** [Agent/model name or unknown]
- **Current Branch:** `[known branch or unknown]`
- **Last Commit:** `[known short SHA or unknown]`
- **Handoff File:** `docs/superpowers/handoffs/YYYY-MM-DD-<feature>-handoff.md`

## Current Objective
[One sentence describing the goal.]

## Done
- [Specific completed work, or `none`.]

## Current State
- **Modified Files:** [Known changed files, or `unknown`.]
- **Tests/Commands:** [Important commands and results, or `unknown`.]

## Next Immediate Action
[The next best command, file edit, or decision.]

## Risks / Gotchas
- [Important blocker, assumption, or risk, or `none`.]

## Source Transcript
- **Source:** [Codex thread/session/path or `unknown`.]
- **Use For:** Evidence only if the receiving agent needs more detail.
```

## Common Mistakes

- **Omitting "Mental State":** Forgetting to document the "why" behind decisions, leaving the next agent to guess your reasoning.
- **Forgetting Modified Files:** Not explicitly listing files you've changed but haven't committed.
- **Outdated Task Status:** Failing to update the task status or TODO list before generating the handoff.
- **Vague Next Steps:** Leaving the "Next Immediate Action" unclear, causing the next agent to waste time re-orienting.
- **Defaulting to Emergency:** Emergency Handoff is a fallback for scarce remaining budget, not the normal mode.
- **Treating transcripts as the handoff:** Raw chat history is evidence. The handoff is the execution entry point.

## For the Receiving Agent

When you see a resumption instruction:
1. **Announce:** "I am taking over from <handoff-path>."
2. **Read:** Prefer the exact handoff path in the instruction. Use the latest file in `docs/superpowers/handoffs/` only if no exact path was provided.
3. **Sync:** Update your internal task list and verify modified files.
4. **Execute:** Continue from the "Next Immediate Action" in the handoff.
