trigger ClaimTrigger on Claim__c (before insert, before update) {
	// Create an instance of the helper class to manage the logic
	new ClaimHelper().run();
}