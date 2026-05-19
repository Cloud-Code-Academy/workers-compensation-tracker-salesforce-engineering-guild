/**
 * Unit tests for intake validation rules.
 *
 * Acceptance Criteria:
 * - Incident Date cannot be in the future
 * - Required fields:
 *      1. Location__c
 *      2. Nature_of_Injury__c
 *      3. Employee__c
 */
@IsTest
private class IntakeValidationTest {

    /*
     * =========================================================
     * FUTURE INCIDENT DATE TESTS
     * =========================================================
     */

    /**
     * Verifies claims cannot be saved
     * when Incident_Date__c is in the future.
     */
    @IsTest
    static void testFutureIncidentDateFailsValidation() {

        Employee__c emp =
            TestDataFactory.createEmployee();

        insert emp;

        Claim__c claim =
            TestDataFactory.createClaim(
                'Open',
                1000
            );

        claim.Employee__c = emp.Id;
        claim.Location__c = 'Warehouse A';
        claim.Injury_Type__c = 'Back Injury';
        claim.Incident_Date__c = Date.today().addDays(5);

        Test.startTest();

        try {

            insert claim;

            System.assert(
                false,
                'Expected validation error for future incident date'
            );

        } catch (DmlException e) {

            System.assert(
                e.getMessage().contains('Incident'),
                'Validation message should reference incident date'
            );
        }

        Test.stopTest();
    }

    /*
     * =========================================================
     * REQUIRED LOCATION TESTS
     * =========================================================
     */

    /**
     * Verifies claims cannot be saved
     * without Location__c.
     */
    @IsTest
    static void testMissingLocationFailsValidation() {

        Employee__c emp =
            TestDataFactory.createEmployee();

        insert emp;

        Claim__c claim =
            TestDataFactory.createClaim(
                'Open',
                1000
            );

        claim.Employee__c = emp.Id;
        claim.Injury_Type__c = 'Shoulder Injury';
        claim.Incident_Date__c = Date.today();

        Test.startTest();

        try {

            insert claim;

            System.assert(
                false,
                'Expected validation error for missing location'
            );

        } catch (DmlException e) {

            System.assert(
                e.getMessage().contains('Location'),
                'Validation should reference missing location'
            );
        }

        Test.stopTest();
    }

    /*
     * =========================================================
     * REQUIRED NATURE OF INJURY TESTS
     * =========================================================
     */

    /**
     * Verifies claims cannot be saved
     * without Nature_of_Injury__c.
     */
    @IsTest
    static void testMissingNatureOfInjuryFailsValidation() {

        Employee__c emp =
            TestDataFactory.createEmployee();

        insert emp;

        Claim__c claim =
            TestDataFactory.createClaim(
                'Open',
                1000
            );

        claim.Employee__c = emp.Id;
        claim.Location__c = 'Warehouse B';
        claim.Incident_Date__c = Date.today();

        Test.startTest();

        try {

            insert claim;

            System.assert(
                false,
                'Expected validation error for missing injury description'
            );

        } catch (DmlException e) {

            System.assert(
                e.getMessage().contains('Injury'),
                'Validation should reference missing injury field'
            );
        }

        Test.stopTest();
    }

    /*
     * =========================================================
     * REQUIRED EMPLOYEE TESTS
     * =========================================================
     */

    /**
     * Verifies claims cannot be saved
     * without Employee__c.
     */
    @IsTest
    static void testMissingEmployeeFailsValidation() {

        Claim__c claim =
            TestDataFactory.createClaim(
                'Open',
                1000
            );

        claim.Location__c = 'Warehouse C';
        claim.Injury_Type__c = 'Leg Injury';
        claim.Incident_Date__c = Date.today();

        Test.startTest();

        try {

            insert claim;

            System.assert(
                false,
                'Expected validation error for missing employee'
            );

        } catch (DmlException e) {

            System.assert(
                e.getMessage().contains('Employee'),
                'Validation should reference missing employee'
            );
        }

        Test.stopTest();
    }

    /*
     * =========================================================
     * POSITIVE VALIDATION TESTS
     * =========================================================
     */

    /**
     * Verifies valid intake records
     * save successfully.
     */
    @IsTest
    static void testValidClaimIntakeSucceeds() {

        Employee__c emp =
            TestDataFactory.createEmployee();

        insert emp;

        Claim__c claim =
            TestDataFactory.createClaim(
                'Open',
                2500
            );

        claim.Employee__c = emp.Id;
        claim.Location__c = 'Distribution Center';
        claim.Injury_Type__c = 'Arm Injury';
        claim.Incident_Date__c = Date.today();

        Test.startTest();
        insert claim;
        Test.stopTest();

        Claim__c insertedClaim = [
            SELECT
                Employee__c,
                Location__c,
                Injury_Type__c,
                Incident_Date__c
            FROM Claim__c
            WHERE Id = :claim.Id
        ];

        System.assertEquals(
            emp.Id,
            insertedClaim.Employee__c,
            'Employee should save correctly'
        );

        System.assertEquals(
            'Distribution Center',
            insertedClaim.Location__c,
            'Location should save correctly'
        );

        System.assertEquals(
            'Arm Injury',
            insertedClaim.Injury_Type__c,
            'Nature of injury should save correctly'
        );

        System.assertEquals(
            Date.today(),
            insertedClaim.Incident_Date__c,
            'Incident date should save correctly'
        );
    }

    /*
     * =========================================================
     * BULK VALIDATION TESTS
     * =========================================================
     */

    /**
     * Verifies intake validations
     * enforce correctly during bulk operations.
     */
    @IsTest
    static void testBulkIntakeValidation() {

        Employee__c emp =
            TestDataFactory.createEmployee();

        insert emp;

        List<Claim__c> claims =
            new List<Claim__c>();

        Claim__c validClaim =
            TestDataFactory.createClaim(
                'Open',
                1000
            );

        validClaim.Employee__c = emp.Id;
        validClaim.Location__c = 'Office';
        validClaim.Injury_Type__c = 'Minor Cut';
        validClaim.Incident_Date__c = Date.today();

        claims.add(validClaim);

        Claim__c invalidClaim =
            TestDataFactory.createClaim(
                'Open',
                1000
            );

        invalidClaim.Employee__c = emp.Id;
        invalidClaim.Location__c = 'Warehouse';
        invalidClaim.Injury_Type__c = 'Burn';
        invalidClaim.Incident_Date__c = Date.today().addDays(3);

        claims.add(invalidClaim);

        Test.startTest();

        Database.SaveResult[] results =
            Database.insert(claims, false);

        Test.stopTest();

        System.assertEquals(
            true,
            results[0].isSuccess(),
            'Valid claim should insert successfully'
        );

        System.assertEquals(
            false,
            results[1].isSuccess(),
            'Future incident claim should fail validation'
        );
    }
}