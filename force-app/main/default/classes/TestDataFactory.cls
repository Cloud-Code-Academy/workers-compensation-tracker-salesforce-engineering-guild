/**
 * =========================================================
 * TEST DATA FACTORY
 * =========================================================
 *
 * Centralized test data utility class used to generate reusable,
 * consistent, and maintainable test records across Apex unit tests.
 *
 * This factory supports creation of:
 * - Accounts
 * - Contacts
 * - Employees
 * - Claims
 * - Employee Claim junction records
 * - Risk scoring scenarios
 * - Bulk testing datasets
 * - Edge case and invalid records
 *
 * ---------------------------------------------------------
 * PURPOSE
 * ---------------------------------------------------------
 *
 * TestDataFactory reduces duplicate setup logic inside test
 * classes by providing reusable helper methods for generating
 * common testing scenarios.
 *
 * Benefits include:
 * - Cleaner test classes
 * - Consistent test data creation
 * - Easier maintenance
 * - Reduced code duplication
 * - Improved readability
 * - Faster test development
 *
 * ---------------------------------------------------------
 * DESIGN PRINCIPLES
 * ---------------------------------------------------------
 *
 * This factory follows Salesforce Apex testing best practices:
 *
 * - Methods return records without automatically inserting
 *   unless explicitly required for relationship setup.
 *
 * - Helper methods are grouped by functional domain:
 *      * Core objects
 *      * Claim scenarios
 *      * Risk scenarios
 *      * Bulk testing
 *      * Edge cases
 *
 * - Scenario-based helpers provide realistic business cases
 *   used across trigger and service-layer tests.
 *
 * ---------------------------------------------------------
 * INSERTION STRATEGY
 * ---------------------------------------------------------
 *
 * Most methods return NON-INSERTED sObjects so test methods
 * can control:
 * - DML timing
 * - governor limit usage
 * - transaction scope
 * - bulk testing behavior
 *
 * Some helper methods intentionally perform inserts when:
 * - relationship IDs are required
 * - complete scenarios must exist in database state
 * - junction records depend on persisted parents
 *
 * ---------------------------------------------------------
 * MAJOR TESTING SCENARIOS SUPPORTED
 * ---------------------------------------------------------
 *
 * EMPLOYEE TESTING
 * - Standard employees
 * - High-risk employees
 * - Duplicate-name scenarios
 * - Missing required field validation
 * - Bulk employee generation
 *
 * CLAIM TESTING
 * - Open claims
 * - Settled claims
 * - Under review claims
 * - Denied claims
 * - High-value claims
 * - Null payout claims
 * - Invalid date scenarios
 * - Bulk claim generation
 *
 * RELATIONSHIP TESTING
 * - Employee-to-Claim junction creation
 * - Multiple claim ownership scenarios
 * - Risk profile generation
 *
 * RISK SCENARIO TESTING
 * - High-risk employees with many large claims
 * - Medium-risk employees
 * - Standard/low-risk employees
 *
 * BULK TESTING
 * - Large employee datasets
 * - Large claim datasets
 * - Governor limit validation support
 *
 * ---------------------------------------------------------
 * USAGE EXAMPLES
 * ---------------------------------------------------------
 *
 * Example: Create and insert an open claim
 *
 *     Claim__c claim =
 *         TestDataFactory.createOpenClaim();
 *
 *     insert claim;
 *
 * Example: Create employee with multiple claims
 *
 *     Employee__c emp =
 *         TestDataFactory.createHighRiskScenario();
 *
 * Example: Bulk claim creation
 *
 *     List<Claim__c> claims =
 *         TestDataFactory.createBulkClaims(200, 5000);
 *
 * ---------------------------------------------------------
 * TESTING BEST PRACTICES
 * ---------------------------------------------------------
 *
 * Recommended usage:
 * - Use helper methods instead of inline record creation
 * - Keep assertions inside test classes, not factory methods
 * - Use scenario methods for readability
 * - Use bulk helpers for governor limit coverage
 *
 * Avoid:
 * - Hardcoding repetitive test data in test classes
 * - Embedding assertions inside factory methods
 * - Overloading factory methods with business logic
 *
 * ---------------------------------------------------------
 * NOTES
 * ---------------------------------------------------------
 *
 * - This class is annotated with @IsTest and does not count
 *   against Apex organization storage limits.
 *
 * - Factory methods are static to allow direct access from
 *   any test class without instantiation.
 *
 * - This class is intended strictly for test support and
 *   should never contain production business logic.
 *
 * =========================================================
 */

 @IsTest
public class TestDataFactory {
    
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
    
        public static Employee__c createEmployeeWithoutName() {
            return new Employee__c();
        }

        /*
         * =========================================================
         * CLAIM METHODS
         * =========================================================
         */
    
         public static Claim__c createClaim(
            String status,
            Decimal amount
        ) {
            return new Claim__c(
                Status__c = status,
                Settlement_Amount__c = amount
            );
        }    

