---
name: require-git-commit-before-deploy
enabled: true
event: bash
pattern: sf\s+project\s+deploy\s+start
action: block
---

🚫 **Salesforce Deploy Blocked — Git Status Check Required**

Before deploying to Salesforce with `sf project deploy start`, you MUST verify that all changes are committed to git.

**Required steps:**

1. Run `git status` to check for uncommitted changes
2. If there are any modified, staged, or untracked files:
   - Stage all relevant changes: `git add <files>`
   - Commit them: `git commit -m "your message"`
3. Confirm `git status` shows a clean working tree (or only intentionally untracked files)
4. Only then proceed with the deploy

**Why this matters:**
- Keeps the git history in sync with what's deployed to Salesforce
- Makes it easy to roll back by reverting to a known commit
- Prevents "mystery deploys" where code in the org doesn't match any commit

Run `git status` now and commit any pending changes before retrying the deploy.
