public with sharing class TrailheadApiService {

    private static final String ENDPOINT_CMT_NAME = 'Trailhead_API';
    private static final String DEFAULT_QUERY_CATALOG_RESOURCE =
        'Trailhead_GraphQL_Query_Catalog';
    private static final String QUERY_TRAILBLAZER_RANK = 'getTrailblazerRank';
    private static final String QUERY_RESOLVE_PROFILE_ID_BY_SLUG =
        'resolveTrailblazerProfileIdBySlug';
    private static final String QUERY_TRAILHEAD_BADGES = 'getTrailheadBadges';
    private static final String QUERY_USER_CERTIFICATIONS = 'getUserCertifications';
    private static final String QUERY_AGENTBLAZER_RANK = 'getAgentblazerRank';
    private static final String QUERY_MVP_STATUS = 'getMvpStatus';
    private static final String QUERY_STAMPS = 'getStamps';

    @TestVisible
    private static Map<String, QueryDefinition> queryCatalogCache;

    public class TrailheadRankData {
        public String trailheadId;
        public String username;
        public String currentRank;
        public Integer totalPoints;
        public Integer totalBadges;
        public Integer totalSuperbadges;
        public Integer totalCertifications;
        public Date lastBadgeDate;
    }

    public class TrailheadBadgeResult {
        public List<TrailheadBadge> badges;
        public String endCursor;
        public Boolean hasNextPage;
        public Integer totalBadgesCount;
        public Integer totalSuperbadgeCount;
    }

    public class TrailheadBadge {
        public String trailheadBadgeId;
        public String title;
        public String type;
        public Date earnedDate;
        public Integer points;
        public String description;
        public String iconUrl;
        public String trailheadUrl;
    }

    public class TrailheadCertResult {
        public List<TrailheadCertification> certifications;
    }

    public class TrailheadCertification {
        public String certId;
        public String name;
        public String status;
        public Date earnedDate;
        public Date expiryDate;
    }

    public class QueryDefinition {
        public String name;
        public String label;
        public String description;
        public String upstreamPath;
        public List<String> usedBy;
        public String query;
    }

    public static TrailheadRankData fetchRankData(String trailheadId) {
        Map<String, Object> response = sendGraphQlRequest(
            QUERY_TRAILBLAZER_RANK,
            new Map<String, Object>{
                'slug' => trailheadId,
                'hasSlug' => !String.isBlank(trailheadId)
            }
        );
        return parseRankData(response, trailheadId);
    }

    public static TrailheadBadgeResult fetchBadges(
        String trailheadId,
        Integer count,
        String afterCursor
    ) {
        Integer pageSize = count != null ? count : getConfiguredPageSize();
        Map<String, Object> response = sendGraphQlRequest(
            QUERY_TRAILHEAD_BADGES,
            new Map<String, Object>{
                'slug' => trailheadId,
                'hasSlug' => !String.isBlank(trailheadId),
                'count' => pageSize,
                'after' => afterCursor,
                'filter' => null
            }
        );
        return parseBadges(response);
    }

    public static TrailheadCertResult fetchCertifications(String trailheadId) {
        Map<String, Object> response = sendGraphQlRequest(
            QUERY_USER_CERTIFICATIONS,
            new Map<String, Object>{
                'trailheadId' => trailheadId,
                'queryProfile' => !String.isBlank(trailheadId)
            }
        );
        return parseCerts(response);
    }

    public static Map<String, Object> fetchAgentblazerRank(String slug) {
        return sendGraphQlRequest(
            QUERY_AGENTBLAZER_RANK,
            new Map<String, Object>{
                'slug' => slug,
                'hasSlug' => !String.isBlank(slug)
            }
        );
    }

    public static Map<String, Object> fetchMvpStatus(String slug) {
        return sendGraphQlRequest(
            QUERY_MVP_STATUS,
            new Map<String, Object>{
                'userSlug' => slug,
                'queryMvp' => !String.isBlank(slug)
            }
        );
    }

    public static Map<String, Object> fetchStamps(
        String slug,
        Integer count,
        String afterCursor
    ) {
        return sendGraphQlRequest(
            QUERY_STAMPS,
            new Map<String, Object>{
                'slug' => slug,
                'first' => count,
                'after' => afterCursor
            }
        );
    }

    private static Map<String, Object> sendGraphQlRequest(
        String queryName,
        Map<String, Object> variables
    ) {
        API_Endpoint__mdt config = getConfig();
        if (config == null || !config.Is_Active__c) {
            logError(
                null,
                'API',
                'Failed',
                0,
                0,
                null,
                0,
                'API_Endpoint__mdt.Trailhead_API not configured or inactive'
            );
            throw new TrailheadApiException(
                'Trailhead API configuration missing or inactive.'
            );
        }

        QueryDefinition queryDefinition = getQueryDefinition(queryName);

        HttpRequest req = new HttpRequest();
        // Prefer Named Credential when configured, but be able to fall back
        // to direct HTTPS in dev/scratch orgs where External Credentials may not exist.
        String graphQlPath = String.isNotBlank(config.GraphQL_Path__c)
            ? config.GraphQL_Path__c
            : '/graphql';
        if (!graphQlPath.startsWith('/')) {
            graphQlPath = '/' + graphQlPath;
        }

        String primaryEndpoint = 'callout:' + config.Named_Credential_Name__c + graphQlPath;
        String fallbackEndpoint = 'https://profile.api.trailhead.com' + graphQlPath;

        req.setEndpoint(primaryEndpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');

        Map<String, Object> bodyWrapper = new Map<String, Object>();
        bodyWrapper.put('query', queryDefinition.query);
        bodyWrapper.put(
            'variables',
            variables == null ? new Map<String, Object>() : variables
        );
        req.setBody(JSON.serialize(bodyWrapper));

        if (config.Timeout_Ms__c != null) {
            req.setTimeout(Integer.valueOf(config.Timeout_Ms__c));
        }

        Http http = new Http();
        Integer attempts = 0;
        Integer maxRetries =
            config.Max_Retries__c != null ? Integer.valueOf(config.Max_Retries__c) : 1;
        Boolean triedFallbackEndpoint = false;
        while (true) {
            attempts++;
            HttpResponse res;
            Integer statusCode = 0;
            try {
                res = http.send(req);
                statusCode = res.getStatusCode();
            } catch (Exception e) {
                // If the org can't access the named/external credential, retry once using direct HTTPS.
                // This is common in scratch orgs where the credential isn't provisioned.
                String msg = e.getMessage();
                if (
                    !triedFallbackEndpoint
                    && req.getEndpoint() == primaryEndpoint
                    && msg != null
                    && msg.containsIgnoreCase('couldn\'t access the credential')
                ) {
                    triedFallbackEndpoint = true;
                    req.setEndpoint(fallbackEndpoint);
                    continue;
                }
                if (attempts > maxRetries) {
                    logError(
                        null,
                        'API',
                        'Failed',
                        statusCode,
                        0,
                        null,
                        0,
                        'Callout failed for ' + queryName + ': ' + e.getMessage()
                    );
                    throw new TrailheadApiException(
                        'Trailhead API callout failed: ' + e.getMessage()
                    );
                }
                continue;
            }

            if (statusCode >= 500 && statusCode < 600 && attempts <= maxRetries) {
                continue;
            }

            if (statusCode < 200 || statusCode >= 300) {
                logError(
                    null,
                    'API',
                    'Failed',
                    statusCode,
                    0,
                    null,
                    0,
                    'Non-success HTTP status for ' + queryName + ': '
                        + statusCode
                        + ' body='
                        + res.getBody()
                );
                throw new TrailheadApiException(
                    'Trailhead API returned status ' + statusCode
                );
            }

            Map<String, Object> responseWrapper =
                (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

            // Trailhead GraphQL may return top-level "errors" without "data" when a query
            // is invalid against the current schema. Treat that as a hard failure and
            // surface the full response body for debugging.
            if (responseWrapper == null || !responseWrapper.containsKey('data')) {
                String body = res.getBody();
                logError(
                    null,
                    'Batch Sync',
                    'Failed',
                    statusCode,
                    0,
                    null,
                    0,
                    'Response missing data node for '
                        + queryName
                        + ': '
                        + body
                );
                throw new TrailheadApiException(
                    'Trailhead API response missing data node. body=' + body
                );
            }
            return responseWrapper;
        }
        return new Map<String, Object>();
    }

    private static TrailheadRankData parseRankData(
        Map<String, Object> response,
        String trailheadId
    ) {
        TrailheadRankData rankData = new TrailheadRankData();
        rankData.trailheadId = trailheadId;

        Map<String, Object> data = (Map<String, Object>) response.get('data');
        if (data == null) {
            return rankData;
        }

        Map<String, Object> profile = (Map<String, Object>) data.get('profile');
        if (profile == null) {
            return rankData;
        }

        // Current Trailhead schema (as observed via live calls) supports id+slug.
        // The older rank/total fields are not available, so leave them null.
        Object profileId = profile.get('id');
        if (profileId instanceof String && !String.isBlank((String) profileId)) {
            rankData.trailheadId = (String) profileId;
        }
        rankData.username = (String) profile.get('slug');

        return rankData;
    }

    /**
     * Resolve the canonical Trailhead profile ID for a given username.
     * This uses the rank GraphQL query and prefers the ID returned by the API.
     */
    public static String resolveTrailheadIdFromUsername(String username) {
        if (String.isBlank(username)) {
            return null;
        }
        Map<String, Object> response = sendGraphQlRequest(
            QUERY_RESOLVE_PROFILE_ID_BY_SLUG,
            new Map<String, Object>{
                'slug' => username,
                'hasSlug' => true
            }
        );

        Map<String, Object> data = (Map<String, Object>) response.get('data');
        if (data == null) {
            return null;
        }
        Map<String, Object> profile = (Map<String, Object>) data.get('profile');
        if (profile == null) {
            return null;
        }
        Object profileId = profile.get('id');
        return profileId instanceof String ? (String) profileId : null;
    }

    private static TrailheadBadgeResult parseBadges(Map<String, Object> response) {
        TrailheadBadgeResult result = new TrailheadBadgeResult();
        result.badges = new List<TrailheadBadge>();
        result.endCursor = null;
        result.hasNextPage = false;

        Map<String, Object> data = (Map<String, Object>) response.get('data');
        if (data == null) {
            return result;
        }
        Map<String, Object> profile = (Map<String, Object>) data.get('profile');
        if (profile == null) {
            return result;
        }

        // Capture badge rollup stats when available.
        Map<String, Object> stats =
            (Map<String, Object>) profile.get('trailheadStats');
        if (stats != null) {
            Map<String, Object> thStats = stats;
            Object earnedBadgesCount = thStats.get('earnedBadgesCount');
            if (earnedBadgesCount != null) {
                result.totalBadgesCount = toInteger(earnedBadgesCount);
            }
            Object superbadgeCount = thStats.get('superbadgeCount');
            if (superbadgeCount != null) {
                result.totalSuperbadgeCount = toInteger(superbadgeCount);
            }
        }

        // New schema: badges are exposed via earnedAwards on PublicProfile.
        Map<String, Object> awardsNode =
            (Map<String, Object>) profile.get('earnedAwards');
        if (awardsNode == null) {
            return result;
        }
        Map<String, Object> pageInfo =
            (Map<String, Object>) awardsNode.get('pageInfo');
        if (pageInfo != null) {
            result.endCursor = (String) pageInfo.get('endCursor');
            Object hasNext = pageInfo.get('hasNextPage');
            result.hasNextPage = hasNext instanceof Boolean ? (Boolean) hasNext : false;
        }
        List<Object> edges = (List<Object>) awardsNode.get('edges');
        if (edges == null) {
            return result;
        }
        for (Object edgeObj : edges) {
            Map<String, Object> edge = (Map<String, Object>) edgeObj;
            Map<String, Object> node = (Map<String, Object>) edge.get('node');
            if (node == null) {
                continue;
            }

            Map<String, Object> award = (Map<String, Object>) node.get('award');
            if (award == null) {
                continue;
            }
            Map<String, Object> content =
                (Map<String, Object>) award.get('content');

            TrailheadBadge badge = new TrailheadBadge();
            badge.trailheadBadgeId = (String) award.get('id');
            badge.title = (String) award.get('title');
            badge.type = (String) award.get('type');
            badge.points = toInteger(node.get('earnedPointsSum'));
            badge.description =
                content != null ? (String) content.get('description') : null;
            badge.iconUrl = (String) award.get('icon');
            badge.trailheadUrl =
                content != null ? (String) content.get('webUrl') : null;

            Object earnedDateVal = node.get('earnedAt');
            if (earnedDateVal instanceof String) {
                Date d = toDateFromIso(earnedDateVal);
                if (d != null) {
                    badge.earnedDate = d;
                }
            }

            result.badges.add(badge);
        }
        return result;
    }

    private static TrailheadCertResult parseCerts(Map<String, Object> response) {
        TrailheadCertResult result = new TrailheadCertResult();
        result.certifications = new List<TrailheadCertification>();

        Map<String, Object> data = (Map<String, Object>) response.get('data');
        if (data == null) {
            return result;
        }
        Map<String, Object> profile = (Map<String, Object>) data.get('profile');
        if (profile == null) {
            return result;
        }
        List<Object> certs = (List<Object>) profile.get('certifications');
        if (certs == null) {
            return result;
        }

        for (Object cObj : certs) {
            Map<String, Object> certNode = (Map<String, Object>) cObj;
            TrailheadCertification cert = new TrailheadCertification();
            cert.certId = (String) certNode.get('id');
            cert.name = (String) certNode.get('name');
            cert.status = (String) certNode.get('status');

            Object earnedVal = certNode.get('earnedOn');
            if (earnedVal instanceof String) {
                try {
                    cert.earnedDate = Date.valueOf((String) earnedVal);
                } catch (Exception e) {
                }
            }
            Object expiryVal = certNode.get('expiresOn');
            if (expiryVal instanceof String) {
                try {
                    cert.expiryDate = Date.valueOf((String) expiryVal);
                } catch (Exception e) {
                }
            }
            result.certifications.add(cert);
        }

        return result;
    }

    private static Integer toInteger(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof Integer) {
            return (Integer) value;
        }
        if (value instanceof Long) {
            return Integer.valueOf((Long) value);
        }
        if (value instanceof Decimal) {
            return ((Decimal) value).intValue();
        }
        if (value instanceof String) {
            try {
                return Integer.valueOf((String) value);
            } catch (Exception e) {
                return null;
            }
        }
        return null;
    }

    // Best-effort conversion of an ISO-8601 datetime string (e.g. 2025-07-27T09:21:21+00:00)
    // to a Date. Falls back to null if parsing fails.
    private static Date toDateFromIso(Object value) {
        if (!(value instanceof String)) {
            return null;
        }
        String s = (String) value;
        if (s == null || s.length() < 10) {
            return null;
        }
        String datePortion = s.substring(0, 10);
        try {
            return Date.valueOf(datePortion);
        } catch (Exception e) {
            return null;
        }
    }

    private static Integer getConfiguredPageSize() {
        API_Endpoint__mdt config = getConfig();
        if (config != null && config.Page_Size__c != null) {
            return Integer.valueOf(config.Page_Size__c);
        }
        return 50;
    }

    private static API_Endpoint__mdt getConfig() {
        return API_Endpoint__mdt.getInstance(ENDPOINT_CMT_NAME);
    }

    private static QueryDefinition getQueryDefinition(String queryName) {
        Map<String, QueryDefinition> catalog = getQueryCatalog();
        QueryDefinition queryDefinition = catalog.get(queryName);
        if (queryDefinition == null || String.isBlank(queryDefinition.query)) {
            throw new TrailheadApiException(
                'Trailhead query "' + queryName + '" is missing from the query catalog.'
            );
        }
        return queryDefinition;
    }

    @TestVisible
    private static Map<String, QueryDefinition> getQueryCatalog() {
        if (queryCatalogCache != null) {
            return queryCatalogCache;
        }

        API_Endpoint__mdt config = getConfig();
        String resourceName = DEFAULT_QUERY_CATALOG_RESOURCE;
        if (config != null && String.isNotBlank(config.Query_Catalog_Static_Resource__c)) {
            resourceName = config.Query_Catalog_Static_Resource__c;
        }

        StaticResource catalogResource = [
            SELECT Body
            FROM StaticResource
            WHERE Name = :resourceName
            LIMIT 1
        ];

        Map<String, Object> rawCatalog =
            (Map<String, Object>) JSON.deserializeUntyped(
                catalogResource.Body.toString()
            );
        List<Object> rawQueries = (List<Object>) rawCatalog.get('queries');
        queryCatalogCache = new Map<String, QueryDefinition>();

        for (Object rawQuery : rawQueries) {
            Map<String, Object> rawEntry = (Map<String, Object>) rawQuery;
            QueryDefinition queryDefinition = new QueryDefinition();
            queryDefinition.name = (String) rawEntry.get('name');
            queryDefinition.label = (String) rawEntry.get('label');
            queryDefinition.description = (String) rawEntry.get('description');
            queryDefinition.upstreamPath = (String) rawEntry.get('upstreamPath');
            queryDefinition.query = (String) rawEntry.get('query');
            queryDefinition.usedBy = new List<String>();

            List<Object> usedByValues = (List<Object>) rawEntry.get('usedBy');
            if (usedByValues != null) {
                for (Object usedByValue : usedByValues) {
                    queryDefinition.usedBy.add((String) usedByValue);
                }
            }

            queryCatalogCache.put(queryDefinition.name, queryDefinition);
        }

        return queryCatalogCache;
    }

    private static void logError(
        Id profileId,
        String operationType,
        String status,
        Integer httpStatusCode,
        Integer recordsProcessed,
        String cursor,
        Integer page,
        String message
    ) {
        try {
            Integration_Log__c log = new Integration_Log__c();
            log.Trailblazer_Profile__c = profileId;
            log.Operation_Type__c = operationType;
            log.Status__c = status;
            log.Http_Status_Code__c = httpStatusCode;
            log.Records_Processed__c = recordsProcessed;
            log.Request_Cursor__c = cursor;
            log.Request_Page__c = page;
            log.Message__c = message;
            insert log;
        } catch (Exception e) {
        }
    }

    public class TrailheadApiException extends Exception {
    }
}
