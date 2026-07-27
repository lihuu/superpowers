# Fast Subagent Repair Prompt Template

Use this template when dispatching a repair subagent after the final
review finds Critical/Important issues. Both rounds dispatch a **fresh
repair subagent** — fast never resumes the original implementer. Each
round reuses the implementer's report file as persistent memory: round 1
reads the implementer's report; round 2 reads the same file (now carrying
the round-1 fix report) and runs on a higher-tier model. See SKILL.md
Repair Loop for the 2-round cap and adjudication.

```
Subagent (general-purpose):
  description: "Repair Packet N review findings (round R)"
  model: [MODEL — REQUIRED: round 1 uses the same tier as the implementer
         that produced the code (or one tier up if that implementer was
         cheap); round 2 uses at least one tier above round 1. See
         SKILL.md Model Selection. An omitted model silently inherits
         the session's most expensive one.]
  prompt: |
    You are repairing review findings in one packet. Round [R] of 2.

    ## Packet Brief

    Read the packet brief: [BRIEF_FILE]
    It contains the original packet requirements.

    ## Prior Work

    Read the implementer's report (and any round-1 fix report appended at
    the end): [REPORT_FILE]
    If this is round 2, a prior repair attempt is recorded there — read it
    before starting so you do not repeat what was tried.

    ## Review Findings To Fix

    [REVIEW_FINDINGS]

    ## Failure Evidence

    [FAILURE_EVIDENCE]

    ## Design Spec (If The Plan References One)

    Read the design spec: [DESIGN_SPEC_PATH_OR_NONE]
    If none exists, say "No design spec provided" and work from the packet
    brief alone. The repair scope is the review findings — read only the
    spec sections relevant to those findings, not the whole file.

    ## Companion Acceptance File (If Present)

    Read the companion acceptance file: [ACCEPTANCE_FILE_PATH_OR_NONE]
    If none exists, say "No Acceptance file provided" and skip the
    acceptance check. When present, read only the criteria the findings
    touch — do not re-open previously passed criteria.

    ## Diff Under Repair

    **Fix base:** [FIX_BASE_SHA] (the head the previous review saw)
    **Head:** [HEAD_SHA]
    **Diff file:** [DIFF_FILE]

    Read the diff file once — it contains the commits since the previous
    review, a stat summary, and the diff with surrounding context. Do not
    re-run git commands. If the diff file is missing, fetch it yourself:
    `git diff --stat [FIX_BASE_SHA]..[HEAD_SHA]` and
    `git diff [FIX_BASE_SHA]..[HEAD_SHA]`.

    ## Rules

    - Fix the root cause demonstrated by the review finding and evidence.
    - Do not broaden the repair scope — fix only the open findings.
    - Do not modify unrelated behavior or reopen previously passed areas.
    - Run the tests covering the amended code and relevant regression tests.
    - Commit the repair as one commit.
    - Append your fix report to the SAME report file ([REPORT_FILE]) — do
      not write a new file. The fix report must name the covering tests you
      ran, the command, and the output. Reviewers will not re-run tests for
      you — your report is the test evidence.

    ## Report Format

    Append to [REPORT_FILE]:
    - Round: R of 2
    - Findings fixed (which review findings you addressed, with file:line)
    - What you changed
    - Files changed
    - Commit (short SHA + subject)
    - Commands run and results (the covering tests, with output)
    - Evidence for re-review
    - Remaining concerns

    Then report back with ONLY (under 15 lines):
    - **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
    - Commit (short SHA + subject)
    - One-line test summary (e.g. "8/8 covering tests passing, output pristine")
    - Findings addressed (one-liners) and any still open
    - The report file path

    If BLOCKED or NEEDS_CONTEXT, put the specifics in the final message
    itself — the controller acts on it directly.
```

**Placeholders:**
- `[MODEL]` — REQUIRED: round 1 same tier as implementer (or one up);
  round 2 at least one tier above round 1.
- `[R]` — the round number (1 or 2).
- `[BRIEF_FILE]` — the packet brief file (`scripts/packet-brief PLAN_FILE N`).
- `[REPORT_FILE]` — REQUIRED: `<workspace>/packet-N-report.md`. Repair
  appends to the implementer's report file — it is the persistent memory
  across rounds.
- `[REVIEW_FINDINGS]` — the Critical/Important findings and spec gaps from
  the previous review, copied verbatim, one per bullet.
- `[DESIGN_SPEC_PATH_OR_NONE]` — path to the design spec file if the plan
  references one, else the literal "No design spec provided". Fast does not
  extract spec regions — the whole design spec file is the source; the
  repair subagent reads only the sections the findings touch.
- `[ACCEPTANCE_FILE_PATH_OR_NONE]` — path to the companion acceptance file
  (`YYYY-MM-DD-<topic>-acceptance.md`) if present, else "No Acceptance file
  provided". Acceptance criteria live in a separate companion file in fast,
  not extracted from a spec region.
- `[FIX_BASE_SHA]` — the head the previous review saw.
- `[HEAD_SHA]` — current commit.
- `[DIFF_FILE]` — the path `scripts/review-package PLAN_FILE FIX_BASE HEAD`
  prints.

**Repair returns:** status, commit, one-line test summary, findings
addressed / still open, report-file path.