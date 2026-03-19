# Flow Element Patterns

XML patterns for all non-screen flow elements: decisions, assignments, loops, data operations, actions, formulas, choices, subflows, and text templates.

## Decisions

Route the flow based on conditions. Each decision has one or more `rules` (outcomes) and a `defaultConnector` for the else path.

```xml
<decisions>
    <name>Check_Account_Type</name>
    <label>Check Account Type</label>
    <locationX>182</locationX>
    <locationY>400</locationY>
    <defaultConnector>
        <targetReference>Handle_Other</targetReference>
    </defaultConnector>
    <defaultConnectorLabel>Other</defaultConnectorLabel>
    <rules>
        <name>Is_Enterprise</name>
        <label>Enterprise</label>
        <conditionLogic>and</conditionLogic>
        <conditions>
            <leftValueReference>Input_AccountType</leftValueReference>
            <operator>EqualTo</operator>
            <rightValue>
                <stringValue>Enterprise</stringValue>
            </rightValue>
        </conditions>
        <connector>
            <targetReference>Process_Enterprise</targetReference>
        </connector>
    </rules>
    <rules>
        <name>Is_SMB</name>
        <label>SMB</label>
        <conditionLogic>and</conditionLogic>
        <conditions>
            <leftValueReference>Input_AccountType</leftValueReference>
            <operator>EqualTo</operator>
            <rightValue>
                <stringValue>SMB</stringValue>
            </rightValue>
        </conditions>
        <connector>
            <targetReference>Process_SMB</targetReference>
        </connector>
    </rules>
</decisions>
```

**Multiple conditions with custom logic:**

```xml
<rules>
    <name>High_Value_Enterprise</name>
    <label>High Value Enterprise</label>
    <conditionLogic>1 AND (2 OR 3)</conditionLogic>
    <conditions>
        <leftValueReference>Input_AccountType</leftValueReference>
        <operator>EqualTo</operator>
        <rightValue>
            <stringValue>Enterprise</stringValue>
        </rightValue>
    </conditions>
    <conditions>
        <leftValueReference>Input_AnnualRevenue</leftValueReference>
        <operator>GreaterThan</operator>
        <rightValue>
            <numberValue>1000000.0</numberValue>
        </rightValue>
    </conditions>
    <conditions>
        <leftValueReference>Input_EmployeeCount</leftValueReference>
        <operator>GreaterThan</operator>
        <rightValue>
            <numberValue>500.0</numberValue>
        </rightValue>
    </conditions>
    <connector>
        <targetReference>VIP_Path</targetReference>
    </connector>
</rules>
```

`conditionLogic` values: `and`, `or`, or custom like `1 AND (2 OR 3)`.

## Assignments

Set variable values, build collections, and perform calculations.

```xml
<!-- Simple assignment -->
<assignments>
    <name>Store_Account_ID</name>
    <label>Store Account ID</label>
    <locationX>176</locationX>
    <locationY>398</locationY>
    <assignmentItems>
        <assignToReference>varAccountId</assignToReference>
        <operator>Assign</operator>
        <value>
            <elementReference>Create_Account</elementReference>
        </value>
    </assignmentItems>
    <connector>
        <targetReference>Next_Element</targetReference>
    </connector>
</assignments>

<!-- Multiple assignments in one element -->
<assignments>
    <name>Initialize_Variables</name>
    <label>Initialize Variables</label>
    <locationX>176</locationX>
    <locationY>200</locationY>
    <assignmentItems>
        <assignToReference>varCounter</assignToReference>
        <operator>Assign</operator>
        <value>
            <numberValue>0.0</numberValue>
        </value>
    </assignmentItems>
    <assignmentItems>
        <assignToReference>varIsProcessed</assignToReference>
        <operator>Assign</operator>
        <value>
            <booleanValue>false</booleanValue>
        </value>
    </assignmentItems>
    <connector>
        <targetReference>Next_Element</targetReference>
    </connector>
</assignments>

<!-- Add item to collection -->
<assignments>
    <name>Add_To_Collection</name>
    <label>Add Contact to List</label>
    <locationX>300</locationX>
    <locationY>500</locationY>
    <assignmentItems>
        <assignToReference>colContacts</assignToReference>
        <operator>Add</operator>
        <value>
            <elementReference>Loop_Current_Contact</elementReference>
        </value>
    </assignmentItems>
    <connector>
        <targetReference>Loop_Contacts</targetReference>
    </connector>
</assignments>

<!-- Count collection -->
<assignments>
    <name>Count_Records</name>
    <label>Count Records</label>
    <locationX>300</locationX>
    <locationY>600</locationY>
    <assignmentItems>
        <assignToReference>varRecordCount</assignToReference>
        <operator>AssignCount</operator>
        <value>
            <elementReference>Get_Records</elementReference>
        </value>
    </assignmentItems>
    <connector>
        <targetReference>Next_Element</targetReference>
    </connector>
</assignments>
```

