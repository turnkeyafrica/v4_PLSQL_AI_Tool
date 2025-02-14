FUNCTION check_risk_exists (v_pol_batch_no       IN     NUMBER,
                                v_scl_code           IN     NUMBER,
                                v_property_id        IN     VARCHAR2,
                                v_wef                IN     DATE,
                                v_wet                IN     DATE,
                                v_allow_duplicates      OUT VARCHAR2,
                                v_add_edit           IN     VARCHAR2)
        RETURN VARCHAR2
    IS
        v_cnt     NUMBER;
        v_msg     VARCHAR2 (2000);
        v_id      NUMBER;
        v_count   NUMBER;
    BEGIN
        --      IF NVL (v_add_edit, 'N') = 'E'
        --      THEN
        --         RETURN NULL;
        --      END IF;
        BEGIN
            v_allow_duplicates :=
                gin_parameters_pkg.get_param_varchar (
                    'ALLOW_DUPLICATION_OF_RISKS');
        EXCEPTION
            WHEN OTHERS
            THEN
                v_allow_duplicates := 'Y';
        END;

        BEGIN
            SELECT COUNT (*)
              INTO v_count
              FROM gin_sub_classes
             WHERE scl_code = v_scl_code AND NVL (scl_risk_unique, 'N') = 'Y';
        EXCEPTION
            WHEN OTHERS
            THEN
                v_count := 0;
        END;

        IF NVL (v_count, 0) <> 0 AND NVL (v_allow_duplicates, 'N') = 'N'
        THEN
              SELECT DISTINCT COUNT (1)
                INTO v_cnt
                FROM gin_insured_property_unds, tqc_clients, tqc_client_systems
               WHERE     ipu_prp_code = clnt_code
                     AND clnt_code = csys_clnt_code
                     AND csys_sys_code = 37
                     AND ipu_sec_scl_code = v_scl_code
                     AND ipu_property_id = v_property_id
                     --and ipu_id !=  v_ipu_id
                     --AND ipu_status = 'NB'
                     AND ipu_id NOT IN
                             (SELECT DISTINCT polar_ipu_id
                                FROM gin_policy_active_risks,
                                     gin_insured_property_unds
                               WHERE     ipu_id = polar_ipu_id
                                     AND NVL (ipu_endos_remove, 'N') = 'Y'
                                     AND ipu_property_id = v_property_id)
                     AND ipu_id NOT IN
                             (SELECT DISTINCT polar_ipu_id
                                FROM gin_policy_active_risks,
                                     gin_insured_property_unds
                               WHERE     ipu_id = polar_ipu_id
                                     AND ipu_property_id = v_property_id
                                     AND (   ipu_status = 'S'
                                          OR ipu_cover_suspended = 'Y')
                                     AND TO_DATE (ipu_suspend_wef,
                                                  'DD/MM/RRRR') BETWEEN v_wef
                                                                    AND v_wet)
                     AND (   (TO_DATE (ipu_wef, 'DD/MM/RRRR') BETWEEN v_wef
                                                                  AND v_wet)
                          OR (TO_DATE (ipu_wet, 'DD/MM/RRRR') BETWEEN v_wef
                                                                  AND v_wet))
                     AND ipu_pol_batch_no NOT IN
                             (SELECT pol_batch_no
                                FROM gin_policies, gin_insured_property_unds
                               WHERE     pol_batch_no = ipu_pol_batch_no
                                     AND ipu_sec_scl_code = v_scl_code
                                     AND ipu_property_id = v_property_id
                                     --and ipu_id !=  v_ipu_id
                                     AND pol_current_status IN ('CN', 'CO') --  AND pol_current_status IN ('CN', 'D', 'CO')
                                                                           )
                     AND NVL (ipu_endos_remove, 'N') != 'Y'
            ORDER BY ipu_code;

            IF NVL (v_cnt, 0) != 0
            THEN
                v_msg :=
                       'This risk/s ID '
                    || v_property_id
                    || ' is/are duplicated '
                    || v_cnt
                    || ' times.';
                RETURN (v_msg);
            ELSE
                RETURN NULL;
            END IF;
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            v_msg := 'Error checking risk duplicates..';
            RETURN (v_msg);
    END;