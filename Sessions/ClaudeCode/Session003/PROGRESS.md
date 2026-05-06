# Detailed Notes — Build Progress

## Where We Are
Tasks 1–4 complete and deployed to `cws-dev`. Next up: **Task 5 — Apex `saveNote`**.

## Key Files
- **Design spec:** `docs/superpowers/specs/2026-05-05-detailed-notes-design.md`
- **Implementation plan:** `docs/superpowers/plans/2026-05-05-detailed-notes.md`
- **Apex controller:** `force-app/main/default/classes/DetailedNoteController.cls`
- **Apex tests:** `force-app/main/default/classes/DetailedNoteControllerTest.cls`

## Task Checklist
- [x] Task 1 — `DetailedNote__c` object + fields (Title, Body, Account/Case/Opp lookups)
- [x] Task 2 — `Edit_All_Detailed_Notes` custom permission + `DetailedNotes_User` permission set
- [x] Task 3 — `DetailedNoteController`: `NoteWrapper` + `getNotes` for Case and Opportunity
- [x] Task 4 — `getNotes` Account rollup with source labels
- [ ] Task 5 — Apex `saveNote`
- [ ] Task 6 — Apex `updateNote` + `deleteNote` with authorization
- [ ] Task 7 — LWC shell + note list (left panel)
- [ ] Task 8 — LWC note viewer + edit/delete visibility (right panel)
- [ ] Task 9 — LWC create/edit form (`lightning-input-rich-text`)
- [ ] Task 10 — Deploy to scratch org + smoke test

## Default Org
Alias: `cws-dev` — run `sf org list` to confirm it's still the default (🍁).
