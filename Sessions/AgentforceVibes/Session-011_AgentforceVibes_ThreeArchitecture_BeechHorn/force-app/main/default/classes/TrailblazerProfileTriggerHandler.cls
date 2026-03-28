/**
 * Handles Trailblazer_Profile__c trigger. Recalculates leader-based sharing when User__c changes.
 */
public with sharing class TrailblazerProfileTriggerHandler {

    public static void handle(
        System.TriggerOperation op,
        List<Trailblazer_Profile__c> newList,
        Map<Id, Trailblazer_Profile__c> oldMap
    ) {
        // Maintain existing behaviour for share recalculation.
        if (op == System.TriggerOperation.AFTER_UPDATE) {
            handleUserChangeSharing(newList, oldMap);
        }

        // New behaviour: when a Trailhead username is set or changed and the
        // Trailhead Id is blank, resolve it asynchronously via the Trailhead API.
        if (
            op == System.TriggerOperation.AFTER_INSERT ||
            op == System.TriggerOperation.AFTER_UPDATE
        ) {
            handleTrailheadUsernameChanges(newList, oldMap);
        }
    }

    private static void handleUserChangeSharing(
        List<Trailblazer_Profile__c> newList,
        Map<Id, Trailblazer_Profile__c> oldMap
    ) {
        Set<Id> profileIdsWithUserChange = new Set<Id>();
        for (Trailblazer_Profile__c p : newList) {
            Trailblazer_Profile__c oldRec = oldMap != null ? oldMap.get(p.Id) : null;
            if (oldRec != null && p.User__c != oldRec.User__c) {
                profileIdsWithUserChange.add(p.Id);
            }
        }
        if (profileIdsWithUserChange.isEmpty()) {
            return;
        }

        Set<Id> groupIds = new Set<Id>();
        for (Study_Group_Member__c m : [
            SELECT Study_Group__c
            FROM Study_Group_Member__c
            WHERE Trailblazer_Profile__c IN :profileIdsWithUserChange
        ]) {
            groupIds.add(m.Study_Group__c);
        }
        TrailblazerProfileSharingService.enqueueRecalculationForGroups(groupIds);
    }

    private static void handleTrailheadUsernameChanges(
        List<Trailblazer_Profile__c> newList,
        Map<Id, Trailblazer_Profile__c> oldMap
    ) {
        Set<Id> profilesNeedingResolution = new Set<Id>();

        for (Trailblazer_Profile__c p : newList) {
            // Only consider profiles where the username is populated and the
            // Trailhead Id is currently blank.
            if (String.isBlank(p.Trailhead_Username__c)) {
                continue;
            }
            if (!String.isBlank(p.Trailhead_Id__c)) {
                continue;
            }

            Boolean usernameChanged = false;
            if (oldMap == null) {
                usernameChanged = true;
            } else {
                Trailblazer_Profile__c oldRec = oldMap.get(p.Id);
                if (
                    oldRec == null ||
                    p.Trailhead_Username__c != oldRec.Trailhead_Username__c
                ) {
                    usernameChanged = true;
                }
            }

            if (usernameChanged) {
                profilesNeedingResolution.add(p.Id);
            }
        }

        if (!profilesNeedingResolution.isEmpty()) {
            System.enqueueJob(
                new TrailblazerProfileUsernameResolver(profilesNeedingResolution)
            );
        }
    }
}
