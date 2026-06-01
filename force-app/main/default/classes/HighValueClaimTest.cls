/**
 * =========================================================
 * HIGH VALUE CLAIM TEST CLASS
 * =========================================================
 *
 * Unit test class for validating high-value claim automation,
 * threshold evaluation logic, and automatic claim flagging.
 *
 * This class verifies automatic updates to:
 *
 * - High_Value_Claim__c
 *
 * based on Settlement_Amount__c values associated with claims.
 *
 * ---------------------------------------------------------
 * BUSINESS PURPOSE
 * ---------------------------------------------------------
 *
 * High-value insurance claims may represent increased:
 *
 * - financial exposure
 * - fraud risk
 * - compliance concerns
 * - operational escalation requirements
 *
 * The system automatically flags claims that exceed
 * predefined payout thresholds to support:
 *
 * - auditing
 * - financial reporting
 * - risk management
 * - investigation workflows
 * - management visibility
 *
 * ---------------------------------------------------------
 * HIGH VALUE THRESHOLD RULES
 * ---------------------------------------------------------
 *
 * A claim is automatically flagged when:
 *
 *     Settlement_Amount__c >= 5000
 *
 * In this scenario:
 *
 *     High_Value_Claim__c = true
 *
 * Claims below the threshold should remain unflagged.
 *
 * ---------------------------------------------------------
 * TEST COVERAGE AREAS
 * ---------------------------------------------------------
 *
 * This class validates:
 *
 * ✔ High-value flagging during insert
 * ✔ Non-high-value claim behavior
 * ✔ Exact threshold edge cases
 * ✔ Below-threshold edge cases
 * ✔ Flag recalculation during updates
 * ✔ Automatic flag removal
 * ✔ Null payout handling
 * ✔ Bulk claim flagging
 *
 * ---------------------------------------------------------
 * INSERT AUTOMATION TESTING
 * ---------------------------------------------------------
 *
 * When claims are inserted:
 *
 * - settlement amounts should evaluate automatically
 * - qualifying claims should be flagged
 * - non-qualifying claims should remain unflagged
 *
 * ---------------------------------------------------------
 * EXACT THRESHOLD TESTING
 * ---------------------------------------------------------
 *
 * Claims matching the threshold exactly:
 *
 *     Settlement_Amount__c = 5000
 *
 * should still be classified as High Value.
 *
 * These tests validate:
 *
 * - inclusive threshold logic
 * - boundary-condition correctness
 *
 * ---------------------------------------------------------
 * BELOW THRESHOLD EDGE CASE TESTING
 * ---------------------------------------------------------
 *
 * Claims just below the threshold:
 *
 *     Settlement_Amount__c < 5000
 *
 * should NOT be flagged.
 *
 * These tests validate:
 *
 * - proper comparison logic
 * - false-positive prevention
 *
 * ---------------------------------------------------------
 * UPDATE AUTOMATION TESTING
 * ---------------------------------------------------------
 *
 * Claims may become High Value after updates.
 *
 * These tests validate:
 *
 * - automatic reevaluation after payout increases
 * - dynamic flag recalculation
 * - trigger responsiveness
 *
 * ---------------------------------------------------------
 * FLAG REMOVAL TESTING
 * ---------------------------------------------------------
 *
 * Claims should automatically lose the High Value flag
 * when payout amounts fall below the threshold.
 *
 * These tests validate:
 *
 * - automatic flag removal
 * - recalculation integrity
 * - data consistency
 *
 * ---------------------------------------------------------
 * NULL VALUE EDGE CASE TESTING
 * ---------------------------------------------------------
 *
 * Claims with:
 *
 *     Settlement_Amount__c = null
 *
 * should never be flagged as High Value.
 *
 * These tests validate:
 *
 * - null-safe automation
 * - defensive logic handling
 * - prevention of incorrect classifications
 *
 * ---------------------------------------------------------
 * BULKIFICATION VALIDATION
 * ---------------------------------------------------------
 *
 * Bulk tests ensure automation:
 *
 * - processes multiple claims correctly
 * - evaluates thresholds consistently
 * - avoids SOQL-in-loop violations
 * - avoids DML-in-loop violations
 * - remains governor-limit safe
 *
 * ---------------------------------------------------------
 * TESTING STRATEGY
 * ---------------------------------------------------------
 *
 * This class follows Apex testing best practices:
 *
 * - isolated test methods
 * - reusable TestDataFactory helpers
 * - positive and negative testing
 * - edge-case validation
 * - threshold-boundary testing
 * - bulk-processing validation
 *
 * ---------------------------------------------------------
 * DEPENDENCIES
 * ---------------------------------------------------------
 *
 * This class depends on:
 *
 * - Claim__c object
 * - high-value claim automation logic
 * - settlement amount evaluation logic
 * - TestDataFactory helper methods
 *
 * ---------------------------------------------------------
 * EXPECTED AUTOMATION BEHAVIOR
 * ---------------------------------------------------------
 *
 * The tested automation is expected to:
 *
 * - evaluate claim payout amounts automatically
 * - flag qualifying claims correctly
 * - remove flags when thresholds are no longer met
 * - handle null values safely
 * - support bulk operations correctly
 * - maintain data consistency
 *
 * ---------------------------------------------------------
 * NOTES
 * ---------------------------------------------------------
 *
 * - This class uses @IsTest and does not count against
 *   Apex organization storage limits.
 *
 * - Tests execute in isolated transactions and do not
 *   access production data.
 *
 * - Assertions validate both business correctness and
 *   automation integrity.
 *
 * =========================================================
 */
