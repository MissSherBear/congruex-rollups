public with sharing class RollupBudgetCostLine {
    public static void updateRollups(Set<Id> jobIds) {
        // Query Jobs and their related Budget Cost Lines
        List<sitetracker__Job__c> jobs = [SELECT Id, (SELECT Id, Job__c, Committed_Cost__c, Actual_Cost__c, Estimated_Cost__c, Cost_Category__r.Name 
                                                     FROM Budget_Cost_Lines__r) 
                                          FROM sitetracker__Job__c WHERE Id IN :jobIds];

        for (sitetracker__Job__c job : jobs) {
            Decimal totalCommittedCost = 0;
            Decimal totalActualCost = 0;
            Decimal totalEstimatedCost = 0;
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

            for (Budget_Cost_Line__c budgetCostLine : job.Budget_Cost_Lines__r) {
                totalCommittedCost += (budgetCostLine.Committed_Cost__c != null) ? budgetCostLine.Committed_Cost__c : 0;
                totalActualCost += (budgetCostLine.Actual_Cost__c != null) ? budgetCostLine.Actual_Cost__c : 0;
                totalEstimatedCost += (budgetCostLine.Estimated_Cost__c != null) ? budgetCostLine.Estimated_Cost__c : 0;

                if (budgetCostLine.Cost_Category__r.Name == 'Labor') {
                    totalCommittedLaborCost += (budgetCostLine.Committed_Cost__c != null) ? budgetCostLine.Committed_Cost__c : 0;
                    totalActualLaborCost += (budgetCostLine.Actual_Cost__c != null) ? budgetCostLine.Actual_Cost__c : 0;
                } else if (budgetCostLine.Cost_Category__r.Name == 'Subcontractor') {
                    totalCommittedSubcontractorCost += (budgetCostLine.Committed_Cost__c != null) ? budgetCostLine.Committed_Cost__c : 0;
                    totalActualSubcontractorCost += (budgetCostLine.Actual_Cost__c != null) ? budgetCostLine.Actual_Cost__c : 0;
                } else if (budgetCostLine.Cost_Category__r.Name == 'Material') {
                    totalCommittedMaterialCost += (budgetCostLine.Committed_Cost__c != null) ? budgetCostLine.Committed_Cost__c : 0;
                    totalActualMaterialCost += (budgetCostLine.Actual_Cost__c != null) ? budgetCostLine.Actual_Cost__c : 0;
                } else if (budgetCostLine.Cost_Category__r.Name == 'Equipment Owned') {
                    totalCommittedEquipmentOwnedCost += (budgetCostLine.Committed_Cost__c != null) ? budgetCostLine.Committed_Cost__c : 0;
                    totalActualEquipmentOwnedCost += (budgetCostLine.Actual_Cost__c != null) ? budgetCostLine.Actual_Cost__c : 0;
                } else if (budgetCostLine.Cost_Category__r.Name == 'Equipment Rented') {
                    totalCommittedEquipmentRentedCost += (budgetCostLine.Committed_Cost__c != null) ? budgetCostLine.Committed_Cost__c : 0;
                    totalActualEquipmentRentedCost += (budgetCostLine.Actual_Cost__c != null) ? budgetCostLine.Actual_Cost__c : 0;
                } else if (budgetCostLine.Cost_Category__r.Name == 'Travel') {
                    totalCommittedTravelCost += (budgetCostLine.Committed_Cost__c != null) ? budgetCostLine.Committed_Cost__c : 0;
                    totalActualTravelCost += (budgetCostLine.Actual_Cost__c != null) ? budgetCostLine.Actual_Cost__c : 0;
                } else if (budgetCostLine.Cost_Category__r.Name == 'Other') {
                    totalCommittedOtherCost += (budgetCostLine.Committed_Cost__c != null) ? budgetCostLine.Committed_Cost__c : 0;
                    totalActualOtherCost += (budgetCostLine.Actual_Cost__c != null) ? budgetCostLine.Actual_Cost__c : 0;
                }

            }

            job.Total_Committed_Cost__c = totalCommittedCost;
            job.Total_Actual_Cost__c = totalActualCost;
            job.Total_Estimated_Cost__c = totalEstimatedCost;
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

        }

        update jobs;

    }
}
