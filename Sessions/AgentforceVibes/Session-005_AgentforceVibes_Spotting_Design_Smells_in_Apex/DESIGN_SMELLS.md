# Code Smell Detection Guide for Agentforce Vibes

A structured guide for identifying code quality issues that often pass static analysis. Organized by category, with clear evidence requirements and actionable outputs.

--- 

## Categories

This guide distinguishes four categories with different burdens of proof:

| Category | What It Means | Consequence |
|----------|---------------|-------------|
| **Platform Risk** | Will fail or cause security issues in production | Bug / outage / vulnerability |
| **Design Smell** | Hurts maintainability, coupling, or cohesion | Tech debt, harder changes |
| **Communication Smell** | Reduces readability or obscures intent | Slower onboarding, bugs from misunderstanding |
| **Team/Process Risk** | Organizational issues inferred from code patterns | Requires verification beyond code |

**Priority order**: Platform Risk > Design Smell > Communication Smell > Team/Process Risk

---

## Evidence Types

Not all evidence is available from code alone. Be explicit about what you can and cannot observe:

| Type | Description | Example |
|------|-------------|---------|
| **Observable** | Visible in the code snippet | "Method calls `insert` inside a for loop" |
| **Assumed** | Common in Salesforce but not provable from snippet | "This object likely has high volume" |
| **Needs Verification** | Requires git history, runtime data, or org context | "Check if this Record Type ID exists in target org" |

Label assumptions explicitly. Don't stuff them into "Interpretation."

---

## Output Rules

1. **Prefer 1–3 findings per file** if the top issues are high severity; max 5 if warranted
2. **One root cause per issue** — if multiple smells describe the same problem, report the most actionable one
3. **Platform risks always surface** — even if you hit the limit
4. **State confidence honestly** — "Low" is acceptable; hallucinated certainty is not
5. **No duplicate categories** — if it's a Platform Risk, don't also call it a Design Smell in the same finding
6. **Impact must match category**:
   - Platform Risk → `Governor Limits | Security | Data Integrity | Runtime Exception | Performance`
   - Design Smell → `Maintainability | Coupling | Cohesion | Testability`
   - Communication Smell → `Readability | Intent | API Predictability`
   - Team/Process Risk → `Bus Factor | Change Risk | Operational Risk`


### Tie-Break Rules

