public with sharing class StreakService {

    public static void calculateStreaks(Set<Id> profileIds) {
        if (profileIds == null || profileIds.isEmpty()) {
            return;
        }

        Streak_Config__mdt config = Streak_Config__mdt.getInstance('Default_Streak_Config');
        if (config == null) {
            return;
        }

        Map<Id, Trailblazer_Profile__c> profiles = new Map<Id, Trailblazer_Profile__c>(
            [
                SELECT Id,
                       Current_Streak__c,
                       Longest_Streak__c,
                       Last_Badge_Date__c
                FROM Trailblazer_Profile__c
                WHERE Id IN :profileIds
            ]
        );
        if (profiles.isEmpty()) {
            return;
        }

        Date today = Date.today();
        Date yesterday = today.addDays(-1);

        Set<Id> profilesWithBadge = new Set<Id>();
        for (AggregateResult ar : [
            SELECT Trailblazer_Profile__c profileId, COUNT(Id) cnt
            FROM Badge__c
            WHERE Trailblazer_Profile__c IN :profiles.keySet()
              AND Earned_Date__c = :yesterday
            GROUP BY Trailblazer_Profile__c
        ]) {
            profilesWithBadge.add((Id) ar.get('profileId'));
        }

        Map<Id, Integer> freezesThisMonth = new Map<Id, Integer>();
        Date firstOfMonth = Date.newInstance(today.year(), today.month(), 1);
        Date lastOfMonth = firstOfMonth.addMonths(1).addDays(-1);
        for (AggregateResult ar2 : [
            SELECT Trailblazer_Profile__c profileId, COUNT(Id) cnt
            FROM Streak_Freeze__c
            WHERE Trailblazer_Profile__c IN :profiles.keySet()
              AND Used_Date__c >= :firstOfMonth
              AND Used_Date__c <= :lastOfMonth
            GROUP BY Trailblazer_Profile__c
        ]) {
            freezesThisMonth.put(
                (Id) ar2.get('profileId'),
                (Integer) ar2.get('cnt')
            );
        }

        List<Trailblazer_Profile__c> toUpdate = new List<Trailblazer_Profile__c>();
        List<Streak_Freeze__c> freezesToInsert = new List<Streak_Freeze__c>();
        List<XPService.XPEvent> milestoneEvents = new List<XPService.XPEvent>();
        Set<Integer> milestones = parseMilestones(config.Milestone_Days__c);

        for (Trailblazer_Profile__c p : profiles.values()) {
            Boolean hadQualifying = profilesWithBadge.contains(p.Id);
            Decimal current = p.Current_Streak__c != null ? p.Current_Streak__c : 0;
            Decimal longest = p.Longest_Streak__c != null ? p.Longest_Streak__c : 0;

            if (hadQualifying) {
                current += 1;
            } else if (config.Freeze_Allowed__c) {
                Integer used = freezesThisMonth.containsKey(p.Id)
                    ? freezesThisMonth.get(p.Id)
                    : 0;
                Integer maxFreezes = config.Max_Freeze_Days__c != null
                    ? Integer.valueOf(config.Max_Freeze_Days__c)
                    : 0;
                if (used < maxFreezes) {
                    Streak_Freeze__c freeze = new Streak_Freeze__c();
                    freeze.Trailblazer_Profile__c = p.Id;
                    freeze.Used_Date__c = today;
                    freezesToInsert.add(freeze);
                } else {
                    current = 0;
                }
            } else {
                current = 0;
            }

            if (current > longest) {
                longest = current;
            }

            p.Current_Streak__c = current;
            p.Longest_Streak__c = longest;
            toUpdate.add(p);

            if (milestones.contains(Integer.valueOf(current))) {
                Map<String, Object> ctx = new Map<String, Object>();
                ctx.put('streakDays', current);
                milestoneEvents.add(
                    new XPService.XPEvent(
                        p.Id,
                        'Streak_Day',
                        ctx
                    )
                );
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
        if (!freezesToInsert.isEmpty()) {
            insert freezesToInsert;
        }
        if (!milestoneEvents.isEmpty()) {
            XPService.awardXP(milestoneEvents);
        }
    }

    private static Set<Integer> parseMilestones(String milestonesString) {
        Set<Integer> result = new Set<Integer>();
        if (String.isBlank(milestonesString)) {
            return result;
        }
        for (String part : milestonesString.split(',')) {
            String trimmed = part.trim();
            if (trimmed == null || trimmed == '') {
                continue;
            }
            try {
                result.add(Integer.valueOf(trimmed));
            } catch (Exception e) {
            }
        }
        return result;
    }
}

