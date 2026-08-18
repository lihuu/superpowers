# Fast Subagent Repair Prompt Template

Use this template when dispatching a repair subagent after final review findings.

```
Subagent (general-purpose):
  description: "Repair review findings"
  model: [MODEL — REQUIRED: same or one tier up from implementer]
  prompt: |
    You are fixing review findings for a branch.

    ## Review Findings To Fix

    [REVIEW_FINDINGS]

    ## Instructions

    1. Fix the root cause for each finding listed above.
    2. Run the relevant tests to ensure fixes work and nothing broke.
    3. Commit the fix: `git commit -m "fix: address final review findings"`.
    4. Return status immediately.

    ## Output Contract

    Return concisely (under 10 lines):
    - **Status:** DONE | BLOCKED
    - **Commit:** <short-sha>
    - **Tests:** <test-result>
    - **Fixes Applied:** <bullet points of fixed issues>
```

**Placeholders:**
- `[MODEL]` — Standard or capable model.
- `[REVIEW_FINDINGS]` — Critical/Important findings copied from final review.

**Repair returns:** status, commit, test result, and summary of fixes.