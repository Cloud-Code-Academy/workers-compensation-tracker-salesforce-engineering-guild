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
private class TestDataFactory {
    
        /*
         * =========================================================
         * CORE ACCOUNT + CONTACT METHODS
         * =========================================================
         */
    
        public static Account createAccount() {
            // Creates default insurance/provider account
            Account acc = new Account(Name = 'Test Account');
            return acc;
        }
    
        public static Contact createContact(Id accountId) {
            // Creates contact tied to account
            Contact con = new Contact(LastName = 'Test Contact', AccountId = accountId);
            return con;
        }
    
        /*
         * =========================================================
         * EMPLOYEE METHODS
         * =========================================================
         */
    
        public static Employee__c createEmployee() {
            // Creates standard employee test record
            Employee__c emp = new Employee__c(Name = 'Test Employee');
            return emp;
        }
    
        public static Employee__c createHighRiskEmployee() {
            // Creates employee preconfigured for risk testing
            Employee__c emp = new Employee__c(Name = 'High Risk Employee', Risk_Level__c = 'High');
            return emp;
        }
    
        public static List<Employee__c> createEmployees(Integer count) {
            // Bulk employee creation helper
            List<Employee__c> emps = new List<Employee__c>();
            for (Integer i = 0; i < count; i++) {
                emps.add(new Employee__c(Name = 'Test Employee ' + i));
            }
            return emps;
        }
    
        /*
         * =========================================================
         * CLAIM METHODS
         * =========================================================
         */
    
        public static Claim__c createClaim() {
            // Creates default open claim
            Claim__c claim = new Claim__c(Status__c = 'Open', Payout_Amount__c = 1000);
            return claim;
        }
    
        public static Claim__c createSettledClaim() {
            // Creates settled claim with payout and settlement date
            Claim__c claim = new Claim__c(Status__c = 'Settled', Payout_Amount__c = 5000, Settlement_Date__c = Date.today());
            return claim;
        }
    
        public static Claim__c createHighValueClaim() {
            // Creates claim above high-value threshold
            Claim__c claim = new Claim__c(Status__c = 'Open', Payout_Amount__c = 10000);
            return claim;
        }
    
        public static Claim__c createMediumRiskClaim() {
            // Creates moderate payout claim for scoring tests
            Claim__c claim = new Claim__c(Status__c = 'Open', Payout_Amount__c = 3000);
            return claim;
        }
    
        public static Claim__c createLowRiskClaim() {
            // Creates small payout claim
            Claim__c claim = new Claim__c(Status__c = 'Open', Payout_Amount__c = 500);
            return claim;
        }
    
        public static List<Claim__c> createClaims(Integer count) {
            // Bulk claim creation helper
            List<Claim__c> claims = new List<Claim__c>();
            for (Integer i = 0; i < count; i++) {
                claims.add(new Claim__c(Status__c = 'Open', Payout_Amount__c = 1000));
            }
            return claims;
        }
    
        /*
         * =========================================================
         * JUNCTION OBJECT METHODS
         * =========================================================
         */
    
        public static Employee_Claim__c createEmployeeClaim(
            Id employeeId,
            Id claimId
        ) {
            // Links employee to claim
            return new Employee_Claim__c(Employee__c = employeeId, Claim__c = claimId);
        }
    
        public static List<Employee_Claim__c> createEmployeeClaims(
            List<Employee__c> employees,
            List<Claim__c> claims
        ) {
            // Bulk junction creation helper
            List<Employee_Claim__c> junctions = new List<Employee_Claim__c>();
            for (Integer i = 0; i < Math.min(employees.size(), claims.size()); i++) {
                junctions.add(new Employee_Claim__c(Employee__c = employees[i].Id, Claim__c = claims[i].Id));
            }
            return junctions;
        }
    
        /*
         * =========================================================
         * RISK SCENARIO HELPERS
         * =========================================================
         */
    /*
        public static Employee__c createEmployeeWithMultipleClaims(
            Integer claimCount,
            Decimal payoutAmount
        ) {
            // Creates employee with configurable risk profile
            Employee__c emp = createEmployee();
            List<Claim__c> claims = new List<Claim__c>();
            for (Integer i = 0; i < claimCount; i++) {
                claims.add(new Claim__c(Status__c = 'Open', Payout_Amount__c = payoutAmount));
            }
            insert emp;
            for (Claim__c c : claims) {
                c.Employee__c = emp.Id;
                }
            insert claims;
        }
    
        public static Employee__c createHighRiskScenario() {
            // Creates employee + multiple large claims
            return createEmployeeWithMultipleClaims(5, 10000);
        }
    
        public static Employee__c createMediumRiskScenario() {
            // Creates employee + moderate claims
            return createEmployeeWithMultipleClaims(3, 3000);
        }
    
        public static Employee__c createStandardRiskScenario() {
            // Creates employee + minimal claim activity
            return createEmployeeWithMultipleClaims(1, 500);
        }
    */
        /*
         * =========================================================
         * CLAIM STATUS SCENARIO HELPERS
         * =========================================================
         */
    
        public static Claim__c createOpenClaim() {
            // Creates claim in Open status
            return new Claim__c(Status__c = 'Open', Payout_Amount__c = 1000);
        }
    
        public static Claim__c createUnderReviewClaim() {
            // Creates claim in Under Review status
            return new Claim__c(Status__c = 'Under Review', Payout_Amount__c = 1000);
        }
    
        public static Claim__c createRejectedClaim() {
            // Creates rejected claim
            return new Claim__c(Status__c = 'Rejected', Payout_Amount__c = 0);
        }
    
        /*
         * =========================================================
         * EDGE CASE HELPERS
         * =========================================================
         */
    
        public static Claim__c createClaimWithNullPayout() {
            // Creates claim without payout amount
            return new Claim__c(Status__c = 'Open');
        }
    
        public static Claim__c createInvalidDateClaim() {
            // Creates intentionally invalid date scenario
            return new Claim__c(Status__c = 'Open', Settlement_Date__c = Date.newInstance(1900, 1, 1));
        }
    
        public static Employee__c createDuplicateNamedEmployee() {
            // Used for duplicate/identity edge case testing
            return new Employee__c(Name = 'Test Employee');
        }
    
        /*
         * =========================================================
         * BULK TEST HELPERS
         * =========================================================
         */
    
        public static List<Claim__c> createBulkClaims(
            Integer count,
            Decimal payoutAmount
        ) {
            // Creates large claim dataset for governor testing
            List<Claim__c> claims = new List<Claim__c>();
            for (Integer i = 0; i < count; i++) {
                claims.add(new Claim__c(Status__c = 'Open', Payout_Amount__c = payoutAmount));
            }
            return claims;
        }
    
        public static List<Employee__c> createBulkEmployees(Integer count) {
            // Creates large employee dataset
            List<Employee__c> emps = new List<Employee__c>();
            for (Integer i = 0; i < count; i++) {
                emps.add(new Employee__c(Name = 'Bulk Employee ' + i));
            }
            return emps;
        }
    }
