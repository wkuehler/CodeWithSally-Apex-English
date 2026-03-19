# Flow Metadata XML Reference

Complete reference for the `<Flow>` metadata type used in `.flow-meta.xml` files.

**Metadata API Docs**: https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_visual_workflow.htm

## Root Element

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Flow xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>66.0</apiVersion>
    <description>Flow description</description>
    <environments>Default</environments>
    <interviewLabel>Runtime Label {!$Flow.CurrentDateTime}</interviewLabel>
    <label>Display Name</label>
    <processMetadataValues>...</processMetadataValues>
    <processType>Flow</processType>
    <runInMode>DefaultMode</runInMode>
    <start>...</start>
    <status>Active</status>

    <!-- Element groups (alphabetical order) -->
    <actionCalls>...</actionCalls>
    <assignments>...</assignments>
    <choices>...</choices>
    <constants>...</constants>
    <decisions>...</decisions>
    <dynamicChoiceSets>...</dynamicChoiceSets>
    <formulas>...</formulas>
    <loops>...</loops>
    <recordCreates>...</recordCreates>
    <recordDeletes>...</recordDeletes>
    <recordLookups>...</recordLookups>
    <recordUpdates>...</recordUpdates>
    <screens>...</screens>
    <subflows>...</subflows>
    <textTemplates>...</textTemplates>
    <transforms>...</transforms>
    <variables>...</variables>
</Flow>
```

## processMetadataValues

Always include these three for Screen Flows built with Lightning Flow Builder:

```xml
<processMetadataValues>
    <name>BuilderType</name>
    <value>
        <stringValue>LightningFlowBuilder</stringValue>
    </value>
</processMetadataValues>
<processMetadataValues>
    <name>CanvasMode</name>
    <value>
        <stringValue>AUTO_LAYOUT_CANVAS</stringValue>
    </value>
</processMetadataValues>
<processMetadataValues>
    <name>OriginBuilderType</name>
    <value>
        <stringValue>LightningFlowBuilder</stringValue>
    </value>
</processMetadataValues>
```

## Start Element

Screen Flow start is simple — just a connector to the first element:

```xml
<start>
    <locationX>176</locationX>
    <locationY>0</locationY>
    <connector>
        <targetReference>First_Screen</targetReference>
    </connector>
</start>
```

## FlowProcessType Enum

| Value | Description |
|---|---|
| `Flow` | Screen Flow (user interaction) |
| `AutoLaunchedFlow` | Autolaunched (record-triggered, scheduled, platform event, no trigger) |
| `Workflow` | Process Builder (legacy) |
| `CheckoutFlow` | Commerce checkout |
| `ContactRequestFlow` | Contact request |
| `FieldServiceMobile` | Field Service mobile |
| `LoginFlow` | Login flow |
| `OrchestrationFlow` | Flow orchestration |
| `RoutingFlow` | Omni-channel routing |
| `Survey` | Survey |

For Screen Flows, always use `<processType>Flow</processType>`.

## FlowRunInMode Enum

| Value | Description |
|---|---|
| `DefaultMode` | Runs in the context of the running user |
| `SystemModeWithSharing` | System mode, respects sharing rules |
| `SystemModeWithoutSharing` | System mode, ignores sharing rules |

## Flow Status Enum

| Value | UI Label |
|---|---|
| `Active` | Active |
| `Draft` | Inactive |
| `Obsolete` | Inactive |
| `InvalidDraft` | Draft (has errors) |

## Connector Types

| XML Element | Used In | Purpose |
|---|---|---|
| `<connector>` | All elements | Normal flow path (Next) |
| `<faultConnector>` | DML, SOQL, Action elements | Error handling path |
| `<defaultConnector>` | Decisions, Waits | Default/else outcome |
| `<nextValueConnector>` | Loops | Path for each iteration |
| `<noMoreValuesConnector>` | Loops | Path after loop completes |

All connectors share the same structure:

```xml
<connector>
    <targetReference>Element_API_Name</targetReference>
</connector>
```

## FlowElementReferenceOrValue (Value Types)

This polymorphic type appears everywhere a value is needed. Use exactly one child:

```xml
<!-- String literal -->
<value><stringValue>hello</stringValue></value>

<!-- Number literal -->
<value><numberValue>42.0</numberValue></value>

<!-- Boolean literal -->
<value><booleanValue>true</booleanValue></value>

<!-- Date literal -->
<value><dateValue>2024-01-15</dateValue></value>

<!-- DateTime literal -->
<value><dateTimeValue>2024-01-15T10:30:00.000Z</dateTimeValue></value>

<!-- Reference to variable, element output, or field -->
<value><elementReference>var_AccountName</elementReference></value>
```

## FlowDataType Enum

| Value | Description | Extra Fields |
|---|---|---|
| `String` | Text | — |
| `Number` | Numeric | `scale` for decimal places |
| `Currency` | Monetary | `scale` for decimal places |
| `Boolean` | true/false | — |
| `Date` | Date only | — |
| `DateTime` | Date and time | — |
| `SObject` | Salesforce record | `objectType` required |
| `Apex` | Apex class instance | `apexClass` required |
| `Picklist` | Picklist value | — |
| `Multipicklist` | Multi-select picklist | semicolon-delimited |

## FlowComparisonOperator Enum

Used in Decision conditions and Record filters:

| Operator | Description |
|---|---|
| `EqualTo` | Equals |
| `NotEqualTo` | Not equals |
| `GreaterThan` | Greater than |
| `GreaterThanOrEqualTo` | Greater than or equal |
| `LessThan` | Less than |
| `LessThanOrEqualTo` | Less than or equal |
| `Contains` | Contains substring |
| `StartsWith` | Starts with |
| `EndsWith` | Ends with |
| `IsNull` | Is null (right value is Boolean) |
| `In` | In collection |
| `NotIn` | Not in collection |

**Docs**: https://help.salesforce.com/s/articleView?id=platform.flow_ref_operators_condition.htm&type=5

## FlowAssignmentOperator Enum

| Operator | Description |
|---|---|
| `Assign` | Direct assignment |
| `Add` | Add to number or add to collection |
| `Subtract` | Subtract from number |
| `AddItem` | Add item to collection |
| `AddAtStart` | Add at start of collection |
| `AssignCount` | Assign count of collection to number |
| `Remove` | Remove value from collection |
| `RemoveAll` | Remove all matching values |
| `RemoveFirst` | Remove first occurrence |

**Docs**: https://help.salesforce.com/s/articleView?id=platform.flow_ref_operators_assignment.htm&type=5

## Key Structural Rules

1. Root-level element groups must appear in **alphabetical order**
2. XML namespace is always `xmlns="http://soap.sforce.com/2006/04/metadata"`
3. File extension is `.flow-meta.xml`
4. File location: `force-app/main/default/flows/{Flow_API_Name}.flow-meta.xml`
5. With `AUTO_LAYOUT_CANVAS`, `locationX` and `locationY` are still required but the builder manages positioning
6. Element `name` fields use underscores (`Create_Account`), not camelCase
7. Every element that is part of the flow path must be connected via connectors — orphaned elements cause deployment errors
