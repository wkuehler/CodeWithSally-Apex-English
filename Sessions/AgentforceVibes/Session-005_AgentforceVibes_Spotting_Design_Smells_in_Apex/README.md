# Resources for Spotting Design Smells in Apex

## Code Smells Overview

**What is a Code Smell?**
- [Code Smell - Martin Fowler](https://martinfowler.com/bliki/CodeSmell.html)

A code smell is a surface indication that usually corresponds to a deeper problem in the system. While smells are quick to spot and often lead to real issues, they don't always indicate problems—they're indicators to investigate rather than definitive flaws themselves.

---

## Recommended Books

### Clean Code
- **Clean Code: A Handbook of Agile Software Craftsmanship** by Robert C. Martin
- [Amazon Link](https://www.amazon.com/Clean-Code-Handbook-Software-Craftsmanship/dp/0132350882)

### Clean Architecture
- **Clean Architecture: A Craftsman's Guide to Software Structure and Design** by Robert C. Martin
- [Amazon Link](https://www.amazon.com/Clean-Architecture-Craftsmans-Software-Structure/dp/0134494164)

### Domain-Driven Design
- **Domain-Driven Design: Tackling Complexity in the Heart of Software** by Eric Evans
- [Amazon Link](https://www.amazon.com/Domain-Driven-Design-Tackling-Complexity-Software/dp/0321125215)

### Refactoring
- **Refactoring: Improving the Design of Existing Code** by Martin Fowler
- [Amazon Link](https://www.amazon.com/Refactoring-Improving-Existing-Addison-Wesley-Signature/dp/0134757599)

---

## Apex PMD

- [PMD Apex Rules Documentation](https://pmd.github.io/pmd/pmd_rules_apex.html)

PMD rules for Apex are static analysis checks that identify code quality issues in Salesforce Apex code. The rules are organized into seven categories: **Best Practices**, **Code Style**, **Design**, **Documentation**, **Error Prone**, **Performance**, and **Security**. Each category contains specialized rules to detect specific issues ranging from naming conventions to potential vulnerabilities.

---

## Salesforce Code Analyzer

- [Salesforce Code Analyzer Documentation](https://developer.salesforce.com/docs/platform/salesforce-code-analyzer/guide/code-analyzer.html)

Salesforce Code Analyzer is a powerful tool designed to help Salesforce Platform developers maintain high standards of code quality and efficiency. It automatically scans Apex, Visualforce, Flows, and Lightning components to identify security vulnerabilities, performance issues, and coding standard violations. The tool integrates multiple scanning engines (PMD, RetireJS, ESLint) and provides over 500 built-in rules that developers can customize.

### Setup Guide
- [Install Code Analyzer](https://developer.salesforce.com/docs/platform/salesforce-code-analyzer/guide/install.html)
- [VS Code Extension for Code Analyzer](https://marketplace.visualstudio.com/items?itemName=salesforce.sfdx-code-analyzer-vscode)
