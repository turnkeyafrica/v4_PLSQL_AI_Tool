PROCEDURE pop_resc_rsk_limits (v_new_ipu_code   IN NUMBER,
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
                              FROM gin_policy_insured_limits
                             WHERE pil_ipu_code = v_new_ipu_code);
    BEGIN
        --RAISE_ERROR('Unable='||v_bind_code||'='||v_sect_type||'='||v_cvt_code||'=='||v_scl_code||'='||v_rs_code||'==='||v_new_ipu_code);
        BEGIN
            DELETE gin_policy_insured_limits
             WHERE     pil_ipu_code = v_new_ipu_code
                   AND pil_sect_type = v_sect_type;
        END;