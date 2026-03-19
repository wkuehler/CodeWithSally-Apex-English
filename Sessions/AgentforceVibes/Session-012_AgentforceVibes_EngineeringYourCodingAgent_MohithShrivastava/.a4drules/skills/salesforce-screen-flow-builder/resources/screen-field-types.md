# Screen Field Types Reference

All field types available inside a `<screens>` element's `<fields>` list.

**Docs**: https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_visual_workflow.htm

## InputField

Standard input for text, number, date, currency, and boolean values. The `dataType` determines the rendered input control.

```xml
<fields>
    <name>Input_AccountName</name>
    <dataType>String</dataType>
    <fieldText>Account Name</fieldText>
    <fieldType>InputField</fieldType>
    <isRequired>true</isRequired>
    <storeOutputAutomatically>true</storeOutputAutomatically>
</fields>
```

**Supported dataType values for InputField:**
- `String` — single-line text input
- `Number` — numeric input (use `scale` for decimal places)
- `Currency` — currency input (use `scale` for decimal places)
- `Date` — date picker
- `DateTime` — date and time picker
- `Boolean` — checkbox

```xml
<!-- Number with 2 decimal places -->
<fields>
    <name>Input_Amount</name>
    <dataType>Number</dataType>
    <fieldText>Amount</fieldText>
    <fieldType>InputField</fieldType>
    <isRequired>true</isRequired>
    <scale>2</scale>
    <storeOutputAutomatically>true</storeOutputAutomatically>
</fields>

<!-- Date picker -->
<fields>
    <name>Input_StartDate</name>
    <dataType>Date</dataType>
    <fieldText>Start Date</fieldText>
    <fieldType>InputField</fieldType>
    <isRequired>false</isRequired>
    <storeOutputAutomatically>true</storeOutputAutomatically>
</fields>

<!-- Checkbox -->
<fields>
    <name>Input_IsActive</name>
    <dataType>Boolean</dataType>
    <fieldText>Is Active?</fieldText>
    <fieldType>InputField</fieldType>
    <isRequired>false</isRequired>
    <storeOutputAutomatically>true</storeOutputAutomatically>
</fields>
```

## DisplayText

Read-only rich text display. Content goes in `fieldText` as HTML-encoded text.

```xml
<fields>
    <name>Welcome_Message</name>
    <fieldType>DisplayText</fieldType>
    <fieldText>&lt;p&gt;&lt;b&gt;Welcome&lt;/b&gt;&lt;/p&gt;&lt;p&gt;Fill out the form below to create a new record.&lt;/p&gt;</fieldText>
</fields>
```

HTML entities: `&lt;` = `<`, `&gt;` = `>`, `&amp;` = `&`, `&quot;` = `"`

Supports inline styles for color, font-size, etc:
```xml
<fieldText>&lt;p&gt;&lt;span style=&quot;color: rgb(194, 57, 52);&quot;&gt;&lt;b&gt;Error occurred&lt;/b&gt;&lt;/span&gt;&lt;/p&gt;</fieldText>
```

## LargeTextArea

Multi-line text input.

```xml
<fields>
    <name>Input_Description</name>
    <dataType>String</dataType>
    <fieldText>Description</fieldText>
    <fieldType>LargeTextArea</fieldType>
    <isRequired>false</isRequired>
    <storeOutputAutomatically>true</storeOutputAutomatically>
</fields>
```

## DropdownBox

Picklist/dropdown. Requires `choiceReferences` pointing to `<choices>` or `<dynamicChoiceSets>` elements.

```xml
<fields>
    <name>Select_Priority</name>
    <choiceReferences>Choice_High</choiceReferences>
    <choiceReferences>Choice_Medium</choiceReferences>
    <choiceReferences>Choice_Low</choiceReferences>
    <dataType>String</dataType>
    <fieldText>Priority</fieldText>
    <fieldType>DropdownBox</fieldType>
    <isRequired>true</isRequired>
    <storeOutputAutomatically>true</storeOutputAutomatically>
</fields>
```

With a dynamic choice set:
```xml
<fields>
    <name>Select_Account</name>
    <choiceReferences>AccountChoiceSet</choiceReferences>
    <dataType>String</dataType>
    <fieldText>Select Account</fieldText>
    <fieldType>DropdownBox</fieldType>
    <isRequired>true</isRequired>
    <storeOutputAutomatically>true</storeOutputAutomatically>
</fields>
```

## RadioButtons

