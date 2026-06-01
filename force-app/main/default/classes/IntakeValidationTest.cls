/**
 * =========================================================
 * INTAKE VALIDATION TEST CLASS
 * =========================================================
 *
 * Unit test class for validating Incident Date intake rules
 * enforced by ClaimTriggerHandler.validateIncidentDate().
 *
 * This class ensures claims cannot be created or updated
 * with invalid future incident dates while still allowing:
 *
 * - current dates
 * - past dates
 * - null values
 *
 * ---------------------------------------------------------
 * BUSINESS PURPOSE
 * ---------------------------------------------------------
 *
 * Incident dates represent when a claim-related event
 * actually occurred.
 *
 * Preventing future incident dates helps maintain:
 *
 * - claim accuracy
 * - audit integrity
 * - reporting reliability
 * - fraud prevention
 * - chronological consistency
 *
 * The validation logic ensures users cannot accidentally
 * or intentionally enter dates that occur after today.
 *
 * ---------------------------------------------------------
 * VALIDATION RULES
 * ---------------------------------------------------------
 *
 * A claim is considered INVALID when:
 *
 *     Incident_Date__c > Date.today()
 *
 * In these cases:
 *
 * - the record should fail validation
 * - a DmlException should occur
 * - the correct validation message should appear
 *
 * A claim is considered VALID when:
 *
 * - Incident_Date__c = today
 * - Incident_Date__c is in the past
 * - Incident_Date__c is null
 *
 * ---------------------------------------------------------
 * TEST COVERAGE AREAS
 * ---------------------------------------------------------
 *
 * This class validates:
 *
 * ✔ Future incident date prevention
 * ✔ Current-date acceptance
 * ✔ Past-date acceptance
 * ✔ Null date handling
 * ✔ Bulk validation behavior
 * ✔ Update validation enforcement
 * ✔ Validation message correctness
 *
 * ---------------------------------------------------------
 * FUTURE DATE VALIDATION TESTING
 * ---------------------------------------------------------
 *
 * Tests verify:
 *
 * - claims with future dates cannot be inserted
 * - claims with future dates cannot be updated
 * - DML operations fail properly
 * - validation messages are accurate
 *
 * These tests confirm trigger enforcement
 * during both insert and update operations.
 *
 * ---------------------------------------------------------
 * VALID DATE TESTING
 * ---------------------------------------------------------
 *
 * Claims should save successfully when:
 *
 * - incident date equals today
 * - incident date is historical
 *
 * These tests validate acceptable
 * chronological scenarios.
 *
 * ---------------------------------------------------------
 * NULL VALUE TESTING
 * ---------------------------------------------------------
 *
 * Some intake workflows may not yet know
 * the incident date at record creation time.
 *
 * These tests ensure:
 *
 * - null values do not trigger errors
 * - optional intake behavior works correctly
 * - validation logic is null-safe
 *
 * ---------------------------------------------------------
 * BULKIFICATION VALIDATION
 * ---------------------------------------------------------
 *
 * Bulk tests verify:
 *
 * - valid records succeed
 * - invalid records fail independently
 * - partial-save behavior works correctly
 * - trigger logic remains bulk-safe
 *
 * Database.insert(records, false) is used
 * to validate partial success behavior.
 *
 * ---------------------------------------------------------
 * UPDATE VALIDATION TESTING
 * ---------------------------------------------------------
 *
 * Tests verify existing claims cannot later
 * be modified into invalid future dates.
 *
 * This ensures:
 *
 * - long-term data integrity
 * - update safety
 * - consistent trigger enforcement
 *
 * ---------------------------------------------------------
 * ERROR HANDLING VALIDATION
 * ---------------------------------------------------------
 *
 * Exception handling tests confirm:
 *
 * - DmlException is thrown correctly
 * - validation messaging is user-friendly
 * - trigger addError() logic executes properly
 *
 * ---------------------------------------------------------
 * TESTING STRATEGY
 * ---------------------------------------------------------
 *
 * This class follows Apex testing best practices:
 *
 * - isolated test methods
 * - reusable TestDataFactory utilities
 * - positive and negative testing
 * - edge-case validation
 * - bulk-processing validation
 * - exception verification
 *
 * ---------------------------------------------------------
 * DEPENDENCIES
 * ---------------------------------------------------------
 *
 * This class depends on:
 *
 * - ClaimTriggerHandler.validateIncidentDate()
 * - Claim__c object
 * - Incident_Date__c field
 * - TestDataFactory helper methods
 *
 * ---------------------------------------------------------
 * EXPECTED AUTOMATION BEHAVIOR
 * ---------------------------------------------------------
 *
 * The tested automation is expected to:
 *
 * - reject future incident dates
 * - allow valid historical dates
 * - allow current dates
 * - allow null values
 * - enforce validation during updates
 * - process bulk operations safely
 * - provide meaningful validation messages
 *
 * ---------------------------------------------------------
 * NOTES
 * ---------------------------------------------------------
 *
 * - This class uses @isTest and does not count
 *   against Apex storage limits.
 *
 * - Tests run in isolated transactions and do not
 *   access production organization data.
 *
 * - Assertions validate both technical correctness
 *   and business-rule enforcement.
 *
 * =========================================================
 */
