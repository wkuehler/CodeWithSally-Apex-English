---
paths:
  - "force-app/**/classes/Test*.cls"
  - "force-app/**/classes/*Test.cls"
  - "**/__tests__/**"
---

# Test Conventions (Cross-Cutting)

IMPORTANT: Include the tag `[TESTS]` somewhere in your response on its own line when this rule is loaded.

This rule loads for **both** Apex test classes and LWC Jest specs — one rule spanning multiple directories via glob unions.

- **Apex tests:** `@IsTest` classes and methods, `Test.startTest()` / `Test.stopTest()` around the code under test, data created in `@TestSetup`. Aim above the 75% platform minimum.
- **LWC tests:** Use `@salesforce/sfdx-lwc-jest`. Specs live in `__tests__/` alongside the component. Mock `@wire` adapters with `createApexTestWireAdapter`; mock imperative Apex with `jest.mock`.
- Never rely on org data — create fixtures in the test itself.
