# Agentforce Vibes: Skills & Rules — Agent Reference Guide

## Skills

Skills are **on-demand** modular instruction sets that extend agent capabilities. They load only when relevant, saving context tokens.

### Progressive Loading Model

| Level | When | ~Cost | Content |
|---|---|---|---|
| Metadata | Startup | ~100 tokens | Name + description (YAML frontmatter) |
| Instructions | Triggered | <5k tokens | SKILL.md body |
| Resources | As needed | Unlimited | Files in `docs/`, `templates/`, `scripts/` |

### Structure

```text
my-skill/
├── SKILL.md          # Required
├── docs/             # Optional: extended documentation
├── templates/        # Optional: boilerplate/config files
└── scripts/          # Optional: deterministic operations
```

**SKILL.md format:**

```markdown
---
name: my-skill
description: Brief description of what this skill does and when to use it.
---

# My Skill

Detailed instructions here.

## Steps
1. First step
2. Second step
3. See [advanced.md](docs/advanced.md)
```

**Required fields:**
- `name` — must exactly match directory name
- `description` — max 1024 chars; determines when the skill activates

### Naming

Use **kebab-case**, be descriptive.
- ✅ `apex-class-generator`, `soql-query-runner`
- ❌ `sf`, `my_skill`, `DeployToOrg`, `misc-helpers`

### Descriptions

Use action verbs, include trigger phrases, mention specific tools/file types/domains.

```text
# Good
Deploy metadata to a Salesforce org using Salesforce DX. Use when deploying, updating, or synchronizing Salesforce applications and components.

# Bad
Helps with Deploy stuff.
```

### Locations

| Path | Scope |
|---|---|
| `.a4drules/skills/` | Project (recommended, version-controllable) |
| OS-specific `globalStorage` | Global |

Global skills take precedence over project skills with the same name.

### Key Guidelines

- Keep `SKILL.md` under 5k tokens; split large content into `docs/`.
- Front-load important information; use clear `##` headers.
- Use `scripts/` for validation, formatting, computations — only output enters context.
- Toggle skills on/off via the ⚖️ icon > Skills tab.

---

## Rules

Rules are **always-active** persistent guidance shaping all agent behavior. They enforce coding standards, architecture patterns, and project preferences.

### Rule Types

- **Global** — apply across all projects
- **Workspace** — specific to a project, stored in `.a4drules/`

### Loading Order

1. `.a4drules/` folder (all `.md` files combined; numeric prefixes like `01-`, `02-` control order)
2. Single `.a4drules` file
3. `agents.md` file

Workspace rules override global rules on conflicts.

### Rule Format

```markdown
# Rule: [Rule Name]

**Description:** [Purpose]

**Guidelines:**
- Guideline 1
- Guideline 2
```

### Creating Rules

- ⚖️ icon > select Global/Workspace > click **+**
- Or use `/newrule` slash command in chat

### OOTB Rules

Three built-in rules enabled by default:
- `a4d-general-rules-no-edit.md`
- `a4d-apex-rules-no-edit.md`
- `a4d-lwc-rules-no-edit.md`

Editable, but changes are overwritten on extension update.

### Best Practices

- One file type per rule
- Be clear and precise
- Test rules across different features
- Update regularly as project evolves

---

## Skills vs Rules at a Glance

| | Skills | Rules |
|---|---|---|
| **Loading** | On-demand | Always active |
| **Purpose** | Task-specific workflows | Persistent standards |
| **Location** | `.a4drules/skills/` | `.a4drules/` |
| **Token impact** | ~100 tokens idle; full cost only when triggered | Always in context |
