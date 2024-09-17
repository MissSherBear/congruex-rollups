public class CommittedCostLineHelper {
    public static void updateBudgetCostLines(Set<Id> budgetCostLineIds) {
        // Query the Budget Cost Lines and the related Jobs
        List<Budget_Cost_Line__c> budgetCostLines = [SELECT Id, Job__c, 
                                                        (SELECT Total_Cost__c FROM Committed_Cost_Lines__r),
                                                        (SELECT Total_Cost__c FROM Actual_Cost_Lines__r)
                                                     FROM Budget_Cost_Line__c 
                                                     WHERE Id IN :budgetCostLineIds];
        Set<Id> jobIds = new Set<Id>();
        
        // Iterate over each Budget Cost Line and sum the Committed Cost Lines
        for (Budget_Cost_Line__c bcl : budgetCostLines) {
            Decimal totalCommittedAmount = 0;
            Decimal totalActualCost = 0;

            for (Committed_Cost_Line__c ccl : bcl.Committed_Cost_Lines__r) {
                totalCommittedAmount += ccl.Total_Cost__c != null ? ccl.Total_Cost__c : 0;
            }
            for (Actual_Cost_Line__c acl : bcl.Actual_Cost_Lines__r) {
                totalActualCost += acl.Total_Cost__c != null ? acl.Total_Cost__c : 0;
            }
            bcl.Committed_Cost__c = totalCommittedAmount;
            bcl.Actual_Cost__c = totalActualCost;

            if (bcl.Job__c != null) {
                jobIds.add(bcl.Job__c);
            }
        }
        
        // Update Budget Cost Lines
        if (!budgetCostLines.isEmpty()) {
            update budgetCostLines;
        }

        // Update the related Jobs
        if (!jobIds.isEmpty()) {
            updateJobs(jobIds);
        }
    }

    public static void updateJobs(Set<Id> jobIds) {
        List<sitetracker__Job__c> jobs = 
                            [SELECT Id, Total_Actual_Cost__c, Total_Committed_Cost__c, Total_Estimated_Cost__c, Payroll_Hours__c, Approved_Hours__c,
                                (SELECT Committed_Cost__c, Actual_Cost__c, Estimated_Cost__c FROM Budget_Lines__r),
                                (SELECT Total_Cost__c, Approved_Hours__c FROM Committed_Cost_Lines__r),
                                (SELECT Total_Cost__c, Payroll_Hours__c FROM Actual_Cost_Lines__r)
                            FROM sitetracker__Job__c WHERE Id IN :jobIds];
        
        for (sitetracker__Job__c job : jobs) {
            Decimal totalJobCommittedAmount = 0;
            Decimal totalJobEstimatedCost = 0;
            Decimal totalJobActualCost = 0;
            Decimal totalApprovedHours = 0;
            Decimal totalPayrollHours = 0;

            for (Budget_Cost_Line__c bcl : job.Budget_Lines__r) {
                totalJobCommittedAmount += bcl.Committed_Cost__c != null ? bcl.Committed_Cost__c : 0;
                totalJobEstimatedCost += bcl.Estimated_Cost__c != null ? bcl.Estimated_Cost__c : 0;
                totalJobActualCost += bcl.Actual_Cost__c != null ? bcl.Actual_Cost__c : 0;
            }

            for (Committed_Cost_Line__c ccl : job.Committed_Cost_Lines__r) {
                totalApprovedHours += ccl.Approved_Hours__c != null ? ccl.Approved_Hours__c : 0;
            }
            for (Actual_Cost_Line__c acl : job.Actual_Cost_Lines__r) {
                totalPayrollHours += acl.Payroll_Hours__c != null ? acl.Payroll_Hours__c : 0;
            }
            
            job.Total_Committed_Cost__c = totalJobCommittedAmount;
            job.Total_Actual_Cost__c = totalJobActualCost;
            job.Total_Estimated_Cost__c = totalJobEstimatedCost;
            job.Approved_Hours__c = totalApprovedHours;
            job.Payroll_Hours__c = totalPayrollHours;
        }

        // Update Jobs
        if (!jobs.isEmpty()) {
            update jobs;
        }
    }
}
