@IsTest
private class XPService_Test {

    @IsTest
    static void testBadgeModuleXP() {
        Trailblazer_Profile__c profile = TestDataFactory.createProfile();

        Map<String, Object> ctx = new Map<String, Object>();
        ctx.put('badgeType', 'MODULE');

        Test.startTest();
        XPService.awardXP(profile.Id, 'Badge_Earned', ctx);
        Test.stopTest();

        profile = [
            SELECT XP_Total__c, Current_Level__c
            FROM Trailblazer_Profile__c
            WHERE Id = :profile.Id
        ];

        System.assertNotEquals(0, profile.XP_Total__c, 'XP should be awarded for badge.');
        System.assertNotEquals(null, profile.Current_Level__c, 'Current_Level__c should be set to numeric level from Level_Definition__mdt.');
        System.assert(profile.Current_Level__c >= 1, 'Current_Level__c should be a positive numeric level.');

        List<XP_Transaction__c> txns = [
            SELECT Id, XP_Amount__c, Action_Type__c
            FROM XP_Transaction__c
            WHERE Trailblazer_Profile__c = :profile.Id
        ];
        System.assertEquals(1, txns.size(), 'One XP transaction expected.');
        System.assertEquals('Badge_Earned', txns[0].Action_Type__c);
        System.assertNotEquals(0, txns[0].XP_Amount__c);
    }

    @IsTest
    static void testBulkAwards() {
        Trailblazer_Profile__c p1 = TestDataFactory.createProfile();
        Trailblazer_Profile__c p2 = TestDataFactory.createProfile();

        List<XPService.XPEvent> events = new List<XPService.XPEvent>();
        events.add(new XPService.XPEvent(p1.Id, 'Badge_Earned', new Map<String, Object>{ 'badgeType' => 'MODULE' }));
        events.add(new XPService.XPEvent(p2.Id, 'Badge_Earned', new Map<String, Object>{ 'badgeType' => 'SUPERBADGE' }));

        Test.startTest();
        XPService.awardXP(events);
        Test.stopTest();

        List<XP_Transaction__c> txns = [
            SELECT Trailblazer_Profile__c, XP_Amount__c
            FROM XP_Transaction__c
            WHERE Trailblazer_Profile__c IN :new Set<Id>{ p1.Id, p2.Id }
        ];
        System.assertEquals(2, txns.size(), 'Two XP transactions expected for bulk call.');
    }
}

