# Handoff Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a `handoff` skill that allows an agent to save its current state to a Markdown file and provide resumption instructions for a new agent.

**Architecture:** Create a new skill directory `skills/handoff/` with a `SKILL.md` file defining the handoff procedure. Include a helper script to automate Git and task state gathering.

**Tech Stack:** Markdown, Bash, Git

---

### Task 1: Create State Gathering Script

**Files:**
- Create: `skills/handoff/scripts/gather-state.sh`
- Test: `tests/handoff/test-gather-state.sh`

- [ ] **Step 1: Create the test script**

```bash
#!/bin/bash
# tests/handoff/test-gather-state.sh
set -e

TEST_DIR="temp-test-handoff"
rm -rf $TEST_DIR
mkdir -p $TEST_DIR
cd $TEST_DIR
git init -q

# Create mock state
echo "feature-branch" > .git/HEAD
echo "mock commit" > mock.txt
git add mock.txt
git commit -m "initial commit" -q
echo "modified" >> mock.txt

# Run gather script (relative to project root)
cd ..
bash skills/handoff/scripts/gather-state.sh $TEST_DIR > $TEST_DIR/output.txt

# Verify output contains git info
if ! grep -q "modified files" $TEST_DIR/output.txt; then
    echo "FAIL: Missing git info"
    exit 1
fi

echo "PASS"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/handoff/test-gather-state.sh`
Expected: FAIL (script missing)

- [ ] **Step 3: Implement the gather-state script**

```bash
#!/bin/bash
# skills/handoff/scripts/gather-state.sh
# Gathers git state and basic project info for handoff summary.

PROJECT_ROOT=$1
if [ -z "$PROJECT_ROOT" ]; then PROJECT_ROOT="."; fi

echo "### Git State"
echo "- **Branch:** $(git -C "$PROJECT_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")"
echo "- **Last Commit:** $(git -C "$PROJECT_ROOT" rev-parse --short HEAD 2>/dev/null || echo "none")"

echo ""
echo "### Modified Files"
git -C "$PROJECT_ROOT" status --short | sed 's/^/- /'

echo ""
echo "### Recent Commits (Last 3)"
git -C "$PROJECT_ROOT" log -n 3 --oneline | sed 's/^/- /'
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/handoff/test-gather-state.sh`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add skills/handoff/scripts/gather-state.sh tests/handoff/test-gather-state.sh
git commit -m "feat(handoff): add state gathering script"
```

---

### Task 2: Define Handoff Skill

**Files:**
- Create: `skills/handoff/SKILL.md`

- [ ] **Step 1: Write the SKILL.md content**

```markdown
---
name: handoff
description: Use when you need to hand off the current task to another agent or session.
---

# Handoff

Capture your current progress, reasoning, and pending tasks into a human-readable Markdown file.

## When to Use
- You are hitting context limits and need a fresh session.
- You need to pass the work to a human or another specialized agent.
- You are stopping for the day and want to ensure a clean resumption.

## The Process

1. **Gather Automated State:** Run `bash skills/handoff/scripts/gather-state.sh .` to get git and file info.
2. **Draft the Summary:**
   - **Current Objective:** What were you just trying to do?
   - **Work Completed:** List specific steps finished.
   - **Pending Tasks:** List exactly what remains in the plan/TODO.
   - **Mental State:** Document your current reasoning, blockers, and "gotchas".
3. **Save the Handoff:**
   - Create the directory if it doesn't exist: `docs/superpowers/handoffs/`
   - Save to: `docs/superpowers/handoffs/YYYY-MM-DD-<feature>-handoff.md`
4. **Resumption Instruction:** End your session by telling the user:
   > "I have performed a handoff. Please tell the next agent: 'Read the latest handoff in docs/superpowers/handoffs/ and resume work.'"

## For the Receiving Agent

When you see a resumption instruction:
1. **Announce:** "I am resuming work from the latest handoff in docs/superpowers/handoffs/".
2. **Read:** Locate the most recent file in `docs/superpowers/handoffs/` and read it.
3. **Sync:** Update your internal task list and verify modified files.
4. **Execute:** Continue from the "Next Immediate Action" in the handoff.
```

- [ ] **Step 2: Commit**

```bash
git add skills/handoff/SKILL.md
git commit -m "feat(handoff): define handoff skill"
```

---

### Task 3: Discovery & Documentation

**Files:**
- Modify: `GEMINI.md`
- Modify: `README.md`

- [ ] **Step 1: Add to GEMINI.md**

Add `@./skills/handoff/SKILL.md` to the top level `GEMINI.md`.

- [ ] **Step 2: Add to README.md**

Add a brief mention of the `handoff` skill in the "Workflow" section of the README.

- [ ] **Step 3: Commit**

```bash
git add GEMINI.md README.md
git commit -m "docs(handoff): register handoff skill"
```

---

### Task 4: Final Verification

- [ ] **Step 1: Run a mock handoff**
  - Manually trigger the `handoff` procedure.
  - Verify `docs/superpowers/handoffs/` contains a valid file.
- [ ] **Step 2: Cleanup test artifacts**
- [ ] **Step 3: Final commit**