Radio button group. Same structure as DropdownBox — uses `choiceReferences`.

```xml
<fields>
    <name>Select_Type</name>
    <choiceReferences>Choice_Individual</choiceReferences>
    <choiceReferences>Choice_Business</choiceReferences>
    <dataType>String</dataType>
    <fieldText>Account Type</fieldText>
    <fieldType>RadioButtons</fieldType>
    <isRequired>true</isRequired>
    <storeOutputAutomatically>true</storeOutputAutomatically>
</fields>
```

## MultiSelectCheckboxes

Multi-select checkboxes. Same structure — uses `choiceReferences`.

```xml
<fields>
    <name>Select_Industries</name>
    <choiceReferences>Choice_Technology</choiceReferences>
    <choiceReferences>Choice_Finance</choiceReferences>
    <choiceReferences>Choice_Healthcare</choiceReferences>
    <dataType>String</dataType>
    <fieldText>Industries</fieldText>
    <fieldType>MultiSelectCheckboxes</fieldType>
    <isRequired>false</isRequired>
    <storeOutputAutomatically>true</storeOutputAutomatically>
</fields>
```

## ComponentInstance

Embeds a Lightning Web Component or standard flow runtime component inside the screen.

**Standard flow runtime components** (provided by Salesforce):

| extensionName | Description |
|---|---|
| `flowruntime:datatable` | Interactive data table |
| `flowruntime:image` | Image display |
| `flowruntime:lookup` | Record lookup field |
| `flowruntime:fileUpload` | File upload |
| `flowruntime:dependentPicklists` | Dependent picklists |
| `flowruntime:slider` | Slider input |
| `flowruntime:toggle` | Toggle switch |
| `flowruntime:address` | Address input |
| `flowruntime:name` | Name input (first/last) |
| `flowruntime:phone` | Phone input |
| `flowruntime:email` | Email input |
| `flowruntime:url` | URL input |

**Custom LWC** — use `extensionName` with `c:componentName` format.

```xml
<!-- Standard datatable -->
<fields>
    <name>Account_Table</name>
    <dataTypeMappings>
        <typeName>T</typeName>
        <typeValue>Account</typeValue>
    </dataTypeMappings>
    <extensionName>flowruntime:datatable</extensionName>
    <fieldType>ComponentInstance</fieldType>
    <inputParameters>
        <name>label</name>
        <value>
            <stringValue>Accounts</stringValue>
        </value>
    </inputParameters>
    <inputParameters>
        <name>tableData</name>
        <value>
            <elementReference>Get_Accounts</elementReference>
        </value>
    </inputParameters>
    <inputParameters>
        <name>columns</name>
        <value>
            <stringValue>[{"fieldName":"Name","label":"Name","type":"text"},{"fieldName":"Industry","label":"Industry","type":"text"}]</stringValue>
        </value>
    </inputParameters>
    <inputsOnNextNavToAssocScrn>UseStoredValues</inputsOnNextNavToAssocScrn>
    <isRequired>true</isRequired>
    <storeOutputAutomatically>true</storeOutputAutomatically>
</fields>

<!-- Lookup component -->
<fields>
    <name>Account_Lookup</name>
    <extensionName>flowruntime:lookup</extensionName>
    <fieldType>ComponentInstance</fieldType>
    <inputParameters>
        <name>fieldApiName</name>
        <value>
            <stringValue>AccountId</stringValue>
        </value>
    </inputParameters>
    <inputParameters>
        <name>label</name>
        <value>
            <stringValue>Account</stringValue>
        </value>
    </inputParameters>
    <inputParameters>
        <name>objectApiName</name>
        <value>
            <stringValue>Contact</stringValue>
        </value>
    </inputParameters>
    <isRequired>true</isRequired>
    <storeOutputAutomatically>true</storeOutputAutomatically>
</fields>

<!-- Custom LWC in a flow screen -->
<fields>
    <name>Custom_Component</name>
    <extensionName>c:myFlowComponent</extensionName>
    <fieldType>ComponentInstance</fieldType>
    <inputParameters>
        <name>recordId</name>
        <value>
            <elementReference>var_RecordId</elementReference>
        </value>
    </inputParameters>
    <outputParameters>
        <assignToReference>var_Result</assignToReference>
        <name>result</name>
    </outputParameters>
    <storeOutputAutomatically>true</storeOutputAutomatically>
</fields>
```

**Docs**: https://developer.salesforce.com/docs/platform/lwc/guide/use-config-for-flow-screens.html

