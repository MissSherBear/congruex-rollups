trigger WorkLogTrigger on Work_Log__c (after insert, after update, after delete, after undelete) {
    if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
        RollupHandler.handleWorkLogs(Trigger.new);
    }
    if (Trigger.isDelete) {
        RollupHandler.handleWorkLogs(Trigger.old);
    }
}
