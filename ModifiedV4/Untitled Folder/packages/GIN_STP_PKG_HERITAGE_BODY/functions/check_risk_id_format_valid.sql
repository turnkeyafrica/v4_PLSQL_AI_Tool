FUNCTION check_risk_id_format_valid (v_ipu_code      IN NUMBER)
        RETURN VARCHAR2
    IS
        v_cnt                    NUMBER;
        v_risk_id_format_param   VARCHAR2 (200);
        v_risk_id_format         gin_sub_classes.scl_risk_id_format%TYPE;
        v_scl_risk_unique        gin_sub_classes.scl_risk_unique%TYPE;
        v_count                  NUMBER := 0;
        v_check_format           BOOLEAN := FALSE;
        v_value                  VARCHAR2 (5) := 'Y';

        CURSOR rsks IS
            SELECT pol_agnt_agent_code,
                   pol_agnt_sht_desc,
                   ipu_code,
                   ipu_comm_rate,
                   ipu_allowed_comm_rate,
                   ipu_pol_policy_no,
                   ipu_property_id,
                   pol_commission_allowed,
                   pro_moto_verfy,
                   ipu_sec_scl_code,
                   pol_policy_status
              FROM gin_insured_property_unds, gin_policies, gin_products
             WHERE     ipu_pol_batch_no = pol_batch_no
                   AND pol_pro_code = pro_code
                   AND ipu_code=v_ipu_code;
    BEGIN
        FOR r IN rsks
        LOOP
            v_risk_id_format_param :=
                NVL (
                    gin_parameters_pkg.get_param_varchar (
                        'ALLOW_UNIQUE_RISK_IDFORMAT'),
                    'N');

            BEGIN
                SELECT scl_risk_id_format, scl_risk_unique
                  INTO v_risk_id_format, v_scl_risk_unique
                  FROM gin_sub_classes
                 WHERE scl_code = r.ipu_sec_scl_code;
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error ('Error getting Risk Id Format');
            END;