/**
 * =========================================================
 * EMPLOYEE CLAIMS SUMMARY TEST CLASS
 * =========================================================
 *
 * Unit test class for validating employee-level claim summary
 * rollup calculations and aggregation behavior.
 *
 * This class verifies automation responsible for maintaining:
 *
 * - Total_Claims__c
 * - Total_Payout__c
 *
 * on Employee__c records based on related claims connected
 * through the Employee_Claim__c junction object.
 *
 * ---------------------------------------------------------
 * BUSINESS PURPOSE
 * ---------------------------------------------------------
 *
 * Employees may have multiple associated insurance claims.
 *
 * The system maintains summary metrics on Employee__c records
 * to support:
 *
 * - risk analysis
 * - claims reporting
 * - financial dashboards
 * - employee profiling
 * - payout aggregation
 * - operational monitoring
 *
 * These summaries must automatically update whenever:
 *
 * - claims are linked
 * - payout amounts change
 * - relationships are removed
 *
 * ---------------------------------------------------------
 * OBJECT RELATIONSHIPS
 * ---------------------------------------------------------
 *
 * Employee__c
 *     ↑
 * Employee_Claim__c (junction object)
 *     ↓
 * Claim__c
 *
 * Employee_Claim__c connects employees to claims and allows
 * rollup automation to aggregate claim information onto
 * Employee__c records.
 *
 * ---------------------------------------------------------
 * ROLLUP FIELDS TESTED
 * ---------------------------------------------------------
 *
 * Total_Claims__c
 * - total number of related claims
 *
 * Total_Payout__c
 * - sum of Settlement_Amount__c values from related claims
 *
 * ---------------------------------------------------------
 * TEST COVERAGE AREAS
 * ---------------------------------------------------------
 *
 * This class validates:
 *
 * ✔ Claim rollups during insert operations
 * ✔ Rollup recalculation after claim updates
 * ✔ Rollup recalculation after relationship deletion
 * ✔ Bulk rollup processing
 * ✔ Financial aggregation accuracy
 * ✔ Junction relationship integrity
 *
 * ---------------------------------------------------------
 * TEST SETUP STRATEGY
 * ---------------------------------------------------------
 *
 * Shared test data is created using @TestSetup.
 *
 * Setup includes:
 *
 * - one Employee__c record
 *
 * Benefits:
 *
 * - reduced duplicate setup logic
 * - improved execution performance
 * - consistent baseline data
 * - cleaner test methods
 *
 * ---------------------------------------------------------
 * INSERT AUTOMATION BEHAVIOR
 * ---------------------------------------------------------
 *
 * When Employee_Claim__c records are inserted:
 *
 * - Total_Claims__c should increase
 * - Total_Payout__c should aggregate claim payouts
 *
 * ---------------------------------------------------------
 * UPDATE AUTOMATION BEHAVIOR
 * ---------------------------------------------------------
 *
 * When Claim__c settlement amounts change:
 *
 * - Employee payout totals should recalculate automatically
 *
 * ---------------------------------------------------------
 * DELETE AUTOMATION BEHAVIOR
 * ---------------------------------------------------------
 *
 * When Employee_Claim__c records are deleted:
 *
 * - claim totals should decrease
 * - payout totals should recalculate
 *
 * ---------------------------------------------------------
 * BULKIFICATION VALIDATION
 * ---------------------------------------------------------
 *
 * Bulk tests ensure rollup automation:
 *
 * - processes many records correctly
 * - avoids SOQL-in-loop violations
 * - avoids DML-in-loop violations
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
 * - insert/update/delete lifecycle testing
 * - business-focused assertions
 * - aggregation integrity testing
 *
 * ---------------------------------------------------------
 * DEPENDENCIES
 * ---------------------------------------------------------
 *
 * This test class depends on:
 *
 * - Employee__c object
 * - Claim__c object
 * - Employee_Claim__c junction object
 * - rollup automation/triggers
 * - TestDataFactory helper methods
 *
 * ---------------------------------------------------------
 * EXPECTED AUTOMATION BEHAVIOR
 * ---------------------------------------------------------
 *
 * The tested automation is expected to:
 *
 * - maintain accurate claim counts
 * - maintain accurate payout totals
 * - recalculate values automatically
 * - preserve aggregation integrity
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
 * - Assertions validate both business correctness and
 *   data aggregation integrity.
 *
 * =========================================================
 */
