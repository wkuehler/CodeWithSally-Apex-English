public with sharing class TrailheadSyncOrchestrator {

    public class SyncResult {
        public Integer badgesProcessed = 0;
        public Integer certsProcessed = 0;
        public Integer pagesProcessed = 0;
    }

    public static SyncResult syncProfile(Id profileId) {
        if (profileId == null) {
            return new SyncResult();
        }
        Trailblazer_Profile__c profile = [
            SELECT Id,
                   Trailhead_Id__c,
                   Trailhead_Username__c,
                   Total_Points__c,
                   Total_Badges__c,
                   Total_Superbadges__c,
                   Total_Certifications__c,
                   Current_Rank__c,
                   Last_Badge_Date__c,
                   Last_Sync_Date__c
            FROM Trailblazer_Profile__c
            WHERE Id = :profileId
            LIMIT 1
        ];

        // If the Trailhead Id is missing but we have a username, attempt to resolve
        // the canonical Trailhead_Id__c via the Trailhead GraphQL API before giving up.
        if (String.isBlank(profile.Trailhead_Id__c)) {
            if (!String.isBlank(profile.Trailhead_Username__c)) {
                try {
                    String resolvedId =
                        TrailheadApiService.resolveTrailheadIdFromUsername(
                            profile.Trailhead_Username__c
                        );
                    if (!String.isBlank(resolvedId)) {
                        profile.Trailhead_Id__c = resolvedId;
                        update profile;
                    } else {
                        insert new Integration_Log__c(
                            Trailblazer_Profile__c = profile.Id,
                            Operation_Type__c = 'Batch Sync',
                            Status__c = 'Failed',
                            Message__c =
                                'Trailhead_Id__c is blank and could not be resolved from Trailhead_Username__c.'
                        );
                        return new SyncResult();
                    }
                } catch (Exception e) {
                    insert new Integration_Log__c(
                        Trailblazer_Profile__c = profile.Id,
                        Operation_Type__c = 'Batch Sync',
                        Status__c = 'Failed',
                        Message__c =
                            'Error resolving Trailhead_Id__c from Trailhead_Username__c: '
                            + e.getMessage()
                    );
                    return new SyncResult();
                }
            } else {
                return new SyncResult();
            }
        }

        SyncResult result = new SyncResult();
        try {
            // The current Trailhead GraphQL schema supports slug-based profile lookup.
            // Use the stored username as the lookup key to avoid profile(id: ...) schema errors.
            TrailheadApiService.TrailheadRankData rankData =
                TrailheadApiService.fetchRankData(profile.Trailhead_Username__c);

            List<TrailheadApiService.TrailheadBadge> allBadges = new List<TrailheadApiService.TrailheadBadge>();
            String cursor;
            Integer pages = 0;

            while (true) {
                TrailheadApiService.TrailheadBadgeResult badgeResult =
                    TrailheadApiService.fetchBadges(
                        profile.Trailhead_Username__c,
                        null,
                        cursor
                    );
                pages++;
                result.pagesProcessed = pages;
                if (
                    pages == 1
                    && badgeResult != null
                    && rankData != null
                ) {
                    if (
                        rankData.totalBadges == null
                        && badgeResult.totalBadgesCount != null
                    ) {
                        rankData.totalBadges = badgeResult.totalBadgesCount;
                    }
                    if (
                        rankData.totalSuperbadges == null
                        && badgeResult.totalSuperbadgeCount != null
                    ) {
                        rankData.totalSuperbadges =
                            badgeResult.totalSuperbadgeCount;
                    }
                }
                if (badgeResult != null && badgeResult.badges != null) {
                    allBadges.addAll(badgeResult.badges);
                }
                cursor =
                    badgeResult != null ? badgeResult.endCursor : null;
                if (badgeResult == null || !badgeResult.hasNextPage) {
                    break;
                }
            }

            // Certification query shape is not supported by the current Trailhead schema.
            // Skip until the catalog query is updated to a schema-valid endpoint.
            TrailheadApiService.TrailheadCertResult certResult =
                new TrailheadApiService.TrailheadCertResult();
            certResult.certifications = new List<TrailheadApiService.TrailheadCertification>();

            Set<String> existingBadgeIds = getExistingBadgeIds(profile.Id);
            Set<String> existingCertIds = getExistingCertIds(profile.Id);

            upsertBadges(profile.Id, allBadges);
            upsertCerts(profile.Id, certResult.certifications);

            result.badgesProcessed = allBadges.size();
            result.certsProcessed = certResult.certifications != null
                ? certResult.certifications.size()
                : 0;

            applyProfileRollups(profile, rankData, allBadges, certResult.certifications);
            update profile;
            StudyGroupMemberTriggerHandler.refreshProfileSnapshots(
                new Set<Id>{ profile.Id }
            );

            applyPostSyncGamification(
                profile.Id,
                allBadges,
                certResult.certifications != null ? certResult.certifications : new List<TrailheadApiService.TrailheadCertification>(),
                existingBadgeIds,
                existingCertIds
            );
        } catch (Exception e) {
            insert new Integration_Log__c(
                Trailblazer_Profile__c = profile.Id,
                Operation_Type__c = 'Batch Sync',
                Status__c = 'Failed',
                Message__c = 'Profile sync failed: ' + e.getMessage()
            );
            throw e;
        }

        insert new Integration_Log__c(
            Trailblazer_Profile__c = profile.Id,
            Operation_Type__c = 'Batch Sync',
            Status__c = 'Success',
            Records_Processed__c = result.badgesProcessed + result.certsProcessed,
            Message__c = 'Profile sync completed.'
        );

        return result;
    }

    private static void upsertBadges(
        Id profileId,
        List<TrailheadApiService.TrailheadBadge> badges
    ) {
        if (badges == null || badges.isEmpty()) {
            return;
        }

        List<Badge__c> toUpsert = new List<Badge__c>();
        for (TrailheadApiService.TrailheadBadge src : badges) {
            Badge__c b = new Badge__c();
            b.Trailblazer_Profile__c = profileId;
            b.Trailhead_Badge_Id__c = src.trailheadBadgeId;
            b.Badge_Title__c = src.title;
            b.Badge_Type__c = src.type;
            b.Earned_Date__c = src.earnedDate;
            b.Points_Earned__c = src.points;
            b.Description__c = src.description;
            b.Icon_URL__c = src.iconUrl;
            b.Trailhead_URL__c = src.trailheadUrl;
            toUpsert.add(b);
        }

        upsert toUpsert Trailhead_Badge_Id__c;
    }

    private static void upsertCerts(
        Id profileId,
        List<TrailheadApiService.TrailheadCertification> certs
    ) {
        if (certs == null || certs.isEmpty()) {
            return;
        }

        List<Certification__c> toUpsert = new List<Certification__c>();
        for (TrailheadApiService.TrailheadCertification src : certs) {
            Certification__c c = new Certification__c();
            c.Trailblazer_Profile__c = profileId;
            c.Cert_Id__c = src.certId;
            c.Cert_Name__c = src.name;
            c.Status__c = src.status;
            c.Date_Earned__c = src.earnedDate;
            c.Date_Expires__c = src.expiryDate;
            toUpsert.add(c);
        }

        upsert toUpsert Cert_Id__c;
    }

    private static void applyProfileRollups(
        Trailblazer_Profile__c profile,
        TrailheadApiService.TrailheadRankData rankData,
        List<TrailheadApiService.TrailheadBadge> badges,
        List<TrailheadApiService.TrailheadCertification> certs
    ) {
        if (rankData != null) {
            profile.Total_Points__c = rankData.totalPoints;
            profile.Total_Badges__c = rankData.totalBadges;
            profile.Total_Superbadges__c = rankData.totalSuperbadges;
            profile.Total_Certifications__c = rankData.totalCertifications;
            profile.Current_Rank__c = rankData.currentRank;
            if (rankData.lastBadgeDate != null) {
                profile.Last_Badge_Date__c = rankData.lastBadgeDate;
            }
        }

        if (profile.Total_Badges__c == null && badges != null) {
            profile.Total_Badges__c = badges.size();
        }
        if ((profile.Total_Superbadges__c == null || profile.Total_Superbadges__c == 0) && badges != null) {
            Integer superCount = 0;
            for (TrailheadApiService.TrailheadBadge b : badges) {
                if ('SUPERBADGE'.equalsIgnoreCase(b.type)) {
                    superCount++;
                }
            }
            profile.Total_Superbadges__c = superCount;
        }
        if (profile.Total_Certifications__c == null && certs != null) {
            profile.Total_Certifications__c = certs.size();
        }

        profile.Last_Sync_Date__c = System.now();
    }

    private static Set<String> getExistingBadgeIds(Id profileId) {
        Set<String> ids = new Set<String>();
        for (Badge__c b : [
            SELECT Trailhead_Badge_Id__c
            FROM Badge__c
            WHERE Trailblazer_Profile__c = :profileId
              AND Trailhead_Badge_Id__c != null
        ]) {
            ids.add(b.Trailhead_Badge_Id__c);
        }
        return ids;
    }

    private static Set<String> getExistingCertIds(Id profileId) {
        Set<String> ids = new Set<String>();
        for (Certification__c c : [
            SELECT Cert_Id__c
            FROM Certification__c
            WHERE Trailblazer_Profile__c = :profileId
              AND Cert_Id__c != null
        ]) {
            ids.add(c.Cert_Id__c);
        }
        return ids;
    }

    private static void applyPostSyncGamification(
        Id profileId,
        List<TrailheadApiService.TrailheadBadge> badges,
        List<TrailheadApiService.TrailheadCertification> certs,
        Set<String> existingBadgeIds,
        Set<String> existingCertIds
    ) {
        if (profileId == null) {
            return;
        }

        List<String> newBadgeTypes = new List<String>();
        if (badges != null) {
            for (TrailheadApiService.TrailheadBadge b : badges) {
                if (b.trailheadBadgeId == null || existingBadgeIds != null && existingBadgeIds.contains(b.trailheadBadgeId)) {
                    continue;
                }
                newBadgeTypes.add(String.isNotBlank(b.type) ? b.type : null);
            }
        }

        Integer newCertCount = 0;
        if (certs != null) {
            for (TrailheadApiService.TrailheadCertification c : certs) {
                if (c.certId != null && (existingCertIds == null || !existingCertIds.contains(c.certId))) {
                    newCertCount++;
                }
            }
        }

        XPService.awardXPForNewBadgesAndCerts(profileId, newBadgeTypes, newCertCount);
        StreakService.calculateStreaks(new Set<Id>{ profileId });
        AchievementService.evaluateAchievements(new Set<Id>{ profileId });
        StudyGroupMemberTriggerHandler.refreshProfileSnapshots(new Set<Id>{ profileId });
    }
}

