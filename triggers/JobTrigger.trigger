trigger JobTrigger on sitetracker__Job__c (after insert, after update, after delete, after undelete) {
    if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
        RollupHandler.handleJobs(Trigger.new);
    }
    if (Trigger.isDelete) {
        RollupHandler.handleJobs(Trigger.old);
    }
}
