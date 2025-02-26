public with sharing class RollupJob {
    public static void updateJob(Set<Id> jobIds) {
        List<sitetracker__Job__c> jobs = [SELECT Id, Claimed_REV_to_Date__c, Approved_REV_to_Date__c, Cash_Receipt__c, 
                                          Finalized_REV_to_Date__c, Invoice_Posted__c, Open_Order__c, Proposal_Created__c 
                                          FROM sitetracker__Job__c WHERE Id IN :jobIds];
    
        for (sitetracker__Job__c job : jobs) {
            Decimal approvedRevToDate = 0;
            Decimal approvedRevToDate2 = 0;
            Decimal cashReceipt = 0;
            Decimal claimedRevToDate = 0;
            Decimal finalizedRevToDate = 0;
            Decimal invoicePosted = 0;
            Decimal openOrder = 0;
            Decimal proposalCreated = 0;
    
            List<sitetracker__Finance__c> relatedFinances = [SELECT Id, Total_Revenue_Accounted_For__c, Approved_WL_Revenue__c,
                                                             Cash_Receipt__c, Actual_Amount__c, Finalized_Revenue__c, 
                                                             Invoice_Posted__c, Open_Order__c, Proposal_Created__c, 
                                                             Add_Unbillable_Bill_Log__c, BU__c, Finance_Line_Type__c 
                                                             FROM sitetracker__Finance__c WHERE Job__c = :job.Id];
    
            for (sitetracker__Finance__c finance : relatedFinances) {
                if (finance.BU__c == 'HHS' && !finance.Add_Unbillable_Bill_Log__c) {
                    approvedRevToDate += (finance.Total_Revenue_Accounted_For__c != null) ? finance.Total_Revenue_Accounted_For__c : 0;
                }
                if (finance.BU__c != 'HHS' && finance.Finance_Line_Type__c != 'Child') {
                    approvedRevToDate2 += (finance.Approved_WL_Revenue__c != null) ? finance.Approved_WL_Revenue__c : 0;
                }
                if (finance.Cash_Receipt__c != null && finance.BU__c != 'HHS') {
                    cashReceipt += (finance.Cash_Receipt__c != null) ? finance.Cash_Receipt__c : 0;
                }
                if (finance.Finance_Line_Type__c != 'Child') {
                    claimedRevToDate += (finance.Actual_Amount__c != null) ? finance.Actual_Amount__c : 0;
                }
                if (finance.Add_Unbillable_Bill_Log__c == null || !finance.Add_Unbillable_Bill_Log__c) {
                    finalizedRevToDate += (finance.Finalized_Revenue__c != null) ? finance.Finalized_Revenue__c : 0;
                }
                if (finance.Invoice_Posted__c != null && finance.BU__c != 'HHS') {
                    invoicePosted += (finance.Invoice_Posted__c != null) ? finance.Invoice_Posted__c : 0;
                }
                if (finance.Open_Order__c != null && finance.BU__c != 'HHS') {
                    openOrder += (finance.Open_Order__c != null) ? finance.Open_Order__c : 0;
                }
                if (finance.Proposal_Created__c != null && finance.BU__c != 'HHS') {
                    proposalCreated += (finance.Proposal_Created__c != null) ? finance.Proposal_Created__c : 0;
                }
            }
    
            job.Approved_REV_to_Date__c = approvedRevToDate;
            job.Approved_REV_to_Date__c = approvedRevToDate2;
            job.Cash_Receipt__c = cashReceipt;
            job.Claimed_REV_to_Date__c = claimedRevToDate;
            job.Finalized_REV_to_Date__c = finalizedRevToDate;
            job.Invoice_Posted__c = invoicePosted;
            job.Open_Order__c = openOrder;
            job.Proposal_Created__c = proposalCreated;
        }
        update jobs;
    }
}
