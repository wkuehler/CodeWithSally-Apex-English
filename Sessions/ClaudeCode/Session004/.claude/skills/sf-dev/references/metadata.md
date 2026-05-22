# Metadata Gotchas

## Custom Fields

### Html (Rich Text Area)
`type>Html` is the metadata type for Rich Text Area. Two constraints that differ
from other field types:

- **`<required>` is not allowed** — omit entirely; deploy will fail if present.
- **`<visibleLines>` is required** — must be specified (e.g., `10`).

```xml
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Body__c</fullName>
    <label>Body</label>
    <length>32768</length>
    <type>Html</type>
    <visibleLines>10</visibleLines>
</CustomField>
```

## Custom Objects

### OWD via sharingModel
`<sharingModel>` on a CustomObject sets the org-wide default (OWD):

| `sharingModel` | OWD |
|---|---|
| `Private` | Private |
| `Read` | Public Read Only |
| `ReadWrite` | Public Read/Write |
| `ControlledByParent` | Controlled by Parent |

## Permission Sets (API 66.0+)

### `<userLicense>` is not valid
Removed in API 66.0. Delete the tag entirely or the deploy fails.

### Required fields cannot have explicit FLS
If a field is `<required>true</required>`, do **not** add it to `<fieldPermissions>`.
Salesforce rejects it:
> "You cannot deploy to a required field: ObjectName.FieldName"

### Minimal valid permission set
```xml
<?xml version="1.0" encoding="UTF-8"?>
<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>My Permission Set</label>
    <objectPermissions>
        <allowCreate>true</allowCreate>
        <allowDelete>false</allowDelete>
        <allowEdit>false</allowEdit>
        <allowRead>true</allowRead>
        <modifyAllRecords>false</modifyAllRecords>
        <object>MyObject__c</object>
        <viewAllRecords>false</viewAllRecords>
    </objectPermissions>
    <fieldPermissions>
        <editable>true</editable>
        <field>MyObject__c.SomeNonRequiredField__c</field>
        <readable>true</readable>
    </fieldPermissions>
</PermissionSet>
```
