public with sharing class RollupProgram {
    public static void updateProgram(Set<Id> programIds) {
        List<sitetracker__Program2__c> programs = [SELECT Id, Total_Actual_Cost__c, Total_Committed_Cost__c, Actionable_Revenue__c, Approved_REV_To_Date__c,
                                                   Claimed_REV_To_Date__c, Number_of_Active_Job__c, Number_of_Jobs__c 
                                                   FROM sitetracker__Program2__c WHERE Id IN :programIds];
        
        for (sitetracker__Program2__c program : programs) {
            Decimal totalActualCost = 0;
            Decimal totalCommittedCost = 0;
            Decimal actionableRevenue = 0;
            Decimal approvedRevToDate = 0;
            Decimal claimedRevToDate = 0;
            Decimal numberOfActiveJobs = 0;
            Decimal numberOfJobs = 0;
    
            List<sitetracker__Project_Price_Book__c> relatedProjectPriceBooks = [SELECT Total_Actual_Cost__c, Total_Committed_Cost__c, Actionable_Revenue__c, 
                                                                                 Approved_REV_To_Date__c, Claimed_REV_To_Date__c, Number_of_Active_Jobs__c, Number_of_Jobs__c 
                                                                                 FROM sitetracker__Project_Price_Book__c WHERE Program__c = :program.Id];
    
            for (sitetracker__Project_Price_Book__c projectPriceBook : relatedProjectPriceBooks) {
                totalActualCost += (projectPriceBook.Total_Actual_Cost__c != null) ? projectPriceBook.Total_Actual_Cost__c : 0;
                totalCommittedCost += (projectPriceBook.Total_Committed_Cost__c != null) ? projectPriceBook.Total_Committed_Cost__c : 0;
                actionableRevenue += (projectPriceBook.Actionable_Revenue__c != null) ? projectPriceBook.Actionable_Revenue__c : 0;
                approvedRevToDate += (projectPriceBook.Approved_REV_To_Date__c != null) ? projectPriceBook.Approved_REV_To_Date__c : 0;
                claimedRevToDate += (projectPriceBook.Claimed_REV_To_Date__c != null) ? projectPriceBook.Claimed_REV_To_Date__c : 0;
                numberOfActiveJobs += (projectPriceBook.Number_of_Active_Jobs__c != null) ? projectPriceBook.Number_of_Active_Jobs__c : 0;
                numberOfJobs += (projectPriceBook.Number_of_Jobs__c != null) ? projectPriceBook.Number_of_Jobs__c : 0;
            }
    
            program.Total_Actual_Cost__c = totalActualCost;
            program.Total_Committed_Cost__c = totalCommittedCost;
            program.Actionable_Revenue__c = actionableRevenue;
            program.Approved_REV_To_Date__c = approvedRevToDate;
            program.Claimed_REV_To_Date__c = claimedRevToDate;
            program.Number_of_Active_Job__c = numberOfActiveJobs;
            program.Number_of_Jobs__c = numberOfJobs;
        }
        update programs;
    }
}
