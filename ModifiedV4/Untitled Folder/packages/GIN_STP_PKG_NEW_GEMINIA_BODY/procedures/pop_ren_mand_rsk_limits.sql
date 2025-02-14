PROCEDURE pop_ren_mand_rsk_limits (v_new_ipu_code   IN NUMBER,
                                       v_scl_code       IN NUMBER,
                                       v_bind_code      IN NUMBER,
                                       v_cvt_code       IN NUMBER,
                                       v_batch_no       IN NUMBER)
    IS                 -- populates mandatory sections for non binder policies
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
                   AND sect_type != 'ND'
                   AND sect_code IN
                           (SELECT scvts_sect_code
                              FROM gin_subcl_covt_sections
                             WHERE     scvts_scl_code = v_scl_code
                                   AND scvts_covt_code = v_cvt_code
                                   AND NVL (scvts_mandatory, 'N') = 'Y')
                   AND sect_code NOT IN
                           (SELECT pil_sect_code
                              FROM gin_ren_policy_insured_limits
                             WHERE pil_ipu_code = v_new_ipu_code);
    BEGIN
        BEGIN
            SELECT pol_binder_policy,
                   NVL (ipu_ncd_status, 'N'),
                   NVL (ipu_ncd_level, 0)
              INTO v_pol_binder, v_ncd_status, v_ncd_level
              FROM gin_ren_policies, gin_ren_insured_property_unds
             WHERE     pol_batch_no = ipu_pol_batch_no
                   AND ipu_code = v_new_ipu_code
                   AND pol_batch_no = v_batch_no;
        EXCEPTION
            WHEN OTHERS
            THEN
                raise_error ('Error determining the policy binder...');
        END;