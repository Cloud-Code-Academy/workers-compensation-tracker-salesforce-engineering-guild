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
private class ClaimStatusAutomationTest {

    /*
     * =========================================================
     * TEST SETUP
     * =========================================================
     */

    @TestSetup
    static void setupData() {

        Claim__c claim =
            TestDataFactory.createOpenClaim();

        insert claim;
    }

    /*
     * =========================================================
     * STATUS TRANSITION TESTS
     * =========================================================
     */

     @IsTest
    static void testOpenToUnderReviewTransition() {

        Claim__c claim = [
            SELECT
                Id,
                Status__c
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
            'Claim should transition from Open to Under Review'
        );
    }

    /*
     * =========================================================
     * SETTLEMENT AUTOMATION TESTS
     * =========================================================
     */

     @IsTest
    static void testSettlementDateAutoPopulates() {

        Claim__c claim = [
            SELECT
                Id,
                Status__c,
                Settlement_Date__c,
                Settlement_Amount__c
            FROM Claim__c
            LIMIT 1
        ];

        claim.Status__c = 'Settled';
        claim.Settlement_Amount__c = 5000;

        Test.startTest();
        update claim;
        Test.stopTest();

        Claim__c updatedClaim = [
            SELECT
                Status__c,
                Settlement_Date__c,
                Settlement_Amount__c
            FROM Claim__c
            WHERE Id = :claim.Id
        ];

        System.assertEquals(
            'Settled',
            updatedClaim.Status__c,
            'Claim should move to Settled status'
        );

        System.assertNotEquals(
            null,
            updatedClaim.Settlement_Date__c,
            'Settlement date should auto-populate when claim is settled'
        );

        System.assertEquals(
            Date.today(),
            updatedClaim.Settlement_Date__c,
            'Settlement date should default to today'
        );
    }

    /*
     * =========================================================
     * REQUIRED FIELD VALIDATION TESTS
     * =========================================================
     */

     @IsTest
    static void testSettlementRequiresAmount() {

        Claim__c claim = [
            SELECT Id
            FROM Claim__c
            LIMIT 1
        ];

        claim.Status__c = 'Settled';
        claim.Settlement_Amount__c = null;

        Test.startTest();

        try {

            update claim;

            System.assert(
                false,
                'Expected validation error for missing settlement amount'
            );

        } catch (DmlException e) {

            System.assert(
                e.getMessage().contains('Settlement'),
                'Validation message should reference settlement requirements'
            );
        }

        Test.stopTest();
    }

    /*
     * =========================================================
     * INVALID STATUS TRANSITION TESTS
     * =========================================================
     */

     @IsTest
    static void testRejectedClaimCannotBeSettledWithoutRequirements() {

        Claim__c claim =
            TestDataFactory.createRejectedClaim();

        insert claim;

        claim.Status__c = 'Settled';

        Test.startTest();

        try {

            update claim;

            System.assert(
                false,
                'Expected validation failure when settling invalid claim'
            );

        } catch (DmlException e) {

            System.assert(
                e.getMessage().contains('Settlement'),
                'Validation should enforce settlement requirements'
            );
        }

        Test.stopTest();
    }

    /*
     * =========================================================
     * STATUS REVERSAL TESTS
     * =========================================================
     */

     @IsTest
    static void testSettledClaimRetainsSettlementDate() {

        Claim__c claim =
            TestDataFactory.createSettledClaim();

        insert claim;

        Date originalSettlementDate =
            claim.Settlement_Date__c;

        claim.Status__c = 'Under Review';

        Test.startTest();
        update claim;
        Test.stopTest();

        Claim__c updatedClaim = [
            SELECT
                Status__c,
                Settlement_Date__c
            FROM Claim__c
            WHERE Id = :claim.Id
        ];

        System.assertEquals(
            'Under Review',
            updatedClaim.Status__c,
            'Claim should move back to Under Review'
        );

        System.assertEquals(
            originalSettlementDate,
            updatedClaim.Settlement_Date__c,
            'Settlement date should remain historically preserved'
        );
    }

    /*
     * =========================================================
     * BULK STATUS AUTOMATION TESTS
     * =========================================================
     */

     @IsTest
    static void testBulkClaimSettlementAutomation() {

        List<Claim__c> claims =
            TestDataFactory.createBulkClaims(5, 1000);

        insert claims;

        for (Claim__c c : claims) {

            c.Status__c = 'Settled';
            c.Settlement_Amount__c = 2500;
        }

        Test.startTest();
        update claims;
        Test.stopTest();

        List<Claim__c> updatedClaims = [
            SELECT
                Status__c,
                Settlement_Date__c,
                Settlement_Amount__c
            FROM Claim__c
            WHERE Id IN :claims
        ];

        for (Claim__c c : updatedClaims) {

            System.assertEquals(
                'Settled',
                c.Status__c,
                'All claims should be settled'
            );

            System.assertNotEquals(
                null,
                c.Settlement_Date__c,
                'Settlement dates should auto-populate in bulk operations'
            );

            System.assertEquals(
                2500,
                c.Settlement_Amount__c,
                'Settlement amounts should update correctly'
            );
        }
    }

    /*
     * =========================================================
     * UNDER REVIEW VALIDATION TESTS
     * =========================================================
     */

     @IsTest
    static void testUnderReviewClaimDoesNotPopulateSettlementDate() {

        Claim__c claim =
            TestDataFactory.createOpenClaim();

        insert claim;

        claim.Status__c = 'Under Review';

        Test.startTest();
        update claim;
        Test.stopTest();

        Claim__c updatedClaim = [
            SELECT
                Status__c,
                Settlement_Date__c
            FROM Claim__c
            WHERE Id = :claim.Id
        ];

        System.assertEquals(
            'Under Review',
            updatedClaim.Status__c,
            'Claim should transition to Under Review'
        );

        System.assertEquals(
            null,
            updatedClaim.Settlement_Date__c,
            'Settlement date should remain blank until claim is settled'
        );
    }
}