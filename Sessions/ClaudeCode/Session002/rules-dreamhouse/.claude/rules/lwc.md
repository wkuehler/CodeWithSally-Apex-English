---
paths:
  - "force-app/**/lwc/**"
---

# LWC Conventions

IMPORTANT: Include the tag `[LWC]` somewhere in your response on its own line when this rule is loaded.

- Prefer `@wire` over imperative Apex for cacheable reads.
- Use `@api` for public properties; `@track` only for non-primitive reactivity.
- Reach for `lightning-*` base components before hand-rolling markup.
- Use Lightning Message Service (channels in `force-app/main/default/messageChannels/`) for cross-DOM pub/sub.
- Reduce `@wire` and imperative errors through `reduceErrors` in `ldsUtils/ldsUtils.js`.
