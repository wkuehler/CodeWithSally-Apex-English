# Detailed Notes — Design Spec

**Date:** 2026-05-05  
**Status:** Approved  

---

## Overview

A Lightning Web Component that lets team members take rich-text notes directly on Account, Case, and Opportunity record pages. Notes are stored in a custom object, visible to all users, and editable/deletable only by their creator (or users with an override permission).

---

## Data Model

**Custom Object:** `DetailedNote__c`

| Field | Type | Details |
|---|---|---|
| `Title__c` | Text(100) | Required |
| `Body__c` | Rich Text Area(32768) | Required |
| `Account__c` | Lookup(Account) | Optional; populated when note is created on an Account page |
| `Case__c` | Lookup(Case) | Optional; populated when note is created on a Case page |
| `Opportunity__c` | Lookup(Opportunity) | Optional; populated when note is created on an Opportunity page |

Standard system fields (`CreatedById`, `CreatedDate`) handle creator tracking. Each lookup field uses child relationship name `DetailedNotes` so the standard related list appears automatically on each object's page layout. Note: the standard related list on Account shows only notes directly linked via `Account__c`; the rolled-up view (including related Case and Opportunity notes) is provided exclusively by the LWC component.

Only one lookup field is populated per note record.

---

## Note Visibility Rules

| Record Type | Notes Shown |
|---|---|
| Case | Notes where `Case__c = recordId` |
| Opportunity | Notes where `Opportunity__c = recordId` |
| Account | Notes where `Account__c = recordId` **plus** all notes from Cases and Opportunities where `AccountId = recordId` |

On the Account view, each note tile displays a source badge indicating its origin (e.g., "Case: Billing Issue" or "Opportunity: Renewal 2026") for notes that come from related records.

---

## Component Architecture

### LWC: `detailedNotes`

Placed on Account, Case, and Opportunity Lightning pages via App Builder. Receives `@api recordId` and `@api objectApiName` from the page context.

**Layout: Split Panel**

- **Left panel:** Scrollable list of note tiles showing title, author, and date. "New Note" button at the top. On Account pages, tiles for related Case/Opportunity notes include a source badge.
- **Right panel:** Displays the selected note's full body (rendered HTML). Edit and Delete buttons appear only when the current user is the note creator or has the `Edit_All_Detailed_Notes` custom permission. Clicking "New Note" or "Edit" replaces the right panel with an inline form: title text input + `lightning-input-rich-text` + Save/Cancel buttons.

### Apex: `DetailedNoteController`

| Method | Signature | Purpose |
|---|---|---|
| `getNotes` | `getNotes(String recordId, String objectApiName)` | Returns notes for the record sorted by `CreatedDate DESC`. On Account, merges results from three queries (direct account notes, related case notes, related opportunity notes). Each note record includes a `canEdit` boolean computed from `CreatedById` and the `Edit_All_Detailed_Notes` permission check. |
| `saveNote` | `saveNote(String title, String body, String recordId, String objectApiName)` | Creates a `DetailedNote__c` and populates the correct lookup field based on `objectApiName`. |
| `updateNote` | `updateNote(String noteId, String title, String body)` | Updates title and body. Throws `AuraHandledException` if caller is not the creator and does not have `Edit_All_Detailed_Notes`. |
| `deleteNote` | `deleteNote(String noteId)` | Deletes the note. Same authorization check as `updateNote`. |

---

## Security & Permissions

- **OWD for `DetailedNote__c`:** Public Read — all users can read all notes; no direct DML outside the Apex controller.
- **Edit/Delete authorization:** Enforced server-side in `updateNote` and `deleteNote` via `CreatedById = UserInfo.getUserId() OR FeatureManagement.checkPermission('Edit_All_Detailed_Notes')`. The `canEdit` flag is also returned on each note record so the LWC can show/hide buttons without a separate permission API call.
- **Custom Permission:** `Edit_All_Detailed_Notes` — grants override capability to edit or delete any note. Assigned to admins or team leads as needed.
- **Permission Set:** `DetailedNotes_User` — grants Read on `DetailedNote__c` and access to `DetailedNoteController`. The `Edit_All_Detailed_Notes` custom permission is included in this permission set and assigned selectively.

---

## Future Enhancements

- Sorting and filtering the note list (e.g., newest/oldest, search by title)

---

## Testing

### Apex: `DetailedNoteControllerTest`

- `getNotes` returns correct notes for Account, Case, and Opportunity
- `getNotes` on Account returns rolled-up Case and Opportunity notes with source info
- `saveNote` creates a note with the correct lookup populated
- `updateNote` succeeds for the creator
- `updateNote` throws for a non-creator without the override permission
- `updateNote` succeeds for a user with `Edit_All_Detailed_Notes`
- `deleteNote` — same three scenarios as `updateNote`

### LWC Jest: `detailedNotes.test.js`

- Renders note list from mocked Apex data
- Clicking a note tile displays the note body in the right panel
- Edit/Delete buttons are visible only when `canEdit` is `true` on the note
- "New Note" and "Edit" swap in the editor form; Save and Cancel swap it back
- Title input enforces 100-character max
