public with sharing class EmployeeClaimHelper extends TriggerHandler{
    private List<Employee_Claim__c>    newRecords = new List<Employee_Claim__c>();
    private Map<id, Employee_Claim__c> newRecordsMap = new Map<Id,Employee_Claim__c>();
    private List<Employee_Claim__c>    oldRecods = new List<Employee_Claim__c>();
    private Map<Id, Employee_Claim__c> oldRecordsMap = new Map<Id,Employee_Claim__c>();

    public EmployeeClaimHelper() {
        this.newRecords    = (List<Employee_Claim__c>) newRecords;
        this.newRecordsMap = (Map<Id,Employee_Claim__c>) newRecordsMap;
        //safe operator to test for prior records to prevent null exception error
        this.oldRecods     = (oldRecods != null) ? (List<Employee_Claim__c>) oldRecods : null;
        this.oldRecordsMap = (oldRecordsMap != null) ? (Map<Id,Employee_Claim__c>) oldRecordsMap : null;
    }
    public override void afterInsert(){
        this.executeAfterLogic();
    }

    public override void afterUpdate(){
        this.executeAfterLogic();
    }

    public override void afterDelete(){
        this.executeAfterLogic();
    }

    public override void afterUndelete(){
        this.executeAfterLogic();
    }

    private void executeAfterLogic(){
        System.debug('execute after logic is running');
    } 
}