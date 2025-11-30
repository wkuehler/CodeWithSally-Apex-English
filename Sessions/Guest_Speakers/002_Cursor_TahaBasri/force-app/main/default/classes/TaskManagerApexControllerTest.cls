/**
 * TaskManagerApexControllerTest
 * 
 * Test class for TaskManagerApexController.
 * Covers positive, negative, and bulk test cases using Assert class methods.
 */
@isTest
private class TaskManagerApexControllerTest {
    
    /**
     * Test setup method to create test data
     */
    @testSetup
    static void setupTestData() {
        // Create test tasks for the current user in various date categories
        List<Task> testTasks = new List<Task>();
        Date today = Date.today();
        Date tomorrow = today.addDays(1);
        
        // Calculate this week (Monday to Sunday)
        Date thisWeekStart = getMondayOfWeek(today);
        Date thisWeekEnd = thisWeekStart.addDays(6);
        
        // Calculate next week (Monday to Sunday)
        Date nextWeekStart = thisWeekStart.addDays(7);
        Date nextWeekEnd = nextWeekStart.addDays(6);
        
        // Overdue tasks
        testTasks.add(new Task(
            Subject = 'Overdue Task 1',
            Priority = 'High',
            ActivityDate = today.addDays(-3),
            Status = 'Not Started'
        ));
        testTasks.add(new Task(
            Subject = 'Overdue Task 2',
            Priority = 'Normal',
            ActivityDate = today.addDays(-1),
            Status = 'In Progress'
        ));
        
        // Today tasks
        testTasks.add(new Task(
            Subject = 'Today Task 1',
            Priority = 'High',
            ActivityDate = today,
            Status = 'Not Started'
        ));
        testTasks.add(new Task(
            Subject = 'Today Task 2',
            Priority = 'Normal',
            ActivityDate = today,
            Status = 'In Progress'
        ));
        
        // Tomorrow tasks
        testTasks.add(new Task(
            Subject = 'Tomorrow Task 1',
            Priority = 'High',
            ActivityDate = tomorrow,
            Status = 'Not Started'
        ));
        testTasks.add(new Task(
            Subject = 'Tomorrow Task 2',
            Priority = 'Low',
            ActivityDate = tomorrow,
            Status = 'Not Started'
        ));
        
        // This Week tasks (after tomorrow, within current week)
        if (today.addDays(2) <= thisWeekEnd) {
            testTasks.add(new Task(
                Subject = 'This Week Task 1',
                Priority = 'Normal',
                ActivityDate = today.addDays(2),
                Status = 'Not Started'
            ));
            testTasks.add(new Task(
                Subject = 'This Week Task 2',
                Priority = 'High',
                ActivityDate = thisWeekEnd,
                Status = 'Not Started'
            ));
        }
        
        // Next Week tasks
        testTasks.add(new Task(
            Subject = 'Next Week Task 1',
            Priority = 'Normal',
            ActivityDate = nextWeekStart,
            Status = 'Not Started'
        ));
        testTasks.add(new Task(
            Subject = 'Next Week Task 2',
            Priority = 'Low',
            ActivityDate = nextWeekEnd,
            Status = 'Not Started'
        ));
        
        // Later tasks (beyond next week)
        testTasks.add(new Task(
            Subject = 'Later Task 1',
            Priority = 'Normal',
            ActivityDate = nextWeekEnd.addDays(5),
            Status = 'Not Started'
        ));
        
        // Task with null ActivityDate (should go to Later)
        testTasks.add(new Task(
            Subject = 'No Due Date Task',
            Priority = 'Normal',
            ActivityDate = null,
            Status = 'Not Started'
        ));
        
        // Completed task (should not appear in results)
        testTasks.add(new Task(
            Subject = 'Completed Task',
            Priority = 'High',
            ActivityDate = today,
            Status = 'Completed'
        ));
        
        insert testTasks;
    }
    
