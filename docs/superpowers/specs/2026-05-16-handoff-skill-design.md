# Design Spec: Task Handoff Skill

**Date:** 2026-05-16
**Status:** Draft
**Goal:** Enable seamless task handoff between agents when a session needs to be manually reassigned or interrupted.

## Overview

The `handoff` skill provides a structured way for an agent to capture its current progress, reasoning, and pending tasks into a human-readable Markdown file. This file acts as a "baton" that another agent can pick up in a fresh session to continue the work without loss of context or redundant exploration.

## Architecture

The skill follows a simple "Snapshot and Resume" architecture:

1. **Snapshot Phase (Source Agent):**
   - Triggered by user command or internal decision to handoff.
   - Gathers Git state (staged/unstaged changes, last commit).
   - Extracts task progress from `TODO.md` or session memory.
   - Summarizes "Mental State" (reasoning, blockers, gotchas).
   - Saves to `docs/superpowers/handoffs/YYYY-MM-DD-<feature>-handoff.md`.
   - Emits a "Resumption Command" for the user.

2. **Resumption Phase (Target Agent):**
   - Triggered by the user providing the Resumption Command.
   - **Announcement:** Agent says "I am resuming work from the latest handoff in docs/superpowers/handoffs/".
   - Reads the latest handoff file.
   - Syncs internal state (tasks, modified files).
   - Continues execution.

## Handoff Template

The generated file will follow this format:

```markdown
# Task Handoff: [Feature/Task Name]

- **Date:** YYYY-MM-DD
- **Previous Agent:** [Model Name]
- **Current Branch:** `feature-name`
- **Last Commit:** `abc1234`

## 🎯 Current Objective
[One-sentence summary of the goal]

## ✅ Work Completed
- [x] Step 1: [Description]
- [x] Step 2: [Description]

## 🚧 Pending Tasks
1. **Next Immediate Action:** [Detailed description of the next step]
2. **Remaining Steps:**
   - [ ] [Task A]
   - [ ] [Task B]

## 📂 Modified Files
- `path/to/file1`: [Change summary]
- `path/to/file2`: [Change summary]

## 🧠 Mental State & Blockers
- **Reasoning:** [Why this approach was taken]
- **Blockers:** [Current SNAGS or issues]
- **Gotchas:** [Things to be careful of]
```

## Implementation Details

- **Skill Name:** `handoff`
- **Trigger:** "I am performing a handoff to another agent."
- **Storage Path:** `docs/superpowers/handoffs/` (parallel to `specs` and `plans`).
- **Resumption Command:** `"Please read the latest handoff in docs/superpowers/handoffs/ and resume the work."`

## Success Criteria

1. The handoff file is correctly generated with all required sections.
2. The file is saved in the correct directory with a timestamped name.
3. A second agent, when given the resumption command, can accurately describe the state and the next step without further research.
4. Git state in the handoff matches the actual file system state.

## Testing Strategy

1. **Generation Test:** Run the `handoff` skill in a mock project and verify the Markdown file content.
2. **Resumption Test (Pressure Scenario):**
   - Start a task, modify a file, then run `handoff`.
   - Start a fresh session with a different agent.
   - Give the resumption command.
   - Verify the second agent identifies the modified file and correctly states the next task.
