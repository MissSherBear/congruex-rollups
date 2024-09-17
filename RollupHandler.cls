public class RollupHandler {

    public static void handleWorkLogs(List<Work_Log__c> workLogs) {
        Set<Id> financeIds = new Set<Id>();
        Set<Id> billLogIds = new Set<Id>();

        for (Work_Log__c workLog : workLogs) {
            financeIds.add(workLog.Finance__c);
            billLogIds.add(workLog.Bill_Log__c);
        }
        updateFinance(financeIds);
        updateBillLog(billLogIds);
    }

    public static void handleBillLogs(List<Bill_Log__c> billLogs) {
        Set<Id> financeIds = new Set<Id>();
        for (Bill_Log__c billLog : billLogs) {
            financeIds.add(billLog.Finance__c);
        }
        updateFinance(financeIds);
    }

    public static void handleFinances(List<sitetracker__Finance__c> finances) {
        Set<Id> jobIds = new Set<Id>();
        for (sitetracker__Finance__c finance : finances) {
            jobIds.add(finance.Job__c);
        }
        updateJob(jobIds);
    }

    public static void handleJobs(List<sitetracker__Job__c> jobs) {
        Set<Id> projectPriceBookIds = new Set<Id>();
        for (sitetracker__Job__c job : jobs) {
            projectPriceBookIds.add(job.Project_Price_Book__c);
        }
        updateProjectPriceBook(projectPriceBookIds);
    }

    public static void handleProjectPriceBooks(List<sitetracker__Project_Price_Book__c> projectPriceBooks) {
        Set<Id> programIds = new Set<Id>();
        for (sitetracker__Project_Price_Book__c projectPriceBook : projectPriceBooks) {
            if (projectPriceBook.Program__c != null) {
                programIds.add(projectPriceBook.Program__c);
            }
        }
        updateProgram(programIds);
    }

    public static void handleCommittedCostLines() {
        Set<Id> budgetCostLineIds = new Set<Id>();

        for (Committed_Cost_Line__c ccLine : ccLines) {
            budgetCostLineIds.add(ccLine.Budget_Line__c);
        }
        updateBudgetCostLine(budgetCostLineIds);
    }

    public static void handleActualCostLines() {
        Set<Id> budgetCostLineIds = new Set<Id>();

        for (Actual_Cost_Line__c acLine : acLines) {
            budgetCostLineIds.add(acLine.Budget_Line__c);
        }
        updateBudgetCostLine(budgetCostLineIds);
    }

    public static void handleBudgetCostLines(List<Budget_Cost_Line__c> budgetCostLines) {
        Set<Id> jobIds = new Set<Id>();
        for (Budget_Cost_Line__c bcl : budgetCostLines) {
            if (bcl.Job__c != null) {
                jobIds.add(bcl.Job__c);
            }
        }
        updateJobsFromCostLines(jobIds);
    }

    private static void updateBillLog(Set<Id> billLogIds) {
        List<Bill_Log__c> billLogs = [SELECT Id, Billable_Amount__c, of_Work_Logs__c, Invoice_Status__c, Confirm_Submission__c, Unbillable__c, BU__c 
                                      FROM Bill_Log__c WHERE Id IN :billLogIds];

        // Get related Work Logs
        List<Work_Log__c> workLogs = [SELECT Id, Finance__c, Claimed_QTY__c, Work_Log_Approval_Status__c, Unbillable__c, Ready_To_Invoice__c,
                                           Bill_Log__c, Bill_Log_Name__c, Work_Log_Actual_Amount__c, Resource_Type__c, Labor_Cost__c 
                                           FROM Work_Log__c WHERE Bill_Log__c IN :billLogIds];
        
        for (Bill_Log__c billLog : billLogs) {
            Integer numberOfWorkLogs = 0;

            for (Work_Log__c workLog : workLogs) {
                if (workLog.Bill_Log__c == billLog.Id) {
                    numberOfWorkLogs++;
                }
            }

            billLog.of_Work_Logs__c = numberOfWorkLogs;
        }

        update billLogs;
    }

    private static void updateBudgetCostLine(Set<Id> budgetCostLineIds) {
        List<Budget_Cost_Line__c> budgetCostLines = [SELECT Id, Estimated_Cost__c, Committed_Cost__c, Actual_Cost__c, 
                                                      (SELECT Id, Total_Cost__c FROM Committed_Cost_Lines__r), 
                                                      (SELECT Id, Total_Cost__c FROM Actual_Cost_Lines__r)
                                                      FROM Budget_Cost_Line__c WHERE Id IN :budgetCostLineIds];

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

    private static void updateJobsFromCostLines(Set<Id> jobIds) {
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
        
    private static void updateFinance(Set<Id> financeIds) {
        List<sitetracker__Finance__c> finances = [SELECT Id, Actual_Amount__c, Actual_Qty__c, Approved_WL_QTY__c, Price_Per_Unit_Formula__c, 
                                                  of_Approved_Work_Logs__c, of_Unbilled_Work_Logs__c, of_Unique_WL_Price_Per_Unit__c, of_Work_Logs__c, Actual_Invoiced_New__c, 
                                                  Approved_To_Bill__c, Claimed_QTY_New__c, CMTD_INT_Cost__c, CMTD_INT_QTY__c, CMTD_EXT_Cost__c, 
                                                  CMTD_EXT_QTY__c, Unbillable_QTY_WL__c, Cash_Receipt__c, Invoice_Posted__c, Open_Order__c, 
                                                  Proposal_Created__c, Finalized_Revenue__c 
                                                  FROM sitetracker__Finance__c WHERE Id IN :financeIds];
        
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
            Integer uniqueWLPricePerUnit = 0;

            // Bill Log aggregates
            Decimal cashReceipt = 0;
            Decimal invoicePosted = 0;
            Decimal openOrder = 0;
            Decimal proposalCreated = 0;
            Decimal finalizedRevenue = 0;

            List<Work_Log__c> relatedWorkLogs = [SELECT Id, Finance__c, Claimed_QTY__c, WL_Price_Per_Unit__c, Work_Log_Approval_Status__c, Unbillable__c, Ready_To_Invoice__c,
                                                 Bill_Log__c, Bill_Log_Name__c, Work_Log_Actual_Amount__c, Resource_Type__c, Labor_Cost__c 
                                                 FROM Work_Log__c WHERE Finance__c = :finance.Id];
            
            // From related Work Logs, aggregate values for count of Work Logs with unique values for WL Price Per Unit
            Set<Integer> uniqueWLPricePerUnitValues = new Set<Integer>();

            for (Work_Log__c workLog : relatedWorkLogs) {
                // Count of Work Logs with different unique values for WL Price Per Unit
                // Aggregate unique values count 
                if (!uniqueWLPricePerUnitValues.contains(workLog.WL_Price_Per_Unit__c)) {
                    uniqueWLPricePerUnitValues.add(workLog.WL_Price_Per_Unit__c);
                    uniqueWLPricePerUnit++;
                }

                if (workLog.Work_Log_Approval_Status__c == 'Approved') {
                    approvedWLQty += workLog.Claimed_QTY__c;
                    approvedWorkLogs++;

                    if (workLog.Unbillable__c == false) {
                        approvedToBill += workLog.Claimed_QTY__c;

                        if (workLog.Bill_Log_Name__c == null && workLog.Work_Log_Actual_Amount__c != 0) {
                            unbilledWorkLogs++;
                        }
                    }

                    if (workLog.Resource_Type__c == 'Person') {
                        committedSelfQty += workLog.Claimed_QTY__c;
                        committedSelfCost += workLog.Labor_Cost__c;
                    } else if (workLog.Resource_Type__c == 'Vendor') {
                        committedSubQty += workLog.Claimed_QTY__c;
                        committedSubCost += workLog.Labor_Cost__c;
                    }
                }
                
                if (workLog.Ready_To_Invoice__c == true) {
                    actualInvoiced += workLog.Claimed_QTY__c;
                }
                if (workLog.Unbillable__c == true) {
                    unbillableQtyWL += workLog.Claimed_QTY__c;
                }
                claimedQty += workLog.Claimed_QTY__c;
                workLogsCount++;
            }

            List<Bill_Log__c> billLogs = [SELECT Billable_Amount__c, Invoice_Status__c, Confirm_Submission__c, Unbillable__c, BU__c
                                          FROM Bill_Log__c WHERE Finance__c = :finance.Id];

            for (Bill_Log__c billLog : billLogs) {
                if (billLog.Invoice_Status__c == 'Paid' && billLog.BU__c != 'HHS') {
                    cashReceipt += billLog.Billable_Amount__c;
                }
                if (billLog.Invoice_Status__c == 'Invoiced' && billLog.BU__c != 'HHS') {
                    invoicePosted += billLog.Billable_Amount__c;
                }
                if (billLog.Invoice_Status__c == 'Open Order' && billLog.BU__c != 'HHS') {
                    openOrder += billLog.Billable_Amount__c;
                }
                if (billLog.Invoice_Status__c == 'Invoice Created' && billLog.BU__c != 'HHS') {
                    proposalCreated += billLog.Billable_Amount__c;
                }
                if (billLog.Confirm_Submission__c == true && billLog.Unbillable__c == false) {
                    finalizedRevenue += billLog.Billable_Amount__c;
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


    private static void updateJob(Set<Id> jobIds) {
        List<sitetracker__Job__c> jobs = [SELECT Id, Claimed_REV_to_Date__c, Approved_REV_to_Date__c, Cash_Receipt__c, 
                                          Finalized_REV_to_Date__c, Invoice_Posted__c, Open_Order__c, Proposal_Created__c 
                                          FROM sitetracker__Job__c WHERE Id IN :jobIds];
    
        for (sitetracker__Job__c job : jobs) {
            Decimal approvedRevToDate = 0;
            Decimal approvedRevToDate2 = 0;
            Decimal cashReceipt = 0;
            Decimal claimedRevToDate = 0;
            Decimal finalizedRevToDate = 0;
            Decimal invoicePosted = 0;
            Decimal openOrder = 0;
            Decimal proposalCreated = 0;
    
            List<sitetracker__Finance__c> relatedFinances = [SELECT Id, Total_Revenue_Accounted_For__c, Approved_WL_Revenue__c,
                                                             Cash_Receipt__c, Actual_Amount__c, Finalized_Revenue__c, 
                                                             Invoice_Posted__c, Open_Order__c, Proposal_Created__c, 
                                                             Add_Unbillable_Bill_Log__c, BU__c, Finance_Line_Type__c 
                                                             FROM sitetracker__Finance__c WHERE Job__c = :job.Id];
    
            for (sitetracker__Finance__c finance : relatedFinances) {
                if (finance.BU__c == 'HHS' && !finance.Add_Unbillable_Bill_Log__c) {
                    approvedRevToDate += (finance.Total_Revenue_Accounted_For__c != null) ? finance.Total_Revenue_Accounted_For__c : 0;
                }
                if (finance.BU__c != 'HHS') {
                    approvedRevToDate2 += (finance.Approved_WL_Revenue__c != null) ? finance.Approved_WL_Revenue__c : 0;
                }
                if (finance.Cash_Receipt__c != null && finance.BU__c != 'HHS') {
                    cashReceipt += finance.Cash_Receipt__c;
                }
                if (finance.Finance_Line_Type__c != 'Parent') {
                    claimedRevToDate += finance.Actual_Amount__c;
                }
                if (finance.Add_Unbillable_Bill_Log__c == null || !finance.Add_Unbillable_Bill_Log__c) {
                    finalizedRevToDate += (finance.Finalized_Revenue__c != null) ? finance.Finalized_Revenue__c : 0;
                }
                if (finance.Invoice_Posted__c != null && finance.BU__c != 'HHS') {
                    invoicePosted += finance.Invoice_Posted__c;
                }
                if (finance.Open_Order__c != null && finance.BU__c != 'HHS') {
                    openOrder += finance.Open_Order__c;
                }
                if (finance.Proposal_Created__c != null && finance.BU__c != 'HHS') {
                    proposalCreated += finance.Proposal_Created__c;
                }
            }
    
            job.Approved_REV_to_Date__c = approvedRevToDate;
            job.Approved_REV_to_Date__c = approvedRevToDate2;
            job.Cash_Receipt__c = cashReceipt;
            job.Claimed_REV_to_Date__c = claimedRevToDate;
            job.Finalized_REV_to_Date__c = finalizedRevToDate;
            job.Invoice_Posted__c = invoicePosted;
            job.Open_Order__c = openOrder;
            job.Proposal_Created__c = proposalCreated;
        }
        
        update jobs;
    }

    private static void updateProjectPriceBook(Set<Id> projectPriceBookIds) {
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

    private static void updateProgram(Set<Id> programIds) {
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