        public static Claim__c createSettledClaim() {
            // Creates settled claim without payout and settlement date
            Claim__c claim = new Claim__c(Status__c = 'Settled', Settlement_Amount__c = 5000, Settlement_Date__c = Date.today());
            return claim;
        }
    
        public static Claim__c createHighValueClaim() {
            // Creates claim settlement above high-value threshold
            Claim__c claim = new Claim__c(Status__c = 'Open', Settlement_Amount__c = 10000);
            return claim;
        }
    
        public static Claim__c createMediumRiskClaim() {
            // Creates moderate settlement claim for scoring tests
            Claim__c claim = new Claim__c(Status__c = 'Open', Settlement_Amount__c = 3000);
            return claim;
        }
    
        public static Claim__c createLowRiskClaim() {
            // Creates small settlement claim
            Claim__c claim = new Claim__c(Status__c = 'Open', Settlement_Amount__c = 500);
            return claim;
        }
    
        public static List<Claim__c> createClaims(Integer count) {
            // Bulk claim creation helper
            List<Claim__c> claims = new List<Claim__c>();
            for (Integer i = 0; i < count; i++) {
                claims.add(new Claim__c(Status__c = 'Open', Settlement_Amount__c = 1000));
            }
            return claims;
        }

        public static Claim__c createInvalidClaim() {
            return new Claim__c();
        }

        /*
         * =========================================================
         * JUNCTION OBJECT METHODS
         * =========================================================
         */

         public static Employee__c createEmployeeWithClaim(            
            String status,
            Decimal amount
     )  {
            Employee__c emp = createEmployee();
            insert emp;
        
            Claim__c claim = createClaim(status, amount);
            insert claim;
        
            insert createEmployeeClaim(emp.Id, claim.Id);
        
            return emp;
        }

        public static Employee_Claim__c createEmployeeClaim(
            Id employeeId,
            Id claimId
        ) {
            // Links employee to claim
            return new Employee_Claim__c(Employee__c = employeeId, Claim__c = claimId);
        }


/**
 * =========================================================
 * createEmployeeClaims
 * =========================================================
 *
 * Creates a bulk collection of Employee_Claim__c junction
 * records that associate Employees with Claims.
 *
 * This helper is primarily used for:
 * - bulk trigger testing
 * - relationship testing
 * - many-record scenario setup
 * - governor limit validation
 *
 * ---------------------------------------------------------
 * PURPOSE
 * ---------------------------------------------------------
 *
 * The Employee_Claim__c object represents a junction
 * relationship between:
 *
 * - Employee__c
 * - Claim__c
 *
 * This method automatically pairs employees and claims
 * together by list index position.
 *
 * Example:
 *
 * employees[0] -> claims[0]
 * employees[1] -> claims[1]
 * employees[2] -> claims[2]
 *
 * ---------------------------------------------------------
 * PARAMETERS
 * ---------------------------------------------------------
 *
 * @param employees
 * A list of Employee__c records.
 *
 * Expected behavior:
 * - Records should already be inserted
 * - IDs must exist for relationship assignment
 *
 * @param claims
 * A list of Claim__c records.
 *
 * Expected behavior:
 * - Records should already be inserted
 * - IDs must exist for relationship assignment
 *
 * ---------------------------------------------------------
 * RETURN VALUE
 * ---------------------------------------------------------
 *
 * @return List<Employee_Claim__c>
 *
 * Returns a list of NON-INSERTED junction records.
 *
 * The calling test method is responsible for:
 * - performing DML
 * - controlling transaction scope
 * - validating behavior
 *
 * ---------------------------------------------------------
 * MATCHING LOGIC
 * ---------------------------------------------------------
 *
 * The method iterates using:
 *
 *     Math.min(employees.size(), claims.size())
 *
 * This prevents index-out-of-bounds exceptions when
 * the input lists have different sizes.
 *
 * Example:
 *
 * employees.size() = 5
 * claims.size()    = 3
 *
 * Only 3 junction records will be created.
 *
 * ---------------------------------------------------------
 * BULKIFICATION
 * ---------------------------------------------------------
 *
 * This method is fully bulkified because:
 *
 * - No SOQL queries are executed
 * - No DML operations occur inside loops
 * - All records are created in memory
 * - Supports large-volume test setup
 *
 * ---------------------------------------------------------
 * USAGE EXAMPLE
 * ---------------------------------------------------------
 *
 *     List<Employee__c> employees =
 *         TestDataFactory.createBulkEmployees(5);
 *
 *     insert employees;
 *
 *     List<Claim__c> claims =
 *         TestDataFactory.createBulkClaims(5, 1000);
 *
 *     insert claims;
 *
 *     List<Employee_Claim__c> junctions =
 *         TestDataFactory.createEmployeeClaims(
 *             employees,
 *             claims
 *         );
 *
 *     insert junctions;
 *
 * ---------------------------------------------------------
 * WHY THIS METHOD IS USEFUL
 * ---------------------------------------------------------
 *
 * Without this helper, every test class would need to:
 *
 * - manually loop through records
 * - create junction objects repeatedly
 * - duplicate setup logic
 *
 * Centralizing this logic improves:
 * - maintainability
 * - readability
 * - consistency
 * - test scalability
 *
 * =========================================================
 */
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
    
