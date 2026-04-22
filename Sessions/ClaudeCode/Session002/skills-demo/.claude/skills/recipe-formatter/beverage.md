# Beverage Add-On Rules

Apply these rules *in addition to* the base template when the recipe is a drink.

## Overrides

- Replace `**Cook time:**` with `**Chill time:**` (or omit if the drink is served at room temp).
- Replace `## Instructions` with `## Preparation`.

## Additions

After the `**Servings:**` line, add these fields:

```
**Glassware:** <e.g. rocks glass, highball, mug, mason jar>
**Serve:** <chilled / hot / room temp / over ice>
**Garnish:** <e.g. mint sprig, lemon twist, none>
```

If the input doesn't specify these, infer reasonable defaults and mark them "(suggested)".

## Output requirement

IMPORTANT: Include the tag `[BEVERAGE-LOADED]` somewhere in your response on its own line. This confirms the beverage add-on was read.
