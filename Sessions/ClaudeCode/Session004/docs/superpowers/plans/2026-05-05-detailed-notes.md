# Detailed Notes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a split-panel Lightning Web Component that lets team members write rich-text notes on Account, Case, and Opportunity pages, stored in a custom Salesforce object with creator-only edit/delete and an admin override permission.

**Architecture:** A single `detailedNotes` LWC receives `recordId` and `objectApiName` from the page context and calls an Apex controller (`DetailedNoteController`) for all data operations. Notes are stored in `DetailedNote__c` with three optional lookup fields (one per supported object); Account pages perform a rollup query that also returns related Case and Opportunity notes. Edit/delete authorization is enforced server-side via a `CreatedById` check and the `Edit_All_Detailed_Notes` custom permission.

**Tech Stack:** Salesforce DX (API 66.0), Apex, Lightning Web Components, `lightning-input-rich-text`, `lightning-formatted-rich-text`, `@salesforce/sfdx-lwc-jest` v7, `@salesforce/wire-service-jest-util`

---

## File Map

| File | Purpose |
|---|---|
| `force-app/main/default/objects/DetailedNote__c/DetailedNote__c.object-meta.xml` | Object definition (OWD = Public Read) |
| `force-app/main/default/objects/DetailedNote__c/fields/Title__c.field-meta.xml` | Text(100), required |
| `force-app/main/default/objects/DetailedNote__c/fields/Body__c.field-meta.xml` | Rich Text Area, required |
| `force-app/main/default/objects/DetailedNote__c/fields/Account__c.field-meta.xml` | Lookup to Account |
| `force-app/main/default/objects/DetailedNote__c/fields/Case__c.field-meta.xml` | Lookup to Case |
| `force-app/main/default/objects/DetailedNote__c/fields/Opportunity__c.field-meta.xml` | Lookup to Opportunity |
| `force-app/main/default/customPermissions/Edit_All_Detailed_Notes.customPermission-meta.xml` | Override permission for admins |
| `force-app/main/default/permissionsets/DetailedNotes_User.permissionset-meta.xml` | Base permission set for all users |
| `force-app/main/default/classes/DetailedNoteController.cls` | All Apex data operations |
| `force-app/main/default/classes/DetailedNoteController.cls-meta.xml` | Apex metadata |
| `force-app/main/default/classes/DetailedNoteControllerTest.cls` | All Apex unit tests |
| `force-app/main/default/classes/DetailedNoteControllerTest.cls-meta.xml` | Test class metadata |
| `force-app/main/default/lwc/detailedNotes/detailedNotes.html` | LWC template |
| `force-app/main/default/lwc/detailedNotes/detailedNotes.js` | LWC controller |
| `force-app/main/default/lwc/detailedNotes/detailedNotes.css` | LWC styles |
| `force-app/main/default/lwc/detailedNotes/detailedNotes.js-meta.xml` | LWC metadata (targets) |
| `force-app/main/default/lwc/detailedNotes/__tests__/detailedNotes.test.js` | All LWC Jest tests |

---

## Task 1: Custom Object and Field Metadata

**Files:**
- Create: `force-app/main/default/objects/DetailedNote__c/DetailedNote__c.object-meta.xml`
- Create: `force-app/main/default/objects/DetailedNote__c/fields/Title__c.field-meta.xml`
- Create: `force-app/main/default/objects/DetailedNote__c/fields/Body__c.field-meta.xml`
- Create: `force-app/main/default/objects/DetailedNote__c/fields/Account__c.field-meta.xml`
- Create: `force-app/main/default/objects/DetailedNote__c/fields/Case__c.field-meta.xml`
- Create: `force-app/main/default/objects/DetailedNote__c/fields/Opportunity__c.field-meta.xml`

- [ ] **Step 1: Create the object directory structure**

```bash
mkdir -p force-app/main/default/objects/DetailedNote__c/fields
```

- [ ] **Step 2: Create the object definition**

File: `force-app/main/default/objects/DetailedNote__c/DetailedNote__c.object-meta.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <deploymentStatus>Deployed</deploymentStatus>
    <label>Detailed Note</label>
    <pluralLabel>Detailed Notes</pluralLabel>
    <nameField>
        <displayFormat>DN-{0000}</displayFormat>
        <label>Detailed Note Name</label>
        <type>AutoNumber</type>
    </nameField>
    <sharingModel>Read</sharingModel>
</CustomObject>
```

`sharingModel>Read` sets OWD to Public Read Only.

- [ ] **Step 3: Create the Title field**

File: `force-app/main/default/objects/DetailedNote__c/fields/Title__c.field-meta.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Title__c</fullName>
    <label>Title</label>
    <length>100</length>
    <required>true</required>
    <type>Text</type>
    <unique>false</unique>
</CustomField>
```

- [ ] **Step 4: Create the Body field**

File: `force-app/main/default/objects/DetailedNote__c/fields/Body__c.field-meta.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Body__c</fullName>
    <label>Body</label>
    <length>32768</length>
    <required>true</required>
    <type>Html</type>
</CustomField>
```

`type>Html` is the Salesforce metadata type for Rich Text Area.

- [ ] **Step 5: Create the Account lookup**

File: `force-app/main/default/objects/DetailedNote__c/fields/Account__c.field-meta.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Account__c</fullName>
    <label>Account</label>
    <referenceTo>Account</referenceTo>
    <relationshipLabel>Detailed Notes</relationshipLabel>
    <relationshipName>DetailedNotes</relationshipName>
    <required>false</required>
    <type>Lookup</type>
</CustomField>
```

- [ ] **Step 6: Create the Case lookup**

File: `force-app/main/default/objects/DetailedNote__c/fields/Case__c.field-meta.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Case__c</fullName>
    <label>Case</label>
    <referenceTo>Case</referenceTo>
    <relationshipLabel>Detailed Notes</relationshipLabel>
    <relationshipName>DetailedNotes</relationshipName>
    <required>false</required>
    <type>Lookup</type>
</CustomField>
```

- [ ] **Step 7: Create the Opportunity lookup**

