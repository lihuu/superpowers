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
2.  **Locate Spec**: Find the spec file (see Spec Discovery below).
3.  **Initialize**: Create `<feature-name>.tracker.md` immediately, with the spec path filled in.
4.  **Visible State**: Do NOT write implementation code until the tracker is visible in the file system.

## Spec Discovery

The tracker requires a spec. Locate it in this order:

1. **Explicit path**: If the user provided a spec file path, use it directly.
2. **Conventional directory**: Scan `docs/superpowers/specs/` for `*.md` files. If files exist, use the most recent one (filenames use `YYYY-MM-DD` prefix, so lexicographic sort = chronological sort).
3. **No spec found**: STOP. Tell your human partner: *"No spec found. Either provide a spec path, or use the brainstorming skill first to create one."* Do NOT proceed without a spec.

```bash
# Discovery command (step 2):
ls -1 docs/superpowers/specs/*.md 2>/dev/null | sort -r | head -1
```

**Never** guess, hallucinate, or fabricate a spec path. If discovery fails, escalate.

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

1.  **Locate Spec**: Run Spec Discovery (above) to find the spec file.
2.  **Initialize Tracker**: Create `<feature-name>.tracker.md` with the discovered spec path.
3.  **Extract Implementation Context**: Resolve `spec-sections` relative to the brainstorming skill directory and run:

```bash
SPEC_SECTIONS="<brainstorming-skill-directory>/spec-sections"
LEGACY_POLICY="${SUPERPOWERS_SPEC_LEGACY_POLICY:-reject}"
# Equivalent CLI: spec-sections implementation <spec>
"$SPEC_SECTIONS" --legacy "$LEGACY_POLICY" implementation "$SPEC_PATH" > /tmp/implementation-spec.md
```

4.  **Map the Spec**: Read `/tmp/implementation-spec.md` and extract its requirements into a checklist. Do not read the original spec file or include Acceptance content in the tracker.
5.  **Record Diff Base**: Before implementation, run `BASE_SHA=$(git rev-parse HEAD)` and record it in the tracker.
6.  **Execute in Slices**:
    - Update tracker → `[in-progress]`.
    - TDD: failing test → code → pass.
    - Record evidence in tracker log.
    - Mark `[x] complete`.
7.  **Independent Acceptance**: Use `superpowers:acceptance-review` to perform independent acceptance verification. It extracts Implementation Spec and Acceptance regions separately, dispatches a fresh reviewer, and runs a minimal repair loop for any failures. Do not collapse the stages into one context.

## Tracker Format

```markdown
# [Feature Name] Implementation Tracker

**Spec:** [auto-discovered path from Spec Discovery, or user-provided path]
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
- **REQUIRED:** Use `acceptance-review` for independent acceptance verification after implementation.
- Use `writing-plans` if the tracker grows beyond 10 items or reveals hidden complexity.
