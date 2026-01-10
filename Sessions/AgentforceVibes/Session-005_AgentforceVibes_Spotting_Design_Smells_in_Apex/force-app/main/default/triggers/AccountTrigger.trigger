trigger AccountTrigger on Account (after insert, after update) {

    List<Account> newCustomerAccounts = new List<Account>();

    for (Account acc : Trigger.new) {
        if (acc.Type == 'Customer') {
            if (Trigger.isInsert) {
                newCustomerAccounts.add(acc);
            } else if (Trigger.isUpdate) {
                Account oldAcc = Trigger.oldMap.get(acc.Id);
                if (oldAcc.Type != 'Customer') {
                    newCustomerAccounts.add(acc);
                }
            }
        }
    }

    if (!newCustomerAccounts.isEmpty()) {
        String priority = 'Normal';
        for (Account acc : newCustomerAccounts) {
            if (acc.AnnualRevenue != null && acc.AnnualRevenue > 100000) {
                priority = 'High';
                break;
            }
        }

        CustomerOnboardingManager manager = new CustomerOnboardingManager();
        manager.processOnboarding(newCustomerAccounts, priority);
    }
}
