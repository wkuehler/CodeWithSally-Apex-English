public with sharing class DetailedNoteController {

    public class NoteWrapper implements Comparable {
        @AuraEnabled public String id;
        @AuraEnabled public String title;
        @AuraEnabled public String body;
        @AuraEnabled public String createdByName;
        @AuraEnabled public String createdById;
        @AuraEnabled public DateTime createdDate;
        @AuraEnabled public Boolean canEdit;
        @AuraEnabled public String sourceLabel;

        public Integer compareTo(Object other) {
            NoteWrapper o = (NoteWrapper) other;
            if (createdDate == o.createdDate) return 0;
            return createdDate > o.createdDate ? -1 : 1;
        }
    }

    private static NoteWrapper toWrapper(
        DetailedNote__c n,
        String sourceLabelValue,
        Boolean hasOverride,
        String currentUserId
    ) {
        NoteWrapper w = new NoteWrapper();
        w.id = n.Id;
        w.title = n.Title__c;
        w.body = n.Body__c;
        w.createdByName = n.CreatedBy.Name;
        w.createdById = n.CreatedById;
        w.createdDate = n.CreatedDate;
        w.canEdit = hasOverride || n.CreatedById == currentUserId;
        w.sourceLabel = sourceLabelValue;
        return w;
    }

    @AuraEnabled(cacheable=true)
    public static List<NoteWrapper> getNotes(String recordId, String objectApiName) {
        Boolean hasOverride = FeatureManagement.checkPermission('Edit_All_Detailed_Notes');
        String currentUserId = UserInfo.getUserId();
        List<NoteWrapper> wrappers = new List<NoteWrapper>();

        if (objectApiName == 'Case') {
            for (DetailedNote__c n : [
                SELECT Id, Title__c, Body__c, CreatedById, CreatedBy.Name, CreatedDate
                FROM DetailedNote__c
                WHERE Case__c = :recordId
                ORDER BY CreatedDate DESC
            ]) {
                wrappers.add(toWrapper(n, null, hasOverride, currentUserId));
            }
        } else if (objectApiName == 'Opportunity') {
            for (DetailedNote__c n : [
                SELECT Id, Title__c, Body__c, CreatedById, CreatedBy.Name, CreatedDate
                FROM DetailedNote__c
                WHERE Opportunity__c = :recordId
                ORDER BY CreatedDate DESC
            ]) {
                wrappers.add(toWrapper(n, null, hasOverride, currentUserId));
            }
        } else if (objectApiName == 'Account') {
            for (DetailedNote__c n : [
                SELECT Id, Title__c, Body__c, CreatedById, CreatedBy.Name, CreatedDate
                FROM DetailedNote__c
                WHERE Account__c = :recordId
            ]) {
                wrappers.add(toWrapper(n, null, hasOverride, currentUserId));
            }
            for (DetailedNote__c n : [
                SELECT Id, Title__c, Body__c, CreatedById, CreatedBy.Name, CreatedDate,
                       Case__r.Subject
                FROM DetailedNote__c
                WHERE Case__r.AccountId = :recordId
            ]) {
                wrappers.add(toWrapper(n, 'Case: ' + n.Case__r.Subject, hasOverride, currentUserId));
            }
            for (DetailedNote__c n : [
                SELECT Id, Title__c, Body__c, CreatedById, CreatedBy.Name, CreatedDate,
                       Opportunity__r.Name
                FROM DetailedNote__c
                WHERE Opportunity__r.AccountId = :recordId
            ]) {
                wrappers.add(toWrapper(n, 'Opportunity: ' + n.Opportunity__r.Name, hasOverride, currentUserId));
            }
            wrappers.sort();
        }

        return wrappers;
    }
}
