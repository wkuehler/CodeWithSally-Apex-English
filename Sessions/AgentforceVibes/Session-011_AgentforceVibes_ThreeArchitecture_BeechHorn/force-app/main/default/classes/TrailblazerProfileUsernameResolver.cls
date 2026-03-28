public with sharing class TrailblazerProfileUsernameResolver
    implements Queueable, Database.AllowsCallouts {

    private Set<Id> profileIds;

    public TrailblazerProfileUsernameResolver(Set<Id> profileIds) {
        this.profileIds = profileIds == null ? new Set<Id>() : profileIds.clone();
    }

    public void execute(QueueableContext context) {
        if (profileIds == null || profileIds.isEmpty()) {
            return;
        }

        List<Trailblazer_Profile__c> profilesToUpdate =
            new List<Trailblazer_Profile__c>();

        for (Trailblazer_Profile__c profile : [
            SELECT Id,
                Trailhead_Username__c,
                Trailhead_Id__c
            FROM Trailblazer_Profile__c
            WHERE Id IN :profileIds
        ]) {
            if (
                String.isBlank(profile.Trailhead_Username__c) ||
                !String.isBlank(profile.Trailhead_Id__c)
            ) {
                continue;
            }

            try {
                String resolvedId = TrailheadApiService.resolveTrailheadIdFromUsername(
                    profile.Trailhead_Username__c
                );
                if (!String.isBlank(resolvedId)) {
                    profile.Trailhead_Id__c = resolvedId;
                    profilesToUpdate.add(profile);
                } else {
                    insert new Integration_Log__c(
                        Trailblazer_Profile__c = profile.Id,
                        Operation_Type__c = 'API Call',
                        Status__c = 'Failed',
                        Message__c =
                            'Unable to resolve Trailhead Id from username ' +
                            profile.Trailhead_Username__c
                    );
                }
            } catch (Exception e) {
                insert new Integration_Log__c(
                    Trailblazer_Profile__c = profile.Id,
                    Operation_Type__c = 'API Call',
                    Status__c = 'Failed',
                    Message__c =
                        'Error resolving Trailhead Id from username ' +
                        profile.Trailhead_Username__c +
                        ': ' +
                        e.getMessage()
                );
            }
        }

        if (!profilesToUpdate.isEmpty()) {
            update profilesToUpdate;
        }
    }
}

