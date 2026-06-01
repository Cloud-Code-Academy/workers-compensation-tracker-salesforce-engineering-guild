/**
 * =========================================================
 * CLAIM DURATION TEST CLASS
 * =========================================================
 *
 * Unit test class for validating claim duration calculation
 * behavior on the Claim__c object.
 *
 * This test suite verifies that automation correctly calculates:
 *
 * - Days_Open__c for active claims
 * - Days_Open__c for settled claims
 * - Duration recalculation during updates
 * - Bulk duration processing
 * - Date validation rules
 * - Edge-case settlement scenarios
 *
 * ---------------------------------------------------------
 * BUSINESS PURPOSE
 * ---------------------------------------------------------
 *
 * Claims often require duration tracking to support:
 *
 * - SLA monitoring
 * - operational reporting
 * - compliance metrics
 * - claim aging dashboards
 * - employee risk analysis
 * - escalation workflows
 *
 * The Days_Open__c field represents the total number
 * of days a claim remained open.
 *
 * ---------------------------------------------------------
 * EXPECTED DURATION LOGIC
 * ---------------------------------------------------------
 *
 * OPEN CLAIMS:
 *
 *     Days_Open__c =
 *         TODAY - Incident_Date__c
 *
 * SETTLED CLAIMS:
 *
 *     Days_Open__c =
 *         Settlement_Date__c - Incident_Date__c
 *
 * SAME-DAY SETTLEMENT:
 *
 *     Days_Open__c = 0
 *
 * INVALID DATE RULE:
 *
 *     Settlement_Date__c
 *         cannot occur before
 *     Incident_Date__c
 *
 * ---------------------------------------------------------
 * TEST COVERAGE AREAS
 * ---------------------------------------------------------
 *
 * This class validates:
 *
 * ✔ Open claim duration calculations
 * ✔ Settled claim duration calculations
 * ✔ Duration recalculation after updates
 * ✔ Real-time active duration tracking
 * ✔ Invalid settlement date validation
 * ✔ Same-day settlement edge cases
 * ✔ Bulk duration processing behavior
 *
 * ---------------------------------------------------------
 * BULKIFICATION VALIDATION
 * ---------------------------------------------------------
 *
 * Bulk tests ensure automation:
 *
 * - handles multiple records correctly
 * - avoids SOQL-in-loop violations
 * - avoids DML-in-loop violations
 * - scales safely within governor limits
 *
 * ---------------------------------------------------------
 * TESTING STRATEGY
 * ---------------------------------------------------------
 *
 * This class follows Apex testing best practices:
 *
 * - Uses isolated test methods
 * - Uses Test.startTest()/stopTest()
 * - Uses reusable TestDataFactory helpers
 * - Separates positive and negative test paths
 * - Validates both insert and update behavior
 * - Includes edge-case coverage
 *
 * ---------------------------------------------------------
 * DEPENDENCIES
 * ---------------------------------------------------------
 *
 * This test class depends on:
 *
 * - Claim__c object
 * - Claim trigger automation
 * - Duration calculation logic
 * - Validation logic
 * - TestDataFactory helper methods
 *
 * ---------------------------------------------------------
 * EXPECTED AUTOMATION BEHAVIOR
 * ---------------------------------------------------------
 *
 * The tested automation is expected to:
 *
 * - calculate durations automatically
 * - update durations during status changes
 * - prevent invalid settlement sequences
 * - support bulk processing safely
 *
 * ---------------------------------------------------------
 * NOTES
 * ---------------------------------------------------------
 *
 * - This class uses @IsTest and does not count toward
 *   Apex storage limits.
 *
 * - No production data is accessed because tests run
 *   in isolated execution contexts.
 *
 * - Assertions verify both business correctness and
 *   data integrity.
 *
 * =========================================================
 */
@IsTest
private class ClaimDurationTest {

    /*
     * =========================================================
     * ACTIVE CLAIM DURATION TESTS
     * =========================================================
     */

    @IsTest 
    static void testOpenClaimDurationCalculation() {

        Claim__c claim = TestDataFactory.createOpenClaim();

        claim.Incident_Date__c = Date.today().addDays(-10);

        Test.startTest();
        insert claim;
        Test.stopTest();

        Claim__c insertedClaim = [
            SELECT
                Incident_Date__c,
                Days_Open__c,
                Status__c
            FROM Claim__c
            WHERE Id = :claim.Id
        ];

        System.assertEquals(
            'Open',
            insertedClaim.Status__c,
            'Claim should remain open'
        );

        System.assertEquals(
            10,
            insertedClaim.Days_Open__c,
            'Days open should equal 10 days'
        );
    }

    /*
     * =========================================================
     * SETTLED CLAIM DURATION TESTS
     * =========================================================
     */

