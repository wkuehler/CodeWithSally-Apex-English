@IsTest
private class TrailblazerProfileSharingService_Test {

    @IsTest
    static void shouldCreateLeaderShareWhenLeaderAndMemberInSameGroup() {
        User leaderUser = TestDataFactory.createStandardUser('leader@share.com');
        Trailblazer_Profile__c leaderProfile;
        Trailblazer_Profile__c memberProfile;
        Study_Group__c grp;

        System.runAs(leaderUser) {
            leaderProfile = TestDataFactory.createProfile();
            leaderProfile.User__c = leaderUser.Id;
            update leaderProfile;

            memberProfile = TestDataFactory.createProfile();

            grp = TestDataFactory.createStudyGroup(10);
            TestDataFactory.createStudyGroupMember(grp.Id, leaderProfile.Id, 'Leader');
            TestDataFactory.createStudyGroupMember(grp.Id, memberProfile.Id, 'Member');
        }

        Test.startTest();
        TrailblazerProfileSharingService.recalculateLeaderSharesForGroups(new Set<Id>{ grp.Id });
        Test.stopTest();

        List<Trailblazer_Profile__Share> shares = [
            SELECT Id, ParentId, UserOrGroupId, RowCause, AccessLevel
            FROM Trailblazer_Profile__Share
            WHERE ParentId = :memberProfile.Id
              AND UserOrGroupId = :leaderUser.Id
              AND RowCause = :Schema.Trailblazer_Profile__Share.RowCause.Leader_Team_Access__c
        ];
        System.assertEquals(1, shares.size(), 'Leader should have read share on member profile.');
        System.assertEquals('Read', shares[0].AccessLevel);
    }

    @IsTest
    static void shouldEnqueueRecalculationForGroups() {
        Study_Group__c grp = TestDataFactory.createStudyGroup(5);
        System.assertEquals(0, [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'Queueable']);

        Test.startTest();
        TrailblazerProfileSharingService.enqueueRecalculationForGroups(new Set<Id>{ grp.Id });
        Test.stopTest();

        List<AsyncApexJob> jobs = [
            SELECT Id, Status, ApexClass.Name
            FROM AsyncApexJob
            WHERE JobType = 'Queueable'
        ];
        System.assert(!jobs.isEmpty(), 'Queueable job should be enqueued.');
    }

    @IsTest
    static void shouldRemoveSharesWhenLeaderRemovedFromGroup() {
        User leaderUser = TestDataFactory.createStandardUser('lead2@share.com');
        Trailblazer_Profile__c leaderProfile;
        Trailblazer_Profile__c memberProfile;
        Study_Group__c grp;

        System.runAs(leaderUser) {
            leaderProfile = TestDataFactory.createProfile();
            leaderProfile.User__c = leaderUser.Id;
            update leaderProfile;
            memberProfile = TestDataFactory.createProfile();
            grp = TestDataFactory.createStudyGroup(10);
            TestDataFactory.createStudyGroupMember(grp.Id, leaderProfile.Id, 'Leader');
            TestDataFactory.createStudyGroupMember(grp.Id, memberProfile.Id, 'Member');
        }

        TrailblazerProfileSharingService.recalculateLeaderSharesForGroups(new Set<Id>{ grp.Id });
        System.assertEquals(
            1,
            [SELECT COUNT() FROM Trailblazer_Profile__Share WHERE ParentId = :memberProfile.Id AND RowCause = :Schema.Trailblazer_Profile__Share.RowCause.Leader_Team_Access__c],
            'Share should exist after recalc.'
        );

        Study_Group_Member__c leaderMembership = [
            SELECT Id FROM Study_Group_Member__c
            WHERE Study_Group__c = :grp.Id AND Trailblazer_Profile__c = :leaderProfile.Id
        ];
        delete leaderMembership;

        Test.startTest();
        TrailblazerProfileSharingService.recalculateLeaderSharesForGroups(new Set<Id>{ grp.Id });
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Trailblazer_Profile__Share WHERE ParentId = :memberProfile.Id AND RowCause = :Schema.Trailblazer_Profile__Share.RowCause.Leader_Team_Access__c],
            'Leader share should be removed after leader removed from group.'
        );
    }
}
