PROCEDURE pop_loading_quot_rsk_limits (
      v_qr_code   IN   NUMBER,
      v_scl_code       IN   NUMBER,
      v_bind_code      IN   NUMBER,
      v_cvt_code       IN   NUMBER,
      v_batch_no       IN   NUMBER,
      v_sect_type      IN   VARCHAR2,
      v_range  IN   NUMBER
   )
   IS
      v_pil_declaration_section   VARCHAR2 (30);
      v_row                       NUMBER;
      v_pol_binder                VARCHAR2 (2);
      v_ncd_status                VARCHAR2 (2);
      v_ncd_level                 gin_quot_risks.qr_ncd_level%TYPE;

      CURSOR pil_cur
      IS
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
                                          SELECT qrl_sect_code
                                           FROM gin_quot_risk_limits
                                          WHERE qrl_qr_code =
                                                              v_qr_code)
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
                     AND sect_type =v_sect_type
                     AND v_range  BETWEEN prr_range_from AND prr_range_to
                  AND sect_code NOT IN (
                                         SELECT qrl_sect_code
                                          FROM gin_quot_risk_limits
                                           WHERE qrl_qr_code =
                                                            v_qr_code)
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
                                          SELECT qrl_sect_code
                                           FROM gin_quot_risk_limits
                                           WHERE qrl_qr_code =
                                                               v_qr_code);
     CURSOR pil_cur_ncd
      IS SELECT *
    FROM gin_quot_risk_limits
    WHERE qrl_qr_code=v_qr_code
    AND qrl_sect_type='ND';                                                           
                                                               
   BEGIN
    --RAISE_ERROR(v_qr_code||'='||v_bind_code||'v_range'||v_range||'v_sect_type='|| v_sect_type);                
              
      BEGIN
         SELECT 'N', NVL ('N', 'N'),
                NVL (qr_ncd_level, 0)
           INTO v_pol_binder, v_ncd_status,
                v_ncd_level
           FROM gin_quotations, gin_quot_risks
          WHERE quot_code = qr_quot_code
            AND qr_code = v_qr_code
            AND quot_code = v_batch_no;
      EXCEPTION
         WHEN OTHERS
         THEN
            raise_error ('Error determining the policy binder...');
      END;