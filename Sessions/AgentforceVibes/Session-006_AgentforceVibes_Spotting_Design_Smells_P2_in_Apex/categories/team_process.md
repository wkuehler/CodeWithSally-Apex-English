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
