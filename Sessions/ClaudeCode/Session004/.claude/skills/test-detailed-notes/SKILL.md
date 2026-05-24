---
name: test-detailed-notes
description: >
  End-to-end browser test for the Detailed Notes LWC component on the Salesforce Account
  record page. Use this skill whenever the user wants to test, verify, or re-run the
  Detailed Notes component tests — phrases like "test detailed notes", "run the notes test",
  "re-run the component test", "verify the notes component works", or "check detailed notes
  on the account" should all trigger this skill. Also use it after deploying changes to
  the detailedNotes LWC to confirm nothing broke.
---

# Test Detailed Notes

Runs a full functional test of the Detailed Notes LWC component deployed on the Account
record layout. The test covers: viewing a note, editing a note, creating a new note, and
deleting the test note (cleanup).

## Prerequisites

- A Salesforce org is authenticated and has at least one Account record
- The `detailedNotes` LWC is deployed to the Account page layout
- `npx playwright-cli` is available (never use `playwright-cli` directly — it is not globally installed)

## Steps

### 1. Get the org login URL

```bash
sf org open --url-only
```

Extract the URL from the line: `Access org <id> as user <email> with the following URL: <url>`

### 2. Open the headed browser and log in

```bash
npx playwright-cli open --headed "<url>"
```

The org's Lightning home page loads. Confirm `Page URL` ends with `/lightning/page/home`.

### 3. Navigate to the Accounts list

```bash
npx playwright-cli goto "https://<your-org-domain>.lightning.force.com/lightning/o/Account/list"
```

Use the domain from the frontdoor URL (the part between `https://` and `/secur/`).

### 4. Open the first Account record

Take a snapshot, find an Account name link, and click it:

```bash
npx playwright-cli snapshot
npx playwright-cli click "<ref for first Account name link>"
```

Confirm the URL changes to `/lightning/r/Account/<id>/view`.

### 5. Verify the Detailed Notes component loaded

Take a snapshot and look for:
- A tab panel with `tablist` containing a **"Detailed Notes"** tab
- The tab panel has a heading "Detailed Notes" and a **"New Note"** button

If the tab is not selected by default, click it:
```bash
npx playwright-cli click "getByRole('tab', { name: 'Detailed Notes' })"
```

---

### Test A: View an existing note

**Only run if at least one note already exists in the list.**

Click the first note in the list (use the ref from the snapshot):
```bash
npx playwright-cli click "<ref for note list item>"
```

Verify the detail pane shows:
- A heading with the note title
- An author + date line (`<Name> · <date>`)
- The note body content
- **Edit** and **Delete** buttons

---

### Test B: Edit a note

Click **Edit** on the currently-viewed note:
```bash
npx playwright-cli click "getByRole('button', { name: 'Edit', exact: true })"
```

Verify the edit form appears with:
- A **Title** textbox pre-filled with the current title
- A rich text toolbar (Bold, Italic, etc.)
- **Save** and **Cancel** buttons

Make a small, reversible change to the title (append " [edited]"):
```bash
npx playwright-cli eval "el => el.value" "<title textbox ref>"
# note the original title so you can restore it
npx playwright-cli fill "<title textbox ref>" "<original title> [edited]"
```

Add a line to the body. The rich text body is a white editable box below the toolbar.
Click it by coordinate (approximate center of the editor box) then type:
```bash
npx playwright-cli mousemove <x> <y>
npx playwright-cli mousedown
npx playwright-cli mouseup
npx playwright-cli press End
npx playwright-cli press Enter
npx playwright-cli type "Test edit line."
```

Click **Save**:
```bash
npx playwright-cli click "getByRole('button', { name: 'Save' })"
```

Verify:
- The list item shows the updated title
- The detail pane shows the updated title and the new body line

**Restore the original title** (best effort — not strictly required if the user is OK leaving it):
```bash
npx playwright-cli click "getByRole('button', { name: 'Edit', exact: true })"
npx playwright-cli fill "<title textbox ref>" "<original title>"
npx playwright-cli click "getByRole('button', { name: 'Save' })"
```

---

### Test C: Create a new note

Click **New Note**:
```bash
npx playwright-cli click "getByLabel('Detailed Notes').getByRole('button', { name: 'New Note' })"
```

Verify the form appears with an empty Title field and rich text editor.

Fill the title:
```bash
npx playwright-cli fill "getByRole('textbox', { name: 'Title' })" "Playwright Test Note"
```

Click the body area (white box below the toolbar) and type:
```bash
npx playwright-cli mousemove <x> <y>
npx playwright-cli mousedown
npx playwright-cli mouseup
npx playwright-cli type "This note was created by Playwright automation testing."
```

Click **Save**:
```bash
npx playwright-cli click "getByRole('button', { name: 'Save' })"
```

Verify:
- "Playwright Test Note" appears at the top of the note list
- No error message is shown

---

### Test D: Delete the test note (cleanup)

Click "Playwright Test Note" in the list to select it, then click **Delete**:
```bash
npx playwright-cli click "<ref for Playwright Test Note list item>"
npx playwright-cli click "getByRole('button', { name: 'Delete' })"
```

> **Note:** Delete is immediate with no confirmation dialog. The note disappears instantly.

Verify:
- "Playwright Test Note" is gone from the list
- The detail pane shows "Select a note to view it."

---

## Reporting results

After all tests, take a final screenshot and summarize:

```bash
npx playwright-cli screenshot --filename=.playwright-cli/test-detailed-notes-final.png
```

Report each test (A–D) as **PASS** or **FAIL** with a one-line note on what was observed.
Flag any unexpected behavior (e.g., missing confirmation on delete, formatting not persisting).

## Notes

- The rich text editor body is **not** a standard `contenteditable` element accessible by ref.
  Always click it by screen coordinates. Take a screenshot first to locate the editor visually.
- `npx playwright-cli` must be prefixed on every command — never `playwright-cli` alone.
- The security warning from `sf org open --url-only` is expected and can be ignored.
- If no notes exist yet, skip Test A and go straight to Test C (Create), then use the created
  note as the subject for Test B (Edit) before running Test D (Delete).
