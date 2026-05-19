/**
 * Unit tests for Employee high-risk automation logic.
 *
 * Acceptance Criteria:
 * - Employee is marked High Risk if:
 *      1. Employee has 3 or more claims
 *      OR
 *      2. Employee has a claim greater than $10,000
 *
 * - High_Risk__c is automatically checked and unchecked
 *   based on trigger evaluation.
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