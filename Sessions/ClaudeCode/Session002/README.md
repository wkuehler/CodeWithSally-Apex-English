# Claude Code Context & Token Management Demos

This project demonstrates how Claude Code loads information into its context window, and the token-cost tradeoffs between the three main mechanisms for providing persistent guidance: **CLAUDE.md files**, **rules**, and **skills**. Each mechanism loads context at a different time and scope — choosing the right one keeps Claude informed without wasting tokens on guidance it doesn't need.

## The Three Mechanisms

### CLAUDE.md — hierarchical, path-scoped
- **When it loads:** When Claude references a file, every `CLAUDE.md` from that file's directory up to the project root is pulled into context.
- **Token cost:** Paid on every session that touches anything under that tree. A root-level CLAUDE.md is always loaded.
- **Prefer when:** Guidance applies to an entire directory subtree and is needed in most sessions.

### Rules — glob-scoped
- **When it loads:** When Claude touches a file matching the rule's glob pattern (defined in YAML frontmatter). Not tied to directory ancestry.
- **Token cost:** Paid only when a matching file is in play. One rule can cover many file types across the tree without duplication.
- **Prefer when:** Guidance is cross-cutting (e.g., "all test files", "all Apex classes") rather than hierarchical.

### Skills — intent-scoped
- **When it loads:** Only when the user's request semantically matches the skill's description. Most aggressive lazy loading of the three.
- **Token cost:** Near-zero baseline; skill body only enters context when invoked.
- **Prefer when:** Guidance is task-specific and irrelevant outside that task (e.g., formatting a recipe, running a specific workflow).

## Slides

`Session-2.pdf` — the full presentation deck for this session. Start here for the concepts before exploring the demo directories.

## Directory Map

| Directory | What it shows |
|---|---|
| `claude-md-demo/` | Teaches CLAUDE.md cascading through nested directories with tag-based validation |
| `claude-md-dreamhouse/` | Salesforce Dreamhouse LWC app configured with a CLAUDE.md pattern |
| `rules-demo/` | Teaches glob-scoped rule loading with a Jest harness |
| `rules-dreamhouse/` | Same Dreamhouse app, configured with `.claude/rules/` instead of CLAUDE.md |
| `skills-demo/` | Teaches intent-triggered skill loading via a recipe-formatter skill |
| `context-demo/` | Teaches the `/context` command by showing how the same trivial prompt costs different amounts of tokens depending on what's already loaded |
| `statusline-prompt-md` | Prompt you can paste into Claude Code to build a custom 4-row status line showing context window, rate limits, token usage, and session location |

## Demo vs. Dreamhouse

The subdirectories come in two flavors:

- **`-demo` projects** are minimal teaching harnesses. They use tag markers and Jest tests to make context-loading mechanics visible — you can prove which files were and weren't loaded into Claude's window.
- **`-dreamhouse` projects** apply the same mechanisms to the real Salesforce Dreamhouse LWC sample app. They show what the patterns look like on production-shaped code, and let you compare CLAUDE.md vs. rules on the same codebase.

Together, the pairs let you first understand the mechanics in isolation, then see them applied.

## Key Takeaway

Pick the narrowest loading mechanism that fits your need. **Skills** load only when the task calls for them; **rules** load only when matching files are touched; **CLAUDE.md** loads for the whole subtree it lives in. Starting with the most aggressive lazy-loading option (skills → rules → CLAUDE.md) keeps Claude's context focused and your token usage efficient.
