---
name: sf-test-opps
description: >
  Opens the default Salesforce org in a headed Playwright browser and navigates to the
  All Opportunities list view. Use this skill whenever the user wants to browse, inspect,
  or test the Opportunities object in their Salesforce org — phrases like "open opps",
  "show me opportunities", "navigate to all opps", or "open salesforce and go to opportunities"
  should all trigger this skill. Also use it as a setup step before any browser-based
  Salesforce opportunity testing.
---

# SF Test Opps

Automates opening the Salesforce org and navigating to the All Opportunities list view using a headed Playwright browser session.

## Steps

### 1. Get the org login URL

```bash
sf org open --url-only
```

Extract the URL from the output line that reads:
`Access org <id> as user <email> with the following URL: <url>`

### 2. Open the headed browser and log in

```bash
npx playwright-cli open --headed "<url>"
```

The org's Lightning home page loads automatically via the frontdoor SSO URL.

### 3. Navigate to Opportunities

Click the **Opportunities** link in the top navigation bar:

```bash
npx playwright-cli click "getByRole('link', { name: 'Opportunities' })"
```

### 4. Switch to All Opportunities list view

Open the list view picker and select **All Opportunities**:

```bash
npx playwright-cli click "getByRole('button', { name: 'Select a List View:' })"
npx playwright-cli click "getByRole('option', { name: 'All Opportunities' })"
```

The URL will update to `filterName=AllOpportunities` and the page title will read **All Opportunities | Opportunities | Salesforce**.

### 5. (Optional) Open a specific opportunity

If the user wants to open a particular record, take a snapshot to get the row links, then click the matching opportunity name:

```bash
npx playwright-cli snapshot
npx playwright-cli click "getByRole('link', { name: '<opportunity name>' })"
```

## Notes

- Always use `--headed` so the browser is visible for interactive inspection or follow-up steps.
- `npx playwright-cli` is required in this project (no global install). Always prefix commands with `npx`.
- If `sf org open --url-only` prints a security warning to stderr before the URL line, that's expected — just parse the URL from the output normally.
