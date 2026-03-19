@IsTest
private class AccountServiceTest {

    @TestSetup
    static void setupTestData() {
        List<Account> accounts = new List<Account>{
            new Account(
                Name = 'Test Account Alpha',
                Industry = 'Technology',
                Phone = '555-0100',
                Website = 'https://alpha.example.com',
                BillingCity = 'San Francisco',
                BillingState = 'CA'
            ),
            new Account(
                Name = 'Test Account Beta',
                Industry = 'Finance',
                Phone = '555-0200',
                Website = 'https://beta.example.com',
                BillingCity = 'New York',
                BillingState = 'NY'
            ),
            new Account(
                Name = 'Test Account Gamma',
                Industry = 'Healthcare',
                Phone = '555-0300',
                Website = 'https://gamma.example.com',
                BillingCity = 'Chicago',
                BillingState = 'IL'
            )
        };
        insert accounts;
    }

    @IsTest
    static void testCreateAccount() {
        Account acc = new Account(
            Name = 'New Test Account',
            Industry = 'Energy',
            Phone = '555-0400'
        );

        Test.startTest();
        Account result = AccountService.createAccount(acc);
        Test.stopTest();

        Assert.isNotNull(result.Id, 'Inserted account should have an Id');
        Account queried = [SELECT Name, Industry, Phone FROM Account WHERE Id = :result.Id];
        Assert.areEqual('New Test Account', queried.Name, 'Name should match');
        Assert.areEqual('Energy', queried.Industry, 'Industry should match');
        Assert.areEqual('555-0400', queried.Phone, 'Phone should match');
    }

    @IsTest
    static void testGetAccountById() {
        Account existing = [SELECT Id FROM Account WHERE Name = 'Test Account Alpha' LIMIT 1];

        Test.startTest();
        Account result = AccountService.getAccountById(existing.Id);
        Test.stopTest();

        Assert.isNotNull(result, 'Should return an account');
        Assert.areEqual('Test Account Alpha', result.Name, 'Name should match');
        Assert.areEqual('Technology', result.Industry, 'Industry should match');
        Assert.areEqual('555-0100', result.Phone, 'Phone should match');
        Assert.areEqual('San Francisco', result.BillingCity, 'BillingCity should match');
    }

    @IsTest
    static void testGetAccounts() {
        Test.startTest();
        List<Account> results = AccountService.getAccounts();
        Test.stopTest();

        Assert.areEqual(3, results.size(), 'Should return all 3 test accounts');
        // Verify ordering by Name
        Assert.areEqual('Test Account Alpha', results[0].Name, 'First account should be Alpha (alphabetical)');
        Assert.areEqual('Test Account Beta', results[1].Name, 'Second account should be Beta');
        Assert.areEqual('Test Account Gamma', results[2].Name, 'Third account should be Gamma');
    }

    @IsTest
    static void testUpdateAccount() {
        Account existing = [SELECT Id, Name, Industry FROM Account WHERE Name = 'Test Account Beta' LIMIT 1];
        existing.Industry = 'Consulting';
        existing.Phone = '555-9999';

        Test.startTest();
        Account result = AccountService.updateAccount(existing);
        Test.stopTest();

        Account queried = [SELECT Industry, Phone FROM Account WHERE Id = :result.Id];
        Assert.areEqual('Consulting', queried.Industry, 'Industry should be updated');
        Assert.areEqual('555-9999', queried.Phone, 'Phone should be updated');
    }

    @IsTest
    static void testDeleteAccount() {
        Account existing = [SELECT Id FROM Account WHERE Name = 'Test Account Gamma' LIMIT 1];
        Id accountId = existing.Id;

        Test.startTest();
        AccountService.deleteAccount(accountId);
        Test.stopTest();

        List<Account> remaining = [SELECT Id FROM Account WHERE Id = :accountId];
        Assert.isTrue(remaining.isEmpty(), 'Account should be deleted');
    }
}
