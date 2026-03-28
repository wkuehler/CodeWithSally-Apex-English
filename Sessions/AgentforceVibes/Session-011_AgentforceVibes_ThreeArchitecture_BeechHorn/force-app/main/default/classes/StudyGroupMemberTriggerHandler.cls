public with sharing class StudyGroupMemberTriggerHandler {

    public static void handle(
        System.TriggerOperation op,
        List<Study_Group_Member__c> newList,
        Map<Id, Study_Group_Member__c> oldMap
    ) {
        switch on op {
            when BEFORE_INSERT {
                beforeInsert(newList);
            }
            when BEFORE_UPDATE {
                beforeUpdate(newList, oldMap);
            }
            when AFTER_INSERT {
                afterInsert(newList);
            }
            when AFTER_UPDATE {
                afterUpdate(newList, oldMap);
            }
            when AFTER_DELETE {
                afterDelete(oldMap);
            }
            when AFTER_UNDELETE {
                afterUndelete(newList);
            }
        }
    }

    private static void beforeInsert(List<Study_Group_Member__c> newList) {
        hydrateSnapshots(newList);
        enforceCapacity(newList);
    }

    private static void beforeUpdate(
        List<Study_Group_Member__c> newList,
        Map<Id, Study_Group_Member__c> oldMap
    ) {
        hydrateSnapshots(newList);
        List<Study_Group_Member__c> changedGroup = new List<Study_Group_Member__c>();
        for (Study_Group_Member__c member : newList) {
            Study_Group_Member__c oldRec = oldMap != null ? oldMap.get(member.Id) : null;
            if (oldRec != null && member.Study_Group__c != oldRec.Study_Group__c) {
                changedGroup.add(member);
            }
        }
        if (!changedGroup.isEmpty()) {
            enforceCapacity(changedGroup);
        }
    }

    public static void refreshProfileSnapshots(Set<Id> profileIds) {
        if (profileIds == null || profileIds.isEmpty()) {
            return;
        }

        List<Study_Group_Member__c> members = [
            SELECT Id,
                   Study_Group__c,
                   Trailblazer_Profile__c
            FROM Study_Group_Member__c
            WHERE Trailblazer_Profile__c IN :profileIds
        ];
        if (members.isEmpty()) {
            return;
        }

        hydrateSnapshots(members);
        update members;
    }

    @TestVisible
    private static void hydrateSnapshots(List<Study_Group_Member__c> members) {
        if (members == null || members.isEmpty()) {
            return;
        }

        Set<Id> groupIds = new Set<Id>();
        Set<Id> profileIds = new Set<Id>();
        for (Study_Group_Member__c member : members) {
            if (member.Study_Group__c != null) {
                groupIds.add(member.Study_Group__c);
            }
            if (member.Trailblazer_Profile__c != null) {
                profileIds.add(member.Trailblazer_Profile__c);
            }
        }

        Map<Id, Study_Group__c> groupsById = groupIds.isEmpty()
            ? new Map<Id, Study_Group__c>()
            : new Map<Id, Study_Group__c>([
                SELECT Id, Group_Name__c
                FROM Study_Group__c
                WHERE Id IN :groupIds
            ]);
        Map<Id, Trailblazer_Profile__c> profilesById = profileIds.isEmpty()
            ? new Map<Id, Trailblazer_Profile__c>()
            : new Map<Id, Trailblazer_Profile__c>([
                SELECT Id,
                       Trailhead_Username__c,
                       Total_Badges__c,
                       Current_Streak__c,
                       XP_Total__c
                FROM Trailblazer_Profile__c
                WHERE Id IN :profileIds
            ]);

        for (Study_Group_Member__c member : members) {
            Study_Group__c groupRecord = groupsById.get(member.Study_Group__c);
            Trailblazer_Profile__c profile = profilesById.get(member.Trailblazer_Profile__c);

            member.Group_Name_Snapshot__c = groupRecord != null
                ? groupRecord.Group_Name__c
                : null;
            member.Member_Name_Snapshot__c = profile != null
                ? profile.Trailhead_Username__c
                : null;
            member.Total_Badges_Snapshot__c = profile != null
                ? profile.Total_Badges__c
                : null;
            member.Current_Streak_Snapshot__c = profile != null
                ? profile.Current_Streak__c
                : null;
            member.XP_Total_Snapshot__c = profile != null
                ? profile.XP_Total__c
                : null;
        }
    }

    @TestVisible
    private static void enforceCapacity(List<Study_Group_Member__c> members) {
        Set<Id> groupIds = new Set<Id>();
        for (Study_Group_Member__c m : members) {
            if (m.Study_Group__c != null) {
                groupIds.add(m.Study_Group__c);
            }
        }
        if (groupIds.isEmpty()) {
            return;
        }

        Map<Id, Study_Group__c> groups = new Map<Id, Study_Group__c>([
            SELECT Id, Max_Members__c
            FROM Study_Group__c
            WHERE Id IN :groupIds
            FOR UPDATE
        ]);

        Map<Id, Integer> existingCounts = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT Study_Group__c grp, COUNT(Id) cnt
            FROM Study_Group_Member__c
            WHERE Study_Group__c IN :groupIds
            GROUP BY Study_Group__c
        ]) {
            existingCounts.put((Id) ar.get('grp'), (Integer) ar.get('cnt'));
        }

        Map<Id, Integer> runningCounts = new Map<Id, Integer>();
        for (Id gid : groupIds) {
            runningCounts.put(gid, existingCounts.containsKey(gid) ? existingCounts.get(gid) : 0);
        }

        for (Study_Group_Member__c m : members) {
            if (m.Study_Group__c == null) {
                continue;
            }
            Study_Group__c groupRecord = groups.get(m.Study_Group__c);
            if (groupRecord == null || groupRecord.Max_Members__c == null) {
                continue;
            }
            Integer currentCount = runningCounts.get(m.Study_Group__c);
            if (currentCount >= groupRecord.Max_Members__c.intValue()) {
                m.addError('This study group is already full.');
            } else {
                runningCounts.put(m.Study_Group__c, currentCount + 1);
            }
        }
    }

    private static void afterInsert(List<Study_Group_Member__c> newList) {
        adjustMemberCounts(newList, 1);
        enqueueLeaderShareRecalc(collectGroupIds(newList));
    }

    private static void afterDelete(Map<Id, Study_Group_Member__c> oldMap) {
        if (oldMap == null || oldMap.isEmpty()) {
            return;
        }
        adjustMemberCounts(oldMap.values(), -1);
        enqueueLeaderShareRecalc(collectGroupIds(oldMap.values()));
    }

    private static void afterUndelete(List<Study_Group_Member__c> newList) {
        adjustMemberCounts(newList, 1);
        enqueueLeaderShareRecalc(collectGroupIds(newList));
    }

    private static void afterUpdate(
        List<Study_Group_Member__c> newList,
        Map<Id, Study_Group_Member__c> oldMap
    ) {
        Set<Id> groupIds = new Set<Id>();
        for (Study_Group_Member__c m : newList) {
            Study_Group_Member__c oldRec = oldMap != null ? oldMap.get(m.Id) : null;
            if (oldRec != null) {
                if (m.Study_Group__c != oldRec.Study_Group__c) {
                    groupIds.add(m.Study_Group__c);
                    groupIds.add(oldRec.Study_Group__c);
                }
                if (m.Role__c != oldRec.Role__c) {
                    if (m.Study_Group__c != null) {
                        groupIds.add(m.Study_Group__c);
                    }
                }
            }
        }
        enqueueLeaderShareRecalc(groupIds);
    }

    @TestVisible
    private static void adjustMemberCounts(
        Iterable<Study_Group_Member__c> members,
        Integer delta
    ) {
        if (delta == 0) {
            return;
        }

        Set<Id> groupIds = new Set<Id>();
        for (Study_Group_Member__c m : members) {
            if (m.Study_Group__c != null) {
                groupIds.add(m.Study_Group__c);
            }
        }
        if (groupIds.isEmpty()) {
            return;
        }

        Map<Id, Study_Group__c> groups = new Map<Id, Study_Group__c>([
            SELECT Id, Member_Count__c
            FROM Study_Group__c
            WHERE Id IN :groupIds
            FOR UPDATE
        ]);

        Map<Id, Integer> deltas = new Map<Id, Integer>();
        for (Id gid : groupIds) {
            deltas.put(gid, 0);
        }
        for (Study_Group_Member__c m : members) {
            if (m.Study_Group__c != null && deltas.containsKey(m.Study_Group__c)) {
                deltas.put(m.Study_Group__c, deltas.get(m.Study_Group__c) + delta);
            }
        }

        List<Study_Group__c> updates = new List<Study_Group__c>();
        for (Id gid : deltas.keySet()) {
            Study_Group__c g = groups.get(gid);
            if (g == null) {
                continue;
            }
            Integer current = g.Member_Count__c == null ? 0 : Integer.valueOf(g.Member_Count__c);
            Integer newValue = current + deltas.get(gid);
            if (newValue < 0) {
                newValue = 0;
            }
            g.Member_Count__c = newValue;
            updates.add(g);
        }
        if (!updates.isEmpty()) {
            update updates;
        }
    }

    private static Set<Id> collectGroupIds(Iterable<Study_Group_Member__c> members) {
        Set<Id> groupIds = new Set<Id>();
        for (Study_Group_Member__c m : members) {
            if (m.Study_Group__c != null) {
                groupIds.add(m.Study_Group__c);
            }
        }
        return groupIds;
    }

    private static void enqueueLeaderShareRecalc(Set<Id> groupIds) {
        if (groupIds == null || groupIds.isEmpty()) {
            return;
        }
        TrailblazerProfileSharingService.enqueueRecalculationForGroups(groupIds);
    }
}

