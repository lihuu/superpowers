---
name: fast-subagent-development
description: Use when executing an existing implementation plan quickly with isolated subagent worker and consolidated final review
---

# Fast Subagent Development

Execute an implementation plan with **one dedicated implementer subagent for the whole plan**, followed by **one consolidated final review**. This combines the warm-context execution speed of `executing-plans` with the clean context isolation and independent review safety of subagents.

**Core principle:** Single-Worker Whole-Plan Execution + Consolidated Final Review = Maximum speed + Context isolation + Automated 2nd-eye review.

Use `subagent-driven-development` instead for strict mode, high-risk security changes, or per-task review gates.

---

## The Workflow

```
  Controller (Main Session)
     │
     ├── 1. Dispatch Implementer Subagent (./implementer-prompt.md)
     │      - Passes the entire implementation plan
     │      - Implementer executes all tasks sequentially with warm context (Task 1 → 2 → 3...)
     │      - Implementer runs tests, commits changes, and reports back
     │
     └── 2. Dispatch Final Reviewer Subagent (./final-reviewer-prompt.md)
            - Inspects git diff BASE..HEAD
            - Runs test suite to verify correctness
            - Issues PASS verdict → Done!
```

---

## Setup

1. Prefer an isolated workspace: use `superpowers:using-git-worktrees` or ensure a feature branch.
2. Record the base commit before starting:
   ```bash
   BASE_SHA=$(git rev-parse HEAD)
   ```

## Model Selection

- **Implementer Subagent**: Standard or capable model depending on plan complexity.
- **Final Reviewer Subagent**: Standard or capable model.

Always specify the `model` explicitly when dispatching subagents.

---

## Execution: Step-by-Step

### Step 1: Dispatch Implementer Subagent

Dispatch **one implementer subagent** with the entire plan using `./implementer-prompt.md`:
- Pass the plan file path or inline plan content.
- Do not slice the plan into multiple single-task packets. The implementer executes all tasks in one continuous flow, retaining full in-memory context across tasks.
- If (and only if) the plan explicitly contains two completely decoupled components in separate directories (e.g. `backend/` and `frontend/`), you may dispatch 2 parallel workers. Otherwise, always use 1 single worker.

### Step 2: Implementer Execution Contract

The implementer:
1. Reads the plan and inspects relevant codebase files.
2. Executes tasks sequentially, following TDD checkpoints.
3. Runs tests to verify changes pass.
4. Commits changes with descriptive commit message(s).
5. Returns a concise completion status (`DONE`, commit SHAs, test summary).

### Step 3: Dispatch Final Reviewer

When the implementer finishes, dispatch **one final reviewer subagent** using `./final-reviewer-prompt.md`:
- Provide `BASE_SHA`, `HEAD_SHA`, and the plan path.
- The reviewer runs tests, inspects `git diff BASE_SHA..HEAD_SHA`, and verifies all plan requirements.

### Step 4: Finish or Repair

- **If Review Passes (PASS):** Proceed directly to finish via `superpowers:finishing-a-development-branch`.
- **If Critical/Important Issues Found:** Dispatch a repair subagent (`./repair-prompt.md`) with the exact defect list, verify with tests, then finish.

---

## Red Flags

Never:
- Split a cohesive plan into 1-task-1-subagent (this destroys speed and causes repeated cold starts).
- Skip the final reviewer (independent 2nd-eye review is the key safety net).
- Let implementers spawn their own subagents.