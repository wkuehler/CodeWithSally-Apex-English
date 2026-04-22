---
paths:
  - "force-app/**/classes/**"
---

# Apex Conventions

IMPORTANT: Include the tag `[APEX]` somewhere in your response on its own line when this rule is loaded.

- Default classes to `with sharing` unless there is a documented reason otherwise.
- Enforce FLS/CRUD with `WITH USER_MODE` on SOQL/DML, or `Security.stripInaccessible` on query results.
- Bulkify: never run SOQL or DML inside a loop.
- `@AuraEnabled(cacheable=true)` for read-only methods consumed by LWC `@wire`.
- Throw `AuraHandledException` with a user-safe message; never surface raw stack traces.
