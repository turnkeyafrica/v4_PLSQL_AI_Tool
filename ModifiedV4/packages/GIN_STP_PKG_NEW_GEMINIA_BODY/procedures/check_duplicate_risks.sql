PROCEDURE check_duplicate_risks (v_pol_batch_no IN NUMBER)
    IS
        v_cnt                NUMBER;
        v_allow_duplicates   VARCHAR2 (5);
        v_msg                VARCHAR2 (2000);
        v_count              NUMBER;

        CURSOR dup_risk IS
              SELECT ipu_pol_batch_no, ipu_property_id, ipu_sec_scl_code
                FROM gin_insured_property_unds, gin_policy_active_risks
               WHERE     ipu_code = polar_ipu_code
                     AND polar_pol_batch_no = v_pol_batch_no
                     AND ipu_pol_batch_no NOT IN
                             (SELECT pol_batch_no
                                FROM gin_policies
                               WHERE     pol_batch_no = ipu_pol_batch_no
                                     AND NVL (pol_loaded, 'N') = 'Y')
              HAVING COUNT (1) > 1
            GROUP BY ipu_pol_batch_no, ipu_property_id, ipu_sec_scl_code;
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
                /*SELECT COUNT (1)
                  INTO v_cnt
                  FROM (  SELECT ipu_pol_batch_no, ipu_property_id
                            FROM gin_insured_property_unds, gin_policy_active_risks
                           WHERE     ipu_code = polar_ipu_code
                                 AND polar_pol_batch_no = v_pol_batch_no
                          HAVING COUNT (1) > 1
                        GROUP BY ipu_pol_batch_no, ipu_property_id);*/
                SELECT COUNT (1)
                  INTO v_cnt
                  FROM (  SELECT ipu_pol_batch_no, ipu_property_id
                            FROM gin_insured_property_unds,
                                 gin_policy_active_risks,
                                 gin_sub_classes
                           WHERE     ipu_code = polar_ipu_code
                                 AND ipu_sec_scl_code = scl_code
                                 AND NVL (scl_risk_unique, 'N') = 'Y'
                                 AND polar_pol_batch_no = v_pol_batch_no
                          HAVING COUNT (1) > 1
                        GROUP BY ipu_pol_batch_no, ipu_property_id);
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
                        FROM gin_insured_property_unds,
                             tqc_clients,
                             tqc_client_systems
                       WHERE     ipu_prp_code = clnt_code
                             AND clnt_code = csys_clnt_code
                             AND csys_sys_code = 37
                             AND ipu_sec_scl_code = d_risk.ipu_sec_scl_code
                             AND ipu_property_id = d_risk.ipu_property_id
                             AND ipu_id NOT IN
                                     (SELECT DISTINCT polar_ipu_id
                                        FROM gin_policy_active_risks,
                                             gin_insured_property_unds
                                       WHERE     ipu_id = polar_ipu_id
                                             AND NVL (ipu_endos_remove, 'N') =
                                                 'Y'
                                             AND ipu_property_id =
                                                 d_risk.ipu_property_id)
                             AND ipu_pol_batch_no NOT IN
                                     (SELECT pol_batch_no
                                        FROM gin_policies,
                                             gin_insured_property_unds
                                       WHERE     pol_batch_no =
                                                 ipu_pol_batch_no
                                             AND ipu_sec_scl_code =
                                                 d_risk.ipu_sec_scl_code
                                             AND ipu_property_id =
                                                 d_risk.ipu_property_id
                                             AND pol_current_status IN
                                                     ('CN', 'CO'))
                             AND NVL (ipu_endos_remove, 'N') != 'Y'
                    ORDER BY ipu_code;

                    v_msg := v_msg || '<' || d_risk.ipu_property_id || '> ';
                END LOOP;

                IF NVL (v_count, 0) <> 0
                THEN
                    --            Null;
                    raise_error (
                           'Risks are duplicated..'
                        || v_msg
                        || ' '
                        || v_count
                        || ' times EEEE ');
                END IF;
            END IF;
        END IF;
    END;