---
name: executing-plans
description: Use when you have a written implementation plan to execute in a separate session with review checkpoints
---

# Executing Plans

## Overview

Load plan, review critically, execute all tasks, report when complete.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

**Note:** Tell your human partner that Superpowers works much better with access to subagents. The quality of its work will be significantly higher if run on a platform with subagent support (Claude Code, Codex CLI, Codex App, Copilot CLI, and Gemini CLI all qualify; see the per-platform tool refs in `../using-superpowers/references/`). If subagents are available, use superpowers:subagent-driven-development instead of this skill.

## The Process

### Step 1: Load and Review Plan
1. Read plan file
2. Review critically - identify any questions or concerns about the plan
3. If concerns: Raise them with your human partner before starting
4. If no concerns: Create todos for the plan items and proceed

### Step 2: Execute Tasks

For each task:
1. Mark as in_progress
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. Mark as completed

### Step 3: Independent Acceptance

After implementation tasks and their tests finish, do not complete the branch yet.

1. Extract fresh review inputs:

```bash
# Equivalent CLIs:
# spec-sections implementation <spec>
# spec-sections acceptance <spec>
"$SPEC_SECTIONS" --legacy "$LEGACY_POLICY" implementation "$SPEC_PATH" > /tmp/review-implementation.md
"$SPEC_SECTIONS" --legacy "$LEGACY_POLICY" acceptance "$SPEC_PATH" > /tmp/review-acceptance.md
git diff "$BASE_SHA..HEAD" > /tmp/review.diff
<project test command> > /tmp/review-tests.txt 2>&1
```

2. Use requesting-code-review with a fresh reviewer. Load complete Implementation Spec, complete Acceptance, diff, then tests in that order.
3. Require PASS, FAIL, or NOT VERIFIED with required evidence for every criterion and Rollout Acceptance check.
4. For failures, create a fresh repair context containing only failed criteria, failure evidence, referenced Implementation Spec sections, and related diff. If the platform cannot provide a fresh agent/session, stop and hand off this minimal packet; do not repair in the acceptance reviewer's full context.
5. Re-verify failed criteria. Keep passed criteria closed unless affected by the repair.
6. After targeted failures pass, freshly extract both complete regions and rerun every Acceptance Criterion and Rollout Acceptance check. Continue only when all are PASS.

### Step 4: Complete Development

After all tasks complete and verified:
- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SUB-SKILL:** Use superpowers:finishing-a-development-branch
- Follow that skill to verify tests, present options, execute choice

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.**

## When to Revisit Earlier Steps

**Return to Review (Step 1) when:**
- Partner updates the plan based on your feedback
- Fundamental approach needs rethinking

**Don't force through blockers** - stop and ask.

## Remember
- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Do not replace independent acceptance with task tests
- Reference skills when plan says to
- Stop when blocked, don't guess
- Never start implementation on main/master branch without explicit user consent

## Integration

**Required workflow skills:**
- **superpowers:using-git-worktrees** - Ensures isolated workspace (creates one or verifies existing)
- **superpowers:writing-plans** - Creates the plan this skill executes
- **superpowers:finishing-a-development-branch** - Complete development after all tasks
