---
name: requesting-code-review
description: Use when completing tasks, implementing major features, or before merging to verify work meets requirements
---

# Requesting Code Review

Dispatch a code reviewer subagent to catch issues before they cascade. The reviewer gets precisely crafted context for evaluation — never your session's history. This keeps the reviewer focused on the work product, not your thought process, and preserves your own context for continued work.

**Core principle:** Review early, review often.

## When to Request Review

**Mandatory:**
- After each task in subagent-driven development
- After completing major feature
- Before merge to main

**Optional but valuable:**
- When stuck (fresh perspective)
- Before refactoring (baseline check)
- After fixing complex bug

## How to Request

**1. Prepare staged requirements when a Spec exists:**

Resolve `spec-sections` relative to the brainstorming skill directory. Extract to files so validation completes before any spec content is loaded:

```bash
SPEC_SECTIONS="<brainstorming-skill-directory>/spec-sections"
LEGACY_POLICY="${SUPERPOWERS_SPEC_LEGACY_POLICY:-reject}"
"$SPEC_SECTIONS" --legacy "$LEGACY_POLICY" implementation "$SPEC_PATH" > /tmp/review-implementation.md
# Equivalent CLI: spec-sections acceptance <spec>
"$SPEC_SECTIONS" --legacy "$LEGACY_POLICY" acceptance "$SPEC_PATH" > /tmp/review-acceptance.md
```

Do not read the original spec file. If either extraction fails, stop without dispatching review.

If no Spec exists, use the supplied plan/requirements as the Implementation Spec input and set the Acceptance Contract to `Not provided: code quality review only`. The reviewer may assess quality and requirement alignment but must not claim formal acceptance.

**2. Get git SHAs, diff, and fresh test results:**
```bash
BASE_SHA=$(git rev-parse HEAD~1)  # or origin/main
HEAD_SHA=$(git rev-parse HEAD)
git diff "$BASE_SHA..$HEAD_SHA" > /tmp/review.diff
<project test command> > /tmp/review-tests.txt 2>&1
```

**3. Dispatch code reviewer subagent:**

Dispatch a `general-purpose` subagent, filling the template at [code-reviewer.md](code-reviewer.md)

**Placeholders:**
- `{DESCRIPTION}` - Brief summary of what you built
- `{IMPLEMENTATION_SPEC}` - Complete extracted Implementation Spec, or explicit plan/requirements when no Spec exists
- `{ACCEPTANCE_CONTRACT}` - Complete extracted Acceptance region, or the no-formal-acceptance notice
- `{IMPLEMENTATION_DIFF}` - Actual diff content
- `{TEST_RESULTS}` - Fresh test command and output
- `{BASE_SHA}` - Starting commit
- `{HEAD_SHA}` - Ending commit

Populate the template in its defined order: Implementation Spec, Acceptance Contract, Implementation Diff, Test Results.

**4. Act on feedback:**
- Fix Critical issues immediately
- Fix Important issues before proceeding
- Note Minor issues for later
- Push back if reviewer is wrong (with reasoning)
- For failed Acceptance Criteria, use the minimal repair packet from subagent-driven-development/repair-prompt.md rather than sending the whole Acceptance region to the repair agent

## Example

```
[Just completed Task 2: Add verification function]

You: Let me request code review before proceeding.

BASE_SHA=$(git log --oneline | grep "Task 1" | head -1 | awk '{print $1}')
HEAD_SHA=$(git rev-parse HEAD)

[Dispatch code reviewer subagent]
  DESCRIPTION: Added verifyIndex() and repairIndex() with 4 issue types
  IMPLEMENTATION_SPEC: Extracted design requirements for Task 2
  ACCEPTANCE_CONTRACT: Extracted completion contract
  IMPLEMENTATION_DIFF: git diff a7981ec..3df7661
  TEST_RESULTS: pytest -q (18 passed)
  BASE_SHA: a7981ec
  HEAD_SHA: 3df7661

[Subagent returns]:
  Strengths: Clean architecture, real tests
  Issues:
    Important: Missing progress indicators
    Minor: Magic number (100) for reporting interval
  Assessment: Ready to proceed

You: [Fix progress indicators]
[Continue to Task 3]
```

## Integration with Workflows

**Subagent-Driven Development:**
- Review after EACH task
- Catch issues before they compound
- Fix before moving to next task

**Executing Plans:**
- Review after each task or at natural checkpoints
- Get feedback, apply, continue

**Ad-Hoc Development:**
- Review before merge
- Review when stuck

## Red Flags

**Never:**
- Skip review because "it's simple"
- Ignore Critical issues
- Proceed with unfixed Important issues
- Argue with valid technical feedback

**If reviewer wrong:**
- Push back with technical reasoning
- Show code/tests that prove it works
- Request clarification

See template at: [code-reviewer.md](code-reviewer.md)
