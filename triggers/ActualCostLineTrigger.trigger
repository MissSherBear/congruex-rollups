trigger ActualCostLineTrigger on Actual_Cost_Line__c (after insert, after update, after delete, after undelete) {
    // Helper method to handle different trigger operations
    if (Trigger.isInsert || Trigger.isUpdate || Trigger.isDelete || Trigger.isUndelete) {
        Set<Id> budgetCostLineIds = new Set<Id>();
        Set<Id> jobIds = new Set<Id>();

        // Collect Parent Budget Cost Line and Job IDs from the affected Actual Cost Lines
        if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
            for (Actual_Cost_Line__c acl : Trigger.new) {
                if (acl.Budget_Line__c != null) {
                    budgetCostLineIds.add(acl.Budget_Line__c);
                }
            }
        }

        if (Trigger.isDelete) {
            for (Actual_Cost_Line__c acl : Trigger.old) {
                if (acl.Budget_Line__c != null) {
                    budgetCostLineIds.add(acl.Budget_Line__c);
                }
            }
        }

        // Update the sums on the Budget Cost Line and its parent Job
        if (!budgetCostLineIds.isEmpty()) {
            CommittedCostLineHelper.updateBudgetCostLines(budgetCostLineIds);
        }
    }
}