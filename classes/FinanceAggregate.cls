public class FinanceAggregate {
    // Aggregation fields for Work Logs and Bill Logs
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
    
    Decimal cashReceipt = 0;
    Decimal invoicePosted = 0;
    Decimal openOrder = 0;
    Decimal proposalCreated = 0;
    Decimal finalizedRevenue = 0;

    public void processWorkLog(Work_Log__c workLog) {
        if (workLog.Work_Log_Approval_Status__c == 'Approved') {
            approvedWLQty += workLog.Claimed_QTY__c;
            approvedWorkLogs++;

            if (!workLog.Unbillable__c) {
                approvedToBill += workLog.Claimed_QTY__c;

                if (workLog.Bill_Log_Name__c == null && workLog.Work_Log_Actual_Amount__c == 0) {
                    unbilledWorkLogs++;
                }
            }

            if (workLog.Resource_Type__c == 'Internal') {
                committedSelfCost += workLog.Labor_Cost__c;
            } else {
                committedSubCost += workLog.Labor_Cost__c;
            }
        }

        if (workLog.Ready_To_Invoice__c) {
            workLogsCount++;
        }
    }

    public void processBillLog(Bill_Log__c billLog) {
        if (billLog.Invoice_Status__c == 'Invoiced') {
            actualInvoiced += billLog.Billable_Amount__c;
        }
    }

    public void applyToFinance(sitetracker__Finance__c finance) {
        finance.Approved_Work_Log_QTY__c = approvedWLQty;
        finance.Approved_To_Bill__c = approvedToBill;
        finance.Committed_Self_Cost__c = committedSelfCost;
        finance.Unbilled_Work_Logs__c = unbilledWorkLogs;
    }
}
