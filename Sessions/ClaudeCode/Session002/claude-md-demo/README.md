# CLAUDE.md Cascade Demo

This project demonstrates how Claude Code loads `CLAUDE.md` files from nested directories into its context based on which files are referenced in a prompt.

## The Mechanic

- The **root `CLAUDE.md`** always loads at the start of a Claude Code session started in this directory.
- A **subdirectory `CLAUDE.md`** loads only when Claude touches a file in that directory (or a deeper one). Just having the directory exist isn't enough; a file inside it has to enter context.
- **Loaded rules stack** — they all load into context and Claude attempts to follow all of them.
- **When rules conflict**, the docs note Claude "may pick one arbitrarily." In practice, the deepest rule often wins on capable models, but there is no formal enforcement — outcomes depend on model capability and concatenation order.

Each `CLAUDE.md` in this demo tells Claude to include a distinctive tag (`[ROOT]`, `[TOP]`, `[MIDDLE]`, `[BOTTOM]`) in its response. The key insight: use **non-conflicting language** like "include" rather than "begin with" so all applicable rules can coexist. When you use conflicting language (e.g., "start with"), only the deepest rule wins.

## Structure

```
claude-md-demo/
├── CLAUDE.md              → [ROOT]
├── README.md              (this file)
├── root-file.md
└── top/
    ├── CLAUDE.md          → [TOP]
    ├── top-file.md
    ├── branch-a/
    │   ├── CLAUDE.md      → [BRANCH-A]
    │   └── branch-a-file.md
    ├── branch-b/
    │   ├── CLAUDE.md      → [BRANCH-B]
    │   └── branch-b-file.md
    ├── override/
    │   ├── CLAUDE.md      → [OVERRIDE] (conflicts with [ROOT])
    │   └── override-file.md
    └── middle/
        ├── CLAUDE.md      → [MIDDLE]
        ├── middle-file.md
        └── bottom/
            ├── CLAUDE.md  → [BOTTOM]
            └── bottom-file.md
```

## Running the Demo

Start a fresh Claude Code session from this directory:

```
cd path/to/claude-md-demo && claude
```

Then run these prompts in order and watch how the tag stack grows:

| # | Prompt | Expected output | What it shows |
|---|--------|-----------------|---------------|
| 1 | `Summarize @root-file.md` | `[ROOT]` `SOURCE:root` | Root loads at session start |
| 2 | `Summarize @top/top-file.md` | `[ROOT]` `[TOP]` `SOURCE:root` `SOURCE:top` | Depth cascade: rules stack |
| 3 | `Summarize @top/middle/middle-file.md` | `[ROOT]` `[TOP]` `[MIDDLE]` + sources | Each level adds to the stack |
| 4 | `Summarize @top/middle/bottom/bottom-file.md` | `[ROOT]` `[TOP]` `[MIDDLE]` `[BOTTOM]` + sources | Full depth cascade |
| 5 | `What is 2 + 2?` (no file, fresh session) | `[ROOT]` `SOURCE:root` only | Subdir rules require a file reference |
| 6 | `Summarize @top/branch-a/branch-a-file.md` | `[ROOT]` `[TOP]` `[BRANCH-A]` + sources | Sibling isolation: branch-b not loaded |
| 7 | `Summarize @top/branch-b/branch-b-file.md` | `[ROOT]` `[TOP]` `[BRANCH-B]` + sources | Sibling isolation: branch-a not loaded |
| 8 | `Summarize @top/branch-a/branch-a-file.md and @top/branch-b/branch-b-file.md` | `[ROOT]` `[TOP]` `[BRANCH-A]` `[BRANCH-B]` + sources | Both siblings load when both referenced |
| 9 ⚠️ | `Summarize @top/override/override-file.md` | `[TOP]` `[OVERRIDE]` `SOURCE:root` `SOURCE:top` — no `[ROOT]` | Partial override: explicit conflict suppressed, independent rule survives |

### What step 5 shows

Even after step 4 has loaded every `CLAUDE.md`, asking a question that doesn't reference a subdirectory file in a new session produces only `[ROOT]`. The subdirectory rules only activate when the relevant directory is in play.

> Note: within a single session, once a deeper `CLAUDE.md` has been loaded it stays in context. To see step 5 cleanly, run it in a fresh session, or exit and restart Claude Code.

