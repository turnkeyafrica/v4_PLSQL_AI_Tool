PROCEDURE pop_ren_loading_rsk_limits (
      v_new_ipu_code   IN   NUMBER,
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
      
    CURSOR pil_cur_ncd
     IS SELECT *
    FROM gin_ren_policy_insured_limits
    WHERE pil_ipu_code=v_new_ipu_code
    AND pil_sect_type=v_sect_type;                                                                  
                                                               
   BEGIN
   --RAISE_ERROR(v_scl_code||'='||v_bind_code||'='||v_new_ipu_code||'=v_range'||v_range);
      BEGIN
         SELECT pol_binder_policy
           INTO v_pol_binder
           FROM gin_ren_policies, gin_ren_insured_property_unds
          WHERE pol_batch_no = ipu_pol_batch_no
            AND ipu_code = v_new_ipu_code
            AND pol_batch_no = v_batch_no;
      EXCEPTION
         WHEN OTHERS
         THEN
            raise_error ('Error determining the policy binder...');
      END;

      IF NVL (v_pol_binder, 'N') != 'Y'
      THEN 
         FOR pil_cur_ncd_rec IN pil_cur_ncd
         LOOP
             DELETE gin_ren_policy_insured_limits 
             WHERE pil_code=pil_cur_ncd_rec.pil_code;
             
             v_row := NVL (v_row, 0) + 1;
           BEGIN                             
               INSERT INTO gin_ren_policy_insured_limits
                           (pil_code,
                            pil_ipu_code, pil_sect_code,
                            pil_sect_sht_desc,
                            pil_desc, pil_row_num, pil_calc_group,
                            pil_limit_amt,
                            pil_prem_rate,
                            pil_prem_amt, pil_rate_type,
                            pil_rate_desc,
                            pil_sect_type, pil_original_prem_rate,
                            pil_multiplier_rate,
                            pil_multiplier_div_factor, pil_annual_premium,
                            pil_rate_div_fact,pil_compute, pil_prd_type,
                            pil_dual_basis, pil_prem_accumulation,
                            pil_declaration_section, pil_annual_actual_prem,
                            pil_free_limit,
                            pil_prorata_full,
                            pil_prr_max_rate,
                            pil_prr_min_rate
                           )
                    VALUES (TO_NUMBER (TO_CHAR (SYSDATE, 'RRRR'))
                            || gin_pil_code_seq.NEXTVAL,
                            pil_cur_ncd_rec.pil_ipu_code,  pil_cur_ncd_rec.pil_sect_code,
                             pil_cur_ncd_rec.pil_sect_sht_desc,
                             pil_cur_ncd_rec.pil_desc,  pil_cur_ncd_rec.pil_row_num,  pil_cur_ncd_rec.pil_calc_group,
                             pil_cur_ncd_rec.pil_limit_amt,
                             pil_cur_ncd_rec.pil_prem_rate,
                             pil_cur_ncd_rec.pil_prem_amt,  pil_cur_ncd_rec.pil_rate_type,
                             pil_cur_ncd_rec.pil_rate_desc,
                             pil_cur_ncd_rec.pil_sect_type,  pil_cur_ncd_rec.pil_original_prem_rate,
                             pil_cur_ncd_rec.pil_multiplier_rate,
                             pil_cur_ncd_rec.pil_multiplier_div_factor,  pil_cur_ncd_rec.pil_annual_premium,
                             pil_cur_ncd_rec.pil_rate_div_fact, pil_cur_ncd_rec.pil_compute,  pil_cur_ncd_rec.pil_prd_type,
                             pil_cur_ncd_rec.pil_dual_basis,  pil_cur_ncd_rec.pil_prem_accumulation,
                             pil_cur_ncd_rec.pil_declaration_section,  pil_cur_ncd_rec.pil_annual_actual_prem,
                             pil_cur_ncd_rec.pil_free_limit,
                             pil_cur_ncd_rec.pil_prorata_full,
                             pil_cur_ncd_rec.pil_prr_max_rate,
                             pil_cur_ncd_rec.pil_prr_min_rate
                           );
            EXCEPTION
               WHEN OTHERS
               THEN
                  raise_error ('Error inserting risk sections..');
            END;
         END LOOP;
         
      END IF;
   END pop_ren_loading_rsk_limits;