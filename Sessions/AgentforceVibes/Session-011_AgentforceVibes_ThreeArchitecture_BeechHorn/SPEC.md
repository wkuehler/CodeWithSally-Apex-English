# SPEC.md — Trailhead Gamified Learning Platform

## Table of Contents

- [1. Personas](#1-personas)
- [2. Epics & User Stories](#2-epics--user-stories)
- [3. Project Plan](#3-project-plan)
- [4. Research Sources](#4-research-sources)

---

## 1. Personas

### P1: New Trailblazer ("Nadia")

- **Role:** Career switcher, 0–20 badges, Scout/Hiker rank
- **Goals:** Understand Salesforce ecosystem, build first app, reach Explorer rank
- **Pain points:** Overwhelmed by content volume, no structure, doesn't know which badges matter for jobs
- **Motivation drivers:** Autonomy (choose own path), Competence (visible progress), Relatedness (community belonging) — per SDT (Ryan & Deci, 2000)
- **Key insight:** Needs guided onboarding and early wins to build confidence before self-directed learning

### P2: Aspiring Admin ("Amir")

- **Role:** Jr. Admin studying for Admin cert, 20–80 badges, Explorer/Mountaineer rank
- **Goals:** Pass Admin certification, build portfolio of hands-on projects, reach Ranger
- **Pain points:** Gaps between Trailhead theory and real-world scenarios, certification anxiety, inconsistent study habits
- **Motivation drivers:** Streak mechanics for daily habit formation (66 days to form a habit — Phillippa Lally, UCL), social accountability (#100DaysOfTrailhead pattern), milestone-based progression
- **Key insight:** Benefits most from study plans, cert-prep tracking, and peer accountability

### P3: Senior Trailblazer ("Sofia")

- **Role:** 3x+ Ranger, multiple certs, community group leader
- **Goals:** Maintain certs, mentor others, compete on leaderboards, earn All Star Ranger
- **Pain points:** Cert maintenance tracking is fragmented, no recognition for mentoring, leaderboard data stale
- **Motivation drivers:** Competition (leaderboards), Social identity (community status), Mastery (new cloud/product areas)
- **Key insight:** Drives community engagement; platform must recognise and reward mentorship behaviours

### P4: Team Lead ("Tariq")

- **Role:** Salesforce practice manager overseeing 5–20 learners
- **Goals:** Track team progress, identify skill gaps, drive cert attainment across team
- **Pain points:** Manual spreadsheet tracking, no dashboard for team-level Trailhead progress, can't correlate learning with job readiness
- **Motivation drivers:** Team performance visibility, ROI justification for training time
- **Key insight:** Needs aggregate dashboards and the ability to assign/track learning paths per team member

---

## 2. Epics & User Stories

### Epic 1: Foundation Data Model

> Establish core objects extending the base Trailhead module's `Discovery` object into a full learning-tracking platform.

---

#### US-1.1: Create Trailblazer Profile Object

**As** any persona, **I want** a central profile record linking my Salesforce user to my Trailhead identity **so that** all progress is tracked in one place.

**Acceptance Criteria:**
- Custom object `Trailblazer_Profile__c` with fields: `Trailhead_Username__c` (Text, unique, required), `Trailhead_Id__c` (Text, external ID), `Current_Rank__c` (Picklist: Scout/Hiker/Explorer/Adventurer/Mountaineer/Expeditioner/Ranger/Double Star Ranger/Triple Star Ranger/Four Star Ranger/Five Star Ranger/All Star Ranger), `Total_Points__c` (Number), `Total_Badges__c` (Number), `Total_Certifications__c` (Number), `Total_Superbadges__c` (Number), `Current_Streak__c` (Number), `Longest_Streak__c` (Number), `Last_Badge_Date__c` (Date), `Last_Sync_Date__c` (DateTime), `XP_Total__c` (Number), `Current_Level__c` (Number)
- Lookup to User (`User__c`)
- Compact layout showing rank, points, badges, streak
- List view: "My Profile", "All Trailblazers", "Top Streaks"
- Tab created and added to app navigation

**Technical Considerations:**
- External ID on `Trailhead_Id__c` for upsert operations during sync
- Roll-up summary fields may require trigger-based calculation since no M-D to User
- `Current_Streak__c` and `Longest_Streak__c` computed by scheduled Apex

**NFRs:** Field-level help text on all fields; accessible field labels (no abbreviations)

**Skills:** `admin-schema`

---

#### US-1.2: Create Badge Tracking Object

**As** Nadia/Amir, **I want** each earned Trailhead badge stored as a record **so that** I can see my full badge history and filter by type.

**Acceptance Criteria:**
- Custom object `Badge__c` (Master-Detail to `Trailblazer_Profile__c`)
- Fields: `Badge_Title__c` (Text), `Badge_Type__c` (Picklist: Module/Project/Superbadge/Event), `Trailhead_Badge_Id__c` (Text, external ID, unique), `Earned_Date__c` (Date), `Points_Earned__c` (Number), `Icon_URL__c` (URL), `Trailhead_URL__c` (URL), `Description__c` (Long Text Area)
- Allow Reports enabled
- List views: "Recent Badges" (sorted by Earned_Date desc), "Superbadges Only"

**Technical Considerations:**
- Master-Detail enables roll-up summaries on `Trailblazer_Profile__c` for `Total_Badges__c`
- External ID for upsert during GraphQL sync (avoid duplicates)
- Expect 100–1200+ records per profile; list view pagination essential

**NFRs:** Bulk insert performance <5s for 100 records

**Skills:** `admin-schema`

---

#### US-1.3: Create Certification Tracking Object

**As** Amir/Sofia, **I want** my Salesforce certifications tracked **so that** I can monitor expiry/maintenance status.

**Acceptance Criteria:**
- Custom object `Certification__c` (Master-Detail to `Trailblazer_Profile__c`)
- Fields: `Cert_Name__c` (Text), `Cert_Id__c` (Text, external ID), `Status__c` (Picklist: Active/Expired/Maintenance Due), `Date_Earned__c` (Date), `Date_Expires__c` (Date), `Maintenance_Due_Date__c` (Date)
- Validation rule: `Date_Expires__c` must be after `Date_Earned__c`
- List view: "Active Certs", "Maintenance Due"

**Technical Considerations:**
- `Status__c` may be computed by formula or scheduled batch based on dates
- GraphQL query `getUserCertifications` returns cert data with status

**NFRs:** Certification data must refresh at least daily

**Skills:** `admin-schema`

---

#### US-1.4: Create Discovery Object (Extended)

**As** Nadia, **I want** to track learning resources I discover **so that** I can build a personal knowledge base.

**Acceptance Criteria:**
- Custom object `Discovery__c` (Lookup to `Trailblazer_Profile__c`)
- Fields: `Discovery_Name` (standard Name field), `Type__c` (Picklist: Module/Blog/Video/Documentation/Community Post/Other, required), `URL__c` (URL), `Notes__c` (Long Text Area), `Rating__c` (Number 1–5), `Related_Certification__c` (Lookup to `Certification__c`), `Tags__c` (Text)
- This extends the base Trailhead project's Discovery object with rating, cert linkage, and tags

**Technical Considerations:**
- Lookup (not M-D) allows discoveries without a profile
- `Tags__c` as comma-separated text for Phase 1; refactor to junction object in Phase 3 if needed

**NFRs:** Mobile-optimized page layout

**Skills:** `admin-schema`

---

#### US-1.5: Create XP & Level Configuration Metadata

**As** a platform admin, **I want** XP thresholds and level definitions stored as configurable metadata **so that** I can tune the gamification system without code changes.

**Acceptance Criteria:**
- Custom Metadata Type `Level_Definition__mdt` with fields: `Level_Number__c` (Number), `XP_Threshold__c` (Number), `Rank_Name__c` (Text), `Badge_Icon_URL__c` (URL), `Description__c` (Text)
- Custom Metadata Type `XP_Rule__mdt` with fields: `Action_Type__c` (Text: Badge_Earned/Cert_Earned/Streak_Day/Discovery_Added/Quest_Completed), `XP_Value__c` (Number), `Multiplier_Conditions__c` (Text, JSON-compatible)
- Custom Metadata Type `Achievement_Definition__mdt` with fields: `Achievement_Name__c` (Text), `Criteria_Type__c` (Text: Badge_Count/Streak_Days/Cert_Count/Superbadge_Count/Points_Threshold), `Criteria_Value__c` (Number), `Icon_URL__c` (URL), `Description__c` (Text)
- Seed data: 12 levels, 8 XP rules, 20 initial achievements

**Technical Considerations:**
- CMTs are deployable via SFDX and readable in Apex without SOQL limits
- `Multiplier_Conditions__c` allows future extensibility (e.g., 2x XP during quests)

**NFRs:** All seed data included in SFDX source for reproducible deploys

**Skills:** `admin-config`

---

#### US-1.6: Create Streak & Quest Configuration Metadata

**As** a platform admin, **I want** streak rules and quest definitions configurable **so that** I can launch new challenges without deployments.

**Acceptance Criteria:**
- Custom Metadata Type `Streak_Config__mdt` with fields: `Qualifying_Action__c` (Text), `Min_Actions_Per_Day__c` (Number), `Freeze_Allowed__c` (Checkbox), `Max_Freeze_Days__c` (Number), `Streak_Bonus_XP__c` (Number, awarded at milestones), `Milestone_Days__c` (Text, comma-separated: "7,30,50,100")
- Custom object `Quest__c` with fields: `Quest_Name__c` (Text), `Description__c` (Rich Text), `Start_Date__c` (Date), `End_Date__c` (Date), `Criteria_Type__c` (Picklist: Badge_Count/Trail_Completion/Cert_Earned/Custom), `Criteria_Value__c` (Number), `Reward_Description__c` (Text), `Is_Active__c` (Formula: today between start/end), `XP_Reward__c` (Number)
- Junction object `Quest_Enrollment__c` (M-D to `Trailblazer_Profile__c`, Lookup to `Quest__c`) with fields: `Enrolled_Date__c` (Date), `Status__c` (Picklist: In Progress/Completed/Expired), `Completed_Date__c` (Date), `Progress_Count__c` (Number)

**Technical Considerations:**
- `Quest__c` is a standard object (not CMT) because quests are time-bound data records, not configuration
- `Quest_Enrollment__c` needs trigger to evaluate completion criteria on badge sync

**NFRs:** Quest evaluation must handle 500+ enrollments in a single batch window

**Skills:** `admin-schema`, `admin-config`

---

### Epic 2: Trailhead API Sync Engine

> Automated data synchronisation from public Trailhead GraphQL API into Salesforce objects.

---

#### US-2.1: Trailhead GraphQL Callout Service

**As** any persona, **I want** my Trailhead data synced automatically **so that** my profile stays current without manual entry.

**Acceptance Criteria:**
- Apex class `TrailheadApiService` performing HTTP POST to `https://profile.api.trailhead.com/graphql`
- Methods: `fetchRankData(String trailheadId)`, `fetchBadges(String trailheadId, Integer count, String afterCursor)`, `fetchCertifications(String trailheadId)`
- Returns strongly-typed wrapper classes (`TrailheadRankData`, `TrailheadBadgeResult`, `TrailheadCertResult`)
- Handles pagination (loop until `hasNextPage == false`)
- Named Credential `Trailhead_API` stored in `API_Endpoint__mdt` Custom Metadata
- Error handling: retry once on 5xx, log all failures to `Integration_Log__c`

**Technical Considerations:**
- GraphQL queries modelled on [nabondance/Trailhead-Banner](https://github.com/nabondance/Trailhead-Banner/tree/main/src/graphql/queries) patterns
- `queryProfile: true` must be included in all requests
- Badge filter values: MODULE, SUPERBADGE, PROJECT, EVENT
- Response parsing via `JSON.deserializeUntyped()` due to dynamic GraphQL schema
- Remote Site Setting for `profile.api.trailhead.com`

**NFRs:**
- Callout timeout: 30s
- Max 10 paginated requests per sync (circuit breaker)
- All PII limited to Trailhead username (publicly available)

**Skills:** `apex-class-generator`

---

#### US-2.2: Batch Sync Job

**As** Tariq, **I want** all team members' Trailhead data refreshed daily **so that** dashboards reflect current progress.

**Acceptance Criteria:**
- Batchable Apex `TrailheadSyncBatch` implements `Database.Batchable<SObject>, Database.AllowsCallouts, Schedulable`
- Queries all `Trailblazer_Profile__c` records with `Trailhead_Username__c != null`
- For each profile: fetch rank, badges (paginated), certifications
- Upsert `Badge__c` on `Trailhead_Badge_Id__c`, upsert `Certification__c` on `Cert_Id__c`
- Update profile roll-up fields: `Total_Points__c`, `Total_Badges__c`, `Total_Certifications__c`, `Total_Superbadges__c`, `Current_Rank__c`, `Last_Badge_Date__c`, `Last_Sync_Date__c`
- Schedulable: default run at 02:00 UTC daily
- Batch size: 1 (callout limitation per transaction)

**Technical Considerations:**
- `Database.AllowsCallouts` required for HTTP in batch
- Batch size of 1 due to callout limits (100 callouts per txn, but pagination may consume many)
- Consider `Queueable` chaining as alternative for large orgs
- `Integration_Log__c` records for each sync attempt (success/fail/records processed)

**NFRs:**
- Complete sync for 200 profiles within 2-hour window
- Graceful handling of Trailhead API downtime (skip, log, continue)
- No partial updates — profile update is all-or-nothing per user

**Skills:** `apex-class-generator`

---

#### US-2.3: On-Demand Sync Action

**As** Amir, **I want** to manually trigger a sync of my profile **so that** I see my latest badge immediately after earning it.

**Acceptance Criteria:**
- Invocable Apex method `TrailheadSyncService.syncProfile(List<Id> profileIds)`
- Callable from Flow, Quick Action, or button
- Screen Flow with "Sync Now" button on `Trailblazer_Profile__c` record page
- Toast notification on completion: "Synced {n} badges, {n} certs"
- Rate limit: max 1 manual sync per profile per 5 minutes (tracked via `Last_Sync_Date__c`)

**Technical Considerations:**
- Invocable must be `@future(callout=true)` or Queueable for callout context
- Flow launches the invocable; result displayed via platform event or polling

**NFRs:** Sync completes within 15 seconds for typical profile (≤500 badges)

**Skills:** `apex-class-generator`, `admin-appbuilder`

---

#### US-2.4: Sync Integration Tests

**As** a developer, **I want** comprehensive test coverage for the sync engine **so that** API changes are caught before deployment.

**Acceptance Criteria:**
- `TrailheadApiService_Test`: Mock HTTP callouts with `HttpCalloutMock`, test rank/badge/cert parsing, test pagination handling, test error/retry logic
- `TrailheadSyncBatch_Test`: Test batch execution with mock callouts, verify upsert correctness, verify roll-up field updates
- `TrailheadSyncService_Test`: Test invocable method, test rate limiting
- `TestDataFactory`: methods for `Trailblazer_Profile__c`, `Badge__c`, `Certification__c` with realistic test data
- All tests: ≥95% coverage per class, no hardcoded IDs, `System.runAs` for user context

**Technical Considerations:**
- Use `StaticResource` for sample GraphQL JSON responses
- Multi-page response mock (simulate `hasNextPage: true` then `false`)

**NFRs:** All tests run in <30 seconds total

**Skills:** `apex-test`

---

### Epic 3: XP, Levels & Achievements Engine

> Internal gamification layer that rewards learning actions with XP, levels, and unlockable achievements.

**Research basis:**
- SDT (Ryan & Deci, 2000): Competence need satisfied by visible progression
- Gamification meta-analysis (Bai et al., 2024): Small but significant effect (g=0.257) on intrinsic motivation when competence need met
- Streak mechanics: Loss aversion makes users 2.3x more likely to engage daily after 7+ day streak (Duolingo internal data, cited by Plotline 2025)
- Apps combining streaks + milestones see 40–60% higher DAU (Plotline 2025)

---

#### US-3.1: XP Calculation Service

**As** any persona, **I want** to earn XP for learning actions **so that** I see tangible progress beyond Trailhead points.

**Acceptance Criteria:**
- Apex class `XPService` with method `awardXP(Id profileId, String actionType, Map<String, Object> context)`
- Reads `XP_Rule__mdt` for base XP value per action type
- Applies multipliers from `Multiplier_Conditions__c` (e.g., 2x during active quest)
- Updates `Trailblazer_Profile__c.XP_Total__c`
- Evaluates level-up: compares new XP total against `Level_Definition__mdt` thresholds
- Updates `Trailblazer_Profile__c.Current_Level__c` if threshold crossed
- Creates `XP_Transaction__c` record: `Profile__c` (M-D), `Action_Type__c`, `XP_Amount__c`, `Transaction_Date__c`, `Notes__c`

**Technical Considerations:**
- Called by badge sync trigger, discovery insert trigger, streak calculator, quest completion
- Must be bulkified — receive list of profile IDs
- CMT query is SOQL-free (uses `getAll()` method)

**NFRs:** Process 200 XP awards in single transaction within governor limits

**Skills:** `apex-class-generator`, `admin-schema` (for `XP_Transaction__c`)

---

#### US-3.2: Achievement Evaluation Engine

**As** Amir, **I want** to unlock achievements when I hit milestones **so that** I feel recognised for significant accomplishments.

**Acceptance Criteria:**
- Apex class `AchievementService` with method `evaluateAchievements(Set<Id> profileIds)`
- Reads `Achievement_Definition__mdt` for all defined achievements
- For each profile: checks criteria (badge count, streak days, cert count, etc.) against profile fields
- Creates `Earned_Achievement__c` (M-D to `Trailblazer_Profile__c`): `Achievement_Name__c`, `Earned_Date__c`, `Definition_Id__c` (Text, CMT DeveloperName)
- Does not re-award already-earned achievements (check existing `Earned_Achievement__c` records)
- Awards XP bonus for each new achievement via `XPService`

**Technical Considerations:**
- Triggered after sync batch, XP award, or streak update
- Bulk-safe: collect all profile IDs, single query for existing achievements, batch insert new ones
- Initial 20 achievements (see seed data in US-1.5)

**Example achievements:**
| Name | Criteria |
|---|---|
| First Steps | 1 badge earned |
| Trailhead Explorer | 25 badges |
| Century Club | 100 badges |
| Streak Starter | 7-day streak |
| Streak Master | 30-day streak |
| Centurion | 100-day streak |
| Certified Professional | 1 certification |
| Multi-Certified | 3 certifications |
| Superbadge Hero | 5 superbadges |
| Quest Completer | 1 quest completed |

**NFRs:** Evaluate 500 profiles in <60 seconds batch execution

**Skills:** `apex-class-generator`, `admin-schema` (for `Earned_Achievement__c`)

---

#### US-3.3: Streak Calculator

**As** Amir, **I want** my learning streak tracked daily **so that** I build a consistent study habit.

**Acceptance Criteria:**
- Apex class `StreakService` with method `calculateStreaks(Set<Id> profileIds)`
- Reads `Streak_Config__mdt` for qualifying action and rules
- Queries `Badge__c` for badges earned yesterday (by `Earned_Date__c`) per profile
- If qualifying action found: increment `Current_Streak__c`, update `Longest_Streak__c` if new max
- If no qualifying action and freeze available: decrement available freezes, streak maintained
- If no qualifying action and no freeze: reset `Current_Streak__c` to 0
- Award milestone XP at streak milestones (7, 30, 50, 100 days) per `Streak_Config__mdt`
- Scheduled to run daily at 03:00 UTC (after sync completes)

**Technical Considerations:**
- Create `Streak_Freeze__c` object: `Profile__c` (M-D), `Used_Date__c` (Date), to track freeze usage
- Max freezes per month configurable in `Streak_Config__mdt`
- Must handle timezone edge cases (learner in UTC-12 vs UTC+12)

**NFRs:** Process 1000 profiles in single batch within governor limits

**Skills:** `apex-class-generator`, `admin-schema` (for `Streak_Freeze__c`)

---

#### US-3.4: Gamification Engine Tests

**As** a developer, **I want** full test coverage of XP, achievements, and streaks **so that** gamification logic is regression-proof.

**Acceptance Criteria:**
- `XPService_Test`: Test XP award for each action type, multiplier logic, level-up transition, bulk operations, negative tests (invalid action type)
- `AchievementService_Test`: Test earning first achievement, no re-award, bulk evaluation, edge cases (exactly at threshold)
- `StreakService_Test`: Test increment, reset, freeze usage, milestone XP, longest streak update
- All tests use `TestDataFactory` for profiles, badges, certs
- ≥95% coverage per class

**NFRs:** All tests isolated, no inter-test dependencies

**Skills:** `apex-test`

---

### Epic 4: Study Groups & Social Features

> Social structures enabling accountability, collaboration, and community — key driver of the Relatedness need (SDT).

**Research basis:**
- 100 Days of Trailhead (2017–2022): Originated from #100DaysOfCode by Alexander Kallaway. Jessica Murphy & Rachel Watson adapted it for the Trailblazer Community. Participants committed to 1 hour/day for 100 consecutive days, tweeting daily progress. 650+ community tweets in 2018 alone. Accountability partners and leaderboards via toptrailblazers.com drove persistence (100daysoftrailhead.com).
- SDT Relatedness: Meta-analysis shows gamification enhances perceived autonomy and relatedness but minimal impact on competence alone (Bai et al., 2024, Educational Technology R&D)
- Social accountability: Public commitment increases follow-through (Cialdini, "Influence", commitment/consistency principle)

---

#### US-4.1: Study Group Object

**As** Amir, **I want** to join a study group **so that** I learn with peers and stay accountable.

**Acceptance Criteria:**
- Custom object `Study_Group__c`: `Group_Name__c` (Text, required), `Description__c` (Rich Text), `Goal__c` (Text, e.g., "Admin Cert by March"), `Start_Date__c` (Date), `End_Date__c` (Date), `Max_Members__c` (Number, default 10), `Is_Active__c` (Formula), `Owner` (standard, group creator)
- Junction object `Study_Group_Member__c` (M-D to `Study_Group__c`, Lookup to `Trailblazer_Profile__c`): `Role__c` (Picklist: Leader/Member), `Joined_Date__c` (Date)
- Validation rule: Cannot exceed `Max_Members__c`
- List views: "My Groups", "Active Groups", "Open Groups"

**Technical Considerations:**
- Validation rule on `Study_Group_Member__c` requires trigger-based count check (roll-up + VR)
- OR use before-insert trigger to enforce max members with locking

**NFRs:** Group membership changes reflected immediately (no async delay)

**Skills:** `admin-schema`

---

#### US-4.2: Group Leaderboard & Progress

**As** Sofia, **I want** to see a leaderboard within my study group **so that** healthy competition drives engagement.

**Acceptance Criteria:**
- Report type: `Study_Group_Member__c` with `Trailblazer_Profile__c` (cross-object)
- Report: "Group Leaderboard" showing member name, badges earned (period), streak length, XP earned
- Dashboard component: Bar chart of group member XP
- FlexiPage component on `Study_Group__c` record page: embedded report chart

**Technical Considerations:**
- Report date filtering for "since group start date" requires relative date formula or report filter
- Dashboard refresh frequency: daily (aligned with sync)

**NFRs:** Dashboard loads in <3 seconds

**Skills:** `admin-appbuilder`

---

#### US-4.3: Study Group Tests

**As** a developer, **I want** tests for group membership enforcement **so that** max-member validation is reliable.

**Acceptance Criteria:**
- `StudyGroupMember_Test`: Test max member enforcement, test role assignment, test joining/leaving
- Trigger handler tests for member count validation
- `System.runAs` tests for member vs leader permissions

**NFRs:** ≥95% coverage

**Skills:** `apex-test`

---

### Epic 5: Lightning App & User Experience

> Declarative UI layer bringing all data together in a cohesive Lightning App experience.

---

#### US-5.1: Lightning App Creation

**As** any persona, **I want** a dedicated Lightning App **so that** all learning features are in one place.

**Acceptance Criteria:**
- Lightning App: "Trailblazer Journey" with custom branding (Trailhead colour palette: #032D60 navy, #1B96FF blue, #04844B green)
- Navigation items: Home, My Profile (Trailblazer_Profile__c), Badges, Certifications, Discoveries, Study Groups, Quests, Achievements, Reports, Dashboards
- Utility bar: Streak counter (if feasible declaratively, else Phase 3)
- Assigned to profiles: System Administrator, Standard User, Custom "Trailblazer" profile

**Technical Considerations:**
- App uses standard Lightning navigation
- Tab ordering reflects user workflow: Profile → Badges → Certs → Groups

**NFRs:** Accessible on desktop and mobile (responsive FlexiPages)

**Skills:** `admin-appbuilder`

---

#### US-5.2: Trailblazer Profile Home Page

**As** Nadia, **I want** a dashboard-style home page **so that** I see my progress at a glance.

**Acceptance Criteria:**
- FlexiPage (Home Page): "Trailblazer Home"
- Components: Today's streak status (report chart), Recent badges (related list - single), XP progress (report chart), Active quests (related list), Achievement showcase (related list), Quick actions: "Add Discovery", "Sync Now"
- Conditional visibility: Show "Getting Started" section for profiles with <5 badges

**Technical Considerations:**
- Report charts sourced from custom report types
- Dynamic forms for conditional sections
- Performance: Limit to 6 components on home page

**NFRs:** Page load <2 seconds, mobile-responsive

**Skills:** `admin-appbuilder`

---

#### US-5.3: Record Pages for All Objects

**As** any persona, **I want** well-organised record pages **so that** I can quickly find relevant information.

**Acceptance Criteria:**
- `Trailblazer_Profile__c` record page: Header (rank, points, badges, streak), Related lists (Recent Badges, Certifications, Achievements, Study Groups, Quest Enrollments, XP Transactions)
- `Badge__c` record page: Badge details with icon, link to Trailhead
- `Quest__c` record page: Description, criteria, enrollment list, progress
- `Study_Group__c` record page: Details, member list, embedded leaderboard report chart
- All pages: Compact layouts defined, highlights panel configured

**Technical Considerations:**
- Use Dynamic Forms where possible for clean layouts
- Related lists limited to 5–10 records with "View All" link

**NFRs:** Consistent layout patterns across all objects; WCAG 2.1 AA compliance for standard components

**Skills:** `admin-appbuilder`

---

### Epic 6: Security & Access Control

> Role-based access ensuring data privacy while enabling team visibility.

---

#### US-6.1: Permission Sets

**As** an admin, **I want** granular permission sets **so that** users only access what they need.

**Acceptance Criteria:**
- Permission Set: `Trailblazer_User` — CRUD on own `Trailblazer_Profile__c`, `Badge__c`, `Certification__c`, `Discovery__c`, `Quest_Enrollment__c`, `Earned_Achievement__c`; Read on `Quest__c`, `Study_Group__c`; Create on `Study_Group_Member__c`
- Permission Set: `Trailblazer_Leader` — Includes `Trailblazer_User` + Create/Edit on `Study_Group__c`, Edit on `Study_Group_Member__c`
- Permission Set: `Trailblazer_Admin` — Full CRUD on all custom objects, Edit on Custom Metadata Types
- Permission Set Group: `Trailblazer_Standard` (includes `Trailblazer_User`)
- Permission Set Group: `Trailblazer_Manager` (includes `Trailblazer_User` + `Trailblazer_Leader`)

**Technical Considerations:**
- FLS explicitly set for all custom fields (no reliance on profile-level)
- OWD: `Trailblazer_Profile__c` Private, with sharing rule for "Team Lead sees team" (criteria-based or programmatic)
- `Badge__c`, `Certification__c` controlled by parent (M-D inherits sharing)

**NFRs:** No data leakage between unrelated users; all FLS verified by automated tests

**Skills:** `admin-security`

---

#### US-6.2: Security Tests

**As** a developer, **I want** automated security tests **so that** permission boundaries are verified.

**Acceptance Criteria:**
- `Security_Test`: Test `Trailblazer_User` can CRUD own records but not others'
- Test `Trailblazer_Leader` can manage study groups
- Test `Trailblazer_Admin` has full access
- `System.runAs` for each permission set
- Negative tests: User without permission set cannot access objects
- Schema assertion tests: Verify all custom fields have FLS set on relevant permission sets

**NFRs:** Zero false positives; tests work in any scratch org

**Skills:** `apex-test`

---

### Epic 7: Reporting & Dashboards

> Analytics layer enabling individual progress tracking and team performance visibility.

---

#### US-7.1: Custom Report Types

**As** Tariq, **I want** cross-object reports **so that** I can analyse team learning data.

**Acceptance Criteria:**
- Report Type: "Trailblazer Profiles with Badges" (Profile → Badges)
- Report Type: "Trailblazer Profiles with Certifications" (Profile → Certifications)
- Report Type: "Trailblazer Profiles with Achievements" (Profile → Earned Achievements)
- Report Type: "Trailblazer Profiles with Quest Enrollments" (Profile → Quest Enrollments)
- Report Type: "Study Groups with Members" (Study Group → Members with Profile)
- Report Type: "XP Transactions" (Profile → XP Transactions)

**Technical Considerations:**
- All report types deployed via SFDX metadata
- Secondary relationships configured where needed

**NFRs:** Report types available in all Lightning report builder contexts

**Skills:** `admin-schema`

---

#### US-7.2: Standard Reports & Dashboards

**As** any persona, **I want** pre-built reports and dashboards **so that** I get immediate value.

**Acceptance Criteria:**
- Reports: "My Badge Timeline" (badges by month), "Certification Status Summary", "Team Leaderboard" (grouped by user, sorted by XP), "Streak Leaderboard", "Quest Completion Rates", "XP by Action Type"
- Dashboard: "My Trailblazer Dashboard" — Streak chart, badge count trend, XP gauge, cert status, achievement grid
- Dashboard: "Team Dashboard" — Leaderboard table, badges this month, avg streak, cert coverage
- Running user: context user for personal, Tariq-equivalent for team

**Technical Considerations:**
- Dashboard components limited to 20 per dashboard
- Scheduled dashboard refresh: daily at 04:00 UTC (after sync + streak calculation)

**NFRs:** Reports run in <5 seconds for 500 profiles × 500 badges

**Skills:** `admin-appbuilder`

---

### Epic 8: DevOps & Deployment

> CI/CD pipeline, scratch org configuration, and deployment validation.

---

#### US-8.1: Scratch Org Definition

**As** a developer, **I want** a scratch org config **so that** I can spin up a clean dev environment.

**Acceptance Criteria:**
- `config/project-scratch-def.json` with features: `EnableSetPasswordInApi`, standard Salesforce features
- SFDX project structure: `force-app/main/default/` with subfolders per metadata type
- `scripts/setup.sh`: create scratch org, push source, assign permission sets, run seed data script
- Seed data script: Create sample `Trailblazer_Profile__c` records, sample badges, sample quests
- `.forceignore` configured for local-only files

**Technical Considerations:**
- Scratch org edition: Developer
- Duration: 30 days default
- Features required: None beyond standard (no special licenses)

**NFRs:** Full setup from zero to working org in <10 minutes

**Skills:** `sf-devops`

---

#### US-8.2: Deployment Validation Pipeline

**As** a developer, **I want** automated deployment validation **so that** every change is verified before merge.

**Acceptance Criteria:**
- Script `scripts/validate.sh`:
  1. `sf project deploy start --dry-run --test-level RunLocalTests`
  2. Parse results: all tests pass, ≥90% coverage per class, ≥95% overall
  3. Exit non-zero on failure
- Script `scripts/deploy.sh`:
  1. `sf project deploy start --test-level RunLocalTests`
  2. Verify deployment success
  3. Run post-deploy smoke test (query for CMT records, verify object existence)
- Documentation: `README.md` with setup instructions

**Technical Considerations:**
- `--dry-run` flag validates without committing (check-only deployment)
- Test level `RunLocalTests` excludes managed package tests
- Coverage parsed from deployment result JSON

**NFRs:** Validation completes in <15 minutes for full project

**Skills:** `sf-devops`

---

## 3. Project Plan

### Phase 1: Foundation (Stories US-1.1 → US-1.6, US-8.1)

**Objective:** Establish data model, configuration metadata, and development environment.

| Sequence | Story | Skill(s) | Depends On |
|---|---|---|---|
| 1.1 | US-8.1 Scratch Org Definition | `sf-devops` | — |
| 1.2 | US-1.1 Trailblazer Profile Object | `admin-schema` | 1.1 |
| 1.3 | US-1.2 Badge Tracking Object | `admin-schema` | 1.2 |
| 1.4 | US-1.3 Certification Tracking Object | `admin-schema` | 1.2 |
| 1.5 | US-1.4 Discovery Object (Extended) | `admin-schema` | 1.2 |
| 1.6 | US-1.5 XP & Level Config Metadata | `admin-config` | 1.2 |
| 1.7 | US-1.6 Streak & Quest Config Metadata | `admin-schema`, `admin-config` | 1.2, 1.6 |

**Verification (sf-devops):**
- `sf project deploy start --dry-run` succeeds
- All objects, fields, CMTs visible in scratch org
- `sf data query --query "SELECT Id FROM Level_Definition__mdt"` returns seed records

---

### Phase 2: Sync Engine (Stories US-2.1 → US-2.4)

**Objective:** Automated data flow from Trailhead into Salesforce.

| Sequence | Story | Skill(s) | Depends On |
|---|---|---|---|
| 2.1 | US-2.1 Trailhead GraphQL Callout Service | `apex-class-generator` | Phase 1 |
| 2.2 | US-2.2 Batch Sync Job | `apex-class-generator` | 2.1 |
| 2.3 | US-2.3 On-Demand Sync Action | `apex-class-generator`, `admin-appbuilder` | 2.1 |
| 2.4 | US-2.4 Sync Integration Tests | `apex-test` | 2.1, 2.2, 2.3 |

**Verification (sf-devops):**
- Deploy with `--test-level RunLocalTests` — all sync tests pass
- Manual test: Execute `TrailheadSyncBatch` for a known public profile, verify badge records created
- Verify pagination: profile with 200+ badges fully synced

---

### Phase 3: Gamification Engine (Stories US-3.1 → US-3.4)

**Objective:** XP, levels, achievements, and streaks operational.

| Sequence | Story | Skill(s) | Depends On |
|---|---|---|---|
| 3.1 | US-3.1 XP Calculation Service | `apex-class-generator`, `admin-schema` | Phase 1, Phase 2 |
| 3.2 | US-3.2 Achievement Evaluation Engine | `apex-class-generator`, `admin-schema` | 3.1 |
| 3.3 | US-3.3 Streak Calculator | `apex-class-generator`, `admin-schema` | Phase 1, Phase 2 |
| 3.4 | US-3.4 Gamification Engine Tests | `apex-test` | 3.1, 3.2, 3.3 |

**Verification (sf-devops):**
- Deploy with `--test-level RunLocalTests` — all gamification tests pass
- Manual test: Award XP, verify level-up, verify achievement unlock
- Verify streak calculation across 3+ day simulation

---

### Phase 4: Social & Groups (Stories US-4.1 → US-4.3)

**Objective:** Study groups and social accountability features.

| Sequence | Story | Skill(s) | Depends On |
|---|---|---|---|
| 4.1 | US-4.1 Study Group Object | `admin-schema` | Phase 1 |
| 4.2 | US-4.2 Group Leaderboard & Progress | `admin-appbuilder` | 4.1, Phase 2 |
| 4.3 | US-4.3 Study Group Tests | `apex-test` | 4.1 |

**Verification (sf-devops):**
- Deploy succeeds, max-member validation fires correctly
- Report type "Study Groups with Members" returns expected data
- Group leaderboard report chart renders on record page

---

### Phase 5: Security (Stories US-6.1 → US-6.2)

**Objective:** Lock down access model and verify with automated tests.

| Sequence | Story | Skill(s) | Depends On |
|---|---|---|---|
| 5.1 | US-6.1 Permission Sets | `admin-security` | Phase 1, Phase 4 |
| 5.2 | US-6.2 Security Tests | `apex-test` | 5.1 |

**Verification (sf-devops):**
- `sf project deploy start --test-level RunLocalTests` — security tests pass
- Manual: Login as user with `Trailblazer_User` permission set, verify cannot see other users' profiles
- Verify FLS: User cannot edit `Total_Points__c` directly (system-maintained field)

---

### Phase 6: UI & Reporting (Stories US-5.1 → US-5.3, US-7.1 → US-7.2)

**Objective:** Polished user experience with dashboards and reports.

| Sequence | Story | Skill(s) | Depends On |
|---|---|---|---|
| 6.1 | US-7.1 Custom Report Types | `admin-schema` | Phase 1–4 |
| 6.2 | US-5.1 Lightning App Creation | `admin-appbuilder` | Phase 1 |
| 6.3 | US-5.2 Trailblazer Profile Home Page | `admin-appbuilder` | 6.1, 6.2 |
| 6.4 | US-5.3 Record Pages for All Objects | `admin-appbuilder` | 6.1, 6.2 |
| 6.5 | US-7.2 Standard Reports & Dashboards | `admin-appbuilder` | 6.1 |

**Verification (sf-devops):**
- All FlexiPages deployed and assigned
- Lightning App visible to assigned profiles
- All 6 report types functional
- Dashboards render with sample data

---

### Phase 7: DevOps Hardening (Story US-8.2)

**Objective:** CI/CD pipeline and deployment automation.

| Sequence | Story | Skill(s) | Depends On |
|---|---|---|---|
| 7.1 | US-8.2 Deployment Validation Pipeline | `sf-devops` | Phase 1–6 |

**Verification (sf-devops):**
- `scripts/validate.sh` runs to completion with zero failures
- `scripts/deploy.sh` deploys to clean scratch org from source with all tests passing
- Coverage report shows ≥95% aggregate

---

### Phase Dependency Graph

```
Phase 1 (Foundation)
  ├── Phase 2 (Sync Engine)
  │     └── Phase 3 (Gamification)
  ├── Phase 4 (Social)
  ├── Phase 5 (Security) ← depends on Phase 1 + 4
  ├── Phase 6 (UI & Reporting) ← depends on Phase 1–4
  └── Phase 7 (DevOps Hardening) ← depends on Phase 1–6
```

---

## 4. Research Sources

### Learner Motivation

| Source | Key Finding |
|---|---|
| Ryan & Deci (2000), "Self-Determination Theory" | Three basic needs: Autonomy, Competence, Relatedness drive intrinsic motivation |
| Bai et al. (2024), "Gamification enhances student intrinsic motivation…", *Ed Tech R&D*, Springer | Meta-analysis (35 studies, n=2500): gamification has small significant effect (g=0.257) on intrinsic motivation; strongest on autonomy and relatedness |
| Landers (2019), "Rhetorical gamification" concept | Game elements without alignment to learning goals produce surface engagement only |
| van Roy & Zaman (2018), "Need-supporting gamification" | Gamification designed to satisfy SDT basic needs produces sustained engagement |
| Luarn, Chen & Chiu (2023), *IJILT* | Social, achievement, and immersion features are key gamification drivers of intrinsic motivation; psychological needs mediate the relationship |

### Streak & Habit Mechanics

| Source | Key Finding |
|---|---|
| Phillippa Lally et al. (2010), "How are habits formed", *European J. Social Psychology* | Average 66 days to form a new habit |
| Duolingo internal data (cited by Plotline, 2025) | Users 2.3x more likely to engage daily after 7+ day streak; streak wager boosts day-14 retention by 14% |
| Plotline (2025), "Streaks and Milestones" | Apps combining streaks + milestones see 40–60% higher DAU vs single-feature |
| Yu-kai Chou, Octalysis Framework | Streak design balances Core Drive 2 (Accomplishment) with Core Drive 8 (Loss Avoidance); ramp-down > hard-reset for retention |

### Community Patterns

| Source | Key Finding |
|---|---|
| 100 Days of Trailhead (2017–2022), 100daysoftrailhead.com | Founded by Jessica Murphy & Rachel Watson (WITDEVS); 1hr/day × 100 days; daily tweet accountability; 650+ tweets in 2018; community-led leaderboards |
| Cialdini, "Influence" (commitment/consistency principle) | Public commitment to a goal increases follow-through |
| Tigh Loughhead (2020), LinkedIn article | Documented 100-day journey: 152 badges, 4 quests, 1 cert, 1 superbadge; competitive leaderboard drove persistence |
| Kel Henderson (2024), blog post | Notes gamification goal is internal achievement, not badge-collecting; warns against gaming the system |

### Platform Mechanics

| Source | Key Finding |
|---|---|
| Trailhead Rank System (trailhead.salesforce.com/trailblazer-ranks) | Scout→Hiker→Explorer→Adventurer→Mountaineer→Expeditioner→Ranger (100 badges/50K pts)→Double Star→Triple Star→Four Star→Five Star→All Star Ranger (600 badges/300K pts) |
| Salesforce Blog, "Seize the Trail" (Jan 2025) | Quests = time-bound challenges + prize sweepstakes (hoodies, mystery boxes); Road to Ranger Quest monthly; Rank-specific quests from Double Star to All Star |
| Salesforce Blog, "Next Evolution of Superbadges" (Sep 2025) | Superbadges now allow collaboration; scenario-based real-world challenges; Super Quest prizes |
| nabondance/Trailhead-Banner (GitHub) | 6 GraphQL queries for public Trailhead data: rank, badges (paginated, filterable), certifications, stamps, MVP status, Agentblazer rank |
| meruff/trailhead-leaderboard (GitHub) | Trailblazer__c object pattern, PopulateTrailblazers batch, middleware API approach |
| Trailhead Road to Ranger module | Points: 100/quiz (first try), 500/hands-on challenge; avg 4 months to Ranger; 3–5 badges/day recommended pace |
