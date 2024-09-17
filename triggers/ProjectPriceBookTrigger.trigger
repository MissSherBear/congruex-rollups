trigger ProjectPriceBookTrigger on sitetracker__Project_Price_Book__c (after insert, after update, after delete, after undelete) {
    if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
        RollupHandler.handleProjectPriceBooks(Trigger.new);
    }
    if (Trigger.isDelete) {
        RollupHandler.handleProjectPriceBooks(Trigger.old);
    }
}
