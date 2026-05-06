# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Salesforce DX project named **DetailedNotes**, targeting API version 66.0. The goal is to build Lightning Web Components (LWC) to improve team quality-of-life workflows. The first component is **Detailed Notes**.

All source metadata lives under `force-app/main/default/` and is organized by metadata type (lwc, classes, triggers, objects, etc.).

## Common Commands

```bash
# Lint LWC and Aura JavaScript
npm run lint

# Run all unit tests
npm run test

# Run tests in watch mode
npm run test:unit:watch

# Run tests for a single component
npx sfdx-lwc-jest --testPathPattern="force-app/main/default/lwc/<componentName>"

# Run tests with coverage
npm run test:unit:coverage

# Format all files
npm run prettier

# Verify formatting without writing
npm run prettier:verify
```

**Salesforce CLI (sf/sfdx) commands:**
```bash
# Authorize an org
sf org login web --alias my-org

# Create a scratch org
sf org create scratch --definition-file config/project-scratch-def.json --alias my-scratch --duration-days 7

# Push source to scratch org
sf project deploy start

# Pull changes from org
sf project retrieve start

# Open the scratch org
sf org open

# Run Apex anonymously
sf apex run --file scripts/apex/hello.apex
```

## Architecture

### Metadata structure
- `force-app/main/default/lwc/` — Lightning Web Components (JS + HTML + CSS + test)
- `force-app/main/default/classes/` — Apex server-side controllers
- `force-app/main/default/triggers/` — Apex triggers
- `force-app/main/default/objects/` — Custom object/field definitions
- `force-app/main/default/flexipages/` — Lightning App Builder page layouts
- `force-app/main/default/permissionsets/` — Permission set definitions

### LWC conventions
Each component lives in its own folder matching its API name. Tests go in `__tests__/` inside the component folder (e.g., `lwc/myComponent/__tests__/myComponent.test.js`). Jest is configured via `@salesforce/sfdx-lwc-jest` with standard Salesforce mock resolution.

### Apex ↔ LWC data flow
LWC components call Apex via `@wire` (reactive) or imperative `import` from `@salesforce/apex/ClassName.methodName`. Apex methods exposed to LWC must be `@AuraEnabled`.

### Pre-commit hooks
Husky runs `lint-staged` on every commit: Prettier formats staged files, ESLint checks LWC/Aura JS, and Jest runs tests related to changed LWC files (`--bail --findRelatedTests`).

## Tooling Notes

- ESLint uses `@salesforce/eslint-config-lwc/recommended` for LWC files and `@salesforce/eslint-plugin-aura` for Aura. The `@lwc/lwc/no-unexpected-wire-adapter-usages` rule is disabled in test files.
- Prettier uses `prettier-plugin-apex` for Apex classes and `@prettier/plugin-xml` for XML metadata. LWC HTML files use the `lwc` parser.
- Scratch org edition is Developer with Lightning Experience enabled (`config/project-scratch-def.json`).
