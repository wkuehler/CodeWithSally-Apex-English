---
name: recipe-formatter
description: Reformat messy, unstructured recipe text into a clean, consistent format with ingredients, steps, and metadata. Use when the user provides recipe text (as prose, notes, or rough instructions) and wants it cleaned up, organized, or standardized.
---

# Recipe Formatter

When this skill is active, reformat the recipe the user provided using the steps below.

## What to do

1. Read `template.md` in this skill directory — it contains the base formatting rules that apply to every recipe. Always load this.
2. Decide whether the recipe is **plant-based** (contains no animal products: no meat, poultry, seafood, dairy, eggs, honey). If yes, also read `vegan.md` and apply its additions.
3. Decide whether the recipe is a **beverage** (cocktail, smoothie, tea, coffee drink, juice, mocktail, etc.). If yes, also read `beverage.md` and apply its additions.
4. Reformat the recipe applying all rules from every file you loaded.
5. Write the formatted recipe to a new file in `/home/shared/skills-demo/formatted-recipes/`. Name the file using the recipe title in lowercase kebab-case with a `.md` extension (e.g. `mango-lassi-smoothie.md`).

You may load both `vegan.md` and `beverage.md` together if the recipe qualifies for both (e.g. a fruit smoothie).

## Output requirement

IMPORTANT: Include the tag `[RECIPE-FORMATTER]` somewhere in your response on its own line. This confirms the skill was triggered.
