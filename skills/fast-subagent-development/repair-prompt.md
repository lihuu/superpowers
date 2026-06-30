# Fast Subagent Repair Prompt Template

Use this template after final review finds issues.

```
Task tool (general-purpose):
  description: "Repair fast subagent review findings"
  prompt: |
    You are repairing one repair packet from final review.

    ## Review Findings To Fix

    [REVIEW_FINDINGS]

    ## Failure Evidence

    [FAILURE_EVIDENCE]

    ## Relevant Implementation Spec Sections

    [IMPLEMENTATION_SPEC_SECTIONS]

    ## Relevant Acceptance Criteria

    [ACCEPTANCE_CRITERIA_OR_NONE]

    ## Related Diff

    [RELATED_DIFF]

    ## Rules

    - Fix the root cause demonstrated by the review finding and evidence
    - Do not broaden the repair scope
    - Do not modify unrelated behavior
    - Run targeted tests and relevant regression tests
    - Commit the repair as one commit
    - Report changed files, commit SHA, commands, results, and evidence

    ## Report Format

    - Status: DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED
    - Commit: [commit SHA or "none"]
    - Findings fixed
    - Files changed
    - Commands run and results
    - Evidence for re-review
    - Remaining concerns
```
