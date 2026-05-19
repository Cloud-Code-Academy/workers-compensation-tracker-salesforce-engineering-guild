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