@isTest
private class IntakeValidationTest {

    /*
     * =========================================================
     * FUTURE DATE VALIDATION TESTS
     * =========================================================
     */

    /**
     * Verifies validation prevents inserting
     * claims with future incident dates.
     */
    @isTest
    static void testFutureIncidentDateFailsValidation() {

        Claim__c claim =
            TestDataFactory.createOpenClaim();

        claim.Incident_Date__c =
            Date.today().addDays(5);

        Test.startTest();

        try {

            insert claim;

            System.assert(
                false,
                'Expected validation error for future incident date'
            );

        } catch (DmlException e) {

            System.assert(
                e.getMessage().contains(
                    'Incident Date cannot be in the future'
                ),
                'Validation message should match trigger error'
            );
        }

        Test.stopTest();
    }

    /*
     * =========================================================
     * VALID DATE TESTS
     * =========================================================
     */

    /**
     * Verifies claims save successfully
     * when incident date is today.
     */
    @isTest
    static void testTodayIncidentDateSucceeds() {

        Claim__c claim =
            TestDataFactory.createOpenClaim();

        claim.Incident_Date__c =
            Date.today();

        Test.startTest();
        insert claim;
        Test.stopTest();

        Claim__c insertedClaim = [
            SELECT Incident_Date__c
            FROM Claim__c
            WHERE Id = :claim.Id
        ];

        System.assertEquals(
            Date.today(),
            insertedClaim.Incident_Date__c,
            'Today should be accepted as valid incident date'
        );
    }

    /**
     * Verifies claims save successfully
     * when incident date is in the past.
     */
    @isTest
    static void testPastIncidentDateSucceeds() {

        Claim__c claim =
            TestDataFactory.createOpenClaim();

        claim.Incident_Date__c =
            Date.today().addDays(-10);

        Test.startTest();
        insert claim;
        Test.stopTest();

        Claim__c insertedClaim = [
            SELECT Incident_Date__c
            FROM Claim__c
            WHERE Id = :claim.Id
        ];

        System.assertEquals(
            Date.today().addDays(-10),
            insertedClaim.Incident_Date__c,
            'Past dates should be accepted'
        );
    }

    /*
     * =========================================================
     * NULL DATE TESTS
     * =========================================================
     */

    /**
     * Verifies null incident dates
     * do not trigger validation logic.
     */
    @isTest
    static void testNullIncidentDateSucceeds() {

        Claim__c claim =
            TestDataFactory.createOpenClaim();

        claim.Incident_Date__c = null;

        Test.startTest();
        insert claim;
        Test.stopTest();

        Claim__c insertedClaim = [
            SELECT Incident_Date__c
            FROM Claim__c
            WHERE Id = :claim.Id
        ];

        System.assertEquals(
            null,
            insertedClaim.Incident_Date__c,
            'Null incident dates should be allowed by handler'
        );
    }

    /*
     * =========================================================
     * BULK VALIDATION TESTS
     * =========================================================
     */

    /**
     * Verifies bulk inserts correctly validate
     * future incident dates while allowing valid records.
     */
    @isTest
    static void testBulkIncidentDateValidation() {

        List<Claim__c> claims =
            new List<Claim__c>();

        Claim__c validClaim =
            TestDataFactory.createOpenClaim();

        validClaim.Incident_Date__c =
            Date.today();

        claims.add(validClaim);

        Claim__c invalidClaim =
            TestDataFactory.createOpenClaim();

        invalidClaim.Incident_Date__c =
            Date.today().addDays(3);

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
            'Future incident date should fail validation'
        );

        System.assert(
            results[1].getErrors()[0]
                .getMessage()
                .contains('Incident Date cannot be in the future'),
            'Bulk validation should return correct error message'
        );
    }

    /*
     * =========================================================
     * UPDATE VALIDATION TESTS
     * =========================================================
     */

    /**
     * Verifies updates cannot change
     * incident dates into the future.
     */
    @isTest
    static void testUpdateFutureIncidentDateFails() {

        Claim__c claim =
            TestDataFactory.createOpenClaim();

        claim.Incident_Date__c =
            Date.today();

        insert claim;

        claim.Incident_Date__c =
            Date.today().addDays(7);

        Test.startTest();

        try {

            update claim;

            System.assert(
                false,
                'Expected validation failure during update'
            );

        } catch (DmlException e) {

            System.assert(
                e.getMessage().contains(
                    'Incident Date cannot be in the future'
                ),
                'Update validation should enforce future-date restriction'
            );
        }

        Test.stopTest();
    }
}
