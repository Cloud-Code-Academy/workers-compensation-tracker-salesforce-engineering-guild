trigger EmployeeClaimTrigger on Employee_Claim__c (before insert, after insert, after update, after delete, after undelete) {
// Create an instance of the helper class to manage the logic
    new EmployeeClaimHelper().run();
}