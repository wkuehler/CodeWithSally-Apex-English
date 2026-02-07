# Workflow: code review workflow
Description: Conduct a code review given the criteiria below and generate the detailed markdown explanation to help an engineer identify different code smells, platform risks, etc within thieir selected files

<detailed_sequence_steps>
    Perform the steps below in order

## 1 - Ask which class or classes to review
<ask_followup_question>
    <question>Which Apex class or classes would you like me to review?</question>
</ask_followup_question>


ONLY if the user specific multiple files (or classes) ask the following followup questions: 
<ask_followup_question>
    <question>Would you like me to Generate a single combined markdown file or one per class?</question>
    <options>["A single file", "Create one markdown per class"]</options>
</ask_followup_question>


## 2. Ask the user what category they need reviewed?
<ask_followup_question>
    <question>Which category would you like reviewed?</question>
    <options>["Communication Smells", "Design Smells", "Platform Risks", "Team Process", "All Categories"]</options>
</ask_followup_question>


## 3. Based on the users input, read the files below and user it review the class(es) chosen by the user

    If the user chose "Communication Smells" choose this file:
<read_file> 
    <path>.a4drules/categories/communication_smells.md</path> 
</read_file>
    If the user chose "Design Smells" choose this file:
<read_file> 
    <path>.a4drules/categories/design_smell.md</path> 
</read_file>
    If the user chose "Platform Risks" choose this file:
<read_file> 
    <path>.a4drules/categories/platform_risks.md</path> 
</read_file>

    If the user chose "Team Process" choose this file:
<read_file> 
    <path>.a4drules/categories/team_process.md</path> 
</read_file>
    If the user chose "All Categories" choose all files from:
<read_file> 
    <path>.a4drules/categories</path> 
</read_file>


## 4. Format the result as a Markdown file
- Include clear Markdown structure with headings, bullet points, and code blocks.

## 5. Save the generated documentation
- Create a folder called `CodeReview` to store those md files in
- If user chose a single combined file:
  - Combine all class outputs into one Markdown file named:
    `ApexClasses_CodeReview.md`
- If user chose multiple files:
  - Save each class separately using:
    `<ClassName>_CodeReview.md`


</detailed_sequence_steps>



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
