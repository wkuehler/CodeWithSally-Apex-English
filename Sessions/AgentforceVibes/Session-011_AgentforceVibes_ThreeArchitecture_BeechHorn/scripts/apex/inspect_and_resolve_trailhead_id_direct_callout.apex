Id profileId = 'a05Au00000Z8DnCIAV';

Trailblazer_Profile__c p = [
    SELECT Id, Trailhead_Username__c, Trailhead_Id__c
    FROM Trailblazer_Profile__c
    WHERE Id = :profileId
    LIMIT 1
];
System.debug('BEFORE username=' + p.Trailhead_Username__c + ' trailheadId=' + p.Trailhead_Id__c);

String slug = p.Trailhead_Username__c;
HttpRequest req = new HttpRequest();
req.setEndpoint('https://profile.api.trailhead.com/graphql');
req.setMethod('POST');
req.setHeader('Content-Type', 'application/json');

Map<String, Object> body = new Map<String, Object>{
    'query' => 'query ProfileBySlug($slug: String!, $hasSlug: Boolean!) { profile(slug: $slug) @include(if: $hasSlug) { __typename ... on PublicProfile { id slug } ... on PrivateProfile { __typename } } }',
    'variables' => new Map<String, Object>{ 'slug' => slug, 'hasSlug' => true }
};
req.setBody(JSON.serialize(body));

Http http = new Http();
HttpResponse res = http.send(req);
System.debug('HTTP ' + res.getStatusCode() + ' body=' + res.getBody());

Map<String, Object> wrapper = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
Map<String, Object> data = wrapper == null ? null : (Map<String, Object>) wrapper.get('data');
Map<String, Object> profile = data == null ? null : (Map<String, Object>) data.get('profile');
String resolvedId = profile == null ? null : (String) profile.get('id');
System.debug('RESOLVED=' + resolvedId);

if (!String.isBlank(resolvedId) && String.isBlank(p.Trailhead_Id__c)) {
    p.Trailhead_Id__c = resolvedId;
    update p;
}

Trailblazer_Profile__c p2 = [
    SELECT Id, Trailhead_Username__c, Trailhead_Id__c
    FROM Trailblazer_Profile__c
    WHERE Id = :profileId
    LIMIT 1
];
System.debug('AFTER username=' + p2.Trailhead_Username__c + ' trailheadId=' + p2.Trailhead_Id__c);

