/**
 * TaskManagerApexController
 * 
 * Apex controller for the TaskManager Lightning Web Component.
 * Provides methods to retrieve, complete, and defer tasks.
 */
public with sharing class TaskManagerApexController {
    
    /**
     * Retrieves all open tasks for the current user, grouped by due date category.
     * 
     * @return Map<String, List<Task>> Tasks grouped by category (Overdue, Today, Tomorrow, This Week, Next Week, Later)
     */
    @AuraEnabled(cacheable=false)
    public static Map<String, List<Task>> getTasks() {
        Map<String, List<Task>> groupedTasks = new Map<String, List<Task>>();
        
        // Initialize all groups
        groupedTasks.put('Overdue', new List<Task>());
        groupedTasks.put('Today', new List<Task>());
        groupedTasks.put('Tomorrow', new List<Task>());
        groupedTasks.put('This Week', new List<Task>());
        groupedTasks.put('Next Week', new List<Task>());
        groupedTasks.put('Later', new List<Task>());
        
        // Query all open tasks assigned to the current user
        List<Task> tasks = [
            SELECT Id, Subject, Priority, ActivityDate, Status, OwnerId
            FROM Task
            WHERE OwnerId = :UserInfo.getUserId()
            AND Status != 'Completed'
            ORDER BY ActivityDate ASC NULLS LAST
        ];
        
        // Get date references for grouping
        Date today = Date.today();
        Date tomorrow = today.addDays(1);
        
        // Calculate this week (Monday to Sunday)
        Date thisWeekStart = getMondayOfWeek(today);
        Date thisWeekEnd = thisWeekStart.addDays(6);
        
        // Calculate next week (Monday to Sunday)
        Date nextWeekStart = thisWeekStart.addDays(7);
        Date nextWeekEnd = nextWeekStart.addDays(6);
        
        // Group tasks by due date category
        for (Task t : tasks) {
            if (t.ActivityDate == null) {
                groupedTasks.get('Later').add(t);
            } else if (t.ActivityDate < today) {
                groupedTasks.get('Overdue').add(t);
            } else if (t.ActivityDate == today) {
                groupedTasks.get('Today').add(t);
            } else if (t.ActivityDate == tomorrow) {
                groupedTasks.get('Tomorrow').add(t);
            } else if (t.ActivityDate > tomorrow && t.ActivityDate <= thisWeekEnd) {
                groupedTasks.get('This Week').add(t);
            } else if (t.ActivityDate >= nextWeekStart && t.ActivityDate <= nextWeekEnd) {
                groupedTasks.get('Next Week').add(t);
            } else {
                groupedTasks.get('Later').add(t);
            }
        }
        
        return groupedTasks;
    }
    
    /**
     * Completes a task by setting its status to 'Completed'.
     * 
     * @param taskId The Id of the task to complete
     * @return Boolean True if successful, false otherwise
     */
    @AuraEnabled(cacheable=false)
    public static Boolean closeTask(Id taskId) {
        try {
            Task taskToUpdate = new Task(Id = taskId);
            taskToUpdate.Status = 'Completed';
            update taskToUpdate;
            return true;
        } catch (Exception e) {
            System.debug('Error closing task: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * Defers a task by adding one day to its ActivityDate.
     * 
     * @param taskId The Id of the task to defer
     * @return Boolean True if successful, false otherwise
     */
    @AuraEnabled(cacheable=false)
    public static Boolean deferTask(Id taskId) {
        try {
            // Query the task to get its current ActivityDate
            Task taskToUpdate = [
                SELECT Id, ActivityDate
                FROM Task
                WHERE Id = :taskId
                LIMIT 1
            ];
            
            // Add one day to the ActivityDate
            if (taskToUpdate.ActivityDate != null) {
                taskToUpdate.ActivityDate = taskToUpdate.ActivityDate.addDays(1);
            } else {
                // If ActivityDate is null, set it to tomorrow
                taskToUpdate.ActivityDate = Date.today().addDays(1);
            }
            
            update taskToUpdate;
            return true;
        } catch (Exception e) {
            System.debug('Error deferring task: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * Helper method to get Monday of the week for a given date.
     * 
     * @param inputDate The date to find the Monday for
     * @return Date The Monday of the week containing the input date
     */
    private static Date getMondayOfWeek(Date inputDate) {
        // January 1, 1900 was a Monday
        Date referenceMonday = Date.newInstance(1900, 1, 1);
        // Calculate days between reference Monday and input date
        Integer daysBetween = referenceMonday.daysBetween(inputDate);
        // Get day of week (0 = Monday, 1 = Tuesday, ..., 6 = Sunday)
        Integer dayOfWeek = Math.mod(daysBetween, 7);
        // Calculate days to subtract to get to Monday
        // If it's Monday (0), subtract 0; otherwise subtract the day offset
        return inputDate.addDays(-dayOfWeek);
    }
}