     @IsTest
    static void testSettledClaimDurationCalculation() {

        Claim__c claim = TestDataFactory.createSettledClaim();

        claim.Incident_Date__c = Date.today().addDays(-30);
        claim.Settlement_Date__c = Date.today().addDays(-5);

        Test.startTest();
        insert claim;
        Test.stopTest();

        Claim__c insertedClaim = [
            SELECT
                Incident_Date__c,
                Settlement_Date__c,
                Days_Open__c,
                Status__c
            FROM Claim__c
            WHERE Id = :claim.Id
        ];

        System.assertEquals(
            'Settled',
            insertedClaim.Status__c,
            'Claim should be settled'
        );

        System.assertEquals(
            25,
            insertedClaim.Days_Open__c,
            'Days open should equal difference between incident and settlement dates'
        );
    }

    /*
     * =========================================================
     * DURATION UPDATE TESTS
     * =========================================================
     */

     @IsTest
    static void testDurationUpdatesWhenClaimSettles() {

        Claim__c claim = TestDataFactory.createOpenClaim();

        claim.Incident_Date__c = Date.today().addDays(-20);

        insert claim;

        claim.Status__c = 'Settled';
        claim.Settlement_Date__c = Date.today();

        Test.startTest();
        update claim;
        Test.stopTest();

        Claim__c updatedClaim = [
            SELECT
                Status__c,
                Days_Open__c,
                Settlement_Date__c
            FROM Claim__c
            WHERE Id = :claim.Id
        ];

        System.assertEquals(
            'Settled',
            updatedClaim.Status__c,
            'Claim should transition to settled'
        );

        System.assertEquals(
            20,
            updatedClaim.Days_Open__c,
            'Duration should recalculate upon settlement'
        );
    }

    /*
     * =========================================================
     * ACTIVE CLAIM REAL-TIME DURATION TEST
     * =========================================================
     */

     @IsTest
    static void testActiveClaimTracksCurrentDuration() {

        Claim__c claim = TestDataFactory.createOpenClaim();

        claim.Incident_Date__c = Date.today().addDays(-45);

        Test.startTest();
        insert claim;
        Test.stopTest();

        Claim__c insertedClaim = [
            SELECT
                Days_Open__c,
                Status__c
            FROM Claim__c
            WHERE Id = :claim.Id
        ];

        System.assertEquals(
            'Open',
            insertedClaim.Status__c,
            'Claim should still be open'
        );

        System.assertEquals(
            45,
            insertedClaim.Days_Open__c,
            'Open claims should calculate duration through today'
        );
    }

    /*
     * =========================================================
     * INVALID DATE SEQUENCE TESTS
     * =========================================================
     */

     @IsTest
    static void testSettlementDateBeforeIncidentDate() {

        Claim__c claim = TestDataFactory.createSettledClaim();

        claim.Incident_Date__c = Date.today();
        claim.Settlement_Date__c = Date.today().addDays(-5);

        Test.startTest();

        try {

            insert claim;

            System.assert(
                false,
                'Expected validation exception for invalid date sequence'
            );

        } catch (DmlException e) {

            System.assert(
                e.getMessage().contains('Settlement'),
                'Validation error should reference settlement date sequencing'
            );
        }

        Test.stopTest();
    }

    /*
     * =========================================================
     * SAME-DAY SETTLEMENT EDGE CASE
     * =========================================================
     */

     @IsTest
    static void testSameDaySettlementDuration() {

        Claim__c claim = TestDataFactory.createSettledClaim();

        claim.Incident_Date__c = Date.today();
        claim.Settlement_Date__c = Date.today();

        Test.startTest();
        insert claim;
        Test.stopTest();

        Claim__c insertedClaim = [
            SELECT Days_Open__c
            FROM Claim__c
            WHERE Id = :claim.Id
        ];

        System.assertEquals(
            0,
            insertedClaim.Days_Open__c,
            'Same-day settlements should have 0 days open'
        );
    }

    /*
     * =========================================================
     * BULK DURATION TESTS
     * =========================================================
     */

     @IsTest
    static void testBulkClaimDurationCalculations() {

        List<Claim__c> claims = new List<Claim__c>();

        for (Integer i = 1; i <= 5; i++) {

            Claim__c claim = TestDataFactory.createOpenClaim();

            claim.Incident_Date__c = Date.today().addDays(-i * 5);

            claims.add(claim);
        }

        Test.startTest();
        insert claims;
        Test.stopTest();

        List<Claim__c> insertedClaims = [
            SELECT Days_Open__c
            FROM Claim__c
            WHERE Id IN :claims
            ORDER BY Days_Open__c ASC
        ];

        Integer expectedDays = 5;

        for (Claim__c c : insertedClaims) {

            System.assertEquals(
                expectedDays,
                c.Days_Open__c,
                'Bulk duration calculations should remain accurate'
            );

            expectedDays += 5;
        }
    }
}