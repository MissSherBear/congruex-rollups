public with sharing class RollupProjectPriceBook {
    public static void updateProjectPriceBook(Set<Id> projectPriceBookIds) {
        List<sitetracker__Project_Price_Book__c> projectPriceBooks = [SELECT Id, Total_Actual_Cost__c, Actionable_Revenue__c, Approved_REV_To_Date__c,
                                                                      Claimed_REV_To_Date__c, Total_Committed_Cost__c, Number_of_Active_Jobs__c, Number_of_Jobs__c 
                                                                      FROM sitetracker__Project_Price_Book__c WHERE Id IN :projectPriceBookIds];
        
        for (sitetracker__Project_Price_Book__c projectPriceBook : projectPriceBooks) {
            Decimal totalActualCost = 0;
            Decimal actionableRevenue = 0;
            Decimal approvedRevToDate = 0;
            Decimal claimedRevToDate = 0;
            Decimal totalCommittedCost = 0;
            Decimal numberOfActiveJobs = 0;
            Decimal numberOfJobs = 0;
    
            List<sitetracker__Job__c> relatedJobs = [SELECT Id, Estimated_Job_Value__c, Total_Actual_Cost__c, Approved_REV_to_Date__c, Claimed_REV_to_Date__c, 
                                                     Total_Committed_Cost__c, sitetracker__Job_Status__c, sitetracker__Job_Number__c 
                                                     FROM sitetracker__Job__c WHERE Project_Price_Book__c = :projectPriceBook.Id];
    
            for (sitetracker__Job__c job : relatedJobs) {
                if (job.sitetracker__Job_Status__c != 'Cancelled') {
                    totalActualCost += (job.Total_Actual_Cost__c != null) ? job.Total_Actual_Cost__c : 0;
                    actionableRevenue += (job.Estimated_Job_Value__c != null) ? job.Estimated_Job_Value__c : 0;
                    approvedRevToDate += (job.Approved_REV_to_Date__c != null) ? job.Approved_REV_to_Date__c : 0;
                    claimedRevToDate += (job.Claimed_REV_to_Date__c != null) ? job.Claimed_REV_to_Date__c : 0;
                    totalCommittedCost += (job.Total_Committed_Cost__c != null) ? job.Total_Committed_Cost__c : 0;
                    numberOfJobs++;
                }
    
                if (job.sitetracker__Job_Status__c == 'In Progress') {
                    numberOfActiveJobs++;
                }
            }
    
            projectPriceBook.Total_Actual_Cost__c = totalActualCost;
            projectPriceBook.Actionable_Revenue__c = actionableRevenue;
            projectPriceBook.Approved_REV_To_Date__c = approvedRevToDate;
            projectPriceBook.Claimed_REV_To_Date__c = claimedRevToDate;
            projectPriceBook.Total_Committed_Cost__c = totalCommittedCost;
            projectPriceBook.Number_of_Active_Jobs__c = numberOfActiveJobs;
            projectPriceBook.Number_of_Jobs__c = numberOfJobs;
        }

        update projectPriceBooks;
    }
}
