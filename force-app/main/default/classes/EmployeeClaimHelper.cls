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

    private void executeAfterLogic(){
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
            WITH USER_MODE
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

    private void recalculateEmployeeMetricsAndRisk(Set<Id> employeeIds){
    /* SCRUM-9 Automation Risk Scoring
     * Complies claims metrics, map logic for evaluating risk and safely handle DML updates
    */
        List <Employee__c> employeesToUpdate = new List<Employee__c>();

        //Query all related junction records and parent Claims
        Map<Id, Employee__c> employeesWithClaimsMap = new Map<Id, Employee__c>([
            SELECT Id, Name,(
                SELECT Id, Claim__c, Claim__r.Settlement_Amount__c, Claim__r.Insurance_Provider_Name__c, Claim__r.Status__c
                FROM Employee_Claims__r
            )
            FROM Employee__c
            WHERE Id IN :employeeIds
            WITH USER_MODE
        ]);

        for (Id empId : employeeIds){
            Employee__c emp = employeesWithClaimsMap.get(empId);
            if(emp == null){
                continue;
            }

            Integer totalClaimsCount = 0;
            Decimal totalPayout = 0.0;
            Boolean isHighRisk = false;

            //Track claims per Insurance Provider
            Map<Id, Integer> claimsPerProviderMap = new Map<Id, Integer>();
            for (Employee_Claim__c ec : emp.Employee_Claims__r){
                totalClaimsCount ++;

                if(ec.Claim__c != null){
                    Decimal payout = ec.Claim__r.Settlement_Amount__c != null ? ec.Claim__r.Settlement_Amount__c : 0.0;
                    //Increment overall settled payouts
                    if (ec.Claim__r.Status__c == 'Settled'){
                        totalPayout += payout;
                    }
                    //Group claims data by Insurance Provider using AccountId
                    Id providerId = ec.Claim__r.Insurance_Provider_Name__c;
                    if (providerId != null){
                        Integer currentCount = claimsPerProviderMap.containsKey(providerId) ? claimsPerProviderMap.get(providerId) : 0;
                        claimsPerProviderMap.put(providerId, currentCount + 1);
                    }
                    if (payout > 10000.0){
                        isHighRisk = true;
                    }
                }
            }
            //Evaluate whether High Risk if 3+ claims exist against any single Ins Provider
            for (Id providerId : claimsPerProviderMap.keySet()){
                if(claimsPerProviderMap.get(providerId) >3){
                    isHighRisk = true;
                    break;
                }
            }
        //Map calculated values back onto the custom Employee fields
        emp.Total_Claims__c = totalClaimsCount;
        emp.Total_Payout__c = totalPayout;
        emp.Risk_Level__c   = isHighRisk ? 'High Risk' : 'Standard';
        employeesToUpdate.add(emp);
        }
        //final check and commit
        if(!employeesToUpdate.isEmpty()){
            Database.update(employeesToUpdate,true);
        }
    }
}