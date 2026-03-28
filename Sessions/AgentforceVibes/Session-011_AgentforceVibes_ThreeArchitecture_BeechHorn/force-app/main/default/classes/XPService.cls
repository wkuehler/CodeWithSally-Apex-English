public with sharing class XPService {

    public class XPEvent {
        public Id profileId;
        public String actionType;
        public Map<String, Object> context;

        public XPEvent(Id profileId, String actionType, Map<String, Object> context) {
            this.profileId = profileId;
            this.actionType = actionType;
            this.context = context == null ? new Map<String, Object>() : context;
        }
    }

    public static void awardXP(Id profileId, String actionType, Map<String, Object> context) {
        if (profileId == null || String.isBlank(actionType)) {
            return;
        }
        List<XPEvent> events = new List<XPEvent>{
            new XPEvent(profileId, actionType, context)
        };
        processEvents(events);
    }

    public static void awardXP(List<XPEvent> events) {
        if (events == null || events.isEmpty()) {
            return;
        }
        processEvents(events);
    }

    /**
     * Awards XP for newly synced badges and certs (used by TrailheadSyncOrchestrator to avoid cross-class inner type reference).
     * One Badge_Earned event per new badge (context badgeType if present), one Cert_Earned per new cert.
     */
    public static void awardXPForNewBadgesAndCerts(
        Id profileId,
        List<String> newBadgeTypes,
        Integer newCertCount
    ) {
        if (profileId == null) {
            return;
        }
        List<XPEvent> events = new List<XPEvent>();
        if (newBadgeTypes != null) {
            for (String badgeType : newBadgeTypes) {
                Map<String, Object> ctx = String.isNotBlank(badgeType)
                    ? new Map<String, Object>{ 'badgeType' => badgeType }
                    : new Map<String, Object>();
                events.add(new XPEvent(profileId, 'Badge_Earned', ctx));
            }
        }
        if (newCertCount != null && newCertCount > 0) {
            for (Integer i = 0; i < newCertCount; i++) {
                events.add(new XPEvent(profileId, 'Cert_Earned', new Map<String, Object>()));
            }
        }
        if (!events.isEmpty()) {
            processEvents(events);
        }
    }

    private static void processEvents(List<XPEvent> events) {
        Set<Id> profileIds = new Set<Id>();
        for (XPEvent e : events) {
            if (e.profileId != null) {
                profileIds.add(e.profileId);
            }
        }
        Map<Id, Trailblazer_Profile__c> profilesById = new Map<Id, Trailblazer_Profile__c>();
        if (!profileIds.isEmpty()) {
            profilesById = new Map<Id, Trailblazer_Profile__c>(
                [
                    SELECT Id,
                           XP_Total__c,
                           Current_Level__c
                    FROM Trailblazer_Profile__c
                    WHERE Id IN :profileIds
                ]
            );
        }

        Map<String, XP_Rule__mdt> xpRules = XP_Rule__mdt.getAll();
        Map<String, Level_Definition__mdt> levelDefs = Level_Definition__mdt.getAll();

        List<XP_Transaction__c> transactions = new List<XP_Transaction__c>();
        Map<Id, Decimal> deltaByProfile = new Map<Id, Decimal>();

        for (XPEvent e : events) {
            Trailblazer_Profile__c profile = profilesById.get(e.profileId);
            if (profile == null) {
                continue;
            }

            Decimal xpAmount = calculateXPAmount(e, xpRules);
            if (xpAmount == null || xpAmount == 0) {
                continue;
            }

            Decimal existingDelta = deltaByProfile.containsKey(e.profileId)
                ? deltaByProfile.get(e.profileId)
                : 0;
            deltaByProfile.put(e.profileId, existingDelta + xpAmount);

            XP_Transaction__c txn = new XP_Transaction__c();
            txn.Trailblazer_Profile__c = e.profileId;
            txn.Action_Type__c = e.actionType;
            txn.XP_Amount__c = xpAmount;
            txn.Transaction_Date__c = System.now();
            txn.Notes__c = buildNotes(e);
            transactions.add(txn);
        }

        if (!transactions.isEmpty()) {
            insert transactions;
        }

        if (!deltaByProfile.isEmpty()) {
            for (Id profileId : deltaByProfile.keySet()) {
                Trailblazer_Profile__c p = profilesById.get(profileId);
                if (p == null) {
                    continue;
                }
                Decimal currentXp = p.XP_Total__c != null ? p.XP_Total__c : 0;
                p.XP_Total__c = currentXp + deltaByProfile.get(profileId);
                Decimal resolvedLevel = resolveLevel(p.XP_Total__c, levelDefs);
                if (resolvedLevel != null) {
                    p.Current_Level__c = resolvedLevel;
                }
            }
            update profilesById.values();
        }
    }

    private static Decimal calculateXPAmount(
        XPEvent event,
        Map<String, XP_Rule__mdt> xpRules
    ) {
        if (xpRules == null || xpRules.isEmpty()) {
            return null;
        }

        List<XP_Rule__mdt> matchingRules = new List<XP_Rule__mdt>();
        for (XP_Rule__mdt rule : xpRules.values()) {
            if (rule.Action_Type__c != event.actionType) {
                continue;
            }
            if (matchesContext(rule.Multiplier_Conditions__c, event.context)) {
                matchingRules.add(rule);
            }
        }

        Decimal total = 0;
        for (XP_Rule__mdt rule : matchingRules) {
            if (rule.XP_Value__c != null) {
                total += rule.XP_Value__c;
            }
        }

        return total;
    }

    private static Boolean matchesContext(String conditionString, Map<String, Object> context) {
        if (String.isBlank(conditionString)) {
            return true;
        }
        if (context == null || context.isEmpty()) {
            return false;
        }

        List<String> parts = conditionString.split(',');
        for (String part : parts) {
            List<String> keyVal = part.split('=');
            if (keyVal.size() != 2) {
                continue;
            }
            String key = keyVal[0].trim();
            String expected = keyVal[1].trim();
            if (!context.containsKey(key)) {
                return false;
            }
            Object actual = context.get(key);
            if (actual == null || String.valueOf(actual) != expected) {
                return false;
            }
        }
        return true;
    }

    /**
     * Resolves the numeric level (Level_Number__c from Level_Definition__mdt) for the given XP total.
     * Returns null if no matching level exists, so unsupported or missing metadata does not overwrite Current_Level__c.
     */
    private static Decimal resolveLevel(Decimal xpTotal, Map<String, Level_Definition__mdt> levelDefs) {
        if (xpTotal == null || levelDefs == null || levelDefs.isEmpty()) {
            return null;
        }

        Decimal levelNumber;
        Decimal bestThreshold;
        for (Level_Definition__mdt def : levelDefs.values()) {
            if (def.XP_Threshold__c == null) {
                continue;
            }
            if (def.XP_Threshold__c <= xpTotal) {
                if (bestThreshold == null || def.XP_Threshold__c > bestThreshold) {
                    bestThreshold = def.XP_Threshold__c;
                    levelNumber = def.Level_Number__c;
                }
            }
        }
        return levelNumber;
    }

    private static String buildNotes(XPEvent e) {
        List<String> parts = new List<String>();
        parts.add('action=' + e.actionType);
        if (e.context != null && !e.context.isEmpty()) {
            for (String key : e.context.keySet()) {
                Object val = e.context.get(key);
                parts.add(key + '=' + String.valueOf(val));
            }
        }
        return String.join(parts, '; ');
    }
}

