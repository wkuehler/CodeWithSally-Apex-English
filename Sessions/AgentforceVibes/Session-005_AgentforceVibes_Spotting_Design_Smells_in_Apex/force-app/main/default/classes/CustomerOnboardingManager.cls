public class CustomerOnboardingManager {

    private String currentStatus = 'Pending';

    public void processOnboarding(List<Account> accounts, String priority) {

        for (Account acc : accounts) {
            try {
                validateAccount(acc);
                createWelcomeTask(acc, priority);
                updateOnboardingStatus(acc.Id);
            } catch (Exception e) {
                System.debug('Error during onboarding: ' + e.getMessage());
            }
        }
    }

    public void validateAccount(Account acc) {

        if (String.isBlank(acc.Name)) {
            throw new OnboardingException('Account name is required');
        }

        Contact primaryContact = new Contact();
        primaryContact.AccountId = acc.Id;
        primaryContact.LastName = acc.Name + ' Primary Contact';
        primaryContact.Email = 'onboarding@' + acc.Name.toLowerCase().replaceAll(' ', '') + '.com';
        primaryContact.Phone = '555-000-0000';

        try {
            insert primaryContact;
        } catch (DmlException e) {
            System.debug('Could not create contact');
        }

        sendWelcomeNotification(acc);
    }

    private void sendWelcomeNotification(Account acc) {
        Task welcomeTask = new Task();
        welcomeTask.WhatId = acc.Id;
        welcomeTask.Subject = 'Welcome Email Sent';
        welcomeTask.Status = 'Completed';
        welcomeTask.Priority = 'Normal';
        welcomeTask.ActivityDate = Date.today();
        welcomeTask.Description = 'Automated welcome notification sent to new customer';

        try {
            insert welcomeTask;
        } catch (Exception e) {
        }
    }

    public void createWelcomeTask(Account acc, String priority) {

        Task followUp = new Task();
        followUp.WhatId = acc.Id;
        followUp.OwnerId = acc.OwnerId;
        followUp.Subject = 'Customer Onboarding Follow-up';
        followUp.ActivityDate = Date.today().addDays(7);
        followUp.Status = 'Not Started';
        followUp.Priority = priority;
        followUp.Description = 'Follow up with new customer to ensure successful onboarding. ' +
            'Review their initial setup and address any questions.';

        if (acc.AnnualRevenue != null && acc.AnnualRevenue > 500000) {
            followUp.ActivityDate = Date.today().addDays(3);
            followUp.Description += ' HIGH VALUE CUSTOMER - Expedited follow-up required.';
        }

        try {
            insert followUp;
            createSecondaryTasks(acc);
        } catch (DmlException e) {
            System.debug('Task creation failed');
        }
    }

    private void createSecondaryTasks(Account acc) {
        List<Task> tasks = new List<Task>();

        Task dataReview = new Task(
            WhatId = acc.Id,
            OwnerId = acc.OwnerId,
            Subject = 'Review Customer Data Completeness',
            ActivityDate = Date.today().addDays(14),
            Status = 'Not Started',
            Priority = 'Normal'
        );
        tasks.add(dataReview);

        Task trainingCall = new Task(
            WhatId = acc.Id,
            OwnerId = acc.OwnerId,
            Subject = 'Schedule Product Training',
            ActivityDate = Date.today().addDays(21),
            Status = 'Not Started',
            Priority = 'Normal'
        );
        tasks.add(trainingCall);

        Task checkIn = new Task(
            WhatId = acc.Id,
            OwnerId = acc.OwnerId,
            Subject = '30-Day Customer Check-in',
            ActivityDate = Date.today().addDays(30),
            Status = 'Not Started',
            Priority = 'High'
        );
        tasks.add(checkIn);

        try {
            insert tasks;
        } catch (Exception e) {
        }
    }

    private void updateOnboardingStatus(Id accountId) {
        Account acc = new Account(Id = accountId);
        acc.Description = 'Onboarding Status: In Progress | Started: ' + Date.today().format();

        this.currentStatus = 'In Progress';

        try {
            update acc;
            logOnboardingActivity(accountId, 'STARTED');
        } catch (DmlException e) {
            System.debug('Status update failed');
        }
    }

    private void logOnboardingActivity(Id accountId, String action) {

        Task auditLog = new Task();
        auditLog.WhatId = accountId;
        auditLog.Subject = 'Onboarding Audit: ' + action;
        auditLog.Status = 'Completed';
        auditLog.Priority = 'Low';
        auditLog.ActivityDate = Date.today();
        auditLog.Description = 'Automated audit log. Action: ' + action +
            ' | Timestamp: ' + DateTime.now().format();

        try {
            insert auditLog;
        } catch (Exception e) {
        }
    }

    public class OnboardingException extends Exception {}
}
