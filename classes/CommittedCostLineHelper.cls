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
            Decimal totalCommittedCost = 0;
            Decimal totalActualCost = 0;

            for (Committed_Cost_Line__c ccl : bcl.Committed_Cost_Lines__r) {
                totalCommittedCost += ccl.Total_Cost__c != null ? ccl.Total_Cost__c : 0;
            }
            for (Actual_Cost_Line__c acl : bcl.Actual_Cost_Lines__r) {
                totalActualCost += acl.Total_Cost__c != null ? acl.Total_Cost__c : 0;
            }
            bcl.Committed_Cost__c = totalCommittedCost;
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
                            [SELECT Id, Total_Actual_Cost__c, Total_Committed_Cost__c, Total_Estimated_Cost__c,  Payroll_Hours__c, Approved_Hours__c,
                                Total_Committed_Labor_Cost__c, Total_Actual_Labor_Cost__c, Total_Committed_Subcontractor_Cost__c, Total_Actual_Subcontractor_Cost__c, 
                                Total_Committed_Material_Cost__c, Total_Actual_Material_Cost__c, Total_Committed_Equipment_Owned_Cost__c, Total_Actual_Equipment_Owned_Cost__c,
                                Total_Committed_Equipment_Rented_Cost__c, Total_Actual_Equipment_Rented_Cost__c, Total_Committed_Travel_Cost__c, Total_Actual_Travel_Cost__c,
                                Total_Committed_Other_Cost__c, Total_Actual_Other_Cost__c,
                                (SELECT Committed_Cost__c, Actual_Cost__c, Estimated_Cost__c, Cost_Category__r.Name FROM Budget_Lines__r),
                                (SELECT Total_Cost__c, Approved_Hours__c FROM Committed_Cost_Lines__r),
                                (SELECT Total_Cost__c, Payroll_Hours__c FROM Actual_Cost_Lines__r)
                            FROM sitetracker__Job__c WHERE Id IN :jobIds];
        
        for (sitetracker__Job__c job : jobs) {
            Decimal totalJobCommittedCost = 0;
            Decimal totalJobEstimatedCost = 0;
            Decimal totalJobActualCost = 0;
            Decimal totalCommittedLaborCost = 0;
            Decimal totalActualLaborCost = 0;
            Decimal totalCommittedSubcontractorCost = 0;
            Decimal totalActualSubcontractorCost = 0;
            Decimal totalCommittedMaterialCost = 0;
            Decimal totalActualMaterialCost = 0;
            Decimal totalCommittedEquipmentOwnedCost = 0;
            Decimal totalActualEquipmentOwnedCost = 0;
            Decimal totalCommittedEquipmentRentedCost = 0;
            Decimal totalActualEquipmentRentedCost = 0;
            Decimal totalCommittedTravelCost = 0;
            Decimal totalActualTravelCost = 0;
            Decimal totalCommittedOtherCost = 0;
            Decimal totalActualOtherCost = 0;
            Decimal totalApprovedHours = 0;
            Decimal totalPayrollHours = 0;

            for (Budget_Cost_Line__c bcl : job.Budget_Lines__r) {
                totalJobCommittedCost += bcl.Committed_Cost__c != null ? bcl.Committed_Cost__c : 0;
                totalJobEstimatedCost += bcl.Estimated_Cost__c != null ? bcl.Estimated_Cost__c : 0;
                totalJobActualCost += bcl.Actual_Cost__c != null ? bcl.Actual_Cost__c : 0;

                if (bcl.Cost_Category__r.Name == 'Labor') {
                    totalCommittedLaborCost += bcl.Committed_Cost__c != null ? bcl.Committed_Cost__c : 0;
                    totalActualLaborCost += bcl.Actual_Cost__c != null ? bcl.Actual_Cost__c : 0;
                } else if (bcl.Cost_Category__r.Name == 'Sub-Contractor') {
                    totalCommittedSubcontractorCost += bcl.Committed_Cost__c != null ? bcl.Committed_Cost__c : 0;
                    totalActualSubcontractorCost += bcl.Actual_Cost__c != null ? bcl.Actual_Cost__c : 0;
                } else if (bcl.Cost_Category__r.Name == 'Material') {
                    totalCommittedMaterialCost += bcl.Committed_Cost__c != null ? bcl.Committed_Cost__c : 0;
                    totalActualMaterialCost += bcl.Actual_Cost__c != null ? bcl.Actual_Cost__c : 0;
                } else if (bcl.Cost_Category__r.Name == 'Equipment - Owned') {
                    totalCommittedEquipmentOwnedCost += bcl.Committed_Cost__c != null ? bcl.Committed_Cost__c : 0;
                    totalActualEquipmentOwnedCost += bcl.Actual_Cost__c != null ? bcl.Actual_Cost__c : 0;
                } else if (bcl.Cost_Category__r.Name == 'Equipment - Rented') {
                    totalCommittedEquipmentRentedCost += bcl.Committed_Cost__c != null ? bcl.Committed_Cost__c : 0;
                    totalActualEquipmentRentedCost += bcl.Actual_Cost__c != null ? bcl.Actual_Cost__c : 0;
                } else if (bcl.Cost_Category__r.Name == 'Travel') {
                    totalCommittedTravelCost += bcl.Committed_Cost__c != null ? bcl.Committed_Cost__c : 0;
                    totalActualTravelCost += bcl.Actual_Cost__c != null ? bcl.Actual_Cost__c : 0;
                } else if (bcl.Cost_Category__r.Name == 'Other') {
                    totalCommittedOtherCost += bcl.Committed_Cost__c != null ? bcl.Committed_Cost__c : 0;
                    totalActualOtherCost += bcl.Actual_Cost__c != null ? bcl.Actual_Cost__c : 0;
                }
            }

            for (Committed_Cost_Line__c ccl : job.Committed_Cost_Lines__r) {
                totalApprovedHours += ccl.Approved_Hours__c != null ? ccl.Approved_Hours__c : 0;
            }
            for (Actual_Cost_Line__c acl : job.Actual_Cost_Lines__r) {
                totalPayrollHours += acl.Payroll_Hours__c != null ? acl.Payroll_Hours__c : 0;
            }
            
            job.Total_Committed_Cost__c = totalJobCommittedCost;
            job.Total_Actual_Cost__c = totalJobActualCost;
            job.Total_Estimated_Cost__c = totalJobEstimatedCost;
            job.Total_Committed_Labor_Cost__c = totalCommittedLaborCost;
            job.Total_Actual_Labor_Cost__c = totalActualLaborCost;
            job.Total_Committed_Subcontractor_Cost__c = totalCommittedSubcontractorCost;
            job.Total_Actual_Subcontractor_Cost__c = totalActualSubcontractorCost;
            job.Total_Committed_Material_Cost__c = totalCommittedMaterialCost;
            job.Total_Actual_Material_Cost__c = totalActualMaterialCost;
            job.Total_Committed_Equipment_Owned_Cost__c = totalCommittedEquipmentOwnedCost;
            job.Total_Actual_Equipment_Owned_Cost__c = totalActualEquipmentOwnedCost;
            job.Total_Committed_Equipment_Rented_Cost__c = totalCommittedEquipmentRentedCost;
            job.Total_Actual_Equipment_Rented_Cost__c = totalActualEquipmentRentedCost;
            job.Total_Committed_Travel_Cost__c = totalCommittedTravelCost;
            job.Total_Actual_Travel_Cost__c = totalActualTravelCost;
            job.Total_Committed_Other_Cost__c = totalCommittedOtherCost;
            job.Total_Actual_Other_Cost__c = totalActualOtherCost;
            job.Approved_Hours__c = totalApprovedHours;
            job.Payroll_Hours__c = totalPayrollHours;
        }

        // Update Jobs
        if (!jobs.isEmpty()) {
            update jobs;
        }
    }
}
