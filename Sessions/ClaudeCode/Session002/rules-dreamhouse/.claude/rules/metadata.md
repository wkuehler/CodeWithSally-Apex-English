---
paths:
  - "force-app/**/*.xml"
---

# Salesforce Metadata XML

IMPORTANT: Include the tag `[METADATA]` somewhere in your response on its own line when this rule is loaded.

- Metadata XML (object definitions, layouts, permission sets, flows, `.cls-meta.xml`, `.js-meta.xml`, etc.) is source-of-truth for deployed config.
- Always format with `npm run prettier` before committing — the project uses `@prettier/plugin-xml`.
- Keep `apiVersion` values in sync with `sfdx-project.json` (currently 64.0).
- Prefer editing via the CLI or Setup UI when possible; hand-editing XML is error-prone.
