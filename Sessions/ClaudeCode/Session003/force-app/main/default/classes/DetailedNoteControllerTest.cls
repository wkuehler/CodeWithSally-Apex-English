@IsTest
private class DetailedNoteControllerTest {

    @TestSetup
    static void makeData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Case c = new Case(Subject = 'Test Case', AccountId = acc.Id);
        insert c;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        List<DetailedNote__c> notes = new List<DetailedNote__c>{
            new DetailedNote__c(Title__c = 'Case Note', Body__c = '<p>case body</p>', Case__c = c.Id),
            new DetailedNote__c(Title__c = 'Opp Note', Body__c = '<p>opp body</p>', Opportunity__c = opp.Id),
            new DetailedNote__c(Title__c = 'Account Note', Body__c = '<p>acc body</p>', Account__c = acc.Id)
        };
        insert notes;
    }

    @IsTest
    static void getNotes_case_returnsOnlyCaseNotes() {
        Case c = [SELECT Id FROM Case LIMIT 1];

        Test.startTest();
        List<DetailedNoteController.NoteWrapper> result =
            DetailedNoteController.getNotes(c.Id, 'Case');
        Test.stopTest();

        Assert.areEqual(1, result.size(), 'Should return 1 case note');
        Assert.areEqual('Case Note', result[0].title);
        Assert.isNull(result[0].sourceLabel, 'Case notes have no source label');
    }

    @IsTest
    static void getNotes_opportunity_returnsOnlyOppNotes() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<DetailedNoteController.NoteWrapper> result =
            DetailedNoteController.getNotes(opp.Id, 'Opportunity');
        Test.stopTest();

        Assert.areEqual(1, result.size(), 'Should return 1 opportunity note');
        Assert.areEqual('Opp Note', result[0].title);
        Assert.isNull(result[0].sourceLabel, 'Opportunity notes have no source label');
    }

    @IsTest
    static void getNotes_account_returnsDirectAndRolledUpNotes() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<DetailedNoteController.NoteWrapper> result =
            DetailedNoteController.getNotes(acc.Id, 'Account');
        Test.stopTest();

        Assert.areEqual(3, result.size(), 'Should return account note + case note + opp note');

        Integer sourceLabelCount = 0;
        for (DetailedNoteController.NoteWrapper w : result) {
            if (w.sourceLabel != null) {
                sourceLabelCount++;
            }
        }
        Assert.areEqual(2, sourceLabelCount, 'Case and Opp notes should have source labels');
    }

    @IsTest
    static void getNotes_account_sourceLabelContainsRecordName() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<DetailedNoteController.NoteWrapper> result =
            DetailedNoteController.getNotes(acc.Id, 'Account');
        Test.stopTest();

        Boolean foundCaseLabel = false;
        Boolean foundOppLabel = false;
        for (DetailedNoteController.NoteWrapper w : result) {
            if (w.sourceLabel != null && w.sourceLabel.startsWith('Case:')) {
                foundCaseLabel = true;
            }
            if (w.sourceLabel != null && w.sourceLabel.startsWith('Opportunity:')) {
                foundOppLabel = true;
            }
        }
        Assert.isTrue(foundCaseLabel, 'Should have a Case source label');
        Assert.isTrue(foundOppLabel, 'Should have an Opportunity source label');
    }
}
