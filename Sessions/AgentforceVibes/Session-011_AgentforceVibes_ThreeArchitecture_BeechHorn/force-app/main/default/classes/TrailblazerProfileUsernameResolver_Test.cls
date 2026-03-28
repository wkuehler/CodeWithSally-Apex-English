@IsTest
private class TrailblazerProfileUsernameResolver_Test {

    private class UsernameResolveMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            // Minimal rank response including id and username
            res.setBody(
                '{"data":{"profile":{"id":"TH-RESOLVED","username":"test.user","currentRank":"Ranger","totalPoints":1000,"totalBadges":10,"totalSuperbadges":1,"totalCertifications":1,"lastBadgeEarnedDate":"2024-01-01"}}}'
            );
            return res;
        }
    }

    @IsTest
    static void shouldResolveTrailheadIdFromUsername() {
        Trailblazer_Profile__c profile = TestDataFactory.createProfile();
        // Clear the Trailhead_Id__c so resolver has work to do.
        profile.Trailhead_Id__c = null;
        update profile;

        Test.setMock(HttpCalloutMock.class, new UsernameResolveMock());

        Test.startTest();
        System.enqueueJob(
            new TrailblazerProfileUsernameResolver(new Set<Id>{ profile.Id })
        );
        Test.stopTest();

        Trailblazer_Profile__c refreshed = [
            SELECT Trailhead_Id__c
            FROM Trailblazer_Profile__c
            WHERE Id = :profile.Id
        ];
        System.assertEquals(
            'TH-RESOLVED',
            refreshed.Trailhead_Id__c,
            'Resolver should populate Trailhead_Id__c from API response.'
        );
    }

    @IsTest
    static void resolveHelperReturnsCanonicalId() {
        Test.setMock(HttpCalloutMock.class, new UsernameResolveMock());

        Test.startTest();
        String resolved =
            TrailheadApiService.resolveTrailheadIdFromUsername('test.user');
        Test.stopTest();

        System.assertEquals(
            'TH-RESOLVED',
            resolved,
            'Helper should return the canonical id from profile.id.'
        );
    }
}

