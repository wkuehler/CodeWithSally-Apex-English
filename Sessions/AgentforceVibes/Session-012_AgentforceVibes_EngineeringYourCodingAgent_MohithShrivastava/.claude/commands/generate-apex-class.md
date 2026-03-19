---
allowed-tools: Bash, Read, Write, Glob, Grep
description: Generate an Apex class with meta XML and a matching test class
---

# Generate Apex Class

You are generating a new Apex class for a Salesforce DX project.

## Arguments

$ARGUMENTS

The first word is the class name (PascalCase). Everything after the dash (-) is the description of what the class does.

## Instructions

1. **Read project context first**:
   - Read `sfdx-project.json` to confirm the API version (use that version for all meta XML files)
   - Glob `force-app/main/default/classes/*.cls` to see existing classes and avoid naming conflicts

2. **Generate four files** in `force-app/main/default/classes/`:

   **File 1: `{ClassName}.cls`**
   - Use `public with sharing class {ClassName}`
   - Include a class-level comment with the description
   - Add stub methods that match the described purpose
   - Follow Salesforce Apex conventions: PascalCase class names, camelCase method names

   **File 2: `{ClassName}.cls-meta.xml`**
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
       <apiVersion>{API_VERSION}</apiVersion>
       <status>Active</status>
   </ApexClass>
   ```

   **File 3: `{ClassName}Test.cls`**
   - Use `@IsTest` annotation on the class
   - Use `private class {ClassName}Test`
   - Include `@IsTest` on each test method
   - Use `@TestSetup` for shared test data when appropriate
   - Add at least one test method per public method in the main class
   - Use `System.assert`, `System.assertEquals`, `System.assertNotEquals`
   - Test both positive and negative scenarios

   **File 4: `{ClassName}Test.cls-meta.xml`**
   - Same format as the main class meta XML

3. **After generating**, list the files you created and briefly describe each.

## Example

If invoked as: `/generate-apex-class AccountService - handles CRUD operations for Account`

- Creates `AccountService.cls` with methods like `createAccount()`, `getAccountById()`, `updateAccount()`, `deleteAccount()`
- Creates `AccountService.cls-meta.xml`
- Creates `AccountServiceTest.cls` with test methods covering each CRUD operation
- Creates `AccountServiceTest.cls-meta.xml`
