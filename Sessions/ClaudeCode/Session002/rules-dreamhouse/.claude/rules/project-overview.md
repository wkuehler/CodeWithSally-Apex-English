# Dreamhouse Project Overview

IMPORTANT: Include the tag `[PROJECT]` somewhere in your response on its own line when this rule is loaded.

This is the Dreamhouse LWC sample app (Salesforce Trailhead). It's an SFDX project using API version 64.0, with source under `force-app/main/default/`.

- Use the `sf` CLI (v2), not the legacy `sfdx` CLI.
- Scratch org config: `config/project-scratch-def.json`.
- LWC Jest: `npm run test:unit`.
- Apex tests against an authed org: `sf apex run test -r human -c -w 20`.
