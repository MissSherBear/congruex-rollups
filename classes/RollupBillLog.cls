public with sharing class RollupBillLog {
    public static void updateBillLog(Set<Id> billLogIds) {
        List<Bill_Log__c> billLogs = [SELECT Id, Billable_Amount__c, of_Work_Logs__c, Finance__c, Invoice_Status__c, Confirm_Submission__c, Unbillable__c, BU__c 
                                      FROM Bill_Log__c WHERE Id IN :billLogIds];

        // Get related Work Logs
        List<Work_Log__c> workLogs = [SELECT Id, Finance__c, Claimed_QTY__c, Work_Log_Approval_Status__c, Unbillable__c, Ready_To_Invoice__c,
                                           Bill_Log__c, Bill_Log_Name__c, Work_Log_Actual_Amount__c, Resource_Type__c, Labor_Cost__c 
                                           FROM Work_Log__c WHERE Bill_Log__c IN :billLogIds];
        
        for (Bill_Log__c billLog : billLogs) {
            Integer numberOfWorkLogs = 0;
            for (Work_Log__c workLog : workLogs) {
                if (workLog.Bill_Log__c == billLog.Id) {
                    numberOfWorkLogs++;
                }
            }
            billLog.of_Work_Logs__c = numberOfWorkLogs;
        }

        update billLogs;
    }
}
