# `.claude/rules/` Demo — Dreamhouse LWC

This project demonstrates how Claude Code loads files from `.claude/rules/` based on YAML `paths` frontmatter and which files the user references in a prompt.

Companion to the [CLAUDE.md cascade demo](../claude-md-demo) — same pedagogical idea (tags embedded in responses as visibility markers), but for the `.claude/rules/` mechanism documented at https://code.claude.com/docs/en/memory.

## The Mechanic

- A rule file in `.claude/rules/` **without** `paths` frontmatter loads unconditionally at session start — treat it like an extra `CLAUDE.md`.
- A rule file **with** `paths: [...]` loads only when Claude reads a file matching at least one of those globs.
- Multiple matching rules stack — touching a file that matches several globs loads all of them.
- A single rule can span multiple concerns by listing multiple globs under `paths`. This is how cross-cutting rules (e.g. "tests") apply to both Apex test classes and LWC Jest specs.

## Structure

```
rules-dreamhouse/
├── RULES_DEMO.md                          (this file)
├── .claude/
│   └── rules/
│       ├── project-overview.md   → [PROJECT]   (no frontmatter, always loads)
│       ├── apex.md               → [APEX]      (force-app/**/classes/**)
│       ├── lwc.md                → [LWC]       (force-app/**/lwc/**)
│       ├── aura.md               → [AURA]      (force-app/**/aura/**)
│       ├── metadata.md           → [METADATA]  (force-app/**/*.xml)
│       └── tests.md              → [TESTS]     (cross-cutting: Apex + LWC tests)
└── ...standard dreamhouse-lwc project files...
```

## Running the Demo

Start a fresh session from this directory:

```
cd path/to/rules-dreamhouse && claude
```

Then run these prompts and watch which tags appear:

| # | Prompt | Expected tags | What it shows |
|---|--------|---------------|---------------|
| 1 | `Summarize @README.md` | `[PROJECT]` | No path-scoped rule matches; only the always-on rule fires |
| 2 | `Summarize @force-app/main/default/classes/PropertyController.cls` | `[PROJECT]` `[APEX]` | Path-scoped glob match |
| 3 | `Summarize @force-app/main/default/lwc/propertyTile/propertyTile.js` | `[PROJECT]` `[LWC]` | Sibling isolation: `[APEX]` does not load |
| 4 | `Summarize @force-app/main/default/aura/pageTemplate_2_7_3/pageTemplate_2_7_3.cmp` | `[PROJECT]` `[AURA]` | Third sibling; only `[AURA]` loads |
| 5 | `Summarize @force-app/main/default/classes/TestPropertyController.cls` | `[PROJECT]` `[APEX]` `[TESTS]` | Cross-cutting: Apex test matches both `apex` and `tests` globs |
| 6 | `Summarize @force-app/main/default/lwc/propertyTile/__tests__/propertyTile.test.js` | `[PROJECT]` `[LWC]` `[TESTS]` | Cross-cutting: LWC test matches both `lwc` and `tests` globs |
| 7 | `Summarize @force-app/main/default/classes/PropertyController.cls and @force-app/main/default/lwc/propertyTile/propertyTile.js` | `[PROJECT]` `[APEX]` `[LWC]` | Composition: multiple trees load multiple rules |
| 8 | `Summarize @force-app/main/default/objects/Property__c/Property__c.object-meta.xml` | `[PROJECT]` `[METADATA]` | Metadata glob scope |
| 9 | `What is 2 + 2?` (fresh session) | `[PROJECT]` only | No file reference → only the always-on rule |

> Within a single session, once a rule has been loaded it stays in context. To see each prompt cleanly, restart Claude Code between prompts.

## How this differs from the CLAUDE.md cascade demo

| | CLAUDE.md | `.claude/rules/` |
|---|-----------|------------------|
| **Scoping** | By directory (a nested `CLAUDE.md` loads when any file in its tree is touched) | By glob pattern (a rule loads when the touched file matches its `paths`) |
| **Cross-cutting scope** | Hard — requires duplicating a `CLAUDE.md` across directories | Natural — one rule can list several globs |
| **Always-on rule** | Root `CLAUDE.md` | Any `.claude/rules/*.md` without `paths` frontmatter |
| **Organization** | Hierarchical, lives alongside code | Flat collection under one directory |

Rules are well-suited to cross-cutting concerns (tests, migrations, documentation style). CLAUDE.md is better for locally-scoped "this area of the codebase works this way" guidance.

## Variations to try

- **Touch a `.cls-meta.xml`**: `Summarize @force-app/main/default/classes/PropertyController.cls-meta.xml` — both `[APEX]` (via `force-app/**/classes/**`) and `[METADATA]` (via `force-app/**/*.xml`) should fire. One file, two matching globs.
- **Narrow a glob**: change `apex.md`'s `paths` to `force-app/**/classes/*.cls` (drop the trailing `**`) and re-run prompt 2. Still matches for a top-level `.cls` file.
- **Drop frontmatter**: remove the `paths:` block from `apex.md` and restart — now `[APEX]` fires on every prompt, same as `[PROJECT]`.
- **Conflict experiment**: add a second rule that says "do NOT include `[PROJECT]`" and observe what happens. The docs note Claude "may pick one arbitrarily" when rules contradict — model capability and concatenation order determine the outcome.
