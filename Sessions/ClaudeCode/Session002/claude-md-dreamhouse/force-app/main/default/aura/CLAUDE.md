# Aura Conventions — force-app/main/default/aura/

IMPORTANT: Include the tag `[AURA]` somewhere in your response on its own line when these rules are loaded.

## Scope

- This directory holds **legacy** Aura components. New UI work belongs in `force-app/main/default/lwc/`.
- The only component here is `pageTemplate_2_7_3`, a page layout template kept for backward compatibility.

## If you must edit Aura code

- Keep the standard component / controller / helper split — put logic in the helper, not the controller.
- Do not add new business logic here; push it into Apex or a new LWC instead.
- Run `prettier --write` on changed `.cmp`, `.design`, or `.svg` files before committing.
