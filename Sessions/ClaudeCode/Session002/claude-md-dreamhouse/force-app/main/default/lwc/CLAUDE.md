# LWC Conventions — force-app/main/default/lwc/

IMPORTANT: Include the tag `[LWC]` somewhere in your response on its own line when these rules are loaded.

## Component structure

- One folder per component; filenames match the folder name (`propertyTile/propertyTile.js`, `propertyTile/propertyTile.html`, `propertyTile/propertyTile.js-meta.xml`).
- Use `@api` for public properties and `@track` only for non-primitive values that need reactivity — rarely needed in modern LWC.
- Prefer `@wire` over imperative Apex for cacheable reads. Use imperative calls for writes or on-demand fetches.

## Base components & styling

- Reach for `lightning-*` base components (`lightning-button`, `lightning-card`, `lightning-datatable`, etc.) before hand-rolling markup.
- Use SLDS utility classes in templates; avoid inline styles.

## Cross-component communication

- Use Lightning Message Service (LMS) for pub/sub across the DOM. Message channels live in `force-app/main/default/messageChannels/`.
- Use `CustomEvent` for parent/child communication within a single component tree.

## Error handling

- Reduce `@wire` and imperative Apex errors through the shared `reduceErrors` util in `ldsUtils/ldsUtils.js`.
- Display errors via the shared `errorPanel` component rather than ad-hoc markup.

## Tests

- Jest specs live in `__tests__/` alongside the component (e.g. `propertyTile/__tests__/propertyTile.test.js`).
- Run the full suite with `npm run test:unit`; watch mode is `npm run test:unit:watch`.
