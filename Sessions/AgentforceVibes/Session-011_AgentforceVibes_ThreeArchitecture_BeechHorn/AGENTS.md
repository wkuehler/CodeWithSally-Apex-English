# AGENTS.md — Trailhead Gamified Learning Platform

## Purpose

A Salesforce-native app that helps learners **track progress, maintain motivation, and build community** on their Trailhead journey. It extends the basic "My Trailblazer Journey" project into a gamified platform with XP, streaks, achievements, leaderboards, and Trailhead API integration.

**North star:** Learners skill up, get certified, and feel confident on the Salesforce platform.

---

## Read‑this‑first (global rules)

- **UI constraints:** No LWC/Aura in Phase 1–2. Use declarative UI (Lightning App, FlexiPages, Related Lists, Report Charts).
- **Configuration:** Put all configurable values in **Custom Metadata Types** (XP thresholds, levels, achievements, streak rules, API settings). Never hardcode thresholds.
- **Trailhead API:** Public, read-only GraphQL over HTTP POST. No write-back.
- **Pagination:** Always handle `hasNextPage` / `endCursor` when consuming Trailhead data.
- **Bulk data:** Design for hundreds of badges per Trailblazer in a single sync. No SOQL/DML in loops.
- **Tests:** Use `TestDataFactory`, no `@seeAllData`. Maintain high coverage and full test isolation.
- **Dependencies:** No managed package dependencies; everything is custom.

---

## Architecture (high level)

| Layer | Technology |
|---|---|
| Data model | Custom objects + Custom Metadata Types (SFDX source format) |
| Business logic | Apex (service layer, trigger framework, batch/queueable) |
| External data | Trailhead public GraphQL API (via Apex HTTP callout) |
| UI | Lightning App + FlexiPages |
| Security | Permission Sets, FLS, OWD sharing model |
| DevOps | SF CLI, scratch orgs, source-driven development |

---

## Trailhead GraphQL integration (summary)

- **Endpoint:** `https://profile.api.trailhead.com/graphql` (public, no auth required for public profiles).
- **Key parameters:** `trailblazerId` (Salesforce user ID), `count`, `after` (cursor), `filter` (SUPERBADGE, MODULE, PROJECT, EVENT).
- **Design:** Centralise callouts in a service/utility layer, respect limits, and always support pagination.
- **Reference implementations:** See Trailhead query examples in [Trailhead-Banner](https://github.com/nabondance/Trailhead-Banner/tree/main/src/graphql/queries) and the `Trailblazer__c` pattern in [go-trailhead-leaderboard-api](https://github.com/meruff/go-trailhead-leaderboard-api).

---

## Conventions

- **SFDX format:** All metadata lives in `force-app/main/default/`.
- **Naming:** Objects `PascalCase__c`, fields `PascalCase__c`, Apex classes `PascalCase`, test classes `*_Test`.
- **Triggers:** One trigger per object → handler class → service class.
- **Apex patterns:** Selector classes for SOQL, Domain classes for business logic, Service classes as API layer.
- **SOQL/DML:** Bulkified, no queries/DML inside loops.

---

## Agent skills & routing

Seven specialised agents share work; an orchestrator uses the `skill` tag on each user story.

| Skill | Scope | Key artefacts |
|---|---|---|
| `admin-schema` | Objects, fields, relationships, record types, layouts, list views, tabs | `objects/`, `tabs/`, `listviews/` |
| `admin-config` | Custom Metadata Types + records (XP tables, levels, achievements, streak rules, API settings) | `customMetadata/`, `objects/` (CMT defs) |
| `admin-appbuilder` | Lightning Apps, FlexiPages, navigation, form factors | `flexipages/`, `applications/`, `appMenus/` |
| `admin-security` | Permission sets/groups, FLS, OWD, sharing, roles | `permissionsets/`, `permissionsetgroups/`, `settings/` |
| `apex-class-generator` | Apex services, selectors, domains, utilities, batch/queueable/schedulable, REST, invocables | `classes/*.cls` (non-test) |
| `apex-test` | Unit/integration tests, factories, security and validation tests | `classes/*_Test.cls`, `classes/TestDataFactory.cls` |
| `sf-devops` | Scratch orgs, deploy/validate, tests, CI integration | `config/`, `scripts/`, `sfdx-project.json` |

**Routing order (happy path):**

1. `admin-schema` → define objects.
2. `admin-config` → configure CMTs.
3. `admin-security` → wire up permissions.
4. `apex-class-generator` → implement logic.
5. `apex-test` → cover logic and rules.
6. `admin-appbuilder` → assemble UI.
7. `sf-devops` → validate and deploy at each phase.

---

## Key domain concepts

| Concept | Definition |
|---|---|
| **Trailblazer** | Learner with a Trailhead profile |
| **Discovery** | Learning resource the user has found (base Trailhead module concept) |
| **Badge** | Trailhead credential (Module, Project, Superbadge, Event) |
| **Certification** | Official Salesforce certification |
| **Rank** | Trailblazer rank progression: Scout → Hiker → Explorer → … → Ranger (100 badges/50K pts) → up to All Star Ranger |
| **XP** | Internal experience points mapped from Trailhead points + app actions |
| **Streak** | Consecutive days with qualifying learning activity |
| **Achievement** | Unlockable award for milestones (badges, streaks, certs) |
| **Quest** | Time-bound challenge with defined completion criteria |
| **Study Group** | Cohort of learners pursuing a shared goal |