## Record Lookups (Get Records)

Query Salesforce records.

```xml
<!-- Get multiple records -->
<recordLookups>
    <name>Get_Contacts</name>
    <label>Get Contacts</label>
    <locationX>182</locationX>
    <locationY>323</locationY>
    <assignNullValuesIfNoRecordsFound>false</assignNullValuesIfNoRecordsFound>
    <connector>
        <targetReference>Display_Results</targetReference>
    </connector>
    <faultConnector>
        <targetReference>Error_Screen</targetReference>
    </faultConnector>
    <filterLogic>and</filterLogic>
    <filters>
        <field>AccountId</field>
        <operator>EqualTo</operator>
        <value>
            <elementReference>var_AccountId</elementReference>
        </value>
    </filters>
    <getFirstRecordOnly>false</getFirstRecordOnly>
    <object>Contact</object>
    <queriedFields>Id</queriedFields>
    <queriedFields>FirstName</queriedFields>
    <queriedFields>LastName</queriedFields>
    <queriedFields>Email</queriedFields>
    <sortField>LastName</sortField>
    <sortOrder>Asc</sortOrder>
    <storeOutputAutomatically>true</storeOutputAutomatically>
</recordLookups>

<!-- Get single record -->
<recordLookups>
    <name>Get_Account</name>
    <label>Get Account</label>
    <locationX>182</locationX>
    <locationY>200</locationY>
    <assignNullValuesIfNoRecordsFound>true</assignNullValuesIfNoRecordsFound>
    <connector>
        <targetReference>Check_Account_Found</targetReference>
    </connector>
    <faultConnector>
        <targetReference>Error_Screen</targetReference>
    </faultConnector>
    <filterLogic>and</filterLogic>
    <filters>
        <field>Id</field>
        <operator>EqualTo</operator>
        <value>
            <elementReference>var_RecordId</elementReference>
        </value>
    </filters>
    <getFirstRecordOnly>true</getFirstRecordOnly>
    <object>Account</object>
    <queriedFields>Id</queriedFields>
    <queriedFields>Name</queriedFields>
    <queriedFields>Industry</queriedFields>
    <storeOutputAutomatically>true</storeOutputAutomatically>
</recordLookups>
```

Key fields:
- `getFirstRecordOnly` — `true` returns single record, `false` returns collection
- `storeOutputAutomatically` — `true` auto-creates output variable (recommended)
- `assignNullValuesIfNoRecordsFound` — `true` clears variable if no results
- `queriedFields` — one element per field; always include `Id`
- `sortField` / `sortOrder` — optional sorting
- `filterLogic` + `filters` — query conditions (same structure as Decision conditions)
- `faultConnector` — always include for error handling

## Record Creates

Insert new records.

```xml
<!-- Using field assignments -->
<recordCreates>
    <name>Create_Account</name>
    <label>Create Account</label>
    <locationX>176</locationX>
    <locationY>278</locationY>
    <connector>
        <targetReference>Store_Account_ID</targetReference>
    </connector>
    <faultConnector>
        <targetReference>Error_Screen</targetReference>
    </faultConnector>
    <inputAssignments>
        <field>Name</field>
        <value>
            <elementReference>Input_AccountName</elementReference>
        </value>
    </inputAssignments>
    <inputAssignments>
        <field>Industry</field>
        <value>
            <elementReference>Input_Industry</elementReference>
        </value>
    </inputAssignments>
    <object>Account</object>
    <storeOutputAutomatically>true</storeOutputAutomatically>
</recordCreates>

<!-- Using a record variable -->
<recordCreates>
    <name>Create_Contact</name>
    <label>Create Contact</label>
    <locationX>176</locationX>
    <locationY>400</locationY>
    <connector>
        <targetReference>Success_Screen</targetReference>
    </connector>
    <faultConnector>
        <targetReference>Error_Screen</targetReference>
    </faultConnector>
    <inputReference>recNewContact</inputReference>
</recordCreates>
```

