PROCEDURE pop_taxes (v_pol_policy_no   IN VARCHAR2,
                         v_pol_endos_no    IN VARCHAR2,
                         v_pol_batch_no    IN NUMBER,
                         v_pro_code        IN NUMBER,
                         v_pol_binder      IN VARCHAR2 DEFAULT 'N',
                         v_trans_type      IN VARCHAR2)
    IS
        v_cnt                      NUMBER;
        v_pol_policy_type          VARCHAR2 (1);
        v_pop_taxes                VARCHAR2 (1);
        v_scl_code                 NUMBER;
        v_allowsdonfacrein_param   VARCHAR2 (1);
        v_con_type                 VARCHAR2 (100) := NULL;
        v_sd_param                 VARCHAR2 (1) := 'N';

        CURSOR sub_class IS
            SELECT *
              FROM gin_insured_property_unds
             WHERE ipu_pol_batch_no = v_pol_batch_no;

        CURSOR taxes (v_scl_code NUMBER)
        IS
            SELECT *
              FROM gin_taxes_types_view
             WHERE     (   scl_code IS NULL
                        OR scl_code IN
                               (SELECT clp_scl_code
                                  FROM gin_product_sub_classes
                                 WHERE     clp_pro_code = v_pro_code
                                       AND clp_scl_code = v_scl_code))
                   AND trnt_mandatory = 'Y'
                   AND trnt_type IN ('UTX',
                                     'SD',
                                     'UTL',
                                     'EX',
                                     'PHFUND',
                                     'MPSD',
                                     'MSD',
                                     'COPHFUND',
                                     'PRM-VAT',
                                     'ROAD',
                                     'HEALTH',
                                     'CERTCHG',
                                     'MOTORTX')
                   AND taxr_trnt_code NOT IN
                           (SELECT ptx_trac_trnt_code
                              FROM gin_policy_taxes
                             WHERE ptx_pol_batch_no = v_pol_batch_no)
                   AND NVL (
                           DECODE (v_trans_type,
                                   'NB', trnt_apply_nb,
                                   'SP', trnt_apply_sp,
                                   'RN', trnt_apply_rn,
                                   'EN', trnt_apply_en,
                                   'CN', trnt_apply_cn,
                                   'EX', trnt_apply_ex,
                                   'DC', trnt_apply_dc,
                                   'RE', trnt_apply_re,
                                   'ME', trnt_apply_re /*This was added to resolve ME policies which were not populating taxes*/
                                                      ),
                           'N') =
                       'Y'
                   AND trnt_code NOT IN (SELECT petx_trnt_code
                                           FROM gin_product_excluded_taxes
                                          WHERE petx_pro_code = v_pro_code);
    BEGIN
        IF v_pol_batch_no = 2019181747
        THEN
            RAISE_ERROR ('TEST THIS');
        END IF;

        BEGIN
            SELECT GIN_PARAMETERS_PKG.GET_PARAM_VARCHAR (
                       'ALLOW_SD_ON_BINDER_POLICY')
              INTO v_sd_param
              FROM DUAL;
        EXCEPTION
            WHEN OTHERS
            THEN
                v_sd_param := 'N';
        END;

        BEGIN
            SELECT pol_policy_type, NVL (pol_pop_taxes, 'Y')
              INTO v_pol_policy_type, v_pop_taxes
              FROM gin_policies
             WHERE pol_batch_no = v_pol_batch_no;
        EXCEPTION
            WHEN OTHERS
            THEN
                raise_error ('Error Checking the policy ...');
        END;

        ---RAISE_eRROR(v_pol_policy_type||' = '||v_pop_taxes);

        BEGIN
            v_allowsdonfacrein_param :=
                gin_parameters_pkg.get_param_varchar ('ALLOW_SD_ON_FACREIN');
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                v_allowsdonfacrein_param := 'N';
            WHEN OTHERS
            THEN
                v_allowsdonfacrein_param := 'N';
        END;

        FOR sub_class_rec IN sub_class
        LOOP
            v_con_type := UPPER (TRIM (sub_class_rec.ipu_conveyance_type));

            IF v_con_type NOT IN ('SEA',
                                  'AIR',
                                  'RAIL',
                                  'ROAD')
            THEN
                v_con_type := UPPER (TRIM (sub_class_rec.ipu_covt_sht_desc));
            END IF;

            IF NVL (sub_class_rec.ipu_sec_scl_code, 0) = 0
            THEN
                raise_error (
                       'sub_class_rec.ipu_sec_scl_code: '
                    || sub_class_rec.ipu_sec_scl_code);
            END IF;

            --RAISE_ERROR('v_pol_policy_type='||v_pol_policy_type||'v_pop_taxes='||v_pop_taxes||'v_pol_binder='||v_pol_binder||'v_sd_param='||v_sd_param);
            IF     NVL (v_pol_policy_type, 'N') = 'N'
               AND NVL (v_pop_taxes, 'Y') = 'Y'
            THEN
                FOR taxes_rec IN taxes (sub_class_rec.ipu_sec_scl_code)
                LOOP
                    --RAISE_eRROR(v_pol_policy_type||' = '||v_pop_taxes);
                    IF NOT (    taxes_rec.trnt_type = 'SD'
                            AND NVL (v_pol_binder, 'N') = 'Y'
                            AND v_sd_param = 'N')
                    THEN
                        v_cnt := NVL (v_cnt, 0) + 1;

                        BEGIN
                            INSERT INTO gin_policy_taxes (
                                            ptx_trac_scl_code,
                                            ptx_trac_trnt_code,
                                            ptx_pol_policy_no,
                                            ptx_pol_ren_endos_no,
                                            ptx_pol_batch_no,
                                            ptx_rate,
                                            ptx_amount,
                                            ptx_tl_lvl_code,
                                            ptx_rate_type,
                                            ptx_rate_desc,
                                            ptx_endos_diff_amt,
                                            ptx_tax_type,
                                            ptx_risk_pol_level)
                                     VALUES (
                                                sub_class_rec.ipu_sec_scl_code,
                                                --taxes_rec.taxr_scl_code,
                                                taxes_rec.trnt_code,
                                                v_pol_policy_no,
                                                v_pol_endos_no,
                                                v_pol_batch_no,
                                                taxes_rec.taxr_rate,
                                                NULL,
                                                'UP',
                                                taxes_rec.taxr_rate_type,
                                                taxes_rec.taxr_rate_desc,
                                                NULL,
                                                taxes_rec.trnt_type,
                                                NVL (
                                                    taxes_rec.taxr_application_area,
                                                    'P'));
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                raise_error ('Error applying taxes..');
                        END;
                    END IF;
                END LOOP;
            ELSIF v_pol_policy_type = 'F' AND NVL (v_pop_taxes, 'Y') = 'Y'
            THEN
                FOR taxes_rec IN taxes (sub_class_rec.ipu_sec_scl_code)
                LOOP
                    IF NVL (v_allowsdonfacrein_param, 'N') = 'Y'
                    THEN
                        IF     taxes_rec.trnt_type = 'SD'
                           AND NVL (v_trans_type, 'XX') = 'NB'
                        THEN
                            v_cnt := NVL (v_cnt, 0) + 1;

                            BEGIN
                                INSERT INTO gin_policy_taxes (
                                                ptx_trac_scl_code,
                                                ptx_trac_trnt_code,
                                                ptx_pol_policy_no,
                                                ptx_pol_ren_endos_no,
                                                ptx_pol_batch_no,
                                                ptx_rate,
                                                ptx_amount,
                                                ptx_tl_lvl_code,
                                                ptx_rate_type,
                                                ptx_rate_desc,
                                                ptx_endos_diff_amt,
                                                ptx_tax_type,
                                                ptx_risk_pol_level)
                                         VALUES (
                                                    sub_class_rec.ipu_sec_scl_code,
                                                    --taxes_rec.taxr_scl_code,
                                                    taxes_rec.trnt_code,
                                                    v_pol_policy_no,
                                                    v_pol_endos_no,
                                                    v_pol_batch_no,
                                                    taxes_rec.taxr_rate,
                                                    NULL,
                                                    'UP',
                                                    taxes_rec.taxr_rate_type,
                                                    taxes_rec.taxr_rate_desc,
                                                    NULL,
                                                    taxes_rec.trnt_type,
                                                    NVL (
                                                        taxes_rec.taxr_application_area,
                                                        'P'));
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    raise_error ('Error applying taxes..');
                            END;
                        END IF;
                    END IF;
                END LOOP;
            END IF;
        END LOOP;

        --- raise_error('v_con_type: '||v_con_type);

        IF NVL (TRIM (v_con_type), 'XYZ') = 'AIR'
        THEN
            DELETE gin_policy_taxes
             WHERE     ptx_trac_trnt_code = 'MPSD'
                   AND ptx_pol_batch_no = v_pol_batch_no;
        END IF;

        IF NVL (TRIM (v_con_type), 'XYZ') = 'SEA'
        THEN
            DELETE gin_policy_taxes
             WHERE     ptx_trac_trnt_code = 'SD'
                   AND ptx_pol_batch_no = v_pol_batch_no;

            UPDATE gin_policy_taxes
               SET ptx_tl_lvl_code = 'SI'
             WHERE     ptx_trac_trnt_code = 'MPSD'
                   AND ptx_pol_batch_no = v_pol_batch_no;
        END IF;

        --RAISE_eRROR(v_pol_policy_type||' 88888 '||v_pop_taxes);

        IF NVL (v_cnt, 0) != 0
        THEN
            BEGIN
                UPDATE gin_policies
                   SET pol_prem_computed = 'N'
                 WHERE pol_batch_no = v_pol_batch_no;
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error (
                        'Error updating policy premium status to changed');
            END;
        END IF;
    END;