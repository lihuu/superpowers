# Fast Subagent Implementer Prompt Template

Use this template when dispatching an implementer subagent for one implementation packet.

```
Task tool (general-purpose):
  description: "Implement packet: [packet name]"
  prompt: |
    You are implementing exactly one implementation packet.

    ## Implementation Spec Context

    [IMPLEMENTATION_SPEC_CONTENT]

    This content was mechanically extracted from the Implementation Spec region.
    Acceptance content must not be provided to an initial implementation agent.

    ## Implementation Packet

    [FULL PACKET TEXT]

    This is the complete implementation packet. Complete every checkbox step inside the packet before reporting DONE.
    Checkbox steps are TDD execution checkpoints, not separate dispatch boundaries.

    ## Context

    [Relevant architecture, dependencies, file ownership, and test commands]

    ## Your Job

    Once requirements are clear:
    1. Follow the packet's TDD sequence
    2. Implement only this packet's scope
    3. Run relevant tests
    4. Commit this packet as one commit
    5. Report status, changed files, commit SHA, commands run, and concerns

    Do not create one commit per checkbox microstep. The commit message should
    describe the packet outcome.

    ## Ask Before Implementing If

    - Requirements conflict
    - The packet boundary is too large or too small
    - Required context is missing
    - The implementation needs files outside the packet's stated scope
    - You see a risk that should change execution order

    ## Status Values

    - DONE: packet implemented, tested, and committed
    - DONE_WITH_CONCERNS: packet committed but concerns remain
    - NEEDS_CONTEXT: missing information prevents safe implementation
    - BLOCKED: cannot proceed without changing plan, packet boundary, model capability, or user decision

    ## Report Format

    - Status: DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED
    - Commit: [commit SHA or "none"]
    - Files changed
    - Commands run and results
    - What was implemented
    - Concerns or blockers
```
