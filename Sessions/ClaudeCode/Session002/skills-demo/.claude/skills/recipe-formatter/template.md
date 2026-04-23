# Base Recipe Formatting Rules

Apply these rules to every recipe, regardless of type.

## Structure

Format the recipe using these sections, in this order:

```
# <Recipe Title in Title Case>

**Prep time:** <time>
**Cook time:** <time>
**Servings:** <number>

## Ingredients

- <quantity> <unit> <ingredient>
- ...

## Instructions

1. <step>
2. <step>
...
```

## Formatting rules

- Title: Title Case, no trailing punctuation.
- Ingredients: one per line as a bullet. Normalize units (e.g. "tbsp" not "tablespoon"; "tsp" not "teaspoon"; "g" not "grams"). Quantity first, then unit, then ingredient.
- Instructions: numbered steps, one action per step. Start each step with an imperative verb ("Heat the oil...", "Add the onions...").
- If prep time, cook time, or servings is not given in the input, infer a reasonable value and mark it with "(estimated)".

## Output requirement

IMPORTANT: Include the tag `[TEMPLATE-LOADED]` somewhere in your response on its own line. This confirms the base template was read.
