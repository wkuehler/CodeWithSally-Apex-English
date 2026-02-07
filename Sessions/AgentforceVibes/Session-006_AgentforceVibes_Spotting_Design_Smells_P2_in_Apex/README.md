# Agentforce Vibes – Spotting Design Smells in Apex (Part 2)

This folder contains the **resources, workflows, and templates** used in  
**Agentforce Vibes: Spotting Design Smells in Apex – Part 2**, hosted on **Code With Sally** with special guest **Saman Attar**.

In this session, we move beyond detection and demonstrate a **real-world, end-to-end workflow**:
from interactive code review → structured Markdown output → AI-assisted refactoring.

---

## 🎥 YouTube Session

👉 Watch the full session here:  
https://youtu.be/D7NmemjZVDw

📌 **Part 1 (foundation on design smells):**  
https://youtu.be/IpOfYGAl1bQ

---

## 🎯 What This Session Covers

In Part 2, we focus on making the workflow **production-ready** and usable in real projects by:

- Making the code review workflow **interactive**
- Allowing users to choose:
  - Which Apex class(es) to review
  - Which risk categories to analyze
  - How results should be grouped
- Outputting findings as a **Markdown (.md) file**
- Using that Markdown output as input to **Agentforce Vibes** for refactoring
- Demonstrating how developers stay in control by selectively approving changes

This mirrors how teams actually work:

**Review → Discuss → Decide → Refactor**

---

## 📂 Folder Structure
Session-006_AgentforceVibes_Spotting_Design_Smells_P2_in_Apex
│
├── categories/
│   ├── design_smell.md
│   ├── platform_risk.md
│   ├── communication_smells.md
│   └── team_process.md
│
├── output_format/
│   └── format.md
│
├── workflows/
│   └── code_review.md
│
└── README.md

---

## 📁 Categories

The `categories` folder contains **individual Markdown files** describing each review category.

Splitting categories into separate files:
- Improves maintainability
- Enables reuse across workflows
- Helps control context window size by loading only what’s needed

Categories included:
- Design Smells
- Platform Risks
- Communication Smells
- Team / Process Risks

---

## 📄 Output Format

The `output_format/format.md` file defines **how review results should be structured**.

Why Markdown output?
- Easy to read
- Easy to review
- Easy to share with teams
- Can be reused as input for refactoring workflows

---

## 🔁 Workflow

The `workflows/code_review.md` file defines the **interactive code review workflow**, including:

- Step-by-step execution order
- User questions (classes to review, categories, output preferences)
- Conditional file loading
- Enforced Markdown output format

This workflow is designed to be:
- Deterministic
- Auditable
- Safe to use in real projects

---

## 🤖 From Review to Refactor

In the session, we demonstrate how to:
1. Run the code review workflow
2. Generate a structured `.md` review report
3. Edit the findings to keep only desired changes
4. Feed the final report back into Agentforce Vibes
5. Perform refactoring in **Plan Mode**

This keeps humans in control while leveraging AI effectively.

---

## 🙌 Credits

Special thanks to **Saman Attar** for sharing deep insights into:
- Code quality
- Design smells
- Practical, maintainable Apex design

Special thanks to **Beech Horn** for teaching me how to reference other files within a workflow.
---

## 💡 Notes

- This repository is meant to be **read alongside the video**
- The workflows are examples you can adapt to your own teams and projects
- Smaller files + clear rules = better AI outcomes

Enjoy — and happy reviewing! 🚀