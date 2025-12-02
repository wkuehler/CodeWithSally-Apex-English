# Week 3 – SOQL, SOSL, Triggers, Unit Testing & Exception Handling

📅 **To be completed between:** **Dec 2 → Dec 9**

Welcome to **Week 3** — the final learning week before your **end-of-sprint project**!

This week focuses on six essential Salesforce developer skills:

- Writing SOQL & SOSL queries  
- Advanced SOQL (relationships, order, limit/offset, dynamic queries)  
- Apex Triggers  
- Apex Unit Testing (best practices, test setup, test data factory, bulk tests)  
- Exception Handling (try/catch, rollback, error messages)  
- Reading & understanding Debug Logs  

These are the core skills every Salesforce developer uses daily.

---

## 🎬 Videos to Watch (Required)

Numbered **1–13** for this week:

1. **Introduction to SOQL & SOSL – Part 1**  
   https://youtu.be/1h2cKyQi37g?si=aeRyy_Ib4RRaJ7Re

2. **Advanced SOQL – ORDER BY, LIMIT, OFFSET – Part 2**  
   https://youtu.be/lfz7VX_TKYM?si=sOb9d0PFlvPPLdXN

3. **Advanced SOQL – Relationships & Dynamic Queries – Part 3**  
   https://youtu.be/a_5ePMefWPY?si=oKQhDZKrGdYcA_cQ

4. **Mastering SOSL – Part 4**  
   https://youtu.be/2HrLRte3rQY?si=aVgcHUY2eHCvLEZC

5. **Apex Invocation Types & Triggers – Part 1**  
   https://youtu.be/hsZJZpu6GwQ?si=_qg8lsEHM41VcNeY

6. **Mastering Apex Triggers – Part 2**  
   https://youtu.be/oJoD2L-YV2o?si=3meVEBxDn_9l2AU9

7. **Introduction to Apex Unit Tests – Part 1**  
   https://youtu.be/Dkk_A5ciAxY?si=OW8gttc9cYjxUXWi

8. **Running Unit Tests & Code Coverage – Part 2**  
   https://youtu.be/FhF1IuP6OG4?si=EG3sX7Sx99ajyh6P

9. **testSetup, Test Data Factory & Bulk Testing – Part 3**  
   https://youtu.be/diHYKbHvZqc?si=fRKRrOXx-y1keIKP

10. **Exception Testing & System.runAs – Part 4**  
    https://youtu.be/RAVHQ0FzwEM?si=QixP0sl2Y63VQHDJ

11. **Exception Handling Basics & Try-Catch – Part 1**  
    https://youtu.be/OvRbFhtRzSM?si=JKK1G3oCFsDN-EPP

12. **Try-Catch Placement & Rollback Handling – Part 2**  
    https://youtu.be/FJ3Z4iLrgeU?si=NEEVnxUeWW-5tewh

13. **How to Read & Use Debug Logs for Troubleshooting**  
    https://youtu.be/tPPv4VQY89k?si=4KT2NohXi-MyunST

---

## ✋ Hands-On Homework (Part 1 — MUST DO)

### **1. Do everything I do in videos 1–13**

Recreate all examples, including:

- SOQL queries  
- SOSL queries  
- Parent–child & child–parent relationships  
- Dynamic SOQL  
- Trigger examples  
- Unit test methods  
- `@testSetup`, bulk testing, negative testing  
- Try/Catch examples  
- Debug Log analysis  

This is essential practice to prepare for the final project.

---

# 🚀 Final Project – Phase 1 (Week 4)

📅 **To be started this week – Due by end of the sprint**  
This is **Part 1** of the Final Project.  
Next week (Final Sprint Week), you will receive **additional project requirements**, so the more progress you make this week, the easier next week will be.

> 🔔 **IMPORTANT:**  
> - All work for the Final Project is done **as a group**, not individually.  
> - Each team will submit **one GitHub Gist** and report progress **in their team Slack channel**.  
> - Every group member should contribute to planning, coding, and testing.