File: `force-app/main/default/objects/DetailedNote__c/fields/Opportunity__c.field-meta.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Opportunity__c</fullName>
    <label>Opportunity</label>
    <referenceTo>Opportunity</referenceTo>
    <relationshipLabel>Detailed Notes</relationshipLabel>
    <relationshipName>DetailedNotes</relationshipName>
    <required>false</required>
    <type>Lookup</type>
</CustomField>
```

- [ ] **Step 8: Commit**

```bash
git add force-app/main/default/objects/
git commit -m "feat: add DetailedNote__c custom object and fields"
```

---

## Task 2: Custom Permission and Permission Set

**Files:**
- Create: `force-app/main/default/customPermissions/Edit_All_Detailed_Notes.customPermission-meta.xml`
- Create: `force-app/main/default/permissionsets/DetailedNotes_User.permissionset-meta.xml`

- [ ] **Step 1: Create the custom permission directory and file**

```bash
mkdir -p force-app/main/default/customPermissions
```

File: `force-app/main/default/customPermissions/Edit_All_Detailed_Notes.customPermission-meta.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomPermission xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Edit All Detailed Notes</label>
</CustomPermission>
```

- [ ] **Step 2: Create the permission set directory and file**

```bash
mkdir -p force-app/main/default/permissionsets
```

File: `force-app/main/default/permissionsets/DetailedNotes_User.permissionset-meta.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>DetailedNotes User</label>
    <objectPermissions>
        <allowCreate>true</allowCreate>
        <allowDelete>false</allowDelete>
        <allowEdit>false</allowEdit>
        <allowRead>true</allowRead>
        <modifyAllRecords>false</modifyAllRecords>
        <object>DetailedNote__c</object>
        <viewAllRecords>false</viewAllRecords>
    </objectPermissions>
    <fieldPermissions>
        <editable>true</editable>
        <field>DetailedNote__c.Title__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>true</editable>
        <field>DetailedNote__c.Body__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>true</editable>
        <field>DetailedNote__c.Account__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>true</editable>
        <field>DetailedNote__c.Case__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>true</editable>
        <field>DetailedNote__c.Opportunity__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <userLicense>Salesforce</userLicense>
</PermissionSet>
```

Note: `allowDelete` and `allowEdit` are `false` because all DML goes through the Apex controller (which runs `without sharing` for write operations). The `Edit_All_Detailed_Notes` custom permission is assigned separately to admins via their own permission set or directly in Setup.

- [ ] **Step 3: Commit**

```bash
git add force-app/main/default/customPermissions/ force-app/main/default/permissionsets/
git commit -m "feat: add Edit_All_Detailed_Notes custom permission and DetailedNotes_User permission set"
```

---

## Task 3: Apex Controller — NoteWrapper + getNotes (Case and Opportunity)

**Files:**
- Create: `force-app/main/default/classes/DetailedNoteController.cls`
- Create: `force-app/main/default/classes/DetailedNoteController.cls-meta.xml`
- Create: `force-app/main/default/classes/DetailedNoteControllerTest.cls`
- Create: `force-app/main/default/classes/DetailedNoteControllerTest.cls-meta.xml`

- [ ] **Step 1: Create Apex class metadata files**

File: `force-app/main/default/classes/DetailedNoteController.cls-meta.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>66.0</apiVersion>
    <status>Active</status>
</ApexClass>
```

File: `force-app/main/default/classes/DetailedNoteControllerTest.cls-meta.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>66.0</apiVersion>
    <status>Active</status>
</ApexClass>
```

- [ ] **Step 2: Write failing tests for getNotes (Case and Opportunity)**

File: `force-app/main/default/classes/DetailedNoteControllerTest.cls`

```apex
@IsTest
private class DetailedNoteControllerTest {

    @TestSetup
    static void makeData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Case c = new Case(Subject = 'Test Case', AccountId = acc.Id);
        insert c;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        List<DetailedNote__c> notes = new List<DetailedNote__c>{
            new DetailedNote__c(Title__c = 'Case Note', Body__c = '<p>case body</p>', Case__c = c.Id),
            new DetailedNote__c(Title__c = 'Opp Note', Body__c = '<p>opp body</p>', Opportunity__c = opp.Id),
            new DetailedNote__c(Title__c = 'Account Note', Body__c = '<p>acc body</p>', Account__c = acc.Id)
        };
        insert notes;
    }

    @IsTest
    static void getNotes_case_returnsOnlyCaseNotes() {
        Case c = [SELECT Id FROM Case LIMIT 1];

        Test.startTest();
        List<DetailedNoteController.NoteWrapper> result =
            DetailedNoteController.getNotes(c.Id, 'Case');
        Test.stopTest();

        Assert.areEqual(1, result.size(), 'Should return 1 case note');
        Assert.areEqual('Case Note', result[0].title);
        Assert.isNull(result[0].sourceLabel, 'Case notes have no source label');
    }

    @IsTest
    static void getNotes_opportunity_returnsOnlyOppNotes() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<DetailedNoteController.NoteWrapper> result =
            DetailedNoteController.getNotes(opp.Id, 'Opportunity');
        Test.stopTest();

        Assert.areEqual(1, result.size(), 'Should return 1 opportunity note');
        Assert.areEqual('Opp Note', result[0].title);
        Assert.isNull(result[0].sourceLabel, 'Opportunity notes have no source label');
    }
}
```

- [ ] **Step 3: Create the controller shell and NoteWrapper**

File: `force-app/main/default/classes/DetailedNoteController.cls`