        public static Employee__c createEmployeeWithMultipleClaims(
            Integer claimCount,
            Decimal settlementAmount
        ) {
            Employee__c emp = createEmployee();
            insert emp;
        
            List<Claim__c> claims = new List<Claim__c>();
        
            for (Integer i = 0; i < claimCount; i++) {
                claims.add(
                    new Claim__c(
                        Status__c = 'Open',
                        Settlement_Amount__c = settlementAmount
                    )
                );
            }
        
            insert claims;
        
            List<Employee_Claim__c> junctions = new List<Employee_Claim__c>();
        
            for (Claim__c c : claims) {
                junctions.add(
                    new Employee_Claim__c(
                        Employee__c = emp.Id,
                        Claim__c = c.Id
                    )
                );
            }        
            insert junctions;        
            return emp;
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
    
        /*
         * =========================================================
         * CLAIM STATUS SCENARIO HELPERS
         * =========================================================
         */
    
        public static Claim__c createOpenClaim() {
            // Creates claim in Open status
            return new Claim__c(Status__c = 'Open', Settlement_Amount__c = 1000);
        }
    
        public static Claim__c createUnderReviewClaim() {
            // Creates claim in Under Review status
            return new Claim__c(Status__c = 'In Review', Settlement_Amount__c = 1000);
        }
    
        public static Claim__c createRejectedClaim() {
            // Creates Denied claim
            return new Claim__c(Status__c = 'Denied', Settlement_Amount__c = 0);
        }
    
        /*
         * =========================================================
         * EDGE CASE HELPERS
         * =========================================================
         */
    
        public static Claim__c createClaimWithNullPayout() {
            // Creates claim without settlement amount
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
    
/**
 * =========================================================
 * createBulkEmployees
 * =========================================================
 *
 * Creates a bulk collection of Employee__c records for
 * high-volume Apex testing scenarios.
 *
 * This helper supports:
 * - trigger bulk testing
 * - governor limit validation
 * - relationship testing
 * - large dataset simulation
 * - scalability verification
 *
 * ---------------------------------------------------------
 * PURPOSE
 * ---------------------------------------------------------
 *
 * Salesforce executes automation in bulk contexts.
 * This method generates large employee datasets to ensure
 * Apex logic remains efficient and bulk-safe.
 *
 * ---------------------------------------------------------
 * PARAMETERS
 * ---------------------------------------------------------
 *
 * @param count
 * The number of Employee__c records to generate.
 *
 * Example:
 *     200
 *
 * ---------------------------------------------------------
 * RETURN VALUE
 * ---------------------------------------------------------
 *
 * @return List<Employee__c>
 *
 * Returns a list of NON-INSERTED Employee__c records.
 *
 * The calling test controls:
 * - DML execution
 * - transaction boundaries
 * - assertions
 *
 * ---------------------------------------------------------
 * DEFAULT FIELD VALUES
 * ---------------------------------------------------------
 *
 * Each employee is assigned a unique Name value:
 *
 *     Bulk Employee 0
 *     Bulk Employee 1
 *     Bulk Employee 2
 *
 * etc.
 *
 * Unique naming helps:
 * - avoid duplicate confusion
 * - improve debugging readability
 * - simplify assertion tracking
 *
 * ---------------------------------------------------------
 * BULKIFICATION
 * ---------------------------------------------------------
 *
 * This method is fully bulkified because:
 *
 * - No SOQL queries are executed
 * - No DML occurs inside loops
 * - Records are created entirely in memory
 *
 * ---------------------------------------------------------
 * USAGE EXAMPLE
 * ---------------------------------------------------------
 *
 *     List<Employee__c> employees =
 *         TestDataFactory.createBulkEmployees(200);
 *
 *     insert employees;
 *
 * ---------------------------------------------------------
 * WHY THIS METHOD IS IMPORTANT
 * ---------------------------------------------------------
 *
 * Large employee datasets help validate:
 *
 * - trigger scalability
 * - relationship handling
 * - aggregation logic
 * - batch-safe processing
 * - governor limit compliance
 *
 * =========================================================
 */
    
        public static List<Claim__c> createBulkClaims(
            Integer count,
            Decimal settleAmount
        ) {
            // Creates large claim dataset for governor testing
            List<Claim__c> claims = new List<Claim__c>();
            for (Integer i = 0; i < count; i++) {
                claims.add(new Claim__c(Status__c = 'Open', Settlement_Amount__c = settleAmount));
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
