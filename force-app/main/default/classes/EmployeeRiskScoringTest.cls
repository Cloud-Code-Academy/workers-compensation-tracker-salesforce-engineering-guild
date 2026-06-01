/**
 * =========================================================
 * EMPLOYEE RISK SCORING TEST CLASS
 * =========================================================
 *
 * Unit test class for validating employee risk-scoring
 * automation and dynamic risk classification behavior.
 *
 * This class verifies that employee risk levels are
 * automatically calculated and updated based on:
 *
 * - total number of related claims
 * - cumulative payout exposure
 * - individual high-value claims
 * - claim additions and removals
 *
 * ---------------------------------------------------------
 * BUSINESS PURPOSE
 * ---------------------------------------------------------
 *
 * Employee risk scoring is used to identify individuals
 * with elevated insurance or operational risk exposure.
 *
 * Risk classifications support:
 *
 * - fraud detection
 * - compliance review
 * - insurance analytics
 * - financial oversight
 * - operational reporting
 * - escalation workflows
 *
 * Employees are automatically assigned risk levels based
 * on their related claims and financial impact.
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
 * Risk calculations aggregate data from related Claim__c
 * records connected through Employee_Claim__c records.
 *
 * ---------------------------------------------------------
 * RISK LEVELS TESTED
 * ---------------------------------------------------------
 *
 * STANDARD
 * - minimal claim activity
 * - low payout exposure
 *
 * MEDIUM RISK
 * - moderate claim activity
 * - moderate payout exposure
 *
 * HIGH
 * - excessive claim activity
 * - large settlement exposure
 * - elevated financial risk
 *
 * ---------------------------------------------------------
 * TEST COVERAGE AREAS
 * ---------------------------------------------------------
 *
 * This class validates:
 *
 * ✔ Standard risk classification
 * ✔ Medium risk classification
 * ✔ High risk classification
 * ✔ Single high-value claim escalation
 * ✔ Claim-volume escalation
 * ✔ Dynamic risk re-evaluation
 * ✔ Risk recalculation after updates
 * ✔ Risk recalculation after deletions
 *
 * ---------------------------------------------------------
 * STANDARD RISK TESTING
 * ---------------------------------------------------------
 *
 * Standard-risk employees are expected to:
 *
 * - maintain low claim counts
 * - maintain low payout totals
 * - remain classified as 'Standard'
 *
 * These tests validate:
 *
 * - baseline scoring behavior
 * - low-risk classification accuracy
 *
 * ---------------------------------------------------------
 * MEDIUM RISK TESTING
 * ---------------------------------------------------------
 *
 * Medium-risk employees represent moderate exposure.
 *
 * These tests validate:
 *
 * - claim aggregation behavior
 * - payout aggregation behavior
 * - medium-level risk escalation
 *
 * ---------------------------------------------------------
 * HIGH RISK TESTING
 * ---------------------------------------------------------
 *
 * High-risk employees are expected when:
 *
 * - claim volume becomes excessive
 * - payout totals become unusually large
 * - individual claims exceed thresholds
 *
 * These tests validate:
 *
 * - high-risk escalation logic
 * - financial exposure calculations
 * - claim-count escalation logic
 *
 * ---------------------------------------------------------
 * LARGE SETTLEMENT EDGE CASE TESTING
 * ---------------------------------------------------------
 *
 * A single high-value claim may independently trigger
 * High risk classification.
 *
 * These tests validate:
 *
 * - single-claim escalation logic
 * - payout threshold evaluation
 * - immediate risk recalculation
 *
 * ---------------------------------------------------------
 * CLAIM VOLUME EDGE CASE TESTING
 * ---------------------------------------------------------
 *
 * Multiple low-value claims may collectively increase
 * employee risk exposure.
 *
 * These tests validate:
 *
 * - volume-based risk escalation
 * - cumulative claim analysis
 * - aggregation integrity
 *
 * ---------------------------------------------------------
 * RISK RE-EVALUATION TESTING
 * ---------------------------------------------------------
 *
 * Employee risk levels must dynamically recalculate when:
 *
 * - settlement amounts change
 * - claims are added
 * - claims are removed
 * - payout exposure changes
 *
 * These tests validate:
 *
 * - automatic recalculation behavior
 * - trigger/automation responsiveness
 * - data consistency
 *
 * ---------------------------------------------------------
 * DELETE AUTOMATION TESTING
 * ---------------------------------------------------------
 *
 * Claim relationship deletions should automatically:
 *
 * - reduce claim counts
 * - reduce payout totals
 * - reevaluate employee risk levels
 *
 * ---------------------------------------------------------
 * BULKIFICATION CONSIDERATIONS
 * ---------------------------------------------------------
 *
 * The tested automation is expected to remain bulk-safe.
 *
 * Automation should:
 *
 * - avoid SOQL-in-loop violations
 * - avoid DML-in-loop violations
 * - support large-volume recalculations
 * - operate within Salesforce governor limits
 *
 * ---------------------------------------------------------
 * TESTING STRATEGY
 * ---------------------------------------------------------
 *
 * This class follows Apex testing best practices:
 *
 * - isolated test methods
 * - reusable TestDataFactory helpers
 * - positive and edge-case testing
 * - aggregation validation
 * - dynamic recalculation testing
 * - business-rule-focused assertions
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
 * - employee risk-scoring automation
 * - payout rollup automation
 * - TestDataFactory helper methods
 *
 * ---------------------------------------------------------
 * EXPECTED AUTOMATION BEHAVIOR
 * ---------------------------------------------------------
 *
 * The tested automation is expected to:
 *
 * - maintain accurate claim totals
 * - maintain accurate payout totals
 * - classify employees correctly
 * - dynamically recalculate risk
 * - respond to updates and deletions
 * - preserve aggregation integrity
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
private class EmployeeRiskScoringTest {

    /*
     * =========================================================
     * STANDARD RISK TESTS
     * =========================================================
     */

    @IsTest
    static void testStandardRiskEmployee() {

        Employee__c emp =
            TestDataFactory.createStandardRiskScenario();

        Employee__c updatedEmp = [
            SELECT
                Id,
                Risk_Level__c,
                Total_Claims__c,
                Total_Payout__c
            FROM Employee__c
            WHERE Id = :emp.Id
        ];

        System.assertEquals(
            1,
            updatedEmp.Total_Claims__c,
            'Standard employee should have 1 claim'
        );

        System.assertEquals(
            500,
            updatedEmp.Total_Payout__c,
            'Standard employee payout should equal 500'
        );

        System.assertEquals(
            'Standard',
            updatedEmp.Risk_Level__c,
            'Employee should be classified as Standard risk'
        );
    }

    /*
     * =========================================================
     * MEDIUM RISK TESTS
     * =========================================================
     */

    @IsTest
    static void testMediumRiskEmployee() {

        Employee__c emp =
            TestDataFactory.createMediumRiskScenario();

        Employee__c updatedEmp = [
            SELECT
                Id,
                Risk_Level__c,
                Total_Claims__c,
                Total_Payout__c
            FROM Employee__c
            WHERE Id = :emp.Id
        ];

        System.assertEquals(
            3,
            updatedEmp.Total_Claims__c,
            'Medium risk employee should have 3 claims'
        );

        System.assertEquals(
            9000,
            updatedEmp.Total_Payout__c,
            'Total payout should equal 9000'
        );

        System.assertEquals(
            'Medium Risk',
            updatedEmp.Risk_Level__c,
            'Employee should be classified as Medium Risk'
        );
    }

    /*
     * =========================================================
     * HIGH RISK TESTS
     * =========================================================
     */

    @IsTest
    static void testHighRiskEmployee() {

        Employee__c emp =
            TestDataFactory.createHighRiskScenario();

        Employee__c updatedEmp = [
            SELECT
                Id,
                Risk_Level__c,
                Total_Claims__c,
                Total_Payout__c
            FROM Employee__c
            WHERE Id = :emp.Id
        ];

        System.assertEquals(
            5,
            updatedEmp.Total_Claims__c,
            'High risk employee should have 5 claims'
        );

        System.assertEquals(
            50000,
            updatedEmp.Total_Payout__c,
            'Total payout should equal 50000'
        );

        System.assertEquals(
            'High',
            updatedEmp.Risk_Level__c,
            'Employee should be classified as High risk'
        );
    }

    /*
     * =========================================================
     * LARGE SETTLEMENT EDGE CASE
     * =========================================================
     */

    @IsTest
    static void testSingleLargeSettlementTriggersHighRisk() {

        Employee__c emp = TestDataFactory.createEmployee();
        insert emp;

        Claim__c claim =
            TestDataFactory.createHighValueClaim();

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
                Total_Claims__c,
                Total_Payout__c
            FROM Employee__c
            WHERE Id = :emp.Id
        ];

        System.assertEquals(
            1,
            updatedEmp.Total_Claims__c,
            'Employee should have one linked claim'
        );

        System.assertEquals(
            10000,
            updatedEmp.Total_Payout__c,
            'Total payout should equal high settlement amount'
        );

        System.assertEquals(
            'High',
            updatedEmp.Risk_Level__c,
            'Single high-value settlement should trigger High risk'
        );
    }

    /*
     * =========================================================
     * CLAIM VOLUME EDGE CASE
     * =========================================================
     */

     @IsTest
    static void testMultipleLowClaimsIncreaseRisk() {

        Employee__c emp = TestDataFactory.createEmployee();
        insert emp;

        List<Claim__c> claims =
            TestDataFactory.createBulkClaims(6, 500);

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
            6,
            updatedEmp.Total_Claims__c,
            'Employee should have 6 claims'
        );

        System.assertEquals(
            3000,
            updatedEmp.Total_Payout__c,
            'Total payout should equal 3000'
        );

        System.assertNotEquals(
            'Standard',
            updatedEmp.Risk_Level__c,
            'High claim volume should increase risk level'
        );
    }

    /*
     * =========================================================
     * RISK RE-EVALUATION TEST
     * =========================================================
     */

    @IsTest
    static void testRiskLevelUpdatesAfterClaimIncrease() {

        Employee__c emp = TestDataFactory.createEmployee();
        insert emp;

        Claim__c claim =
            TestDataFactory.createLowRiskClaim();

        insert claim;

        Employee_Claim__c junction =
            TestDataFactory.createEmployeeClaim(
                emp.Id,
                claim.Id
            );

        insert junction;

        Employee__c initialEmp = [
            SELECT Risk_Level__c
            FROM Employee__c
            WHERE Id = :emp.Id
        ];

        claim.Settlement_Amount__c = 15000;

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
            15000,
            updatedEmp.Total_Payout__c,
            'Payout total should update after settlement increase'
        );

        System.assertNotEquals(
            initialEmp.Risk_Level__c,
            updatedEmp.Risk_Level__c,
            'Risk level should recalculate after payout increase'
        );
    }

    /*
     * =========================================================
     * DELETE CLAIM EDGE CASE
     * =========================================================
     */

    @IsTest
    static void testRiskLevelDropsAfterClaimRemoval() {

        Employee__c emp =
            TestDataFactory.createHighRiskScenario();

        Employee__c beforeDelete = [
            SELECT
                Risk_Level__c,
                Total_Claims__c
            FROM Employee__c
            WHERE Id = :emp.Id
        ];

        List<Employee_Claim__c> junctions = [
            SELECT Id
            FROM Employee_Claim__c
            WHERE Employee__c = :emp.Id
            LIMIT 4
        ];

        Test.startTest();
        delete junctions;
        Test.stopTest();

        Employee__c updatedEmp = [
            SELECT
                Risk_Level__c,
                Total_Claims__c,
                Total_Payout__c
            FROM Employee__c
            WHERE Id = :emp.Id
        ];

        System.assert(
            updatedEmp.Total_Claims__c <
            beforeDelete.Total_Claims__c,
            'Claim count should decrease after deletions'
        );

        System.assertNotEquals(
            beforeDelete.Risk_Level__c,
            updatedEmp.Risk_Level__c,
            'Risk level should recalculate after claim removal'
        );
    }
}
