PROCEDURE pop_liab_limits (v_pol_policy_no   IN VARCHAR2,
                               v_pol_endos_no    IN VARCHAR2,
                               v_pol_batch_no    IN NUMBER,
                               v_pro_code        IN NUMBER)
    IS
        CURSOR pop_limits_liabilities IS
            SELECT schv_code,
                   schv_narration,
                   schv_value,
                   schv_scl_code
              FROM gin_schedule_values
             WHERE schv_scl_code = (SELECT pro_sht_desc
                                      FROM gin_products
                                     WHERE pro_code = v_pro_code);

        v_auto_pop_limits_param   VARCHAR2 (1) := 'N';
        v_trans_type              VARCHAR2 (100);
    BEGIN
        v_auto_pop_limits_param :=
            NVL (
                GIN_PARAMETERS_PKG.get_param_varchar (
                    'AUTO_POP_LIMITS_LIABILITIES'),
                'N');

        BEGIN
            SELECT pol_policy_status
              INTO v_trans_type
              FROM gin_policies
             WHERE pol_batch_no = v_pol_batch_no;
        EXCEPTION
            WHEN OTHERS
            THEN
                v_trans_type := NULL;
        END;


        FOR lmts IN pop_limits_liabilities
        LOOP
            IF NVL (v_auto_pop_limits_param, 'N') = 'Y'
            THEN
                INSERT INTO gin_pol_schedule_values (schpv_code,
                                                     schpv_schv_code,
                                                     schpv_pol_batch_no,
                                                     schpv_value,
                                                     schpv_narration)
                     VALUES (gin_schpv_code_seq.NEXTVAL,
                             lmts.schv_code,
                             v_pol_batch_no,
                             lmts.schv_value,
                             lmts.schv_narration);
            ELSIF     NVL (v_auto_pop_limits_param, 'N') = 'N'
                  AND v_trans_type NOT IN ('NB')
            THEN
                INSERT INTO gin_pol_schedule_values (schpv_code,
                                                     schpv_schv_code,
                                                     schpv_pol_batch_no,
                                                     schpv_value,
                                                     schpv_narration)
                     VALUES (gin_schpv_code_seq.NEXTVAL,
                             lmts.schv_code,
                             v_pol_batch_no,
                             lmts.schv_value,
                             lmts.schv_narration);
            END IF;
        END LOOP;
    END;