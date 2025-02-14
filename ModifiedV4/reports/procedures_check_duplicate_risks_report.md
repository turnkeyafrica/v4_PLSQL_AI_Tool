# PL/SQL Procedure `check_duplicate_risks` Change Analysis Report

This report analyzes the changes made to the PL/SQL procedure `check_duplicate_risks` between the HERITAGE and NEW_GEMINIA versions.

## Summary of Key Changes:

### Reordering of Conditional Logic:

- **HERITAGE Version:** The HERITAGE version first checks if duplicate risks are allowed (`v_allow_duplicates`). If not, it proceeds to count duplicates.  The logic is relatively straightforward but lacks detailed checks on specific risk attributes.

- **NEW_GEMINIA Version:** The NEW_GEMINIA version maintains the initial check for allowed duplicates. However, the duplicate risk check is significantly more complex, involving additional joins with `gin_sub_classes`, `tqc_clients`, and `tqc_client_systems` tables and incorporating conditions based on `scl_risk_unique`, `ipu_endos_remove`, `pol_current_status`, and system code 37.  The logic is nested and harder to follow.


### Modification of WHERE Clauses:

- **Removal and Addition of Conditions:** The NEW_GEMINIA version significantly expands the `WHERE` clause in the duplicate risk check.  It adds conditions to filter based on:
    - `ipu_sec_scl_code` (Sub-class code)
    - `scl_risk_unique` (Flag indicating if risk should be unique)
    - `ipu_endos_remove` (Flag indicating if risk should be removed)
    - `pol_current_status` (Status of the policy)
    - System code 37 (from `tqc_client_systems`)
    - Exclusion of policies with `pol_loaded = 'Y'`

The original `WHERE` clause only checked `ipu_code` and `polar_pol_batch_no`.  This is a substantial change in the data being considered for duplicate detection.

### Exception Handling Adjustments:

- **HERITAGE Version:** The HERITAGE version has basic exception handling for the `gin_parameters_pkg.get_param_varchar` call, defaulting to 'Y' if an error occurs.  The duplicate check itself also has a basic `WHEN OTHERS` exception handler.

- **NEW_GEMINIA Version:** The NEW_GEMINIA version maintains similar exception handling for parameter retrieval. However, the exception handling for the duplicate check remains largely the same, raising a generic error message.  The improved error message in the `raise_error` call is a minor improvement.

### Formatting and Indentation:

- The NEW_GEMINIA version shows improved formatting and indentation, making the code slightly more readable.


## Implications of the Changes:

### Logic Alteration in Fee Determination:

- **Priority Shift:**
    - **HERITAGE:** The HERITAGE version simply checks for duplicate `ipu_property_id` within a policy batch.
    - **NEW_GEMINIA:** The NEW_GEMINIA version introduces a much more nuanced check, considering sub-class codes, client systems, policy statuses, and flags for risk removal or uniqueness.  This suggests a change in how duplicate risks are handled and potentially how fees are calculated.

- **Potential Outcome Difference:** The changes could lead to different results in identifying duplicate risks.  The NEW_GEMINIA version might identify fewer or more duplicates than the HERITAGE version, impacting fee calculations and potentially the overall financial outcome.

### Business Rule Alignment:

The NEW_GEMINIA version reflects a more complex business rule for handling duplicate risks.  The original rule was simple; the new rule is far more intricate and requires careful review to ensure it accurately reflects the current business requirements.

### Impact on Clients:

The changes could affect clients' premiums or policy details if the definition of duplicate risks changes the calculation of fees or the identification of errors in the policy data.  This needs careful consideration and communication.


## Recommendations for Merging:

### Review Business Requirements:

- **Confirm Intent:**  Thoroughly review the business requirements to understand the rationale behind the changes in the duplicate risk check logic.  Document the new business rules precisely.

### Consult Stakeholders:

Discuss the changes with business stakeholders, including those responsible for underwriting, pricing, and client management, to ensure the new logic aligns with their expectations and doesn't introduce unintended consequences.

### Test Thoroughly:

- **Create Test Cases:** Develop comprehensive test cases covering various scenarios, including edge cases and boundary conditions, to validate the new logic.  Pay close attention to the impact on fee calculations.
- **Validate Outcomes:** Compare the results of the NEW_GEMINIA version with the HERITAGE version to identify any discrepancies and assess their impact.

### Merge Strategy:

- **Conditional Merge:**  A conditional merge might be appropriate, allowing for a phased rollout or a feature flag to switch between the HERITAGE and NEW_GEMINIA versions. This allows for testing and rollback if necessary.
- **Maintain Backward Compatibility:**  If possible, maintain backward compatibility by adding a parameter to control the behavior, allowing users to select either the old or new logic.

### Update Documentation:

Update the package documentation to reflect the changes in the procedure's logic, including the new business rules and the implications for duplicate risk handling.

### Code Quality Improvements:

- **Consistent Exception Handling:**  Improve the exception handling to provide more specific error messages, making debugging easier.
- **Clean Up Code:** Refactor the code to improve readability and maintainability.  The nested logic in the NEW_GEMINIA version needs simplification if possible.


## Potential Actions Based on Analysis:

- **If the Change Aligns with Business Goals:**  Proceed with the merge after thorough testing and stakeholder approval.  Implement a phased rollout or feature flag to mitigate risks.

- **If the Change Does Not Align:**  Re-evaluate the business requirements and discuss the discrepancies with stakeholders.  Consider reverting to the HERITAGE version or revising the NEW_GEMINIA version to align with the intended business rules.

- **If Uncertain:**  Conduct further investigation to clarify the business requirements and the intended behavior of the new logic.  Delay the merge until the uncertainties are resolved.


## Additional Considerations:

- **Database Integrity:**  The changes could impact database integrity if the new logic introduces inconsistencies in data handling.  Thorough testing is crucial to prevent data corruption.

- **Performance Impact:**  The added joins in the NEW_GEMINIA version might impact the procedure's performance.  Performance testing is necessary to assess the impact and optimize the code if needed.

- **Error Messages:**  The error messages should be improved to provide more context and helpful information to users and developers.


## Conclusion:

The changes to the `check_duplicate_risks` procedure are substantial and introduce a significantly more complex logic for identifying duplicate risks.  A thorough review of business requirements, extensive testing, and stakeholder consultation are crucial before merging the changes.  A phased rollout or a mechanism for backward compatibility is highly recommended to mitigate potential risks and allow for a smooth transition.  The code also needs improvements in terms of readability and error handling.  Without a clear understanding of the business justification for these changes, merging this code is risky.