    /**
     * Test getTasks() - Positive case: Verify tasks are grouped correctly
     */
    @isTest
    static void testGetTasks_Positive() {
        Test.startTest();
        Map<String, List<Task>> result = TaskManagerApexController.getTasks();
        Test.stopTest();
        
        // Assert all groups exist
        Assert.isNotNull(result, 'Result map should not be null');
        Assert.isTrue(result.containsKey('Overdue'), 'Should contain Overdue group');
        Assert.isTrue(result.containsKey('Today'), 'Should contain Today group');
        Assert.isTrue(result.containsKey('Tomorrow'), 'Should contain Tomorrow group');
        Assert.isTrue(result.containsKey('This Week'), 'Should contain This Week group');
        Assert.isTrue(result.containsKey('Next Week'), 'Should contain Next Week group');
        Assert.isTrue(result.containsKey('Later'), 'Should contain Later group');
        
        // Assert tasks are grouped correctly
        Assert.isTrue(result.get('Overdue').size() >= 2, 'Should have at least 2 overdue tasks');
        Assert.isTrue(result.get('Today').size() >= 2, 'Should have at least 2 today tasks');
        Assert.isTrue(result.get('Tomorrow').size() >= 2, 'Should have at least 2 tomorrow tasks');
        Assert.isTrue(result.get('Next Week').size() >= 2, 'Should have at least 2 next week tasks');
        Assert.isTrue(result.get('Later').size() >= 2, 'Should have at least 2 later tasks (including null date)');
        
        // Assert completed task is not included
        Boolean hasCompletedTask = false;
        for (List<Task> taskList : result.values()) {
            for (Task t : taskList) {
                if (t.Subject == 'Completed Task') {
                    hasCompletedTask = true;
                    break;
                }
            }
        }
        Assert.isFalse(hasCompletedTask, 'Completed tasks should not be included');
        
        // Assert all tasks belong to current user
        Id currentUserId = UserInfo.getUserId();
        for (List<Task> taskList : result.values()) {
            for (Task t : taskList) {
                Assert.areEqual(currentUserId, t.OwnerId, 'Task should belong to current user');
            }
        }
    }
    
    /**
     * Test getTasks() - Negative case: No tasks scenario
     */
    @isTest
    static void testGetTasks_Negative_NoTasks() {
        // Delete all tasks
        delete [SELECT Id FROM Task];
        
        Test.startTest();
        Map<String, List<Task>> result = TaskManagerApexController.getTasks();
        Test.stopTest();
        
        // Assert all groups exist but are empty
        Assert.isNotNull(result, 'Result map should not be null');
        Assert.areEqual(0, result.get('Overdue').size(), 'Overdue group should be empty');
        Assert.areEqual(0, result.get('Today').size(), 'Today group should be empty');
        Assert.areEqual(0, result.get('Tomorrow').size(), 'Tomorrow group should be empty');
        Assert.areEqual(0, result.get('This Week').size(), 'This Week group should be empty');
        Assert.areEqual(0, result.get('Next Week').size(), 'Next Week group should be empty');
        Assert.areEqual(0, result.get('Later').size(), 'Later group should be empty');
    }
    
    /**
     * Test closeTask() - Positive case: Successfully complete a task
     */
    @isTest
    static void testCloseTask_Positive() {
        Task testTask = [SELECT Id, Status FROM Task WHERE Status != 'Completed' LIMIT 1];
        Assert.areNotEqual('Completed', testTask.Status, 'Task should not be completed initially');
        
        Test.startTest();
        Boolean result = TaskManagerApexController.closeTask(testTask.Id);
        Test.stopTest();
        
        // Assert method returns true
        Assert.isTrue(result, 'closeTask should return true on success');
        
        // Assert task is now completed
        Task updatedTask = [SELECT Id, Status FROM Task WHERE Id = :testTask.Id];
        Assert.areEqual('Completed', updatedTask.Status, 'Task status should be Completed');
    }
    
    /**
     * Test closeTask() - Negative case: Invalid task ID
     */
    @isTest
    static void testCloseTask_Negative_InvalidId() {
        Id invalidId = '00T000000000000AAA'; // Invalid task ID format
        
        Test.startTest();
        Boolean result = TaskManagerApexController.closeTask(invalidId);
        Test.stopTest();
        
        // Assert method returns false
        Assert.isFalse(result, 'closeTask should return false for invalid ID');
    }
    
    /**
     * Test closeTask() - Bulk case: Complete multiple tasks
     */
    @isTest
    static void testCloseTask_Bulk() {
        List<Task> testTasks = [SELECT Id FROM Task WHERE Status != 'Completed' LIMIT 5];
        Assert.isTrue(testTasks.size() > 0, 'Should have test tasks');
        
        Test.startTest();
        List<Boolean> results = new List<Boolean>();
        for (Task t : testTasks) {
            results.add(TaskManagerApexController.closeTask(t.Id));
        }
        Test.stopTest();
        
        // Assert all operations succeeded
        for (Boolean result : results) {
            Assert.isTrue(result, 'All bulk closeTask operations should succeed');
        }
        
        // Assert all tasks are completed
        List<Task> updatedTasks = [SELECT Id, Status FROM Task WHERE Id IN :testTasks];
        Assert.areEqual(testTasks.size(), updatedTasks.size(), 'Should have same number of updated tasks');
        for (Task t : updatedTasks) {
            Assert.areEqual('Completed', t.Status, 'All tasks should be completed');
        }
    }
    
