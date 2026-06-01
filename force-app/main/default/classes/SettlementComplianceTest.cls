/**
 * SETTLEMENT COMPLIANCE & CLAIM VALIDATION TEST CLASS
 * 
 * Unit test class for validating lifecycle processing and 
 * business rules enforced by ClaimHelper.
 */
@IsTest
private class SettlementComplianceTest {

    /*    
     * 
     * INTAKE VALIDATION TESTS (STORY #1)
     * 
     */

    @IsTest
    static void testFutureIncidentDateFails() {
        Claim__c claim = TestDataFactory.createOpenClaim();
        claim.Incident_Date__c = Date.today().addDays(1); // Future date

        Test.startTest();
        try {
            insert claim;
            System.assert(false, 'Expected validation error for future incident date.');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('Incident Date cannot be in the future'),
                'Validation message should reject future incident dates.'
            );
        }
        Test.stopTest();
    }

    /*
     * 
     * NULL SETTLEMENT AMOUNT TESTS (STORY #7)
     * 
     */

    @IsTest
    static void testSettledStatusFailsWithNullSettlementAmount() {
        Claim__c claim = TestDataFactory.createOpenClaim();
        insert claim;

        claim.Status__c = 'Settled';
        claim.Settlement_Amount__c = null;

        Test.startTest();
        try {
            update claim;
            System.assert(false, 'Expected validation error for null settlement amount');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('A claim cannot be marked Settled with a $0 or blank payout.'),
                'Validation message should match the trigger framework error.'
            );
        }
        Test.stopTest();
    }

    /*
     * 
     * ZERO SETTLEMENT AMOUNT TESTS (STORY #7)
     * 
     */

    @IsTest
    static void testSettledStatusFailsWithZeroSettlementAmount() {
        Claim__c claim = TestDataFactory.createOpenClaim();
        insert claim;

        claim.Status__c = 'Settled';
        claim.Settlement_Amount__c = 0;

        Test.startTest();
        try {
            update claim;
            System.assert(false, 'Expected validation error for zero settlement amount');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('A claim cannot be marked Settled with a $0 or blank payout.'),
                'Validation message should match the trigger framework error.'
            );
        }
        Test.stopTest();
    }

    /*
     * 
     * POSITIVE SETTLEMENT TESTS
     * 
     */

    @IsTest
    static void testSettledStatusSucceedsWithValidSettlementAmount() {
        Claim__c claim = TestDataFactory.createOpenClaim();
        insert claim;

        claim.Status__c = 'Settled';
        claim.Settlement_Amount__c = 5000;

        Test.startTest();
        update claim;
        Test.stopTest();

        Claim__c updatedClaim = [
            SELECT Status__c, Settlement_Amount__c, High_Value_Claim__c
            FROM Claim__c
            WHERE Id = :claim.Id
        ];

        System.assertEquals('Settled', updatedClaim.Status__c, 'Claim should successfully move to Settled status');
        System.assertEquals(5000, updatedClaim.Settlement_Amount__c, 'Settlement amount should save correctly');
        System.assertEquals(false, updatedClaim.High_Value_Claim__c, 'Claims under $15k should not be flagged high value.');
    }

    /*
     * NEGATIVE VALUE EDGE CASE TESTS
     * 
     */

    @IsTest
    static void testSettledStatusFailsWithNegativeSettlementAmount() {
        Claim__c claim = TestDataFactory.createOpenClaim();
        insert claim;

        claim.Status__c = 'Settled';
        claim.Settlement_Amount__c = -100;

        Test.startTest();
        try {
            update claim;
            System.assert(false, 'Expected validation error for negative settlement amount');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('A claim cannot be marked Settled with a $0 or blank payout.'),
                'Negative settlement values should trigger the zero/blank payout catch.'
            );
        }
        Test.stopTest();
    }

    /*
     * 
     * DENIED & HIGH VALUE AUTOMATION ADDITIONAL SCENARIOS
     * 
     */

    @IsTest
    static void testDeniedStatusClearsSettlementAmount() {
        Claim__c claim = TestDataFactory.createOpenClaim();
        claim.Settlement_Amount__c = 5000;
        insert claim;

        claim.Status__c = 'Denied';

        Test.startTest();
        update claim;
        Test.stopTest();

        Claim__c updatedClaim = [SELECT Settlement_Amount__c, High_Value_Claim__c FROM Claim__c WHERE Id = :claim.Id];
        System.assertEquals(0, updatedClaim.Settlement_Amount__c, 'Denied status must programmatic clear financial values to 0.');
        System.assertEquals(false, updatedClaim.High_Value_Claim__c, 'Denied status cannot be a high value claim.');
    }

    @IsTest
    static void testHighValueClaimFlagging() {
        Claim__c claim = TestDataFactory.createOpenClaim();
        claim.Status__c = 'In Review';
        claim.Settlement_Amount__c = 20000; // Greater than 15000 threshold

        Test.startTest();
        insert claim;
        Test.stopTest();

        Claim__c updatedClaim = [SELECT High_Value_Claim__c FROM Claim__c WHERE Id = :claim.Id];
        System.assertEquals(true, updatedClaim.High_Value_Claim__c, 'Claims over $15,000 must automatically flag high value.');
    }

    /*
     * 
     * BULK VALIDATION TESTS
     * 
     */

    @IsTest
    static void testBulkSettlementComplianceValidation() {
        List<Claim__c> claims = TestDataFactory.createBulkClaims(3, 1000);
        insert claims;

        claims[0].Status__c = 'Settled';
        claims[0].Settlement_Amount__c = null; // Invalid

        claims[1].Status__c = 'Settled';
        claims[1].Settlement_Amount__c = 0; // Invalid

        claims[2].Status__c = 'Settled';
        claims[2].Settlement_Amount__c = 5000; // Valid

        Test.startTest();
        Database.SaveResult[] results = Database.update(claims, false);
        Test.stopTest();

        System.assertEquals(false, results[0].isSuccess(), 'Null settlement amount should fail validation');
        System.assertEquals(false, results[1].isSuccess(), 'Zero settlement amount should fail validation');
        System.assertEquals(true, results[2].isSuccess(), 'Valid settlement amount should succeed');
    }
}