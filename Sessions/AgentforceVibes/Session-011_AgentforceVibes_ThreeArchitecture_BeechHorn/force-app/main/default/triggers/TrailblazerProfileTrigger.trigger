trigger TrailblazerProfileTrigger on Trailblazer_Profile__c (
    after insert,
    after update
) {
    TrailblazerProfileTriggerHandler.handle(
        Trigger.operationType,
        Trigger.new,
        Trigger.oldMap
    );
}