Two modes:
1. **Field assignments** — `inputAssignments` with `field` + `value` pairs, plus `object` name
2. **Record variable** — `inputReference` pointing to an SObject variable

## Record Updates

Update existing records.

```xml
<!-- Update by filters -->
<recordUpdates>
    <name>Update_Account_Status</name>
    <label>Update Account Status</label>
    <locationX>182</locationX>
    <locationY>500</locationY>
    <connector>
        <targetReference>Success_Screen</targetReference>
    </connector>
    <faultConnector>
        <targetReference>Error_Screen</targetReference>
    </faultConnector>
    <filterLogic>and</filterLogic>
    <filters>
        <field>Id</field>
        <operator>EqualTo</operator>
        <value>
            <elementReference>var_AccountId</elementReference>
        </value>
    </filters>
    <inputAssignments>
        <field>Status__c</field>
        <value>
            <stringValue>Active</stringValue>
        </value>
    </inputAssignments>
    <object>Account</object>
</recordUpdates>

<!-- Update using record variable -->
<recordUpdates>
    <name>Update_Contact</name>
    <label>Update Contact</label>
    <locationX>182</locationX>
    <locationY>600</locationY>
    <connector>
        <targetReference>Next_Element</targetReference>
    </connector>
    <faultConnector>
        <targetReference>Error_Screen</targetReference>
    </faultConnector>
    <inputReference>recContact</inputReference>
</recordUpdates>
```

## Record Deletes

Delete records.

```xml
<!-- Delete by filter -->
<recordDeletes>
    <name>Delete_Old_Records</name>
    <label>Delete Old Records</label>
    <locationX>440</locationX>
    <locationY>518</locationY>
    <connector>
        <targetReference>Next_Element</targetReference>
    </connector>
    <faultConnector>
        <targetReference>Error_Screen</targetReference>
    </faultConnector>
    <filterLogic>and</filterLogic>
    <filters>
        <field>CreatedDate</field>
        <operator>LessThan</operator>
        <value>
            <elementReference>var_CutoffDate</elementReference>
        </value>
    </filters>
    <object>Task</object>
</recordDeletes>

<!-- Delete by reference (record or ID variable) -->
<recordDeletes>
    <name>Delete_Account_on_Error</name>
    <label>Delete Account on Error</label>
    <locationX>440</locationX>
    <locationY>518</locationY>
    <connector>
        <targetReference>Error_Screen</targetReference>
    </connector>
    <inputReference>varCreatedAccountId</inputReference>
</recordDeletes>
```

## Loops

Iterate over a collection.

```xml
<loops>
    <name>Loop_Contacts</name>
    <label>Loop Over Contacts</label>
    <locationX>50</locationX>
    <locationY>400</locationY>
    <collectionReference>Get_Contacts</collectionReference>
    <iterationOrder>Asc</iterationOrder>
    <nextValueConnector>
        <targetReference>Process_Contact</targetReference>
    </nextValueConnector>
    <noMoreValuesConnector>
        <targetReference>After_Loop</targetReference>
    </noMoreValuesConnector>
</loops>
```

- `collectionReference` — the collection variable or auto-stored output to iterate
- `iterationOrder` — `Asc` or `Desc`
- `nextValueConnector` — path executed for each item (loop body)
- `noMoreValuesConnector` — path after all items are processed
- The current item is accessed via `{!Loop_Contacts}` in the flow

## Action Calls

Invoke Apex invocable actions, standard actions, email alerts, etc.

