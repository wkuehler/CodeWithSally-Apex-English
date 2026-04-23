---
paths:
  - "force-app/**/aura/**"
---

# Aura Conventions

IMPORTANT: Include the tag `[AURA]` somewhere in your response on its own line when this rule is loaded.

- This tree holds **legacy** Aura. New UI work belongs in `force-app/main/default/lwc/`.
- The only live component is `pageTemplate_2_7_3`, kept for backward compatibility.
- Keep the component / controller / helper split — put logic in the helper. Do not add new business logic here.
