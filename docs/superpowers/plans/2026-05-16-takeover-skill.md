# Takeover Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a receiving-side `takeover` skill that resumes from handoff context only after validating workspace state.

**Architecture:** Create `skills/takeover/SKILL.md` as the receiving counterpart to `handoff`. Update `handoff` to point resumption prompts at `takeover`, register the skill in README/GEMINI, and add static plus trigger tests.

**Tech Stack:** Markdown, Bash, existing skill-triggering test harness

---

### Task 1: Add Static Tests

**Files:**
- Create: `tests/takeover/test-skill-template.sh`
- Create: `tests/takeover/test-handoff-integration.sh`

- [ ] **Step 1: Write failing takeover template test**

```bash
#!/bin/bash
set -e

SKILL_FILE="skills/takeover/SKILL.md"

for required in \
    "Locate" \
    "Verify" \
    "Resume" \
    "Next Immediate Action" \
    "State mismatch" \
    "State matches"; do
    if ! grep -q "$required" "$SKILL_FILE"; then
        echo "FAIL: Missing required takeover text: $required"
        exit 1
    fi
done

echo "PASS"
```

- [ ] **Step 2: Write failing handoff integration test**

```bash
#!/bin/bash
set -e

SKILL_FILE="skills/handoff/SKILL.md"

if ! grep -q "takeover skill" "$SKILL_FILE"; then
    echo "FAIL: Handoff resumption instruction does not mention takeover skill"
    exit 1
fi

if ! grep -q "<exact-handoff-file>" "$SKILL_FILE"; then
    echo "FAIL: Handoff resumption instruction does not prefer exact handoff file path"
    exit 1
fi

echo "PASS"
```

- [ ] **Step 3: Run tests and verify they fail**

Run:
```bash
bash tests/takeover/test-skill-template.sh
bash tests/takeover/test-handoff-integration.sh
```

Expected: both fail before implementation.

---

### Task 2: Implement Takeover Skill

**Files:**
- Create: `skills/takeover/SKILL.md`
- Modify: `skills/handoff/SKILL.md`

- [ ] **Step 1: Create `skills/takeover/SKILL.md`**

Include frontmatter:
```yaml
---
name: takeover
description: Use when taking over existing work, resuming from a handoff file, continuing an interrupted session, or inheriting a partially completed task.
---
```

Include required sections:
- Overview
- When to Use
- Quick Reference
- Locate Context
- Verify Workspace State
- Resume Work
- State Mismatch Rules
- Common Mistakes

- [ ] **Step 2: Update handoff resumption instruction**

Change the handoff instruction to:
```text
I have performed a handoff. Please tell the next agent: "Use the takeover skill to read docs/superpowers/handoffs/<exact-handoff-file>.md and resume work."
```

- [ ] **Step 3: Run static tests**

Run:
```bash
bash tests/takeover/test-skill-template.sh
bash tests/takeover/test-handoff-integration.sh
```

Expected: PASS.

---

### Task 3: Register Takeover and Trigger Test

**Files:**
- Modify: `README.md`
- Modify: `GEMINI.md`
- Modify: `tests/skill-triggering/run-all.sh`
- Create: `tests/skill-triggering/prompts/takeover.txt`

- [ ] **Step 1: Register in README**

Add `takeover` to the basic workflow after `handoff` and to the Collaboration skills list.

- [ ] **Step 2: Register in GEMINI**

Add:
```text
@./skills/takeover/SKILL.md
```

- [ ] **Step 3: Add skill triggering prompt**

Create `tests/skill-triggering/prompts/takeover.txt`:
```text
Please read the latest handoff in docs/superpowers/handoffs/ and resume the work.
```

- [ ] **Step 4: Include takeover in `run-all.sh`**

Add `"takeover"` to the `SKILLS` array.

- [ ] **Step 5: Verify shell/static tests**

Run:
```bash
bash tests/takeover/test-skill-template.sh
bash tests/takeover/test-handoff-integration.sh
sh -n tests/takeover/test-skill-template.sh tests/takeover/test-handoff-integration.sh tests/skill-triggering/run-all.sh
```

Expected: PASS and no syntax errors.

---

### Task 4: Final Verification

**Files:**
- All files from previous tasks

- [ ] **Step 1: Run local deterministic tests**

Run:
```bash
bash tests/handoff/test-gather-state.sh
bash tests/handoff/test-skill-template.sh
bash tests/takeover/test-skill-template.sh
bash tests/takeover/test-handoff-integration.sh
```

Expected: all PASS.

- [ ] **Step 2: Review final diff**

Run:
```bash
git diff --stat
git diff -- skills/takeover/SKILL.md skills/handoff/SKILL.md README.md GEMINI.md tests/takeover tests/skill-triggering
```

Expected: only takeover-related changes plus the prior approved handoff fixes.