```apex
public with sharing class DetailedNoteController {

    public class NoteWrapper implements Comparable {
        @AuraEnabled public String id;
        @AuraEnabled public String title;
        @AuraEnabled public String body;
        @AuraEnabled public String createdByName;
        @AuraEnabled public String createdById;
        @AuraEnabled public DateTime createdDate;
        @AuraEnabled public Boolean canEdit;
        @AuraEnabled public String sourceLabel;

        public Integer compareTo(Object other) {
            NoteWrapper o = (NoteWrapper) other;
            if (createdDate == o.createdDate) return 0;
            return createdDate > o.createdDate ? -1 : 1;
        }
    }

    private static NoteWrapper toWrapper(
        DetailedNote__c n,
        String sourceLabelValue,
        Boolean hasOverride,
        String currentUserId
    ) {
        NoteWrapper w = new NoteWrapper();
        w.id = n.Id;
        w.title = n.Title__c;
        w.body = n.Body__c;
        w.createdByName = n.CreatedBy.Name;
        w.createdById = n.CreatedById;
        w.createdDate = n.CreatedDate;
        w.canEdit = hasOverride || n.CreatedById == currentUserId;
        w.sourceLabel = sourceLabelValue;
        return w;
    }

    @AuraEnabled(cacheable=true)
    public static List<NoteWrapper> getNotes(String recordId, String objectApiName) {
        Boolean hasOverride = FeatureManagement.checkPermission('Edit_All_Detailed_Notes');
        String currentUserId = UserInfo.getUserId();
        List<NoteWrapper> wrappers = new List<NoteWrapper>();

        if (objectApiName == 'Case') {
            for (DetailedNote__c n : [
                SELECT Id, Title__c, Body__c, CreatedById, CreatedBy.Name, CreatedDate
                FROM DetailedNote__c
                WHERE Case__c = :recordId
                ORDER BY CreatedDate DESC
            ]) {
                wrappers.add(toWrapper(n, null, hasOverride, currentUserId));
            }
        } else if (objectApiName == 'Opportunity') {
            for (DetailedNote__c n : [
                SELECT Id, Title__c, Body__c, CreatedById, CreatedBy.Name, CreatedDate
                FROM DetailedNote__c
                WHERE Opportunity__c = :recordId
                ORDER BY CreatedDate DESC
            ]) {
                wrappers.add(toWrapper(n, null, hasOverride, currentUserId));
            }
        } else if (objectApiName == 'Account') {
            // Account rollup — implemented in Task 4
        }

        return wrappers;
    }
}
```

- [ ] **Step 4: Deploy to scratch org and run Apex tests**

```bash
sf project deploy start
sf apex run test --class-names DetailedNoteControllerTest --result-format human --wait 5
```

Expected: 2 passing tests.

- [ ] **Step 5: Commit**

```bash
git add force-app/main/default/classes/
git commit -m "feat: add DetailedNoteController with NoteWrapper and getNotes for Case/Opportunity"
```

---

## Task 4: Apex Controller — getNotes Account Rollup

**Files:**
- Modify: `force-app/main/default/classes/DetailedNoteController.cls` (Account branch of `getNotes`)
- Modify: `force-app/main/default/classes/DetailedNoteControllerTest.cls` (add Account tests)

- [ ] **Step 1: Write failing tests for Account rollup**

Add to `DetailedNoteControllerTest.cls` inside the class body:

```apex
@IsTest
static void getNotes_account_returnsDirectAndRolledUpNotes() {
    Account acc = [SELECT Id FROM Account LIMIT 1];

    Test.startTest();
    List<DetailedNoteController.NoteWrapper> result =
        DetailedNoteController.getNotes(acc.Id, 'Account');
    Test.stopTest();

    Assert.areEqual(3, result.size(), 'Should return account note + case note + opp note');

    // Verify source labels are set on rolled-up notes
    Integer sourceLabelCount = 0;
    for (DetailedNoteController.NoteWrapper w : result) {
        if (w.sourceLabel != null) {
            sourceLabelCount++;
        }
    }
    Assert.areEqual(2, sourceLabelCount, 'Case and Opp notes should have source labels');
}

@IsTest
static void getNotes_account_sourceLabelContainsRecordName() {
    Account acc = [SELECT Id FROM Account LIMIT 1];

    Test.startTest();
    List<DetailedNoteController.NoteWrapper> result =
        DetailedNoteController.getNotes(acc.Id, 'Account');
    Test.stopTest();

    Boolean foundCaseLabel = false;
    Boolean foundOppLabel = false;
    for (DetailedNoteController.NoteWrapper w : result) {
        if (w.sourceLabel != null && w.sourceLabel.startsWith('Case:')) {
            foundCaseLabel = true;
        }
        if (w.sourceLabel != null && w.sourceLabel.startsWith('Opportunity:')) {
            foundOppLabel = true;
        }
    }
    Assert.isTrue(foundCaseLabel, 'Should have a Case source label');
    Assert.isTrue(foundOppLabel, 'Should have an Opportunity source label');
}
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
sf apex run test --class-names DetailedNoteControllerTest --result-format human --wait 5
```

Expected: `getNotes_account_returnsDirectAndRolledUpNotes` and `getNotes_account_sourceLabelContainsRecordName` FAIL.

- [ ] **Step 3: Implement the Account branch in getNotes**

Replace the `} else if (objectApiName == 'Account') {` block in `DetailedNoteController.cls`:

```apex
} else if (objectApiName == 'Account') {
    for (DetailedNote__c n : [
        SELECT Id, Title__c, Body__c, CreatedById, CreatedBy.Name, CreatedDate
        FROM DetailedNote__c
        WHERE Account__c = :recordId
    ]) {
        wrappers.add(toWrapper(n, null, hasOverride, currentUserId));
    }
    for (DetailedNote__c n : [
        SELECT Id, Title__c, Body__c, CreatedById, CreatedBy.Name, CreatedDate,
               Case__r.Subject
        FROM DetailedNote__c
        WHERE Case__r.AccountId = :recordId
    ]) {
        wrappers.add(toWrapper(n, 'Case: ' + n.Case__r.Subject, hasOverride, currentUserId));
    }
    for (DetailedNote__c n : [
        SELECT Id, Title__c, Body__c, CreatedById, CreatedBy.Name, CreatedDate,
               Opportunity__r.Name
        FROM DetailedNote__c
        WHERE Opportunity__r.AccountId = :recordId
    ]) {
        wrappers.add(toWrapper(n, 'Opportunity: ' + n.Opportunity__r.Name, hasOverride, currentUserId));
    }
    wrappers.sort();
}
```

- [ ] **Step 4: Deploy and run all tests**

```bash
sf project deploy start
sf apex run test --class-names DetailedNoteControllerTest --result-format human --wait 5
```