@IsTest
private class HighValueClaimTest {

    /*
     * =========================================================
     * POSITIVE HIGH VALUE TESTS
     * =========================================================
     */

    @IsTest
    static void testHighValueClaimFlaggedOnInsert() {

        Claim__c claim =
            TestDataFactory.createHighValueClaim();

        Test.startTest();
        insert claim;
        Test.stopTest();

        Claim__c insertedClaim = [
            SELECT
                Settlement_Amount__c,
                High_Value_Claim__c
            FROM Claim__c
            WHERE Id = :claim.Id
        ];

        System.assertEquals(
            10000,
            insertedClaim.Settlement_Amount__c,
            'Claim should retain settlement amount'
        );

        System.assertEquals(
            true,
            insertedClaim.High_Value_Claim__c,
            'High-value claim should be flagged automatically'
        );
    }

    /*
     * =========================================================
     * NEGATIVE THRESHOLD TESTS
     * =========================================================
     */

    @IsTest
    static void testLowValueClaimNotFlagged() {

        Claim__c claim =
            TestDataFactory.createLowRiskClaim();

        Test.startTest();
        insert claim;
        Test.stopTest();

        Claim__c insertedClaim = [
            SELECT
                Settlement_Amount__c,
                High_Value_Claim__c
            FROM Claim__c
            WHERE Id = :claim.Id
        ];

        System.assertEquals(
            500,
            insertedClaim.Settlement_Amount__c,
            'Claim should retain low settlement amount'
        );

        System.assertEquals(
            false,
            insertedClaim.High_Value_Claim__c,
            'Low-value claims should not be flagged'
        );
    }

    /*
     * =========================================================
     * EXACT THRESHOLD TESTS
     * =========================================================
     */

    @IsTest
    static void testExactThresholdClaimFlagging() {

        Claim__c claim =
            TestDataFactory.createClaim(
                'Open',
                5000
            );

        Test.startTest();
        insert claim;
        Test.stopTest();

        Claim__c insertedClaim = [
            SELECT
                Settlement_Amount__c,
                High_Value_Claim__c
            FROM Claim__c
            WHERE Id = :claim.Id
        ];

        System.assertEquals(
            5000,
            insertedClaim.Settlement_Amount__c,
            'Claim should equal exact threshold amount'
        );

        System.assertEquals(
            true,
            insertedClaim.High_Value_Claim__c,
            'Claims meeting threshold should be flagged'
        );
    }

    /*
     * =========================================================
     * BELOW THRESHOLD EDGE CASE
     * =========================================================
     */