| Situation | Report This | Not This |
|-----------|-------------|----------|
| Huge class doing everything | God Object | Divergent Change (unless you have commit history) |
| Single method mixes levels | Inconsistent Abstraction | God Object (class may be fine) |
| Same logic in 5 places | Shotgun Surgery | Feature Envy (that's per-method) |
| Method uses other class's data heavily | Feature Envy | — |
| Platform limit will be hit | The specific platform risk | Any design smell |

## Response Format

```markdown
## Finding: [SMELL_NAME]
**Location**: [Class.method] | Lines [X-Y]
**Category**: [Platform Risk | Design Smell | Communication Smell | Team/Process Risk]
**Confidence**: [High | Medium | Low]
**Scope**: [Local | Cross-file (needs search) | Cross-repo (needs verification)]

**Evidence (observable)**:
- [Concrete observation from code]

**Evidence (assumed)**:
- [What you're assuming based on Salesforce norms — or omit if none]

**Evidence (needs verification)**:
- [What to check in git/org/runtime — or omit if none]

**Interpretation**:
- [Why this matches the smell]

**Falsification check**:
- [What would make this NOT a problem]

**Impact**: [Must match category per Output Rules]

**Suggested Refactor**:
1. [Smallest safe change]
2. [Next step if time permits]

**Priority**: [Critical | High | Medium | Low]
**Co-occurs with**: [Related smells to avoid duplicate reporting]
```

---

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

# DESIGN SMELLS

Issues affecting maintainability, coupling, and cohesion. These won't crash production but make the codebase harder to work with.

---

## DS-1: God Object

Class with too many responsibilities, violating Single Responsibility Principle.

**Signals**:
- Vague name: Manager, Handler, Processor, Utility, Helper
- Methods spanning multiple concerns: DB + email + calculations + external APIs
- High import count (many dependencies)
- Common threshold: 10+ unrelated public methods, 500+ lines

**Co-occurs with**: Divergent Change, Inconsistent Abstraction (report God Object if the class is the problem)

**Falsification**: Class is intentionally a Facade coordinating subsystems, with thin methods delegating to focused services.

**Refactor pattern**:
- Extract cohesive method groups into focused service classes
- God Object becomes thin orchestrator

**Impact**: Maintainability | Cohesion

**Priority**: High (in core business logic), Medium (in utilities)

---

## DS-2: Feature Envy

Method more interested in another class's data than its own.

**Signals**:
- Method calls 5+ getters on a single external object
- Method uses 0-1 fields from its own class
- Heavy use of a passed-in parameter vs `this`

**Co-occurs with**: Primitive Obsession, Data Clumps

**Falsification**: Method is intentionally a "mapper" or "transformer" between two domains.

**Refactor pattern**:
- Move method to the class whose data it uses
- Or, make the external class provide the computed result

**Impact**: Coupling

**Priority**: Medium

---

## DS-3: Shotgun Surgery

One conceptual change requires touching many files.

**Scope**: Cross-file (needs search)

**Signals**:
- Same validation logic in 5+ classes
- Duplicated formatting, calculation, or business rule
- Copy-pasted code with slight variations

**Co-occurs with**: Primitive Obsession (no shared abstraction)

**Falsification**: Duplication is intentional to avoid coupling (rare, should be documented).

**Refactor pattern**:
- Extract shared logic to a single utility or service
- Use a shared value object or domain class

**Impact**: Maintainability

**Priority**: Medium

---

## DS-4: Primitive Obsession

Using primitives instead of small domain objects.

**Signals**:
- Method with 5+ primitive parameters
- `String status` instead of `Status` enum
- Groups of parameters that always travel together (address fields, money fields)
- No type safety for important domain concepts

**Co-occurs with**: Data Clumps, Feature Envy

**Falsification**: Domain is genuinely simple and unlikely to grow.

**Refactor pattern**:
- Create value objects: `Address`, `Money`, `EmailAddress`
- Use enums for status/type fields

**Impact**: Maintainability | Testability

**Priority**: Medium

---

## DS-5: Data Clumps

Groups of fields/parameters that always appear together but aren't encapsulated.

**Signals**:
- Same 3+ parameters in multiple method signatures
- Instance variables always used together
- Address fields, date ranges, coordinates repeated everywhere

**Falsification**: Parameters are coincidentally similar but semantically different.

**Refactor pattern**:
- Create a class to hold the clump
- Pass the object instead of individual fields

**Impact**: Maintainability

**Priority**: Medium

---

## DS-6: Temporal Coupling

Methods that must be called in a specific order, but nothing enforces it.

**Signals**:
- Methods that fail if called out of sequence
- Comments like "must call initialize() first"
- State flags checked manually (`if (!isInitialized) throw`)

**Falsification**: Order is enforced by a state machine or builder pattern.

**Refactor pattern**:
- Use constructor injection for required state
- Use builder pattern that only exposes valid transitions
- Return new objects from each step (functional approach)

**Impact**: Maintainability | Testability

**Priority**: Medium

---

## DS-7: Hidden Dependencies

Method relies on state not visible in its signature.

**Signals**:
- Method uses singletons (`getInstance()`)
- Method calls static methods for configuration or context
- Method depends on global state
- Salesforce-specific hidden dependencies:
  - `UserInfo.getUserId()`, `UserInfo.getSessionId()`
  - `Limits.getQueries()`, `Limits.getDmlStatements()`
  - `System.now()`, `System.today()`
  - `Test.isRunningTest()`
  - `CustomSetting__c.getInstance()`, `CustomSetting__c.getOrgDefaults()`

**Falsification**: Dependency is a true global (logging, metrics) where injection adds no value.

**Refactor pattern**:
- Pass dependencies as parameters
- Use dependency injection
- For time: pass `Datetime` parameter with default `System.now()`
- For settings: inject configuration object

**Impact**: Testability | Coupling

**Priority**: Medium

---

## DS-8: Speculative Generality

Abstraction built for hypothetical future needs.

**Signals**:
- Abstract class with only one implementation
- Unused parameters or configuration options
- Plugin/hook architecture with single plugin

**Evidence (needs verification)**: Check git history — has the abstraction been used in 6+ months?

**Falsification**: Extension is planned for imminent release.

**Refactor pattern**:
- Remove unused abstraction
- Add abstraction when second use case appears (YAGNI)

**Impact**: Maintainability

**Priority**: Low

---

## DS-9: Middle Man

Class that only delegates without adding value.

**Signals**:
- Every method is a one-liner calling another class
- No transformation, validation, or logic added
- Wrapper that doesn't wrap anything meaningful

**Falsification**: Class exists for API stability, dependency inversion, or access control.

**Refactor pattern**:
- Remove the middle man
- Have callers use the underlying class directly

**Impact**: Maintainability

**Priority**: Low

---

## DS-10A: Swallowed Errors

Catching exceptions without handling or propagating them.

**Signals**:
- Empty catch blocks: `catch (Exception e) { }`
- Catch blocks that only log and continue
- Returning `null` on error (caller can't distinguish from valid null)
- No rethrow after partial handling

**Falsification**: Error is genuinely ignorable and documented as such.

**Refactor pattern**:
```apex
// Before
try {
    doSomething();
} catch (Exception e) {
    System.debug(e);  // Swallowed
}

// After - rethrow with context
try {
    doSomething();
} catch (Exception e) {
    // Log with context for debugging
    System.debug(LoggingLevel.ERROR, 
        'MyClass.myMethod failed: ' + e.getTypeName() + ': ' + e.getMessage());
    System.debug(LoggingLevel.ERROR, e.getStackTraceString());
    // Rethrow (optionally wrap in custom exception)
    throw new MyException('Operation failed for record ' + recordId, e);
}
```

Note: Apex exception constructors vary — `new MyException(message, cause)` works if your custom exception extends `Exception` properly. Otherwise, include original exception details in the message.

**Impact**: Maintainability | Testability

**Priority**: High (in critical paths), Medium (in utilities)

---

## DS-10B: Low-Context Error Handling

Errors logged or thrown without enough information to debug.

**Signals**:
- Log messages without record IDs or operation name
- Generic messages: "An error occurred"
- Exception message doesn't include input values or state
- No correlation ID for tracing across systems

**Falsification**: Context is available through other means (centralized logging with request ID).

**Refactor pattern**:
```apex
// Before
System.debug('Error: ' + e.getMessage());

// After
System.debug(LoggingLevel.ERROR, 
    'OrderService.processOrder failed | ' +
    'OrderId=' + orderId + ' | ' +
    'Status=' + status + ' | ' +
    'Error=' + e.getMessage());
```

**Impact**: Maintainability

**Priority**: Medium

---

## DS-11: Inconsistent Abstraction Levels

Single method mixing high-level concepts with low-level details.

**Signals**:
- Business logic alongside string manipulation
- HTTP setup details next to domain operations
- SQL queries inline with business rules
- API response parsing mixed with business decisions

**Note**: This is a design smell (affects maintainability and separation of concerns), not just communication.

**Falsification**: Method is intentionally a "glue" layer with no better home.

**Refactor pattern**:
- Extract low-level details to helper methods
- Keep each method at one abstraction level

**Impact**: Maintainability | Cohesion

**Priority**: Medium

---

# COMMUNICATION SMELLS

Issues that obscure intent and hurt readability.

---

## CS-1: Misleading Names

Names that don't match behavior.

**Signals**:
- `get*` methods that modify state
- `validate*` methods that insert/update records
- `check*` methods that send emails
- Variables named `temp`, `data`, `obj`, `result` without context

**Falsification**: None — names should match behavior.

**Refactor pattern**:
- Rename to match actual behavior
- Or split method so the name becomes accurate

**Impact**: Intent | API Predictability

**Priority**: High

---

## CS-2: Inconsistent Naming

Same operation named differently across codebase.

**Scope**: Cross-file (needs search)

**Signals**:
- Mixed verbs: `get/fetch/retrieve/obtain`, `delete/remove/destroy`
- Mixed prefixes: `is/has/can/check/verify` for booleans
- Mixed styles: `getUser()`, `fetch_customer()`, `RetrieveAccount()`

**Falsification**: Different names reflect genuinely different semantics.

**Refactor pattern**:
- Establish naming conventions
- Refactor for consistency

**Impact**: Readability | API Predictability

**Priority**: Medium

---

## CS-3: Magic Values

Literals without explanation.

**Signals**:
- `if (status == 3)` — what is 3?
- `if (amount > 5000)` — why 5000?
- String literals for important comparisons: `if (type == "premium")`

**Falsification**: Value is self-evident in context (e.g., `if (count == 0)`).

**Refactor pattern**:
- Extract to named constant
- Use enum for status/type values

**Impact**: Readability | Intent

**Priority**: Medium

---

## CS-4: Comments Explaining What, Not Why

Comments that restate code instead of explaining intent.

**Signals**:
- `// Loop through orders` above `for (Order o : orders)`
- `// Set status to 3` instead of explaining what 3 means
- Complex business logic with no comment explaining the rule

**Falsification**: Comment is genuinely clarifying a non-obvious "what" (e.g., regex explanation).

**Refactor pattern**:
- Delete obvious comments
- Add comments explaining business rules and "why"
- Improve naming to eliminate need for "what" comments

**Impact**: Readability

**Priority**: Low

---

# TEAM/PROCESS RISKS

These are inferred from code patterns but require verification beyond the code itself.

---

## TP-1: Knowledge Silo (Inferred)

Code that appears to be understood by only one person.

**Scope**: Cross-repo (needs verification)

**Signals (observable)**:
- Complex algorithms without comments or documentation
- Non-obvious business rules with no explanation
- Unclear variable names in critical logic

**Signals (needs verification)**:
- Only one author in git history
- Comments like "Ask [Name] about this"
- Team reports only one person can modify it

**Falsification**: Code is well-tested and team has documented knowledge elsewhere.

**Action**: Flag for documentation or pairing, not immediate refactoring.

**Impact**: Bus Factor

**Priority**: Medium

---

## TP-2: Copy-Paste Inheritance (Inferred)

Similar code duplicated instead of abstracted.

**Scope**: Cross-file (needs search)

**Signals (observable)**:
- Methods that are 90% identical with slight variations
- Parallel class structures with repeated logic
- Same bug pattern likely in multiple places

**Signals (needs verification)**:
- Git history shows copy-paste commits
- Bug fixes applied to multiple files

**Falsification**: Duplication is intentional to allow independent evolution.

**Refactor pattern**:
- Extract common logic to shared base or utility
- Use composition or strategy pattern for variations

**Impact**: Change Risk

**Priority**: Medium

---

## TP-3: Dead Code (Inferred)

Code paths that appear unreachable.

**Scope**: Cross-repo (needs verification)

**Signals (observable)**:
- Conditional branches for values that don't seem to exist
- Methods with no apparent callers in the codebase
- Feature flags that appear always set one way

**Signals (needs verification)**:
- Runtime telemetry shows zero executions
- Data queries confirm no records with legacy values
- Git history shows feature was migrated away

**Action**: Confirm before removing. Flag as "appears dead — verify before deletion."

**Impact**: Operational Risk

**Priority**: Low

---

# Quick Reference

## Platform Risks (Critical/High)
| Code | Name | Key Signal | Impact |
|------|------|------------|--------|
| PR-1 | Non-Bulkified | DML/SOQL in loops | Governor Limits |
| PR-2 | Undeclared Sharing | No sharing declaration | Security |
| PR-3 | Missing CRUD/FLS | No security check on user-facing data | Security |
| PR-4 | Unbounded Query | High-volume object, weak filters | Performance |
| PR-5 | Missing Idempotency | Insert without existence check | Data Integrity |
| PR-6 | Test Anti-Patterns | seeAllData, no assertions | Data Integrity |
| PR-7 | Missing Null Safety | list[0] without size check | Runtime Exception |

## Design Smells (High/Medium)
| Code | Name | Key Signal | Impact |
|------|------|------------|--------|
| DS-1 | God Object | 10+ unrelated methods, vague name | Cohesion |
| DS-2 | Feature Envy | Method uses other class's data | Coupling |
| DS-3 | Shotgun Surgery | Same logic in 5+ places | Maintainability |
| DS-4 | Primitive Obsession | 5+ primitive params, no value objects | Maintainability |
| DS-5 | Data Clumps | Same fields always together | Maintainability |
| DS-6 | Temporal Coupling | Must call methods in order | Testability |
| DS-7 | Hidden Dependencies | UserInfo, System.now(), singletons | Testability |
| DS-8 | Speculative Generality | Abstraction with one implementation | Maintainability |
| DS-9 | Middle Man | Only delegates, no added value | Maintainability |
| DS-10A | Swallowed Errors | Empty catch, null returns | Maintainability |
| DS-10B | Low-Context Errors | Logs without record IDs | Maintainability |
| DS-11 | Inconsistent Abstraction | Business logic + string parsing | Cohesion |

## Communication Smells (Medium/Low)
| Code | Name | Key Signal | Impact |
|------|------|------------|--------|
| CS-1 | Misleading Names | get* that modifies, validate* that inserts | Intent |
| CS-2 | Inconsistent Naming | get/fetch/retrieve mixed | Readability |
| CS-3 | Magic Values | `if (status == 3)` | Readability |
| CS-4 | What-Not-Why Comments | Comments restate code | Readability |

## Team/Process Risks (Verify First)
| Code | Name | Key Signal | Impact |
|------|------|------------|--------|
| TP-1 | Knowledge Silo | Complex code, no docs, single author | Bus Factor |
| TP-2 | Copy-Paste | 90% identical methods | Change Risk |
| TP-3 | Dead Code | Unreachable branches, no callers | Operational Risk |

---

# When NOT to Flag

Context matters. Don't flag if:

- **God Object**: Class is an intentional Facade with thin delegation methods
- **Speculative Generality**: Extension is planned for next sprint
- **Middle Man**: Layer exists for API stability or access control
- **Temporal Coupling**: Order is enforced by builder/state machine pattern
- **Missing CRUD/FLS (PR-3)**: Code is internal-only with no user-facing data flow
- **Non-Bulkified**: Private method documented as single-record-only — **still flag with Low confidence** and note fragility (triggers can receive 200 records; future reuse breaks assumption)

**General principle**: If the pattern exists for a documented, intentional reason, it's not a smell — it's a tradeoff. Note it and move on.


---

# Threshold Signals, Not Rules

Numbers like "10+ methods" or "500+ lines" are heuristics. Flag only if the story matches the smell:

- A 600-line class that's a well-documented state machine isn't a God Object
- A method with 6 parameters that are genuinely independent isn't Data Clumps
- 3 similar methods might be coincidence; 7 is a pattern

Use judgment. The goal is maintainability, not checkbox compliance.
