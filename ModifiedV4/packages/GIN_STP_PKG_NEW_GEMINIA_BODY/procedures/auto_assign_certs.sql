PROCEDURE auto_assign_certs (
        v_ipu_code            IN NUMBER,
        v_wef_date            IN DATE,
        v_wet_date            IN DATE,
        v_polc_passenger_no   IN NUMBER,
        v_pol_add_edit           VARCHAR2,
        v_tonnage                VARCHAR2 DEFAULT NULL)
    IS
        v_add_edit              VARCHAR2 (1);
        v_ct_code               NUMBER;
        v_ipu_id                NUMBER;
        v_cer_cnt               NUMBER;
        v_error                 VARCHAR2 (200);
        v_scl_code              NUMBER;
        v_covt_code             NUMBER;
        v_curr_cert_wet         DATE;
        v_cover_suspended       VARCHAR2 (3);
        v_polc_tonnage          NUMBER;
        v_polc_pll              NUMBER;
        v_depend                VARCHAR (1);
        v_pass                  NUMBER;
        v_pro_code              NUMBER;
        v_scr_name              VARCHAR2 (50);
        v_pol_regional_endors   VARCHAR (1);
    /*v_pol_regional_endors flag introduced to manage regional certificates GIS-12169*/
    BEGIN
        BEGIN
            SELECT DISTINCT pol_pro_code, pol_regional_endors
              INTO v_pro_code, v_pol_regional_endors
              FROM gin_policies, gin_insured_property_unds
             WHERE pol_batch_no = ipu_pol_batch_no AND ipu_code = v_ipu_code;
        EXCEPTION
            WHEN OTHERS
            THEN
                raise_error ('Error getting risk product details...');
        END;

        --RAISE_ERROR('HERE'||v_pol_regional_endors);
        BEGIN
            SELECT screen_name
              INTO v_scr_name
              FROM gin_screens, gin_products
             WHERE     pro_unwr_scr_code = screen_code
                   AND pro_code = v_pro_code
                   AND screen_level = 'U';
        EXCEPTION
            WHEN OTHERS
            THEN
                raise_error ('Error product screen details...');
        END;

        IF v_scr_name IN ('UMOTCOM', 'UMOTPSV')
        THEN
            IF NVL (v_polc_passenger_no, 0) = 0
            THEN
                BEGIN
                    SELECT TO_NUMBER (mcoms_carry_capacity), mcoms_tonnage
                      INTO v_pass, v_polc_tonnage
                      FROM gin_motor_commercial_sch
                     WHERE mcoms_ipu_code = v_ipu_code;
                --AND NVL (mcoms_acc_limit, 'N') = 'N';
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        NULL;
                    WHEN OTHERS
                    THEN
                        ROLLBACK;
                        raise_error (
                            'Error getting tonnage/no. of passengers...');
                        RETURN;
                END;
            ELSE
                v_pass := v_polc_passenger_no;
            END IF;

            --RAISE_ERROR(' v_pass '||v_pass);
            IF NVL (v_pol_add_edit, 'U') = 'E'
            THEN
                IF NVL (v_pass, 0) = 0
                THEN
                    NULL;
                --RAISE_ERROR('Error getting the number of passengers...'||v_pol_add_edit);
                END IF;
            END IF;
        END IF;

        IF NVL (v_polc_tonnage, '0') = '0'
        THEN
            v_polc_tonnage := v_tonnage;
        END IF;

        --RAISE_ERROR('v_pass '||v_pass);
        BEGIN
            SELECT sct_ct_code,
                   ipu_id,
                   ipu_sec_scl_code,
                   sct_covt_code,
                   ipu_cover_suspended,
                   ct_pass_dep
              INTO v_ct_code,
                   v_ipu_id,
                   v_scl_code,
                   v_covt_code,
                   v_cover_suspended,
                   v_depend
              FROM gin_insured_property_unds,
                   gin_subclass_cert_types,
                   gin_cert_types
             WHERE     sct_covt_code(+) = ipu_covt_code
                   AND sct_scl_code(+) = ipu_sec_scl_code
                   AND sct_ct_code = ct_code(+)
                   AND ipu_code = v_ipu_code
                   AND NVL (ct_cert_type, 'COVER') !=
                       DECODE (NVL (v_pol_regional_endors, 'N'),
                               'Y', 'COVER',
                               'REGIONAL') /*v_pol_regional_endors flag introduced to manage
              regional certificates GIS-12169*/
                   AND DECODE (NVL (ct_pass_dep, 'N'),  'N', 0,  'Y', v_pass) BETWEEN DECODE (
                                                                                          NVL (
                                                                                              ct_pass_dep,
                                                                                              'N'),
                                                                                          'N', 0,
                                                                                          'Y', ct_min_pass)
                                                                                  AND DECODE (
                                                                                          NVL (
                                                                                              ct_pass_dep,
                                                                                              'N'),
                                                                                          'N', 0,
                                                                                          'Y', ct_max_pass);
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                RAISE_ERROR ('error...' || SQLERRM);
            WHEN OTHERS
            THEN
                IF NVL (v_depend, 'N') = 'N'
                THEN
                    NULL;
                ELSE
                    raise_error (
                        'Error getting certificate....SCL== ' || v_ipu_code);
                END IF;
        END;

        IF NVL (v_cover_suspended, 'N') = 'Y'
        THEN
            raise_error ('Cannot assign a certificate to a suspended risk..');
        END IF;

        --     RAISE_ERROR(' v_wef_date '||v_wef_date||' v_wet_date '||v_wet_date||' v_ct_code '||v_ct_code||' v_pass '||v_pass);
        IF v_ct_code IS NOT NULL
        THEN
            BEGIN
                SELECT COUNT (1), MAX (polc_wet)
                  INTO v_cer_cnt, v_curr_cert_wet
                  FROM gin_policy_certs
                 WHERE     polc_ipu_id = v_ipu_id
                       AND v_wef_date <= polc_wet
                       AND (   polc_wef BETWEEN v_wef_date AND v_wet_date
                            OR polc_wet BETWEEN v_wef_date AND v_wet_date)
                       AND polc_status != 'C';
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error (
                           'Error getting certificate....SCL== '
                        || v_scl_code
                        || ' ipu_cvt_code== '
                        || v_covt_code);
            END;

            IF v_wef_date > v_wet_date
            THEN
                raise_error (
                       'Certificate from date '
                    || v_wef_date
                    || 'cannot be greater than To Date :'
                    || v_wet_date);
            END IF;

            -- raise_error (
            --                 'Certificate from date '
            --               || v_wef_date
            --               || 'cannot be greater than To Date :'
            --               || v_wet_date);
            -- IF v_wet_date > TRUNC (SYSDATE) THEN -- this part is handled in the