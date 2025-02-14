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

      IF NVL (v_pol_binder, 'N') != 'Y'
      THEN       
           FOR pil_cur_rec IN pil_cur
           LOOP
             v_row := NVL (v_row, 0) + 1;
              BEGIN
                INSERT INTO gin_quot_risk_limits
                           (qrl_code,
                            qrl_ipu_code, qrl_sect_code,
                            qrl_sect_sht_desc,
                            qrl_desc, qrl_row_num, qrl_calc_group,
                            qrl_limit_amt,
                            qrl_prem_rate,
                            qrl_prem_amt, qrl_rate_type,
                            qrl_rate_desc,
                            qrl_sect_type,
                            qrl_multiplier_rate,
                            qrl_multiplier_div_factor, qrl_annual_prem,
                            qrl_rate_div_factor,qrl_compute, qrl_prd_type,
                            qrl_dual_basis,
                            qrl_free_limit, qrl_max_prem_rate,
                            qrl_min_prem_rate,
                            qrl_qr_code
                           )
                    VALUES (   TO_NUMBER (TO_CHAR (SYSDATE, 'RRRR'))
                            || gin_pil_code_seq.NEXTVAL,
                            v_qr_code, pil_cur_rec.sect_code,
                            pil_cur_rec.sect_sht_desc,
                            pil_cur_rec.sect_desc, v_row, 1,
                            NULL,
                            DECODE (pil_cur_rec.prr_rate_type,
                                    'SRG', 0,
                                    'RCU', 0,
                                    pil_cur_rec.prr_rate
                                   ),
                            0, pil_cur_rec.prr_rate_type,
                            pil_cur_rec.prr_rate_desc,
                            pil_cur_rec.sect_type, 
                            pil_cur_rec.prr_multiplier_rate,
                            pil_cur_rec.prr_multplier_div_fact, 0,
                            pil_cur_rec.prr_division_factor, 
                            'Y', NULL,
                            'N', 
                            pil_cur_rec.prr_free_limit,
                            pil_cur_rec.prr_max_rate,
                            pil_cur_rec.prr_min_rate,
                            v_qr_code
                           );
              EXCEPTION
               WHEN OTHERS
               THEN
                  raise_error ('Error inserting risk sections..');
              END;
           END LOOP;
         FOR pil_cur_ncd_rec IN pil_cur_ncd
         LOOP
             DELETE gin_quot_risk_limits 
             WHERE QRL_CODE=pil_cur_ncd_rec.qrl_code;
             
             v_row := NVL (v_row, 0) + 1;
           BEGIN
                             
               INSERT INTO gin_quot_risk_limits
                           (qrl_code,
                            qrl_ipu_code, qrl_sect_code,
                            qrl_sect_sht_desc,
                            qrl_desc, qrl_row_num, qrl_calc_group,
                            qrl_limit_amt,
                            qrl_prem_rate,
                            qrl_prem_amt, qrl_rate_type,
                            qrl_rate_desc,
                            qrl_sect_type,
                            qrl_multiplier_rate,
                            qrl_multiplier_div_factor, qrl_annual_prem,
                            qrl_rate_div_factor,qrl_compute, qrl_prd_type,
                            qrl_dual_basis,
                            qrl_free_limit, qrl_max_prem_rate,
                            qrl_min_prem_rate,
                            qrl_qr_code
                           )
                    VALUES (  TO_NUMBER (TO_CHAR (SYSDATE, 'RRRR'))
                            || gin_pil_code_seq.NEXTVAL,
                            pil_cur_ncd_rec.qrl_ipu_code, pil_cur_ncd_rec.qrl_sect_code,
                            pil_cur_ncd_rec.qrl_sect_sht_desc,
                            pil_cur_ncd_rec.qrl_desc, pil_cur_ncd_rec.qrl_row_num, pil_cur_ncd_rec.qrl_calc_group,
                            pil_cur_ncd_rec.qrl_limit_amt,
                            pil_cur_ncd_rec.qrl_prem_rate,
                            pil_cur_ncd_rec.qrl_prem_amt, pil_cur_ncd_rec.qrl_rate_type,
                            pil_cur_ncd_rec.qrl_rate_desc,
                            pil_cur_ncd_rec.qrl_sect_type,
                            pil_cur_ncd_rec.qrl_multiplier_rate,
                            pil_cur_ncd_rec.qrl_multiplier_div_factor, pil_cur_ncd_rec.qrl_annual_prem,
                            pil_cur_ncd_rec.qrl_rate_div_factor,pil_cur_ncd_rec.qrl_compute, pil_cur_ncd_rec.qrl_prd_type,
                            pil_cur_ncd_rec.qrl_dual_basis,
                            pil_cur_ncd_rec.qrl_free_limit, pil_cur_ncd_rec.qrl_max_prem_rate,
                            pil_cur_ncd_rec.qrl_min_prem_rate,
                            pil_cur_ncd_rec.qrl_qr_code
                           );
            EXCEPTION
               WHEN OTHERS
               THEN
                  raise_error ('Error inserting risk sections..');
            END;
         END LOOP;  
           
      END IF;
   END pop_loading_quot_rsk_limits;