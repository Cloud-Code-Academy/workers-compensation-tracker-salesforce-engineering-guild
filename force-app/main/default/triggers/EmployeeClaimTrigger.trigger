trigger EmployeeClaimTrigger on Employee_Claim__c (after insert, after update, after delete, after undelete) {
// Create an instance of the helper class to manage the logic
    new EmployeeClaimHelper().run();
}