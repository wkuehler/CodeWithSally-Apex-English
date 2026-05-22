# Apex Test Patterns

## Granting Custom Permissions in Tests
Custom permissions can't be assigned inline — wire them up via PermissionSet +
SetupEntityAccess, then `System.runAs()`:

```apex
Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
User testUser = new User(
    FirstName = 'Test', LastName = 'User',
    Email = 'test@example.com',
    Username = 'test' + System.now().getTime() + '@example.com',
    Alias = 'tuser',
    TimeZoneSidKey = 'America/New_York',
    LocaleSidKey = 'en_US',
    EmailEncodingKey = 'UTF-8',
    LanguageLocaleKey = 'en_US',
    ProfileId = p.Id
);
insert testUser;

PermissionSet ps = new PermissionSet(Name = 'TestOverride', Label = 'Test Override');
insert ps;
CustomPermission cp = [
    SELECT Id FROM CustomPermission
    WHERE DeveloperName = 'Edit_All_Detailed_Notes' LIMIT 1
];
insert new SetupEntityAccess(ParentId = ps.Id, SetupEntityId = cp.Id);
insert new PermissionSetAssignment(AssigneeId = testUser.Id, PermissionSetId = ps.Id);

System.runAs(testUser) {
    // code here runs with the custom permission
}
```

## Asserting Authorization Failures
```apex
try {
    MyController.deleteRecord(recordId);
    Assert.fail('Expected AuraHandledException');
} catch (AuraHandledException e) {
    Assert.isTrue(e.getMessage().contains('permission'));
}
```

## Test Data Setup
Use `@TestSetup` for shared data across all test methods in a class — it runs
once per class, not once per test, so it's faster:

```apex
@TestSetup
static void makeData() {
    Account acc = new Account(Name = 'Test Account');
    insert acc;
    // ... more records
}

@IsTest
static void myTest() {
    Account acc = [SELECT Id FROM Account LIMIT 1]; // query what makeData created
    // ...
}
```
