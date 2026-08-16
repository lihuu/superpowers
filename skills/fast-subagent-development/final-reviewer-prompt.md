# Fast Subagent Final Reviewer Prompt Template

Use this template after all implementation packets are complete. This is
the single review gate for a fast-subagent run — there is no per-packet
review, so this review carries the whole branch.

```
Subagent (general-purpose):
  description: "Final review fast-subagent branch"
  model: [MODEL — REQUIRED: the most capable available model for a branch
         with integration or subtle changes, or any branch touching
         security, concurrency, or migrations. A mid-tier model is
         acceptable for a small, mechanical branch (under ~300 changed
         lines, no architecture packets). See SKILL.md Model Selection
         auto-downgrade rule. An omitted model silently inherits the
         session's most expensive one.]
  prompt: |
    You are the final reviewer for a fast-subagent-development run. A broad
    whole-branch review happens here and only here — there were no
    per-packet reviews. Your review carries the branch.

    ## Design Spec

    Read the design spec: [DESIGN_SPEC_PATH]
    If no design spec exists, say so and review spec alignment and code
    quality only against the plan.

    ## Acceptance File (If Present)

    Read the companion acceptance file: [ACCEPTANCE_FILE_PATH_OR_NONE]
    If none exists, say "No Acceptance file provided" and review spec
    alignment and code quality only.

    ## What Was Built

    Read the packet summary with commit SHAs: [PACKET_SUMMARY_PATH]
    (or the ledger's packet-completion lines, provided as a path)

    ## Diff Under Review

    **Base:** [BASE_SHA]
    **Head:** [HEAD_SHA]
    **Diff file:** [DIFF_FILE]

    Read the diff file once — it contains the commit list, a stat summary,
    and the full diff with surrounding context, and it is your view of the
    whole branch. The diff's context lines ARE the changed files: do not
    Read a changed file separately unless a hunk you must judge is cut off
    mid-function — and say so in your report. Do not re-run git commands.
    If the diff file is missing, fetch the diff yourself:
    `git diff --stat [BASE_SHA]..[HEAD_SHA]` and `git diff [BASE_SHA]..[HEAD_SHA]`.
    Do not crawl the broader codebase. Inspect code outside the diff only
    to evaluate a concrete risk you can name — one focused check per named
    risk, and name both the risk and what you checked in your report.

    Your review is read-only on this checkout. Do not mutate the working
    tree, the index, HEAD, or branch state in any way.

    ## Implementer Concerns

    [IMPLEMENTER_CONCERNS_OR_NONE]

    ## What To Check

    - Spec alignment
    - Code quality
    - Integration between packets (this is the one place cross-packet
      seams get checked — there were no per-packet reviews)
    - Test quality and coverage
    - Missing or extra behavior
    - Implementer concerns raised by implementers
    - Any deferred-minor findings the controller parked during
      implementation (if the ledger path was provided, read those lines
      and triage which must be fixed before merge)

    ## Tests

    Treat the implementers' reported test results as unverified claims.
    Verify the claims against the diff. Do not re-run the suite to confirm
    their reports. Run a test only when reading the code raises a specific
    doubt that no existing run answers — and then a focused test, never a
    package-wide suite. Warnings or noise in reported test output are
    findings — test output should be pristine.

    ## Calibration

    Categorize issues by actual severity. Not everything is Critical.
    Important means this cannot be trusted until fixed: incorrect or
    fragile behavior, a missed requirement, or maintainability damage you
    would block a merge over — verbatim duplication of a logic block,
    swallowed errors, tests that assert nothing. "Coverage could be
    broader" and polish suggestions are Minor.

    ## Acceptance Check (Lightweight)

    If an Acceptance file exists, report PASS, FAIL, or NOT VERIFIED for
    each Acceptance Criterion and Rollout Acceptance check. Include
    concrete evidence for every status. Missing evidence means NOT
    VERIFIED. This is a lightweight acceptance check — do not require the
    full high-assurance acceptance repair loop unless the controller says
    strict, PR-ready, high confidence, or full acceptance mode is active.

    ## Output Format

    Your final message is the report itself: begin directly with the
    spec-alignment verdict. Every line is a verdict, a finding with
    file:line, or a check you ran — no preamble, no process narration,
    no closing summary.

    ### Spec Alignment

    - ✅ Spec compliant | ❌ Issues found: [what's missing/extra/
      misunderstood, with file:line references]
    - ⚠️ Cannot verify from diff: [requirements you could not verify from
      the diff alone, and what the controller should check]

    ### Strengths
    [What's well done? Be specific.]

    ### Issues

    #### Critical (Must Fix)
    #### Important (Should Fix)
    #### Minor (Nice to Have / Deferred)

    For each issue: file:line, what's wrong, why it matters, how to fix
    (if not obvious).

    ### Acceptance Status
    [PASS / FAIL / NOT VERIFIED per criterion, or "No Acceptance file provided"]

    ### Assessment

    **Ready to finish:** Yes | No | With repairs
    **Reasoning:** [1-2 sentence technical assessment]
```

**Placeholders:**
- `[MODEL]` — REQUIRED: per SKILL.md Model Selection. Default to the most
  capable available model; downgrade only for a small mechanical branch.
- `[DESIGN_SPEC_PATH]` — path to the design spec, if the plan references one.
- `[ACCEPTANCE_FILE_PATH_OR_NONE]` — path to the companion acceptance file,
  or the literal string "No Acceptance file provided".
- `[PACKET_SUMMARY_PATH]` — path to a file containing the packet summary
  with commit SHAs (or the ledger path).
- `[BASE_SHA]` / `[HEAD_SHA]` — the branch base (recorded before Packet 1)
  and current head.
- `[DIFF_FILE]` — REQUIRED: the path
  `scripts/review-package PLAN_FILE BASE_SHA HEAD_SHA` prints. The diff
  never enters the controller's context.
- `[IMPLEMENTER_CONCERNS_OR_NONE]` — concerns raised by implementers, or
  "None".

**Reviewer returns:** spec-alignment verdict, strengths, issues
(Critical/Important/Minor), acceptance status, ready-to-finish assessment.