@IsTest
private class StudyGroupLeaderboardService_Test {

    @IsTest
    static void shouldReturnRankedMembersForGroup() {
        User u = TestDataFactory.createStandardUser('leaderboardsvc@test.com');

        System.runAs(u) {
            Study_Group__c studyGroup = TestDataFactory.createStudyGroup(5);

            Trailblazer_Profile__c leaderProfile = TestDataFactory.createProfile();
            leaderProfile.Trailhead_Username__c = 'leader.user';
            leaderProfile.Total_Badges__c = 12;
            leaderProfile.Current_Streak__c = 7;
            leaderProfile.XP_Total__c = 500;
            update leaderProfile;

            Trailblazer_Profile__c memberProfile = TestDataFactory.createProfile();
            memberProfile.Trailhead_Username__c = 'member.user';
            memberProfile.Total_Badges__c = 8;
            memberProfile.Current_Streak__c = 3;
            memberProfile.XP_Total__c = 250;
            update memberProfile;

            TestDataFactory.createStudyGroupMember(studyGroup.Id, leaderProfile.Id, 'Leader');
            TestDataFactory.createStudyGroupMember(studyGroup.Id, memberProfile.Id, 'Member');

            Test.startTest();
            List<StudyGroupLeaderboardService.MemberRow> rows =
                StudyGroupLeaderboardService.getMembers(studyGroup.Id);
            Test.stopTest();

            Assert.areEqual(2, rows.size(), 'Expected two ranked members');
            Assert.areEqual(1, rows[0].rank, 'Leader should be ranked first');
            Assert.areEqual('leader.user', rows[0].memberName);
            Assert.areEqual(100, rows[0].xpPercent, 'Top row should use the full bar');
            Assert.areEqual(2, rows[1].rank, 'Second member should be ranked second');
        }
    }

    @IsTest
    static void shouldReturnGlobalLeaderboardWhenRequested() {
        User u = TestDataFactory.createStandardUser('leaderboardglobal@test.com');

        System.runAs(u) {
            Study_Group__c studyGroup = TestDataFactory.createStudyGroup(5);
            Trailblazer_Profile__c profile = TestDataFactory.createProfile();
            profile.Trailhead_Username__c = 'global.user';
            profile.XP_Total__c = 150;
            update profile;
            TestDataFactory.createStudyGroupMember(studyGroup.Id, profile.Id, 'Member');

            List<StudyGroupLeaderboardService.MemberRow> rows =
                StudyGroupLeaderboardService.getGlobalTopMembers(10);

            Assert.isFalse(rows.isEmpty(), 'Expected at least one global leaderboard row');
            Assert.areEqual('global.user', rows[0].memberName);
        }
    }
}

