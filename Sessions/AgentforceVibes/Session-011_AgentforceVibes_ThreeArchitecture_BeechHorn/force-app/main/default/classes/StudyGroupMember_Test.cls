@IsTest
private class StudyGroupMember_Test {

    @IsTest
    static void shouldEnforceMaxMembersOnInsert() {
        User u = TestDataFactory.createStandardUser('leader@test.com');
        System.runAs(u) {
            Study_Group__c studyGroup = TestDataFactory.createStudyGroup(2);
            Trailblazer_Profile__c p1 = TestDataFactory.createProfile();
            Trailblazer_Profile__c p2 = TestDataFactory.createProfile();
            Trailblazer_Profile__c p3 = TestDataFactory.createProfile();

            Test.startTest();
            TestDataFactory.createStudyGroupMember(studyGroup.Id, p1.Id, 'Leader');
            TestDataFactory.createStudyGroupMember(studyGroup.Id, p2.Id, 'Member');

            Boolean threw = false;
            try {
                TestDataFactory.createStudyGroupMember(studyGroup.Id, p3.Id, 'Member');
            } catch (DmlException e) {
                threw = e.getMessage().contains('This study group is already full');
            }
            Test.stopTest();

            Assert.isTrue(threw, 'Should prevent inserting beyond max members');
        }
    }

    @IsTest
    static void shouldUpdateMemberCountOnInsertAndDelete() {
        User u = TestDataFactory.createStandardUser('owner@test.com');
        System.runAs(u) {
            Study_Group__c studyGroup = TestDataFactory.createStudyGroup(5);
            Trailblazer_Profile__c p1 = TestDataFactory.createProfile();
            Trailblazer_Profile__c p2 = TestDataFactory.createProfile();

            Test.startTest();
            Study_Group_Member__c m1 =
                TestDataFactory.createStudyGroupMember(
                    studyGroup.Id,
                    p1.Id,
                    'Leader'
                );
            Study_Group_Member__c m2 =
                TestDataFactory.createStudyGroupMember(
                    studyGroup.Id,
                    p2.Id,
                    'Member'
                );
            Test.stopTest();

            studyGroup = [
                SELECT Member_Count__c
                FROM Study_Group__c
                WHERE Id = :studyGroup.Id
            ];
            Assert.areEqual(
                2,
                studyGroup.Member_Count__c,
                'Member count should reflect two members'
            );

            Test.startTest();
            delete m1;
            Test.stopTest();

            studyGroup = [
                SELECT Member_Count__c
                FROM Study_Group__c
                WHERE Id = :studyGroup.Id
            ];
            Assert.areEqual(
                1,
                studyGroup.Member_Count__c,
                'Member count should decrement after delete'
            );
        }
    }

    @IsTest
    static void shouldAllowJoinLeaveWithinLimitsForMemberAndLeader() {
        User leaderUser = TestDataFactory.createStandardUser('lg@test.com');
        User memberUser = TestDataFactory.createStandardUser('mb@test.com');

        Study_Group__c studyGroup = null;
        Study_Group_Member__c leaderMembership = null;

        System.runAs(leaderUser) {
            studyGroup = TestDataFactory.createStudyGroup(3);
            Trailblazer_Profile__c leaderProfile = TestDataFactory.createProfile();
            leaderMembership = TestDataFactory.createStudyGroupMember(
                studyGroup.Id,
                leaderProfile.Id,
                'Leader'
            );
        }

        System.runAs(memberUser) {
            Trailblazer_Profile__c memberProfile = TestDataFactory.createProfile();

            Test.startTest();
            Study_Group_Member__c member =
                TestDataFactory.createStudyGroupMember(
                    studyGroup.Id,
                    memberProfile.Id,
                    'Member'
                );
            delete member;
            Test.stopTest();
        }

        // Sanity check that leader record still exists
        List<Study_Group_Member__c> remaining = [
            SELECT Id
            FROM Study_Group_Member__c
            WHERE Id = :leaderMembership.Id
        ];
        Assert.areEqual(1, remaining.size(), 'Leader membership should remain');
    }

    @IsTest
    static void shouldRefreshSnapshotsForProfiles() {
        User u = TestDataFactory.createStandardUser('snap@test.com');
        System.runAs(u) {
            Study_Group__c studyGroup = TestDataFactory.createStudyGroup(5);
            Trailblazer_Profile__c profile =
                TestDataFactory.createProfileWithCounts(3, 1, 7);

            Study_Group_Member__c member = new Study_Group_Member__c(
                Study_Group__c = studyGroup.Id,
                Trailblazer_Profile__c = profile.Id,
                Role__c = 'Member'
            );
            insert member;

            Test.startTest();
            StudyGroupMemberTriggerHandler.refreshProfileSnapshots(
                new Set<Id>{ profile.Id }
            );
            Test.stopTest();

            Study_Group_Member__c refreshed = [
                SELECT Group_Name_Snapshot__c,
                       Member_Name_Snapshot__c,
                       Total_Badges_Snapshot__c,
                       Current_Streak_Snapshot__c,
                       XP_Total_Snapshot__c
                FROM Study_Group_Member__c
                WHERE Id = :member.Id
            ];
            System.assertEquals(
                studyGroup.Group_Name__c,
                refreshed.Group_Name_Snapshot__c
            );
            System.assertEquals(
                profile.Trailhead_Username__c,
                refreshed.Member_Name_Snapshot__c
            );
        }
    }
}

