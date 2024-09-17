trigger FinanceTrigger on sitetracker__Finance__c (after insert, after update, after delete, after undelete) {
    if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
        RollupHandler.handleFinances(Trigger.new);
    }
    if (Trigger.isDelete) {
        RollupHandler.handleFinances(Trigger.old);
    }
}
