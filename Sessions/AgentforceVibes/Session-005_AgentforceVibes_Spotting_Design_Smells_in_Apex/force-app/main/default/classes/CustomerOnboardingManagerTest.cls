@isTest
private class CustomerOnboardingManagerTest {

    @isTest
    static void testProcessOnboarding_NewCustomer() {
        Account testAccount = new Account(
            Name = 'Test Customer Corp',
            Type = 'Customer',
            Industry = 'Technology',
            AnnualRevenue = 250000,
            BillingCity = 'San Francisco'
        );
        insert testAccount;

        testAccount = [SELECT Id, Name, Type, OwnerId, AnnualRevenue FROM Account WHERE Id = :testAccount.Id];

        Test.startTest();
        CustomerOnboardingManager manager = new CustomerOnboardingManager();
        manager.processOnboarding(new List<Account>{testAccount}, 'Normal');
        Test.stopTest();

        List<Contact> contacts = [SELECT Id, LastName, AccountId FROM Contact WHERE AccountId = :testAccount.Id];
        System.assertEquals(1, contacts.size(), 'Should create primary contact');

        List<Task> tasks = [SELECT Id, Subject, WhatId FROM Task WHERE WhatId = :testAccount.Id];
        System.assert(tasks.size() >= 5, 'Should create multiple onboarding tasks');
    }

    @isTest
    static void testProcessOnboarding_HighValueCustomer() {
        Account highValueAccount = new Account(
            Name = 'Big Enterprise Inc',
            Type = 'Customer',
            AnnualRevenue = 750000
        );
        insert highValueAccount;

        highValueAccount = [SELECT Id, Name, Type, OwnerId, AnnualRevenue FROM Account WHERE Id = :highValueAccount.Id];

        Test.startTest();
        CustomerOnboardingManager manager = new CustomerOnboardingManager();
        manager.processOnboarding(new List<Account>{highValueAccount}, 'High');
        Test.stopTest();

        List<Task> followUpTasks = [
            SELECT Id, Subject, ActivityDate
            FROM Task
            WHERE WhatId = :highValueAccount.Id
            AND Subject = 'Customer Onboarding Follow-up'
        ];
        System.assertEquals(1, followUpTasks.size(), 'Should create follow-up task');
        System.assertEquals(
            Date.today().addDays(3),
            followUpTasks[0].ActivityDate,
            'High-value customers should get 3-day follow-up'
        );
    }

    @isTest
    static void testProcessOnboarding_ErrorHandling() {
        Account testAccount = new Account(Name = 'Error Test', Type = 'Customer');
        insert testAccount;
        testAccount = [SELECT Id, Name, Type, OwnerId FROM Account WHERE Id = :testAccount.Id];

        Test.startTest();
        CustomerOnboardingManager manager = new CustomerOnboardingManager();
        try {
            manager.processOnboarding(new List<Account>{testAccount}, 'Normal');
            System.assert(true, 'Process completed without throwing');
        } catch (Exception e) {
            System.assert(false, 'Should not throw exceptions due to error swallowing');
        }
        Test.stopTest();
    }

    @isTest
    static void testTriggerIntegration() {
        Test.startTest();
        Account customerAccount = new Account(
            Name = 'Trigger Test Corp',
            Type = 'Customer',
            AnnualRevenue = 150000
        );
        insert customerAccount;
        Test.stopTest();

        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :customerAccount.Id];
        System.assert(tasks.size() > 0, 'Trigger should initiate onboarding');

        List<Contact> contacts = [SELECT Id FROM Contact WHERE AccountId = :customerAccount.Id];
        System.assertEquals(1, contacts.size(), 'Should create primary contact via trigger');
    }

    @isTest
    static void testAccountTypeChange() {
        Account prospectAccount = new Account(
            Name = 'Prospect to Customer',
            Type = 'Prospect'
        );
        insert prospectAccount;

        List<Task> tasksBefore = [SELECT Id FROM Task WHERE WhatId = :prospectAccount.Id];
        System.assertEquals(0, tasksBefore.size(), 'No tasks before becoming customer');

        Test.startTest();
        prospectAccount.Type = 'Customer';
        update prospectAccount;
        Test.stopTest();

        List<Task> tasksAfter = [SELECT Id FROM Task WHERE WhatId = :prospectAccount.Id];
        System.assert(tasksAfter.size() > 0, 'Should trigger onboarding when Type changes to Customer');
    }
}
