@IsTest
private class TrailheadApiService_Test {

    private static Integer retryInvocationCount = 0;

    private class SinglePageMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            Assert.areEqual(
                'callout:Trailhead_API/graphql',
                req.getEndpoint(),
                'callout should use the named credential plus GraphQL path'
            );
            Assert.isTrue(
                req.getBody().contains('GetTrailblazerRank')
                    || req.getBody().contains('GetTrailheadBadges')
                    || req.getBody().contains('GetUserCertifications'),
                'request body should include a cataloged GraphQL operation name'
            );
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"data":{"profile":{"__typename":"PublicProfile","id":"TH-RANK","slug":"test.user","trailheadStats":{"__typename":"TrailheadProfileStats","earnedBadgesCount":10,"superbadgeCount":1},"earnedAwards":{"edges":[{"node":{"__typename":"EarnedAwardSelf","id":"badge-1","award":{"__typename":"Award","id":"award-1","title":"Sample Module","type":"MODULE","icon":"https://example.com/icon.png","content":{"__typename":"Content","webUrl":"https://trailhead.salesforce.com","description":"Desc"}},"earnedAt":"2024-01-01T00:00:00+00:00","earnedPointsSum":100}}],"pageInfo":{"__typename":"PageInfo","endCursor":null,"hasNextPage":false,"startCursor":null,"hasPreviousPage":false}},"certifications":[{"id":"cert-1","name":"Sample Cert","status":"Active","earnedOn":"2023-01-01","expiresOn":"2025-01-01"}]}}}');
            return res;
        }
    }

    private class CatalogQueryMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            Assert.areEqual(
                'callout:Trailhead_API/graphql',
                req.getEndpoint(),
                'catalog query should still use the named credential'
            );
            Assert.isTrue(
                req.getBody().contains('GetAgentblazerStatus')
                    || req.getBody().contains('GetTbcMvpContext')
                    || req.getBody().contains('EarnedStamps'),
                'request body should include one of the reference queries'
            );

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"data":{"ok":true}}');
            return res;
        }
    }

    private class RetryThenSuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            retryInvocationCount++;

            HttpResponse res = new HttpResponse();
            if (retryInvocationCount == 1) {
                res.setStatusCode(503);
                res.setBody('{"errors":[{"message":"temporary"}]}');
                return res;
            }

            res.setStatusCode(200);
            res.setBody('{"data":{"profile":{"__typename":"PublicProfile","id":"TH-RETRY","slug":"retry.user"}}}');
            return res;
        }
    }

    private class InvalidResponseMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"errors":[{"message":"missing data"}]}');
            return res;
        }
    }

    private class GracefulParsingMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"data":{"profile":{"__typename":"PublicProfile","id":"TH-PARSE","slug":"parse.user","trailheadStats":{"__typename":"TrailheadProfileStats","earnedBadgesCount":"12","superbadgeCount":"2"},"earnedAwards":{"pageInfo":{"__typename":"PageInfo","endCursor":"cursor-2","hasNextPage":true,"startCursor":null,"hasPreviousPage":false},"edges":[{"node":{"__typename":"EarnedAwardSelf","id":"badge-2","award":{"__typename":"Award","id":"award-2","title":"Sample Project","type":"PROJECT","icon":"https://example.com/icon2.png","content":{"__typename":"Content","webUrl":"https://trailhead.salesforce.com","description":"Desc"}},"earnedAt":"bad-date","earnedPointsSum":"125"}}]},"certifications":[{"id":"cert-2","name":"Another Cert","status":"Active","earnedOn":"bad-date","expiresOn":"bad-date"}]}}}');
            return res;
        }
    }

    @IsTest
    static void fetchRankData_parsesFields() {
        Test.setMock(HttpCalloutMock.class, new SinglePageMock());
        TrailheadApiService.queryCatalogCache = null;
        TrailheadApiService.TrailheadRankData data =
            TrailheadApiService.fetchRankData('005000000000001');
        Assert.isNotNull(data, 'rank data should not be null');
        Assert.areEqual('TH-RANK', data.trailheadId, 'trailhead id should come from profile.id');
        Assert.areEqual('test.user', data.username, 'username/slug mismatch');
    }

    @IsTest
    static void fetchBadges_handlesPaginationFalse() {
        Test.setMock(HttpCalloutMock.class, new SinglePageMock());
        TrailheadApiService.queryCatalogCache = null;
        TrailheadApiService.TrailheadBadgeResult result =
            TrailheadApiService.fetchBadges('005000000000001', 50, null);
        Assert.isFalse(result.hasNextPage, 'should not have next page');
        Assert.areEqual(1, result.badges.size(), 'badge count mismatch');
        Assert.areEqual(10, result.totalBadgesCount, 'total badge count should come from trailheadStats');
        Assert.areEqual(1, result.totalSuperbadgeCount, 'superbadge count should come from trailheadStats');
    }

    @IsTest
    static void fetchCertifications_parsesList() {
        Test.setMock(HttpCalloutMock.class, new SinglePageMock());
        TrailheadApiService.queryCatalogCache = null;
        TrailheadApiService.TrailheadCertResult result =
            TrailheadApiService.fetchCertifications('005000000000001');
        Assert.isTrue(result.certifications.size() > 0, 'certs should exist');
    }

    @IsTest
    static void catalog_exposesAllSixQueriesAndReferenceMethodsUseThem() {
        TrailheadApiService.queryCatalogCache = null;
        Map<String, TrailheadApiService.QueryDefinition> catalog =
            TrailheadApiService.getQueryCatalog();

        Assert.areEqual(6, catalog.size(), 'all documented queries should be present');
        Assert.isTrue(catalog.containsKey('getAgentblazerRank'), 'agentblazer query missing');
        Assert.isTrue(catalog.containsKey('getMvpStatus'), 'mvp query missing');
        Assert.isTrue(catalog.containsKey('getStamps'), 'stamps query missing');

        Test.setMock(HttpCalloutMock.class, new CatalogQueryMock());

        Map<String, Object> agentblazer =
            TrailheadApiService.fetchAgentblazerRank('sample.slug');
        Map<String, Object> mvp = TrailheadApiService.fetchMvpStatus('sample.slug');
        Map<String, Object> stamps =
            TrailheadApiService.fetchStamps('sample.slug', 10, 'cursor-1');

        Assert.isNotNull(agentblazer.get('data'), 'agentblazer response should be returned');
        Assert.isNotNull(mvp.get('data'), 'mvp response should be returned');
        Assert.isNotNull(stamps.get('data'), 'stamps response should be returned');
    }

    @IsTest
    static void fetchRankData_retriesOnServerError() {
        retryInvocationCount = 0;
        Test.setMock(HttpCalloutMock.class, new RetryThenSuccessMock());
        TrailheadApiService.queryCatalogCache = null;

        TrailheadApiService.TrailheadRankData data =
            TrailheadApiService.fetchRankData('005000000000002');

        Assert.areEqual(2, retryInvocationCount, 'callout should retry once');
        Assert.areEqual('TH-RETRY', data.trailheadId, 'retry response should return id from profile');
    }

    @IsTest
    static void fetchRankData_logsAndThrowsWhenDataNodeMissing() {
        Test.setMock(HttpCalloutMock.class, new InvalidResponseMock());
        TrailheadApiService.queryCatalogCache = null;

        try {
            TrailheadApiService.fetchRankData('005000000000003');
            Assert.fail('missing data node should throw');
        } catch (TrailheadApiService.TrailheadApiException e) {
            Assert.isTrue(
                e.getMessage().contains('response invalid'),
                'exception should explain the invalid response'
            );
        }
    }

    @IsTest
    static void parsing_handlesStringNumbersAndInvalidDatesGracefully() {
        Test.setMock(HttpCalloutMock.class, new GracefulParsingMock());
        TrailheadApiService.queryCatalogCache = null;

        TrailheadApiService.TrailheadRankData rankData =
            TrailheadApiService.fetchRankData('005000000000004');
        TrailheadApiService.TrailheadBadgeResult badgeResult =
            TrailheadApiService.fetchBadges('005000000000004', 25, null);
        TrailheadApiService.TrailheadCertResult certResult =
            TrailheadApiService.fetchCertifications('005000000000004');

        // Rank data no longer exposes totals from the public schema; ensure it at least returns an id.
        Assert.isNotNull(rankData.trailheadId, 'rank data should still return a trailhead id');
        Assert.areEqual('cursor-2', badgeResult.endCursor, 'page info should parse');
        Assert.isTrue(badgeResult.hasNextPage, 'page info should parse');
        Assert.areEqual(125, badgeResult.badges[0].points, 'string badge points should parse');
        Assert.isNull(badgeResult.badges[0].earnedDate, 'invalid badge dates should resolve to null');
        Assert.isNull(certResult.certifications[0].earnedDate, 'invalid cert dates should resolve to null');
        Assert.isNull(certResult.certifications[0].expiryDate, 'invalid cert dates should resolve to null');
    }
}

