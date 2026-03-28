public with sharing class AchievementService {

    public static void evaluateAchievements(Set<Id> profileIds) {
        if (profileIds == null || profileIds.isEmpty()) {
            return;
        }

        Map<String, Achievement_Definition__mdt> defsByName = Achievement_Definition__mdt.getAll();
        if (defsByName == null || defsByName.isEmpty()) {
            return;
        }

        Map<Id, Trailblazer_Profile__c> profiles = new Map<Id, Trailblazer_Profile__c>(
            [
                SELECT Id,
                       Total_Badges__c,
                       Total_Certifications__c,
                       Current_Streak__c,
                       XP_Total__c,
                       Current_Level__c
                FROM Trailblazer_Profile__c
                WHERE Id IN :profileIds
            ]
        );
        if (profiles.isEmpty()) {
            return;
        }

        Map<Id, Set<String>> alreadyEarned = new Map<Id, Set<String>>();
        for (Earned_Achievement__c ea : [
            SELECT Trailblazer_Profile__c,
                   Definition_Id__c
            FROM Earned_Achievement__c
            WHERE Trailblazer_Profile__c IN :profiles.keySet()
        ]) {
            if (!alreadyEarned.containsKey(ea.Trailblazer_Profile__c)) {
                alreadyEarned.put(ea.Trailblazer_Profile__c, new Set<String>());
            }
            alreadyEarned.get(ea.Trailblazer_Profile__c).add(ea.Definition_Id__c);
        }

        List<Earned_Achievement__c> toInsert = new List<Earned_Achievement__c>();
        List<XPService.XPEvent> bonusEvents = new List<XPService.XPEvent>();

        for (Id profileId : profiles.keySet()) {
            Trailblazer_Profile__c p = profiles.get(profileId);
            for (Achievement_Definition__mdt def : defsByName.values()) {
                String defKey = def.DeveloperName;
                if (alreadyEarned.containsKey(profileId)
                    && alreadyEarned.get(profileId).contains(defKey)) {
                    continue;
                }
                if (!meetsCriteria(p, def)) {
                    continue;
                }

                Earned_Achievement__c ea = new Earned_Achievement__c();
                ea.Trailblazer_Profile__c = profileId;
                ea.Achievement_Name__c = def.Achievement_Name__c;
                ea.Earned_Date__c = Date.today();
                ea.Definition_Id__c = def.DeveloperName;
                toInsert.add(ea);

                if (def.Bonus_XP__c != null && def.Bonus_XP__c > 0) {
                    Map<String, Object> ctx = new Map<String, Object>();
                    ctx.put('achievement', def.Achievement_Name__c);
                    ctx.put('definition', def.DeveloperName);
                    ctx.put('bonusXP', def.Bonus_XP__c);
                    bonusEvents.add(
                        new XPService.XPEvent(
                            profileId,
                            'Achievement_Bonus',
                            ctx
                        )
                    );
                }
            }
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
        }

        if (!bonusEvents.isEmpty()) {
            XPService.awardXP(bonusEvents);
        }
    }

    private static Boolean meetsCriteria(
        Trailblazer_Profile__c profile,
        Achievement_Definition__mdt def
    ) {
        if (def == null || String.isBlank(def.Criteria_Type__c)) {
            return false;
        }
        Decimal threshold = def.Criteria_Value__c;
        if (threshold == null) {
            return false;
        }

        String criteria = def.Criteria_Type__c;
        if (criteria == 'Badge_Count') {
            Decimal count = profile.Total_Badges__c != null
                ? profile.Total_Badges__c
                : 0;
            return count >= threshold;
        }
        if (criteria == 'Streak_Days') {
            Decimal days = profile.Current_Streak__c != null
                ? profile.Current_Streak__c
                : 0;
            return days >= threshold;
        }
        if (criteria == 'Cert_Count') {
            Decimal certs = profile.Total_Certifications__c != null
                ? profile.Total_Certifications__c
                : 0;
            return certs >= threshold;
        }
        if (criteria == 'Points_Total') {
            Decimal points = profile.Total_Points__c != null
                ? profile.Total_Points__c
                : 0;
            return points >= threshold;
        }

        return false;
    }
}

