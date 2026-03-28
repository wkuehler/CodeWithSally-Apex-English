/**
 * Maintains Apex-managed sharing on Trailblazer_Profile__c so study group leaders
 * have read access to their team members' profiles. Uses sharing reason Leader_Team_Access.
 * Call recalculateLeaderSharesForGroups() when membership or leader role changes.
 * From triggers, use enqueueRecalculationForGroups() so recalculation runs in system context.
 */
public with sharing class TrailblazerProfileSharingService {

    private static final String ROW_CAUSE = Schema.Trailblazer_Profile__Share.RowCause.Leader_Team_Access__c;

    /**
     * Enqueue recalculation for the given study groups. Use from triggers so share
     * DML runs in system context (required for Apex-managed sharing).
     */
    public static void enqueueRecalculationForGroups(Set<Id> groupIds) {
        if (groupIds == null || groupIds.isEmpty()) {
            return;
        }
        System.enqueueJob(new TrailblazerProfileSharingQueueable(new List<Id>(groupIds)));
    }

    /**
     * Recalculate leader-based read shares for the given study groups.
     * For each group, leaders (Role__c = 'Leader') get read access to all members' Trailblazer_Profile__c
     * via the profile's User__c (Salesforce User Id). Removes stale shares and inserts current ones.
     */
    public static void recalculateLeaderSharesForGroups(Set<Id> groupIds) {
        if (groupIds == null || groupIds.isEmpty()) {
            return;
        }

        List<Study_Group_Member__c> members = [
            SELECT Id,
                   Study_Group__c,
                   Trailblazer_Profile__c,
                   Role__c
            FROM Study_Group_Member__c
            WHERE Study_Group__c IN :groupIds
              AND Trailblazer_Profile__c != null
        ];

        Set<Id> leaderProfileIds = new Set<Id>();
        Set<Id> memberProfileIds = new Set<Id>();
        Map<Id, Set<Id>> groupToMemberProfileIds = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> groupToLeaderProfileIds = new Map<Id, Set<Id>>();

        for (Study_Group_Member__c m : members) {
            if (!groupToMemberProfileIds.containsKey(m.Study_Group__c)) {
                groupToMemberProfileIds.put(m.Study_Group__c, new Set<Id>());
                groupToLeaderProfileIds.put(m.Study_Group__c, new Set<Id>());
            }
            groupToMemberProfileIds.get(m.Study_Group__c).add(m.Trailblazer_Profile__c);
            memberProfileIds.add(m.Trailblazer_Profile__c);
            if (m.Role__c == 'Leader') {
                groupToLeaderProfileIds.get(m.Study_Group__c).add(m.Trailblazer_Profile__c);
                leaderProfileIds.add(m.Trailblazer_Profile__c);
            }
        }

        if (leaderProfileIds.isEmpty() || memberProfileIds.isEmpty()) {
            deleteExistingLeaderShares(memberProfileIds);
            return;
        }

        Map<Id, Id> profileIdToUserId = new Map<Id, Id>();
        for (Trailblazer_Profile__c p : [
            SELECT Id, User__c
            FROM Trailblazer_Profile__c
            WHERE Id IN :leaderProfileIds
              AND User__c != null
        ]) {
            profileIdToUserId.put(p.Id, p.User__c);
        }

        List<Trailblazer_Profile__Share> toInsert = new List<Trailblazer_Profile__Share>();
        for (Id gid : groupIds) {
            Set<Id> leaderProfiles = groupToLeaderProfileIds.get(gid);
            Set<Id> memberProfiles = groupToMemberProfileIds.get(gid);
            if (leaderProfiles == null || memberProfiles == null) {
                continue;
            }
            for (Id leaderProfileId : leaderProfiles) {
                Id leaderUserId = profileIdToUserId.get(leaderProfileId);
                if (leaderUserId == null) {
                    continue;
                }
                for (Id memberProfileId : memberProfiles) {
                    toInsert.add(buildShare(memberProfileId, leaderUserId));
                }
            }
        }

        deleteExistingLeaderShares(memberProfileIds);

        Set<String> seen = new Set<String>();
        List<Trailblazer_Profile__Share> deduped = new List<Trailblazer_Profile__Share>();
        for (Trailblazer_Profile__Share s : toInsert) {
            String key = s.ParentId + '-' + s.UserOrGroupId;
            if (seen.contains(key)) {
                continue;
            }
            seen.add(key);
            deduped.add(s);
        }

        if (!deduped.isEmpty()) {
            insert deduped;
        }
    }

    private static Trailblazer_Profile__Share buildShare(Id parentId, Id userOrGroupId) {
        Trailblazer_Profile__Share s = new Trailblazer_Profile__Share();
        s.ParentId = parentId;
        s.UserOrGroupId = userOrGroupId;
        s.AccessLevel = 'Read';
        s.RowCause = ROW_CAUSE;
        return s;
    }

    private static void deleteExistingLeaderShares(Set<Id> parentIds) {
        if (parentIds == null || parentIds.isEmpty()) {
            return;
        }
        List<Trailblazer_Profile__Share> existing = [
            SELECT Id
            FROM Trailblazer_Profile__Share
            WHERE ParentId IN :parentIds
              AND RowCause = :ROW_CAUSE
        ];
        if (!existing.isEmpty()) {
            delete existing;
        }
    }

    /**
     * Queueable that runs recalculateLeaderSharesForGroups in system context.
     */
    public class TrailblazerProfileSharingQueueable implements Queueable {
        private List<Id> groupIds;

        public TrailblazerProfileSharingQueueable(List<Id> groupIds) {
            this.groupIds = groupIds != null ? groupIds : new List<Id>();
        }

        public void execute(QueueableContext ctx) {
            if (groupIds.isEmpty()) {
                return;
            }
            TrailblazerProfileSharingService.recalculateLeaderSharesForGroups(new Set<Id>(groupIds));
        }
    }
}
