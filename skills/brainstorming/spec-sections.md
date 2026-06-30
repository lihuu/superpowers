# Staged Spec Sections

`spec-sections` keeps design and acceptance in one file while controlling which region enters each agent stage.

## Required Markers

```markdown
<!-- IMPLEMENTATION-SPEC-BEGIN -->
...complete normative design...
<!-- IMPLEMENTATION-SPEC-END -->

<!-- ACCEPTANCE-BEGIN -->
...completion contract and acceptance...
<!-- ACCEPTANCE-END -->
```

Markers must be exact, unique, paired, non-nested, and ordered as shown. Both regions must contain non-whitespace content.

## Commands

Resolve the executable relative to the brainstorming skill directory:

```bash
SPEC_SECTIONS="<brainstorming-skill-directory>/spec-sections"

"$SPEC_SECTIONS" validate path/to/spec.md
"$SPEC_SECTIONS" implementation path/to/spec.md
"$SPEC_SECTIONS" acceptance path/to/spec.md
"$SPEC_SECTIONS" full path/to/spec.md
```

- `validate`: checks structure without writing spec content to stdout.
- `implementation`: outputs only the Implementation Spec region.
- `acceptance`: outputs only the Acceptance region.
- `full`: outputs both regions in their defined order.

All commands validate before output. Errors return nonzero and do not emit file content to stdout.

## Stage Inputs

| Stage | Input |
|---|---|
| Spec writing and spec review | Complete file while editing; validated `full` extraction for reviewer dispatch |
| Plan generation and initial implementation | `implementation` only |
| Independent acceptance | `implementation`, then `acceptance`, then diff, then test results |
| Repair loop | Failed criteria, failure evidence, referenced design sections, related diff |
| Final acceptance | Fresh complete `implementation` and `acceptance` extractions; all criteria and rollout checks rerun |

Do not replace extraction with instructions to ignore a section. The excluded region must not be sent to that stage.

## Legacy Specs

The default policy rejects unmarked specs:

```bash
"$SPEC_SECTIONS" implementation old-spec.md
```

Explicit compatibility mode restores whole-file behavior:

```bash
"$SPEC_SECTIONS" --legacy full implementation old-spec.md
```

The tool logs `staged isolation disabled` to stderr. Compatibility mode applies only when no exact marker is present; partial, duplicate, or malformed markers still fail.
