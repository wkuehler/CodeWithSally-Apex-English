# PHASE 1: Foundation — Build Plan

## Objective

Establish the complete data model, configuration metadata, and development environment for the Trailhead Gamified Learning Platform. No Apex code is written in this phase. The output is a deployable SFDX project with all custom objects, fields, validation rules, CMTs, seed data, and DevOps scaffolding that all subsequent phases build upon.

Stories in scope: US-8.1, US-1.1, US-1.2, US-1.3, US-1.4, US-1.5, US-1.6

Notes and constraints:
- SFDX source format for all metadata under force-app/main/default/.
- No Apex, LWC, Aura, or App Builder in this phase.
- Follow .a4drules for custom object decomposed metadata and XML structure.
- Use sf CLI, prefer MCP tools (salesforce-dx) for org operations.

---

## Dependency Order & Phase Gates

```
GATE 0: DevOps Scaffold  (sf-devops)
    └── GATE 1: Core Object Schema  (admin-schema)
            ├── GATE 2: Dependent Object Schema  (admin-schema)
            └── GATE 3: Configuration Metadata  (admin-config)
                    └── GATE 4: Deploy & Verify  (sf-devops)
```

Each gate must be verified before the next begins. The sf-devops agent runs a dry-run deploy at every gate to confirm the in-progress metadata compiles cleanly.

---

## GATE 0 — DevOps Scaffold

Skill: sf-devops  
Depends on: Existing scratch org connection  
Objective: Confirm the project skeleton is correct and the scratch org is reachable. Establish all DevOps artefacts.

### Required Files/Structure

- sfdx-project.json includes:
  - packageDirectories → path: "force-app", default: true
  - sourceApiVersion → current API version (keep in sync on deploy)
  - namespace → "" (empty)
- .forceignore covers:
  - .DS_Store
  - node_modules/
  - *.lock
  - .env
  - .env.*
  - coverage/
- config/project-scratch-def.json:
  - edition: "Developer"
  - hasSampleData: false
  - orgName: "Trailhead Gamified Platform"
  - features: ["EnableSetPasswordInApi"]
- Directory tree baseline:
  - force-app/main/default/
    - objects/
    - customMetadata/
    - permissionsets/
    - tabs/
    - applications/
    - flexipages/
    - staticresources/
    - profiles/
    - settings/
- Scripts (executable):
  - scripts/setup.sh
  - scripts/validate.sh
  - scripts/deploy.sh
- README.md updated with prerequisites and placeholders

### Tool Calls

| Step | MCP Tool | Purpose |
|---|---|---|
| 0.1 | list_all_orgs | Confirm the connected scratch org is listed and authenticated |
| 0.2 | run_soql_query | SELECT Id, Name, OrganizationType FROM Organization — confirm org identity |
| 0.3 | deploy_metadata | Deploy the initial project skeleton (sfdx-project.json + config/) |
| 0.4 | retrieve_metadata | Pull back org metadata to confirm round-trip works |

### TODO Items

- [ ] 0.1 Verify sfdx-project.json exists with "sourceApiVersion" current, "packageDirectories" pointing to force-app/main/default/, and "namespace" empty.
- [ ] 0.2 Create config/project-scratch-def.json: edition Developer, hasSampleData: false, orgName: "Trailhead Gamified Platform", features includes "EnableSetPasswordInApi".
- [ ] 0.3 Create .forceignore excluding .DS_Store, *.lock, node_modules/, and any local env files.
- [ ] 0.4 Create the full force-app/main/default/ subfolder structure: objects/, customMetadata/, permissionsets/, tabs/, applications/, flexipages/, staticresources/, profiles/, settings/.
- [ ] 0.5 Create scripts/setup.sh skeleton (executable): steps for sf project deploy start, sf org assign permset, and seed data execution — stubs only, to be completed in Gate 4.
- [ ] 0.6 Create scripts/validate.sh skeleton: sf project deploy start --dry-run --test-level RunLocalTests and exit non-zero on failure.
- [ ] 0.7 Create scripts/deploy.sh skeleton: sf project deploy start --test-level RunLocalTests.
- [ ] 0.8 Create README.md with project purpose, prerequisite tools (SF CLI, Node.js), and placeholders for setup steps.
- [ ] 0.9 Run list_all_orgs via MCP — confirm scratch org is visible and status is active.
- [ ] 0.10 Run run_soql_query (SELECT Id, Name, OrganizationType FROM Organization) — record the org ID for use in later verification steps.

### Gate 0 Exit Criteria

