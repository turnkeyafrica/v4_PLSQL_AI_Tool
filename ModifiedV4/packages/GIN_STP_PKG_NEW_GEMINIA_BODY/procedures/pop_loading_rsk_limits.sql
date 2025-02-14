PROCEDURE pop_loading_rsk_limits (v_new_ipu_code   IN NUMBER,
                                      v_scl_code       IN NUMBER,
                                      v_bind_code      IN NUMBER,
                                      v_cvt_code       IN NUMBER,
                                      v_batch_no       IN NUMBER,
                                      v_sect_type      IN VARCHAR2,
                                      v_range          IN NUMBER)
    IS
        v_pil_declaration_section   VARCHAR2 (30);
        v_row                       NUMBER;
        v_pol_binder                VARCHAR2 (2);
        v_ncd_status                gin_insured_property_unds.ipu_ncd_status%TYPE;
        v_ncd_level                 gin_insured_property_unds.ipu_ncd_level%TYPE;
        v_calc_group                NUMBER := 1;
        v_calc_row                  NUMBER := 1;

        CURSOR pil_cur IS
            SELECT DISTINCT
                   sect_sht_desc,
                   sect_code,
                   sect_desc
                       sect_desc,
                   sect_type,
                   DECODE (sect_type,
                           'ND', 'NCD',
                           'ES', 'Extension SI',
                           'EL', 'Extension Limit',
                           'SS', 'Section SI',
                           'SL', 'Section Limit',
                           'DS', 'Discount',
                           'LO', 'Loading',
                           'EC', 'Escalation')
                       type_desc,
                   prr_rate_type,
                   DECODE (prr_rate_type,  'SRG', 0,  'RCU', 0,  prr_rate)
                       prr_rate,
                   DECODE (prr_rate_type,  'SRG', 0,  'RCU', 0,  prr_rate)
                       rate,
                   '0'
                       terr_description,
                   DECODE (prr_rate_type,
                           'SRG', 0,
                           'RCU', 0,
                           prr_prem_minimum_amt)
                       prr_prem_minimum_amt,
                   DECODE (prr_rate_type,
                           'SRG', 1,
                           'RCU', 1,
                           prr_multiplier_rate)
                       prr_multiplier_rate,
                   DECODE (prr_rate_type,
                           'SRG', 1,
                           'RCU', 1,
                           prr_division_factor)
                       prr_division_factor,
                   DECODE (prr_rate_type,
                           'SRG', 1,
                           'RCU', 1,
                           prr_multplier_div_fact)
                       prr_multplier_div_fact,
                   prr_rate_desc,
                   prr_free_limit,
                   prr_prorated_full,
                   prr_max_rate,
                   prr_min_rate
              FROM gin_premium_rates, gin_sections
             WHERE     prr_sect_code = sect_code
                   AND prr_scl_code = v_scl_code
                   AND prr_bind_code = v_bind_code
                   AND sect_type = v_sect_type
                   AND v_range BETWEEN prr_range_from AND prr_range_to
                   AND sect_code NOT IN
                           (SELECT pil_sect_code
                              FROM gin_policy_insured_limits
                             WHERE pil_ipu_code = v_new_ipu_code)
            UNION
            SELECT DISTINCT
                   sect_sht_desc,
                   sect_code,
                   sect_desc
                       sect_desc,
                   sect_type,
                   DECODE (sect_type,
                           'ND', 'NCD',
                           'ES', 'Extension SI',
                           'EL', 'Extension Limit',
                           'SS', 'Section SI',
                           'SL', 'Section Limit',
                           'DS', 'Discount',
                           'LO', 'Loading',
                           'EC', 'Escalation')
                       type_desc,
                   prr_rate_type,
                   DECODE (prr_rate_type,  'SRG', 0,  'RCU', 0,  prr_rate)
                       prr_rate,
                   DECODE (prr_rate_type,  'SRG', 0,  'RCU', 0,  prr_rate)
                       rate,
                   '0'
                       terr_description,
                   DECODE (prr_rate_type,
                           'SRG', 0,
                           'RCU', 0,
                           prr_prem_minimum_amt)
                       prr_prem_minimum_amt,
                   DECODE (prr_rate_type,
                           'SRG', 1,
                           'RCU', 1,
                           prr_multiplier_rate)
                       prr_multiplier_rate,
                   DECODE (prr_rate_type,
                           'SRG', 1,
                           'RCU', 1,
                           prr_division_factor)
                       prr_division_factor,
                   DECODE (prr_rate_type,
                           'SRG', 1,
                           'RCU', 1,
                           prr_multplier_div_fact)
                       prr_multplier_div_fact,
                   prr_rate_desc,
                   prr_free_limit,
                   prr_prorated_full,
                   prr_max_rate,
                   prr_min_rate
              FROM gin_premium_rates, gin_sections
             WHERE     prr_sect_code = sect_code
                   AND prr_scl_code = v_scl_code
                   AND prr_bind_code = v_bind_code
                   AND sect_type = v_sect_type
                   AND v_range BETWEEN prr_range_from AND prr_range_to
                   AND sect_code NOT IN
                           (SELECT pil_sect_code
                              FROM gin_policy_insured_limits
                             WHERE pil_ipu_code = v_new_ipu_code)
            UNION
            SELECT DISTINCT
                   sect_sht_desc,
                   sect_code,
                   sect_desc
                       sect_desc,
                   sect_type,
                   DECODE (sect_type,
                           'ND', 'NCD',
                           'ES', 'Extension SI',
                           'EL', 'Extension Limit',
                           'SS', 'Section SI',
                           'SL', 'Section Limit',
                           'DS', 'Discount',
                           'LO', 'Loading',
                           'EC', 'Escalation')
                       type_desc,
                   prr_rate_type,
                   DECODE (prr_rate_type,  'SRG', 0,  'RCU', 0,  prr_rate)
                       prr_rate,
                   DECODE (prr_rate_type,  'SRG', 0,  'RCU', 0,  prr_rate)
                       rate,
                   '0'
                       terr_description,
                   DECODE (prr_rate_type,
                           'SRG', 0,
                           'RCU', 0,
                           prr_prem_minimum_amt)
                       prr_prem_minimum_amt,
                   DECODE (prr_rate_type,
                           'SRG', 1,
                           'RCU', 1,
                           prr_multiplier_rate)
                       prr_multiplier_rate,
                   DECODE (prr_rate_type,
                           'SRG', 1,
                           'RCU', 1,
                           prr_division_factor)
                       prr_division_factor,
                   DECODE (prr_rate_type,
                           'SRG', 1,
                           'RCU', 1,
                           prr_multplier_div_fact)
                       prr_multplier_div_fact,
                   prr_rate_desc,
                   prr_free_limit,
                   prr_prorated_full,
                   prr_max_rate,
                   prr_min_rate
              FROM gin_premium_rates, gin_sections
             WHERE     prr_sect_code = sect_code
                   AND prr_scl_code = v_scl_code
                   AND prr_bind_code = v_bind_code
                   AND sect_type = v_sect_type
                   AND v_range BETWEEN prr_range_from AND prr_range_to
                   AND sect_code NOT IN
                           (SELECT pil_sect_code
                              FROM gin_policy_insured_limits
                             WHERE pil_ipu_code = v_new_ipu_code);

        CURSOR pil_cur_ncd IS
            SELECT *
              FROM gin_policy_insured_limits
             WHERE pil_ipu_code = v_new_ipu_code AND pil_sect_type = 'ND';
    BEGIN
        BEGIN
            SELECT pol_binder_policy,
                   NVL (ipu_ncd_status, 'N'),
                   NVL (ipu_ncd_level, 0)
              INTO v_pol_binder, v_ncd_status, v_ncd_level
              FROM gin_policies, gin_insured_property_unds
             WHERE     pol_batch_no = ipu_pol_batch_no
                   AND ipu_code = v_new_ipu_code
                   AND pol_batch_no = v_batch_no;
        EXCEPTION
            WHEN OTHERS
            THEN
                raise_error ('Error determining the policy binder...');
        END;

        IF NVL (v_pol_binder, 'N') != 'Y'
        THEN
            FOR pil_cur_rec IN pil_cur
            LOOP
                BEGIN
                    SELECT DISTINCT SCVTS_ORDER, SCVTS_CALC_GROUP
                      INTO v_calc_row, v_calc_group
                      FROM GIN_SUBCL_COVT_SECTIONS
                     WHERE     SCVTS_SECT_CODE = pil_cur_rec.sect_code
                           AND SCVTS_SCL_CODE = v_scl_code
                           AND SCVTS_COVT_CODE IN
                                   (SELECT IPU_COVT_CODE
                                      FROM GIN_INSURED_PROPERTY_UNDS
                                     WHERE IPU_CODE = v_new_ipu_code);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        v_calc_group := 1;
                        v_calc_row := 1;
                END;

                v_row := NVL (v_row, 0) + 1;

                BEGIN
                    INSERT INTO gin_policy_insured_limits (
                                    pil_code,
                                    pil_ipu_code,
                                    pil_sect_code,
                                    pil_sect_sht_desc,
                                    pil_desc,
                                    pil_row_num,
                                    pil_calc_group,
                                    pil_limit_amt,
                                    pil_prem_rate,
                                    pil_prem_amt,
                                    pil_rate_type,
                                    pil_rate_desc,
                                    pil_sect_type,
                                    pil_original_prem_rate,
                                    pil_multiplier_rate,
                                    pil_multiplier_div_factor,
                                    pil_annual_premium,
                                    pil_rate_div_fact,
                                    --PIL_DESC,
                                    pil_compute,
                                    pil_prd_type,
                                    pil_dual_basis,
                                    pil_prem_accumulation,
                                    pil_declaration_section,
                                    pil_annual_actual_prem,
                                    pil_free_limit,
                                    pil_prorata_full,
                                    pil_prr_max_rate,
                                    pil_prr_min_rate)
                             VALUES (
                                           TO_NUMBER (
                                               TO_CHAR (SYSDATE, 'RRRR'))
                                        || gin_pil_code_seq.NEXTVAL,
                                        v_new_ipu_code,
                                        pil_cur_rec.sect_code,
                                        pil_cur_rec.sect_sht_desc,
                                        pil_cur_rec.sect_desc,
                                        v_calc_row, --pil_cur_rec.pil_row_num ,--v_row,
                                        v_calc_group, -- pil_cur_rec.pil_calc_group,
                                        NULL,
                                        DECODE (pil_cur_rec.prr_rate_type,
                                                'SRG', 0,
                                                'RCU', 0,
                                                pil_cur_rec.prr_rate),
                                        0,
                                        pil_cur_rec.prr_rate_type,
                                        pil_cur_rec.prr_rate_desc,
                                        pil_cur_rec.sect_type,
                                        pil_cur_rec.prr_rate,
                                        pil_cur_rec.prr_multiplier_rate,
                                        pil_cur_rec.prr_multplier_div_fact,
                                        0,
                                        pil_cur_rec.prr_division_factor,
                                        --v_type_desc,
                                        'Y',
                                        NULL,
                                        'N',
                                        0,
                                        v_pil_declaration_section,
                                        0,
                                        pil_cur_rec.prr_free_limit,
                                        pil_cur_rec.prr_prorated_full,
                                        pil_cur_rec.prr_max_rate,
                                        pil_cur_rec.prr_min_rate);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error ('Error inserting risk sections..');
                END;
            END LOOP;

            FOR pil_cur_ncd_rec IN pil_cur_ncd
            LOOP
                BEGIN
                    SELECT DISTINCT SCVTS_ORDER, SCVTS_CALC_GROUP
                      INTO v_calc_row, v_calc_group
                      FROM GIN_SUBCL_COVT_SECTIONS
                     WHERE     SCVTS_SECT_CODE =
                               pil_cur_ncd_rec.pil_sect_code
                           AND SCVTS_SCL_CODE = v_scl_code
                           AND SCVTS_COVT_CODE IN
                                   (SELECT IPU_COVT_CODE
                                      FROM GIN_INSURED_PROPERTY_UNDS
                                     WHERE IPU_CODE = v_new_ipu_code);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        v_calc_group := 1;
                        v_calc_row := 1;
                END;

                --         RAISE_ERROR('NCD .....'||pil_cur_ncd_rec.pil_prem_amt);
                DELETE gin_policy_insured_limits
                 WHERE pil_code = pil_cur_ncd_rec.pil_code;


                v_row := NVL (v_row, 0) + 1;

                BEGIN
                    INSERT INTO gin_policy_insured_limits (
                                    pil_code,
                                    pil_ipu_code,
                                    pil_sect_code,
                                    pil_sect_sht_desc,
                                    pil_desc,
                                    pil_row_num,
                                    pil_calc_group,
                                    pil_limit_amt,
                                    pil_prem_rate,
                                    pil_prem_amt,
                                    pil_rate_type,
                                    pil_rate_desc,
                                    pil_sect_type,
                                    pil_original_prem_rate,
                                    pil_multiplier_rate,
                                    pil_multiplier_div_factor,
                                    pil_annual_premium,
                                    pil_rate_div_fact,
                                    pil_compute,
                                    pil_prd_type,
                                    pil_dual_basis,
                                    pil_prem_accumulation,
                                    pil_declaration_section,
                                    pil_annual_actual_prem,
                                    pil_free_limit,
                                    pil_prorata_full,
                                    pil_prr_max_rate,
                                    pil_prr_min_rate,
                                    pil_firstloss,
                                    pil_firstloss_amt_pcnt,
                                    pil_firstloss_value)
                             VALUES (
                                           TO_NUMBER (
                                               TO_CHAR (SYSDATE, 'RRRR'))
                                        || gin_pil_code_seq.NEXTVAL,
                                        pil_cur_ncd_rec.pil_ipu_code,
                                        pil_cur_ncd_rec.pil_sect_code,
                                        pil_cur_ncd_rec.pil_sect_sht_desc,
                                        pil_cur_ncd_rec.pil_desc,
                                        v_calc_row, --pil_cur_rec.pil_row_num ,--v_row,
                                        v_calc_group,
                                        --pil_cur_ncd_rec.pil_row_num,
                                        --pil_cur_ncd_rec.pil_calc_group,
                                        pil_cur_ncd_rec.pil_limit_amt,
                                        pil_cur_ncd_rec.pil_prem_rate,
                                        pil_cur_ncd_rec.pil_prem_amt,
                                        pil_cur_ncd_rec.pil_rate_type,
                                        pil_cur_ncd_rec.pil_rate_desc,
                                        pil_cur_ncd_rec.pil_sect_type,
                                        pil_cur_ncd_rec.pil_original_prem_rate,
                                        pil_cur_ncd_rec.pil_multiplier_rate,
                                        pil_cur_ncd_rec.pil_multiplier_div_factor,
                                        pil_cur_ncd_rec.pil_annual_premium,
                                        pil_cur_ncd_rec.pil_rate_div_fact,
                                        pil_cur_ncd_rec.pil_compute,
                                        pil_cur_ncd_rec.pil_prd_type,
                                        pil_cur_ncd_rec.pil_dual_basis,
                                        pil_cur_ncd_rec.pil_prem_accumulation,
                                        pil_cur_ncd_rec.pil_declaration_section,
                                        pil_cur_ncd_rec.pil_annual_actual_prem,
                                        pil_cur_ncd_rec.pil_free_limit,
                                        pil_cur_ncd_rec.pil_prorata_full,
                                        pil_cur_ncd_rec.pil_prr_max_rate,
                                        pil_cur_ncd_rec.pil_prr_min_rate,
                                        pil_cur_ncd_rec.pil_firstloss,
                                        pil_cur_ncd_rec.pil_firstloss_amt_pcnt,
                                        pil_cur_ncd_rec.pil_firstloss_value);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error ('Error inserting risk sections..');
                END;
            END LOOP;
        END IF;
    END pop_loading_rsk_limits;