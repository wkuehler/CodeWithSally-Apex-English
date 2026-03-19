---
name: salesforce-screen-flow-builder
description: Generate deployable Salesforce Screen Flow .flow-meta.xml files from requirements. Use when users want to create screen flows, build guided user interfaces with Flow Builder, design multi-step data collection or display workflows, or need help with any Flow metadata element including screens, decisions, record operations, loops, choices, and formulas.
---

# Salesforce Screen Flow Builder

Generate valid, deployable `.flow-meta.xml` files for Salesforce Screen Flows. This skill produces actual Flow metadata XML — not documentation or guidance.

## When to Use This Skill

Activate when the user wants to:
- Create a new Screen Flow from requirements
- Add screens, decisions, record operations, or loops to a flow
- Build data collection forms, record viewers, or guided wizards
- Generate flow metadata XML that can be deployed via `sf project deploy start`

## Before You Start

1. **Read `sfdx-project.json`** to get the project's API version (use it in `<apiVersion>`)
2. **Read existing flows** in `force-app/main/default/flows/` to avoid naming conflicts and match conventions
3. **Read the project's existing flow** in this repo for a working reference:
   - `force-app/main/default/flows/Create_Account_And_Contact.flow-meta.xml`

## Progressive Resource Loading

Load these resources as needed — don't read them all upfront. Pick the ones relevant to the user's requirements.

| Resource | When to Load | Path |
|---|---|---|
| **Flow Metadata Reference** | Always — core structure, enums, connectors, value types | `resources/flow-metadata-reference.md` |
| **Screen Field Types** | Building screens with inputs, dropdowns, datatables, sections | `resources/screen-field-types.md` |
| **Element Patterns** | Decisions, loops, record operations, formulas, choices, subflows | `resources/element-patterns.md` |
| **Example: Data Entry Flow** | Multi-screen forms with validation and record creation | `resources/example-data-entry-flow.xml` |
| **Example: Record Lookup Flow** | Record queries, datatables, decisions, formulas | `resources/example-record-lookup-flow.xml` |

