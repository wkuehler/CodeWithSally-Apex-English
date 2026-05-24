# Session 003 — Building with Superpowers: Detailed Notes Component

**Series:** Claude with Sally (Code With Sally)
**Topic:** Starting a real Salesforce build using Claude Code with Superpowers — brainstorming, design spec, implementation plan, and TDD

---

## What We Built (So Far)

The **Apex backend** for a Detailed Notes component — the data model, security model, and controller are complete and deployed. The LWC frontend is planned but not yet started.

**Completed this session:**

- `DetailedNote__c` custom object with Title, Body, and optional Account/Case/Opportunity lookups
- `Edit_All_Detailed_Notes` custom permission + `DetailedNotes_User` permission set
- `DetailedNoteController` Apex class with `NoteWrapper` and `getNotes` — returns notes for Case and Opportunity records, plus a three-query Account rollup with source labels (e.g., "Case: Billing Issue")
- Full Apex test coverage for all completed methods (4 passing tests)

**Planned (future sessions):**

- `saveNote`, `updateNote`, `deleteNote` Apex methods with creator/override authorization
- `detailedNotes` LWC — split-panel layout with note list, viewer, and rich-text editor

---

## What We Covered

### 1. Superpowers — the workflow we used

Instead of jumping straight into code, we used the Superpowers skill set to guide the session:

- **Brainstorming first** — Claude presented three layout options as visual mockups (Split Panel, Stacked Cards, List + Modal). We chose Split Panel.
- **Design spec** — A written spec locked down the data model, visibility rules, component architecture, security model, and test cases before any code was written. See `docs/superpowers/specs/2026-05-05-detailed-notes-design.md`.
- **Implementation plan** — A task-by-task plan with exact file names, code snippets, and test commands. See `docs/superpowers/plans/2026-05-05-detailed-notes.md`.

### 2. Skills — custom reusable knowledge

We created a project-level **`sf-dev` skill** (`.claude/skills/sf-dev/`) that captures Salesforce-specific lessons learned in reference files:

| File | Contents |
|---|---|
| `references/deploy.md` | SF CLI deploy commands, test flags |
| `references/metadata.md` | Custom object/field XML gotchas |
| `references/apex.md` | `@AuraEnabled`, sharing keywords, permission checks |
| `references/lwc.md` | Wire adapter patterns, `js-meta.xml` targets |
| `references/testing.md` | `@TestSetup`, `System.runAs`, custom permission grants |

Skills let Claude load exactly the knowledge it needs for a task without stuffing everything into a single prompt. Instead of repeating yourself every session, the skill file evolves as you discover new patterns.

### 3. TDD — test-driven Apex development

Each Apex task followed the same rhythm:

1. Write failing tests first
2. Run them to confirm they fail
3. Implement the method
4. Deploy and run tests until they pass
5. Commit

---

## Progress at End of Session

Tasks 1–4 complete and deployed to dev org `cws-dev`. See `PROGRESS.md` for the full checklist.

| Task | Status | What it covers |
|---|---|---|
| 1 — Object + fields | Done | `DetailedNote__c` with Title, Body, Account/Case/Opp lookups |
| 2 — Custom permission + permission set | Done | `Edit_All_Detailed_Notes`, `DetailedNotes_User` |
| 3 — `NoteWrapper` + `getNotes` (Case/Opp) | Done | Apex controller shell, TDD passing |
| 4 — `getNotes` Account rollup | Done | Three-query merge with source labels, sorted by date |
| 5 — `saveNote` | Up next | |
| 6 — `updateNote` + `deleteNote` | | |
| 7–9 — LWC (list, viewer, editor) | | |
| 10 — Deploy + smoke test | | |

---

## Key Files

```
docs/superpowers/specs/2026-05-05-detailed-notes-design.md   Design spec
docs/superpowers/plans/2026-05-05-detailed-notes.md          Implementation plan (task by task)
PROGRESS.md                                                   Live progress tracker

.claude/skills/sf-dev/SKILL.md                               Custom sf-dev skill definition
.claude/skills/sf-dev/references/                            Reference files loaded per task

force-app/main/default/objects/DetailedNote__c/              Custom object + fields
force-app/main/default/customPermissions/                    Edit_All_Detailed_Notes permission
force-app/main/default/permissionsets/                       DetailedNotes_User permission set
force-app/main/default/classes/DetailedNoteController.cls    Apex controller
force-app/main/default/classes/DetailedNoteControllerTest.cls Apex tests
```

---

## Running the Tests

```bash
# Deploy to your scratch org
sf project deploy start

# Run Apex tests
sf apex run test --class-names DetailedNoteControllerTest --result-format human --wait 5
```

---

## Concepts Demonstrated

- Brainstorm before you build — use visual mockups to decide on UX before writing a line of code
- Design spec as a contract — locks scope and prevents mid-build drift
- Skills as living documentation — build up a project-specific knowledge base that Claude loads on demand
- TDD rhythm for Apex — write tests → confirm failure → implement → pass → commit
- Two-tier security — OWD + server-side authorization in Apex + `canEdit` flag for the LWC
- Account rollup query pattern — three separate SOQL queries merged and sorted in Apex
