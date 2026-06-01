/**
 * =========================================================
 * CLAIM STATUS AUTOMATION TEST CLASS
 * =========================================================
 *
 * Unit test class for validating automated claim status
 * behavior, settlement processing rules, and lifecycle
 * validation logic for Claim__c records.
 *
 * This class verifies:
 *
 * - status transitions
 * - settlement automation
 * - required settlement validations
 * - historical data preservation
 * - invalid lifecycle transitions
 * - bulk automation behavior
 *
 * ---------------------------------------------------------
 * BUSINESS PURPOSE
 * ---------------------------------------------------------
 *
 * Claims progress through a controlled lifecycle during
 * investigation and resolution.
 *
 * Typical lifecycle flow:
 *
 *     Open
 *         ↓
 *     In Review
 *         ↓
 *     Settled / Rejected
 *
 * Status transitions may trigger:
 *
 * - automatic field population
 * - financial validations
 * - settlement tracking
 * - reporting updates
 * - audit history preservation
 *
 * This test class ensures lifecycle automation behaves
 * consistently and preserves data integrity.
 *
 * ---------------------------------------------------------
 * AUTOMATION RULES BEING TESTED
 * ---------------------------------------------------------
 *
 * SETTLED CLAIM RULES
 * - Settlement_Date__c auto-populates
 * - Settlement_Amount__c is required
 * - settlement values persist correctly
 *
 * In Review RULES
 * - no settlement date should populate
 *
 * REJECTED CLAIM RULES
 * - rejected claims cannot bypass settlement requirements
 *
 * HISTORICAL DATA RULES
 * - settlement dates remain preserved even if
 *   status changes later
 *
 * ---------------------------------------------------------
 * TEST COVERAGE AREAS
 * ---------------------------------------------------------
 *
 * This class validates:
 *
 * ✔ Open → In Review transitions
 * ✔ Settlement date auto-population
 * ✔ Settlement amount validation
 * ✔ Invalid settlement transitions
 * ✔ Historical settlement preservation
 * ✔ Bulk settlement automation
 * ✔ Non-settled status behavior
 *
 * ---------------------------------------------------------
 * TEST SETUP STRATEGY
 * ---------------------------------------------------------
 *
 * Shared test data is created using @TestSetup.
 *
 * Setup creates:
 *
 * - one open Claim__c record
 *
 * Benefits include:
 *
 * - reduced duplicate setup logic
 * - faster execution
 * - cleaner test methods
 * - reusable baseline data
 *
 * ---------------------------------------------------------
 * SETTLEMENT AUTOMATION BEHAVIOR
 * ---------------------------------------------------------
 *
 * When a claim becomes:
 *
 *     Status__c = 'Settled'
 *
 * automation is expected to:
 *
 * - populate Settlement_Date__c
 * - validate Settlement_Amount__c
 * - preserve settlement history
 *
 * ---------------------------------------------------------
 * BULKIFICATION VALIDATION
 * ---------------------------------------------------------
 *
 * Bulk tests ensure automation:
 *
 * - processes many records safely
 * - avoids SOQL-in-loop violations
 * - avoids DML-in-loop violations
 * - scales within governor limits
 *
 * ---------------------------------------------------------
 * TESTING STRATEGY
 * ---------------------------------------------------------
 *
 * This class follows Apex testing best practices:
 *
 * - isolated test methods
 * - reusable TestDataFactory helpers
 * - positive and negative test coverage
 * - edge-case validation
 * - bulk processing validation
 * - lifecycle integrity testing
 *
 * ---------------------------------------------------------
 * DEPENDENCIES
 * ---------------------------------------------------------
 *
 * This class depends on:
 *
 * - Claim__c object
 * - claim status automation
 * - validation rules/triggers
 * - settlement automation logic
 * - TestDataFactory helper methods
 *
 * ---------------------------------------------------------
 * EXPECTED AUTOMATION BEHAVIOR
 * ---------------------------------------------------------
 *
 * The tested automation is expected to:
 *
 * - enforce lifecycle rules
 * - populate settlement fields automatically
 * - validate settlement requirements
 * - preserve historical data
 * - support bulk operations safely
 *
 * ---------------------------------------------------------
 * NOTES
 * ---------------------------------------------------------
 *
 * - This class uses @IsTest and does not count toward
 *   Apex storage limits.
 *
 * - Tests run in isolated execution contexts and do not
 *   access production data.
 *
 * - Assertions validate both business correctness and
 *   data integrity.
 *
 * =========================================================
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

        claim.Status__c = 'In Review';

        Test.startTest();
        update claim;
        Test.stopTest();

        Claim__c updatedClaim = [
            SELECT Status__c
            FROM Claim__c
            WHERE Id = :claim.Id
        ];

        System.assertEquals(
            'In Review',
            updatedClaim.Status__c,
            'Claim should transition from Open to In Review'
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

        claim.Status__c = 'In Review';

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
            'In Review',
            updatedClaim.Status__c,
            'Claim should move back to In Review'
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
     * In Review VALIDATION TESTS
     * =========================================================
     */

     @IsTest
    static void testUnderReviewClaimDoesNotPopulateSettlementDate() {

        Claim__c claim =
            TestDataFactory.createOpenClaim();

        insert claim;

        claim.Status__c = 'In Review';

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
            'In Review',
            updatedClaim.Status__c,
            'Claim should transition to In Review'
        );

        System.assertEquals(
            null,
            updatedClaim.Settlement_Date__c,
            'Settlement date should remain blank until claim is settled'
        );
    }
}
