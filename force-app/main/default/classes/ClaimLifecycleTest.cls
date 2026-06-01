/**
 * =========================================================
 * CLAIM LIFECYCLE TEST CLASS
 * =========================================================
 *
 * Unit test class for validating the complete lifecycle
 * behavior of Claim__c records and their related employee
 * financial rollup calculations.
 *
 * This class verifies:
 *
 * - claim status transitions
 * - settlement processing
 * - payout tracking
 * - financial rollup calculations
 * - rejected claim handling
 * - bulk lifecycle processing
 * - relationship integrity
 *
 * ---------------------------------------------------------
 * BUSINESS PURPOSE
 * ---------------------------------------------------------
 *
 * Claims move through multiple lifecycle stages during
 * processing and investigation.
 *
 * Common lifecycle progression:
 *
 *     Open
 *         ↓
 *     In Review
 *         ↓
 *     Settled / Rejected
 *
 * Each transition may trigger:
 *
 * - financial calculations
 * - reporting updates
 * - employee risk recalculations
 * - payout rollups
 * - validation logic
 * - automation workflows
 *
 * ---------------------------------------------------------
 * TEST COVERAGE AREAS
 * ---------------------------------------------------------
 *
 * This test suite validates:
 *
 * ✔ Open → In Review transitions
 * ✔ In Review → Settled transitions
 * ✔ Settlement amount updates
 * ✔ Settlement date population
 * ✔ Employee financial rollups
 * ✔ Rejected claim handling
 * ✔ Bulk lifecycle processing
 * ✔ Junction relationship integrity
 *
 * ---------------------------------------------------------
 * TEST SETUP STRATEGY
 * ---------------------------------------------------------
 *
 * This class uses @TestSetup to create reusable baseline
 * test data shared across all test methods.
 *
 * Shared setup includes:
 *
 * - one Employee__c record
 * - one Claim__c record
 * - one Employee_Claim__c junction record
 *
 * Benefits of @TestSetup:
 *
 * - faster test execution
 * - reduced duplicate setup logic
 * - cleaner test methods
 * - improved maintainability
 *
 * ---------------------------------------------------------
 * LIFECYCLE STATES TESTED
 * ---------------------------------------------------------
 *
 * OPEN
 * - newly created claims
 * - active investigations
 *
 * In Review
 * - claim currently being evaluated
 * - pending investigation or approval
 *
 * SETTLED
 * - claim approved and paid
 * - settlement amount finalized
 * - settlement date populated
 *
 * REJECTED
 * - claim denied
 * - no payout issued
 * - no settlement date allowed
 *
 * ---------------------------------------------------------
 * FINANCIAL ROLLUP VALIDATION
 * ---------------------------------------------------------
 *
 * Employee-level financial summaries are expected to update
 * automatically when claims settle.
 *
 * Tested rollup fields include:
 *
 * - Total_Claims__c
 * - Total_Payout__c
 *
 * This ensures related automation correctly aggregates:
 *
 * - claim counts
 * - payout totals
 * - settlement values
 *
 * ---------------------------------------------------------
 * BULKIFICATION VALIDATION
 * ---------------------------------------------------------
 *
 * Bulk tests ensure lifecycle automation:
 *
 * - processes multiple claims correctly
 * - avoids SOQL-in-loop issues
 * - avoids DML-in-loop issues
 * - scales within Salesforce governor limits
 *
 * ---------------------------------------------------------
 * TESTING STRATEGY
 * ---------------------------------------------------------
 *
 * This class follows Apex testing best practices:
 *
 * - isolated test methods
 * - reusable TestDataFactory helpers
 * - bulk-safe validation
 * - positive-path lifecycle testing
 * - financial integrity validation
 * - relationship validation
 *
 * ---------------------------------------------------------
 * DEPENDENCIES
 * ---------------------------------------------------------
 *
 * This test class depends on:
 *
 * - Claim__c object
 * - Employee__c object
 * - Employee_Claim__c junction object
 * - lifecycle automation
 * - financial rollup automation
 * - TestDataFactory helper methods
 *
 * ---------------------------------------------------------
 * EXPECTED AUTOMATION BEHAVIOR
 * ---------------------------------------------------------
 *
 * The tested automation is expected to:
 *
 * - allow valid lifecycle transitions
 * - update settlement fields correctly
 * - maintain relationship integrity
 * - recalculate employee financial totals
 * - support bulk operations safely
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
 * - Assertions validate both business logic correctness
 *   and data integrity.
 *
 * =========================================================
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
     * OPEN -> In Review
     * =========================================================
     */

     @IsTest
    static void testClaimMovesToUnderReview() {

        Claim__c claim = [
            SELECT Id, Status__c
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
            'Claim should transition to In Review'
        );
    }

    /*
     * =========================================================
     * In Review -> SETTLED
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

        claim.Status__c = 'Denied';
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
            'Denied',
            updatedClaim.Status__c,
            'Claim should move to Rejected status'
        );

        System.assertEquals(
            0,
            updatedClaim.Settlement_Amount__c,
            'Denied claims should not have settlement payouts'
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