> ⚠️ **Prompt 9 note:** Partial override behavior (SOURCE:root surviving while [ROOT] is suppressed) requires a capable model. Tested working on `claude-sonnet-4-6`. On `claude-haiku-4-5`, the entire root context may be suppressed. See [Key Findings](#key-findings) below.

## Key Findings

These insights emerged from building and testing this demo — they aren't all obvious from the documentation.

- **CLAUDE.md is context, not configuration.** Claude reads it and attempts to comply, but the runtime does not enforce rules. Compliance is best-effort, especially for conflicting instructions.
- **Conflict resolution has no formal spec.** Concatenation order and model capability both influence the outcome. More capable models (Sonnet, Opus) handle nuanced conflicts more reliably than smaller ones (Haiku).
- **Rule language determines whether rules compose.** Positional language ("begin with") creates conflicts that only one rule can win. Permissive language ("include") allows all applicable rules to coexist.
- **Silence ≠ suppression.** An override CLAUDE.md that doesn't mention a parent rule leaves that rule intact. Only explicitly contradicted rules are suppressed.
- **Granularity matters.** Rules written as separate IMPORTANT statements can be independently overridden. Rules bundled into one sentence tend to be treated as a unit.
- **Loading is path-triggered, not depth-triggered.** A sibling directory's CLAUDE.md does not load just because another sibling at the same depth was loaded.

## Sibling Isolation

Prompts 6–8 demonstrate that **sibling directories load independently**. Loading `branch-a/` does not automatically load `branch-b/`. Path matters, not just depth.

This is a common misconception: people assume "directories at depth N load at depth N," but the real rule is "loading happens when a file in that specific directory enters context."

## Rule Conflicts and Resolution

Prompts 6–8 demonstrate **non-conflicting rules stacking**. When rules use compatible language (e.g., "include [TAG]"), all applicable rules execute and you see all tags.

Prompt 9 tests what happens when rules **partially conflict**. The `override/CLAUDE.md` explicitly says:
- "Include `[OVERRIDE]`"
- "Do NOT include `[ROOT]`"
- Says **nothing** about `SOURCE:root`

This is the key insight: each CLAUDE.md specifies two things:
1. A **tag rule** ([ROOT], [TOP], etc.) — conflicting with override
2. A **source rule** (SOURCE:root, SOURCE:top, etc.) — NOT mentioned by override

**Result:** Conflict resolution operates at the **individual rule level** when rules are written as clearly separate IMPORTANT statements. You'll see:
- `[ROOT]` → absent (explicitly conflicted)
- `SOURCE:root` → present (independent rule, never mentioned by override)
- `[OVERRIDE]` → present (deepest rule applies)
- `[TOP]` → present (top/ CLAUDE.md not mentioned by override)
- `SOURCE:top` → present (top/ CLAUDE.md not mentioned by override)

This demonstrates **silence ≠ suppression**. Only the specific rule that was explicitly contradicted gets suppressed. Independent rules — even from the same CLAUDE.md file — survive if they aren't mentioned in the conflict.

**Design lesson:** Keep rules as separate IMPORTANT statements so they can be independently overridden. Rules bundled together in one sentence may be treated as a unit and suppressed together.

## The Language Matters: A Critical Discovery

During testing, we discovered that **the wording of rules determines whether they can coexist**.

### Conflicting Language
```md
IMPORTANT: **Begin** every response with the tag `[ROOT]` on its own line.
```

When multiple rules use "begin," "start with," or other positional constraints, only one can satisfy the constraint. Only the deepest rule's constraint is honored. Siblings conflict: you can't "begin with `[ROOT]`" and also "begin with `[BRANCH-A]`" simultaneously.

### Non-Conflicting Language
```md
IMPORTANT: **Include** the tag `[ROOT]` somewhere in your response on its own line.
Also include `SOURCE:root` on its own line somewhere in your response.
```

When rules use "include" or other non-positional language, they don't conflict. All applicable rules can coexist: you can include `[ROOT]`, `[TOP]`, and `[BRANCH-A]` all in the same response. Multiple non-conflicting rules from the same CLAUDE.md all apply.

### Partial Overrides: Silence ≠ Suppression

In prompt 9, the override CLAUDE.md suppresses `[ROOT]` but says nothing about `SOURCE:root`. Because these are written as separate IMPORTANT statements in root CLAUDE.md, Claude treats them as independent rules. The result: `[ROOT]` is absent (explicit conflict), but `SOURCE:root` is present (never mentioned by override).

**Takeaway:** When designing CLAUDE.md files for a multi-level hierarchy, use permissive language that allows rules to compose. If you must override a parent rule, do it explicitly. Silence doesn't suppress — only conflicts do.

## Variations to Try

- **Test language impact:** Change one rule from "include" back to "begin with" and rerun its prompt. Watch it suppress sibling tags.
- **Multi-file references:** Run `Summarize @root-file.md and @top/middle/middle-file.md` in one prompt and watch all tags from root to middle appear.
- **Edit vs. read:** Edit a file in `top/` (instead of just reading one) to confirm edits trigger the same loading behavior.
- **Delete and observe:** Temporarily delete one `CLAUDE.md` file and rerun its matching prompt to see the tag disappear.
- **Conflict resolution:** Run prompt 9 and note that `[ROOT]` is suppressed even though root CLAUDE.md is still loaded. The override rule (deepest, most specific) takes precedence.
- **Fresh sessions:** Between prompts, start fresh sessions to reset the tag stack. Within a single session, loaded rules persist.
