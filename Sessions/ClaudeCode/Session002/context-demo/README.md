# `/context` Token Usage Demo

This project demonstrates how Claude Code's `/context` command reveals the **true** token cost of a prompt — and why the same trivial question like `what is 2 + 2?` can cost wildly different amounts depending on when in a session you ask it.

## The Mechanic

Every turn, Claude is billed for **everything currently in its context window**, not just the text you just typed. That includes:

- The system prompt
- Tool schemas (built-in and MCP)
- Loaded `CLAUDE.md` files and `MEMORY.md` entries
- Every prior user message and assistant response in this session
- Every file Claude has read and every tool result it has seen

`/context` shows this breakdown: how many tokens are in each category and how much free space remains before auto-compaction kicks in. A "cheap" prompt like `what is 2 + 2?` is only cheap in isolation. Ask it as turn 20 after reading a 5000-line file, and you pay for all 5000 lines again on that turn.

## Structure

```
context-demo/
├── CLAUDE.md          → reminds Claude to echo TAG: lines and not auto-read
├── README.md          (this file)
├── small-file.md      → ~10 lines,    TAG:small
├── medium-file.md     → ~160 lines,   TAG:medium
├── large-file.md      → ~1600 lines,  TAG:large
└── huge-file.md       → ~8000 lines,  TAG:huge
```

## Running the Demo

Start a fresh Claude Code session from this directory and run `/context` between prompts. Record the **total input tokens** and the breakdown each time.

```
cd path/to/context-demo && claude
```

| # | Action | What to record from `/context` | What it shows |
|---|--------|-------------------------------|---------------|
| 1 | Fresh session. Run `/context` immediately. | Baseline: system + tools + memory + CLAUDE.md | The floor cost before you've said anything |
| 2 | `what is 2 + 2?` → `/context` | Small delta over baseline | A trivial prompt against a near-empty window |
| 3 | Fresh session. `Read @small-file.md` → `what is 2 + 2?` → `/context` | Slight growth | Small file barely moves the needle |
| 4 | Fresh session. `Read @medium-file.md` → `what is 2 + 2?` → `/context` | Noticeable growth | Medium file is now a visible line item |
| 5 | Fresh session. `Read @large-file.md` → `what is 2 + 2?` → `/context` | Large jump | Same trivial question — now expensive |
| 6 | Same session as 5. Ask `what is 2 + 2?` three more times, `/context` after each | Each turn pays for the large file again | Per-turn billing compounds across a session |
| 7 | Fresh session. `Read @huge-file.md` → `/context` | Approaches the free-space warning | Context pressure / auto-compact territory |
| 8 | In session 7, run `/compact` → `/context` | Messages section shrinks dramatically | Compaction as a mitigation |

Between each numbered step (except 6 and 8), start a fresh session so you can isolate the effect.

## Key Findings

- **A prompt's cost is the whole window, not the typed text.** `what is 2 + 2?` is ~5 tokens on its own and thousands of tokens as turn 20.
- **`/context` is the only reliable view of where your tokens are going.** It breaks the window down by system, tools, MCP, memory, CLAUDE.md files, and messages.
- **MCP servers and tool schemas have a floor cost** you pay on *every* turn even if you never call the tool. More servers = higher baseline.
- **Loaded CLAUDE.md files and memory entries** live in the window for the rest of the session. Large ones are not free.
- **Caching softens repeat costs but doesn't eliminate them.** Cache reads are cheaper than cache writes, which are cheaper than fresh input — but all three still count.
- **Fresh sessions and `/compact` are the main levers** for reclaiming space. Knowing when to use each is a practical skill.

## Variations to Try

- **MCP toggle:** Disable an MCP server, restart, and compare the Tools section in `/context`.
- **Memory growth:** Add a long entry to `~/.claude/CLAUDE.md` or your `MEMORY.md` and watch the Memory section grow on every session.
- **Model swap:** Re-run the sequence with `--model claude-haiku-4-5` vs. Opus and multiply tokens × per-model price to see real cost differences.
- **Cache behavior:** Run prompt 5 twice in the same session and watch `/cost` to see the cache-read savings on the second call.
- **Multi-file reference:** In one prompt, reference both `@medium-file.md` and `@large-file.md` and see how the Messages section stacks.
- **Auto-compact:** Keep reading files in session 7 until auto-compact triggers, then check `/context` to see what was kept.

## Why This Matters

The `/context` command turns token usage from an abstract worry into a concrete, observable number. Once you've run this demo, you'll reflexively think about the cost floor at the start of a session, and you'll know exactly when to reach for `/compact` or start fresh.
