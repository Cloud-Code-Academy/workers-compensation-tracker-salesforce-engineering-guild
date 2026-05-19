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
@isTest
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

    @isTest
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

    @isTest
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

    @isTest
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

    @isTest
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