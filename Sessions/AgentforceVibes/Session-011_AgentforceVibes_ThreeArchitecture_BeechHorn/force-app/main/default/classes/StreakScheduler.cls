global with sharing class StreakScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {
        List<Trailblazer_Profile__c> profiles = [
            SELECT Id
            FROM Trailblazer_Profile__c
            WHERE Trailhead_Username__c != null
        ];
        if (profiles.isEmpty()) {
            return;
        }
        Set<Id> ids = new Set<Id>();
        for (Trailblazer_Profile__c p : profiles) {
            ids.add(p.Id);
        }
        StreakService.calculateStreaks(ids);
    }
}

