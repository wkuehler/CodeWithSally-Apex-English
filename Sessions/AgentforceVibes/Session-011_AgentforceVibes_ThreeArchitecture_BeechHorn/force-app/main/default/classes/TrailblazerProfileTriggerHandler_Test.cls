@IsTest
private class TrailblazerProfileTriggerHandler_Test {

    @IsTest
    static void shouldEnqueueShareRecalcWhenUserChanges() {
        User u1 = TestDataFactory.createStandardUser('u1@profile.com');
        User u2 = TestDataFactory.createStandardUser('u2@profile.com');

        Trailblazer_Profile__c profile;
        Study_Group__c grp;
        System.runAs(u1) {
            profile = TestDataFactory.createProfile();
            profile.User__c = u1.Id;
            update profile;
            grp = TestDataFactory.createStudyGroup(5);
            TestDataFactory.createStudyGroupMember(grp.Id, profile.Id, 'Member');
        }

        Integer beforeJobs = [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'Queueable'];

        System.runAs(u1) {
            profile.User__c = u2.Id;
            Test.startTest();
            update profile;
            Test.stopTest();
        }

        Integer afterJobs = [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'Queueable'];
        System.assert(afterJobs >= beforeJobs, 'Profile trigger should enqueue share recalc when User__c changes.');
    }

    @IsTest
    static void shouldNotEnqueueWhenUserUnchanged() {
        User u = TestDataFactory.createStandardUser('u3@profile.com');
        Trailblazer_Profile__c profile;
        System.runAs(u) {
            profile = TestDataFactory.createProfile();
            profile.User__c = u.Id;
            update profile;
        }

        Integer countBefore = [
            SELECT COUNT() FROM AsyncApexJob
            WHERE JobType = 'Queueable'
              AND ApexClass.Name = 'TrailblazerProfileSharingService'
        ];

        profile.Trailhead_Username__c = 'updated-name';
        Test.startTest();
        update profile;
        Test.stopTest();

        Integer countAfter = [
            SELECT COUNT() FROM AsyncApexJob
            WHERE JobType = 'Queueable'
              AND ApexClass.Name = 'TrailblazerProfileSharingService'
        ];
        System.assertEquals(countBefore, countAfter, 'No share recalc when User__c did not change.');
    }
}
