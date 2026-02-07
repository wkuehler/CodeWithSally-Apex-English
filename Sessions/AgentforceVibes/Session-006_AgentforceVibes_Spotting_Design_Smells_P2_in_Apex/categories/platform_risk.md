# PLATFORM RISKS (Salesforce/Apex)

These are correctness and security issues, not just "smells." They cause production failures.

---

## PR-1: Non-Bulkified Code (DML/SOQL in Loops)

Database operations inside loops will hit governor limits with sufficient data volume.

**Signals**:
- `insert`, `update`, `delete`, `upsert` inside any loop construct
- SOQL query `[SELECT ...]` inside a loop
- Method calls inside loops where the method contains DML/SOQL (trace into them)
- Try/catch wrapping DML inside a loop (often `DmlException`)
- Methods named `create*`, `save*`, `update*`, `process*` called from loops

**Detection approach**:
1. Find all loops (`for`, `while`, `do`)
2. Check loop body for direct DML/SOQL
3. For each method call in loop body, trace into it recursively
4. Flag if any path contains DML/SOQL

**Falsification**: Method is private and documented as single-record-only. **Still flag with lower confidence** — triggers receive up to 200 records, and future code reuse breaks this assumption. Note the fragility explicitly.

**Refactor pattern**:
- Collect sObjects in a List outside the loop
- Perform single bulk DML after the loop: `Database.insert(records, false)`
- For SOQL, query once with `WHERE Id IN :idSet` before the loop

**Impact**: Governor Limits

**Priority**: Critical

---

## PR-2: Undeclared Sharing Posture

Class runs in system mode without explicit declaration, creating unclear security posture.

**Signals**:
- Class declared without `with sharing`, `without sharing`, or `inherited sharing`
- No documentation explaining security posture

**Nuance**:
- `with sharing` is the safe default for user-context code
- `without sharing` is valid for system operations — but should be documented
- `inherited sharing` is often safest for utility/library classes
- The smell is *unintentional* or *undeclared* posture, not system mode itself

**Falsification**: Class is intentionally `without sharing` for a documented reason (e.g., background job, platform event handler, system integration).

**Refactor pattern**:
- Add explicit sharing declaration to all classes
- Document any `without sharing` with a comment explaining why

**Impact**: Security

**Priority**: High

---

## PR-3: Missing CRUD/FLS Enforcement

Data returned to users without field/object-level security checks.

**Signals**:
- SOQL without `WITH SECURITY_ENFORCED` or `WITH USER_MODE`
- DML without `AccessLevel.USER_MODE`
- No `Security.stripInaccessible()` before returning data
- No `Schema.sObjectType.*.isAccessible()` checks

**When this matters**:
- Data flows to UI (Visualforce, LWC, Aura)
- Data returned from `@AuraEnabled` methods (especially `cacheable=true`)
- Data returned via LWC wire adapters or imperative Apex calls
- Data returned via API (REST, SOAP, Platform Events)
- Data included in emails or external callouts
- Any user-facing outcome

**When this may NOT matter**:
- Purely internal processing with no user exposure
- System-to-system integration with service account
- Operations on fields the user already sees elsewhere

**Falsification**: Code is internal-only, operates on safe/universal fields, or security is enforced at a higher layer.

**Refactor pattern**:
- Use `WITH USER_MODE` in SOQL
- Use `Security.stripInaccessible()` before returning data
- Check `Schema.sObjectType.*.isAccessible()` for dynamic access

**Impact**: Security

**Priority**: Critical (when user-facing), Medium (internal processing)

---

## PR-4: Unbounded or Non-Selective Queries

Queries on high-volume objects without adequate filtering.

**Signals (observable)**:
- Query on commonly high-volume objects (Lead, Contact, Task, Event, EmailMessage) or objects used for operational logging / activity tracking
- Weak or absent WHERE clause
- Runs in batch `start()`, trigger, or scheduled context
- `LIMIT` used as a band-aid for unfiltered query

**Signals (assumed)**:
- Object has high record count based on its purpose (activity logs, events, transactions)
- Fields in WHERE clause may not be selective

**Signals (needs verification)**:
- Check Query Plan in Developer Console for selectivity
- Verify data distribution and cardinality
- Check for data skew on filter fields
- Confirm custom indexes exist

**Falsification**: Object is known to have low record count, or query is in test context only.

**Refactor pattern**:
- Add filters on indexed/selective fields (Id, lookup, external ID, custom indexed)
- Use `Database.QueryLocator` with selective filters in batch
- Consider Platform Events or Change Data Capture for high-volume processing

**Impact**: Performance | Governor Limits

**Priority**: High (runtime failure at scale)

---

## PR-5: Missing Idempotency

Operations that create duplicates when retried or re-executed.

**Signals**:
- `INSERT` without checking for existing records
- No External Id for upsert operations
- No guard field (e.g., `Welcome_Email_Sent__c`) preventing re-processing
- Code callable from Flows, triggers, or APIs (all can retry)

**Falsification**: Operation is intentionally non-idempotent (e.g., logging every invocation).

**Refactor pattern**:
- Query for existing records before insert, or use `UPSERT` with External Id
- Add guard fields to parent records
- Use deterministic keys for child record creation

**Impact**: Data Integrity

**Priority**: High

---

## PR-6: Test Anti-Patterns

Tests that don't follow Salesforce testing best practices.

**Signals**:
- `@isTest(seeAllData=true)` — tests depend on org data
- No `Test.startTest()` / `Test.stopTest()` — async not executed, governors not reset
- No assertions, or assertions only checking for no exceptions
- No bulk tests (200+ records)
- Data created inline instead of `@TestSetup`

**Falsification**: `seeAllData=true` is required for specific platform features (rare).

**Refactor pattern**:
- Use `@TestSetup` for reusable test data
- Wrap test logic in `Test.startTest()` / `Test.stopTest()`
- Add meaningful assertions for expected behavior
- Include bulk and negative test cases

**Impact**: Data Integrity (unreliable tests)

**Priority**: Medium

---

## PR-7: Missing Null Safety in Bulk Context

Unsafe assumptions that cause runtime exceptions in bulk operations.

**Signals**:
- `list[0]` access without size check
- `map.get(key).Field__c` without null guard
- SOQL assumed to return a record without `isEmpty()` check
- `Trigger.new[0]` access (triggers can have 1-200 records)
- Chained method calls without null checks: `record.getRelated().getField()`

**Detection approach**:
1. Find collection access (`list[index]`, `map.get()`)
2. Check if guarded by size/null check
3. Flag unguarded access, especially in trigger/batch context

**Falsification**: Access is guaranteed by prior logic (e.g., `if (!list.isEmpty())` before access). Verify the guard is actually present.

**Refactor pattern**:
```apex
// Before
Account acc = [SELECT Id FROM Account WHERE Name = :name];
acc.Description = 'Updated';  // Fails if no match

// After
List<Account> accs = [SELECT Id FROM Account WHERE Name = :name];
if (!accs.isEmpty()) {
    accs[0].Description = 'Updated';
}

// Or use safe navigation (Winter '21+)
String val = record?.Related__r?.Field__c;
```

**Impact**: Runtime Exception

**Priority**: High (causes "random" bulk failures)

---
