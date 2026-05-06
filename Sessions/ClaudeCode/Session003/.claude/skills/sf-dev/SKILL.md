---
name: sf-dev
description: >
  Salesforce DX development reference covering metadata quirks, Apex patterns,
  LWC conventions, and CLI commands. Use this skill whenever working on a
  Salesforce DX project — writing or deploying metadata (custom objects, fields,
  permission sets), writing Apex controllers for LWC, running tests, or
  troubleshooting deploy failures. Also use it when hitting metadata deploy errors,
  writing @AuraEnabled methods, setting up OWD/sharing, or checking custom
  permissions in Apex. If anything involves sfdx-project.json, force-app/, sf CLI,
  or Apex, load this skill first.
---

# Salesforce DX Development Reference

Lessons learned from real project work. Read the relevant reference file before
writing metadata or code — each one is short and prevents real deploy failures.

## Reference Files

| Topic | File | When to read |
|---|---|---|
| Deploy commands | `references/deploy.md` | Deploying source, running tests, assigning permission sets |
| Metadata gotchas | `references/metadata.md` | Writing custom fields, objects, or permission sets |
| Apex patterns | `references/apex.md` | Writing `@AuraEnabled` controllers, custom permission checks, sorting |
| LWC conventions | `references/lwc.md` | Writing LWC components, wiring Apex, configuring `js-meta.xml` |
| Apex testing | `references/testing.md` | Writing test classes, granting custom permissions in tests |

Load only the section(s) relevant to the current task. For a deploy failure, start
with `references/metadata.md`. For a new Apex method, start with `references/apex.md`.
