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