    /**
     * Test deferTask() - Positive case: Successfully defer a task with ActivityDate
     */
    @isTest
    static void testDeferTask_Positive_WithDate() {
        Task testTask = [SELECT Id, ActivityDate FROM Task WHERE ActivityDate != null AND Status != 'Completed' LIMIT 1];
        Date originalDate = testTask.ActivityDate;
        Date expectedDate = originalDate.addDays(1);
        
        Test.startTest();
        Boolean result = TaskManagerApexController.deferTask(testTask.Id);
        Test.stopTest();
        
        // Assert method returns true
        Assert.isTrue(result, 'deferTask should return true on success');
        
        // Assert ActivityDate is incremented by 1 day
        Task updatedTask = [SELECT Id, ActivityDate FROM Task WHERE Id = :testTask.Id];
        Assert.areEqual(expectedDate, updatedTask.ActivityDate, 'ActivityDate should be incremented by 1 day');
    }
    
    /**
     * Test deferTask() - Positive case: Defer task with null ActivityDate
     */
    @isTest
    static void testDeferTask_Positive_NullDate() {
        Task testTask = [SELECT Id, ActivityDate FROM Task WHERE ActivityDate = null AND Status != 'Completed' LIMIT 1];
        Assert.isNull(testTask.ActivityDate, 'Task should have null ActivityDate');
        Date expectedDate = Date.today().addDays(1);
        
        Test.startTest();
        Boolean result = TaskManagerApexController.deferTask(testTask.Id);
        Test.stopTest();
        
        // Assert method returns true
        Assert.isTrue(result, 'deferTask should return true on success');
        
        // Assert ActivityDate is set to tomorrow
        Task updatedTask = [SELECT Id, ActivityDate FROM Task WHERE Id = :testTask.Id];
        Assert.areEqual(expectedDate, updatedTask.ActivityDate, 'ActivityDate should be set to tomorrow');
    }
    
    /**
     * Test deferTask() - Negative case: Invalid task ID
     */
    @isTest
    static void testDeferTask_Negative_InvalidId() {
        Id invalidId = '00T000000000000AAA'; // Invalid task ID format
        
        Test.startTest();
        Boolean result = TaskManagerApexController.deferTask(invalidId);
        Test.stopTest();
        
        // Assert method returns false
        Assert.isFalse(result, 'deferTask should return false for invalid ID');
    }
    
    /**
     * Test deferTask() - Bulk case: Defer multiple tasks
     */
    @isTest
    static void testDeferTask_Bulk() {
        List<Task> testTasks = [SELECT Id, ActivityDate FROM Task WHERE Status != 'Completed' LIMIT 5];
        Assert.isTrue(testTasks.size() > 0, 'Should have test tasks');
        
        Map<Id, Date> originalDates = new Map<Id, Date>();
        for (Task t : testTasks) {
            originalDates.put(t.Id, t.ActivityDate);
        }
        
        Test.startTest();
        List<Boolean> results = new List<Boolean>();
        for (Task t : testTasks) {
            results.add(TaskManagerApexController.deferTask(t.Id));
        }
        Test.stopTest();
        
        // Assert all operations succeeded
        for (Boolean result : results) {
            Assert.isTrue(result, 'All bulk deferTask operations should succeed');
        }
        
        // Assert all tasks have ActivityDate incremented correctly
        List<Task> updatedTasks = [SELECT Id, ActivityDate FROM Task WHERE Id IN :testTasks];
        Assert.areEqual(testTasks.size(), updatedTasks.size(), 'Should have same number of updated tasks');
        for (Task t : updatedTasks) {
            Date originalDate = originalDates.get(t.Id);
            if (originalDate != null) {
                Assert.areEqual(originalDate.addDays(1), t.ActivityDate, 'ActivityDate should be incremented by 1 day');
            } else {
                Assert.areEqual(Date.today().addDays(1), t.ActivityDate, 'Null ActivityDate should be set to tomorrow');
            }
        }
    }
    
    /**
     * Helper method to get Monday of the week for a given date (same logic as controller)
     */
    private static Date getMondayOfWeek(Date inputDate) {
        Date referenceMonday = Date.newInstance(1900, 1, 1);
        Integer daysBetween = referenceMonday.daysBetween(inputDate);
        Integer dayOfWeek = Math.mod(daysBetween, 7);
        return inputDate.addDays(-dayOfWeek);
    }
}

