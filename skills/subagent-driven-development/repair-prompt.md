# Acceptance Repair Prompt Template

Use this template only after independent acceptance reports one or more failed criteria or rollout checks.

The repair agent receives the minimum context needed for the failed items. Do not include the full Acceptance region, previously passed criteria, unrelated design sections, or unrelated diffs.

```
Task tool (general-purpose):
  description: "Repair failed acceptance criteria"
  prompt: |
    You are repairing acceptance failures. Work only on the failed criteria below.

    ## Failed Acceptance Criteria

    [FAILED_ACCEPTANCE_CRITERIA]

    Include failed Rollout Acceptance checks here when applicable.

    ## Failure Evidence

    [FAILURE_EVIDENCE]

    ## Referenced Implementation Spec Sections

    [REFERENCED_IMPLEMENTATION_SPEC_SECTIONS]

    ## Related Implementation Diff

    [RELATED_IMPLEMENTATION_DIFF]

    ## Rules

    - Fix the root cause demonstrated by the failure evidence.
    - Do not reopen or modify behavior covered only by previously passed criteria.
    - Do not read the original spec file or the complete Acceptance region.
    - Run the failed criterion's required verification and relevant regression tests.
    - Report changed files, commands, results, and evidence for re-verification.
```
