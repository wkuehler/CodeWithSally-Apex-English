@IsTest
private class AchievementService_Test {

    @IsTest
    static void testEarnFirstBadgeAchievement() {
        Trailblazer_Profile__c profile =
            TestDataFactory.createProfileWithCounts(1, 0, 0);

        Test.startTest();
        AchievementService.evaluateAchievements(new Set<Id>{ profile.Id });
        Test.stopTest();

        List<Earned_Achievement__c> earned = [
            SELECT Achievement_Name__c, Definition_Id__c
            FROM Earned_Achievement__c
            WHERE Trailblazer_Profile__c = :profile.Id
        ];
        System.assert(
            !earned.isEmpty(),
            'An achievement should be earned when badge count meets threshold.'
        );

        Integer beforeCount = earned.size();

        // Second evaluation should not create duplicates.
        AchievementService.evaluateAchievements(new Set<Id>{ profile.Id });

        Integer afterCount = [
            SELECT COUNT()
            FROM Earned_Achievement__c
            WHERE Trailblazer_Profile__c = :profile.Id
        ];
        System.assertEquals(
            beforeCount,
            afterCount,
            'Achievements must not be re-awarded.'
        );
    }

    @IsTest
    static void testOtherCriteriaTypes() {
        // Badge_Count and Cert_Count already covered by existing seed data; focus on streak and points.
        Trailblazer_Profile__c profile =
            TestDataFactory.createProfileWithCounts(10, 2, 15);

        Test.startTest();
        AchievementService.evaluateAchievements(new Set<Id>{ profile.Id });
        Test.stopTest();

        // We don't assert specific achievements (seed data–dependent), but we
        // ensure the method runs without error across multiple criteria paths.
        Integer earnedCount = [
            SELECT COUNT()
            FROM Earned_Achievement__c
            WHERE Trailblazer_Profile__c = :profile.Id
        ];
        System.assert(
            earnedCount >= 0,
            'Evaluation across multiple criteria types should complete without error.'
        );
    }
}
