@IsTest
private class TrailheadSyncBatch_Test {

    private class BatchMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"data":{"profile":{"username":"test.user","currentRank":"Ranger","totalPoints":1000,"totalBadges":10,"totalSuperbadges":1,"totalCertifications":1,"lastBadgeEarnedDate":"2024-01-01","badges":{"pageInfo":{"endCursor":null,"hasNextPage":false},"edges":[{"node":{"id":"badge-1","title":"Sample Module","type":"MODULE","points":100,"description":"Desc","iconUrl":"https://example.com/icon.png","url":"https://trailhead.salesforce.com","earnedOn":"2024-01-01"}}]},"certifications":[{"id":"cert-1","name":"Sample Cert","status":"Active","earnedOn":"2023-01-01","expiresOn":"2025-01-01"}]}}}');
            return res;
        }
    }

    @IsTest
    static void batchSync_updatesProfileAndChildren() {
        Trailblazer_Profile__c profile = TestDataFactory.createProfile();

        Test.setMock(HttpCalloutMock.class, new BatchMock());

        Test.startTest();
        TrailheadSyncBatch batch = new TrailheadSyncBatch();
        Database.executeBatch(batch, 1);
        Test.stopTest();

        Trailblazer_Profile__c refreshed = [
            SELECT Total_Points__c,
                   Total_Badges__c,
                   Total_Certifications__c,
                   Last_Sync_Date__c
            FROM Trailblazer_Profile__c
            WHERE Id = :profile.Id
        ];
        Assert.areEqual(1000, refreshed.Total_Points__c, 'points rollup');
        Assert.isNotNull(refreshed.Last_Sync_Date__c, 'last sync should be set');

        List<Badge__c> badges = [
            SELECT Id
            FROM Badge__c
            WHERE Trailblazer_Profile__c = :profile.Id
        ];
        Assert.isTrue(badges.size() > 0, 'badges should be upserted');

        List<Certification__c> certs = [
            SELECT Id
            FROM Certification__c
            WHERE Trailblazer_Profile__c = :profile.Id
        ];
        Assert.isTrue(certs.size() > 0, 'certs should be upserted');
    }
}

