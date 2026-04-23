# Apex Conventions — force-app/main/default/classes/

IMPORTANT: Include the tag `[APEX]` somewhere in your response on its own line when these rules are loaded.

## Security & sharing

- Default every class to `with sharing` unless there is a documented reason to use `without sharing` or `inherited sharing`.
- Enforce FLS/CRUD with `WITH USER_MODE` on SOQL/DML, or `Security.stripInaccessible` on records returned from queries.
- For dynamic SOQL, pass user input through `String.escapeSingleQuotes` before concatenation.

## Bulkification

- Never place SOQL or DML inside a loop — collect IDs, query once, operate on lists.
- Use `Database.insert(records, false)` (and similar) with `Database.SaveResult[]` when partial success is acceptable.

## Controllers called from LWC

- Use `@AuraEnabled(cacheable=true)` for read-only methods consumed by `@wire`.
- Return typed shapes (custom wrapper classes or SObjects) — avoid `Map<String, Object>` returns.
- Throw `AuraHandledException` with a user-safe message; never surface raw stack traces to the client.

## Tests

- Every class needs a matching test class in this directory. Dreamhouse mixes two naming styles (`TestPropertyController.cls` and `FileUtilitiesTest.cls`) — match the style already used for the class you're editing.
- Use `@IsTest` on classes and methods, and wrap the code under test in `Test.startTest()` / `Test.stopTest()`.
- Create test data in `@TestSetup` methods; do not rely on org data.
- Aim above the 75% platform minimum; most classes here exceed 90%.
