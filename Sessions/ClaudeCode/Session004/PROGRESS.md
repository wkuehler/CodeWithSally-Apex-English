# Detailed Notes — Build Progress

## Where We Are
Tasks 1–9 complete and deployed to `cws-dev`. Task 10 (smoke test) is in progress — metadata deployed and permission set assigned. Org is open; manual verification steps remain.

## Key Files
- **Design spec:** `docs/superpowers/specs/2026-05-05-detailed-notes-design.md`
- **Implementation plan:** `docs/superpowers/plans/2026-05-05-detailed-notes.md`
- **Apex controller:** `force-app/main/default/classes/DetailedNoteController.cls`
- **Apex tests:** `force-app/main/default/classes/DetailedNoteControllerTest.cls`
- **LWC component:** `force-app/main/default/lwc/detailedNotes/`
- **LWC tests:** `force-app/main/default/lwc/detailedNotes/__tests__/detailedNotes.test.js`

## Task Checklist
- [x] Task 1 — `DetailedNote__c` object + fields (Title, Body, Account/Case/Opp lookups)
- [x] Task 2 — `Edit_All_Detailed_Notes` custom permission + `DetailedNotes_User` permission set
- [x] Task 3 — `DetailedNoteController`: `NoteWrapper` + `getNotes` for Case and Opportunity
- [x] Task 4 — `getNotes` Account rollup with source labels
- [x] Task 5 — Apex `saveNote`
- [x] Task 6 — Apex `updateNote` + `deleteNote` with authorization
- [x] Task 7 — LWC shell + note list (left panel)
- [x] Task 8 — LWC note viewer + edit/delete visibility (right panel)
- [x] Task 9 — LWC create/edit form (`lightning-input-rich-text`)
- [ ] Task 10 — Deploy to scratch org + smoke test

## Test Status
- **Apex:** 13/13 passing (`DetailedNoteControllerTest`)
- **LWC Jest:** 10/10 passing (`detailedNotes.test.js`)

## Task 10 — Smoke Test Checklist
Metadata deployed to `cws-dev`, `DetailedNotes_User` permset assigned. To complete:

- [ ] Add component to an Account Lightning page via App Builder and activate
- [ ] Empty state shows "No notes yet."
- [ ] "New Note" opens editor in the right panel
- [ ] Title field rejects input beyond 100 characters
- [ ] Rich text editor is functional (bold, bullets, etc.)
- [ ] Saving a note adds it to the left panel list
- [ ] Clicking a note tile shows its body in the right panel
- [ ] Edit and Delete buttons appear only on your own notes
- [ ] Edit pre-fills title and body; saving updates the note
- [ ] Delete removes the note from the list
- [ ] Repeat smoke test on Case and Opportunity pages
- [ ] Verify Account rollup: notes from linked Cases and Opps appear with source badges

## Implementation Notes
- Controller is `without sharing` — required so the `Edit_All_Detailed_Notes` override permission can edit/delete records not owned by the running user. Authorization is enforced explicitly in `assertCanEdit()`.
- `AuraHandledException` requires `e.setMessage(msg)` in addition to the constructor arg — otherwise `getMessage()` returns `"Script-thrown exception"` on the client.

## Default Org
Alias: `cws` — run `sf org list` to confirm it's still the default (🍁).
