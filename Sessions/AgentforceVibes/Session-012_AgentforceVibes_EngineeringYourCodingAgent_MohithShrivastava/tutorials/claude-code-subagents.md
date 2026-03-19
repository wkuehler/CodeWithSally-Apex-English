# Claude Code: Subagents, Agent Teams & Skills

> Build faster by teaching Claude Code to delegate, coordinate, and automate.

This tutorial introduces three patterns that scale Claude Code beyond single prompts: **subagents** for parallel work, **agent teams** for coordinated analysis, and **skills** for reusable automation. Each example uses this Salesforce DX project so you can try them immediately.

**Prerequisites**: Complete the [Agentforce Vibes & Hooks](./agentforce-vibes-hooks.md) tutorial first, or at least have Claude Code installed and this project open.

---

## Quick Reference

| Pattern | When to Use | How It Works |
|---|---|---|
| **Subagent** | Parallel independent tasks | Main agent spawns workers, each returns a result |
| **Agent Team** | Coordinated multi-step work | Team lead assigns tasks via shared list, teammates communicate |
| **Skill** | Reusable automation | Markdown file defines a slash command anyone can invoke |

---

## Pattern 1: Subagents

Subagents are independent workers that the main agent spawns in parallel. Each subagent gets a focused task, does its work, and reports back. They don't talk to each other — the main agent synthesizes all results at the end.

```
               ┌─────────────────┐
               │   Main Agent    │
               │  (orchestrator) │
               └────────┬────────┘
                         │ spawns
            ┌────────────┼────────────┐
            ▼            ▼            ▼
     ┌─────────┐  ┌─────────┐  ┌─────────┐
     │Subagent │  │Subagent │  │Subagent │
     │    1    │  │    2    │  │    3    │
     │  Apex   │  │   LWC   │  │  Tests  │
     └────┬────┘  └────┬────┘  └────┬────┘
          │            │            │
          ▼            ▼            ▼
       results      results      results
          │            │            │
          └────────────┼────────────┘
                       ▼
               ┌─────────────────┐
               │   Main Agent    │
               │  (synthesizes)  │
               └─────────────────┘
```

### Salesforce Example: Build an Account Management Feature

Try this prompt in Claude Code:

```
Build an Account Management feature using subagents:

- Subagent 1: Create an AccountService Apex class in force-app/main/default/classes/
  with CRUD methods (createAccount, getAccountById, updateAccount, deleteAccount).
  Include the .cls-meta.xml with API version 66.0.

- Subagent 2: Create an accountManager LWC in force-app/main/default/lwc/
  with a datatable showing accounts and inline edit support.
  Read the existing workflowVisualizer component first to match conventions.
  Include .js, .html, .css, and .js-meta.xml files.

- Subagent 3: Create AccountServiceTest in force-app/main/default/classes/
  with @IsTest methods covering all CRUD operations.
  Include @TestSetup for shared test data. Include the .cls-meta.xml.

Run all three subagents in parallel, then summarize what was created.
```

Claude Code will launch three parallel workers. Each one reads what it needs, generates its files, and reports back. The main agent then gives you a unified summary.

### When to Use Subagents

- **Building multiple components at once** — Apex service + LWC + tests
- **Generating boilerplate in bulk** — permission sets, layouts, meta XML files
- **Independent research tasks** — "Read these 5 files and summarize each"
- **Any task where parts don't depend on each other**

### Key Characteristics

- Subagents run in **parallel** — total time is roughly the slowest subagent
- No communication between subagents — they can't see each other's work
- The main agent is responsible for combining results
- Each subagent has its own tool access and context

---

## Pattern 2: Agent Teams

Agent teams go beyond subagents by adding **coordination**. A team lead manages a shared task list, and teammates can see each other's progress and findings. This matters when one agent's output affects another's work.

```
               ┌─────────────────┐
               │    Team Lead    │
               │  (coordinates)  │
               └────────┬────────┘
                        │ assigns tasks
                        ▼
               ┌─────────────────┐
               │  Shared Tasks   │
               │  ┌───────────┐  │
               │  │ Task 1: ☑ │  │
               │  │ Task 2: ◻ │  │
               │  │ Task 3: ◻ │  │
               │  └───────────┘  │
               └────────┬────────┘
            ┌───────────┼───────────┐
            ▼                       ▼
     ┌─────────────┐        ┌─────────────┐
     │ Teammate 1  │───────▶│ Teammate 2  │
     │ Apex Audit  │◀───────│ Perms Audit │
     └──────┬──────┘        └──────┬──────┘
            │    cross-reference    │
            ▼                       ▼
     ┌─────────────────────────────────┐
     │         Team Lead               │
     │   (unified report)              │
     └─────────────────────────────────┘
```

### Salesforce Example: Security Review

Try this prompt in Claude Code:

```
Perform a security review of this project using an agent team:

Team Lead: Coordinate the review and produce a unified security report.

Teammate 1 (Apex Security):
- Scan all Apex classes for "without sharing" usage
- Check for SOQL injection risks (dynamic queries without bind variables)
- Verify CRUD/FLS enforcement (Security.stripInaccessible or WITH SECURITY_ENFORCED)
- Check for hardcoded credentials or secrets
- Log all findings to the shared task list

Teammate 2 (Permissions & Metadata):
- Audit all permission sets for overly broad access
- Cross-reference permission set object access with Apex DML operations
- Check that LWC components have appropriate target configurations
- Review API version consistency across all meta.xml files
- Log findings and cross-reference with Teammate 1's Apex findings

After both teammates complete their analysis, produce a unified report
with prioritized recommendations.
```

