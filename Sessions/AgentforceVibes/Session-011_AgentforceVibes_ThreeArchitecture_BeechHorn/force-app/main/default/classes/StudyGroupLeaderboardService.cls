public with sharing class StudyGroupLeaderboardService {

    @AuraEnabled(cacheable=true)
    public static List<MemberRow> getMembers(Id studyGroupId) {
        List<MemberRow> rows = new List<MemberRow>();

        if (studyGroupId == null) {
            return rows;
        }

        List<Study_Group_Member__c> memberships = [
            SELECT Id,
                   Study_Group__c,
                   Role__c,
                   Joined_Date__c,
                   Group_Name_Snapshot__c,
                   Member_Name_Snapshot__c,
                   Total_Badges_Snapshot__c,
                   Current_Streak_Snapshot__c,
                   XP_Total_Snapshot__c,
                   Group_Name__c,
                   Member_Name__c,
                   Total_Badges__c,
                   Current_Streak__c,
                   XP_Total__c
            FROM Study_Group_Member__c
            WHERE Study_Group__c = :studyGroupId
            ORDER BY XP_Total_Snapshot__c DESC,
                     Total_Badges_Snapshot__c DESC,
                     Current_Streak_Snapshot__c DESC,
                     Joined_Date__c ASC
        ];

        Decimal maxXp = 0;
        for (Study_Group_Member__c membership : memberships) {
            MemberRow row = new MemberRow();
            row.role = membership.Role__c;
            row.joinedDate = membership.Joined_Date__c;
            row.groupName = coalesce(
                membership.Group_Name_Snapshot__c,
                membership.Group_Name__c,
                'Study Group'
            );
            row.memberName = coalesce(
                membership.Member_Name_Snapshot__c,
                membership.Member_Name__c,
                'Member'
            );
            row.totalBadges = toInteger(
                membership.Total_Badges_Snapshot__c,
                membership.Total_Badges__c
            );
            row.currentStreak = toInteger(
                membership.Current_Streak_Snapshot__c,
                membership.Current_Streak__c
            );
            row.xpTotal = toDecimal(
                membership.XP_Total_Snapshot__c,
                membership.XP_Total__c
            );
            rows.add(row);
            if (row.xpTotal > maxXp) {
                maxXp = row.xpTotal;
            }
        }

        if (maxXp <= 0) {
            maxXp = 1;
        }

        Integer rankCounter = 1;
        for (MemberRow row : rows) {
            row.rank = rankCounter++;
            row.xpPercent = Integer.valueOf(
                ((row.xpTotal * 100) / maxXp).setScale(0)
            );
        }

        return rows;
    }

    @AuraEnabled(cacheable=true)
    public static List<MemberRow> getGlobalTopMembers(Integer limitSize) {
        Integer maxSize = (limitSize == null || limitSize <= 0) ? 25 : limitSize;

        List<Study_Group_Member__c> memberships = [
            SELECT Id,
                   Study_Group__c,
                   Role__c,
                   Joined_Date__c,
                   Group_Name_Snapshot__c,
                   Member_Name_Snapshot__c,
                   Total_Badges_Snapshot__c,
                   Current_Streak_Snapshot__c,
                   XP_Total_Snapshot__c,
                   Group_Name__c,
                   Member_Name__c,
                   Total_Badges__c,
                   Current_Streak__c,
                   XP_Total__c
            FROM Study_Group_Member__c
            ORDER BY XP_Total_Snapshot__c DESC,
                     Total_Badges_Snapshot__c DESC,
                     Current_Streak_Snapshot__c DESC,
                     Joined_Date__c ASC
            LIMIT :maxSize
        ];

        List<MemberRow> rows = new List<MemberRow>();
        Decimal maxXp = 0;

        for (Study_Group_Member__c membership : memberships) {
            MemberRow row = new MemberRow();
            row.role = membership.Role__c;
            row.joinedDate = membership.Joined_Date__c;
            row.groupName = coalesce(
                membership.Group_Name_Snapshot__c,
                membership.Group_Name__c,
                'Study Group'
            );
            row.memberName = coalesce(
                membership.Member_Name_Snapshot__c,
                membership.Member_Name__c,
                'Member'
            );
            row.totalBadges = toInteger(
                membership.Total_Badges_Snapshot__c,
                membership.Total_Badges__c
            );
            row.currentStreak = toInteger(
                membership.Current_Streak_Snapshot__c,
                membership.Current_Streak__c
            );
            row.xpTotal = toDecimal(
                membership.XP_Total_Snapshot__c,
                membership.XP_Total__c
            );
            rows.add(row);
            if (row.xpTotal > maxXp) {
                maxXp = row.xpTotal;
            }
        }

        if (maxXp <= 0) {
            maxXp = 1;
        }

        Integer rankCounter = 1;
        for (MemberRow row : rows) {
            row.rank = rankCounter++;
            row.xpPercent = Integer.valueOf(
                ((row.xpTotal * 100) / maxXp).setScale(0)
            );
        }

        return rows;
    }

    private static String coalesce(String primaryValue, String secondaryValue, String fallbackValue) {
        if (!String.isBlank(primaryValue)) {
            return primaryValue;
        }
        if (!String.isBlank(secondaryValue)) {
            return secondaryValue;
        }
        return fallbackValue;
    }

    private static Integer toInteger(Decimal primaryValue, Decimal secondaryValue) {
        Decimal value = primaryValue != null ? primaryValue : secondaryValue;
        return value == null ? 0 : value.intValue();
    }

    private static Decimal toDecimal(Decimal primaryValue, Decimal secondaryValue) {
        Decimal value = primaryValue != null ? primaryValue : secondaryValue;
        return value == null ? 0 : value;
    }

    public class MemberRow {
        @AuraEnabled public Integer rank { get; set; }
        @AuraEnabled public String groupName { get; set; }
        @AuraEnabled public String memberName { get; set; }
        @AuraEnabled public String role { get; set; }
        @AuraEnabled public Date joinedDate { get; set; }
        @AuraEnabled public Integer totalBadges { get; set; }
        @AuraEnabled public Integer currentStreak { get; set; }
        @AuraEnabled public Decimal xpTotal { get; set; }
        @AuraEnabled public Integer xpPercent { get; set; }
    }
}