Expected: All 4 tests pass.

- [ ] **Step 5: Commit**

```bash
git add force-app/main/default/classes/
git commit -m "feat: implement getNotes Account rollup with source labels"
```

---

## Task 5: Apex Controller — saveNote

**Files:**
- Modify: `force-app/main/default/classes/DetailedNoteController.cls`
- Modify: `force-app/main/default/classes/DetailedNoteControllerTest.cls`

- [ ] **Step 1: Write failing test for saveNote**

Add to `DetailedNoteControllerTest.cls`:

```apex
@IsTest
static void saveNote_case_createsNoteWithCaseLookup() {
    Case c = [SELECT Id FROM Case LIMIT 1];

    Test.startTest();
    DetailedNoteController.saveNote('New Title', '<p>new body</p>', c.Id, 'Case');
    Test.stopTest();

    List<DetailedNote__c> notes = [
        SELECT Id, Title__c, Body__c, Case__c, Account__c, Opportunity__c
        FROM DetailedNote__c
        WHERE Title__c = 'New Title'
    ];
    Assert.areEqual(1, notes.size(), 'Should have created one note');
    Assert.areEqual(c.Id, notes[0].Case__c, 'Case lookup should be set');
    Assert.isNull(notes[0].Account__c, 'Account lookup should be null');
    Assert.isNull(notes[0].Opportunity__c, 'Opportunity lookup should be null');
}

@IsTest
static void saveNote_account_createsNoteWithAccountLookup() {
    Account acc = [SELECT Id FROM Account LIMIT 1];

    Test.startTest();
    DetailedNoteController.saveNote('Account Title', '<p>body</p>', acc.Id, 'Account');
    Test.stopTest();

    List<DetailedNote__c> notes = [
        SELECT Id, Account__c
        FROM DetailedNote__c
        WHERE Title__c = 'Account Title'
    ];
    Assert.areEqual(1, notes.size());
    Assert.areEqual(acc.Id, notes[0].Account__c);
}

@IsTest
static void saveNote_opportunity_createsNoteWithOpportunityLookup() {
    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

    Test.startTest();
    DetailedNoteController.saveNote('Opp Title', '<p>body</p>', opp.Id, 'Opportunity');
    Test.stopTest();

    List<DetailedNote__c> notes = [
        SELECT Id, Opportunity__c
        FROM DetailedNote__c
        WHERE Title__c = 'Opp Title'
    ];
    Assert.areEqual(1, notes.size());
    Assert.areEqual(opp.Id, notes[0].Opportunity__c);
}
```

- [ ] **Step 2: Implement saveNote in DetailedNoteController.cls**

Add to `DetailedNoteController.cls` after the `getNotes` method:

```apex
@AuraEnabled
public static void saveNote(
    String title,
    String body,
    String recordId,
    String objectApiName
) {
    DetailedNote__c note = new DetailedNote__c(
        Title__c = title,
        Body__c = body
    );
    if (objectApiName == 'Account') {
        note.Account__c = recordId;
    } else if (objectApiName == 'Case') {
        note.Case__c = recordId;
    } else if (objectApiName == 'Opportunity') {
        note.Opportunity__c = recordId;
    }
    insert note;
}
```

- [ ] **Step 3: Deploy and run tests**

```bash
sf project deploy start
sf apex run test --class-names DetailedNoteControllerTest --result-format human --wait 5
```

Expected: All 7 tests pass.

- [ ] **Step 4: Commit**

```bash
git add force-app/main/default/classes/
git commit -m "feat: implement saveNote with correct lookup routing"
```

---

## Task 6: Apex Controller — updateNote and deleteNote

**Files:**
- Modify: `force-app/main/default/classes/DetailedNoteController.cls`
- Modify: `force-app/main/default/classes/DetailedNoteControllerTest.cls`

- [ ] **Step 1: Write failing tests**

Add to `DetailedNoteControllerTest.cls`:

```apex
@IsTest
static void updateNote_creator_succeeds() {
    DetailedNote__c note = [SELECT Id FROM DetailedNote__c WHERE Title__c = 'Case Note' LIMIT 1];

    Test.startTest();
    DetailedNoteController.updateNote(note.Id, 'Updated Title', '<p>updated</p>');
    Test.stopTest();

    DetailedNote__c updated = [SELECT Title__c, Body__c FROM DetailedNote__c WHERE Id = :note.Id];
    Assert.areEqual('Updated Title', updated.Title__c);
    Assert.areEqual('<p>updated</p>', updated.Body__c);
}

@IsTest
static void updateNote_nonCreator_throwsException() {
    DetailedNote__c note = [SELECT Id FROM DetailedNote__c WHERE Title__c = 'Case Note' LIMIT 1];

    // Create a second user to run as
    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
    User otherUser = new User(
        FirstName = 'Other',
        LastName = 'User',
        Email = 'other@example.com',
        Username = 'other' + System.now().getTime() + '@example.com',
        Alias = 'other',
        TimeZoneSidKey = 'America/New_York',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        ProfileId = p.Id
    );
    insert otherUser;

    Test.startTest();
    System.runAs(otherUser) {
        try {
            DetailedNoteController.updateNote(note.Id, 'Hacked', '<p>x</p>');
            Assert.fail('Expected AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isTrue(
                e.getMessage().contains('permission'),
                'Exception message should mention permission'
            );
        }
    }
    Test.stopTest();
}

@IsTest
static void updateNote_userWithOverridePermission_succeeds() {
    DetailedNote__c note = [SELECT Id FROM DetailedNote__c WHERE Title__c = 'Case Note' LIMIT 1];

    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
    User adminUser = new User(
        FirstName = 'Admin',
        LastName = 'Override',
        Email = 'adminoverride@example.com',
        Username = 'adminoverride' + System.now().getTime() + '@example.com',
        Alias = 'admov',
        TimeZoneSidKey = 'America/New_York',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        ProfileId = p.Id
    );
    insert adminUser;

    // Assign Edit_All_Detailed_Notes custom permission via a permission set
    PermissionSet ps = new PermissionSet(Name = 'TestEditAllNotes', Label = 'Test Edit All Notes');
    insert ps;
    CustomPermission cp = [
        SELECT Id FROM CustomPermission
        WHERE DeveloperName = 'Edit_All_Detailed_Notes'
        LIMIT 1
    ];
    SetupEntityAccess sea = new SetupEntityAccess(ParentId = ps.Id, SetupEntityId = cp.Id);
    insert sea;
    insert new PermissionSetAssignment(AssigneeId = adminUser.Id, PermissionSetId = ps.Id);

    Test.startTest();
    System.runAs(adminUser) {
        DetailedNoteController.updateNote(note.Id, 'Admin Override Title', '<p>ok</p>');
    }
    Test.stopTest();

    DetailedNote__c updated = [SELECT Title__c FROM DetailedNote__c WHERE Id = :note.Id];
    Assert.areEqual('Admin Override Title', updated.Title__c);
}

@IsTest
static void deleteNote_creator_succeeds() {
    DetailedNote__c note = [SELECT Id FROM DetailedNote__c WHERE Title__c = 'Opp Note' LIMIT 1];
    Id noteId = note.Id;

    Test.startTest();
    DetailedNoteController.deleteNote(noteId);
    Test.stopTest();

    Assert.areEqual(
        0,
        [SELECT COUNT() FROM DetailedNote__c WHERE Id = :noteId],
        'Note should be deleted'
    );
}

@IsTest
static void deleteNote_nonCreator_throwsException() {
    DetailedNote__c note = [SELECT Id FROM DetailedNote__c WHERE Title__c = 'Opp Note' LIMIT 1];

    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
    User otherUser = new User(
        FirstName = 'Del',
        LastName = 'Test',
        Email = 'deltest@example.com',
        Username = 'deltest' + System.now().getTime() + '@example.com',
        Alias = 'delt',
        TimeZoneSidKey = 'America/New_York',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        ProfileId = p.Id
    );
    insert otherUser;

    Test.startTest();
    System.runAs(otherUser) {
        try {
            DetailedNoteController.deleteNote(note.Id);
            Assert.fail('Expected AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('permission'));
        }
    }
    Test.stopTest();
}
```