- sfdx-project.json and config/project-scratch-def.json are valid JSON.
- force-app/main/default/ directory tree exists.
- MCP list_all_orgs returns the scratch org with an active status.
- deploy_metadata of the empty project skeleton returns success (0 components, 0 errors).

---

## GATE 1 — Core Object Schema

Skill: admin-schema  
Depends on: Gate 0  
Objective: Create Trailblazer_Profile__c first (all other objects depend on it), then Badge__c and Certification__c as master-detail children. Each object must be deployed and verified before dependents are built.

### Tool Calls

| Step | MCP Tool | Purpose |
|---|---|---|
| 1.1 | deploy_metadata | Deploy Trailblazer_Profile__c object + fields |
| 1.2 | run_soql_query | Verify object and required fields exist in the org |
| 1.3 | deploy_metadata | Deploy Badge__c object |
| 1.4 | run_soql_query | Verify Badge__c master-detail relationship and external ID |
| 1.5 | deploy_metadata | Deploy Certification__c object |
| 1.6 | run_soql_query | Verify Certification__c fields and validation rule |

### TODO Items — US-1.1: Trailblazer_Profile__c

- [ ] 1.1.1 Create force-app/main/default/objects/Trailblazer_Profile__c/Trailblazer_Profile__c.object-meta.xml. Set label, pluralLabel, nameField (AutoNumber or Text), deploymentStatus: Deployed, sharingModel: Private, enableReports: true, enableActivities: true, enableHistory: true, enableSearch: true, enableBulkApi: true, enableStreamingApi: true.
- [ ] 1.1.2 Create field metadata files (force-app/main/default/objects/Trailblazer_Profile__c/fields/*.field-meta.xml):
  - Trailhead_Username__c: Text(255), required, unique (case-insensitive), externalId: false. inlineHelpText: "Your Trailhead username as shown on your public profile."
  - Trailhead_Id__c: Text(18), externalId: true, unique. inlineHelpText: "Salesforce User ID from your Trailhead public profile URL."
  - Current_Rank__c: Picklist with 12 values: Scout, Hiker, Explorer, Adventurer, Mountaineer, Expeditioner, Ranger, Double Star Ranger, Triple Star Ranger, Four Star Ranger, Five Star Ranger, All Star Ranger. inlineHelpText: "Your current Trailhead rank, synced from Trailhead API."
  - Total_Points__c: Number(18,0), defaultValue: 0. inlineHelpText: "Cumulative Trailhead points synced from your public profile."
  - Total_Badges__c: Number(18,0), defaultValue: 0. inlineHelpText: "Total badges earned on Trailhead."
  - Total_Certifications__c: Number(18,0), defaultValue: 0. inlineHelpText: "Number of active Salesforce certifications."
  - Total_Superbadges__c: Number(18,0), defaultValue: 0. inlineHelpText: "Number of superbadges earned on Trailhead."
  - Current_Streak__c: Number(18,0), defaultValue: 0. inlineHelpText: "Consecutive days with qualifying learning activity."
  - Longest_Streak__c: Number(18,0), defaultValue: 0. inlineHelpText: "Your all-time longest learning streak in days."
  - Last_Badge_Date__c: Date. inlineHelpText: "Date the most recent badge was earned."
  - Last_Sync_Date__c: DateTime. inlineHelpText: "Timestamp of the last successful Trailhead API sync."
  - XP_Total__c: Number(18,0), defaultValue: 0. inlineHelpText: "Total internal XP earned across all platform actions."
  - Current_Level__c: Number(18,0), defaultValue: 1. inlineHelpText: "Current platform level based on XP total."
  - User__c: Lookup(User). inlineHelpText: "The Salesforce user this profile belongs to."
- [ ] 1.1.3 Create compact layout: force-app/main/default/objects/Trailblazer_Profile__c/compactLayouts/Trailblazer_Profile__c-Compact.compactLayout-meta.xml with fields Name, Current_Rank__c, Total_Points__c, Total_Badges__c, Current_Streak__c.
- [ ] 1.1.4 Create list views (force-app/main/default/objects/Trailblazer_Profile__c/listViews/):
  - My_Profile.listView-meta.xml — filter User__c = $User.Id
  - All_Trailblazers.listView-meta.xml — no filter, sort by Total_Points__c desc
  - Top_Streaks.listView-meta.xml — no filter, sort by Current_Streak__c desc
- [ ] 1.1.5 Create tab: force-app/main/default/tabs/Trailblazer_Profile__c.tab-meta.xml with icon standard:user.
- [ ] 1.1.6 Deploy Trailblazer_Profile__c metadata via deploy_metadata.
- [ ] 1.1.7 Verify object: SELECT QualifiedApiName FROM EntityDefinition WHERE QualifiedApiName = 'Trailblazer_Profile__c' (returns 1).
- [ ] 1.1.8 Verify field count: SELECT QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'Trailblazer_Profile__c' (count includes 14 custom fields).
- [ ] 1.1.9 Verify external ID: SELECT QualifiedApiName, IsIdLookup FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'Trailblazer_Profile__c' AND QualifiedApiName = 'Trailhead_Id__c' (IsIdLookup = true).

### TODO Items — US-1.2: Badge__c

- [ ] 1.2.1 Create force-app/main/default/objects/Badge__c/Badge__c.object-meta.xml. Set sharingModel: ControlledByParent, enableReports, enableActivities.
- [ ] 1.2.2 Create fields:
  - Trailblazer_Profile__c: MasterDetail(Trailblazer_Profile__c), label "Trailblazer Profile", reparentableMasterDetail: false, relationshipOrder: 0, relationshipName: Badges.
  - Badge_Title__c: Text(255), required. inlineHelpText: "The full title of the Trailhead badge."
  - Badge_Type__c: Picklist: Module, Project, Superbadge, Event. inlineHelpText: "Category of the Trailhead badge."
  - Trailhead_Badge_Id__c: Text(255), externalId: true, unique. inlineHelpText: "Unique Trailhead identifier used to prevent duplicate badge records."
  - Earned_Date__c: Date. inlineHelpText: "The date this badge was earned on Trailhead."
  - Points_Earned__c: Number(18,0), defaultValue: 0. inlineHelpText: "Trailhead points awarded for this badge."
  - Icon_URL__c: Url(255). inlineHelpText: "URL to the badge icon image from Trailhead."
  - Trailhead_URL__c: Url(255). inlineHelpText: "Direct link to this badge on Trailhead."
  - Description__c: LongTextArea(32768). inlineHelpText: "Badge description from Trailhead."
- [ ] 1.2.3 Create list views: Recent_Badges (sort Earned_Date__c desc), Superbadges_Only (filter Badge_Type__c = 'Superbadge').
- [ ] 1.2.4 Create compact layout with Badge_Title__c, Badge_Type__c, Earned_Date__c, Points_Earned__c.
- [ ] 1.2.5 Deploy Badge__c metadata.
- [ ] 1.2.6 Verify M-D: SELECT QualifiedApiName, DataType FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'Badge__c' AND QualifiedApiName = 'Trailblazer_Profile__c' — DataType indicates MasterDetail.
- [ ] 1.2.7 Verify external ID on Trailhead_Badge_Id__c via FieldDefinition.IsIdLookup.

### TODO Items — US-1.3: Certification__c

- [ ] 1.3.1 Create force-app/main/default/objects/Certification__c/Certification__c.object-meta.xml. Set sharingModel: ControlledByParent, enableReports, enableActivities (optional).
- [ ] 1.3.2 Create fields:
  - Trailblazer_Profile__c: MasterDetail(Trailblazer_Profile__c), relationshipName: Certifications, relationshipOrder: 0.
  - Cert_Name__c: Text(255), required. inlineHelpText: "Full name of the Salesforce certification."
  - Cert_Id__c: Text(255), externalId: true, unique. inlineHelpText: "Trailhead certification identifier for deduplication."
  - Status__c: Picklist: Active, Expired, Maintenance Due. inlineHelpText: "Current maintenance status of this certification."
  - Date_Earned__c: Date. inlineHelpText: "Date the certification was awarded."
  - Date_Expires__c: Date. inlineHelpText: "Expiry date (if applicable)."
  - Maintenance_Due_Date__c: Date. inlineHelpText: "Date by which maintenance must be completed."
- [ ] 1.3.3 Create validation rule (force-app/main/default/objects/Certification__c/validationRules/Expiry_After_Earned.validationRule-meta.xml): condition Date_Expires__c != null AND Date_Expires__c <= Date_Earned__c; message "Expiry date must be after the date earned."
- [ ] 1.3.4 Create list views: Active_Certs (Status__c = 'Active'), Maintenance_Due (Status__c = 'Maintenance Due').
- [ ] 1.3.5 Create compact layout: Cert_Name__c, Status__c, Date_Earned__c, Maintenance_Due_Date__c.
- [ ] 1.3.6 Deploy Certification__c metadata.
- [ ] 1.3.7 Verify validation rule exists: SELECT ValidationName, EntityDefinition.QualifiedApiName FROM ValidationRule WHERE EntityDefinition.QualifiedApiName = 'Certification__c' — returns ≥ 1.

### Gate 1 Exit Criteria

- deploy_metadata returns 0 errors for all three objects.
- SOQL verification confirms all 3 objects exist with correct field counts.
- M-D relationships on Badge__c and Certification__c confirmed via FieldDefinition.
- External IDs confirmed on Trailhead_Id__c, Trailhead_Badge_Id__c, Cert_Id__c.
- Validation rule on Certification__c confirmed.

---

## GATE 2 — Dependent Object Schema

Skill: admin-schema  
Depends on: Gate 1 (Trailblazer_Profile__c must exist)  
Objective: Create Discovery__c, Quest__c, and Quest_Enrollment__c objects. These have dependencies on objects from Gate 1.

### Tool Calls

| Step | MCP Tool | Purpose |
|---|---|---|
| 2.1 | deploy_metadata | Deploy Discovery__c |
| 2.2 | run_soql_query | Verify Discovery__c fields and relationships |
| 2.3 | deploy_metadata | Deploy Quest__c |
| 2.4 | run_soql_query | Verify Quest__c formula field and picklist |
| 2.5 | deploy_metadata | Deploy Quest_Enrollment__c |
| 2.6 | run_soql_query | Verify Quest_Enrollment__c relationships |
| 2.7 | deploy_metadata | Full project dry-run deploy |

### TODO Items — US-1.4: Discovery__c

- [ ] 2.1.1 Create force-app/main/default/objects/Discovery__c/Discovery__c.object-meta.xml. Set sharingModel: ReadWrite, enableReports: true, enableActivities: true, enableHistory: true, enableSearch: true.
- [ ] 2.1.2 Create fields:
  - Name: AutoNumber or Text (object nameField definition).
  - Type__c: Picklist: Module, Blog, Video, Documentation, Community Post, Other. required. inlineHelpText: "The category of this learning resource."
  - URL__c: Url(255). inlineHelpText: "Link to the learning resource."
  - Notes__c: LongTextArea(32768). inlineHelpText: "Your personal notes on this resource."
  - Rating__c: Number(1,0), defaultValue: null. inlineHelpText: "Your rating of this resource from 1 (poor) to 5 (excellent)."
  - Related_Certification__c: Lookup(Certification__c), label "Related Certification". inlineHelpText: "Link this resource to a certification you are studying for."
  - Tags__c: Text(255). inlineHelpText: "Comma-separated tags for filtering (e.g. 'admin,flow,automation')."
  - Trailblazer_Profile__c: Lookup(Trailblazer_Profile__c). inlineHelpText: "The Trailblazer profile this discovery is associated with."
- [ ] 2.1.3 Validation rule (force-app/main/default/objects/Discovery__c/validationRules/Rating_Range.validationRule-meta.xml): Rating__c != null AND (Rating__c < 1 || Rating__c > 5) → "Rating must be between 1 and 5."
- [ ] 2.1.4 Deploy Discovery__c.
- [ ] 2.1.5 Verify field count: SELECT COUNT() FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'Discovery__c'.

### TODO Items — US-1.6: Quest__c

- [ ] 2.2.1 Create force-app/main/default/objects/Quest__c/Quest__c.object-meta.xml. Set sharingModel: ReadWrite, enableReports: true, enableActivities: true.
- [ ] 2.2.2 Create fields:
  - Quest_Name__c: Text(255), required. inlineHelpText: "The name of this time-bound learning challenge."
  - Description__c: Html (RichTextArea) length 32768. inlineHelpText: "Full description of the quest objectives and prizes."
  - Start_Date__c: Date. inlineHelpText: "The date the quest opens for enrollment."
  - End_Date__c: Date. inlineHelpText: "The date the quest closes."
  - Criteria_Type__c: Picklist: Badge_Count, Trail_Completion, Cert_Earned, Custom. inlineHelpText: "The type of completion criteria for this quest."
  - Criteria_Value__c: Number(18,0). inlineHelpText: "The target value for the completion criteria (e.g., 10 for 10 badges)."
  - Reward_Description__c: Text(255). inlineHelpText: "Description of the prize or reward for completing this quest."
  - Is_Active__c: Formula(Checkbox): TODAY() >= Start_Date__c && TODAY() <= End_Date__c. inlineHelpText: "True when today falls within the quest start and end dates."
  - XP_Reward__c: Number(18,0), defaultValue: 0. inlineHelpText: "Platform XP awarded on quest completion."
- [ ] 2.2.3 Validation rule (force-app/main/default/objects/Quest__c/validationRules/End_After_Start.validationRule-meta.xml): End_Date__c != null AND Start_Date__c != null AND End_Date__c <= Start_Date__c → "End date must be after start date."
- [ ] 2.2.4 List views: Active_Quests (Is_Active__c = true), All_Quests (no filter).
- [ ] 2.2.5 Tab: force-app/main/default/tabs/Quest__c.tab-meta.xml.
- [ ] 2.2.6 Deploy Quest__c.

### TODO Items — US-1.6: Quest_Enrollment__c

- [ ] 2.3.1 Create force-app/main/default/objects/Quest_Enrollment__c/Quest_Enrollment__c.object-meta.xml. Master-Detail to Trailblazer_Profile__c (primary), Lookup to Quest__c. Set sharingModel: ControlledByParent.
- [ ] 2.3.2 Create fields:
  - Trailblazer_Profile__c: MasterDetail(Trailblazer_Profile__c), relationshipName: Quest_Enrollments, relationshipOrder: 0.
  - Quest__c: Lookup(Quest__c), required. inlineHelpText: "The quest this enrollment record belongs to."
  - Enrolled_Date__c: Date, defaultValue: TODAY(). inlineHelpText: "The date the learner enrolled in this quest."
  - Status__c: Picklist: In Progress, Completed, Expired. default: In Progress. inlineHelpText: "Current completion status of this quest enrollment."
  - Completed_Date__c: Date. inlineHelpText: "The date the learner completed this quest."
  - Progress_Count__c: Number(18,0), defaultValue: 0. inlineHelpText: "Running count of qualifying actions towards quest completion."
- [ ] 2.3.3 Validation rule (force-app/main/default/objects/Quest_Enrollment__c/validationRules/Completed_Requires_Date.validationRule-meta.xml): ISPICKVAL(Status__c, 'Completed') && ISBLANK(Completed_Date__c) → "Completed Date is required when status is Completed."
- [ ] 2.3.4 Deploy Quest_Enrollment__c.
- [ ] 2.3.5 Verify all 3 new objects via EntityDefinition SOQL.

### Gate 2 Exit Criteria

- All 3 objects deployed without errors.
- Discovery__c lookups to Trailblazer_Profile__c and Certification__c confirmed.
- Quest__c formula field Is_Active__c confirmed as Formula type.
- Quest_Enrollment__c M-D to profile confirmed.
- Full dry-run deploy of entire project passes: deploy_metadata with dry-run.

---

## GATE 3 — Configuration Metadata

Skill: admin-config  
Depends on: Gate 1 (CMT field references align with object fields)  
Objective: Create all three Custom Metadata Types and their seed records. All configurable thresholds must be in CMTs — no hardcoded values.

### Tool Calls

| Step | MCP Tool | Purpose |
|---|---|---|
| 3.1 | deploy_metadata | Deploy CMT type definitions (objects) |
| 3.2 | deploy_metadata | Deploy CMT seed records (customMetadata/) |
| 3.3 | run_soql_query | Verify Level_Definition__mdt seed count = 12 |
| 3.4 | run_soql_query | Verify XP_Rule__mdt seed count = 8 |
| 3.5 | run_soql_query | Verify Achievement_Definition__mdt seed count = 20 |
| 3.6 | run_soql_query | Verify Streak_Config__mdt seed count ≥ 1 |

### TODO Items — US-1.5: Level_Definition__mdt

- [ ] 3.1.1 Create force-app/main/default/objects/Level_Definition__mdt/Level_Definition__mdt.object-meta.xml with fields:
  - Level_Number__c: Number(18,0), required.
  - XP_Threshold__c: Number(18,0), required.
  - Rank_Name__c: Text(255).
  - Badge_Icon_URL__c: Url(255).
  - Description__c: Text(255).
- [ ] 3.1.2 Create 12 seed records: force-app/main/default/customMetadata/Level_Definition__mdt.Level_1.md-meta.xml … Level_12 with thresholds: 0, 500, 1500, 3500, 7500, 15000, 25000, 40000, 60000, 85000, 115000, 150000. Rank names map Scout → … → All Star Ranger.

### TODO Items — US-1.5: XP_Rule__mdt

- [ ] 3.2.1 Create force-app/main/default/objects/XP_Rule__mdt/XP_Rule__mdt.object-meta.xml with fields:
  - Action_Type__c: Text(255), required. Values used: Badge_Earned, Cert_Earned, Streak_Day, Discovery_Added, Quest_Completed.
  - XP_Value__c: Number(18,0), required.
  - Multiplier_Conditions__c: Text(255).
- [ ] 3.2.2 Create 8 seed records under force-app/main/default/customMetadata/: XP_Rule__mdt.Badge_Earned_Module, XP_Rule__mdt.Badge_Earned_Superbadge, XP_Rule__mdt.Badge_Earned_Project, XP_Rule__mdt.Badge_Earned_Event, XP_Rule__mdt.Cert_Earned, XP_Rule__mdt.Streak_Day, XP_Rule__mdt.Discovery_Added, XP_Rule__mdt.Quest_Completed.

### TODO Items — US-1.5: Achievement_Definition__mdt

- [ ] 3.3.1 Create force-app/main/default/objects/Achievement_Definition__mdt/Achievement_Definition__mdt.object-meta.xml with fields:
  - Achievement_Name__c: Text(255), required.
  - Criteria_Type__c: Text(255). Valid values: Badge_Count, Streak_Days, Cert_Count, Superbadge_Count, Points_Threshold.
  - Criteria_Value__c: Number(18,0).
  - Icon_URL__c: Url(255).
  - Description__c: Text(255).
- [ ] 3.3.2 Create 20 seed records under force-app/main/default/customMetadata/ using US-3.2 table + 10 additional meaningful achievements. Ensure Criteria_Type__c is in the valid set and Criteria_Value__c is populated.

### TODO Items — US-1.6: Streak_Config__mdt

- [ ] 3.4.1 Create force-app/main/default/objects/Streak_Config__mdt/Streak_Config__mdt.object-meta.xml with fields:
  - Qualifying_Action__c: Text(255).
  - Min_Actions_Per_Day__c: Number(18,0), default 1.
  - Freeze_Allowed__c: Checkbox, default true.
  - Max_Freeze_Days__c: Number(18,0), default 2.
  - Streak_Bonus_XP__c: Number(18,0).
  - Milestone_Days__c: Text(255), default "7,30,50,100".
- [ ] 3.4.2 Create 1 seed record: force-app/main/default/customMetadata/Streak_Config__mdt.Default_Streak_Config.md-meta.xml with sensible defaults.

### Gate 3 Exit Criteria

- deploy_metadata succeeds for all CMT type definitions and seed records.
- SELECT COUNT() FROM Level_Definition__mdt returns 12.
- SELECT COUNT() FROM XP_Rule__mdt returns 8.
- SELECT COUNT() FROM Achievement_Definition__mdt returns 20.
- SELECT COUNT() FROM Streak_Config__mdt returns ≥ 1.
- All CMT Action_Type__c / Criteria_Type__c values match the enumerated lists (case-sensitive).

---

## GATE 4 — Deploy, Verify & DevOps Hardening

Skill: sf-devops  
Depends on: Gates 1–3  
Objective: Full project deploy, end-to-end verification, and completion of the DevOps scaffold begun in Gate 0.

### Tool Calls

| Step | MCP Tool | Purpose |
|---|---|---|
| 4.1 | deploy_metadata | Full dry-run deploy of entire project |
| 4.2 | deploy_metadata | Full live deploy |
| 4.3 | run_soql_query | Object existence check — all 7 custom objects |
| 4.4 | run_soql_query | CMT seed data verification queries |
| 4.5 | run_soql_query | Validation rule existence checks |
| 4.6 | run_soql_query | External ID field confirmation |
| 4.7 | run_soql_query | List view existence checks |
| 4.8 | run_soql_query | Tab existence check |

### TODO Items — Schema Verification Queries

Run each of the following run_soql_query calls and confirm expected results:

- [ ] 4.1 SELECT QualifiedApiName FROM EntityDefinition WHERE QualifiedApiName IN ('Trailblazer_Profile__c','Badge__c','Certification__c','Discovery__c','Quest__c','Quest_Enrollment__c') → must return 6 rows.
- [ ] 4.2 SELECT COUNT() FROM Level_Definition__mdt → 12.
- [ ] 4.3 SELECT COUNT() FROM XP_Rule__mdt → 8.
- [ ] 4.4 SELECT COUNT() FROM Achievement_Definition__mdt → 20.
- [ ] 4.5 SELECT DeveloperName, Criteria_Type__c, Criteria_Value__c FROM Achievement_Definition__mdt ORDER BY Criteria_Value__c → review all 20; confirm all Criteria_Type__c values are valid.
- [ ] 4.6 SELECT DeveloperName, Action_Type__c, XP_Value__c FROM XP_Rule__mdt → confirm 8 records with non-null XP_Value__c.
- [ ] 4.7 SELECT ValidationName FROM ValidationRule WHERE EntityDefinition.QualifiedApiName IN ('Certification__c','Discovery__c','Quest__c','Quest_Enrollment__c') → must return at least 4 rows.
- [ ] 4.8 SELECT QualifiedApiName, IsIdLookup FROM FieldDefinition WHERE IsIdLookup = true AND EntityDefinition.QualifiedApiName IN ('Trailblazer_Profile__c','Badge__c','Certification__c') → confirm 3 external ID fields exist.
- [ ] 4.9 SELECT Name, SobjectType FROM ListView WHERE SobjectType IN ('Trailblazer_Profile__c','Badge__c','Certification__c','Quest__c') → confirm list views exist across all 4 object types.

### TODO Items — DevOps Scaffold Completion

- [ ] 4.10 Complete scripts/setup.sh with real sf CLI commands. Include: sf project deploy start, sf org assign permset --name Trailblazer_Admin, and a stub for seed data insert (Apex anonymous placeholder).
- [ ] 4.11 Complete scripts/validate.sh with failure condition parsing: check deployment JSON output for "numberTestErrors": 0 and "success": true. Exit 1 on failure.
- [ ] 4.12 Update README.md with actual setup steps now that the project skeleton is real.
- [ ] 4.13 Run full dry-run deploy: deploy_metadata targeting entire force-app/main/default/ directory with dry-run flag. Must return 0 errors, 0 test failures.

### Gate 4 Exit Criteria (Phase 1 Complete)

- Full dry-run deploy returns 0 component errors.
- All 8 SOQL verification queries return expected counts.
- All 4 validation rules exist.
- 3 external ID fields confirmed.
- List views exist for all specified objects.
- scripts/setup.sh, scripts/validate.sh, scripts/deploy.sh exist and are executable.
- README.md contains complete setup instructions.

---

## Acceptance Criteria Test Matrix

The following table maps each story's acceptance criteria to the verification query or manual check performed in Gate 4. These are the pass/fail assertions that confirm Phase 1 is complete.

| Story | Acceptance Criterion | Verification Method | Gate |
|---|---|---|---|
| US-8.1 | config/project-scratch-def.json exists with Developer edition | File exists, valid JSON | Gate 0 |
| US-8.1 | SFDX project structure correct | force-app/main/default/ subfolders exist | Gate 0 |
| US-8.1 | scripts/setup.sh exists and is executable | File check | Gate 4 |
| US-1.1 | Trailblazer_Profile__c exists | EntityDefinition SOQL | Gate 1 |
| US-1.1 | 14 custom fields present | FieldDefinition COUNT SOQL | Gate 1 |
| US-1.1 | Trailhead_Id__c is external ID | FieldDefinition IsIdLookup | Gate 1 |
| US-1.1 | sharingModel = Private | Object metadata inspection | Gate 1 |
| US-1.1 | Compact layout with 5 fields | deploy_metadata success | Gate 1 |
| US-1.1 | 3 list views created | ListView SOQL | Gate 4 |
| US-1.1 | Tab exists | deploy_metadata + Tab SOQL | Gate 1 |
| US-1.2 | Badge__c M-D to Profile | FieldDefinition DataType | Gate 1 |
| US-1.2 | Trailhead_Badge_Id__c external ID | FieldDefinition IsIdLookup | Gate 1 |
| US-1.2 | Allow Reports enabled | EntityDefinition | Gate 1 |
| US-1.2 | 2 list views | ListView SOQL | Gate 4 |
| US-1.3 | Certification__c M-D to Profile | FieldDefinition DataType | Gate 1 |
| US-1.3 | Cert_Id__c external ID | FieldDefinition IsIdLookup | Gate 1 |
| US-1.3 | Validation rule: expiry after earned | ValidationRule SOQL | Gate 1 |
| US-1.3 | 2 list views | ListView SOQL | Gate 4 |
| US-1.4 | Discovery__c Lookup (not M-D) to Profile | FieldDefinition DataType | Gate 2 |
| US-1.4 | Lookup to Certification__c present | FieldDefinition SOQL | Gate 2 |
| US-1.4 | Rating validation rule exists | ValidationRule SOQL | Gate 2 |
| US-1.5 | Level_Definition__mdt has 5 fields | CMT object metadata | Gate 3 |
| US-1.5 | 12 Level seed records | COUNT SOQL on CMT | Gate 3 |
| US-1.5 | 8 XP_Rule seed records | COUNT SOQL on CMT | Gate 3 |
| US-1.5 | 20 Achievement_Definition records | COUNT SOQL on CMT | Gate 3 |
| US-1.5 | All seed data in SFDX source | File existence check | Gate 3 |
| US-1.6 | Streak_Config__mdt has 6 fields | CMT object metadata | Gate 3 |
| US-1.6 | Default streak config record exists | COUNT SOQL on CMT | Gate 3 |
| US-1.6 | Quest__c formula Is_Active__c | FieldDefinition DataType=Formula | Gate 2 |
| US-1.6 | Quest_Enrollment__c M-D to Profile | FieldDefinition DataType | Gate 2 |
| US-1.6 | Quest_Enrollment__c Completed_Date validation | ValidationRule SOQL | Gate 2 |

---

## NFR Verification

All NFRs must be explicitly verified before Phase 1 is signed off.

| NFR | Story | Verification |
|---|---|---|
| Field-level help text on all fields | US-1.1 | Inspect deployed field metadata — every field must have non-empty inlineHelpText |
| Accessible field labels (no abbreviations) | US-1.1 | Review all field labels — reject abbreviations like "Ttl Pts" |
| Bulk insert performance <5s for 100 Badge records | US-1.2 | Phase 2 load test (flagged here as dependency for Phase 2 test design) |
| Certification data refreshes at least daily | US-1.3 | Confirmed via batch scheduler in Phase 2; data model supports it (Last_Sync_Date__c) |
| Mobile-optimized page layout for Discovery | US-1.4 | Verify compact layout exists and page layout has phone/tablet column settings |
| All CMT seed data in SFDX source | US-1.5 | ls force-app/main/default/customMetadata/ — 41 files (12 + 8 + 20 + 1) |
| Quest evaluation handles 500+ enrollments | US-1.6 | Phase 2 batch design dependency; schema supports bulk (no per-record anti-patterns) |

---

## Non-Goals for Phase 1

- No Apex classes, triggers, or test classes (Phase 2+)
- No Lightning Web Components or Aura components
- No FlexiPages or Lightning App configuration (Phase 6)
- No Permission Sets or sharing rules (Phase 5)
- No Streak_Freeze__c object (Phase 3 — US-3.3)
- No XP_Transaction__c object (Phase 3 — US-3.1)
- No Earned_Achievement__c object (Phase 3 — US-3.2)
- No Study_Group__c or Study_Group_Member__c objects (Phase 4 — US-4.1)
- No Integration_Log__c object (Phase 2 — US-2.1)
- No Named Credentials or Remote Site Settings (Phase 2)

---

## Phase 1 Artefact Checklist

On completion the following files must exist under force-app/main/default/:

```
objects/
  Trailblazer_Profile__c/
    Trailblazer_Profile__c.object-meta.xml
    fields/  (14 field files)
    listViews/  (3 list view files)
    compactLayouts/  (1 compact layout)
  Badge__c/
    Badge__c.object-meta.xml
    fields/  (9 field files)
    listViews/  (2 list view files)
    compactLayouts/  (1 compact layout)
  Certification__c/
    Certification__c.object-meta.xml
    fields/  (7 field files)
    validationRules/  (1 validation rule)
    listViews/  (2 list view files)
    compactLayouts/  (1 compact layout)
  Discovery__c/
    Discovery__c.object-meta.xml
    fields/  (8 field files)
    validationRules/  (1 validation rule)
  Quest__c/
    Quest__c.object-meta.xml
    fields/  (9 field files)
    validationRules/  (1 validation rule)
    listViews/  (2 list view files)
  Quest_Enrollment__c/
    Quest_Enrollment__c.object-meta.xml
    fields/  (6 field files)
    validationRules/  (1 validation rule)
customMetadata/
  Level_Definition__mdt.Level_1.md-meta.xml  (through Level_12)
  XP_Rule__mdt.Badge_Earned_Module.md-meta.xml  (8 files)
  Achievement_Definition__mdt.First_Steps.md-meta.xml  (20 files)
  Streak_Config__mdt.Default_Streak_Config.md-meta.xml
tabs/
  Trailblazer_Profile__c.tab-meta.xml
  Quest__c.tab-meta.xml
config/
  project-scratch-def.json
scripts/
  setup.sh
  validate.sh
  deploy.sh
sfdx-project.json
.forceignore
README.md
