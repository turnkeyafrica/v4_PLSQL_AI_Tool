# PL/SQL Function `check_risk_exists` Change Analysis Report

This report analyzes the changes made to the PL/SQL function `check_risk_exists` between the HERITAGE and NEW_GEMINIA versions.


## Summary of Key Changes:

### Reordering of Conditional Logic:

- **HERITAGE Version:** The `IF NVL (v_add_edit, 'N') = 'E' THEN RETURN NULL; END IF;` statement was placed at the beginning, immediately returning NULL if `v_add_edit` was 'E'.  This prioritized early exit for edits.

- **NEW_GEMINIA Version:** This conditional logic has been commented out. The function now proceeds with the risk check regardless of the `v_add_edit` value.

### Modification of WHERE Clauses:

- **Removal and Addition of Conditions:** The `WHERE` clause in the main `SELECT COUNT(*)` statement has undergone significant changes.  Specifically:

    - The condition `REPLACE(ipu_property_id,' ','') = REPLACE(v_property_id,' ','')` which removed spaces from the property ID for comparison, has been simplified to `ipu_property_id = v_property_id`. This assumes that leading/trailing spaces are no longer a concern.

    - Additional conditions have been added to the subquery within the `NOT IN` clause to exclude risks with `ipu_status = 'S'` or `ipu_cover_suspended = 'Y'`, and to check the suspension date (`ipu_suspend_wef`) against the provided `v_wef` and `v_wet` dates.  This adds more refined logic for handling suspended risks.


### Exception Handling Adjustments:

- **HERITAGE Version:** Exception handling was implemented within separate `BEGIN...EXCEPTION...END` blocks for fetching parameter `ALLOW_DUPLICATION_OF_RISKS` and counting records from `gin_sub_classes`.  The main `SELECT` statement also had its own exception handler.

- **NEW_GEMINIA Version:**  The exception handling for fetching the parameter and counting sub-classes is maintained, but the main `SELECT` statement's exception handling is consolidated into a single `BEGIN...EXCEPTION...END` block at the end of the function. This improves code readability and maintainability.


### Formatting and Indentation:

- The code formatting and indentation have been improved in the NEW_GEMINIA version, making it more readable and easier to understand.  Parameter lists are broken across multiple lines for better readability.


## Implications of the Changes:

### Logic Alteration in Fee Determination:

- **Priority Shift:**  The HERITAGE version prioritized early exit for edits. The NEW_GEMINIA version removes this priority, always performing the risk check.

- **Potential Outcome Difference:** The removal of the `v_add_edit` check means the function will now always check for duplicate risks, even during edits. This could lead to different results compared to the HERITAGE version, potentially blocking edits that were previously allowed.  The addition of the `ipu_status` and `ipu_cover_suspended` checks in the `WHERE` clause will also affect the results, potentially changing which risks are considered duplicates.

### Business Rule Alignment:

The changes might or might not align with the business rules.  The removal of the space-handling in the property ID comparison suggests a change in how property IDs are managed.  The additional conditions in the `WHERE` clause suggest a refinement in how suspended or cancelled risks are handled.  A thorough review of business requirements is crucial to determine alignment.

### Impact on Clients:

The changes could impact clients if the new logic results in different risk assessments.  For example, previously accepted edits might now be rejected due to the removal of the `v_add_edit` check.  This could lead to workflow disruptions and require client communication.


## Recommendations for Merging:

### Review Business Requirements:

- **Confirm Intent:**  Carefully review the business requirements to understand the rationale behind the changes.  Determine if the removal of the `v_add_edit` check and the modifications to the `WHERE` clause are intentional and reflect the desired business logic.

### Consult Stakeholders:

Discuss the changes with stakeholders (business analysts, testers, and users) to ensure the new logic aligns with their expectations and to assess the potential impact on clients.

### Test Thoroughly:

- **Create Test Cases:** Develop comprehensive test cases to cover all scenarios, including edits, new entries, and various combinations of `ipu_status` and `ipu_cover_suspended` values.  Pay special attention to edge cases and boundary conditions.

- **Validate Outcomes:** Compare the results of the NEW_GEMINIA version with the HERITAGE version to identify any discrepancies and ensure the new logic produces the expected outcomes.

### Merge Strategy:

- **Conditional Merge:**  Instead of a direct replacement, consider a conditional merge.  This could involve adding a parameter or configuration setting to control which logic is used (HERITAGE or NEW_GEMINIA). This allows for a phased rollout and easier rollback if needed.

- **Maintain Backward Compatibility:**  If possible, maintain backward compatibility by providing a mechanism to switch between the old and new logic. This allows for a smoother transition and minimizes disruption.

### Update Documentation:

Thoroughly update the documentation to reflect the changes in the function's logic, including the rationale behind the modifications and any potential impact on users.

### Code Quality Improvements:

- **Consistent Exception Handling:**  Maintain consistent exception handling throughout the function.  Consider using a single, centralized exception handler to improve code readability and maintainability.

- **Clean Up Code:**  Remove unnecessary comments and ensure consistent formatting and indentation.


## Potential Actions Based on Analysis:

- **If the Change Aligns with Business Goals:**  Proceed with merging the NEW_GEMINIA version after thorough testing and stakeholder consultation.

- **If the Change Does Not Align:**  Revert the changes and investigate the reason for the discrepancy between the intended business logic and the implemented changes.

- **If Uncertain:**  Conduct further analysis and consultation with stakeholders to clarify the intended behavior and ensure the changes align with business requirements before merging.


## Additional Considerations:

- **Database Integrity:**  Verify that the changes do not compromise database integrity.  Pay close attention to the impact of the modified `WHERE` clause on data retrieval and potential inconsistencies.

- **Performance Impact:**  Assess the performance impact of the changes, especially the additional conditions in the `WHERE` clause.  Consider optimizing the queries if necessary.

- **Error Messages:**  Review and improve the error messages to provide more informative and user-friendly feedback.


## Conclusion:

The changes to the `check_risk_exists` function introduce significant modifications to the logic for identifying duplicate risks.  The removal of the `v_add_edit` check and the addition of conditions related to `ipu_status` and `ipu_cover_suspended` have the potential to alter the function's behavior significantly.  A thorough review of business requirements, comprehensive testing, and stakeholder consultation are crucial before merging the NEW_GEMINIA version.  A phased rollout with a mechanism for backward compatibility is highly recommended to minimize disruption and allow for easy rollback if necessary.
