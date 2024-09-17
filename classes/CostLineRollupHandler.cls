public class CostLineRollupHandler {
    public static void handleCommittedCostLines() {
        Set<Id> budgetLineIds = new Set<Id>();

        for (Committed_Cost_Line__c ccLine : ccLines) {
            budgetLineIds.add(ccLine.Budget_Line__c);
        }

        updateBudgetLine(budgetLineIds);
    }

    public static void handleActualCostLines() {
        Set<Id> budgetLineIds = new Set<Id>();

        for (Actual_Cost_Line__c acLine : acLines) {
            budgetLineIds.add(acLine.Budget_Line__c);
        }

        updateBudgetLine(budgetLineIds);
    }

    private static void updateBudgetLine(Set<Id> budgetLineIds) {
        List<Budget_Cost_Line__c> budgetCostLines = [SELECT Id, Committed_Cost__c, Actual_Cost__c, 
                                                        (SELECT Id, Total_Cost__c FROM Committed_Cost_Lines__r), 
                                                        (SELECT Id, Total_Cost__c FROM Actual_Cost_Lines__r)
                                                    FROM Budget_Cost_Line__c WHERE Id IN :budgetLineIds];

        for (Budget_Cost_Line__c bcl : budgetCostLines) {
            Decimal totalCost = 0;
            Decimal actualCost = 0;

            for (Committed_Cost_Line__c ccLine : bcl.Committed_Cost_Lines__r) {
                totalCost += ccLine.Total_Cost__c;
            }

            for (Actual_Cost_Line__c acLine : bcl.Actual_Cost_Lines__r) {
                actualCost += acLine.Total_Cost__c;
            }

            bcl.Committed_Cost__c = totalCost;
        }

        update budgetCostLines;
    }


}