```xml
<!-- Apex invocable action -->
<actionCalls>
    <name>Process_Records</name>
    <label>Process Records via Apex</label>
    <locationX>176</locationX>
    <locationY>638</locationY>
    <actionName>ProcessRecordAction</actionName>
    <actionType>apex</actionType>
    <flowTransactionModel>CurrentTransaction</flowTransactionModel>
    <connector>
        <targetReference>Success_Screen</targetReference>
    </connector>
    <faultConnector>
        <targetReference>Error_Screen</targetReference>
    </faultConnector>
    <inputParameters>
        <name>recordIds</name>
        <value>
            <elementReference>var_SelectedIds</elementReference>
        </value>
    </inputParameters>
    <outputParameters>
        <assignToReference>var_IsSuccess</assignToReference>
        <name>isSuccess</name>
    </outputParameters>
    <storeOutputAutomatically>true</storeOutputAutomatically>
</actionCalls>

<!-- Lightning navigation action -->
<actionCalls>
    <name>Navigate_to_Record</name>
    <label>Navigate to Record</label>
    <locationX>176</locationX>
    <locationY>800</locationY>
    <actionName>lightning:navigation</actionName>
    <actionType>standardAction</actionType>
    <flowTransactionModel>CurrentTransaction</flowTransactionModel>
    <inputParameters>
        <name>type</name>
        <value>
            <stringValue>standard__recordPage</stringValue>
        </value>
    </inputParameters>
    <inputParameters>
        <name>attributes</name>
        <value>
            <stringValue>{"recordId":"{!varRecordId}"}</stringValue>
        </value>
    </inputParameters>
    <storeOutputAutomatically>true</storeOutputAutomatically>
</actionCalls>

<!-- Send email -->
<actionCalls>
    <name>Send_Notification</name>
    <label>Send Email Notification</label>
    <locationX>176</locationX>
    <locationY>500</locationY>
    <actionName>emailSimple</actionName>
    <actionType>emailSimple</actionType>
    <flowTransactionModel>CurrentTransaction</flowTransactionModel>
    <connector>
        <targetReference>Next_Element</targetReference>
    </connector>
    <inputParameters>
        <name>emailAddresses</name>
        <value>
            <elementReference>var_Email</elementReference>
        </value>
    </inputParameters>
    <inputParameters>
        <name>emailSubject</name>
        <value>
            <stringValue>Record Created Successfully</stringValue>
        </value>
    </inputParameters>
    <inputParameters>
        <name>emailBody</name>
        <value>
            <elementReference>Email_Body_Template</elementReference>
        </value>
    </inputParameters>
</actionCalls>
```

`actionType` values: `apex`, `standardAction`, `emailSimple`, `emailAlert`, `submit`, `flow`
`flowTransactionModel` values: `CurrentTransaction`, `Automatic`

## Subflows

Call another flow from within this flow.

```xml
<subflows>
    <name>Call_Validation_Flow</name>
    <label>Run Validation</label>
    <locationX>550</locationX>
    <locationY>300</locationY>
    <flowName>Validate_Account_Data</flowName>
    <connector>
        <targetReference>Check_Validation_Result</targetReference>
    </connector>
    <inputAssignments>
        <name>inputAccountId</name>
        <value>
            <elementReference>var_AccountId</elementReference>
        </value>
    </inputAssignments>
    <outputAssignments>
        <assignToReference>var_IsValid</assignToReference>
        <name>outputIsValid</name>
    </outputAssignments>
</subflows>
```

- `flowName` — API name of the child flow
- `inputAssignments` — map parent variables to child flow input variables
- `outputAssignments` — map child flow output variables back to parent variables

## Formulas

Calculate values using formula expressions. Referenced via `{!Formula_Name}`.

```xml
<formulas>
    <name>Full_Name</name>
    <dataType>String</dataType>
    <expression>{!Input_FirstName} &amp; &quot; &quot; &amp; {!Input_LastName}</expression>
</formulas>

<formulas>
    <name>Commission_Amount</name>
    <dataType>Number</dataType>
    <expression>IF({!Input_Amount} > 1000, {!Input_Amount} * 0.1, {!Input_Amount} * 0.05)</expression>
    <scale>2</scale>
</formulas>

<formulas>
    <name>Is_High_Priority</name>
    <dataType>Boolean</dataType>
    <expression>{!Input_Amount} > 50000 &amp;&amp; ISPICKVAL({!Input_Priority}, &quot;High&quot;)</expression>
</formulas>
```

Note: In XML, `&` = `&amp;`, `"` = `&quot;`, `<` = `&lt;`, `>` = `&gt;`.

## Choices (Static)

Define static options for DropdownBox, RadioButtons, and MultiSelectCheckboxes.

```xml
<choices>
    <name>Choice_High</name>
    <choiceText>High Priority</choiceText>
    <dataType>String</dataType>
    <value>
        <stringValue>High</stringValue>
    </value>
</choices>

<choices>
    <name>Choice_Medium</name>
    <choiceText>Medium Priority</choiceText>
    <dataType>String</dataType>
    <value>
        <stringValue>Medium</stringValue>
    </value>
</choices>

<choices>
    <name>Choice_Low</name>
    <choiceText>Low Priority</choiceText>
    <dataType>String</dataType>
    <value>
        <stringValue>Low</stringValue>
    </value>
</choices>
```

