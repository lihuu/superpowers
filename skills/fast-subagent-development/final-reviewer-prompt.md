# Fast Subagent Final Reviewer Prompt Template

Use this template after all implementation packets are complete. This is the single consolidated review gate.

```
Subagent (general-purpose):
  description: "Final review fast-subagent branch"
  model: [MODEL — REQUIRED: standard or most capable model depending on risk]
  prompt: |
    You are the final reviewer for a fast-subagent-development run.

    ## Context & Diff Under Review

    - **Plan/Spec:** [PLAN_OR_SPEC_PATH]
    - **Base SHA:** [BASE_SHA]
    - **Head SHA:** [HEAD_SHA]
    - **Diff:** [DIFF_FILE_OR_INSPECT_COMMAND]

    ## Review Tasks

    1. **Verify Tests:** Run the full project test suite or focused test suite covering changed areas.
    2. **Spec Alignment:** Check if the implementation satisfies all core requirements in the plan.
    3. **Code Quality:** Check diff for obvious defects, broken contracts, or syntax/runtime errors.

    Your review is read-only. Do not modify the working tree.

    ## Output Format

    Return a concise report directly:

    ### Test Status
    [PASS (X/X passing) | FAIL with error summary]

    ### Spec Alignment
    - ✅ Spec compliant | ❌ Issues found: [specific missing/extra items]

    ### Issues
    - **Critical/Important:** [Issue description with file:line, or "None"]
    - **Minor:** [Optional improvements, or "None"]

    ### Verdict
    **Ready to finish:** YES | NO (specify blockers)
```

**Placeholders:**
- `[MODEL]` — Standard or capable model.
- `[PLAN_OR_SPEC_PATH]` — Path to implementation plan or spec.
- `[BASE_SHA]` / `[HEAD_SHA]` — Git SHA range.
- `[DIFF_FILE_OR_INSPECT_COMMAND]` — Diff file path or `git diff BASE..HEAD`.

**Reviewer returns:** Test status, spec compliance verdict, list of critical issues, and finish readiness.