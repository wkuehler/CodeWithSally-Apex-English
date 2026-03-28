public with sharing class TrailheadSyncService implements Queueable, Database.AllowsCallouts {

    private Id profileId;

    public TrailheadSyncService(Id profileId) {
        this.profileId = profileId;
    }

    public void execute(QueueableContext context) {
        if (profileId == null) {
            return;
        }
        TrailheadSyncOrchestrator.syncProfile(profileId);
    }

    @AuraEnabled
    public static String syncNow(Id profileId) {
        if (profileId == null) {
            return 'No profileId supplied.';
        }

        Trailblazer_Profile__c profile = [
            SELECT Id, Last_Sync_Date__c
            FROM Trailblazer_Profile__c
            WHERE Id = :profileId
            LIMIT 1
        ];

        if (!canSyncNow(profile.Last_Sync_Date__c)) {
            return 'Sync recently performed; please wait before syncing again.';
        }

        System.enqueueJob(new TrailheadSyncService(profile.Id));
        return 'Sync queued.';
    }

    @InvocableMethod(
        label='Sync Trailblazer Profiles'
        description='Synchronise one or more Trailblazer_Profile__c records with Trailhead.'
    )
    public static List<SyncOutput> syncProfile(List<SyncInput> inputs) {
        List<SyncOutput> results = new List<SyncOutput>();
        if (inputs == null) {
            return results;
        }

        for (SyncInput input : inputs) {
            SyncOutput out = new SyncOutput();
            results.add(out);
            if (input == null || input.profileId == null) {
                out.message = 'No profileId supplied.';
                continue;
            }

            Trailblazer_Profile__c profile = [
                SELECT Id, Last_Sync_Date__c
                FROM Trailblazer_Profile__c
                WHERE Id = :input.profileId
                LIMIT 1
            ];

            if (!canSyncNow(profile.Last_Sync_Date__c)) {
                out.message = 'Sync recently performed; please wait before syncing again.';
                continue;
            }

            System.enqueueJob(new TrailheadSyncService(profile.Id));
            out.message = 'Sync queued.';
        }
        return results;
    }

    private static Boolean canSyncNow(Datetime lastSync) {
        if (lastSync == null) {
            return true;
        }
        Datetime threshold = System.now().addMinutes(-5);
        return lastSync < threshold;
    }

    public class SyncInput {
        @InvocableVariable
        public Id profileId;
    }

    public class SyncOutput {
        @InvocableVariable
        public String message;
    }
}

