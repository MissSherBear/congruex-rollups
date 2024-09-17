@isTest
public class RollupHandlerTest {
    
    @testSetup
    static void setup() {

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

        // Create test Programs
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

        // Create test Project Price Books
        List<sitetracker__Project_Price_Book__c> projectPriceBooks = new List<sitetracker__Project_Price_Book__c>();
        for (Integer i = 0; i < 2; i++) {
            projectPriceBooks.add(new sitetracker__Project_Price_Book__c(
                Name = 'Test Project Price Book ' + i, 
                Program__c = program.Id, 
                sitetracker__Project_Template__c = template.Id,
                sitetracker__Active__c = true,
                dataAreaId__c = 'CNS',
                Customer__c = acct.Id
            ));
        }

        insert projectPriceBooks;

        // Create test Price Book Items
        sitetracker__Pricebook_Item__c pbi = new sitetracker__Pricebook_Item__c(
            Name = 'Test Price Book Item',
            sitetracker__Project_Price_Book__c = projectPriceBooks[0].Id,
            Price_Per_Unit__c = 2.00
        );

        insert pbi;

        // Create test Jobs
        List<sitetracker__Job__c> jobs = new List<sitetracker__Job__c>();
        for (Integer i = 0; i < 2; i++) {
            jobs.add(new sitetracker__Job__c(
                Name = 'Test Job ' + i, 
                Project_Price_Book__c = projectPriceBooks[i].Id,
                BU__c = 'CNS',
                Division__c = 'Interco',
                Client__c = acct.id
            ));
        }
        insert jobs;

        // Create test Finances
        List<sitetracker__Finance__c> finances = new List<sitetracker__Finance__c>();
        for (Integer i = 0; i < 2; i++) {
            finances.add(new sitetracker__Finance__c(
                Job__c = jobs[i].Id,
                sitetracker__Pricebook_Item__c = pbi.Id
            ));
        }
        insert finances;

        // Create test Work Logs
        List<Work_Log__c> workLogs = new List<Work_Log__c>();
        for (Integer i = 0; i < 2; i++) {
            workLogs.add(new Work_Log__c(
                Finance__c = finances[i].Id, 
                Claimed_QTY__c = 100, 
                Work_Log_Approval_Status__c = 'Approved', 
                Work_Date__c = Date.today(),
                Unbillable__c = false));
        }
        insert workLogs;
    }

    @isTest
    static void testHandleWorkLogs() {
        // Retrieve Work Logs for testing
        List<Work_Log__c> workLogs = [SELECT Id, Finance__c, Bill_Log__c FROM Work_Log__c];
        
        // Call the handler method
        Test.startTest();
        RollupHandler.handleWorkLogs(workLogs);
        Test.stopTest();
        
        // Verify the results
        List<sitetracker__Finance__c> finances = [SELECT Id, Approved_WL_QTY__c FROM sitetracker__Finance__c];
        for (sitetracker__Finance__c finance : finances) {
            System.debug('Finance ' + finance.Id + ' Approved_WL_QTY__c: ' + finance.Approved_WL_QTY__c);
            System.assertEquals(100, finance.Approved_WL_QTY__c, 'Finance Approved_WL_QTY__c should be 100');
        }
    }

    @isTest
    static void testHandleFinances() {
        // Retrieve Finances for testing
        List<sitetracker__Finance__c> finances = [SELECT Id, Job__c FROM sitetracker__Finance__c];
        
        // Call the handler method
        Test.startTest();
        RollupHandler.handleFinances(finances);
        Test.stopTest();
        
        // Verify the results
        List<sitetracker__Job__c> jobs = [SELECT Id, Claimed_REV_to_Date__c FROM sitetracker__Job__c];
        for (sitetracker__Job__c job : jobs) {
            System.debug(LoggingLevel.INFO, 'Job ' + job.Id + ' Claimed_REV_to_Date__c: ' + job.Claimed_REV_to_Date__c);
            System.assertEquals(200, job.Claimed_REV_to_Date__c, 'Job Claimed_REV_to_Date__c should be 200');
        }
    }

    @isTest
    static void testHandleJobs() {
        // Retrieve Jobs for testing
        List<sitetracker__Job__c> jobs = [SELECT Id, Project_Price_Book__c, Total_Actual_Cost__c FROM sitetracker__Job__c];
        
        // Call the handler method
        Test.startTest();
        RollupHandler.handleJobs(jobs);
        Test.stopTest();
        
        // Verify the results
        List<sitetracker__Project_Price_Book__c> projectPriceBooks = [SELECT Id, Claimed_REV_To_Date__c, Total_Actual_Cost__c FROM sitetracker__Project_Price_Book__c];
        for (sitetracker__Project_Price_Book__c projectPriceBook : projectPriceBooks) {
            System.assertEquals(200, projectPriceBook.Claimed_REV_to_Date__c, 'Project Price Book Claimed_REV_to_Date__c should be 400');
        }
    }

    @isTest
    static void testHandleProjectPriceBooks() {
        // Retrieve Project Price Books for testing
        List<sitetracker__Project_Price_Book__c> projectPriceBooks = [SELECT Id, Program__c FROM sitetracker__Project_Price_Book__c];
        
        // Add debug log
        for (sitetracker__Project_Price_Book__c ppb : projectPriceBooks) {
            System.debug('Project Price Book: ' + ppb);
            System.debug('Program__c: ' + ppb.Program__c);
        }

        // Call the handler method
        Test.startTest();
        RollupHandler.handleProjectPriceBooks(projectPriceBooks);
        Test.stopTest();
        
        // Verify the results
        List<sitetracker__Program2__c> programs = [SELECT Id, Claimed_REV_to_Date__c, Total_Actual_Cost__c FROM sitetracker__Program2__c];
        for (sitetracker__Program2__c program : programs) {
            System.assertEquals(400, program.Claimed_REV_to_Date__c, 'Program Claimed_REV_to_Date__c should be 800');
        }
    }
}