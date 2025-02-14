# PL/SQL Procedure `pop_single_taxes` Change Analysis Report

This report analyzes the changes made to the PL/SQL procedure `pop_single_taxes` between the HERITAGE and NEW_GEMINIA versions.

## Summary of Key Changes

### Reordering of Conditional Logic

**HERITAGE Version:** The HERITAGE version applies a simple conditional check based on `v_add_edit` ('A' for Add, 'E' for Edit) to determine whether to insert or update `gin_policy_taxes`.  The condition for excluding Stamp Duty ('SD') when `v_pol_binder` is 'Y' is nested within the 'A' (Add) condition.

**NEW_GEMINIA Version:** The NEW_GEMINIA version significantly restructures the conditional logic. It introduces additional checks before applying taxes, specifically:
    - Checks if Stamp Duty ('SD') is allowed for Fac Reinsurance policies based on parameter `v_allowsdonfacrein_param`.
    - Checks if Stamp Duty ('SD') is allowed for Co-insurance follower policies based on parameter `v_allowsdoncoinfollower_param`.
    - The `v_add_edit` condition remains, but the logic for adding and editing taxes is separated more clearly.  It also includes a new parameter `v_override_rate` and updates the `gin_policy_taxes` table accordingly.
    - It includes a second loop to handle updates specifically for the 'E' (Edit) case, potentially addressing issues with the original single update statement.


### Modification of WHERE Clauses

**Removal and Addition of Conditions:** The `WHERE` clause in the `UPDATE` statement remains largely the same, but the `INSERT` statement now includes additional fields (`ptx_override`, `ptx_override_amt`) reflecting the new parameter `v_override_rate`.  The `taxes` cursor now explicitly excludes records already present in `gin_policy_taxes` based on `ptx_pol_batch_no` and `ptx_trac_trnt_code`.  A new cursor `edit_taxes` is introduced to handle updates separately, improving clarity and potentially addressing potential issues with the original single update.

### Exception Handling Adjustments

**HERITAGE Version:** The HERITAGE version uses a generic `WHEN OTHERS` exception handler with a simple error message ('Error applying taxes..') for both `INSERT` and `UPDATE` operations.

**NEW_GEMINIA Version:** The NEW_GEMINIA version maintains the generic `WHEN OTHERS` exception handler but adds more specific exception handling for retrieving policy and parameter data.  This improves error reporting and allows for more targeted responses to different error scenarios.


### Formatting and Indentation

The NEW_GEMINIA version shows improved formatting and indentation, making the code more readable and maintainable.  Parameter lists are broken into multiple lines for better readability.


## Implications of the Changes

### Logic Alteration in Fee Determination

**Priority Shift:**
    - **HERITAGE:**  The HERITAGE version prioritizes the `v_add_edit` flag and then considers the Stamp Duty exclusion based on `v_pol_binder`.
    - **NEW_GEMINIA:** The NEW_GEMINIA version prioritizes checks for whether Stamp Duty is allowed based on policy type and parameters (`v_allowsdonfacrein_param`, `v_allowsdoncoinfollower_param`) before considering `v_add_edit` and `v_pol_binder`.

**Potential Outcome Difference:** The changes in conditional logic can lead to different tax calculations, particularly for Stamp Duty on specific policy types (Fac Reinsurance and Co-insurance follower).  The new version introduces business rules that prevent the application of Stamp Duty under certain conditions.

### Business Rule Alignment

The NEW_GEMINIA version introduces new business rules regarding the application of Stamp Duty based on policy type and parameters. This suggests an update to the business requirements or a clarification of existing rules.

### Impact on Clients

The changes might affect clients whose policies fall under the newly introduced restrictions for Stamp Duty application.  This could result in different tax amounts compared to the HERITAGE version.  Clear communication to clients about these changes is crucial.


## Recommendations for Merging

### Review Business Requirements

**Confirm Intent:**  Thoroughly review the business requirements to confirm the intent behind the changes in Stamp Duty application logic.  Verify if the new rules accurately reflect the current business needs.

### Consult Stakeholders

Discuss the changes with stakeholders (business analysts, clients, and other developers) to ensure everyone understands the implications and agrees with the new logic.

### Test Thoroughly

**Create Test Cases:** Create comprehensive test cases covering all scenarios, including edge cases and different policy types, to validate the correctness of the new logic.  Pay close attention to scenarios involving Stamp Duty calculations.

**Validate Outcomes:**  Compare the results of the NEW_GEMINIA version with the HERITAGE version for a representative sample of data to identify any discrepancies.

### Merge Strategy

**Conditional Merge:**  A conditional merge strategy is recommended.  Carefully analyze the differences and selectively integrate the changes, ensuring that the new business rules are correctly implemented.

**Maintain Backward Compatibility:**  Consider maintaining backward compatibility if possible.  This might involve adding a parameter to control the behavior (e.g., using a flag to switch between the HERITAGE and NEW_GEMINIA logic).

### Update Documentation

Update the procedure's documentation to reflect the changes in logic, parameters, and business rules.  Clearly explain the new restrictions on Stamp Duty application.

### Code Quality Improvements

**Consistent Exception Handling:**  Standardize the exception handling throughout the procedure.  Use more specific exception types whenever possible and provide informative error messages.

**Clean Up Code:**  Refactor the code to improve readability and maintainability.  Consider using more descriptive variable names and breaking down complex logic into smaller, more manageable functions.


## Potential Actions Based on Analysis

**If the Change Aligns with Business Goals:**  Merge the NEW_GEMINIA version after thorough testing and documentation updates.

**If the Change Does Not Align:**  Revert the changes and investigate the reasons for the discrepancy between the business requirements and the implemented logic.

**If Uncertain:**  Conduct further investigation to clarify the business requirements and resolve any ambiguities before merging the changes.


## Additional Considerations

### Database Integrity

Ensure the changes do not compromise database integrity.  Thoroughly test the procedure to prevent data corruption or inconsistencies.

### Performance Impact

Assess the performance impact of the changes, especially the additional conditional checks and the new cursor.  Optimize the code if necessary to maintain acceptable performance levels.

### Error Messages

Improve the error messages to provide more context and helpful information to users and developers.


## Conclusion

The changes to the `pop_single_taxes` procedure introduce significant alterations to the tax calculation logic, primarily affecting Stamp Duty application based on new business rules.  A careful and thorough review of the business requirements, extensive testing, and stakeholder consultation are crucial before merging these changes into production.  Prioritizing clear communication about the impact on clients is also essential.  The improved formatting and more specific exception handling in the NEW_GEMINIA version are positive aspects that should be retained.
