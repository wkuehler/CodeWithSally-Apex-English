public with sharing class AccountService {

    @AuraEnabled
    public static Account createAccount(Account acc) {
        insert acc;
        return acc;
    }

    @AuraEnabled(cacheable=true)
    public static Account getAccountById(Id accountId) {
        return [
            SELECT Id, Name, Industry, Phone, Website,
                   BillingStreet, BillingCity, BillingState,
                   BillingPostalCode, BillingCountry
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Account> getAccounts() {
        return [
            SELECT Id, Name, Industry, Phone, Website,
                   BillingStreet, BillingCity, BillingState,
                   BillingPostalCode, BillingCountry
            FROM Account
            ORDER BY Name
            LIMIT 200
        ];
    }

    @AuraEnabled
    public static Account updateAccount(Account acc) {
        update acc;
        return acc;
    }

    @AuraEnabled
    public static void deleteAccount(Id accountId) {
        Account acc = [SELECT Id FROM Account WHERE Id = :accountId LIMIT 1];
        delete acc;
    }
}
