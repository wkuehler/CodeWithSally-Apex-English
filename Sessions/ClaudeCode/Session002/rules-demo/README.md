# `.claude/rules/` Demo

This project demonstrates how Claude Code loads rule files from `.claude/rules/` based on YAML `paths` frontmatter and which files are referenced in a prompt.

Companion to the [CLAUDE.md cascade demo](../claude-md-demo) — same pedagogical shape (tags embedded in responses as visibility markers, a Jest harness that validates expected behavior), but for the `.claude/rules/` mechanism.

## The Mechanic

- A rule file in `.claude/rules/` **without** `paths` frontmatter loads unconditionally at session start. Treat it like an extra `CLAUDE.md`.
- A rule file **with** `paths: [...]` loads only when Claude reads a file matching at least one of those globs.
- Multiple matching rules stack — touching a file that matches several globs loads all of them.
- A single rule can span multiple concerns by listing multiple globs under `paths`. This is how cross-cutting rules (e.g. "tests") can apply to both JS and TS tests.
- **When rules conflict**, the docs note Claude "may pick one arbitrarily." In practice, the most specific rule often wins on capable models, but outcomes depend on model capability and concatenation order.

Each rule in this demo instructs Claude to include a distinctive tag (`[ALL]`, `[JS]`, `[TS]`, `[TESTS]`, `[SRC]`, `[OVERRIDE]`) in its response. Use **non-conflicting language** like "include" rather than "begin with" so all applicable rules can coexist.

## Structure

```
rules-demo/
├── README.md                     (this file)
├── package.json
├── tsconfig.json
├── .claude/
│   └── rules/
│       ├── all.md           → [ALL]        (no frontmatter, always loads)
│       ├── js.md            → [JS]         (paths: **/*.js)
│       ├── ts.md            → [TS]         (paths: **/*.ts)
│       ├── tests.md         → [TESTS]      (paths: **/*.test.js, **/*.test.ts)
│       ├── src.md           → [SRC]        (paths: src/**)
│       └── override.md      → [OVERRIDE]   (paths: override/**; conflicts with [ALL])
├── plain.md                      (no matching path-scoped rule)
├── example.js                    (matches js.md)
├── example.ts                    (matches ts.md)
├── example.test.js               (matches js.md AND tests.md)
├── src/
│   └── src-file.js               (matches js.md AND src.md)
├── override/
│   └── override-file.js          (matches js.md AND override.md)
└── harness/
    └── rules.test.ts             (Jest validation suite)
```

## Running the Demo

Start a fresh Claude Code session from this directory:

```
cd path/to/rules-demo && claude
```

Then run these prompts in order and watch how the tag set changes:

| # | Prompt | Expected output | What it shows |
|---|--------|-----------------|---------------|
| 1 | `Summarize @plain.md` | `[ALL]` `SOURCE:all` | No path-scoped match; only always-on rule |
| 2 | `What is 2 + 2?` (fresh session) | `[ALL]` `SOURCE:all` | No file reference; path-scoped rules require a match |
| 3 | `Summarize @example.js` | `[ALL]` `[JS]` `SOURCE:all` | Path-scoped glob match |
| 4 | `Summarize @example.ts` | `[ALL]` `[TS]` `SOURCE:all` | Sibling isolation: `[JS]` does not fire |
| 5 | `Summarize @example.test.js` | `[ALL]` `[JS]` `[TESTS]` `SOURCE:all` | Cross-cutting: matches both `js.md` and `tests.md` |
| 6 | `Summarize @example.js and @example.ts` | `[ALL]` `[JS]` `[TS]` `SOURCE:all` | Composition: two separate globs both match |
| 7 | `Summarize @src/src-file.js` | `[ALL]` `[JS]` `[SRC]` `SOURCE:all` | Narrower and broader globs both match |
| 8 ⚠️ | `Summarize @override/override-file.js` | `[JS]` `[OVERRIDE]` `SOURCE:all` — no `[ALL]` | Partial override: explicit conflict suppressed, independent rule survives |

> Within a single session, once a rule has been loaded it stays in context. To see each prompt cleanly, restart Claude Code between prompts.

> ⚠️ **Prompt 8 note:** Partial override behavior (`SOURCE:all` surviving while `[ALL]` is suppressed) requires a capable model. Tested working on `claude-sonnet-4-6`. Smaller models may suppress the whole `all.md` rule together.

## Key Findings

These insights come from building and testing this demo — and parallel what we saw in the [CLAUDE.md cascade demo](../claude-md-demo):

- **Rules are context, not configuration.** Claude reads them and attempts to comply; the runtime does not enforce rules.
- **Conflict resolution has no formal spec.** Docs say Claude "may pick one arbitrarily" when rules contradict. More capable models handle nuanced conflicts more reliably.
- **Rule language determines whether rules compose.** Positional language ("begin with") creates conflicts only one rule can win. Permissive language ("include") allows all applicable rules to coexist.
- **Silence ≠ suppression.** A rule that doesn't mention a parent rule leaves that rule intact. Only explicitly contradicted rules are suppressed. (See prompt 8: `override.md` suppresses `[ALL]` but says nothing about `SOURCE:all`, so `SOURCE:all` survives.)
- **Granularity matters.** Rules written as separate `IMPORTANT` statements can be independently overridden. Rules bundled into one sentence tend to be treated as a unit.
- **Rules are glob-scoped, not directory-scoped.** Unlike `CLAUDE.md` (which loads by directory ancestry), a rule fires when any touched file matches any of its `paths` globs — regardless of where the rule file lives.

## How this compares to the CLAUDE.md cascade demo

| | `CLAUDE.md` | `.claude/rules/` |
|---|-------------|------------------|
| **Scoping** | By directory (a nested `CLAUDE.md` loads when any file in its tree is touched) | By glob pattern (a rule loads when the touched file matches its `paths`) |
| **Cross-cutting scope** | Hard — requires duplicating `CLAUDE.md` across directories | Natural — one rule can list several globs |
| **Always-on rule** | Root `CLAUDE.md` | Any `.claude/rules/*.md` without `paths` frontmatter |
| **Organization** | Hierarchical, lives alongside code | Flat collection under `.claude/rules/` |

Rules are well-suited to cross-cutting concerns (tests, migrations, documentation style). `CLAUDE.md` is better for locally-scoped "this area of the codebase works this way" guidance.

## Variations to Try

- **Drop frontmatter**: remove the `paths:` block from `js.md` and restart. `[JS]` now fires on every prompt, same as `[ALL]`.
- **Narrow a glob**: change `js.md`'s `paths` to `src/**/*.js` and re-run prompt 3 (`@example.js` at root). `[JS]` stops firing — the root-level `.js` file no longer matches.
- **Brace expansion**: collapse `tests.md`'s two globs into a single `**/*.test.{js,ts}` and confirm behavior is identical.
- **Multi-file references**: `Summarize @example.js and @src/src-file.js` loads `[ALL]` `[JS]` `[SRC]` — the second file pulls in `src.md` even though the first doesn't match it.
- **Conflict experiment**: add a second rule with the same glob as an existing one but contradictory content. Observe whether the newer or older rule wins (the docs warn this is non-deterministic).

## Running the test harness

`harness/rules.test.ts` validates all 8 scenarios by spawning real `claude -p` invocations and asserting on output. Run with:

```
npm install
npm test
```

Each test spawns a fresh Claude session, so the full suite takes several minutes. The harness uses `claude-sonnet-4-6`.
