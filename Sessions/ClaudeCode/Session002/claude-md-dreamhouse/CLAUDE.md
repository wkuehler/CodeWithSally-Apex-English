# Dreamhouse LWC — Project Rules

IMPORTANT: Include the tag `[DREAMHOUSE]` somewhere in your response on its own line when these rules are loaded.

## Project basics

- SFDX project, API version 64.0 (see `sfdx-project.json`). Use the `sf` CLI, not the legacy `sfdx` CLI.
- Source lives under `force-app/main/default/`.
- Scratch org config: `config/project-scratch-def.json`. Spin one up with:
  `sf org create scratch -f config/project-scratch-def.json -a dreamhouse -d -y 30`
- Deploy source with `sf project deploy start`; for scratch orgs, `sf project source push` is fine.

## Scripts

- `npm run test:unit` — LWC Jest via `sfdx-lwc-jest`.
- `npm run lint` — ESLint across `**/lwc/**/*.js`.
- `npm run prettier` — formats Apex, LWC, XML, and more (`prettier-plugin-apex`, `@prettier/plugin-xml`).
- Husky pre-commit runs `lint-staged`: Prettier on changed files, ESLint on LWC JS, and related LWC Jest tests.

Run Apex tests against an authed org with `sf apex run test -r human -c -w 20`.