The key difference from subagents: Teammate 2 can **read Teammate 1's findings** and cross-reference them. If Teammate 1 finds an Apex class using `without sharing`, Teammate 2 can check whether the permission set that grants access to that class is properly scoped.

### When to Use Agent Teams

- **Security reviews** — findings from one area inform analysis of another
- **Cross-cutting audits** — metadata consistency, naming conventions, dead code
- **Complex refactoring** — one teammate plans changes, another validates them
- **Any task where agents benefit from seeing each other's work**

### Key Characteristics

- Teammates communicate through a **shared task list**
- The team lead coordinates task assignment and synthesizes results
- Work can be sequential or parallel — the team lead decides
- Better for analysis and review than for code generation

---

## Subagents vs. Agent Teams

| | Subagents | Agent Teams |
|---|---|---|
| **Communication** | None between subagents | Teammates see each other's work |
| **Task dependency** | Fully independent | Can depend on each other |
| **Coordination** | Main agent only | Shared task list + team lead |
| **Speed** | Fastest (fully parallel) | Slower (coordination overhead) |
| **Best for** | Building components in parallel | Reviews, cross-cutting analysis |
| **Example** | "Create 3 components at once" | "Audit security across layers" |

**Rule of thumb**: If the tasks are independent, use subagents. If one agent's findings affect another agent's work, use a team.

---

## Pattern 3: Skills (Custom Slash Commands)

Skills are reusable prompts saved as markdown files. Type `/skill-name` in Claude Code and the prompt executes with its own tool permissions. Think of them as project-specific automation.

### Anatomy of a Skill File

```markdown
---
allowed-tools: Bash, Read, Write, Glob, Grep
description: What this skill does (shown in the picker)
---

# Skill Title

Instructions for Claude Code to follow when this skill is invoked.

Use $ARGUMENTS to access whatever the user types after the command.
```

### Where Skills Live

| Location | Scope | Who Can Use |
|---|---|---|
| `.claude/commands/` | Project | Anyone working in this repo |
| `~/.claude/commands/` | Personal | Only you, across all projects |

### Skills We Created

This project includes three skills in `.claude/commands/`:

#### `/generate-apex-class`

Generates an Apex class, its meta XML, a test class, and the test's meta XML. Follows Salesforce conventions: `with sharing`, `@IsTest`, PascalCase.

```
/generate-apex-class AccountService - handles CRUD operations for Account
```

Creates four files:
- `AccountService.cls` — The service class with stub methods
- `AccountService.cls-meta.xml` — Metadata with project API version
- `AccountServiceTest.cls` — Test class with `@TestSetup` and coverage
- `AccountServiceTest.cls-meta.xml` — Test metadata

#### `/scaffold-lwc`

Scaffolds a complete LWC. Reads the existing `workflowVisualizer` component first to match project conventions (SLDS patterns, accessibility, decorators).

```
/scaffold-lwc contactCard - displays contact details with edit capability
```

Creates four files:
- `contactCard.js` — Component logic with decorators and computed properties
- `contactCard.html` — SLDS-styled template with loading/error states
- `contactCard.css` — Responsive styles with accessibility and animation safety
- `contactCard.js-meta.xml` — Metadata exposing the component to pages

#### `/audit-metadata`

Read-only audit of project metadata health. Inventories all metadata, finds missing test classes, checks API version consistency, and flags empty directories.

```
/audit-metadata
```

Notice this skill only has `Bash, Read, Glob, Grep` — no `Write` or `Edit`. This is **principle of least privilege**: an audit skill should never modify your project.

### Skills + Subagents: Better Together

Skills compose naturally with subagent patterns. Try this:

```
Build a Contact management feature using subagents:

- Subagent 1: Run /generate-apex-class ContactService - CRUD operations for Contact
- Subagent 2: Run /scaffold-lwc contactList - datatable showing contacts with search
- Subagent 3: After the other two finish, run /audit-metadata to verify everything
```

Each subagent invokes a skill, bringing consistent generation patterns to parallel workflows.

---

## Putting It All Together

Here's a realistic developer workflow combining all three patterns:

**Morning**: You're starting a new feature — Account-Contact management.

1. **Use subagents** to generate the foundation in parallel:
   - Subagent 1: `/generate-apex-class AccountContactService - manages Account-Contact relationships`
   - Subagent 2: `/scaffold-lwc accountContactManager - dual datatable for accounts and contacts`

2. **Use an agent team** to review what was generated:
   - Teammate 1: Review the Apex for security (sharing rules, CRUD/FLS, SOQL safety)
   - Teammate 2: Review the LWC for accessibility (ARIA, keyboard nav, screen readers)
   - Team lead: Produce a unified list of issues to fix

3. **Fix issues** from the review — Claude Code handles them in a single conversation

4. **Run `/audit-metadata`** to verify everything is consistent before committing

This workflow uses skills for reusable generation, subagents for parallel speed, and agent teams for thorough review — each pattern where it fits best.

---

## Tips

- **Start with skills** — they're the simplest pattern and pay off immediately
- **Subagents are fast but isolated** — don't use them when tasks need to share context
- **Agent teams have overhead** — only use them when cross-referencing matters
- **Principle of least privilege** — give each skill only the tools it needs (like our read-only audit)
- **Read before generating** — skills that read existing code first (like `/scaffold-lwc`) produce more consistent output
- **Compose patterns freely** — subagents can invoke skills, agent teams can use subagent findings
- **Keep skills focused** — one clear purpose per skill is better than one skill that does everything
