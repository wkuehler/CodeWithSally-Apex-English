---
allowed-tools: Bash, Read, Write, Glob, Grep
description: Scaffold a complete Lightning Web Component matching project conventions
---

# Scaffold Lightning Web Component

You are scaffolding a new Lightning Web Component for a Salesforce DX project.

## Arguments

$ARGUMENTS

The first word is the component name (camelCase). Everything after the dash (-) describes what the component does.

## Instructions

1. **Read project context first**:
   - Read `sfdx-project.json` to confirm the API version
   - Read all files in the `force-app/main/default/lwc/workflowVisualizer/` directory to understand project conventions for:
     - SLDS usage patterns
     - Accessibility approach (aria attributes, keyboard navigation, focus management)
     - CSS structure (custom properties, responsive design, transitions)
     - Decorator usage (@api, @track, @wire)
     - Error and loading state handling
   - Glob `force-app/main/default/lwc/*/` to see existing components and avoid naming conflicts

2. **Generate four files** in `force-app/main/default/lwc/{componentName}/`:

   **File 1: `{componentName}.js`**
   - Import from `lwc` (LightningElement plus needed decorators)
   - Use the conventions observed in the existing workflowVisualizer component:
     - Computed properties (getters) for derived state
     - Proper error handling with try/catch
     - JSDoc comments on public API properties
     - Event dispatching with CustomEvent for parent communication
   - Include loading and error state management
   - Add methods that fulfill the described purpose

   **File 2: `{componentName}.html`**
   - Use `<template>` as root element
   - Use SLDS classes for layout and styling (e.g., `slds-card`, `slds-grid`, `slds-col`)
   - Include conditional rendering for loading, error, and empty states
   - Add accessibility attributes: `aria-label`, `aria-live`, `role` where appropriate
   - Use `lightning-*` base components where they fit (e.g., `lightning-button`, `lightning-icon`, `lightning-spinner`)

   **File 3: `{componentName}.css`**
   - Follow the project's CSS conventions:
     - Use CSS custom properties for theming (e.g., `--slds-*` or custom `--component-*` vars)
     - Include responsive media queries for mobile, tablet, desktop
     - Add smooth transitions for interactive elements
     - Include focus-visible styles for accessibility
     - Use `@media (prefers-reduced-motion: reduce)` for animation safety
   - Keep styles scoped and minimal - prefer SLDS utility classes in HTML

   **File 4: `{componentName}.js-meta.xml`**
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
       <apiVersion>{API_VERSION}</apiVersion>
       <isExposed>true</isExposed>
       <masterLabel>{Component Label}</masterLabel>
       <description>{description from arguments}</description>
       <targets>
           <target>lightning__AppPage</target>
           <target>lightning__HomePage</target>
           <target>lightning__RecordPage</target>
           <target>lightning__Tab</target>
       </targets>
   </LightningComponentBundle>
   ```

3. **After generating**, list the files you created and briefly describe each.

## Example

If invoked as: `/scaffold-lwc accountManager - datatable showing accounts with inline edit`

Creates:
- `accountManager.js` — Component with @wire to fetch accounts, handles inline edit events, save/cancel logic
- `accountManager.html` — SLDS card with lightning-datatable, loading spinner, error banner
- `accountManager.css` — Responsive styles, focus management, transition effects
- `accountManager.js-meta.xml` — Metadata exposing the component to App/Home/Record pages
