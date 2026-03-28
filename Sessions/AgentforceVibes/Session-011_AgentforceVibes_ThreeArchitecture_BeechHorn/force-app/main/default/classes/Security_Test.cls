@IsTest
private class Security_Test {

    private static void assignPermset(User u, String permsetName) {
        PermissionSet ps = [
            SELECT Id
            FROM PermissionSet
            WHERE Name = :permsetName
              AND IsOwnedByProfile = false
            LIMIT 1
        ];
        insert new PermissionSetAssignment(
            AssigneeId = u.Id,
            PermissionSetId = ps.Id
        );
    }

    private static void assertObjectCrud(String sobjectApiName, Boolean expectCreate, Boolean expectRead, Boolean expectEdit, Boolean expectDelete) {
        Schema.SObjectType t = Schema.getGlobalDescribe().get(sobjectApiName);
        System.assertNotEquals(null, t, 'Unknown sObject: ' + sobjectApiName);
        System.assertEquals(expectCreate, t.getDescribe().isCreateable(), 'Create mismatch for ' + sobjectApiName);
        System.assertEquals(expectRead, t.getDescribe().isAccessible(), 'Read mismatch for ' + sobjectApiName);
        System.assertEquals(expectEdit, t.getDescribe().isUpdateable(), 'Edit mismatch for ' + sobjectApiName);
        System.assertEquals(expectDelete, t.getDescribe().isDeletable(), 'Delete mismatch for ' + sobjectApiName);
    }

    private static void assertPermsetFieldPermission(String permsetName, String fieldApiName, Boolean expectedRead, Boolean expectedEdit) {
        PermissionSet ps = [
            SELECT Id
            FROM PermissionSet
            WHERE Name = :permsetName
              AND IsOwnedByProfile = false
            LIMIT 1
        ];

        List<FieldPermissions> fps = [
            SELECT SobjectType, Field, PermissionsRead, PermissionsEdit
            FROM FieldPermissions
            WHERE ParentId = :ps.Id
              AND Field = :fieldApiName
            LIMIT 1
        ];
        System.assertEquals(1, fps.size(), 'Missing FieldPermissions for ' + permsetName + ' on ' + fieldApiName);
        System.assertEquals(expectedRead, fps[0].PermissionsRead, 'PermissionsRead mismatch for ' + permsetName + ' on ' + fieldApiName);
        System.assertEquals(expectedEdit, fps[0].PermissionsEdit, 'PermissionsEdit mismatch for ' + permsetName + ' on ' + fieldApiName);
    }

    @IsTest
    static void userWithoutTrailblazerPermsets_hasNoAccessToCustomObjects() {
        User u = TestDataFactory.createStandardUser('noaccess@sec.com');

        System.runAs(u) {
            assertObjectCrud('Trailblazer_Profile__c', false, false, false, false);
            assertObjectCrud('Badge__c', false, false, false, false);
            assertObjectCrud('Certification__c', false, false, false, false);
            assertObjectCrud('Discovery__c', false, false, false, false);
            assertObjectCrud('Quest__c', false, false, false, false);
            assertObjectCrud('Quest_Enrollment__c', false, false, false, false);
            assertObjectCrud('Study_Group__c', false, false, false, false);
            assertObjectCrud('Study_Group_Member__c', false, false, false, false);
            assertObjectCrud('Earned_Achievement__c', false, false, false, false);
            assertObjectCrud('XP_Transaction__c', false, false, false, false);
        }
    }

    @IsTest
    static void trailblazerUser_hasExpectedCrudAndFls() {
        User u = TestDataFactory.createStandardUser('tbuser@sec.com');
        assignPermset(u, 'Trailblazer_User');

        System.runAs(u) {
            assertObjectCrud('Trailblazer_Profile__c', true, true, true, true);
            assertObjectCrud('Badge__c', true, true, true, true);
            assertObjectCrud('Certification__c', true, true, true, true);
            assertObjectCrud('Discovery__c', true, true, true, true);
            assertObjectCrud('Quest__c', false, true, false, false);
            assertObjectCrud('Quest_Enrollment__c', true, true, true, true);
        }
    }

    @IsTest
    static void trailblazerLeader_hasExpectedCrudAndFls() {
        User u = TestDataFactory.createStandardUser('tbleader@sec.com');
        assignPermset(u, 'Trailblazer_Leader');

        System.runAs(u) {
            assertObjectCrud('Trailblazer_Profile__c', true, true, true, true);
            assertObjectCrud('Study_Group__c', true, true, true, false);
            assertObjectCrud('Study_Group_Member__c', true, true, true, true);
            assertObjectCrud('Quest__c', false, true, false, false);
        }
    }

    @IsTest
    static void trailblazerAdmin_hasExpectedCrudAndFls() {
        User u = TestDataFactory.createStandardUser('tbadmin@sec.com');
        assignPermset(u, 'Trailblazer_Admin');

        System.runAs(u) {
            assertObjectCrud('Trailblazer_Profile__c', true, true, true, true);
            assertObjectCrud('Badge__c', true, true, true, true);
            assertObjectCrud('Certification__c', true, true, true, true);
            assertObjectCrud('Discovery__c', true, true, true, true);
            assertObjectCrud('Quest__c', true, true, true, true);
            assertObjectCrud('Quest_Enrollment__c', true, true, true, true);
            assertObjectCrud('Study_Group__c', true, true, true, true);
            assertObjectCrud('Study_Group_Member__c', true, true, true, true);
            assertObjectCrud('Earned_Achievement__c', true, true, true, true);
            assertObjectCrud('XP_Transaction__c', true, true, true, true);
        }

        assertPermsetFieldPermission('Trailblazer_Admin', 'Trailblazer_Profile__c.XP_Total__c', true, true);
    }
}

