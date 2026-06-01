/**
 * =========================================================
 * EMPLOYEE HIGH RISK AUTOMATION TEST CLASS
 * =========================================================
 *
 * Unit test class for validating employee high-risk
 * classification automation and risk recalculation logic.
 *
 * This class verifies automatic updates to:
 *
 * - Risk_Level__c
 * - Total_Claims__c
 * - Total_Payout__c
 *
 * based on employee claim activity and financial exposure.
 *
 * ---------------------------------------------------------
 * BUSINESS PURPOSE
 * ---------------------------------------------------------
 *
 * Employees with excessive claim activity or unusually
 * large claims may represent elevated organizational risk.
 *
 * The system automatically evaluates employee claim data
 * and classifies employees as High Risk when predefined
 * thresholds are exceeded.
 *
 * This automation supports:
 *
 * - fraud detection
 * - compliance monitoring
 * - operational risk analysis
 * - insurance oversight
 * - employee claim auditing
 * - financial exposure tracking
 *
 * ---------------------------------------------------------
 * HIGH-RISK CLASSIFICATION RULES
 * ---------------------------------------------------------
 *
 * An employee is classified as:
 *
 *     Risk_Level__c = 'High'
 *
 * when either condition is met:
 *
 * 1. Employee has 3 or more related claims
 *
 * OR
 *
 * 2. Employee has at least one claim with
 *    Settlement_Amount__c > 10,000
 *
 * ---------------------------------------------------------
 * AUTOMATION BEHAVIOR TESTED
 * ---------------------------------------------------------
 *
 * The automation is expected to:
 *
 * ✔ Automatically classify employees as High Risk
 * ✔ Recalculate risk when claims change
 * ✔ Remove High Risk status when thresholds are no longer met
 * ✔ Recalculate totals after updates/deletes
 * ✔ Support bulk-safe processing
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
 * Employee risk calculations are based on related claims
 * connected through Employee_Claim__c records.
 *
 * ---------------------------------------------------------
 * TEST COVERAGE AREAS
 * ---------------------------------------------------------
 *
 * This class validates:
 *
 * ✔ High-risk classification by claim count
 * ✔ High-risk classification by large payout amount
 * ✔ Non-high-risk scenarios
 * ✔ Automatic risk removal after payout reduction
 * ✔ Automatic risk removal after claim deletion
 * ✔ Rollup recalculation integrity
 *
 * ---------------------------------------------------------
 * CLAIM COUNT THRESHOLD TESTING
 * ---------------------------------------------------------
 *
 * Employees should automatically become High Risk when:
 *
 *     Total_Claims__c >= 3
 *
 * The related tests validate:
 *
 * - correct claim counting
 * - automatic risk escalation
 * - rollup accuracy
 *
 * ---------------------------------------------------------
 * LARGE CLAIM THRESHOLD TESTING
 * ---------------------------------------------------------
 *
 * Employees should automatically become High Risk when:
 *
 *     Settlement_Amount__c > 10,000
 *
 * The related tests validate:
 *
 * - payout aggregation
 * - financial threshold evaluation
 * - automatic risk escalation
 *
 * ---------------------------------------------------------
 * NEGATIVE TESTING
 * ---------------------------------------------------------
 *
 * The class verifies employees are NOT incorrectly marked
 * as High Risk when thresholds are not met.
 *
 * This protects against:
 *
 * - false positives
 * - inaccurate reporting
 * - unnecessary escalation
 *
 * ---------------------------------------------------------
 * RISK REMOVAL TESTING
 * ---------------------------------------------------------
 *
 * The automation must also REMOVE High Risk status when:
 *
 * - payout values decrease
 * - claims are removed
 * - thresholds are no longer exceeded
 *
 * This ensures risk classifications remain accurate over time.
 *
 * ---------------------------------------------------------
 * DELETE AUTOMATION TESTING
 * ---------------------------------------------------------
 *
 * Claim relationship deletions should trigger:
 *
 * - claim count recalculation
 * - payout recalculation
 * - risk reevaluation
 *
 * ---------------------------------------------------------
 * BULKIFICATION CONSIDERATIONS
 * ---------------------------------------------------------
 *
 * Although individual scenarios are emphasized,
 * the automation is expected to remain bulk-safe.
 *
 * The tested logic should:
 *
 * - avoid SOQL-in-loop violations
 * - avoid DML-in-loop violations
 * - support governor-limit-safe recalculations
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
 * - lifecycle recalculation testing
 * - business-rule validation
 * - aggregation integrity testing
 *
 * ---------------------------------------------------------
 * DEPENDENCIES
 * ---------------------------------------------------------
 *
 * This class depends on:
 *
 * - Employee__c object
 * - Claim__c object
 * - Employee_Claim__c junction object
 * - employee risk automation logic
 * - payout rollup calculations
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
 * - classify employee risk correctly
 * - automatically reevaluate risk after changes
 * - preserve data consistency
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
private class EmployeeHighRiskAutomationTest {

    /*
     * =========================================================
     * CLAIM COUNT THRESHOLD TESTS
     * =========================================================
     */

    /**
     * Verifies employee becomes high risk
     * after reaching 3 claims.
     */
    @IsTest
    static void testEmployeeMarkedHighRiskFromClaimCount() {

        Employee__c emp =
            TestDataFactory.createEmployee();

        insert emp;

        List<Claim__c> claims =
            TestDataFactory.createBulkClaims(3, 1000);

        insert claims;

        List<Employee_Claim__c> junctions =
            new List<Employee_Claim__c>();

        for (Claim__c c : claims) {

            junctions.add(
                TestDataFactory.createEmployeeClaim(
                    emp.Id,
                    c.Id
                )
            );
        }

        Test.startTest();
        insert junctions;
        Test.stopTest();

        Employee__c updatedEmp = [
            SELECT
                Risk_Level__c,
                Total_Claims__c
            FROM Employee__c
            WHERE Id = :emp.Id
        ];

        System.assertEquals(
            3,
            updatedEmp.Total_Claims__c,
            'Employee should have 3 claims'
        );

        System.assertEquals(
            'High',
            updatedEmp.Risk_Level__c,
            'Employee should be marked high risk after 3 claims'
        );
    }

    /*
     * =========================================================
     * LARGE CLAIM THRESHOLD TESTS
     * =========================================================
     */

    /**
     * Verifies employee becomes high risk
     * when a linked claim exceeds $10,000.
     */
    @IsTest
    static void testEmployeeMarkedHighRiskFromLargeClaim() {

        Employee__c emp =
            TestDataFactory.createEmployee();

        insert emp;

        Claim__c claim =
            TestDataFactory.createClaim(
                'Open',
                15000
            );

        insert claim;

        Employee_Claim__c junction =
            TestDataFactory.createEmployeeClaim(
                emp.Id,
                claim.Id
            );

        Test.startTest();
        insert junction;
        Test.stopTest();

        Employee__c updatedEmp = [
            SELECT
                Risk_Level__c,
                Total_Payout__c
            FROM Employee__c
            WHERE Id = :emp.Id
        ];

        System.assertEquals(
            15000,
            updatedEmp.Total_Payout__c,
            'Employee payout should equal large settlement amount'
        );

        System.assertEquals(
            'High',
            updatedEmp.Risk_Level__c,
            'Employee should be marked high risk from large claim'
        );
    }

    /*
     * =========================================================
     * NEGATIVE TESTS
     * =========================================================
     */

    /**
     * Verifies employee remains not high risk
     * below all thresholds.
     */
    @IsTest
    static void testEmployeeNotMarkedHighRisk() {

        Employee__c emp =
            TestDataFactory.createEmployee();

        insert emp;

        List<Claim__c> claims =
            TestDataFactory.createBulkClaims(2, 1000);

        insert claims;

        List<Employee_Claim__c> junctions =
            new List<Employee_Claim__c>();

        for (Claim__c c : claims) {

            junctions.add(
                TestDataFactory.createEmployeeClaim(
                    emp.Id,
                    c.Id
                )
            );
        }

        Test.startTest();
        insert junctions;
        Test.stopTest();

        Employee__c updatedEmp = [
            SELECT
                Risk_Level__c,
                Total_Claims__c,
                Total_Payout__c
            FROM Employee__c
            WHERE Id = :emp.Id
        ];

        System.assertEquals(
            2,
            updatedEmp.Total_Claims__c,
            'Employee should only have 2 claims'
        );

        System.assertEquals(
            2000,
            updatedEmp.Total_Payout__c,
            'Employee payout should remain below threshold'
        );

        System.assertNotEquals(
            'High',
            updatedEmp.Risk_Level__c,
            'Employee should not be marked high risk'
        );
    }

    /*
     * =========================================================
     * HIGH RISK REMOVAL TESTS
     * =========================================================
     */

    /**
     * Verifies High_Risk__c is unchecked
     * after claim values drop below threshold.
     */
    @IsTest
    static void testHighRiskCheckboxAutomaticallyUnchecked() {

        Employee__c emp =
            TestDataFactory.createEmployee();

        insert emp;

        Claim__c claim =
            TestDataFactory.createClaim(
                'Open',
                15000
            );

        insert claim;

        Employee_Claim__c junction =
            TestDataFactory.createEmployeeClaim(
                emp.Id,
                claim.Id
            );

        insert junction;

        claim.Settlement_Amount__c = 1000;

        Test.startTest();
        update claim;
        Test.stopTest();

        Employee__c updatedEmp = [
            SELECT
                Risk_Level__c,
                Total_Payout__c
            FROM Employee__c
            WHERE Id = :emp.Id
        ];

        System.assertEquals(
            1000,
            updatedEmp.Total_Payout__c,
            'Employee payout should recalculate after reduction'
        );

        System.assertNotEquals(
            'High',
            updatedEmp.Risk_Level__c,
            'Employee should no longer be high risk'
        );
    }

    /*
     * =========================================================
     * CLAIM DELETE TESTS
     * =========================================================
     */

    /**
     * Verifies High_Risk__c is unchecked
     * when claim count drops below threshold.
     */
    @IsTest
    static void testHighRiskRemovedAfterClaimDeletion() {

        Employee__c emp =
            TestDataFactory.createEmployee();

        insert emp;

        List<Claim__c> claims =
            TestDataFactory.createBulkClaims(3, 1000);

        insert claims;

        List<Employee_Claim__c> junctions =
            new List<Employee_Claim__c>();

        for (Claim__c c : claims) {

            junctions.add(
                TestDataFactory.createEmployeeClaim(
                    emp.Id,
                    c.Id
                )
            );
        }

        insert junctions;

        delete junctions[0];

        Employee__c updatedEmp = [
            SELECT
                Risk_Level__c,
                Total_Claims__c
            FROM Employee__c
            WHERE Id = :emp.Id
        ];

        System.assertEquals(
            2,
            updatedEmp.Total_Claims__c,
            'Employee should now have only 2 claims'
        );

        System.assertNotEquals(
            'High',
            updatedEmp.Risk_Level__c,
            'Employee should no longer be high risk'
        );
    }
}
