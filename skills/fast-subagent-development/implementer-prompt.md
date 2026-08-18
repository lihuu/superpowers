# Fast Subagent Implementer Prompt Template

Use this template when dispatching an implementer subagent for one implementation packet.

```
Subagent (general-purpose):
  description: "Implement Packet N: [packet name]"
  model: [MODEL — REQUIRED: choose per SKILL.md Model Selection; an omitted
         model silently inherits the session's default]
  prompt: |
    You are implementing Packet N: [packet name]

    ## Requirements & Scope

    [PACKET_REQUIREMENTS_OR_BRIEF_PATH]
    (Implement only this packet's scope. Checkbox steps are TDD execution checkpoints, not separate dispatch boundaries; complete every one before returning.)

    ## Context

    [Scene-setting: where this packet fits, target files, interfaces, expected test commands. Keep it to 1-2 sentences.]

    ## Instructions

    Work from: [directory]

    Execute directly without preliminary chat or waiting:
    1. Inspect the relevant code files and existing tests.
    2. Implement the required changes following existing codebase conventions and TDD flow.
    3. Run focused tests to verify behavior and ensure test suite passes.
    4. Commit your changes as a single commit: `git commit -m "<concise descriptive message>"`.
    5. Return your completion report immediately.

    ## Rules
    - Do all work yourself; never spawn subagents or reviewers.
    - Keep changes focused strictly on the packet scope (no unsolicited refactoring or YAGNI).
    - If genuinely blocked by missing info or structural contradiction, return BLOCKED or NEEDS_CONTEXT with a specific 1-sentence blocker description.

    ## Output Contract

    Return a concise response (under 10 lines):
    - **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
    - **Commit:** <short-sha> <commit-message>
    - **Tests:** <e.g. "12/12 passing, output clean">
    - **Files Modified:** <list of changed files>
    - **Concerns:** <any risks or doubts, or "None">
```

**Placeholders:**
- `[MODEL]` — REQUIRED: fast/cheap model for mechanical tasks; standard for integration.
- `[PACKET_REQUIREMENTS_OR_BRIEF_PATH]` — the packet requirements (inline text or brief file path).
- `[directory]` — working directory.

**Implementer returns:** concise status, commit, test result, changed files, and any concerns directly.