# PL/SQL Procedure `duplicate_risk` Change Analysis Report

This report analyzes the changes made to the PL/SQL procedure `duplicate_risk` between the HERITAGE and NEW_GEMINIA versions.

## Summary of Key Changes:

### Reordering of Conditional Logic:

- **HERITAGE Version:** The HERITAGE version lacked any conditional logic within the procedure.  All INSERT statements were executed unconditionally.

- **NEW_GEMINIA Version:** The NEW_GEMINIA version introduces a conditional statement (`IF v_is_motor_risk = 'Y' THEN ... END IF;`). This conditional logic now controls the execution of a block of code that calls the `gin_stp_uw_pkg.populate_cert_to_print` procedure, responsible for certificate allocation.  This means certificate allocation is now dependent on the `SCL_MOTOR_VERIFY` flag.

### Modification of WHERE Clauses:

- **Removal and Addition of Conditions:** No conditions were removed from the `WHERE` clauses in the heritage version.  The NEW_GEMINIA version maintains the original `WHERE` clauses but adds a new `WHERE` clause to the initial `SELECT` statement to retrieve `IPU_POL_BATCH_NO` and `SCL_MOTOR_VERIFY` from the `GIN_INSURED_PROPERTY_UNDS` and `GIN_SUB_CLASSES` tables. This is crucial for the conditional logic introduced.

### Exception Handling Adjustments:

- **HERITAGE Version:** The HERITAGE version had no explicit exception handling.

- **NEW_GEMINIA Version:** The NEW_GEMINIA version includes a `BEGIN ... EXCEPTION ... END;` block within the conditional statement. This handles potential errors during the certificate allocation process (`gin_stp_uw_pkg.populate_cert_to_print`) by raising a custom error message including the underlying SQL error.

### Formatting and Indentation:

- The NEW_GEMINIA version shows significant improvements in formatting and indentation, making the code much more readable and maintainable.  The HERITAGE version is less structured.  Column names are now broken across multiple lines for improved readability in the INSERT statements.


## Implications of the Changes:

### Logic Alteration in Fee Determination:

- **Priority Shift:** The HERITAGE version implicitly assumed that certificate allocation always happened. The NEW_GEMINIA version makes certificate allocation conditional upon the `SCL_MOTOR_VERIFY` flag indicating a motor risk.

- **Potential Outcome Difference:**  Before, certificates were always allocated. Now, certificates are only allocated for motor risks ('Y'). This could lead to different numbers of certificates being generated, potentially impacting downstream processes and reporting.

### Business Rule Alignment:

The change in NEW_GEMINIA aligns with a new business rule where certificate allocation is now a conditional process, dependent on the type of risk (motor or non-motor). The HERITAGE version did not reflect this rule.

### Impact on Clients:

The change might not directly impact clients unless the certificate allocation process is directly visible to them (e.g., through online portals).  However, indirectly, it could affect the accuracy of their policy documents if the certificate allocation is linked to other policy information.


## Recommendations for Merging:

### Review Business Requirements:

- **Confirm Intent:** Verify that the conditional logic for certificate allocation accurately reflects the current business requirements.  Confirm the intended behavior for both motor and non-motor risks.

### Consult Stakeholders:

Discuss the implications of the changes with stakeholders (business analysts, testers, and users) to ensure everyone understands the new behavior and its potential impact.

### Test Thoroughly:

- **Create Test Cases:** Develop comprehensive test cases covering both motor and non-motor risk scenarios to validate the correctness of the conditional logic and exception handling.  Test cases should include scenarios where the `gin_stp_uw_pkg.populate_cert_to_print` procedure might fail.

- **Validate Outcomes:**  Verify that the number of certificates generated and other related data are accurate and consistent with the expected outcomes for both scenarios.

### Merge Strategy:

- **Conditional Merge:**  A direct merge is possible, but thorough testing is crucial.

- **Maintain Backward Compatibility:**  Consider adding a parameter to control the conditional logic if backward compatibility with the HERITAGE version is required for a phased rollout.

### Update Documentation:

Update the package documentation to reflect the changes in the procedure's logic, including the conditional certificate allocation and exception handling.

### Code Quality Improvements:

- **Consistent Exception Handling:**  While the NEW_GEMINIA version includes exception handling, consider implementing a more robust and centralized exception-handling mechanism for the entire package.

- **Clean Up Code:**  Maintain the improved formatting and indentation consistently throughout the package.


## Potential Actions Based on Analysis:

- **If the Change Aligns with Business Goals:** Merge the NEW_GEMINIA version after thorough testing and documentation updates.

- **If the Change Does Not Align:** Revert the changes and investigate why the business requirements were not correctly implemented.

- **If Uncertain:** Conduct further analysis and discussions with stakeholders to clarify the business requirements and intended behavior before merging.


## Additional Considerations:

- **Database Integrity:** Ensure that the changes do not compromise database integrity.  The addition of the conditional logic should not introduce data inconsistencies.

- **Performance Impact:** Assess the performance impact of the added conditional logic and exception handling, especially for high-volume processing.

- **Error Messages:** The error message in the exception handler should be informative and helpful for debugging and troubleshooting.  Consider logging the error details for later analysis.


## Conclusion:

The changes in the `duplicate_risk` procedure introduce important conditional logic and exception handling, aligning the procedure with updated business rules regarding certificate allocation.  However, a thorough review of business requirements, consultation with stakeholders, and rigorous testing are crucial before merging the NEW_GEMINIA version to ensure the changes are correctly implemented and do not introduce unintended consequences.  The improved formatting and indentation are positive changes that enhance code readability and maintainability.