@IsTest
private class EmployeeClaimsSummaryTest {

    /*
     * =========================================================
     * TEST SETUP
     * =========================================================
     */

    @TestSetup
    static void setupData() {
        Employee__c emp = TestDataFactory.createEmployee();
        insert emp;
    }

    /*
     * =========================================================
     * INSERT TESTS
     * =========================================================
     */

     @IsTest
    static void testInsertEmployeeClaimRollup() {

        Employee__c emp = [
            SELECT Id, Total_Claims__c, Total_Payout__c
            FROM Employee__c
            LIMIT 1
        ];

        Claim__c claim1 = TestDataFactory.createClaim('Open', 1000);
        Claim__c claim2 = TestDataFactory.createClaim('Open', 3000);

        insert new List<Claim__c>{ claim1, claim2 };

        List<Employee_Claim__c> junctions = new List<Employee_Claim__c>{
            TestDataFactory.createEmployeeClaim(emp.Id, claim1.Id),
            TestDataFactory.createEmployeeClaim(emp.Id, claim2.Id)
        };

        Test.startTest();
        insert junctions;
        Test.stopTest();

        Employee__c updatedEmp = [
            SELECT Total_Claims__c, Total_Payout__c
            FROM Employee__c
            WHERE Id = :emp.Id
        ];

        System.assertEquals(
            2,
            updatedEmp.Total_Claims__c,
            'Employee should have 2 total claims'
        );

        System.assertEquals(
            4000,
            updatedEmp.Total_Payout__c,
            'Employee payout total should equal 4000'
        );
    }

    /*
     * =========================================================
     * UPDATE TESTS
     * =========================================================
     */

    @IsTest
    static void testUpdateClaimAmountRollup() {

        Employee__c emp = [
            SELECT Id
            FROM Employee__c
            LIMIT 1
        ];

        Claim__c claim = TestDataFactory.createClaim('Open', 1000);
        insert claim;

        Employee_Claim__c junction =
            TestDataFactory.createEmployeeClaim(emp.Id, claim.Id);

        insert junction;

        claim.Settlement_Amount__c = 5000;

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
            5000,
            updatedEmp.Total_Payout__c,
            'Rollup should reflect updated payout amount'
        );
    }

    /*
     * =========================================================
     * DELETE TESTS
     * =========================================================
     */

     @IsTest
    static void testDeleteEmployeeClaimRollup() {

        Employee__c emp = [
            SELECT Id
            FROM Employee__c
            LIMIT 1
        ];

        Claim__c claim = TestDataFactory.createClaim('Open', 2000);
        insert claim;

        Employee_Claim__c junction =
            TestDataFactory.createEmployeeClaim(emp.Id, claim.Id);

        insert junction;

        Test.startTest();
        delete junction;
        Test.stopTest();

        Employee__c updatedEmp = [
            SELECT Total_Claims__c, Total_Payout__c
            FROM Employee__c
            WHERE Id = :emp.Id
        ];

        System.assertEquals(
            0,
            updatedEmp.Total_Claims__c,
            'Employee should have 0 claims after delete'
        );

        System.assertEquals(
            0,
            updatedEmp.Total_Payout__c,
            'Employee payout should reset to 0 after delete'
        );
    }

    /*
     * =========================================================
     * BULK TESTS
     * =========================================================
     */

     @IsTest
    static void testBulkInsertRollup() {

        Employee__c emp = [
            SELECT Id
            FROM Employee__c
            LIMIT 1
        ];

        List<Claim__c> claims = TestDataFactory.createBulkClaims(5, 1000);
        insert claims;

        List<Employee_Claim__c> junctions = new List<Employee_Claim__c>();

        for (Claim__c c : claims) {
            junctions.add(
                TestDataFactory.createEmployeeClaim(emp.Id, c.Id)
            );
        }

        Test.startTest();
        insert junctions;
        Test.stopTest();

        Employee__c updatedEmp = [
            SELECT Total_Claims__c, Total_Payout__c
            FROM Employee__c
            WHERE Id = :emp.Id
        ];

        System.assertEquals(
            5,
            updatedEmp.Total_Claims__c,
            'Employee should have 5 claims'
        );

        System.assertEquals(
            5000,
            updatedEmp.Total_Payout__c,
            'Total payout should equal 5000'
        );
    }
}
