public with sharing class TrailheadSyncBatch
    implements Database.Batchable<SObject>, Database.AllowsCallouts, Schedulable {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id
            FROM Trailblazer_Profile__c
            WHERE Trailhead_Username__c != null
        ]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        for (SObject sobj : scope) {
            Trailblazer_Profile__c profile = (Trailblazer_Profile__c) sobj;
            try {
                TrailheadSyncOrchestrator.syncProfile(profile.Id);
            } catch (Exception e) {
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new TrailheadSyncBatch(), 1);
    }
}

