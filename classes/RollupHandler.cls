public class RollupHandler {

    public static void handleWorkLogs(List<Work_Log__c> workLogs) {
        Set<Id> financeIds = new Set<Id>();
        Set<Id> billLogIds = new Set<Id>();

        for (Work_Log__c workLog : workLogs) {
            if (workLog.Finance__c != null) {
                financeIds.add(workLog.Finance__c);
            }
            if (workLog.Bill_Log__c != null) {
                billLogIds.add(workLog.Bill_Log__c);
            }
        }
        
        if (!financeIds.isEmpty()) {
            updateFinance(financeIds);
        }
        
        if (!billLogIds.isEmpty()) {
            updateBillLog(billLogIds);
        }
    }

    public static void handleBillLogs(List<Bill_Log__c> billLogs) {
        Set<Id> financeIds = new Set<Id>();
        for (Bill_Log__c billLog : billLogs) {
            if (billLog.Finance__c != null) {
                financeIds.add(billLog.Finance__c);
            }
        }
        
        if (!financeIds.isEmpty()) {
            updateFinance(financeIds);
        }
    }

    public static void handleFinances(List<sitetracker__Finance__c> finances) {
        Set<Id> jobIds = new Set<Id>();
        for (sitetracker__Finance__c finance : finances) {
            if (finance.Job__c != null) {
                jobIds.add(finance.Job__c);
            }
        }
        
        if (!jobIds.isEmpty()) {
            updateJob(jobIds);
        }
    }

    public static void handleJobs(List<sitetracker__Job__c> jobs) {
        Set<Id> projectPriceBookIds = new Set<Id>();
        for (sitetracker__Job__c job : jobs) {
            if (job.Project_Price_Book__c != null) {
                projectPriceBookIds.add(job.Project_Price_Book__c);
            }
        }
        
        if (!projectPriceBookIds.isEmpty()) {
            updateProjectPriceBook(projectPriceBookIds);
        }
    }

    public static void handleProjectPriceBooks(List<sitetracker__Project_Price_Book__c> projectPriceBooks) {
        Set<Id> programIds = new Set<Id>();
        for (sitetracker__Project_Price_Book__c projectPriceBook : projectPriceBooks) {
            if (projectPriceBook.Program__c != null) {
                programIds.add(projectPriceBook.Program__c);
            }
        }
        
        if (!programIds.isEmpty()) {
            updateProgram(programIds);
        }
    }

    private static void updateBillLog(Set<Id> billLogIds) {
        // Fetch Bill Logs
        List<Bill_Log__c> billLogs = [SELECT Id, of_Work_Logs__c FROM Bill_Log__c WHERE Id IN :billLogIds];

        // Fetch related Work Logs
        List<Work_Log__c> workLogs = [SELECT Id, Bill_Log__c FROM Work_Log__c WHERE Bill_Log__c IN :billLogIds];

        Map<Id, Integer> billLogToWorkLogCount = new Map<Id, Integer>();

        // Count the number of work logs per Bill Log
        for (Work_Log__c workLog : workLogs) {
            if (!billLogToWorkLogCount.containsKey(workLog.Bill_Log__c)) {
                billLogToWorkLogCount.put(workLog.Bill_Log__c, 0);
            }
            billLogToWorkLogCount.put(workLog.Bill_Log__c, billLogToWorkLogCount.get(workLog.Bill_Log__c) + 1);
        }

        // Update Bill Logs with the number of related Work Logs
        for (Bill_Log__c billLog : billLogs) {
            billLog.of_Work_Logs__c = billLogToWorkLogCount.containsKey(billLog.Id) ? billLogToWorkLogCount.get(billLog.Id) : 0;
        }

        update billLogs;
    }

    private static void updateFinance(Set<Id> financeIds) {
        // Fetch Finances
        List<sitetracker__Finance__c> finances = [SELECT Id FROM sitetracker__Finance__c WHERE Id IN :financeIds];

        // Fetch related Work Logs
        List<Work_Log__c> relatedWorkLogs = [SELECT Id, Finance__c, Claimed_QTY__c, Work_Log_Approval_Status__c, Unbillable__c, Ready_To_Invoice__c,
                                             Bill_Log_Name__c, Work_Log_Actual_Amount__c, Resource_Type__c, Labor_Cost__c
                                             FROM Work_Log__c WHERE Finance__c IN :financeIds];

        // Initialize Finance aggregations
        Map<Id, FinanceAggregate> financeAggregates = new Map<Id, FinanceAggregate>();

        for (sitetracker__Finance__c finance : finances) {
            financeAggregates.put(finance.Id, new FinanceAggregate());
        }

        // Populate aggregates
        for (Work_Log__c workLog : relatedWorkLogs) {
            FinanceAggregate agg = financeAggregates.get(workLog.Finance__c);
            agg.processWorkLog(workLog);
        }

        // Fetch related Bill Logs
        List<Bill_Log__c> billLogs = [SELECT Id, Finance__c, Billable_Amount__c, Invoice_Status__c, Confirm_Submission__c, Unbillable__c, BU__c
                                      FROM Bill_Log__c WHERE Finance__c IN :financeIds];

        // Populate Bill Log aggregates
        for (Bill_Log__c billLog : billLogs) {
            FinanceAggregate agg = financeAggregates.get(billLog.Finance__c);
            agg.processBillLog(billLog);
        }

        // Update Finances
        List<sitetracker__Finance__c> financesToUpdate = new List<sitetracker__Finance__c>();

        for (sitetracker__Finance__c finance : finances) {
            FinanceAggregate agg = financeAggregates.get(finance.Id);
            agg.applyToFinance(finance);
            financesToUpdate.add(finance);
        }

        update financesToUpdate;
    }

    private static void updateJob(Set<Id> jobIds) {
        // Fetch Jobs
        List<sitetracker__Job__c> jobs = [SELECT Id FROM sitetracker__Job__c WHERE Id IN :jobIds];

        // Fetch related Finances
        List<sitetracker__Finance__c> finances = [SELECT Id, Job__c FROM sitetracker__Finance__c WHERE Job__c IN :jobIds];

        // Initialize Job aggregates
        Map<Id, JobAggregate> jobAggregates = new Map<Id, JobAggregate>();

        for (sitetracker__Job__c job : jobs) {
            jobAggregates.put(job.Id, new JobAggregate());
        }

        // Populate aggregates from Finances
        for (sitetracker__Finance__c finance : finances) {
            JobAggregate agg = jobAggregates.get(finance.Job__c);
            agg.processFinance(finance);
        }

        // Update Jobs
        List<sitetracker__Job__c> jobsToUpdate = new List<sitetracker__Job__c>();

        for (sitetracker__Job__c job : jobs) {
            JobAggregate agg = jobAggregates.get(job.Id);
            agg.applyToJob(job);
            jobsToUpdate.add(job);
        }

        update jobsToUpdate;
    }

    private static void updateProjectPriceBook(Set<Id> projectPriceBookIds) {
        // Fetch Project Price Books
        List<sitetracker__Project_Price_Book__c> projectPriceBooks = [SELECT Id FROM sitetracker__Project_Price_Book__c WHERE Id IN :projectPriceBookIds];

        // Fetch related Jobs
        List<sitetracker__Job__c> jobs = [SELECT Id, Project_Price_Book__c FROM sitetracker__Job__c WHERE Project_Price_Book__c IN :projectPriceBookIds];

        // Initialize Project Price Book aggregates
        Map<Id, ProjectPriceBookAggregate> ppbAggregates = new Map<Id, ProjectPriceBookAggregate>();

        for (sitetracker__Project_Price_Book__c ppb : projectPriceBooks) {
            ppbAggregates.put(ppb.Id, new ProjectPriceBookAggregate());
        }

        // Populate aggregates from Jobs
        for (sitetracker__Job__c job : jobs) {
            ProjectPriceBookAggregate agg = ppbAggregates.get(job.Project_Price_Book__c);
            agg.processJob(job);
        }

        // Update Project Price Books
        List<sitetracker__Project_Price_Book__c> ppbsToUpdate = new List<sitetracker__Project_Price_Book__c>();

        for (sitetracker__Project_Price_Book__c ppb : projectPriceBooks) {
            ProjectPriceBookAggregate agg = ppbAggregates.get(ppb.Id);
            agg.applyToProjectPriceBook(ppb);
            ppbsToUpdate.add(ppb);
        }

        update ppbsToUpdate;
    }

    private static void updateProgram(Set<Id> programIds) {
        // Fetch Programs
        List<Program__c> programs = [SELECT Id FROM Program__c WHERE Id IN :programIds];

        // Fetch related Project Price Books
        List<sitetracker__Project_Price_Book__c> projectPriceBooks = [SELECT Id, Program__c FROM sitetracker__Project_Price_Book__c WHERE Program__c IN :programIds];

        // Initialize Program aggregates
        Map<Id, ProgramAggregate> programAggregates = new Map<Id, ProgramAggregate>();

        for (Program__c program : programs) {
            programAggregates.put(program.Id, new ProgramAggregate());
        }

        // Populate aggregates from Project Price Books
        for (sitetracker__Project_Price_Book__c ppb : projectPriceBooks) {
            ProgramAggregate agg = programAggregates.get(ppb.Program__c);
            agg.processProjectPriceBook(ppb);
        }

        // Update Programs
        List<Program__c> programsToUpdate = new List<Program__c>();

        for (Program__c program : programs) {
            ProgramAggregate agg = programAggregates.get(program.Id);
            agg.applyToProgram(program);
            programsToUpdate.add(program);
        }

        update programsToUpdate;
    }
}
