// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents
//
// This script generates test tasks for the TaskManager component.
// It deletes existing tasks and creates new ones in all date categories.

// Step 1: Delete existing tasks
System.debug('Deleting existing tasks...');
List<Task> existingTasks = [SELECT Id FROM Task WHERE OwnerId = :UserInfo.getUserId()];
Integer deletedCount = existingTasks.size();
if (deletedCount > 0) {
    delete existingTasks;
    System.debug('Deleted ' + deletedCount + ' existing task(s).');
} else {
    System.debug('No existing tasks to delete.');
}

// Step 2: Create test tasks for each category
System.debug('Creating test tasks...');
List<Task> newTasks = new List<Task>();
Date today = Date.today();
Date tomorrow = today.addDays(1);

// Helper function to get Monday of the week
Date getMondayOfWeek(Date inputDate) {
    Date referenceMonday = Date.newInstance(1900, 1, 1);
    Integer daysBetween = referenceMonday.daysBetween(inputDate);
    Integer dayOfWeek = Math.mod(daysBetween, 7);
    return inputDate.addDays(-dayOfWeek);
}

// Calculate this week (Monday to Sunday)
Date thisWeekStart = getMondayOfWeek(today);
Date thisWeekEnd = thisWeekStart.addDays(6);

// Calculate next week (Monday to Sunday)
Date nextWeekStart = thisWeekStart.addDays(7);
Date nextWeekEnd = nextWeekStart.addDays(6);

// Overdue tasks (at least 3)
newTasks.add(new Task(
    Subject = 'Overdue Task 1 - Review Q4 budget proposal',
    Priority = 'High',
    ActivityDate = today.addDays(-5),
    Status = 'Not Started'
));
newTasks.add(new Task(
    Subject = 'Overdue Task 2 - Update project documentation',
    Priority = 'Normal',
    ActivityDate = today.addDays(-3),
    Status = 'In Progress'
));
newTasks.add(new Task(
    Subject = 'Overdue Task 3 - Follow up with client on contract',
    Priority = 'High',
    ActivityDate = today.addDays(-1),
    Status = 'Not Started'
));

// Today tasks (at least 3)
newTasks.add(new Task(
    Subject = 'Today Task 1 - Team standup meeting',
    Priority = 'Normal',
    ActivityDate = today,
    Status = 'Not Started'
));
newTasks.add(new Task(
    Subject = 'Today Task 2 - Submit expense report',
    Priority = 'High',
    ActivityDate = today,
    Status = 'In Progress'
));
newTasks.add(new Task(
    Subject = 'Today Task 3 - Review pull requests',
    Priority = 'Normal',
    ActivityDate = today,
    Status = 'Not Started'
));

// Tomorrow tasks (at least 3)
newTasks.add(new Task(
    Subject = 'Tomorrow Task 1 - Prepare presentation slides',
    Priority = 'High',
    ActivityDate = tomorrow,
    Status = 'Not Started'
));
newTasks.add(new Task(
    Subject = 'Tomorrow Task 2 - Schedule team training session',
    Priority = 'Normal',
    ActivityDate = tomorrow,
    Status = 'Not Started'
));
newTasks.add(new Task(
    Subject = 'Tomorrow Task 3 - Update project timeline',
    Priority = 'Low',
    ActivityDate = tomorrow,
    Status = 'Not Started'
));

// This Week tasks (at least 3) - after tomorrow, within current week (Mon-Sun)
// Create tasks for dates after tomorrow but still within this week
Date thisWeekDate = tomorrow.addDays(1);
Integer thisWeekTaskCount = 0;
List<String> thisWeekSubjects = new List<String>{
    'This Week Task 1 - Client demo preparation',
    'This Week Task 2 - Code review for sprint items',
    'This Week Task 3 - Weekly team retrospective'
};
List<String> thisWeekPriorities = new List<String>{'High', 'Normal', 'Normal'};

while (thisWeekTaskCount < 3 && thisWeekDate <= thisWeekEnd) {
    newTasks.add(new Task(
        Subject = thisWeekSubjects[thisWeekTaskCount],
        Priority = thisWeekPriorities[thisWeekTaskCount],
        ActivityDate = thisWeekDate,
        Status = 'Not Started'
    ));
    thisWeekTaskCount++;
    thisWeekDate = thisWeekDate.addDays(1);
}

// Next Week tasks (at least 3)
newTasks.add(new Task(
    Subject = 'Next Week Task 1 - Quarterly planning meeting',
    Priority = 'High',
    ActivityDate = nextWeekStart,
    Status = 'Not Started'
));
newTasks.add(new Task(
    Subject = 'Next Week Task 2 - Update system documentation',
    Priority = 'Normal',
    ActivityDate = nextWeekStart.addDays(2),
    Status = 'Not Started'
));
newTasks.add(new Task(
    Subject = 'Next Week Task 3 - Review vendor proposals',
    Priority = 'Low',
    ActivityDate = nextWeekEnd,
    Status = 'Not Started'
));

// Later tasks (at least 3) - beyond next week or null
newTasks.add(new Task(
    Subject = 'Later Task 1 - Annual performance review prep',
    Priority = 'Normal',
    ActivityDate = nextWeekEnd.addDays(5),
    Status = 'Not Started'
));
newTasks.add(new Task(
    Subject = 'Later Task 2 - Long-term strategy planning',
    Priority = 'Low',
    ActivityDate = nextWeekEnd.addDays(10),
    Status = 'Not Started'
));
newTasks.add(new Task(
    Subject = 'Later Task 3 - Task with no due date',
    Priority = 'Normal',
    ActivityDate = null,
    Status = 'Not Started'
));

// Insert all tasks
try {
    insert newTasks;
    System.debug('Successfully created ' + newTasks.size() + ' test task(s).');
    System.debug('Task breakdown:');
    System.debug('  - Overdue: 3 tasks');
    System.debug('  - Today: 3 tasks');
    System.debug('  - Tomorrow: 3 tasks');
    System.debug('  - This Week: 3 tasks');
    System.debug('  - Next Week: 3 tasks');
    System.debug('  - Later: 3 tasks');
    System.debug('Total: ' + newTasks.size() + ' tasks created.');
} catch (Exception e) {
    System.debug('Error creating tasks: ' + e.getMessage());
    System.debug('Stack trace: ' + e.getStackTraceString());
}

