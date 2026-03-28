@IsTest
private class TrailheadSyncService_Test {

    private class ManualMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            // Align with current public schema: id/slug + trailheadStats + earnedAwards + certifications.
            res.setBody('{"data":{"profile":{"__typename":"PublicProfile","id":"TH-RESOLVED","slug":"test.user","trailheadStats":{"__typename":"TrailheadProfileStats","earnedBadgesCount":10,"superbadgeCount":1},"earnedAwards":{"edges":[{"node":{"__typename":"EarnedAwardSelf","id":"badge-1","award":{"__typename":"Award","id":"award-1","title":"Sample Module","type":"MODULE","icon":"https://example.com/icon.png","content":{"__typename":"Content","webUrl":"https://trailhead.salesforce.com","description":"Desc"}},"earnedAt":"2024-01-01T00:00:00+00:00","earnedPointsSum":100}}],"pageInfo":{"__typename":"PageInfo","endCursor":null,"hasNextPage":false,"startCursor":null,"hasPreviousPage":false}},"certifications":[{"id":"cert-1","name":"Sample Cert","status":"Active","earnedOn":"2023-01-01","expiresOn":"2025-01-01"}]}}}');
            return res;
        }
    }

    @IsTest
    static void manualSync_enqueuesJobAndHonoursRateLimit() {
        Trailblazer_Profile__c profile = TestDataFactory.createProfile();
        Study_Group__c studyGroup = TestDataFactory.createStudyGroup(5);
        Study_Group_Member__c membership =
            TestDataFactory.createStudyGroupMember(studyGroup.Id, profile.Id, 'Member');

        Test.setMock(HttpCalloutMock.class, new ManualMock());

        TrailheadSyncService.SyncInput input = new TrailheadSyncService.SyncInput();
        input.profileId = profile.Id;

        Test.startTest();
        List<TrailheadSyncService.SyncOutput> outputs =
            TrailheadSyncService.syncProfile(new List<TrailheadSyncService.SyncInput>{ input });
        Test.stopTest();

        Assert.areEqual(1, outputs.size(), 'one output expected');
        Assert.isTrue(
            outputs[0].message.contains('Sync queued'),
            'first call should queue sync'
        );

        Trailblazer_Profile__c refreshed = [
            SELECT Last_Sync_Date__c,
                   Total_Badges__c
            FROM Trailblazer_Profile__c
            WHERE Id = :profile.Id
        ];
        Assert.isNotNull(refreshed.Last_Sync_Date__c, 'sync should stamp Last_Sync_Date__c');
        Assert.areEqual(10, refreshed.Total_Badges__c, 'sync should update badge totals');

        membership = [
            SELECT Total_Badges_Snapshot__c
            FROM Study_Group_Member__c
            WHERE Id = :membership.Id
        ];
        Assert.areEqual(
            10,
            membership.Total_Badges_Snapshot__c,
            'study group member snapshots should refresh after sync'
        );

        TrailheadSyncService.SyncInput secondInput = new TrailheadSyncService.SyncInput();
        secondInput.profileId = profile.Id;

        List<TrailheadSyncService.SyncOutput> secondOutputs =
            TrailheadSyncService.syncProfile(new List<TrailheadSyncService.SyncInput>{ secondInput });
        Assert.isTrue(
            secondOutputs[0].message.contains('Sync recently performed'),
            'second call should be rate limited'
        );
    }

    @IsTest
    static void manualSync_resolvesTrailheadIdFromUsernameWhenMissing() {
        Trailblazer_Profile__c profile = TestDataFactory.createProfile();
        // Simulate a profile created with a username but without a Trailhead_Id__c.
        profile.Trailhead_Id__c = null;
        update profile;

        Test.setMock(HttpCalloutMock.class, new ManualMock());

        TrailheadSyncService.SyncInput input = new TrailheadSyncService.SyncInput();
        input.profileId = profile.Id;

        Test.startTest();
        List<TrailheadSyncService.SyncOutput> outputs =
            TrailheadSyncService.syncProfile(new List<TrailheadSyncService.SyncInput>{ input });
        Test.stopTest();

        Assert.areEqual(1, outputs.size(), 'one output expected');
        Assert.isTrue(
            outputs[0].message.contains('Sync queued'),
            'sync should still be queued when only username is present'
        );

        Trailblazer_Profile__c refreshed = [
            SELECT Trailhead_Id__c,
                   Last_Sync_Date__c,
                   Total_Badges__c
            FROM Trailblazer_Profile__c
            WHERE Id = :profile.Id
        ];
        Assert.areEqual(
            'TH-RESOLVED',
            refreshed.Trailhead_Id__c,
            'sync should resolve and persist Trailhead_Id__c from username'
        );
        Assert.isNotNull(
            refreshed.Last_Sync_Date__c,
            'sync should still update Last_Sync_Date__c after resolving id'
        );
        Assert.areEqual(
            10,
            refreshed.Total_Badges__c,
            'sync should still roll up badge totals after resolving id'
        );
    }

    @IsTest
    static void syncNow_returnsExpectedMessages() {
        Trailblazer_Profile__c profile = TestDataFactory.createProfile();

        String missingMessage = TrailheadSyncService.syncNow(null);
        Assert.isTrue(
            missingMessage.contains('No profileId supplied'),
            'null profile ids should be rejected'
        );

        profile.Last_Sync_Date__c = System.now();
        update profile;

        String rateLimitedMessage = TrailheadSyncService.syncNow(profile.Id);
        Assert.isTrue(
            rateLimitedMessage.contains('please wait'),
            'recent syncs should be rate limited'
        );
    }
}

