public with sharing class RollupFinance {
    public static void updateFinance(Set<Id> financeIds) {
        List<sitetracker__Finance__c> finances = [SELECT Id, Actual_Amount__c, Actual_Qty__c, Approved_WL_QTY__c, Price_Per_Unit_Formula__c, 
                                                  of_Approved_Work_Logs__c, of_Unbilled_Work_Logs__c, of_Work_Logs__c, Actual_Invoiced_New__c, 
                                                  Approved_To_Bill__c, Claimed_QTY_New__c, CMTD_INT_Cost__c, CMTD_INT_QTY__c, CMTD_EXT_Cost__c, 
                                                  CMTD_EXT_QTY__c, Unbillable_QTY_WL__c, Cash_Receipt__c, Invoice_Posted__c, Open_Order__c, 
                                                  Proposal_Created__c, Finalized_Revenue__c, Finance_Line_Type__c
                                                  FROM sitetracker__Finance__c WHERE Id IN :financeIds];

        List<Work_Log__c> relatedWorkLogs = [SELECT Id, Finance__c, Claimed_QTY__c, Work_Log_Approval_Status__c, Unbillable__c, Ready_To_Invoice__c,
                                             Bill_Log__c, Bill_Log_Name__c, Work_Log_Actual_Amount__c, Resource_Type__c, Labor_Cost__c, Finance_Line_Type__c
                                             FROM Work_Log__c WHERE Finance__c IN :financeIds];

        List<Bill_Log__c> billLogs = [SELECT Id, Finance__c, Billable_Amount__c, Invoice_Status__c, Confirm_Submission__c, Unbillable__c, BU__c
                                      FROM Bill_Log__c WHERE Finance__c IN :financeIds];
        
        Map<Id, List<Work_Log__c>> financeToWorkLogsMap = new Map<Id, List<Work_Log__c>>();
        Map<Id, List<Bill_Log__c>> financeToBillLogsMap = new Map<Id, List<Bill_Log__c>>();

        for (Work_Log__c workLog : relatedWorkLogs) {
            if (!financeToWorkLogsMap.containsKey(workLog.Finance__c)) {
                financeToWorkLogsMap.put(workLog.Finance__c, new List<Work_Log__c>());
            }
            financeToWorkLogsMap.get(workLog.Finance__c).add(workLog);
        }

        for (Bill_Log__c billLog : billLogs) {
            if (!financeToBillLogsMap.containsKey(billLog.Finance__c)) {
                financeToBillLogsMap.put(billLog.Finance__c, new List<Bill_Log__c>());
            }
            financeToBillLogsMap.get(billLog.Finance__c).add(billLog);
        } 

        for (sitetracker__Finance__c finance : finances) {
            // Work Log aggregates
            Decimal approvedWLQty = 0;
            Decimal actualInvoiced = 0;
            Decimal approvedToBill = 0;
            Decimal claimedQty = 0;
            Decimal committedSelfCost = 0;
            Decimal committedSelfQty = 0;
            Decimal committedSubCost = 0;
            Decimal committedSubQty = 0;
            Decimal unbillableQtyWL = 0;
            Integer approvedWorkLogs = 0;
            Integer unbilledWorkLogs = 0;
            Integer workLogsCount = 0;

            // Bill Log aggregates
            Decimal cashReceipt = 0;
            Decimal invoicePosted = 0;
            Decimal openOrder = 0;
            Decimal proposalCreated = 0;
            Decimal finalizedRevenue = 0;
            
            List<Work_Log__c> workLogs = financeToWorkLogsMap.get(finance.Id);
            if (workLogs != null) {
                for (Work_Log__c workLog : workLogs) {
                    if (workLog.Work_Log_Approval_Status__c == 'Approved') {
                        approvedWLQty += (workLog.Claimed_QTY__c != null) ? workLog.Claimed_QTY__c : 0;
                        approvedWorkLogs++;
                        if (workLog.Unbillable__c == false && workLog.Finance_Line_Type__c != 'Child') {
                            approvedToBill += (workLog.Claimed_QTY__c != null) ? workLog.Claimed_QTY__c : 0;
                            if (workLog.Bill_Log_Name__c == null && workLog.Work_Log_Actual_Amount__c != 0) {
                                unbilledWorkLogs++;
                            }
                        }
                        if (workLog.Resource_Type__c == 'Person') {
                            committedSelfQty += (workLog.Claimed_QTY__c != null) ? workLog.Claimed_QTY__c : 0;
                            committedSelfCost += (workLog.Labor_Cost__c != null) ? workLog.Labor_Cost__c : 0;
                        } else if (workLog.Resource_Type__c == 'Vendor') {
                            committedSubQty += (workLog.Claimed_QTY__c != null) ? workLog.Claimed_QTY__c : 0;
                            committedSubCost += (workLog.Labor_Cost__c != null) ? workLog.Labor_Cost__c : 0;
                        }
                    }
                    
                    if (workLog.Ready_To_Invoice__c == true) {
                        actualInvoiced += (workLog.Claimed_QTY__c != null) ? workLog.Claimed_QTY__c : 0;
                    }
                    if (workLog.Unbillable__c == true) {
                        unbillableQtyWL += (workLog.Claimed_QTY__c != null) ? workLog.Claimed_QTY__c : 0;
                    }
                    if (workLog.Finance_Line_Type__c != 'Child') {
                        claimedQty += (workLog.Claimed_QTY__c != null) ? workLog.Claimed_QTY__c : 0;
                    }
                    workLogsCount++;
                }
            }

            List<Bill_Log__c> billLogsForFinance = financeToBillLogsMap.get(finance.Id);
            if (billLogsForFinance != null) {
                for (Bill_Log__c billLog : billLogsForFinance) {
                    if (billLog.Invoice_Status__c == 'Paid' && billLog.BU__c != 'HHS') {
                        cashReceipt += (billLog.Billable_Amount__c != null) ? billLog.Billable_Amount__c : 0;
                    }
                    if (billLog.Invoice_Status__c == 'Invoiced' && billLog.BU__c != 'HHS') {
                        invoicePosted += (billLog.Billable_Amount__c != null) ? billLog.Billable_Amount__c : 0;
                    }
                    if (billLog.Invoice_Status__c == 'Open Order' && billLog.BU__c != 'HHS') {
                        openOrder += (billLog.Billable_Amount__c != null) ? billLog.Billable_Amount__c : 0;
                    }
                    if (billLog.Invoice_Status__c == 'Invoice Created' && billLog.BU__c != 'HHS') {
                        proposalCreated += (billLog.Billable_Amount__c != null) ? billLog.Billable_Amount__c : 0;
                    }
                    if (billLog.Confirm_Submission__c == true && billLog.Unbillable__c == false) {
                        finalizedRevenue += (billLog.Billable_Amount__c != null) ? billLog.Billable_Amount__c : 0;
                    }
                }
            }

            // Work Log aggregates
            finance.of_Approved_Work_Logs__c = approvedWorkLogs;
            finance.of_Unbilled_Work_Logs__c = unbilledWorkLogs;
            finance.of_Work_Logs__c = workLogsCount;
            finance.Actual_Invoiced_New__c = actualInvoiced;
            finance.Approved_To_Bill__c = approvedToBill;
            finance.Approved_WL_QTY__c = approvedWLQty;
            finance.Claimed_QTY_New__c = claimedQty;
            finance.CMTD_INT_Cost__c = committedSelfCost;
            finance.CMTD_INT_QTY__c = committedSelfQty;
            finance.CMTD_EXT_Cost__c = committedSubCost;
            finance.CMTD_EXT_QTY__c = committedSubQty;
            finance.Unbillable_QTY_WL__c = unbillableQtyWL;

            // Bill Log aggregates
            finance.Cash_Receipt__c = cashReceipt;
            finance.Invoice_Posted__c = invoicePosted;
            finance.Open_Order__c = openOrder;
            finance.Proposal_Created__c = proposalCreated;
            finance.Finalized_Revenue__c = finalizedRevenue;
        }
        update finances;
    }
}