- [ ] **Step 2: Implement updateNote, deleteNote, and assertCanEdit**

Add to `DetailedNoteController.cls` after `saveNote`:

```apex
@AuraEnabled
public static void updateNote(String noteId, String title, String body) {
    DetailedNote__c note = [
        SELECT Id, CreatedById
        FROM DetailedNote__c
        WHERE Id = :noteId
        LIMIT 1
    ];
    assertCanEdit(note.CreatedById);
    note.Title__c = title;
    note.Body__c = body;
    update note;
}

@AuraEnabled
public static void deleteNote(String noteId) {
    DetailedNote__c note = [
        SELECT Id, CreatedById
        FROM DetailedNote__c
        WHERE Id = :noteId
        LIMIT 1
    ];
    assertCanEdit(note.CreatedById);
    delete note;
}

private static void assertCanEdit(String createdById) {
    if (
        createdById != UserInfo.getUserId() &&
        !FeatureManagement.checkPermission('Edit_All_Detailed_Notes')
    ) {
        throw new AuraHandledException(
            'You do not have permission to edit or delete this note.'
        );
    }
}
```

- [ ] **Step 3: Deploy and run all tests**

```bash
sf project deploy start
sf apex run test --class-names DetailedNoteControllerTest --result-format human --wait 5
```

Expected: All 12 tests pass.

- [ ] **Step 4: Commit**

```bash
git add force-app/main/default/classes/
git commit -m "feat: implement updateNote and deleteNote with creator/override authorization"
```

---

## Task 7: LWC — Component Shell and Note List

**Files:**
- Create: `force-app/main/default/lwc/detailedNotes/detailedNotes.js-meta.xml`
- Create: `force-app/main/default/lwc/detailedNotes/detailedNotes.html`
- Create: `force-app/main/default/lwc/detailedNotes/detailedNotes.js`
- Create: `force-app/main/default/lwc/detailedNotes/detailedNotes.css`
- Create: `force-app/main/default/lwc/detailedNotes/__tests__/detailedNotes.test.js`

- [ ] **Step 1: Create directory structure**

```bash
mkdir -p force-app/main/default/lwc/detailedNotes/__tests__
```

- [ ] **Step 2: Create LWC metadata**

File: `force-app/main/default/lwc/detailedNotes/detailedNotes.js-meta.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>66.0</apiVersion>
    <isExposed>true</isExposed>
    <targets>
        <target>lightning__RecordPage</target>
    </targets>
    <targetConfigs>
        <targetConfig targets="lightning__RecordPage">
            <objects>
                <object>Account</object>
                <object>Case</object>
                <object>Opportunity</object>
            </objects>
        </targetConfig>
    </targetConfigs>
</LightningComponentBundle>
```

- [ ] **Step 3: Write failing Jest test for note list rendering**

File: `force-app/main/default/lwc/detailedNotes/__tests__/detailedNotes.test.js`

