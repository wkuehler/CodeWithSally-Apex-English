Id profileId = 'a05Au00000Z8DnCIAV';

Trailblazer_Profile__c p = [
    SELECT Id, Trailhead_Username__c, Trailhead_Id__c
    FROM Trailblazer_Profile__c
    WHERE Id = :profileId
    LIMIT 1
];
System.debug('BEFORE username=' + p.Trailhead_Username__c + ' trailheadId=' + p.Trailhead_Id__c);

String resolved = TrailheadApiService.resolveTrailheadIdFromUsername(p.Trailhead_Username__c);
System.debug('RESOLVED=' + resolved);

if (!String.isBlank(resolved) && String.isBlank(p.Trailhead_Id__c)) {
    p.Trailhead_Id__c = resolved;
    update p;
}

Trailblazer_Profile__c p2 = [
    SELECT Id, Trailhead_Username__c, Trailhead_Id__c
    FROM Trailblazer_Profile__c
    WHERE Id = :profileId
    LIMIT 1
];
System.debug('AFTER username=' + p2.Trailhead_Username__c + ' trailheadId=' + p2.Trailhead_Id__c);

