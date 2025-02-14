PROCEDURE check_duplicate_quot_risks (v_quot_code IN NUMBER)
    IS
        v_cnt                NUMBER;
        v_allow_duplicates   VARCHAR2 (5);
        v_msg                VARCHAR2 (2000);
        v_count              NUMBER;

        CURSOR dup_risk IS
            SELECT qr_quot_code, qr_property_id, qr_scl_code
              FROM gin_quot_risks
             WHERE qr_quot_code = v_quot_code;

        CURSOR dup_distinct_risk IS
            SELECT DISTINCT qr_quot_code, qr_property_id, qr_scl_code
              FROM gin_quot_risks
             WHERE qr_quot_code = v_quot_code;
    BEGIN
        BEGIN
            v_allow_duplicates :=
                gin_parameters_pkg.get_param_varchar (
                    'ALLOW_DUPLICATION_OF_RISKS');
        EXCEPTION
            WHEN OTHERS
            THEN
                v_allow_duplicates := 'Y';
        END;


        IF NVL (v_allow_duplicates, 'N') = 'N'
        THEN
            BEGIN
                SELECT COUNT (1)
                  INTO v_cnt
                  FROM (  SELECT qr_quot_code, qr_property_id
                            FROM gin_quot_risks
                           WHERE     qr_quot_code = v_quot_code
                                 AND qr_scl_code IN
                                         (SELECT scl_code
                                            FROM gin_sub_classes
                                           WHERE     scl_code = qr_scl_code
                                                 AND NVL (scl_risk_unique, 'N') =
                                                     'Y')
                          HAVING COUNT (1) > 1
                        GROUP BY qr_quot_code, qr_property_id);
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error ('Error checking for risk duplicates..');
            END;

            IF NVL (v_cnt, 0) > 0
            THEN
                FOR d_risk IN dup_risk
                LOOP
                      SELECT DISTINCT COUNT (1)
                        INTO v_count
                        FROM gin_quot_risks, tqc_clients, tqc_client_systems
                       WHERE     qr_prp_code = clnt_code
                             AND clnt_code = csys_clnt_code
                             AND csys_sys_code = 37
                             AND qr_scl_code = d_risk.qr_scl_code
                             AND qr_property_id = d_risk.qr_property_id
                             AND qr_quot_code = d_risk.qr_quot_code
                    ORDER BY qr_code;
                END LOOP;

                FOR d_d_risk IN dup_distinct_risk
                LOOP
                    v_msg := v_msg || '<' || d_d_risk.qr_property_id || '> ';
                END LOOP;


                IF NVL (v_count, 0) <> 1
                THEN
                    --            Null;
                    raise_error (
                           'Risks are duplicated..'
                        || v_msg
                        || ' '
                        || v_count
                        || ' times ');
                END IF;
            END IF;
        END IF;
    END;