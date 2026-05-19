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
private class HighValueClaimTest {

    /*
     * =========================================================
     * POSITIVE HIGH VALUE TESTS
     * =========================================================
     */

    @IsTest
    static void testHighValueClaimFlaggedOnInsert() {

        Claim__c claim =
            TestDataFactory.createHighValueClaim();

        Test.startTest();
        insert claim;
        Test.stopTest();

        Claim__c insertedClaim = [
            SELECT
                Settlement_Amount__c,
                High_Value_Claim__c
            FROM Claim__c
            WHERE Id = :claim.Id
        ];

        System.assertEquals(
            10000,
            insertedClaim.Settlement_Amount__c,
            'Claim should retain settlement amount'
        );

        System.assertEquals(
            true,
            insertedClaim.High_Value_Claim__c,
            'High-value claim should be flagged automatically'
        );
    }

    /*
     * =========================================================
     * NEGATIVE THRESHOLD TESTS
     * =========================================================
     */

    @IsTest
    static void testLowValueClaimNotFlagged() {

        Claim__c claim =
            TestDataFactory.createLowRiskClaim();

        Test.startTest();
        insert claim;
        Test.stopTest();

        Claim__c insertedClaim = [
            SELECT
                Settlement_Amount__c,
                High_Value_Claim__c
            FROM Claim__c
            WHERE Id = :claim.Id
        ];

        System.assertEquals(
            500,
            insertedClaim.Settlement_Amount__c,
            'Claim should retain low settlement amount'
        );

        System.assertEquals(
            false,
            insertedClaim.High_Value_Claim__c,
            'Low-value claims should not be flagged'
        );
    }

    /*
     * =========================================================
     * EXACT THRESHOLD TESTS
     * =========================================================
     */

    @IsTest
    static void testExactThresholdClaimFlagging() {

        Claim__c claim =
            TestDataFactory.createClaim(
                'Open',
                5000
            );

        Test.startTest();
        insert claim;
        Test.stopTest();

        Claim__c insertedClaim = [
            SELECT
                Settlement_Amount__c,
                High_Value_Claim__c
            FROM Claim__c
            WHERE Id = :claim.Id
        ];

        System.assertEquals(
            5000,
            insertedClaim.Settlement_Amount__c,
            'Claim should equal exact threshold amount'
        );

        System.assertEquals(
            true,
            insertedClaim.High_Value_Claim__c,
            'Claims meeting threshold should be flagged'
        );
    }

    /*
     * =========================================================
     * BELOW THRESHOLD EDGE CASE
     * =========================================================
     */

    @IsTest
    static void testBelowThresholdClaimNotFlagged() {

        Claim__c claim =
            TestDataFactory.createClaim(
                'Open',
                4999
            );

        Test.startTest();
        insert claim;
        Test.stopTest();

        Claim__c insertedClaim = [
            SELECT
                Settlement_Amount__c,
                High_Value_Claim__c
            FROM Claim__c
            WHERE Id = :claim.Id
        ];

        System.assertEquals(
            4999,
            insertedClaim.Settlement_Amount__c,
            'Claim should remain below threshold'
        );

        System.assertEquals(
            false,
            insertedClaim.High_Value_Claim__c,
            'Claims below threshold should not be flagged'
        );
    }

    /*
     * =========================================================
     * UPDATE FLAGGING TESTS
     * =========================================================
     */

     @IsTest
    static void testClaimBecomesHighValueAfterUpdate() {

        Claim__c claim =
            TestDataFactory.createLowRiskClaim();

        insert claim;

        claim.Settlement_Amount__c = 12000;

        Test.startTest();
        update claim;
        Test.stopTest();

        Claim__c updatedClaim = [
            SELECT
                Settlement_Amount__c,
                High_Value_Claim__c
            FROM Claim__c
            WHERE Id = :claim.Id
        ];

        System.assertEquals(
            12000,
            updatedClaim.Settlement_Amount__c,
            'Settlement amount should update correctly'
        );

        System.assertEquals(
            true,
            updatedClaim.High_Value_Claim__c,
            'Claim should become flagged after threshold increase'
        );
    }

    /*
     * =========================================================
     * FLAG REMOVAL TESTS
     * =========================================================
     */

     @IsTest
    static void testClaimLosesHighValueFlagAfterReduction() {

        Claim__c claim =
            TestDataFactory.createHighValueClaim();

        insert claim;

        claim.Settlement_Amount__c = 1000;

        Test.startTest();
        update claim;
        Test.stopTest();

        Claim__c updatedClaim = [
            SELECT
                Settlement_Amount__c,
                High_Value_Claim__c
            FROM Claim__c
            WHERE Id = :claim.Id
        ];

        System.assertEquals(
            1000,
            updatedClaim.Settlement_Amount__c,
            'Settlement amount should reduce correctly'
        );

        System.assertEquals(
            false,
            updatedClaim.High_Value_Claim__c,
            'Claim should lose high-value flag after reduction'
        );
    }

    /*
     * =========================================================
     * NULL VALUE EDGE CASES
     * =========================================================
     */

     @IsTest
    static void testNullSettlementAmountNotFlagged() {

        Claim__c claim =
            TestDataFactory.createClaimWithNullPayout();

        Test.startTest();
        insert claim;
        Test.stopTest();

        Claim__c insertedClaim = [
            SELECT
                Settlement_Amount__c,
                High_Value_Claim__c
            FROM Claim__c
            WHERE Id = :claim.Id
        ];

        System.assertEquals(
            null,
            insertedClaim.Settlement_Amount__c,
            'Settlement amount should remain null'
        );

        System.assertEquals(
            false,
            insertedClaim.High_Value_Claim__c,
            'Null payouts should never be flagged as high value'
        );
    }

    /*
     * =========================================================
     * BULK FLAGGING TESTS
     * =========================================================
     */

     @IsTest
    static void testBulkHighValueFlagging() {

        List<Claim__c> claims = new List<Claim__c>{

            TestDataFactory.createClaim(
                'Open',
                1000
            ),

            TestDataFactory.createClaim(
                'Open',
                5000
            ),

            TestDataFactory.createClaim(
                'Open',
                15000
            ),

            TestDataFactory.createClaim(
                'Open',
                3000
            )

        };

        Test.startTest();
        insert claims;
        Test.stopTest();

        List<Claim__c> insertedClaims = [
            SELECT
                Settlement_Amount__c,
                High_Value_Claim__c
            FROM Claim__c
            WHERE Id IN :claims
            ORDER BY Settlement_Amount__c ASC
        ];

        for (Claim__c c : insertedClaims) {

            if (c.Settlement_Amount__c >= 5000) {

                System.assertEquals(
                    true,
                    c.High_Value_Claim__c,
                    'Claims at or above threshold should be flagged'
                );

            } else {

                System.assertEquals(
                    false,
                    c.High_Value_Claim__c,
                    'Claims below threshold should not be flagged'
                );
            }
        }
    }
}