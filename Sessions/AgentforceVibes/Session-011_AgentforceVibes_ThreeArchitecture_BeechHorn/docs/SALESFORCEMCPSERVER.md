# Salesforce DX MCP Server — Configuration Manual

> Package: `@salesforce/mcp` · Status: Beta · [Source](https://github.com/salesforcecli/mcp) · [Docs](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_mcp.htm)

---

## 1. Prerequisites

Before configuring the MCP server you must:

1. Have **Node.js** and **npx** available on your PATH.
2. **Authorize at least one Salesforce org** locally via `sf org login web` (or the VS Code command palette equivalent). The MCP server connects to already-authorized orgs only — it cannot initiate auth itself.

---

## 2. Anatomy of a Configuration

Every MCP client (VS Code, Claude Code, Cursor, Cline, etc.) reads a JSON config file. The shape varies slightly but the `args` array is identical everywhere.

```jsonc
{
  "<wrapper_key>": {                 // "servers" (VS Code) or "mcpServers" (most others)
    "Salesforce DX": {
      "command": "npx",
      "args": [
        "-y", "@salesforce/mcp",     // fixed — installs the package automatically
        "--orgs",     "<value>",     // REQUIRED — which org(s) to expose
        "--toolsets", "<value>",     // OPTIONAL — groups of tools to register
        "--tools",    "<value>",     // OPTIONAL — individual tools to register
        "--allow-non-ga-tools",      // OPTIONAL boolean flag
        "--dynamic-tools",           // OPTIONAL boolean flag
        "--debug",                   // OPTIONAL boolean flag
        "--no-telemetry"             // OPTIONAL boolean flag
      ]
    }
  }
}
```

**Formatting rules for `args`:**
- Every flag name *and* every value must be its own quoted string.
- Separate all elements with commas.
- Boolean flags (`--debug`, `--allow-non-ga-tools`, etc.) stand alone with no value.
- Multi-value flags use a single comma-delimited string: `"orgs,metadata,data"`.

---

## 3. Flag Reference

| Flag | Type | Required | Default | Purpose |
|---|---|---|---|---|
| `--orgs` | string | **Yes** | — | Comma-separated list of authorized orgs to expose. |
| `--toolsets` | string | No | `core` only | Comma-separated toolset names to enable. |
| `--tools` | string | No | — | Comma-separated individual tool names to enable (additive with `--toolsets`). |
| `--allow-non-ga-tools` | boolean | No | `false` | Unlock NON-GA tools within selected toolsets/tools. |
| `--dynamic-tools` | boolean | No | `false` | *Experimental.* Start with minimal tools, load on demand. Reduces initial context. Works in VS Code and Cline. |
| `--debug` | boolean | No | `false` | Emit debug logs (only visible in clients that expose MCP logs). |
| `--no-telemetry` | boolean | No | `false` | Disable telemetry collection. |

---

## 4. `--orgs` Values

| Value | Resolves to |
|---|---|
| `DEFAULT_TARGET_ORG` | Local project default org, falling back to global default. |
| `DEFAULT_TARGET_DEV_HUB` | Local project default Dev Hub, falling back to global default. |
| `ALLOW_ALL_ORGS` | Every locally-authorized org. **Use with caution.** |
| `<username or alias>` | A specific org by its username or CLI alias. |

Combine multiple: `"--orgs", "DEFAULT_TARGET_ORG,my-sandbox,admin@devhub.org"`

---

## 5. Toolsets at a Glance

The server ships 60+ tools grouped into toolsets. Only `core` is always active; everything else is opt-in.

| Toolset | What it gives you | Key tools |
|---|---|---|
| `core` | Always on. Org resolution, resume long-running ops. | `get_username`, `resume_tool_operation` |
| `orgs` | Org lifecycle management. | `list_all_orgs` (GA), `create_scratch_org`, `delete_org`, `open_org` (NON-GA) |
| `metadata` | Deploy & retrieve metadata. | `deploy_metadata`, `retrieve_metadata` |
| `data` | Query org data. | `run_soql_query` |
| `users` | User/permission management. | `assign_permission_set` |
| `testing` | Run tests. | `run_apex_test`, `run_agent_test` |
| `code-analysis` | Static analysis via Code Analyzer. | `run_code_analyzer`, `query_code_analyzer_results`, `list_code_analyzer_rules` |
| `lwc-experts` | LWC dev, testing, GraphQL, accessibility. | `create_lwc_component_from_prd`, `create_lwc_jest_tests`, `guide_lwc_*`, `create_lds_graphql_*` |
| `aura-experts` | Aura analysis & migration to LWC. | `orchestrate_aura_migration`, `create_aura_blueprint_draft` |
| `devops` | DevOps Center work items & merge conflicts. | `detect_devops_center_merge_conflict` (GA), `list_devops_center_work_items` (NON-GA) |
| `enrich_metadata` | Enrich metadata in DX projects. | `enrich_metadata` (NON-GA) |
| `mobile` | Full mobile dev capability set. | `create_mobile_lwc_barcode_scanner`, `get_mobile_lwc_offline_analysis`, etc. |
| `mobile-core` | Subset of `mobile` — essentials only. | Barcode, biometrics, location, offline analysis/guidance. |
| `scale-products` | Apex performance analysis. | `scan_apex_class_for_antipatterns` |
| `all` | Enables **everything**. Not recommended — context overload for LLMs. | — |

---

## 6. Goal-Oriented Configuration Recipes

Below are copy-paste ready `args` arrays for common scenarios.

### 6.1 — Minimal: Query Data & Manage Orgs

Goal: An agent that can list orgs, run SOQL, and assign permission sets.

```json
"args": ["-y", "@salesforce/mcp",
         "--orgs", "DEFAULT_TARGET_ORG",
         "--toolsets", "orgs,data,users"]
```

### 6.2 — CI/CD Agent: Deploy, Test & Analyze

Goal: Autonomous deploy → test → static analysis loop.

```json
"args": ["-y", "@salesforce/mcp",
         "--orgs", "DEFAULT_TARGET_ORG",
         "--toolsets", "metadata,testing,code-analysis"]
```

### 6.3 — LWC Development Assistant

Goal: Full LWC lifecycle — scaffold, test, accessibility, GraphQL.

```json
"args": ["-y", "@salesforce/mcp",
         "--orgs", "DEFAULT_TARGET_ORG",
         "--toolsets", "lwc-experts,testing,metadata",
         "--allow-non-ga-tools"]
```

### 6.4 — Aura-to-LWC Migration Agent

Goal: End-to-end Aura migration workflow.

```json
"args": ["-y", "@salesforce/mcp",
         "--orgs", "DEFAULT_TARGET_ORG",
         "--toolsets", "aura-experts,lwc-experts,metadata",
         "--allow-non-ga-tools"]
```

### 6.5 — DevOps Center Merge-Conflict Resolver

Goal: Detect and resolve merge conflicts, manage work items.

```json
"args": ["-y", "@salesforce/mcp",
         "--orgs", "DEFAULT_TARGET_ORG,DEFAULT_TARGET_DEV_HUB",
         "--toolsets", "devops,orgs",
         "--allow-non-ga-tools"]
```

### 6.6 — Mobile Offline Development

Goal: Build and validate offline-capable mobile LWC components.

```json
"args": ["-y", "@salesforce/mcp",
         "--orgs", "DEFAULT_TARGET_ORG",
         "--toolsets", "mobile-core,lwc-experts,metadata"]
```

### 6.7 — Surgical: Single Tool Only

Goal: An agent that can *only* run Apex tests — nothing else.

```json
"args": ["-y", "@salesforce/mcp",
         "--orgs", "DEFAULT_TARGET_ORG",
         "--tools", "run_apex_test"]
```

### 6.8 — Multi-Org with Minimal Context

Goal: Access two named orgs with dynamic tool loading to conserve LLM tokens.

```json
"args": ["-y", "@salesforce/mcp",
         "--orgs", "dev@sandbox.org,admin@staging.org",
         "--toolsets", "orgs,metadata,data",
         "--dynamic-tools"]
```

### 6.9 — Kitchen Sink (Not Recommended)

Goal: Everything available. Useful for exploration only — the 60+ tool definitions will consume significant LLM context.

```json
"args": ["-y", "@salesforce/mcp",
         "--orgs", "ALLOW_ALL_ORGS",
         "--toolsets", "all",
         "--allow-non-ga-tools",
         "--debug"]
```

---

## 7. Client Config File Locations

| Client | Wrapper Key | File Path |
|---|---|---|
| VS Code (Copilot) | `"servers"` | `.vscode/mcp.json` in project root |
| Claude Code | `"mcpServers"` | `.mcp.json` in project root |
| Cline | `"mcpServers"` | `cline_mcp_settings.json` |
| Cursor | `"mcpServers"` | `mcp.json` (see Cursor docs) |

---

## 8. Design Principles for Agent Configurations

**Minimise registered tools.** Every tool definition is injected into the LLM context window. Registering `all` 60+ tools wastes tokens and increases tool-selection ambiguity. Prefer targeted `--toolsets` + `--tools` combos.

**Use `--dynamic-tools` where supported.** This starts the server with a minimal tool surface and loads tools lazily. It's ideal for agents that handle diverse requests but shouldn't pay the context cost upfront.

**Scope `--orgs` tightly.** `ALLOW_ALL_ORGS` grants the agent access to every authorized org on the machine. For production agents, pin to a specific username/alias or use `DEFAULT_TARGET_ORG`.

**Combine `--toolsets` and `--tools`.** You can enable a full toolset *and* cherry-pick individual tools from another. e.g., all `data` tools plus `run_apex_test` from `testing`:

```json
"--toolsets", "data", "--tools", "run_apex_test"
```

**Gate NON-GA tools deliberately.** Only add `--allow-non-ga-tools` when your workflow needs it. NON-GA tools (marked in the tool lists) may change or be removed.

---

## 9. Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| Server fails to start | No authorized orgs | Run `sf org login web` first. |
| Tools not appearing | Toolset not specified | Add the toolset to `--toolsets` or the tool name to `--tools`. |
| NON-GA tool missing | Flag not set | Add `--allow-non-ga-tools`. |
| Agent picks wrong tool | Too many tools registered | Narrow `--toolsets` or enable `--dynamic-tools`. |
| No debug output | Client hides MCP logs | Check client docs; not all expose MCP stderr. |
| `npx` prompts for install | Missing `-y` flag | Ensure `"-y"` is the first element in `args`. |

---

## 10. Quick-Start Checklist

1. `sf org login web -a my-org` — authorize your org.
2. Choose a recipe from §6 or compose your own from §3–5.
3. Paste config into the correct file for your client (§7).
4. Reload/restart your MCP client.
5. Verify tools are registered (most clients show a tool list or log).
6. Prompt your agent — e.g. *"List all custom objects in my org"* or *"Deploy the force-app directory"*.