```javascript
import { createElement } from 'lwc';
import DetailedNotes from 'c/detailedNotes';
import getNotes from '@salesforce/apex/DetailedNoteController.getNotes';

// Mock the apex wire adapter
jest.mock(
    '@salesforce/apex/DetailedNoteController.getNotes',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/wire-service-jest-util');
        return createApexTestWireAdapter(jest.fn());
    },
    { virtual: true }
);

// Mock imperative apex calls
jest.mock('@salesforce/apex/DetailedNoteController.saveNote', () => jest.fn(), { virtual: true });
jest.mock('@salesforce/apex/DetailedNoteController.updateNote', () => jest.fn(), { virtual: true });
jest.mock('@salesforce/apex/DetailedNoteController.deleteNote', () => jest.fn(), { virtual: true });

const MOCK_NOTES = [
    {
        id: 'a001',
        title: 'First Note',
        body: '<p>Body 1</p>',
        createdByName: 'Alice',
        createdById: 'user001',
        createdDate: '2026-05-01T10:00:00.000Z',
        canEdit: true,
        sourceLabel: null
    },
    {
        id: 'a002',
        title: 'Second Note',
        body: '<p>Body 2</p>',
        createdByName: 'Bob',
        createdById: 'user002',
        createdDate: '2026-05-02T10:00:00.000Z',
        canEdit: false,
        sourceLabel: 'Case: Billing Issue'
    }
];

describe('detailedNotes', () => {
    let element;

    beforeEach(() => {
        element = createElement('c-detailed-notes', { is: DetailedNotes });
        element.recordId = 'record001';
        element.objectApiName = 'Account';
        document.body.appendChild(element);
    });

    afterEach(() => {
        document.body.removeChild(element);
    });

    it('renders note tiles after wire emits data', async () => {
        getNotes.emit(MOCK_NOTES);
        await Promise.resolve();

        const tiles = element.shadowRoot.querySelectorAll('[data-id]');
        expect(tiles.length).toBe(2);
    });

    it('shows title and author on each tile', async () => {
        getNotes.emit(MOCK_NOTES);
        await Promise.resolve();

        const tiles = element.shadowRoot.querySelectorAll('[data-id]');
        expect(tiles[0].textContent).toContain('First Note');
        expect(tiles[0].textContent).toContain('Alice');
    });

    it('shows source badge when sourceLabel is present', async () => {
        getNotes.emit(MOCK_NOTES);
        await Promise.resolve();

        const badges = element.shadowRoot.querySelectorAll('.source-badge');
        expect(badges.length).toBe(1);
        expect(badges[0].textContent).toContain('Case: Billing Issue');
    });

    it('renders new note button', () => {
        const btn = element.shadowRoot.querySelector('[data-id="new-note-btn"]');
        expect(btn).not.toBeNull();
    });
});
```

- [ ] **Step 4: Run test to confirm it fails**

```bash
npx sfdx-lwc-jest --testPathPattern="force-app/main/default/lwc/detailedNotes"
```

Expected: FAIL — component doesn't exist yet.

- [ ] **Step 5: Create the LWC HTML (note list only)**

File: `force-app/main/default/lwc/detailedNotes/detailedNotes.html`

```html
<template>
    <lightning-card title="Detailed Notes">
        <div slot="actions">
            <lightning-button
                label="New Note"
                data-id="new-note-btn"
                onclick={handleNewNote}
            ></lightning-button>
        </div>
        <div class="slds-grid note-container">
            <!-- Left panel: note list -->
            <div class="slds-col note-list">
                <template if:true={hasNotes}>
                    <template for:each={noteList} for:item="note">
                        <div
                            key={note.id}
                            class={note.tileClass}
                            data-id={note.id}
                            onclick={handleNoteSelect}
                        >
                            <div class="note-tile-title">{note.title}</div>
                            <div class="note-tile-meta">{note.createdByName} &middot; {note.formattedDate}</div>
                            <template if:true={note.sourceLabel}>
                                <div class="source-badge">{note.sourceLabel}</div>
                            </template>
                        </div>
                    </template>
                </template>
                <template if:false={hasNotes}>
                    <p class="slds-text-color_weak slds-p-around_small">No notes yet.</p>
                </template>
            </div>
            <!-- Right panel: viewer/editor — implemented in Task 8 and 9 -->
            <div class="slds-col slds-size_2-of-3 note-panel"></div>
        </div>
    </lightning-card>
</template>
```

- [ ] **Step 6: Create the LWC JavaScript (note list logic)**

File: `force-app/main/default/lwc/detailedNotes/detailedNotes.js`

```javascript
import { LightningElement, api, wire } from 'lwc';
import getNotes from '@salesforce/apex/DetailedNoteController.getNotes';
import saveNote from '@salesforce/apex/DetailedNoteController.saveNote';
import updateNote from '@salesforce/apex/DetailedNoteController.updateNote';
import deleteNote from '@salesforce/apex/DetailedNoteController.deleteNote';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class DetailedNotes extends LightningElement {
    @api recordId;
    @api objectApiName;

    selectedNoteId = null;
    showEditor = false;
    editorTitle = '';
    editorBody = '';
    editingNoteId = null;

    _wiredResult;

    @wire(getNotes, { recordId: '$recordId', objectApiName: '$objectApiName' })
    wiredNotes(result) {
        this._wiredResult = result;
    }

    get noteList() {
        if (!this._wiredResult?.data) return [];
        return this._wiredResult.data.map((n) => ({
            ...n,
            formattedDate: new Date(n.createdDate).toLocaleDateString(),
            tileClass:
                'note-tile' + (n.id === this.selectedNoteId ? ' note-tile--selected' : '')
        }));
    }

    get hasNotes() {
        return this.noteList.length > 0;
    }

    get selectedNote() {
        if (!this.selectedNoteId) return null;
        return this.noteList.find((n) => n.id === this.selectedNoteId) || null;
    }

    handleNoteSelect(event) {
        this.selectedNoteId = event.currentTarget.dataset.id;
        this.showEditor = false;
    }

    handleNewNote() {
        this.editingNoteId = null;
        this.editorTitle = '';
        this.editorBody = '';
        this.showEditor = true;
    }
}
```

- [ ] **Step 7: Create the CSS**

File: `force-app/main/default/lwc/detailedNotes/detailedNotes.css`

```css
.note-container {
    min-height: 300px;
}

.note-list {
    width: 35%;
    border-right: 1px solid #dddbda;
    overflow-y: auto;
    max-height: 500px;
}

.note-panel {
    width: 65%;
    padding: 0 1rem;
}

.note-tile {
    padding: 0.75rem 1rem;
    border-bottom: 1px solid #f3f2f2;
    cursor: pointer;
}

.note-tile:hover {
    background-color: #f3f2f2;
}

.note-tile--selected {
    background-color: #e8f4ff;
    border-left: 3px solid #0070d2;
}

.note-tile-title {
    font-weight: 600;
    font-size: 0.875rem;
}

.note-tile-meta {
    font-size: 0.75rem;
    color: #706e6b;
    margin-top: 2px;
}

.source-badge {
    font-size: 0.7rem;
    color: #0070d2;
    margin-top: 3px;
}

.editor-actions {
    margin-top: 1rem;
    display: flex;
    gap: 0.5rem;
}
```