    @IsTest
    static void testBelowThresholdClaimNotFlagged() {

        Claim__c claim =
            TestDataFactory.createClaim(
                'Open',
                4999
            );

        Test.startTest();
        insert claim;
        Test.stopTest();

        Claim__c insertedClaim = [
            SELECT
                Settlement_Amount__c,
                High_Value_Claim__c
            FROM Claim__c
            WHERE Id = :claim.Id
        ];

        System.assertEquals(
            4999,
            insertedClaim.Settlement_Amount__c,
            'Claim should remain below threshold'
        );

        System.assertEquals(
            false,
            insertedClaim.High_Value_Claim__c,
            'Claims below threshold should not be flagged'
        );
    }

    /*
     * =========================================================
     * UPDATE FLAGGING TESTS
     * =========================================================
     */

     @IsTest
    static void testClaimBecomesHighValueAfterUpdate() {

        Claim__c claim =
            TestDataFactory.createLowRiskClaim();

        insert claim;

        claim.Settlement_Amount__c = 12000;

        Test.startTest();
        update claim;
        Test.stopTest();

        Claim__c updatedClaim = [
            SELECT
                Settlement_Amount__c,
                High_Value_Claim__c
            FROM Claim__c
            WHERE Id = :claim.Id
        ];

        System.assertEquals(
            12000,
            updatedClaim.Settlement_Amount__c,
            'Settlement amount should update correctly'
        );

        System.assertEquals(
            true,
            updatedClaim.High_Value_Claim__c,
            'Claim should become flagged after threshold increase'
        );
    }

    /*
     * =========================================================
     * FLAG REMOVAL TESTS
     * =========================================================
     */

     @IsTest
    static void testClaimLosesHighValueFlagAfterReduction() {

        Claim__c claim =
            TestDataFactory.createHighValueClaim();

        insert claim;

        claim.Settlement_Amount__c = 1000;

        Test.startTest();
        update claim;
        Test.stopTest();

        Claim__c updatedClaim = [
            SELECT
                Settlement_Amount__c,
                High_Value_Claim__c
            FROM Claim__c
            WHERE Id = :claim.Id
        ];

        System.assertEquals(
            1000,
            updatedClaim.Settlement_Amount__c,
            'Settlement amount should reduce correctly'
        );

        System.assertEquals(
            false,
            updatedClaim.High_Value_Claim__c,
            'Claim should lose high-value flag after reduction'
        );
    }

    /*
     * =========================================================
     * NULL VALUE EDGE CASES
     * =========================================================
     */

     @IsTest
    static void testNullSettlementAmountNotFlagged() {

        Claim__c claim =
            TestDataFactory.createClaimWithNullPayout();

        Test.startTest();
        insert claim;
        Test.stopTest();

        Claim__c insertedClaim = [
            SELECT
                Settlement_Amount__c,
                High_Value_Claim__c
            FROM Claim__c
            WHERE Id = :claim.Id
        ];

        System.assertEquals(
            null,
            insertedClaim.Settlement_Amount__c,
            'Settlement amount should remain null'
        );

        System.assertEquals(
            false,
            insertedClaim.High_Value_Claim__c,
            'Null payouts should never be flagged as high value'
        );
    }

    /*
     * =========================================================
     * BULK FLAGGING TESTS
     * =========================================================
     */

     @IsTest
    static void testBulkHighValueFlagging() {

        List<Claim__c> claims = new List<Claim__c>{

            TestDataFactory.createClaim(
                'Open',
                1000
            ),

            TestDataFactory.createClaim(
                'Open',
                5000
            ),

            TestDataFactory.createClaim(
                'Open',
                15000
            ),

            TestDataFactory.createClaim(
                'Open',
                3000
            )

        };

        Test.startTest();
        insert claims;
        Test.stopTest();

        List<Claim__c> insertedClaims = [
            SELECT
                Settlement_Amount__c,
                High_Value_Claim__c
            FROM Claim__c
            WHERE Id IN :claims
            ORDER BY Settlement_Amount__c ASC
        ];

        for (Claim__c c : insertedClaims) {

            if (c.Settlement_Amount__c >= 5000) {

                System.assertEquals(
                    true,
                    c.High_Value_Claim__c,
                    'Claims at or above threshold should be flagged'
                );

            } else {

                System.assertEquals(
                    false,
                    c.High_Value_Claim__c,
                    'Claims below threshold should not be flagged'
                );
            }
        }
    }
}
