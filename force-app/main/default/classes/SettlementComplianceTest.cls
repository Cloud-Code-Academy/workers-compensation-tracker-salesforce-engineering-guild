/**
 * Unit tests for settlement compliance validation rules.
 *
 * Acceptance Criteria:
 * - Claim cannot be marked as Settled
 *   if Settlement_Amount__c is:
 *      1. Null
 *      2. Equal to 0
 */
@IsTest
private class SettlementComplianceTest {

    /*
     * =========================================================
     * NULL SETTLEMENT AMOUNT TESTS
     * =========================================================
     */

    /**
     * Verifies validation prevents claims
     * from being settled with null settlement amount.
     */
    @IsTest
    static void testSettledStatusFailsWithNullSettlementAmount() {

        Claim__c claim =
            TestDataFactory.createOpenClaim();

        insert claim;

        claim.Status__c = 'Settled';
        claim.Settlement_Amount__c = null;

        Test.startTest();

        try {

            update claim;

            System.assert(
                false,
                'Expected validation error for null settlement amount'
            );

        } catch (DmlException e) {

            System.assert(
                e.getMessage().contains('Settlement'),
                'Validation message should reference settlement amount'
            );
        }

        Test.stopTest();
    }

    /*
     * =========================================================
     * ZERO SETTLEMENT AMOUNT TESTS
     * =========================================================
     */

    /**
     * Verifies validation prevents claims
     * from being settled with zero settlement amount.
     */
    @IsTest
    static void testSettledStatusFailsWithZeroSettlementAmount() {

        Claim__c claim =
            TestDataFactory.createOpenClaim();

        insert claim;

        claim.Status__c = 'Settled';
        claim.Settlement_Amount__c = 0;

        Test.startTest();

        try {

            update claim;

            System.assert(
                false,
                'Expected validation error for zero settlement amount'
            );

        } catch (DmlException e) {

            System.assert(
                e.getMessage().contains('Settlement'),
                'Validation message should reference settlement amount'
            );
        }

        Test.stopTest();
    }

    /*
     * =========================================================
     * POSITIVE SETTLEMENT TESTS
     * =========================================================
     */

    /**
     * Verifies valid settlement amount
     * allows claim to be settled successfully.
     */
    @IsTest
    static void testSettledStatusSucceedsWithValidSettlementAmount() {

        Claim__c claim =
            TestDataFactory.createOpenClaim();

        insert claim;

        claim.Status__c = 'Settled';
        claim.Settlement_Amount__c = 5000;

        Test.startTest();
        update claim;
        Test.stopTest();

        Claim__c updatedClaim = [
            SELECT
                Status__c,
                Settlement_Amount__c
            FROM Claim__c
            WHERE Id = :claim.Id
        ];

        System.assertEquals(
            'Settled',
            updatedClaim.Status__c,
            'Claim should successfully move to Settled status'
        );

        System.assertEquals(
            5000,
            updatedClaim.Settlement_Amount__c,
            'Settlement amount should save correctly'
        );
    }

    /*
     * =========================================================
     * NEGATIVE VALUE EDGE CASE TESTS
     * =========================================================
     */

    /**
     * Verifies negative settlement amounts
     * are blocked if validation rules exist.
     */
    @IsTest
    static void testSettledStatusFailsWithNegativeSettlementAmount() {

        Claim__c claim =
            TestDataFactory.createOpenClaim();

        insert claim;

        claim.Status__c = 'Settled';
        claim.Settlement_Amount__c = -100;

        Test.startTest();

        try {

            update claim;

            System.assert(
                false,
                'Expected validation error for negative settlement amount'
            );

        } catch (DmlException e) {

            System.assert(
                true,
                'Negative settlement validation triggered successfully'
            );
        }

        Test.stopTest();
    }

    /*
     * =========================================================
     * BULK VALIDATION TESTS
     * =========================================================
     */

    /**
     * Verifies bulk updates enforce
     * settlement validation consistently.
     */
    @IsTest
    static void testBulkSettlementComplianceValidation() {

        List<Claim__c> claims =
            TestDataFactory.createBulkClaims(3, 1000);

        insert claims;

        claims[0].Status__c = 'Settled';
        claims[0].Settlement_Amount__c = null;

        claims[1].Status__c = 'Settled';
        claims[1].Settlement_Amount__c = 0;

        claims[2].Status__c = 'Settled';
        claims[2].Settlement_Amount__c = 5000;

        Test.startTest();

        Database.SaveResult[] results =
            Database.update(claims, false);

        Test.stopTest();

        System.assertEquals(
            false,
            results[0].isSuccess(),
            'Null settlement amount should fail validation'
        );

        System.assertEquals(
            false,
            results[1].isSuccess(),
            'Zero settlement amount should fail validation'
        );

        System.assertEquals(
            true,
            results[2].isSuccess(),
            'Valid settlement amount should succeed'
        );
    }
}