## Dynamic Choice Sets

Query records or picklist values at runtime to populate choice fields.

```xml
<!-- Record-based dynamic choices -->
<dynamicChoiceSets>
    <name>AccountChoiceSet</name>
    <dataType>String</dataType>
    <displayField>Name</displayField>
    <filterLogic>and</filterLogic>
    <filters>
        <field>IsDeleted</field>
        <operator>EqualTo</operator>
        <value>
            <booleanValue>false</booleanValue>
        </value>
    </filters>
    <object>Account</object>
    <outputAssignments>
        <assignToReference>var_SelectedAccountId</assignToReference>
        <field>Id</field>
    </outputAssignments>
    <sortField>Name</sortField>
    <sortOrder>Asc</sortOrder>
    <valueField>Id</valueField>
</dynamicChoiceSets>

<!-- Picklist-based dynamic choices -->
<dynamicChoiceSets>
    <name>IndustryPicklist</name>
    <dataType>Picklist</dataType>
    <displayField>Industry</displayField>
    <object>Account</object>
    <picklistField>Industry</picklistField>
    <picklistObject>Account</picklistObject>
</dynamicChoiceSets>
```

## Constants

Define constant values referenced as `{!CONSTANT_NAME}`.

```xml
<constants>
    <name>MAX_RECORDS</name>
    <dataType>Number</dataType>
    <value>
        <numberValue>200.0</numberValue>
    </value>
</constants>

<constants>
    <name>DEFAULT_STATUS</name>
    <dataType>String</dataType>
    <value>
        <stringValue>New</stringValue>
    </value>
</constants>
```

## Text Templates

Reusable text blocks, often used for email bodies or display text that includes merge fields.

```xml
<textTemplates>
    <name>Email_Body_Template</name>
    <isViewedAsPlainText>false</isViewedAsPlainText>
    <text>&lt;p&gt;Dear {!var_ContactName},&lt;/p&gt;&lt;p&gt;Your account &lt;b&gt;{!var_AccountName}&lt;/b&gt; has been created.&lt;/p&gt;</text>
</textTemplates>

<textTemplates>
    <name>Plain_Text_Message</name>
    <isViewedAsPlainText>true</isViewedAsPlainText>
    <text>Record {!var_RecordName} was processed successfully on {!$Flow.CurrentDate}.</text>
</textTemplates>
```

## Variables

Declare flow variables for storing data throughout the flow.

```xml
<!-- Simple string variable -->
<variables>
    <name>varAccountId</name>
    <dataType>String</dataType>
    <isCollection>false</isCollection>
    <isInput>false</isInput>
    <isOutput>false</isOutput>
</variables>

<!-- Input/Output variable (available to calling flows or embedding pages) -->
<variables>
    <name>recordId</name>
    <dataType>String</dataType>
    <isCollection>false</isCollection>
    <isInput>true</isInput>
    <isOutput>false</isOutput>
</variables>

<!-- SObject variable -->
<variables>
    <name>recAccount</name>
    <dataType>SObject</dataType>
    <isCollection>false</isCollection>
    <isInput>false</isInput>
    <isOutput>false</isOutput>
    <objectType>Account</objectType>
</variables>

<!-- Collection variable -->
<variables>
    <name>colSelectedIds</name>
    <dataType>String</dataType>
    <isCollection>true</isCollection>
    <isInput>false</isInput>
    <isOutput>false</isOutput>
</variables>

<!-- SObject collection variable -->
<variables>
    <name>colContacts</name>
    <dataType>SObject</dataType>
    <isCollection>true</isCollection>
    <isInput>false</isInput>
    <isOutput>false</isOutput>
    <objectType>Contact</objectType>
</variables>

<!-- Variable with default value -->
<variables>
    <name>varStatus</name>
    <dataType>String</dataType>
    <isCollection>false</isCollection>
    <isInput>false</isInput>
    <isOutput>false</isOutput>
    <value>
        <stringValue>New</stringValue>
    </value>
</variables>

<!-- Apex-defined variable -->
<variables>
    <name>lstWrapperData</name>
    <apexClass>MyDataWrapper</apexClass>
    <dataType>Apex</dataType>
    <isCollection>true</isCollection>
    <isInput>false</isInput>
    <isOutput>false</isOutput>
</variables>
```
