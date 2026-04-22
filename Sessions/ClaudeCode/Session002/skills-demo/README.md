# Skills Demo

This project demonstrates how Claude Code loads **skills** into context based on the user's prompt intent — and how a skill can use **progressive disclosure** to load more files only when they're actually needed.

Companion to the [CLAUDE.md cascade demo](../claude-md-demo) and the [`.claude/rules/` demo](../rules-demo). Same pedagogical shape (tags embedded in responses as visibility markers) but for the `.claude/skills/` mechanism.

## The Mechanic

- A skill lives in `.claude/skills/<name>/SKILL.md` with YAML frontmatter containing `name` and `description`.
- **Unlike CLAUDE.md and rules, a skill does not load into context at session start.** Claude sees only its name and description. The skill body loads only when Claude decides the current prompt matches the description.
- Once a skill is active, it can instruct Claude to **read additional files** from the skill directory. Those files only enter context if Claude actually reads them. This is called **progressive disclosure**.
- Progressive disclosure can **branch**: a skill can tell Claude "read file A always, read file B only if condition X, read file C only if condition Y." Each branch is taken independently.

The `recipe-formatter` skill in this demo formats messy recipe text. It always reads a base `template.md` when triggered, and *conditionally* reads `vegan.md` (for plant-based recipes) or `beverage.md` (for drinks). Each file instructs Claude to emit a distinctive tag when it was read, so you can observe exactly what loaded.

| File | Tag |
|---|---|
| `SKILL.md` | `[RECIPE-FORMATTER]` |
| `template.md` | `[TEMPLATE-LOADED]` |
| `vegan.md` | `[VEGAN-LOADED]` |
| `beverage.md` | `[BEVERAGE-LOADED]` |

## Structure

```
skills-demo/
├── README.md                 (this file)
├── sample-recipe.txt         (chicken stir fry — template only)
├── sample-vegan.txt          (red lentil curry — template + vegan)
├── sample-beverage.txt       (vegan mango smoothie — template + beverage + vegan)
└── .claude/
    └── skills/
        └── recipe-formatter/
            ├── SKILL.md      → [RECIPE-FORMATTER]   (decides which add-ons to load)
            ├── template.md   → [TEMPLATE-LOADED]    (base formatting, always read when triggered)
            ├── vegan.md      → [VEGAN-LOADED]       (read only for plant-based recipes)
            └── beverage.md   → [BEVERAGE-LOADED]    (read only for drinks)
```

## Running the Demo

Start a fresh Claude Code session from this directory:

```
cd path/to/skills-demo && claude
```

Then run these prompts in order. **Start each prompt in a fresh session** — once a skill has been loaded in a session, it stays in context, which will muddy the next observation.

| # | Prompt | Expected tags | What it shows |
|---|--------|---------------|---------------|
| 1 | `What is 2 + 2?` | *(none)* | Skill doesn't load for unrelated prompts. The description didn't match. |
| 2 | `Format this recipe: @sample-recipe.txt` | `[RECIPE-FORMATTER]` `[TEMPLATE-LOADED]` | Description matches → skill loads → base template is read. No branches taken. |
| 3 | `Format this recipe: @sample-vegan.txt` | `[RECIPE-FORMATTER]` `[TEMPLATE-LOADED]` `[VEGAN-LOADED]` | Skill sees a plant-based recipe and takes the vegan branch in progressive disclosure. |
| 4 | `Format this recipe: @sample-beverage.txt` | `[RECIPE-FORMATTER]` `[TEMPLATE-LOADED]` `[BEVERAGE-LOADED]` `[VEGAN-LOADED]` | A *vegan smoothie* — both branches fire together. Progressive disclosure is a decision tree, not an either/or. |
| 5 | `Summarize @sample-recipe.txt` | *(none)* | Even though the file is the same recipe, the prompt intent is "summarize," not "format." The skill doesn't trigger. Unlike rules, skills do not fire based on which files are touched — only on prompt intent. |

> Within a single session, once a skill has been loaded it stays in context. To see each prompt cleanly, restart Claude Code between prompts.

## Key Findings

- **Skills are invisible to Claude until the description matches intent.** At session start, Claude only sees the skill's name and description, not its body. This is the big difference from CLAUDE.md and rules, both of which are loaded into context eagerly.
- **Description quality *is* the loading decision.** A vague description like "helps with text" will miss recipe prompts. A specific description like the one in `SKILL.md` — mentioning recipes, messy text, ingredients, and steps — reliably triggers.
- **Progressive disclosure keeps context lean.** SKILL.md stays short and only pulls in `template.md` + conditional add-ons when needed. The alternative — cramming every format variant into one big file — would waste tokens on every invocation.
- **Branches are independent.** Vegan and beverage are separate conditions; a vegan smoothie loads both. Claude evaluates each branch on its own.
- **File references don't trigger skills.** Unlike `.claude/rules/` with `paths`, the skill won't fire just because you opened a recipe file. You have to express the *intent* ("format this recipe") in the prompt. This is the key mental model difference: rules are path-scoped, skills are intent-scoped.

## How this compares to CLAUDE.md and rules

| | `CLAUDE.md` | `.claude/rules/` | Skills |
|---|---|---|---|
| **Trigger** | Directory ancestry (root loads at session start; nested loads when a file in that tree is touched) | Glob match on touched files | Semantic match between the user's prompt and the skill's description |
| **In context by default?** | Yes (if in your path) | Yes if no `paths` frontmatter; otherwise on match | **No** — only loaded when the description matches |
| **Scales with** | Project structure | File types / cross-cutting concerns | Task types |
| **Best for** | Project-wide facts ("we use pnpm, not npm") | File-type conventions ("all API handlers validate inputs") | Task-specific procedures ("format a recipe", "write a release note") |

Skills are the right tool when you have a repeatable procedure that isn't needed in every conversation. Putting that procedure in CLAUDE.md would waste context on every session where you don't use it.

## Variations to Try

- **Weaken the description.** Edit `SKILL.md`'s frontmatter `description` to something vague like "helps with text formatting." Restart and re-run prompt 2 — the skill may no longer trigger. This demonstrates that the description is the loading decision.
- **Collapse progressive disclosure.** Copy the contents of `template.md`, `vegan.md`, and `beverage.md` directly into `SKILL.md`. The recipes still format correctly, but the `[TEMPLATE-LOADED]` / `[VEGAN-LOADED]` / `[BEVERAGE-LOADED]` tags will disappear because nothing gets progressively disclosed anymore. SKILL.md is longer, and every invocation now pays for every branch whether relevant or not.
- **Try a non-matching prompt with the file attached.** Run `Tell me a story about @sample-recipe.txt`. The skill shouldn't fire — the file is there but the intent doesn't match. Contrast this with `.claude/rules/`, which would fire on the file path alone.
- **Make it user-level.** Move `.claude/skills/recipe-formatter/` to `~/.claude/skills/recipe-formatter/` and the skill is now available in every project on your machine.
- **Add a conflicting skill.** Create a second skill (`.claude/skills/recipe-summarizer/SKILL.md`) with a similar description. Run prompt 2 and see which one Claude picks — or whether it asks you to clarify.
