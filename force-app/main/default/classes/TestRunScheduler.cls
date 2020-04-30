/**
 * This class starts the unit test run.
 *
 * Each execution of the org's unit tests will have a parent job id,
 * this is stored in Test_Run__c.
 *
 * TestRunProcesssor.cls, also scheduleable, checks the status of the test
 * run. When it is complete it'll fire off and check the results.
 *
 * TLDR; this class starts the org's unit tests, but does nothing with the results.
 */
public with sharing class TestRunScheduler implements Schedulable {
    public void execute(SchedulableContext SC) {
        // get all unit test classes (excluding managed package unit tests)
        ApexClass[] testClasses = [FIND '@isTest' IN ALL FIELDS RETURNING ApexClass(Id, Name)][0];

        if (testClasses.size() > 0) {
            List<ApexTestQueueItem> queueItems = new List<ApexTestQueueItem>();
            for (ApexClass testClass : testClasses) {
                queueItems.add(new ApexTestQueueItem(ApexClassId = testClass.Id));
            }

            // bulk insert, when bulk inserted they will all contain the same ParentJobId
            if (!Test.isRunningTest()) {
                // can't queue unit tests while running a test
                insert queueItems;
            }

            Test_Run__c newRun = new Test_Run__c(
                Parent_Job_Id__c = queueItems[0].ParentJobId,
                Total_Classes__c = queueItems.size()
            );

            insert newRun;
        }
    }
}