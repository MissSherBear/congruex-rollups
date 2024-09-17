trigger CGX2_BillingTrigger on Billing__c (after delete, after insert, after undelete, after update,before delete, before insert, before update) {
    sitetracker.StTriggerFactory.createAndExecuteHandler(CGX2_BillingTriggerHandler.class);
}