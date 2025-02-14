PROCEDURE pop_quot_rsk_limits (
      v_qr_code     IN   NUMBER,
      v_qp_code     IN   NUMBER,
      v_quot_code   IN   NUMBER,
      v_pro_code    IN   NUMBER,
      v_scl_code    IN   NUMBER,
      v_bind_code   IN   NUMBER,
      v_cvt_code    IN   NUMBER
   )
   IS
      v_row   NUMBER;

      CURSOR pil_cur
      IS
         SELECT DISTINCT sect_sht_desc, sect_code, sect_desc sect_desc,
                         sect_type,
                         DECODE (sect_type,
                                 'ND', 'NCD',
                                 'ES', 'Extension SI',
                                 'EL', 'Extension Limit',
                                 'SS', 'Section SI',
                                 'SL', 'Section Limit',
                                 'DS', 'Discount',
                                 'LO', 'Loading',
                                 'EC', 'Escalation'
                                ) type_desc,
                         prr_rate_type,
                         DECODE (prr_rate_type,
                                 'SRG', 0,
                                 'RCU', 0,
                                 prr_rate
                                ) prr_rate,
                         DECODE (prr_rate_type,
                                 'SRG', 0,
                                 'RCU', 0,
                                 prr_rate
                                ) rate,
                         '0' terr_description,
                         DECODE (prr_rate_type,
                                 'SRG', 0,
                                 'RCU', 0,
                                 prr_prem_minimum_amt
                                ) prr_prem_minimum_amt,
                         DECODE (prr_rate_type,
                                 'SRG', 1,
                                 'RCU', 1,
                                 prr_multiplier_rate
                                ) prr_multiplier_rate,
                         DECODE (prr_rate_type,
                                 'SRG', 1,
                                 'RCU', 1,
                                 prr_division_factor
                                ) prr_division_factor,
                         DECODE
                               (prr_rate_type,
                                'SRG', 1,
                                'RCU', 1,
                                prr_multplier_div_fact
                               ) prr_multplier_div_fact,
                         prr_rate_desc, prr_free_limit
                    FROM gin_premium_rates, gin_sections
                   WHERE prr_sect_code = sect_code
                     AND prr_scl_code = v_scl_code
                     AND prr_bind_code = v_bind_code
                     AND sect_code IN (
                            SELECT scvts_sect_code
                              FROM gin_subcl_covt_sections
                             WHERE scvts_scl_code = v_scl_code
                               AND scvts_covt_code = v_cvt_code
                               AND NVL(scvts_mandatory,'N')='Y'
                               )
                     AND sect_code NOT IN (SELECT qrl_sect_code
                                             FROM gin_quot_risk_limits
                                            WHERE qrl_qr_code = v_qr_code);
   BEGIN
  
      FOR pil_cur_rec IN pil_cur
      LOOP
       
         v_row := NVL (v_row, 0) + 1;

         BEGIN
            INSERT INTO gin_quot_risk_limits
                        (qrl_code, qrl_ipu_code,
                         qrl_sect_code, qrl_sect_sht_desc,
                         qrl_limit_amt, qrl_prem_rate, qrl_prem_amt,
                         qrl_qr_code, qrl_qr_quot_code, qrl_qp_pro_code,
                         qrl_qp_code, qrl_sect_type,
                         qrl_min_premium,
                         qrl_rate_type,
                         qrl_rate_desc,
                         qrl_rate_div_factor,
                         qrl_multiplier_rate,
                         qrl_multiplier_div_factor, qrl_row_num,
                         qrl_calc_group, qrl_compute, qrl_annual_prem,
                         qrl_used_limit, qrl_desc, qrl_dual_basis,
                         qrl_indem_prd, qrl_prd_type, qrl_indem_fstprd,
                         qrl_indem_fstprd_pct, qrl_indem_remprd_pct,
                         qrl_free_limit
                        )
                 VALUES (TO_NUMBER (   TO_CHAR (SYSDATE, 'YYYY')
                                          || gin_qrl_code_seq.NEXTVAL
                                         ), NULL,
                         pil_cur_rec.sect_code, pil_cur_rec.sect_sht_desc,
                         NULL, pil_cur_rec.prr_rate, 0,
                         v_qr_code, v_quot_code, v_pro_code,
                         v_qp_code, pil_cur_rec.sect_type,
                         pil_cur_rec.prr_prem_minimum_amt,
                         pil_cur_rec.prr_rate_type,
                         pil_cur_rec.prr_rate_desc,
                         pil_cur_rec.prr_division_factor,
                         pil_cur_rec.prr_multiplier_rate,
                         pil_cur_rec.prr_multplier_div_fact, v_row,
                         1, 'Y', 0,
                         NULL, pil_cur_rec.sect_desc, 'N',
                         NULL, NULL, NULL,
                         NULL, NULL,
                         pil_cur_rec.prr_free_limit
                        );
                   --raise_Error(v_qr_code||' = '||v_qr_code||' = '||v_cvt_code||'= ' ||v_cvt_code);
         EXCEPTION
            WHEN OTHERS
            THEN
               raise_error ('Error inserting risk sections..');
         END;
      END LOOP;

      IF NVL (v_row, 0) = 0
      THEN
         raise_application_error
            (-20001,
             'Please define Mandatory Sections...'
            );
      END IF;
   END;