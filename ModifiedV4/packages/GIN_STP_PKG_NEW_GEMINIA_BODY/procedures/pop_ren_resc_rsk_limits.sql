PROCEDURE pop_ren_resc_rsk_limits (
        v_new_ipu_code   IN NUMBER,
        v_scl_code       IN NUMBER,
        v_bind_code      IN NUMBER,
        v_cvt_code       IN NUMBER,
        v_sect_type      IN VARCHAR2,
        v_rs_code        IN NUMBER DEFAULT NULL)
    IS
        v_sect_sht_desc             VARCHAR2 (30);
        v_sect_desc                 VARCHAR2 (40);
        --v_sect_type                                VARCHAR2(30);
        v_type_desc                 VARCHAR2 (30);
        v_prr_rate_type             VARCHAR2 (10);
        v_prr_rate                  NUMBER;
        v_terr_description          VARCHAR2 (30);
        v_prr_prem_minimum_amt      NUMBER;
        v_prr_multiplier_rate       NUMBER;
        v_prr_division_factor       NUMBER;
        v_prr_multplier_div_fact    NUMBER;
        v_prr_rate_desc             VARCHAR2 (30);
        v_dc_sect                   VARCHAR2 (5);
        v_insert                    BOOLEAN := FALSE;
        v_no_limit                  VARCHAR2 (2);
        v_pil_declaration_section   VARCHAR2 (30);
        v_row                       NUMBER;
        v_apply_as_discount         VARCHAR2 (1);

        CURSOR pil_cur IS
            SELECT DISTINCT
                   sect_sht_desc,
                   sect_code,
                   sect_desc || ' ' || prr_ncd_level
                       sect_desc,
                   sect_type,
                   DECODE (sect_type,
                           'ND', 'NCD ' || prr_ncd_level,
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
                   prr_prorated_full
              FROM gin_premium_rates, gin_sections, gin_resc_srv_subcl
             WHERE     prr_sect_code = sect_code
                   AND rss_sect_code = sect_code
                   AND rss_rs_code = v_rs_code
                   AND prr_scl_code = v_scl_code
                   AND prr_bind_code = v_bind_code
                   AND NVL (rss_apply_as_discount, 'N') = 'Y'
                   AND prr_section_type = v_sect_type
                   AND sect_code IN
                           (SELECT scvts_sect_code
                              FROM gin_subcl_covt_sections
                             WHERE     scvts_scl_code = v_scl_code
                                   AND scvts_covt_code = v_cvt_code)
                   AND sect_code NOT IN
                           (SELECT pil_sect_code
                              FROM gin_ren_policy_insured_limits
                             WHERE pil_ipu_code = v_new_ipu_code);
    BEGIN
        BEGIN
            DELETE gin_ren_policy_insured_limits
             WHERE     pil_ipu_code = v_new_ipu_code
                   AND pil_sect_type = v_sect_type;
        END;

        BEGIN
            SELECT rss_apply_as_discount
              INTO v_apply_as_discount
              FROM gin_resc_srv_subcl
             WHERE rss_rs_code = v_rs_code AND rss_scl_code = v_scl_code;
        EXCEPTION
            WHEN OTHERS
            THEN
                raise_error ('Error getting section details..');
        END;

        FOR pil_cur_rec IN pil_cur
        LOOP
            v_row := NVL (v_row, 0) + 1;

            BEGIN
                SELECT sec_declaration
                  INTO v_pil_declaration_section
                  FROM gin_subcl_sections
                 WHERE     sec_sect_code = pil_cur_rec.sect_code
                       AND sec_scl_code = v_scl_code;
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error (
                        'Unable to retrieve the section declaration status');
            END;

            BEGIN
                INSERT INTO gin_ren_policy_insured_limits (
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
                                pil_free_limit,
                                pil_prorata_full)
                         VALUES (
                                    gin_pil_code_seq.NEXTVAL,
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
                                    pil_cur_rec.prr_free_limit,
                                    pil_cur_rec.prr_prorated_full);
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error ('Error inserting risk sections..');
            END;
        END LOOP;

        IF NVL (v_row, 0) = 0 AND NVL (v_apply_as_discount, 'N') = 'Y'
        THEN
            raise_application_error (
                -20001,
                'Sections already defined or Premium rates not defined for the selected class and binder...');
        END IF;
    END pop_ren_resc_rsk_limits;