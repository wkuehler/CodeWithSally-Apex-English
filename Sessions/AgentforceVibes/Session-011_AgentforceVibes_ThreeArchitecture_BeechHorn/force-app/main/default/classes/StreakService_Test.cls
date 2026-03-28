@IsTest
private class StreakService_Test {

    @IsTest
    static void testIncrementAndMilestone() {
        Trailblazer_Profile__c profile =
            TestDataFactory.createProfileWithCounts(0, 0, 6);
        TestDataFactory.createBadge(
            profile.Id,
            Date.today().addDays(-1),
            'MODULE'
        );

        Test.startTest();
        StreakService.calculateStreaks(new Set<Id>{ profile.Id });
        Test.stopTest();

        profile = [
            SELECT Current_Streak__c, Longest_Streak__c
            FROM Trailblazer_Profile__c
            WHERE Id = :profile.Id
        ];
        System.assertEquals(7, profile.Current_Streak__c);
        System.assertEquals(7, profile.Longest_Streak__c);
    }

    @IsTest
    static void testFreezeOrResetBasedOnConfig() {
        // Default_Streak_Config has Freeze_Allowed__c=true and Max_Freeze_Days__c=2.
        // With no qualifying badge activity yesterday, streak should freeze until freezes are exhausted.

        Trailblazer_Profile__c pFreeze =
            TestDataFactory.createProfileWithCounts(0, 0, 3);

        Trailblazer_Profile__c pReset =
            TestDataFactory.createProfileWithCounts(0, 0, 3);
        // Exhaust monthly freezes (Max_Freeze_Days__c=2)
        TestDataFactory.createStreakFreeze(pReset.Id, Date.today());
        TestDataFactory.createStreakFreeze(pReset.Id, Date.today());

        Test.startTest();
        StreakService.calculateStreaks(new Set<Id>{ pFreeze.Id, pReset.Id });
        Test.stopTest();

        pFreeze = [
            SELECT Current_Streak__c
            FROM Trailblazer_Profile__c
            WHERE Id = :pFreeze.Id
        ];
        System.assertEquals(
            3,
            pFreeze.Current_Streak__c,
            'With freeze available, streak should not reset.'
        );
        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM Streak_Freeze__c
                WHERE Trailblazer_Profile__c = :pFreeze.Id
                  AND Used_Date__c = :Date.today()
            ],
            'A freeze record should be inserted for today.'
        );

        pReset = [
            SELECT Current_Streak__c
            FROM Trailblazer_Profile__c
            WHERE Id = :pReset.Id
        ];
        System.assertEquals(0, pReset.Current_Streak__c, 'After freezes are exhausted, streak should reset.');
    }
}
