@IsTest
private class Phase5Security_Test {

    @IsTest
    static void permissionSetsExist() {
        List<PermissionSet> psList = [
            SELECT Name, Label
            FROM PermissionSet
            WHERE Name IN ('Trailblazer_User', 'Trailblazer_Leader', 'Trailblazer_Admin')
              AND IsOwnedByProfile = false
        ];
        System.assertEquals(3, psList.size(), 'Trailblazer_User, Trailblazer_Leader, and Trailblazer_Admin permission sets must exist.');
    }

    @IsTest
    static void permissionSetGroupsExist() {
        List<PermissionSetGroup> psgList = [
            SELECT DeveloperName
            FROM PermissionSetGroup
            WHERE DeveloperName IN ('Trailblazer_Standard', 'Trailblazer_Manager')
        ];
        System.assertEquals(2, psgList.size(), 'Trailblazer_Standard and Trailblazer_Manager permission set groups must exist.');
    }
}
