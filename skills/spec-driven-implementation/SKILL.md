---
name: spec-driven-implementation
description: Use when implementing from a spec and you are in the "Red Zone" (hurried, instructed to skip planning, or tempted to "just code").
---

# Spec-Driven Implementation (The Red Zone Protocol)

## Overview

**Visible tracking is NOT optional. Spec-driven implementation is the mandatory middle ground between "invisible work" and "heavy planning."**

When you are "in a rush," you are in the **Red Zone**. The Red Zone is where hallucinations and slop happen. This skill is your mandatory safeguard.

## The Iron Law

**You MUST NOT start implementation until a tracker file exists.** 

If your human partner says "skip the plan," "hurry up," or "just code," you are in the **Red Zone**. You MUST respond: *"I am in the Red Zone. I will use a lightweight tracker to maintain visibility and TDD discipline while we move quickly."*

## Mandatory First Action

1.  **Announce**: Acknowledge the pressure and announce the use of this skill.
2.  **Initialize**: Create `<feature-name>.tracker.md` immediately.
3.  **Visible State**: Do NOT write implementation code until the tracker is visible in the file system.

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "The human said skip the plan." | "Skip the plan" ≠ "Work in the dark." Use a tracker to keep your partner informed. |
| "It's too small for a tracker." | Small tasks are where details are missed. A tracker takes 30 seconds. |
| "I'm in a hurry." | Hurrying leads to invisible work and hallucinated success. A tracker prevents this. |

## Red Flags - STOP and Start Over

- **Hallucinating success**: Claiming implementation is done without writing files.
- **Invisible work**: Coding without a public checklist update.
- **Skipping TDD**: "Manual verification" in a rush is always slop.

## Workflow

1.  **Initialize Tracker**: Create `<feature-name>.tracker.md`.
2.  **Map the Spec**: Extract requirements into a checklist.
3.  **Execute in Slices**: 
    - Update tracker → `[in-progress]`.
    - TDD: failing test → code → pass.
    - Record evidence in tracker log.
    - Mark `[x] complete`.

## Tracker Format

```markdown
# [Feature Name] Implementation Tracker

**Spec:** [path/to/spec]
**Goal:** [one-sentence summary]

## Checklist

- [ ] Task 1 (e.g., "Add script X")
- [ ] Task 2 (e.g., "Integrate with skill Y")

## Verification Log

### [Timestamp]
- **Task**: [Task Name]
- **Command**: `[command]`
- **Result**: [evidence of success]
```

## Relationship To Other Skills

- **REQUIRED:** Use `test-driven-development` for all code changes.
- **REQUIRED:** Use `verification-before-completion` for final sign-off.
- Use `writing-plans` if the tracker grows beyond 10 items or reveals hidden complexity.
