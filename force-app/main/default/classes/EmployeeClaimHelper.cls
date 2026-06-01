public with sharing class EmployeeClaimHelper extends TriggerHandler{
    private List<Employee_Claim__c>    newRecords = new List<Employee_Claim__c>();
    private Map<id, Employee_Claim__c> newRecordsMap = new Map<Id,Employee_Claim__c>();
    private List<Employee_Claim__c>    oldRecods = new List<Employee_Claim__c>();
    private Map<Id, Employee_Claim__c> oldRecordsMap = new Map<Id,Employee_Claim__c>();

    public EmployeeClaimHelper() {
        this.newRecords    = (List<Employee_Claim__c>) newRecords;
        this.newRecordsMap = (Map<Id,Employee_Claim__c>) newRecordsMap;
        this.oldRecods     = (List<Employee_Claim__c>) oldRecods;
        this.oldRecordsMap = (Map<Id,Employee_Claim__c>) oldRecordsMap;
    }
}