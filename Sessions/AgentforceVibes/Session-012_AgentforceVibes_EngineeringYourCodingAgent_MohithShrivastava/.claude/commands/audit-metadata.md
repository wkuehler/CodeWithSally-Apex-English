---
allowed-tools: Bash, Read, Glob, Grep
description: Read-only audit of project metadata health and consistency
---

# Audit Metadata

You are performing a read-only audit of this Salesforce DX project's metadata health. Do NOT create, modify, or delete any files.

## Instructions

Run the following checks and compile a report:

### 1. Metadata Inventory

Glob across `force-app/main/default/` to build an inventory:
- **Apex Classes**: Count `.cls` files in `classes/`
- **Apex Triggers**: Count `.trigger` files in `triggers/`
- **LWC Components**: List directories in `lwc/`
- **Aura Components**: List directories in `aura/`
- **Flows**: Count `.flow-meta.xml` files in `flows/`
- **Permission Sets**: Count `.permissionset-meta.xml` files in `permissionsets/`
- **Custom Objects**: List directories in `objects/`
- **Flexi Pages**: Count files in `flexipages/`
- **Layouts**: Count files in `layouts/`
- **Static Resources**: Count files in `staticresources/`

### 2. Missing Test Classes

For each Apex class `{Name}.cls` (excluding files ending in `Test.cls`), check whether `{Name}Test.cls` exists. Report any classes without a matching test class.

### 3. API Version Consistency

- Read `sfdx-project.json` to get the project's declared API version
- Grep all `-meta.xml` files for `<apiVersion>` tags
- Report any files whose API version does not match the project-level version
- List the distinct API versions found and how many files use each

### 4. Empty Metadata Directories

Check these directories under `force-app/main/default/` and flag any that are empty (contain no metadata files):
- `classes/`, `triggers/`, `aura/`, `lwc/`, `flows/`, `objects/`, `permissionsets/`, `layouts/`, `flexipages/`, `staticresources/`, `tabs/`, `contentassets/`, `applications/`

### 5. LWC Completeness Check

For each LWC component directory, verify it contains the expected files:
- `{name}.js` (required)
- `{name}.html` (required)
- `{name}.js-meta.xml` (required)
- `{name}.css` (optional, note if missing)
- `__tests__/` directory (optional, note if missing)

### Report Format

Present findings as a structured report:

```
## Metadata Audit Report

### Inventory
| Metadata Type | Count | Details |
|---|---|---|

### Missing Test Classes
- {list or "All classes have test coverage"}

### API Version Consistency
- Project version: {version}
- {findings}

### Empty Directories
- {list or "No empty directories found"}

### LWC Completeness
| Component | JS | HTML | Meta | CSS | Tests |
|---|---|---|---|---|---|

### Recommendations
1. {prioritized recommendations based on findings}
```
