trigger RollupTrigger on Work_Log__c (after insert, after update, after delete, after undelete) 
                         sitetracker__Finance__c (after insert, after update, after delete, after undelete),
                         sitetracker__Job__c (after insert, after update, after delete, after undelete),
                         Project_Price_Book__c (after insert, after update, after delete, after undelete) {

    if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            RollupHandler.handleWorkLogs(Trigger.new);
            RollupHandler.handleFinances(Trigger.new);
            RollupHandler.handleJobs(Trigger.new);
            RollupHandler.handleProjectPriceBooks(Trigger.new);
        }
        if (Trigger.isUndelete) {
            RollupHandler.handleWorkLogs(Trigger.new);
            RollupHandler.handleFinances(Trigger.new);
            RollupHandler.handleJobs(Trigger.new);
            RollupHandler.handleProjectPriceBooks(Trigger.new);
        }
    }
    if (Trigger.isDelete) {
        RollupHandler.handleWorkLogs(Trigger.old);
        RollupHandler.handleFinances(Trigger.old);
        RollupHandler.handleJobs(Trigger.old);
        RollupHandler.handleProjectPriceBooks(Trigger.old);
    }
}
