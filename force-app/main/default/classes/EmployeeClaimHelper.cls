public with sharing class EmployeeClaimHelper extends TriggerHandler{
    private List<Employee_Claim__c>    newRecords = new List<Employee_Claim__c>();
    private Map<id, Employee_Claim__c> newRecordsMap = new Map<Id,Employee_Claim__c>();
    private List<Employee_Claim__c>    oldRecords = new List<Employee_Claim__c>();
    private Map<Id, Employee_Claim__c> oldRecordsMap = new Map<Id,Employee_Claim__c>();

    public EmployeeClaimHelper() {
        this.newRecords    = (List<Employee_Claim__c>) Trigger.new;
        this.newRecordsMap = (Map<Id,Employee_Claim__c>) Trigger.newMap;
        //safe operator to test for prior records to prevent null exception error
        this.oldRecords     = (Trigger.old != null) ? (List<Employee_Claim__c>) Trigger.old : null;
        this.oldRecordsMap = (Trigger.oldMap != null) ? (Map<Id,Employee_Claim__c>) Trigger.oldMap : null;
    }
    public override void beforeInsert(){
        this.preventDuplicateEmployeeClaims(this.newRecords);
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

    public void executeAfterLogic(){
        Set<Id> employeeIds = new Set<Id>();

        //Gather all relevant Employee Ids accross trigger insert/update/delete/undelete states
        List<Employee_Claim__c> sourceRecords = (Trigger.isDelete) ? this.oldRecords : this.newRecords;

        if(sourceRecords != null){
            for(Employee_Claim__c ec : sourceRecords){
                if (ec.Employee__c != null){
                    employeeIds.add(ec.Employee__c);
                }
                //if the employee assignment changed during an update, recalculate the old employee too
                if (Trigger.isUpdate && this.oldRecordsMap != null){
                    Employee_Claim__c oldRec = this.oldRecordsMap.get(ec.id);
                    if (oldRec != null && oldRec.Employee__c != null && oldRec.Employee__c != ec.Employee__c){
                        employeeIds.add(oldRec.Employee__c);
                    }
                }
            }
        }
        if (!employeeIds.isEmpty()){
            this.recalculateEmployeeMetricsAndRisk(employeeIds);
        }
    }

    private void preventDuplicateEmployeeClaims(List<Employee_Claim__c> recordsToCheck){
        //Prevent an Employee from being assigned to the same Claim twice (SCRUM-11 Data Recovery Logic)
        Set<Id> claimIds = new Set<Id>();
        Set<Id> employeeIds = new Set<Id>();

        for (Employee_Claim__c ec : recordsToCheck) {
            if (ec.Claim__c != null && ec.Employee__c != null){
                claimIds.add(ec.Claim__c);
                employeeIds.add(ec.Employee__c);
            }
        }
        if (claimIds.isEmpty()  || employeeIds.isEmpty()) {
            return;
        }
        //Query existing junction assignments to match parameters
        Set<String> existingPairs = new Set<String>();
        for (Employee_Claim__c existing : [
            SELECT Employee__c, Claim__c
            FROM Employee_Claim__c
            WHERE Claim__c IN :claimIds AND Employee__c IN :employeeIds
            WITH SYSTEM_MODE
            ]){
            existingPairs.add(String.valueOf(existing.Employee__c) + String.valueOf(existing.Claim__c));
        }
        //Compare incoming records and throw an error if duplicates occur
        for (Employee_Claim__c ec : recordsToCheck){
            String currentPair = String.valueOf(ec.Employee__c) + String.valueOf(ec.Claim__c);
            if (existingPairs.contains(currentPair)){
                ec.addError('This employee is already linked to the specific insurance claim incident.');
            }
        }
    }

    public void recalculateEmployeeMetricsAndRisk(Set<Id> employeeIds){
    /* SCRUM-9 Automation Risk Scoring
         * Complies claims metrics, map logic for evaluating risk and safely handle DML updates
         */
        List<Employee__c> employeesToUpdate = new List<Employee__c>();
        
        List<Employee__c> employeesWithClaims = [
            SELECT Id, 
                (SELECT Claim__r.Settlement_Amount__c, Claim__r.Insurance_Provider_Name__c 
                FROM Employee_Claims__r) 
            FROM Employee__c 
            WHERE Id IN :employeeIds
            WITH SYSTEM_MODE
        ];

        for (Employee__c emp : employeesWithClaims) {
            Integer totalClaimsCount = 0;
            Decimal totalPayout = 0.0;
            Boolean isHighRisk = false;
            Map<String, Integer> claimsPerProviderMap = new Map<String, Integer>();

            for (Employee_Claim__c ec : emp.Employee_Claims__r) {
                totalClaimsCount++;

                if (ec.Claim__r != null) {
                    Decimal payout = ec.Claim__r.Settlement_Amount__c != null ? ec.Claim__r.Settlement_Amount__c : 0.0;
                    totalPayout += payout;

                    String provider = ec.Claim__r.Insurance_Provider_Name__c;
                    if (provider != null) {
                        Integer count = claimsPerProviderMap.containsKey(provider) ? claimsPerProviderMap.get(provider) : 0;
                        claimsPerProviderMap.put(provider, count + 1);
                    }
                }
            }

            if (totalClaimsCount >= 3 || totalPayout > 100000) {
                isHighRisk = true;
            } else {
                for (String provider : claimsPerProviderMap.keySet()) {
                    if (claimsPerProviderMap.get(provider) >= 2) {
                        isHighRisk = true;
                        break;
                    }
                }
            }

            emp.Total_Claims__c = totalClaimsCount;
            emp.Total_Payout__c = totalPayout;
            emp.Risk_Level__c = isHighRisk ? 'High Risk' : 'Standard';
            
            employeesToUpdate.add(emp);
        }

        if (!employeesToUpdate.isEmpty()) {
            Database.update(employeesToUpdate, true);
        }
    }
}