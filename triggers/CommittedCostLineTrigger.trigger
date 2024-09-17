trigger CommittedCostLineTrigger on Committed_Cost_Line__c (after insert, after update, after delete, after undelete) {
    // Helper method to handle different trigger operations
    if (Trigger.isInsert || Trigger.isUpdate || Trigger.isDelete || Trigger.isUndelete) {
        Set<Id> budgetCostLineIds = new Set<Id>();
        Set<Id> jobIds = new Set<Id>();

        // Collect Parent Budget Cost Line and Job IDs from the affected Committed Cost Lines
        if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
            for (Committed_Cost_Line__c ccl : Trigger.new) {
                if (ccl.Budget_Line__c != null) {
                    budgetCostLineIds.add(ccl.Budget_Line__c);
                }
            }
        }

        if (Trigger.isDelete) {
            for (Committed_Cost_Line__c ccl : Trigger.old) {
                if (ccl.Budget_Line__c != null) {
                    budgetCostLineIds.add(ccl.Budget_Line__c);
                }
            }
        }

        // Update the sums on the Budget Cost Line and its parent Job
        if (!budgetCostLineIds.isEmpty()) {
            CommittedCostLineHelper.updateBudgetCostLines(budgetCostLineIds);
        }
    }
}
