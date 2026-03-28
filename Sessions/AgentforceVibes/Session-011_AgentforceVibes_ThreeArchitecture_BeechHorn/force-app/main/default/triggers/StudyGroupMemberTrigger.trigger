trigger StudyGroupMemberTrigger on Study_Group_Member__c (
    before insert, before update,
    after insert, after update, after delete, after undelete
) {
    StudyGroupMemberTriggerHandler.handle(
        Trigger.operationType,
        Trigger.new,
        Trigger.oldMap
    );
}