**External references** (use when you need detail beyond the resources above):
- [Flow Metadata API](https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_visual_workflow.htm) — complete type reference
- [LWC in Flow Screens](https://developer.salesforce.com/docs/platform/lwc/guide/use-config-for-flow-screens.html) — ComponentInstance configuration
- [Flow Data Types](https://developer.salesforce.com/docs/platform/lwc/guide/use-flow-data-types.html) — supported data types
- [Condition Operators](https://help.salesforce.com/s/articleView?id=platform.flow_ref_operators_condition.htm&type=5) — comparison operators
- [Assignment Operators](https://help.salesforce.com/s/articleView?id=platform.flow_ref_operators_assignment.htm&type=5) — assignment operators

## Output Requirements

Every generated flow must:

1. **Be a complete, valid `.flow-meta.xml` file** — deployable as-is
2. **Use the project's API version** from `sfdx-project.json`
3. **Set `processType` to `Flow`** (Screen Flow)
4. **Set `status` to `Draft`** (user activates after testing)
5. **Include all three `processMetadataValues`** (BuilderType, CanvasMode, OriginBuilderType)
6. **Connect every element** — no orphaned elements; every path must lead somewhere
7. **Include `faultConnector`** on all DML and SOQL elements pointing to an error screen
8. **Include an error screen** with `{!$Flow.FaultMessage}` and a "Try Again" back button
9. **Write the file** to `force-app/main/default/flows/{Flow_API_Name}.flow-meta.xml`

## Flow XML Skeleton

Every Screen Flow starts with this structure:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Flow xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>{API_VERSION}</apiVersion>
    <description>{description}</description>
    <environments>Default</environments>
    <interviewLabel>{label} {!$Flow.CurrentDateTime}</interviewLabel>
    <label>{Display Name}</label>
    <processMetadataValues>
        <name>BuilderType</name>
        <value><stringValue>LightningFlowBuilder</stringValue></value>
    </processMetadataValues>
    <processMetadataValues>
        <name>CanvasMode</name>
        <value><stringValue>AUTO_LAYOUT_CANVAS</stringValue></value>
    </processMetadataValues>
    <processMetadataValues>
        <name>OriginBuilderType</name>
        <value><stringValue>LightningFlowBuilder</stringValue></value>
    </processMetadataValues>
    <processType>Flow</processType>
    <start>
        <locationX>176</locationX>
        <locationY>0</locationY>
        <connector>
            <targetReference>{First_Element}</targetReference>
        </connector>
    </start>
    <status>Draft</status>

    <!-- Elements in alphabetical order by type:
         actionCalls, assignments, choices, constants, decisions,
         dynamicChoiceSets, formulas, loops, recordCreates, recordDeletes,
         recordLookups, recordUpdates, screens, subflows, textTemplates,
         transforms, variables -->
</Flow>
```

## Core Patterns

### Screen with Input Fields

```xml
<screens>
    <name>Input_Screen</name>
    <label>Enter Details</label>
    <locationX>176</locationX>
    <locationY>158</locationY>
    <allowBack>false</allowBack>
    <allowFinish>true</allowFinish>
    <allowPause>false</allowPause>
    <connector>
        <targetReference>Next_Element</targetReference>
    </connector>
    <fields>
        <name>Input_Name</name>
        <dataType>String</dataType>
        <fieldText>Name</fieldText>
        <fieldType>InputField</fieldType>
        <isRequired>true</isRequired>
    </fields>
    <showFooter>true</showFooter>
    <showHeader>true</showHeader>
</screens>
```

### Create Record with Error Handling

```xml
<recordCreates>
    <name>Create_Record</name>
    <label>Create Record</label>
    <locationX>176</locationX>
    <locationY>278</locationY>
    <connector>
        <targetReference>Success_Screen</targetReference>
    </connector>
    <faultConnector>
        <targetReference>Error_Screen</targetReference>
    </faultConnector>
    <inputAssignments>
        <field>Name</field>
        <value>
            <elementReference>Input_Name</elementReference>
        </value>
    </inputAssignments>
    <object>Account</object>
    <storeOutputAutomatically>true</storeOutputAutomatically>
</recordCreates>
```

### Error Screen (include in every flow)

```xml
<screens>
    <name>Error_Screen</name>
    <label>Error</label>
    <locationX>440</locationX>
    <locationY>398</locationY>
    <allowBack>true</allowBack>
    <allowFinish>true</allowFinish>
    <allowPause>false</allowPause>
    <backButtonLabel>Try Again</backButtonLabel>
    <connector>
        <targetReference>Input_Screen</targetReference>
    </connector>
    <fields>
        <name>Error_Message</name>
        <fieldType>DisplayText</fieldType>
        <fieldText>&lt;p&gt;&lt;span style=&quot;color: rgb(194, 57, 52);&quot;&gt;&lt;b&gt;An error occurred&lt;/b&gt;&lt;/span&gt;&lt;/p&gt;&lt;p&gt;{!$Flow.FaultMessage}&lt;/p&gt;</fieldText>
    </fields>
    <showFooter>true</showFooter>
    <showHeader>true</showHeader>
</screens>
```

### Decision (Branching)

```xml
<decisions>
    <name>Check_Value</name>
    <label>Check Value</label>
    <locationX>176</locationX>
    <locationY>398</locationY>
    <defaultConnector>
        <targetReference>Default_Path</targetReference>
    </defaultConnector>
    <defaultConnectorLabel>Default</defaultConnectorLabel>
    <rules>
        <name>Match_Found</name>
        <label>Match Found</label>
        <conditionLogic>and</conditionLogic>
        <conditions>
            <leftValueReference>Input_Type</leftValueReference>
            <operator>EqualTo</operator>
            <rightValue>
                <stringValue>Enterprise</stringValue>
            </rightValue>
        </conditions>
        <connector>
            <targetReference>Enterprise_Path</targetReference>
        </connector>
    </rules>
</decisions>
```

### Variable Declaration

```xml
<variables>
    <name>varRecordId</name>
    <dataType>String</dataType>
    <isCollection>false</isCollection>
    <isInput>false</isInput>
    <isOutput>false</isOutput>
</variables>
```

## Naming Conventions

| Element | Convention | Example |
|---|---|---|
| Flow API name | `Verb_Noun_Qualifier` | `Create_Account_And_Contact` |
| Screen names | `Purpose_Screen` | `Input_Screen`, `Error_Screen` |
| Input fields | `Input_FieldName` | `Input_AccountName` |
| Variables | `var` prefix, camelCase | `varAccountId`, `varContactCount` |
| Choices | `Choice_` prefix | `Choice_High`, `Choice_Technology` |
| Decisions | Descriptive question | `Has_Contacts`, `Check_Account_Type` |
| Record operations | `Verb_Object` | `Create_Account`, `Get_Contacts` |
| Collections | `col` prefix | `colSelectedIds` |
| Record variables | `rec` prefix | `recAccount` |
| Formulas | Descriptive name | `Full_Name`, `Commission_Amount` |

## Common Flow Patterns

### Pattern 1: Data Collection Form
**Use case:** Collect user input and create a record
**Flow:** Screen → Create Record → Success Screen
**Fault path:** Create Record → Error Screen → back to Input Screen
**Load:** `resources/example-data-entry-flow.xml`

### Pattern 2: Multi-Step Wizard
**Use case:** Guided process across multiple screens
**Flow:** Screen 1 (allowBack=false) → Screen 2 (allowBack=true) → ... → Create Records → Confirmation
**Key:** Set `allowBack=true` on screens 2+, do NOT use `storeOutputAutomatically` on screen input fields

### Pattern 3: Record Lookup and Display
**Use case:** Query and display records (datatable, detail view)
**Flow:** Get Records → Decision (found?) → Display Screen with datatable / Empty State Screen
**Load:** `resources/example-record-lookup-flow.xml`, `resources/screen-field-types.md` (ComponentInstance section)

### Pattern 4: Edit Existing Record
**Use case:** Look up a record, show current values, let user edit, save changes
**Flow:** Get Record → Edit Screen (pre-populated) → Update Record → Success Screen
**Key:** Use `recordId` input variable with `isInput=true`, pre-populate screen fields via merge references

### Pattern 5: Bulk Processing with Loop
**Use case:** Process multiple records from user selection
**Flow:** Screen (datatable) → Loop over selected → Assignment/DML per item → Summary Screen
**Load:** `resources/element-patterns.md` (Loops section)

### Pattern 6: Conditional Branching
**Use case:** Different paths based on user choices
**Flow:** Screen with DropdownBox/RadioButtons → Decision → Path A / Path B / Default
**Load:** `resources/element-patterns.md` (Decisions section), `resources/screen-field-types.md` (DropdownBox/RadioButtons)

## Structural Rules

1. **Element ordering:** Root-level element groups must be alphabetical (`actionCalls` before `assignments` before `choices`, etc.)
2. **Connectors are mandatory:** Every element in the flow path must have a `<connector>` to the next element. The only exception is a terminal screen (flow ends there).
3. **faultConnectors:** Always add `<faultConnector>` on `recordCreates`, `recordUpdates`, `recordDeletes`, `recordLookups`, and `actionCalls`
4. **locationX/locationY:** Required on all elements. Use `176` for the main path X, `440` for fault path X. Increment Y by ~120 per element.
5. **storeOutputAutomatically:** Set to `true` ONLY on record operations (`recordCreates`, `recordUpdates`, etc.). DO NOT use on screen fields with `fieldType` of `InputField` or `DropdownBox` - it will cause deployment failures.
6. **XML namespace:** Always `xmlns="http://soap.sforce.com/2006/04/metadata"` on the `<Flow>` root
7. **HTML in DisplayText:** Must be HTML-entity-encoded (`&lt;p&gt;` not `<p>`)
8. **File path:** `force-app/main/default/flows/{Flow_API_Name}.flow-meta.xml`

## After Generating

1. List the file you created with a brief summary of the flow
2. Describe the flow path: Start → Element 1 → Element 2 → ... → End
3. Note any input variables the flow expects (e.g., `recordId` for record page embedding)
4. Remind the user to deploy with `sf project deploy start` and activate in Setup → Flows
