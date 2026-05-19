/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@IsTest
private class ClaimLifecycleTest {

    /*
     * =========================================================
     * TEST SETUP
     * =========================================================
     */

    @TestSetup
    static void setupData() {

        Employee__c emp = TestDataFactory.createEmployee();
        insert emp;

        Claim__c claim = TestDataFactory.createOpenClaim();
        insert claim;

        Employee_Claim__c junction =
            TestDataFactory.createEmployeeClaim(emp.Id, claim.Id);

        insert junction;
    }

    /*
     * =========================================================
     * OPEN -> UNDER REVIEW
     * =========================================================
     */

     @IsTest
    static void testClaimMovesToUnderReview() {

        Claim__c claim = [
            SELECT Id, Status__c
            FROM Claim__c
            LIMIT 1
        ];

        claim.Status__c = 'Under Review';

        Test.startTest();
        update claim;
        Test.stopTest();

        Claim__c updatedClaim = [
            SELECT Status__c
            FROM Claim__c
            WHERE Id = :claim.Id
        ];

        System.assertEquals(
            'Under Review',
            updatedClaim.Status__c,
            'Claim should transition to Under Review'
        );
    }

    /*
     * =========================================================
     * UNDER REVIEW -> SETTLED
     * =========================================================
     */

     @IsTest
    static void testClaimSettlementLifecycle() {

        Claim__c claim = [
            SELECT Id, Status__c, Settlement_Amount__c, Settlement_Date__c
            FROM Claim__c
            LIMIT 1
        ];

        claim.Status__c = 'Settled';
        claim.Settlement_Amount__c = 7500;
        claim.Settlement_Date__c = Date.today();

        Test.startTest();
        update claim;
        Test.stopTest();

        Claim__c updatedClaim = [
            SELECT
                Status__c,
                Settlement_Amount__c,
                Settlement_Date__c
            FROM Claim__c
            WHERE Id = :claim.Id
        ];

        System.assertEquals(
            'Settled',
            updatedClaim.Status__c,
            'Claim should move to Settled status'
        );

        System.assertEquals(
            7500,
            updatedClaim.Settlement_Amount__c,
            'Settlement amount should update correctly'
        );

        System.assertEquals(
            Date.today(),
            updatedClaim.Settlement_Date__c,
            'Settlement date should be populated'
        );
    }

    /*
     * =========================================================
     * FINANCIAL ROLLUP VALIDATION
     * =========================================================
     */

     @IsTest
    static void testEmployeeFinancialTotalsUpdate() {

        Employee__c emp = [
            SELECT Id
            FROM Employee__c
            LIMIT 1
        ];

        Claim__c claim = [
            SELECT Id, Settlement_Amount__c
            FROM Claim__c
            LIMIT 1
        ];

        claim.Status__c = 'Settled';
        claim.Settlement_Amount__c = 10000;
        claim.Settlement_Date__c = Date.today();

        Test.startTest();
        update claim;
        Test.stopTest();

        Employee__c updatedEmp = [
            SELECT Total_Claims__c, Total_Payout__c
            FROM Employee__c
            WHERE Id = :emp.Id
        ];

        System.assertEquals(
            1,
            updatedEmp.Total_Claims__c,
            'Employee should still have 1 claim'
        );

        System.assertEquals(
            10000,
            updatedEmp.Total_Payout__c,
            'Employee payout total should reflect settlement amount'
        );
    }

    /*
     * =========================================================
     * REJECTED CLAIM TEST
     * =========================================================
     */

     @IsTest
    static void testRejectedClaimBehavior() {

        Claim__c claim = [
            SELECT Id
            FROM Claim__c
            LIMIT 1
        ];

        claim.Status__c = 'Rejected';
        claim.Settlement_Amount__c = 0;
        claim.Settlement_Date__c = null;

        Test.startTest();
        update claim;
        Test.stopTest();

        Claim__c updatedClaim = [
            SELECT
                Status__c,
                Settlement_Amount__c,
                Settlement_Date__c
            FROM Claim__c
            WHERE Id = :claim.Id
        ];

        System.assertEquals(
            'Rejected',
            updatedClaim.Status__c,
            'Claim should move to Rejected status'
        );

        System.assertEquals(
            0,
            updatedClaim.Settlement_Amount__c,
            'Rejected claims should not have settlement payouts'
        );

        System.assertEquals(
            null,
            updatedClaim.Settlement_Date__c,
            'Rejected claims should not have settlement dates'
        );
    }

    /*
     * =========================================================
     * BULK CLAIM LIFECYCLE TEST
     * =========================================================
     */

     @IsTest
    static void testBulkClaimSettlementUpdates() {

        List<Claim__c> claims =
            TestDataFactory.createBulkClaims(5, 1000);

        insert claims;

        for (Claim__c c : claims) {
            c.Status__c = 'Settled';
            c.Settlement_Amount__c = 5000;
            c.Settlement_Date__c = Date.today();
        }

        Test.startTest();
        update claims;
        Test.stopTest();

        List<Claim__c> updatedClaims = [
            SELECT
                Status__c,
                Settlement_Amount__c,
                Settlement_Date__c
            FROM Claim__c
            WHERE Id IN :claims
        ];

        for (Claim__c c : updatedClaims) {

            System.assertEquals(
                'Settled',
                c.Status__c,
                'All claims should be settled'
            );

            System.assertEquals(
                5000,
                c.Settlement_Amount__c,
                'Settlement amount should update correctly'
            );

            System.assertEquals(
                Date.today(),
                c.Settlement_Date__c,
                'Settlement date should be populated'
            );
        }
    }
}