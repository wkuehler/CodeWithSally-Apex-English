# Engineering Your Coding Agent

**Agentforce Vibes + Claude Code | Rules, Skills, Hooks & Subagents**

This repo is the companion project for the [Code With Sally session on Engineering Your Coding Agent](https://www.youtube.com/watch?v=Fj31gh4iNdk). It walks you through configuring two AI coding agents — **Agentforce Vibes** (Salesforce's VS Code extension) and **Claude Code** (Anthropic's CLI) — using Rules, Skills, Hooks, and Subagents to make them work the way *you* want.

The idea is simple: instead of prompting your coding agent from scratch every time, you **engineer** it. You define reusable skills, set up automated quality gates with hooks, and teach it to delegate work to subagents. The result is an agent that formats its own code, follows your project conventions, and builds features in parallel — without you micromanaging every step.

---

## What's Inside

```
.
├── .a4drules/                  # Agentforce Vibes configuration
│   ├── hooks/
│   │   └── PostToolUse         # Auto-format & lint hook (Prettier + ESLint)
│   └── skills/
│       └── salesforce-screen-flow-builder/
│           ├── SKILL.md        # Screen Flow builder skill
│           └── resources/      # Flow metadata references & examples
│               ├── flow-metadata-reference.md    # XML structure, enums, connectors
│               ├── screen-field-types.md         # All screen field types with XML
│               ├── element-patterns.md           # Decisions, loops, DML, formulas
│               ├── example-data-entry-flow.xml   # Multi-screen form example
│               └── example-record-lookup-flow.xml # Datatable + query example
│
├── .claude/                    # Claude Code configuration
│   └── commands/
│       ├── audit-metadata.md   # /audit-metadata — read-only project health check
│       ├── generate-apex-class.md  # /generate-apex-class — Apex + test scaffolding
│       └── scaffold-lwc.md     # /scaffold-lwc — LWC scaffolding
│
├── tutorials/                  # Step-by-step guides
│   ├── agentforce-vibes-hooks.md   # How to build hooks for Agentforce Vibes
│   └── claude-code-subagents.md    # Subagents, Agent Teams & Skills patterns
│
├── force-app/                  # Example Salesforce app (Apex, LWC, Flows)
├── config/                     # Scratch org definition
├── scripts/                    # Example SOQL & anonymous Apex scripts
└── sfdx-project.json           # Salesforce DX project config (API v66.0)
```

---

## Agentforce Vibes: Rules, Skills & Hooks

> **Where to look:** [`.a4drules/`](.a4drules/)

Agentforce Vibes reads its configuration from the `.a4drules` directory at the root of your project. This is where you define how the agent behaves.

### Hooks — Automated Quality Gates

**File:** [`.a4drules/hooks/PostToolUse`](.a4drules/hooks/PostToolUse)

Hooks are lifecycle callbacks that fire at key moments during an Agentforce Vibes session. Our `PostToolUse` hook runs every time the agent writes a file and:

1. **Auto-formats** with Prettier (supports `.cls`, `.js`, `.html`, `.xml`, `.css`, `.trigger`, `.cmp`, `.page`)
2. **Lints** JavaScript files in `aura/` or `lwc/` directories with ESLint
3. **Feeds errors back** to the agent via `contextModification` so it self-corrects

The agent sees the lint output, fixes the issue in its next action, and moves on — no follow-up prompt from you required.

Agentforce Vibes supports eight hook types:

| Hook | When It Fires |
|---|---|
| `PreRequest` | Before a prompt is sent to the LLM |
| `PostRequest` | After the LLM responds |
| `PreToolUse` | Before a tool call executes |
| `PostToolUse` | After a tool call completes |
| `PreTask` | When a task begins |
| `PostTask` | When a task ends |
| `OnError` | When an error occurs |
| `ContextUpdate` | When the conversation context changes |

**Full tutorial:** [`tutorials/agentforce-vibes-hooks.md`](tutorials/agentforce-vibes-hooks.md)

### Skills — Reusable Domain Knowledge

**File:** [`.a4drules/skills/salesforce-screen-flow-builder/SKILL.md`](.a4drules/skills/salesforce-screen-flow-builder/SKILL.md)

Skills give the agent deep, reusable expertise on a specific topic. The **Salesforce Screen Flow Builder** skill teaches Agentforce Vibes how to generate valid, deployable `.flow-meta.xml` files — the actual metadata XML that Salesforce reads.

The skill includes a `resources/` folder with reference material the agent loads progressively:

| Resource | What It Provides |
|---|---|
| `flow-metadata-reference.md` | Root XML structure, all enums, connector types, value types |
| `screen-field-types.md` | Every screen field type with XML (InputField, DisplayText, ComponentInstance, RegionContainer, etc.) |
| `element-patterns.md` | Decisions, loops, record operations, formulas, choices, subflows with XML |
| `example-data-entry-flow.xml` | Complete multi-screen form with two-column layouts, dropdowns, and error handling |
| `example-record-lookup-flow.xml` | Record query with datatable, decision branching, and formulas |

The agent reads only the resources it needs for the current request, keeping context efficient while having deep metadata knowledge available.

---

## Claude Code: Subagents & Skills

> **Where to look:** [`.claude/`](.claude/)

Claude Code reads slash-command skills from `.claude/commands/`. These are markdown files that define reusable automation — type the command and Claude Code executes the full prompt.

### Skills (Slash Commands)

| Command | What It Does | Tools |
|---|---|---|
| `/generate-apex-class` | Scaffolds an Apex class + meta XML + test class + test meta XML | Read, Write, Glob, Grep, Bash |
| `/scaffold-lwc` | Scaffolds a complete LWC (JS, HTML, CSS, meta XML) matching project conventions | Read, Write, Glob, Grep, Bash |
| `/audit-metadata` | Read-only audit of project metadata health (inventory, missing tests, API version drift) | Read, Glob, Grep, Bash |

**Example usage:**

```bash
# Generate an Apex service class with full test coverage
/generate-apex-class ContactService - handles CRUD operations for Contact

# Scaffold a new LWC that matches your project's existing conventions
/scaffold-lwc contactList - datatable showing contacts with search and inline edit

# Audit your project's metadata health (read-only, safe to run anytime)
/audit-metadata
```

Note how `/audit-metadata` intentionally omits the `Write` tool — principle of least privilege. An audit skill should never modify your project.

### Subagents & Agent Teams

Claude Code can spawn parallel workers (subagents) and coordinated teams (agent teams) to tackle larger tasks. The tutorial covers three patterns:

| Pattern | When to Use | Key Trait |
|---|---|---|
| **Subagents** | Parallel independent tasks | Workers don't talk to each other |
| **Agent Teams** | Coordinated multi-step analysis | Teammates see each other's findings |
| **Skills** | Reusable single-purpose automation | Markdown file = slash command |

**Subagents** are great for building multiple components at once — an Apex service, an LWC, and tests all generated in parallel:

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
    │  Apex   │  │   LWC   │  │  Tests  │
    └─────────┘  └─────────┘  └─────────┘
```

**Agent Teams** add coordination — one teammate's findings inform another's work. Perfect for security reviews where Apex audit results affect permission set analysis.

**Full tutorial:** [`tutorials/claude-code-subagents.md`](tutorials/claude-code-subagents.md)

---

## The Example App

The repo includes a working Salesforce DX app so you can try everything hands-on:

| Component | Path | What It Does |
|---|---|---|
| **AccountService** | `force-app/main/default/classes/AccountService.cls` | Apex service with CRUD methods for Account |
| **AccountServiceTest** | `force-app/main/default/classes/AccountServiceTest.cls` | Full test coverage with `@TestSetup` |
| **accountManager** | `force-app/main/default/lwc/accountManager/` | LWC with datatable, inline edit, create modal |
| **workflowVisualizer** | `force-app/main/default/lwc/workflowVisualizer/` | Interactive 7-step AI workflow visualization |
| **Create Account & Contact** | `force-app/main/default/flows/` | Screen Flow with transactional rollback |
| **Permission Sets** | `force-app/main/default/permissionsets/` | Scoped access for flow and LWC |

The `workflowVisualizer` component also serves as a **convention reference** — the `/scaffold-lwc` skill reads it first to match your project's SLDS patterns, accessibility approach, and CSS structure.

---

## Getting Started

### Prerequisites

- [Salesforce CLI](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_intro.htm)
- [VS Code](https://code.visualstudio.com/) with [Salesforce Extensions](https://developer.salesforce.com/tools/vscode/)
- [Agentforce Vibes](https://developer.salesforce.com/) VS Code extension
- [Claude Code](https://claude.ai/claude-code) CLI (for subagent patterns)
- Node.js (for Prettier, ESLint, and Jest)

### Setup

```bash
# Clone the repo
git clone <repo-url>
cd Session-012_AgentforceVibes_EngineeringYourCodingAgent_MohithShrivastava

# Install dependencies (Prettier, ESLint, Jest, Husky)
npm install

# Make the hook executable
chmod +x .a4drules/hooks/PostToolUse

# Create a scratch org (optional — for deploying the example app)
sf org create scratch -f config/project-scratch-def.json -a vibes-demo
sf project deploy start -o vibes-demo
```

### Try It Out

1. **Hooks** — Open Agentforce Vibes, enable the PostToolUse hook, then ask the agent to create an LWC. Watch it auto-format and self-correct lint errors.

2. **Skills (Agentforce Vibes)** — Ask the agent to build a Screen Flow. It will follow the structured process from the Flow Builder skill.

3. **Skills (Claude Code)** — Run `/generate-apex-class OpportunityService - handles pipeline operations` and get four files instantly.

4. **Subagents** — Paste the subagent prompt from [`tutorials/claude-code-subagents.md`](tutorials/claude-code-subagents.md) into Claude Code and watch three parallel workers build a feature simultaneously.

---

## Tutorials

| Tutorial | What You'll Learn |
|---|---|
| [Agentforce Vibes Hooks](tutorials/agentforce-vibes-hooks.md) | Build a PostToolUse hook that auto-formats code and feeds lint errors back to the agent |
| [Claude Code Subagents](tutorials/claude-code-subagents.md) | Three patterns for scaling Claude Code — subagents, agent teams, and skills |

---

## Watch the Session

[Engineering Your Coding Agent — Code With Sally](https://www.youtube.com/watch?v=Fj31gh4iNdk)

---

## Tech Stack

- **Salesforce DX** — API version 66.0
- **Apex** — Service classes with `with sharing`
- **Lightning Web Components** — SLDS, accessibility, responsive design
- **Screen Flows** — Transactional record creation with error handling
- **Prettier** — Auto-formatting with `prettier-plugin-apex` and `@prettier/plugin-xml`
- **ESLint** — Salesforce LWC and Aura linting rules
- **Jest** — LWC unit testing via `@salesforce/sfdx-lwc-jest`
- **Husky + lint-staged** — Pre-commit quality gates
