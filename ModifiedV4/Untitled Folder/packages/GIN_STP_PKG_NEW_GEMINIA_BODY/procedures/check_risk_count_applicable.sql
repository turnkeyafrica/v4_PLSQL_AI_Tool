PROCEDURE check_risk_count_applicable (v_pol_batch_no   IN NUMBER,
                                           v_uw_year        IN NUMBER)
    IS
        v_max_risk_count   NUMBER;
        v_risk_count       NUMBER;
    BEGIN
        IF gin_parameters_pkg.get_param_varchar ('RISKS_COUNT_LIMIT_ALLOWED') =
           'Y'
        THEN
            BEGIN
                  SELECT COUNT (ipu_code), NVL (scl_max_risk_count, 0)
                    INTO v_risk_count, v_max_risk_count
                    FROM gin_policies,
                         gin_sub_classes,
                         gin_insured_property_unds,
                         gin_policy_active_risks
                   WHERE     ipu_pol_batch_no = pol_batch_no
                         AND polar_ipu_code = ipu_code
                         AND polar_pol_batch_no = ipu_pol_batch_no
                         AND scl_code = ipu_sec_scl_code
                         AND pol_batch_no = v_pol_batch_no
                         AND pol_uw_year = v_uw_year
                GROUP BY NVL (scl_max_risk_count, 0);
            END;