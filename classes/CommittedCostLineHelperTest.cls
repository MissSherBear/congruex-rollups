@isTest
public class CommittedCostLineHelperTest {
    
    @testSetup
    static void setupTestData() {
        sitetracker__Project_Template__c template = new sitetracker__Project_Template__c(
            Name = 'Test class Project Template',
            sitetracker__Active__c = true
        );
        insert template;

        sitetracker__Site__c site = new sitetracker__Site__c(
            Name = 'Test class Site'
        );
        insert site;

        sitetracker__Project__c project = new sitetracker__Project__c(
            sitetracker__Site__c = site.Id,
            sitetracker__ProjectTemplate__c = template.Id
        );
        insert project;

        sitetracker__Program2__c program = new sitetracker__Program2__c(
            Name = 'Test Program'
        );
        insert program;

        Account acct = new Account(
            Name = 'Test Account1',
            Customer_Group__c = 'Engineer', 
            Payment_Terms__c = 'N30',
            OU__c = 'CNS',   
            BillingStreet = '123 Test St',
            BillingCity = 'Test City',
            BillingState = 'CA',
            BillingPostalCode = '12345',
            BillingCountry = 'USA'
        );
        insert acct;

        sitetracker__Project_Price_Book__c projectPriceBook = new sitetracker__Project_Price_Book__c(
            Name = 'Test Project Price Book',
            Program__c = program.Id, 
            sitetracker__Project_Template__c = template.Id,
            sitetracker__Active__c = true,
            dataAreaId__c = 'CNS',
            Customer__c = acct.Id
        );
        insert projectPriceBook;

        // Create a Job
        sitetracker__Job__c job = new sitetracker__Job__c(Name = 'Test Job', sitetracker__Project__c = project.Id, Project_Price_Book__c = projectPriceBook.Id, BU__c = 'CNS', Division__c = 'Interco', Client__c = acct.id);
        insert job;
        
        // Create Budget Cost Line
        Budget_Cost_Line__c budgetCostLine = new Budget_Cost_Line__c(Job__c = job.Id, Estimated_Cost__c = 1000);
        insert budgetCostLine;
        
        // Create Committed Cost Lines
        Committed_Cost_Line__c committedCostLine1 = new Committed_Cost_Line__c(Quantity__c = 500, Cost_Per_Unit__c = 1, Job__c = job.Id, Budget_Line__c = budgetCostLine.Id);
        Committed_Cost_Line__c committedCostLine2 = new Committed_Cost_Line__c(Quantity__c = 300, Cost_Per_Unit__c = 1, Job__c = job.Id, Budget_Line__c = budgetCostLine.Id);
        insert new List<Committed_Cost_Line__c>{committedCostLine1, committedCostLine2};
        
        // Create Actual Cost Lines
        Actual_Cost_Line__c actualCostLine1 = new Actual_Cost_Line__c(Quantity__c = 200, Cost_Per_Unit__c = 1, Job__c = job.Id, Budget_Line__c = budgetCostLine.Id);
        Actual_Cost_Line__c actualCostLine2 = new Actual_Cost_Line__c(Quantity__c = 400, Cost_Per_Unit__c = 1, Job__c = job.Id, Budget_Line__c = budgetCostLine.Id);
        insert new List<Actual_Cost_Line__c>{actualCostLine1, actualCostLine2};
    }
    
    @isTest
    static void testUpdateBudgetCostLines() {
        // Query test data
        Budget_Cost_Line__c budgetCostLine = [SELECT Id, Job__c FROM Budget_Cost_Line__c LIMIT 1];
        
        // Call the method to test
        Test.startTest();
        CommittedCostLineHelper.updateBudgetCostLines(new Set<Id>{budgetCostLine.Id});
        Test.stopTest();
        
        // Verify the Budget Cost Line updates
        Budget_Cost_Line__c updatedBudgetCostLine = [SELECT Committed_Cost__c, Actual_Cost__c FROM Budget_Cost_Line__c WHERE Id = :budgetCostLine.Id];
        System.assertEquals(800, updatedBudgetCostLine.Committed_Cost__c, 'Committed cost should be the sum of committed cost lines (500 + 300)');
        System.assertEquals(600, updatedBudgetCostLine.Actual_Cost__c, 'Actual cost should be the sum of actual cost lines (200 + 400)');
        
        // Verify the Job updates as well (since it's part of the update in the helper method)
        sitetracker__Job__c updatedJob = [SELECT Total_Committed_Cost__c, Total_Actual_Cost__c FROM sitetracker__Job__c WHERE Id = :budgetCostLine.Job__c];
        System.assertEquals(800, updatedJob.Total_Committed_Cost__c, 'Total committed cost should reflect the budget cost line update.');
        System.assertEquals(600, updatedJob.Total_Actual_Cost__c, 'Total actual cost should reflect the budget cost line update.');
    }
    
    @isTest
    static void testUpdateJobs() {
        // Query test data
        sitetracker__Job__c job = [SELECT Id FROM sitetracker__Job__c LIMIT 1];

        // Call the method to test
        Test.startTest();
        Map<Id, Decimal> jobCommittedCostMap = new Map<Id, Decimal>{ job.Id => 500 };
        Map<Id, Decimal> jobActualCostMap = new Map<Id, Decimal>{ job.Id => 300 };
        CommittedCostLineHelper.updateJobs(jobCommittedCostMap, jobActualCostMap);
        Test.stopTest();
        
        // Verify the Job updates
        sitetracker__Job__c updatedJob = [SELECT Total_Committed_Cost__c, Total_Actual_Cost__c, Approved_Hours__c, Payroll_Hours__c FROM sitetracker__Job__c WHERE Id = :job.Id];
        System.assertEquals(500, updatedJob.Total_Committed_Cost__c, 'Total committed cost should be 500');
        System.assertEquals(300, updatedJob.Total_Actual_Cost__c, 'Total actual cost should be 300');
        System.assertEquals(0, updatedJob.Approved_Hours__c, 'Approved hours should be 0 since no approved hours were added');
        System.assertEquals(0, updatedJob.Payroll_Hours__c, 'Payroll hours should be 0 since no payroll hours were added');
    }
}
