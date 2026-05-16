# Document Auto-Archive Design Spec

## Goal
Automate the archival of completed or discarded specification (Spec) and implementation plan (Plan) documents to maintain workspace cleanliness and optimize AI agent context.

## Core Requirements
- **Automated Trigger**: Archive process must run automatically after successful merge, PR creation, or branch discard in the `finishing-a-development-branch` skill.
- **Precise Matching**: Locate files using the standard `YYYY-MM-DD-<feature-name>.md` format.
- **Link Integrity**: Automatically update relative Markdown links between archived documents.
- **Preservation of Discarded Work**: Move documents related to discarded branches to a specific `discarded/` sub-archive.
- **Transparent Logging**: Provide detailed terminal output of the archival actions.
- **Git Atomicity**: Automatically stage and commit moved files.

## Architecture

### Directory Structure
```text
docs/superpowers/
├── specs/
│   ├── archive/
│   │   └── discarded/
│   └── [active-specs].md
└── plans/
    ├── archive/
    │   └── discarded/
    └── [active-plans].md
```

### Process Flow
1. **Identify Feature Name**: Extract `<feature-name>` from the current branch name or session context.
2. **Search**: Find matching files in `docs/superpowers/specs/` and `docs/superpowers/plans/`.
3. **Analyze Links**: Read file contents to identify relative links to other documents being archived.
4. **Update Paths**: Replace relative links (e.g., `[Spec](../specs/foo.md)` -> `[Spec](foo.md)` if both moved to the same archive folder).
5. **Move Files**: 
   - Successful completion -> `archive/`
   - Discarded work -> `archive/discarded/`
6. **Log Actions**: Output step-by-step progress to the terminal.
7. **Commit**: 
   - Command: `git add <moved-files>`
   - Message: `docs: archive <feature-name> [completed|discarded]`

## Component Details

### Path Dependency Resolution
When moving a file from `docs/superpowers/specs/` to `docs/superpowers/specs/archive/`, links to `../plans/plan.md` must be updated to maintain functionality if the plan is also moved to `docs/superpowers/plans/archive/`. 
- Logic: If link target exists in the set of files currently being archived, calculate the new relative path based on target's destination.

### Logging Format
```text
[Archive] Archiving documentation for: <feature-name>
  - Moving spec: <old-path> -> <new-path>
  - Moving plan: <old-path> -> <new-path>
  - Updating relative links... Done (<count> updated)
  - Committing to git... Done
✅ Documentation archived to archive/ directory.
```

## Testing Strategy
1. **Happy Path**: Complete a task using `finishing-a-development-branch` and verify files move to `archive/` and are committed.
2. **Discard Path**: Choose Option 4 in `finishing-a-development-branch` and verify files move to `archive/discarded/`.
3. **Link Verification**: Create a spec with a link to a plan, archive both, and verify the link in the archived spec still works.
4. **Missing Files**: Run on a branch with no matching documents; verify process skips gracefully with no error.

## Success Criteria
- Root `specs/` and `plans/` directories contain only active work.
- All historical documents are discoverable in `archive/`.
- Cross-document links remain functional after archival.
- Archival status is clearly visible in the terminal log and git history.