- [ ] **Step 8: Run Jest tests**

```bash
npx sfdx-lwc-jest --testPathPattern="force-app/main/default/lwc/detailedNotes"
```

Expected: All 4 tests pass.

- [ ] **Step 9: Commit**

```bash
git add force-app/main/default/lwc/detailedNotes/
git commit -m "feat: add detailedNotes LWC shell with note list panel"
```

---

## Task 8: LWC — Note Viewer Panel with Edit/Delete

**Files:**
- Modify: `force-app/main/default/lwc/detailedNotes/detailedNotes.html`
- Modify: `force-app/main/default/lwc/detailedNotes/detailedNotes.js`
- Modify: `force-app/main/default/lwc/detailedNotes/__tests__/detailedNotes.test.js`

- [ ] **Step 1: Add failing tests for the viewer panel**

Add these tests inside the `describe('detailedNotes')` block in `detailedNotes.test.js`:

```javascript
it('clicking a note tile displays the note body', async () => {
    getNotes.emit(MOCK_NOTES);
    await Promise.resolve();

    const tile = element.shadowRoot.querySelector('[data-id="a001"]');
    tile.click();
    await Promise.resolve();

    const viewer = element.shadowRoot.querySelector('[data-id="note-viewer"]');
    expect(viewer).not.toBeNull();
});

it('shows edit and delete buttons when canEdit is true', async () => {
    getNotes.emit(MOCK_NOTES);
    await Promise.resolve();

    element.shadowRoot.querySelector('[data-id="a001"]').click();
    await Promise.resolve();

    const editBtn = element.shadowRoot.querySelector('[data-id="edit-btn"]');
    const deleteBtn = element.shadowRoot.querySelector('[data-id="delete-btn"]');
    expect(editBtn).not.toBeNull();
    expect(deleteBtn).not.toBeNull();
});

it('hides edit and delete buttons when canEdit is false', async () => {
    getNotes.emit(MOCK_NOTES);
    await Promise.resolve();

    // Select note a002 which has canEdit: false
    element.shadowRoot.querySelector('[data-id="a002"]').click();
    await Promise.resolve();

    const editBtn = element.shadowRoot.querySelector('[data-id="edit-btn"]');
    const deleteBtn = element.shadowRoot.querySelector('[data-id="delete-btn"]');
    expect(editBtn).toBeNull();
    expect(deleteBtn).toBeNull();
});
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
npx sfdx-lwc-jest --testPathPattern="force-app/main/default/lwc/detailedNotes"
```

Expected: 3 new tests fail.

- [ ] **Step 3: Update HTML — add note viewer to the right panel**

Replace the `<div class="slds-col slds-size_2-of-3 note-panel"></div>` in `detailedNotes.html` with:

```html
<div class="slds-col note-panel">
    <template if:false={showEditor}>
        <template if:true={selectedNote}>
            <div data-id="note-viewer">
                <h2 class="slds-text-heading_medium">{selectedNote.title}</h2>
                <p class="note-tile-meta">
                    {selectedNote.createdByName} &middot; {selectedNote.formattedDate}
                </p>
                <template if:true={selectedNote.sourceLabel}>
                    <p class="source-badge">{selectedNote.sourceLabel}</p>
                </template>
                <div class="note-body slds-m-top_small">
                    <lightning-formatted-rich-text
                        value={selectedNote.body}
                    ></lightning-formatted-rich-text>
                </div>
                <template if:true={selectedNote.canEdit}>
                    <div class="editor-actions">
                        <lightning-button
                            label="Edit"
                            data-id="edit-btn"
                            onclick={handleEdit}
                        ></lightning-button>
                        <lightning-button
                            label="Delete"
                            variant="destructive"
                            data-id="delete-btn"
                            onclick={handleDelete}
                        ></lightning-button>
                    </div>
                </template>
            </div>
        </template>
        <template if:false={selectedNote}>
            <p class="slds-text-color_weak slds-p-around_small">Select a note to view it.</p>
        </template>
    </template>
    <!-- Editor form placeholder — implemented in Task 9 -->
    <template if:true={showEditor}>
        <div data-id="editor-form"></div>
    </template>
</div>
```

- [ ] **Step 4: Add handleEdit and handleDelete to detailedNotes.js**

Add these methods to the `DetailedNotes` class in `detailedNotes.js`:

```javascript
handleEdit() {
    this.editingNoteId = this.selectedNoteId;
    this.editorTitle = this.selectedNote.title;
    this.editorBody = this.selectedNote.body;
    this.showEditor = true;
}

async handleDelete() {
    try {
        await deleteNote({ noteId: this.selectedNoteId });
        this.selectedNoteId = null;
        await refreshApex(this._wiredResult);
        this.dispatchEvent(
            new ShowToastEvent({ title: 'Success', message: 'Note deleted.', variant: 'success' })
        );
    } catch (e) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: e.body?.message || 'Delete failed.',
                variant: 'error'
            })
        );
    }
}
```

- [ ] **Step 5: Run all Jest tests**

```bash
npx sfdx-lwc-jest --testPathPattern="force-app/main/default/lwc/detailedNotes"
```

Expected: All 7 tests pass.

- [ ] **Step 6: Commit**

```bash
git add force-app/main/default/lwc/detailedNotes/
git commit -m "feat: add note viewer panel with conditional edit/delete buttons"
```

---

## Task 9: LWC — Create/Edit Form

**Files:**
- Modify: `force-app/main/default/lwc/detailedNotes/detailedNotes.html`
- Modify: `force-app/main/default/lwc/detailedNotes/detailedNotes.js`
- Modify: `force-app/main/default/lwc/detailedNotes/__tests__/detailedNotes.test.js`

- [ ] **Step 1: Add failing tests for the editor form**

Add to `detailedNotes.test.js`:

