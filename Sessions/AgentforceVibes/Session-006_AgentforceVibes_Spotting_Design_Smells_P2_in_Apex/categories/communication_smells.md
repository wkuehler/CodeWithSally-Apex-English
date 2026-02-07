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
