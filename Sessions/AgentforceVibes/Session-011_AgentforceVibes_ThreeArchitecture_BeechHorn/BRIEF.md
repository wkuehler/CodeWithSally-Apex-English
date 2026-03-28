# Research & Bootstrap: Trailhead Gamified Learning Platform

## Objective

Perform deep research and produce two foundational reference
files (**AGENTS.md** and **SPEC.md**) that any future AI agent
can consume to contribute to this project with zero ramp-up.

Optimise ruthlessly for low token count and high information
density.

---

## 1 — Primary Source

Read and internalise the Trailhead project module:
https://trailhead.salesforce.com/content/learn/projects/build-an-app-to-track-your-trailblazer-journey

This is our **starting point**, not our ceiling. We will extend
well beyond its scope.

---

## 2 — Research Directives

Supplement the module with well-sourced research across three
dimensions:

| Dimension              | Focus                          |
| ---------------------- | ------------------------------ |
| **Learner Motivation** | What drives participants to    |
|                        | start, persist, and succeed?   |
|                        | Consider self-determination    |
|                        | theory, streak mechanics, and  |
|                        | social accountability.         |
| **Community Patterns** | Events like *100 Days of       |
|                        | Trailhead* — daily badges,     |
|                        | accountability partners,       |
|                        | contests, and organic          |
|                        | friendships. How do these      |
|                        | sustain engagement?            |
| **Platform Mechanics** | Salesforce Quests — prizes,    |
|                        | skill-based challenges, and    |
|                        | progression systems. What      |
|                        | makes them effective?          |

Quests reference: https://trailhead.salesforce.com/quests

### Key Insight

Ultimately, learners want to **skill up, get certified, and
feel confident** on the platform. Every feature we design must
serve that outcome.

### Technical Reference

Nathan Abondance reverse-engineered public Trailhead GraphQL
queries for progress data:
https://github.com/nabondance/Trailhead-Banner/tree/main/src/graphql/queries

Evaluate these for integration potential.

---

## 3 — Agent Skills

The build will be executed by **seven specialised AI agents**.
The SPEC.md must tag every user story with the agent(s)
required to deliver it. The AGENTS.md must list these skills
so any orchestrator can route work correctly.

### Schema & Data Model

| Skill              | Responsibility                  |
| ------------------ | ------------------------------- |
| `admin-schema`     | Custom objects, fields,         |
|                    | relationships (Lookup,          |
|                    | Master-Detail), picklists,      |
|                    | validation rules, record types, |
|                    | page layouts, compact layouts,  |
|                    | field sets, list views, tabs,   |
|                    | and all object-level metadata   |
|                    | in SFDX source format.          |
| `admin-config`     | Custom Metadata Types and       |
|                    | records for rule engines, level |
|                    | definitions, XP thresholds,     |
|                    | achievement criteria, milestone |
|                    | definitions, API endpoint       |
|                    | settings — anything admins can  |
|                    | modify without code changes.    |

### Application & Security

| Skill                 | Responsibility                |
| --------------------- | ----------------------------- |
| `admin-appbuilder`    | Lightning Apps, FlexiPages    |
|                       | (home, record, utility bar),  |
|                       | app navigation, and form      |
|                       | factor settings.              |
| `admin-security`      | Permission sets, permission   |
|                       | set groups, field-level       |
|                       | security, object permissions, |
|                       | OWD sharing model, and        |
|                       | role-based access control.    |

### Apex Development

| Skill                  | Responsibility               |
| ---------------------- | ---------------------------- |
| `apex-class-generator` | Production Apex: service     |
|                        | classes, selectors, domain / |
|                        | trigger handlers, utilities, |
|                        | batch / queueable /          |
|                        | schedulable jobs, REST/SOAP  |
|                        | web services, and invocable  |
|                        | methods.                     |
| `apex-test`            | Test classes: unit tests,    |
|                        | integration tests, test data |
|                        | factories, System.runAs      |
|                        | security tests, validation   |
|                        | rule tests, schema tests,    |
|                        | and coverage enforcement.    |

### DevOps

| Skill        | Responsibility                       |
| ------------ | ------------------------------------ |
| `sf-devops`  | SFDX project lifecycle: scratch org  |
|              | creation, source deploy, test        |
|              | execution, org queries, and          |
|              | deployment validation via SF CLI.    |

---

## 4 — Deliverables

### A) `AGENTS.md`

Follow the specification at https://agents.md/

This file is the **single-page briefing** every future prompt
will receive regardless of task. It must contain:

- Project purpose and boundaries (distilled to essence)
- Architecture and conventions
- The seven agent skills listed above with routing guidance
- Any fact that changes how an agent behaves; **cut
  everything else**

### B) `SPEC.md`

A comprehensive product & engineering specification:

- **Personas** — distinct user archetypes with goals and
  pain points
- **Epics & User Stories** — organised by theme, each
  story including:
  - Acceptance criteria
  - Technical considerations (Apex patterns, metadata
    structure, GraphQL integration points)
  - Non-functional requirements (performance,
    accessibility, security)
  - **Agent skill tag(s)** — which of the seven skills
    are needed to implement the story
- **Project Plan** — a phased breakdown of work packages
  sequenced for agent execution. Assume **time and budget
  are irrelevant**; optimise for quality and completeness.
  Each phase must identify:
  - Dependent phases / stories
  - Skill(s) involved
  - Verification criteria (`sf-devops` validation steps)

---

## Constraints

- Cite sources (URLs, paper titles, framework names).
- Prefer bullet points and tables over prose.
- Tag every user story with one or more agent skills from
  the seven defined in §3.
- Every section must pass the test: *"Would a new agent
  landing on this project for the first time have
  everything it needs?"*
  