## RegionContainer (Sections)

Creates multi-column layouts on a screen. Contains `Region` children for each column.

```xml
<!-- Two-column section -->
<fields>
    <name>Account_Details_Section</name>
    <fieldType>RegionContainer</fieldType>
    <fields>
        <name>Left_Column</name>
        <fieldType>Region</fieldType>
        <fields>
            <name>Input_Name</name>
            <dataType>String</dataType>
            <fieldText>Name</fieldText>
            <fieldType>InputField</fieldType>
            <isRequired>true</isRequired>
            <storeOutputAutomatically>true</storeOutputAutomatically>
        </fields>
        <inputParameters>
            <name>width</name>
            <value>
                <stringValue>6</stringValue>
            </value>
        </inputParameters>
        <isRequired>false</isRequired>
    </fields>
    <fields>
        <name>Right_Column</name>
        <fieldType>Region</fieldType>
        <fields>
            <name>Input_Phone</name>
            <dataType>String</dataType>
            <fieldText>Phone</fieldText>
            <fieldType>InputField</fieldType>
            <isRequired>false</isRequired>
            <storeOutputAutomatically>true</storeOutputAutomatically>
        </fields>
        <inputParameters>
            <name>width</name>
            <value>
                <stringValue>6</stringValue>
            </value>
        </inputParameters>
        <isRequired>false</isRequired>
    </fields>
    <isRequired>false</isRequired>
    <regionContainerType>SectionWithoutHeader</regionContainerType>
</fields>
```

- `regionContainerType`: `SectionWithHeader` or `SectionWithoutHeader`
- Region `width` values are out of 12 (grid system): `6` = half, `4` = third, `12` = full

## Repeater

Repeatable section that lets users add multiple rows of inputs dynamically.

```xml
<fields>
    <name>Contact_Repeater</name>
    <fieldType>Repeater</fieldType>
    <fields>
        <name>Contact_FirstName</name>
        <dataType>String</dataType>
        <fieldText>First Name</fieldText>
        <fieldType>InputField</fieldType>
        <isRequired>true</isRequired>
    </fields>
    <fields>
        <name>Contact_LastName</name>
        <dataType>String</dataType>
        <fieldText>Last Name</fieldText>
        <fieldType>InputField</fieldType>
        <isRequired>true</isRequired>
    </fields>
    <isRequired>false</isRequired>
</fields>
```

## ObjectProvided

Renders a field directly from a record variable's object definition.

```xml
<fields>
    <name>Account_Industry</name>
    <dataType>String</dataType>
    <fieldText>Industry</fieldText>
    <fieldType>ObjectProvided</fieldType>
    <objectFieldReference>recAccount.Industry</objectFieldReference>
    <storeOutputAutomatically>true</storeOutputAutomatically>
</fields>
```

## PasswordField

Password input (masked).

```xml
<fields>
    <name>Input_Password</name>
    <dataType>String</dataType>
    <fieldText>Password</fieldText>
    <fieldType>PasswordField</fieldType>
    <isRequired>true</isRequired>
    <storeOutputAutomatically>true</storeOutputAutomatically>
</fields>
```

## Common FlowScreenField Properties

These properties apply across field types:

| Property | Type | Description |
|---|---|---|
| `name` | String | API name (required) |
| `fieldType` | Enum | Field type (required) |
| `fieldText` | String | Label or HTML content |
| `dataType` | Enum | Data type (for input fields) |
| `isRequired` | Boolean | Required field |
| `helpText` | String | Inline help text |
| `defaultValue` | Value | Default value |
| `validationRule` | Object | Validation with `formulaExpression` and `errorMessage` |
| `choiceReferences` | String[] | References to choices/dynamic choice sets |
| `extensionName` | String | Component name (for ComponentInstance) |
| `inputParameters` | Object[] | Input params (for ComponentInstance, Region) |
| `outputParameters` | Object[] | Output params (for ComponentInstance) |
| `dataTypeMappings` | Object[] | Generic type mappings (for ComponentInstance) |
| `storeOutputAutomatically` | Boolean | Auto-store user input |
| `inputsOnNextNavToAssocScrn` | String | `UseStoredValues` to retain values on back navigation |
| `scale` | int | Decimal places (for Number/Currency) |
| `regionContainerType` | String | Section type (for RegionContainer) |
| `objectFieldReference` | String | Object field path (for ObjectProvided) |
