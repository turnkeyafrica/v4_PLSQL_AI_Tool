PROCEDURE pop_bouquet_rsk_limits (v_new_ipu_code    IN NUMBER,
                                      v_scl_code        IN NUMBER,
                                      v_bind_code       IN NUMBER,
                                      v_cvt_code        IN NUMBER,
                                      v_batch_no        IN NUMBER,
                                      v_sect_type       IN VARCHAR2,
                                      v_range           IN NUMBER,
                                      v_garage_applic   IN VARCHAR2,
                                      v_no_claim_hist   IN NUMBER,
                                      v_usage_type      IN VARCHAR2,
                                      v_vehicle_size    IN VARCHAR2)
    IS
        v_pil_declaration_section   VARCHAR2 (30);
        v_row                       NUMBER;
        v_pol_binder                VARCHAR2 (2);
        v_ncd_status                gin_insured_property_unds.ipu_ncd_status%TYPE;
        v_ncd_level                 gin_insured_property_unds.ipu_ncd_level%TYPE;

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
                   --AND NVL(v_range,0) BETWEEN NVL(prr_range_from,0) AND NVL(prr_range_to,0)
                   AND sect_code NOT IN
                           (SELECT pil_sect_code
                              FROM gin_policy_insured_limits
                             WHERE pil_ipu_code = v_new_ipu_code);
        /*UNION
        SELECT DISTINCT sect_sht_desc, sect_code, sect_desc sect_desc,
                      sect_type,DECODE (sect_type,'ND', 'NCD','ES', 'Extension SI','EL', 'Extension Limit','SS', 'Section SI',
                              'SL', 'Section Limit','DS', 'Discount','LO', 'Loading', 'EC', 'Escalation' ) type_desc, prr_rate_type,
                      DECODE (prr_rate_type,'SRG', 0,'RCU', 0,prr_rate) prr_rate,
                      DECODE (prr_rate_type,     'SRG', 0,  'RCU', 0,   prr_rate    ) rate,
                      '0' terr_description,  DECODE (prr_rate_type, 'SRG', 0,'RCU', 0, prr_prem_minimum_amt) prr_prem_minimum_amt,
                      DECODE (prr_rate_type,'SRG', 1,    'RCU', 1, prr_multiplier_rate) prr_multiplier_rate,
                      DECODE (prr_rate_type,    'SRG', 1,   'RCU', 1,   prr_division_factor ) prr_division_factor,
                      DECODE (prr_rate_type, 'SRG', 1, 'RCU', 1,prr_multplier_div_fact) prr_multplier_div_fact,
                      prr_rate_desc, prr_free_limit, prr_prorated_full,prr_max_rate, prr_min_rate
                 FROM gin_premium_rates, gin_sections
                WHERE prr_sect_code = sect_code
                  AND prr_scl_code = v_scl_code
                  AND prr_bind_code = v_bind_code
                  AND sect_type =v_sect_type
                  AND v_range  BETWEEN prr_range_from AND prr_range_to
                  AND sect_code NOT IN (
                                      SELECT pil_sect_code
                                       FROM gin_policy_insured_limits
                                        WHERE pil_ipu_code =
                                                         v_new_ipu_code)
UNION
SELECT DISTINCT sect_sht_desc, sect_code, sect_desc sect_desc,
                      sect_type,DECODE (sect_type,'ND', 'NCD','ES', 'Extension SI','EL', 'Extension Limit','SS', 'Section SI',
                              'SL', 'Section Limit','DS', 'Discount','LO', 'Loading', 'EC', 'Escalation' ) type_desc, prr_rate_type,
                      DECODE (prr_rate_type,'SRG', 0,'RCU', 0,prr_rate) prr_rate,
                      DECODE (prr_rate_type,     'SRG', 0,  'RCU', 0,   prr_rate    ) rate,
                      '0' terr_description,  DECODE (prr_rate_type, 'SRG', 0,'RCU', 0, prr_prem_minimum_amt) prr_prem_minimum_amt,
                      DECODE (prr_rate_type,'SRG', 1,    'RCU', 1, prr_multiplier_rate) prr_multiplier_rate,
                      DECODE (prr_rate_type,    'SRG', 1,   'RCU', 1,   prr_division_factor ) prr_division_factor,
                      DECODE (prr_rate_type, 'SRG', 1, 'RCU', 1,prr_multplier_div_fact) prr_multplier_div_fact,
                      prr_rate_desc, prr_free_limit, prr_prorated_full,prr_max_rate, prr_min_rate
                 FROM gin_premium_rates, gin_sections
                WHERE prr_sect_code = sect_code
                  AND prr_scl_code = v_scl_code
                  AND prr_bind_code = v_bind_code
                 AND sect_type  =v_sect_type
                  AND v_range  BETWEEN prr_range_from AND prr_range_to
                  AND sect_code NOT IN (
                                       SELECT pil_sect_code
                                        FROM gin_policy_insured_limits
                                        WHERE pil_ipu_code =
                                                            v_new_ipu_code);*/
    BEGIN
        --RAISE_eRROR('v_pol_binder='||v_pol_binder);
        FOR pil_cur_rec IN pil_cur
        LOOP
            v_row := NVL (v_row, 0) + 1;

            IF pil_cur_rec.sect_type NOT IN ('GD',
                                             'GR',
                                             'NC',
                                             'CL',
                                             'UD',
                                             'VU',
                                             'VL')
            THEN
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
                                        v_row,
                                        1,
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