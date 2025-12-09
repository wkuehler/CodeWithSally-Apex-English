# Week 4 – Final Sprint Week (Full Project Requirements)

📅 **Project Presentation:** **Tuesday, Dec 16 — 11am–1pm EST**

Welcome to **Week 4**, the final sprint of our Africa Ohana × Code With Sally Apex Beginner Cohort!  
This week is fully dedicated to your **Final Project**, teamwork, testing, polishing your solution, and preparing for your live presentation.

There are **NO new videos assigned this week**, but you are strongly encouraged to:

- Finish any videos you missed from previous weeks  
- Ask questions early — don’t wait until the end  
- Move slowly and carefully through the requirements  
- Focus on understanding, not rushing  

Your project presentation is only successful when the **entire team understands the code**, not when one person does all the work.

---

# 🚀 Final Project – Full Requirements

You will build a **mini Salesforce Project Management App** using `Project__c` and `Project_Task__c`, including triggers, handlers, validations, automation, and unit tests.

> 🔔 **IMPORTANT:**  
> - This is a **group project** — no individual submissions.  
> - Submit **ONE GitHub Gist** per team.  
> - Post progress **in your team Slack channel**, not privately.  
> - Communicate often — do NOT wait until the last day.

---

# ⭐ 1. Create Parent Object – `Project__c`

**Fields:**
- **Name** (Standard)
- **Start_Date__c** (Date)
- **End_Date__c** (Date)
- **Description__c** (Long Text Area)

---

# ⭐ 2. Create Child Object – `Project_Task__c`  
Relationship: **Master-Detail → Project__c**

**Fields:**
- **Project__c** (Master Detail)
- **Name** (Standard Text)
- **Due_Date__c** (Date) — **Required**
- **Status__c** (Picklist) — Default: *Not Started*  
  Values: Not Started, In Progress, Completed
- **isCompleted__c** (Checkbox) — Default unchecked
- **Priority__c** (Picklist) — **Required**  
  Values: Low, Medium, High

---

# ⭐ 3. Trigger on `Project_Task__c`

Must accomplish:

### a. Due Date Validation  
- Applies on **insert** and **update**  
- Block if Due_Date__c is **today or in the past**

### b. Auto Complete Behavior  
If `isCompleted__c` becomes **true** on update → set Status__c = “Completed”

### c. Prevent Priority Downgrade  
If old Priority__c = High → users CANNOT change it to Medium or Low

### d. Prevent Pre-Completed Inserts  
Block inserting a new Task where `isCompleted__c = true`

---

# ⭐ 4. Trigger on `Project__c`

For every new Project__c created, auto-create a default kickoff task:

- **Name:** “Kickoff Task”  
- **Due_Date__c:** Start_Date__c + 2 days  
- **Priority__c:** Medium  
- **Status__c:** Not Started  

---

# ⭐ 5. Unit Testing Requirements

Each team must create:

- A **Test Data Factory**  
- A **@testSetup** method where appropriate  
- Tests that cover:
  - Positive scenarios  
  - Negative/validation scenarios  
  - Bulk scenarios for both objects  
- Ensure you cover **every branch** of your logic  

Target coverage: **75%+**, but correctness is more important than numbers.

---

# ⭐ 6. Extra Challenge (Optional but Highly Recommended)

To strengthen SOQL, SOSL, and custom Apex class skills, you may add a custom search feature.

### add Search Utility Class

### add 1st Method to this Apex class 
- Purpose : to Query Project Tasks that matches a certain status filter and include Project details. 
- Method return type : List of Project Tasks 
- Parameter: Status Filter as String

### Add 2nd Method this Apex Method to your Utility Class
public static List<SearchResultWrapper> searchAll(String keyword)

### Requirements:
- Use SOSL to search across:  
  - Project__c  
  - Project_Task__c  
  - Account  
  - Contact  

### Return a wrapper list:

```apex
public class SearchResultWrapper {
    public String objectType;
    public String name;
    public String additionalInfo;
}
```

You will demo these methods live in the Developer Console.

This mirrors real-world search functionalities and looks great in a presentation.

---

# 📤 Final Group Submission Checklist

Each group must submit:

### ✔ GitHub Gist (ONE per team)  
Containing:  
- Project triggers  
- Trigger handlers  
- Apex service classes (if used)  
- Test classes  
- Test Data Factory  

### ✔ Screenshots  
- All tests passed  
- Code coverage %  

### ✔ Team Slack Update  
Include:  
- What is completed  
- What’s left  
- Challenges faced  
- Who contributed to what (high level)

---

# 🎤 Final Presentation Expectations (Dec 16)

Your 25-minutes presentation must include:

### ✔ Team introduction  
Who you are, and what each person worked on.

### ✔ Live Demo  
Show the system working end-to-end:  
- Trigger behaviors  
- Validations  
- Automation  
- Optional search feature  
- Error scenarios  

### ✔ Show Your Tests  
- Run tests and show coverage  
- Explain testing strategy:
  - Positive  
  - Negative  
  - Bulk  
  - Test Data Factory  

### ✔ Lessons Learned  
- From the course  
- From the project  
- From working as a team  

### ✔ Obstacles & Solutions  
Talk about what challenged you and how you solved it.

### ✔ Creativity is encouraged  
Slides, storytelling, diagrams — anything that makes your work memorable.

---

# 🌟 Camp Apex (Optional Practice)

You may work on as many challenges as you want:

- https://www.campapex.org/practice/variables  
- https://www.campapex.org/practice/conditionals  
- https://www.campapex.org/practice/loops  
- https://www.campapex.org/practice/lists  
- https://www.campapex.org/practice/sets  
- https://www.campapex.org/practice/maps  
- https://www.campapex.org/practice/classes  
- https://www.campapex.org/practice/methods  
- https://www.campapex.org/practice/oo  
- https://www.campapex.org/practice/sobjects  
- https://www.campapex.org/practice/dml  
- https://www.campapex.org/practice/soql  

👉 Your Camp Apex username must start with: `africaOhana1_`

Feel free to explore beyond these categories too!

---

# 📚 After the Cohort: Keep Learning Apex

If you want to learn more about Apex and see how it is used in real companies:

➡ **Intermediate Apex Series:**  
https://www.youtube.com/playlist?list=PLeevJTFuNoITwTpPlXqeGWlShf41do1wt

---

# 🎉 Final Message  
You’ve already come so far — this last sprint is where everything comes together.

Work as a team.  
Move slowly.  
Ask questions.  
And enjoy building something real.

You’ve got this! 🚀
