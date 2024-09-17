trigger BillLogTrigger on Bill_Log__c (after insert, after update, after delete, after undelete) {
    if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
        RollupHandler.handleBillLogs(Trigger.new);
    }
    if (Trigger.isDelete) {
        RollupHandler.handleBillLogs(Trigger.old);
    }
}