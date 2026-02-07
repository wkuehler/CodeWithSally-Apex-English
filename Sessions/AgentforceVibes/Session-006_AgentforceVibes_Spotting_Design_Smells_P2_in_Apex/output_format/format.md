
## Response Format

Use this format for each code review finding. 

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
