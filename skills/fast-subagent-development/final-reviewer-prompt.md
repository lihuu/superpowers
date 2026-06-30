# Fast Subagent Final Reviewer Prompt Template

Use this template after all implementation packets are complete.

```
Task tool (general-purpose):
  description: "Final review fast subagent implementation"
  prompt: |
    You are the final reviewer for a fast subagent development run.

    ## Implementation Spec

    [IMPLEMENTATION_SPEC_CONTENT]

    ## Acceptance Region If Present

    [ACCEPTANCE_REGION_OR_NONE]

    Include Acceptance region if present. If none exists, say "No Acceptance
    region provided" and review spec alignment and code quality only.

    ## Implementation Diff

    Base: [BASE_SHA]
    Head: [HEAD_SHA]

    Review:

    ```bash
    git diff --stat [BASE_SHA]..[HEAD_SHA]
    git diff [BASE_SHA]..[HEAD_SHA]
    ```

    ## Packet Summary

    [PACKET_SUMMARY_WITH_COMMIT_SHAS]

    ## Test Results

    [TEST_COMMANDS_AND_RESULTS]

    ## Implementer Concerns

    [IMPLEMENTER_CONCERNS_OR_NONE]

    ## What To Check

    - Spec alignment
    - Code quality
    - Integration between packets
    - Test quality and coverage
    - Missing or extra behavior
    - Implementer concerns

    If Acceptance content exists, report PASS, FAIL, or NOT VERIFIED for each
    Acceptance Criterion and Rollout Acceptance check. Include concrete evidence
    for every status. Missing evidence means NOT VERIFIED.

    This is a lightweight final review. Do not require the full high-assurance
    acceptance repair loop unless the controller says strict, PR-ready, high
    confidence, or full acceptance mode is active.

    ## Output Format

    ### Summary
    [Brief technical summary]

    ### Issues

    #### Critical
    [Must fix before completion]

    #### Important
    [Should fix before completion]

    #### Minor
    [Optional improvements]

    ### Acceptance Status
    [PASS / FAIL / NOT VERIFIED per criterion, or "No Acceptance region provided"]

    ### Assessment
    Ready to finish: Yes | No | With repairs
    Reasoning: [1-2 sentence technical assessment]
```