```javascript
import saveNote from '@salesforce/apex/DetailedNoteController.saveNote';
import updateNote from '@salesforce/apex/DetailedNoteController.updateNote';

it('clicking New Note shows the editor form', async () => {
    getNotes.emit(MOCK_NOTES);
    await Promise.resolve();

    element.shadowRoot.querySelector('[data-id="new-note-btn"]').click();
    await Promise.resolve();

    const form = element.shadowRoot.querySelector('[data-id="editor-form"]');
    expect(form).not.toBeNull();
});

it('clicking Cancel hides the editor form', async () => {
    getNotes.emit(MOCK_NOTES);
    await Promise.resolve();

    element.shadowRoot.querySelector('[data-id="new-note-btn"]').click();
    await Promise.resolve();

    element.shadowRoot.querySelector('[data-id="cancel-btn"]').click();
    await Promise.resolve();

    const form = element.shadowRoot.querySelector('[data-id="editor-form"]');
    // editor-form div should be gone (template if:true={showEditor} is false)
    expect(element.shadowRoot.querySelector('[data-id="note-viewer"]')).toBeNull();
    // and the "Select a note" placeholder should be visible
    const placeholder = element.shadowRoot.querySelector('.slds-text-color_weak');
    expect(placeholder).not.toBeNull();
});

it('title input enforces maxlength of 100', async () => {
    getNotes.emit([]);
    await Promise.resolve();

    element.shadowRoot.querySelector('[data-id="new-note-btn"]').click();
    await Promise.resolve();

    const titleInput = element.shadowRoot.querySelector('[data-id="title-input"]');
    expect(titleInput.maxLength).toBe(100);
});
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
npx sfdx-lwc-jest --testPathPattern="force-app/main/default/lwc/detailedNotes"
```

Expected: 3 new tests fail.

- [ ] **Step 3: Replace the editor form placeholder in detailedNotes.html**

Replace `<div data-id="editor-form"></div>` inside `<template if:true={showEditor}>` with:

```html
<div data-id="editor-form">
    <lightning-input
        data-id="title-input"
        label="Title"
        value={editorTitle}
        max-length="100"
        onchange={handleTitleChange}
        required
    ></lightning-input>
    <div class="slds-m-top_small">
        <lightning-input-rich-text
            value={editorBody}
            onchange={handleBodyChange}
        ></lightning-input-rich-text>
    </div>
    <div class="editor-actions">
        <lightning-button
            label="Save"
            variant="brand"
            onclick={handleSave}
        ></lightning-button>
        <lightning-button
            label="Cancel"
            data-id="cancel-btn"
            onclick={handleCancel}
        ></lightning-button>
    </div>
</div>
```

- [ ] **Step 4: Add handleTitleChange, handleBodyChange, handleSave, handleCancel to detailedNotes.js**

Add these methods to the `DetailedNotes` class:

```javascript
handleTitleChange(event) {
    this.editorTitle = event.target.value;
}

handleBodyChange(event) {
    this.editorBody = event.target.value;
}

handleCancel() {
    this.showEditor = false;
}

async handleSave() {
    try {
        if (this.editingNoteId) {
            await updateNote({
                noteId: this.editingNoteId,
                title: this.editorTitle,
                body: this.editorBody
            });
        } else {
            await saveNote({
                title: this.editorTitle,
                body: this.editorBody,
                recordId: this.recordId,
                objectApiName: this.objectApiName
            });
        }
        await refreshApex(this._wiredResult);
        this.showEditor = false;
        this.dispatchEvent(
            new ShowToastEvent({ title: 'Success', message: 'Note saved.', variant: 'success' })
        );
    } catch (e) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: e.body?.message || 'Save failed.',
                variant: 'error'
            })
        );
    }
}
```

- [ ] **Step 5: Run all Jest tests**

```bash
npx sfdx-lwc-jest --testPathPattern="force-app/main/default/lwc/detailedNotes"
```

Expected: All 10 tests pass.

- [ ] **Step 6: Run full test suite and lint**

```bash
npm run lint
npm run test
```

Expected: No lint errors, all tests pass.

- [ ] **Step 7: Commit**

```bash
git add force-app/main/default/lwc/detailedNotes/
git commit -m "feat: add create/edit form to detailedNotes LWC"
```

---

## Task 10: Deploy and Smoke Test on Scratch Org

**Files:** No code changes — deployment and manual verification only.

- [ ] **Step 1: Create a scratch org (if you don't have one)**

```bash
sf org create scratch \
  --definition-file config/project-scratch-def.json \
  --alias detailed-notes-dev \
  --duration-days 7
```

- [ ] **Step 2: Deploy all metadata**

```bash
sf project deploy start --target-org detailed-notes-dev
```

Expected: Deploy succeeds with no errors.

- [ ] **Step 3: Assign permission set to yourself**

```bash
sf org assign permset \
  --name DetailedNotes_User \
  --target-org detailed-notes-dev
```

- [ ] **Step 4: Open the scratch org**

```bash
sf org open --target-org detailed-notes-dev
```

- [ ] **Step 5: Add the component to an Account page**

In the org:
1. Navigate to any Account record.
2. Click the gear icon → **Edit Page**.
3. Find **Detailed Notes** in the component list and drag it onto the page.
4. Save and activate the page.

- [ ] **Step 6: Smoke test the component**

Verify the following manually:

- [ ] Component renders with an empty state message when there are no notes
- [ ] "New Note" button opens the editor form in the right panel
- [ ] Title input rejects input beyond 100 characters
- [ ] Rich text editor is functional (bold, bullets, etc.)
- [ ] Saving a note adds it to the left panel list
- [ ] Clicking a note tile shows its body in the right panel
- [ ] Edit and Delete buttons appear on your own notes
- [ ] Edit pre-fills title and body; saving updates the note
- [ ] Delete removes the note from the list

- [ ] **Step 7: Add component to Case and Opportunity pages via App Builder, repeat smoke test**

- [ ] **Step 8: Verify the Account rollup**

1. Create a Case linked to a test Account and add a note to the Case.
2. Create an Opportunity linked to the same Account and add a note to it.
3. On the Account page, confirm the component shows the Account's own notes plus the Case note (with "Case: …" badge) and the Opportunity note (with "Opportunity: …" badge).

- [ ] **Step 9: Final commit**

```bash
git add .
git commit -m "chore: final metadata state after smoke test"
```
