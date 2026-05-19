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