---

# ✋ Hands-On Homework (Part 2 — REQUIRED)  
## **Apex Trigger + Unit Testing Scenario – Project Phase 1**

This week you will begin building a **mini Salesforce Project Management App** using `Project__c` and `Project_Task__c`.

---

## ⭐ **1. Create the Parent Object – Project__c**

**Fields:**
   - **Name** (standard)
   - **Start_Date__c** (Date)
   - **End_Date__c** (Date)
   - **Description__c** (Long Text Area)

---

## ⭐ **2. Create the Child Object – Project_Task__c**
**Fields:**
   - **Project__c** (Master Detail to Project__c)
   - **Name** (Text)  (Standard Field)
   - **Due_Date__c** (Date) (Required field) 
   - **Status__c** (Picklist):  (Default Value Not Started)
     - Not Started  
     - In Progress  
     - Completed  
   - **isCompleted__c** (Checkbox) (Default Unchecked)
   - **Priority__c** (Picklist): (Required Field)
      - Low
      - Medium
      - High
---

## ⭐ **3. Trigger on Project_Task__c**
   1. Ensures **Due_Date__c** is in the future 
         - 	Applies when inserting a new record
         -	Applies when a user updates an existing record
         -	Block the action if the date is Today or in the past  
		 
   2. Automatically sets **Status__c = 'Completed'** if **isCompleted__c** is set to true during update
   
   3. Prevent lowering priority: If Priority__c was previously 'High', users cannot change it to Medium or Low.
   
   4. Prevent setting isCompleted__c = true when inserting new Task

---

## ⭐ **4. Trigger on Project__c**
For every new Project__c record, automatically create one Project_Task__c child record: 
	- Name: “Kickoff Task”
	- Due_Date__c = Project.Start_Date__c + 2 days 
	- Priority__c = Medium
	- Status__c = Not Started

---
## ⭐ **5. Unit Testing Requirements**
   - Use a **Test Data Factory**  
   - Use **@testSetup** where appropriate  
   - Cover for all your code:
      - Positive cases  
      - Negative (validation error) cases  
      - Bulk operations for both Project__c and Project_Task__c  

**Goal:**  
> Aim for **75%+ coverage**, but more importantly, test every branch of your logic.

---

# 📤 **Group Submission Requirements**

Each project team must submit:

1. **One GitHub Gist link** containing:
   - Trigger code  
   - Handler classes  
   - Test classes  
   - Test data factory  

2. **Screenshots**:
   - Running tests  
   - Code coverage  
   - Passing results  

3. **Status update messages**  
   - Post updates only in **your team’s Slack channel**, not privately  
   - One consolidated update per team

---

# 📝 Notes for Phase 1

- This is **not** the full project – more requirements will be added next week.
- Teams should aim to complete as much as possible **this week**, so Week 5 can focus on enhancements.
- Collaboration is key — discuss design decisions, test strategies, and divide tasks.

---

## ✋ Hands-On Homework (Part 3 — OPTIONAL BUT HIGHLY RECOMMENDED)

# 🌟 Camp Apex Collaboration (Week 3)

Choose **3–5 challenges** from the following:

1. **Lists** → https://www.campapex.org/practice/lists  
2. **Sets** → https://www.campapex.org/practice/sets  
3. **Maps** → https://www.campapex.org/practice/maps  
4. **Classes** → https://www.campapex.org/practice/classes  
5. **Methods** → https://www.campapex.org/practice/methods  
6. **Object-Oriented (OO)** → https://www.campapex.org/practice/oo  
7. **sObjects** → https://www.campapex.org/practice/sobjects  
8. **DML** → https://www.campapex.org/practice/dml  

👉 **Your Camp Apex username must start with:**  
`africaOhana1_`

---

# YOU’RE DOING AMAZING! 🌟  
If you get stuck, ask questions in Slack — we learn together.
