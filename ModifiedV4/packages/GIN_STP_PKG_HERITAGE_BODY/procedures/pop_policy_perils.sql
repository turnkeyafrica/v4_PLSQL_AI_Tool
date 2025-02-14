PROCEDURE pop_policy_perils (
      v_batch_no    IN   NUMBER,
      v_pro_code    IN   NUMBER,
      v_bind_code   IN   NUMBER
   )
   IS
      v_bind_type   VARCHAR2 (1);
   BEGIN
      IF v_bind_code IS NULL
      THEN
         v_bind_type := 'M';
      ELSE
         BEGIN
            SELECT bind_type
              INTO v_bind_type
              FROM gin_binders
             WHERE bind_code = v_bind_code;
         EXCEPTION
            WHEN OTHERS
            THEN
               raise_error ('Error getting the binder type...');
         END;
      END IF;

      IF v_bind_type = 'B'
      THEN
         INSERT INTO gin_policy_section_perils
                     (pspr_code, pspr_sspr_code, pspr_scl_code,
                      pspr_sect_code, pspr_sect_sht_desc, pspr_per_code,
                      pspr_per_sht_desc, pspr_mandatory, pspr_peril_limit,
                      pspr_peril_type, pspr_si_or_limit, pspr_sec_code,
                      pspr_excess_type, pspr_excess, pspr_excess_min,
                      pspr_excess_max, pspr_expire_on_claim, pspr_bind_code,
                      pspr_person_limit, pspr_claim_limit, pspr_desc,
                      pspr_bind_type, pspr_pol_batch_no, pspr_salvage_pct,
                      pspr_tl_excess_type, pspr_tl_excess,
                      pspr_tl_excess_min, pspr_tl_excess_max,
                      pspr_pl_excess_type, pspr_pl_excess,
                      pspr_pl_excess_min, pspr_pl_excess_max,
                      pspr_claim_excess_min, pspr_claim_excess_max,
                      pspr_depend_loss_type, pspr_claim_excess_type,
                      pspr_ttd_ben_pcts)
            SELECT gin_pspr_code_seq.NEXTVAL, sspr_code, sspr_scl_code,
                   ssprm_sect_code, ssprm_sect_sht_desc, sspr_per_code,
                   sspr_per_sht_desc, sspr_mandatory, sspr_peril_limit,
                   sspr_peril_type, sspr_si_or_limit, ssprm_sec_code,
                   sspr_excess_type, sspr_excess, sspr_excess_min,
                   sspr_excess_max, sspr_expire_on_claim, ssprm_bind_code,
                   sspr_person_limit, sspr_claim_limit, sspr_desc,
                   ssprm_bind_type, v_batch_no, sspr_salvage_pct,
                   sspr_tl_excess_type, sspr_tl_excess, sspr_tl_excess_min,
                   sspr_tl_excess_max, sspr_pl_excess_type, sspr_pl_excess,
                   sspr_pl_excess_min, sspr_pl_excess_max,
                   sspr_claim_excess_min, sspr_claim_excess_max,
                   sspr_depend_loss_type, sspr_claim_excess_type,
                   sspr_ttd_ben_pcts
              FROM gin_subcl_sction_perils, gin_subcl_sction_perils_map
             WHERE sspr_bind_code = v_bind_code
               AND sspr_code = ssprm_sspr_code
               AND sspr_scl_code IN (SELECT clp_scl_code
                                       FROM gin_product_sub_classes
                                      WHERE clp_pro_code = v_pro_code)
               AND sspr_code NOT IN (SELECT pspr_sspr_code
                                       FROM gin_policy_section_perils
                                      WHERE pspr_pol_batch_no = v_batch_no);
      ELSE
         INSERT INTO gin_policy_section_perils
                     (pspr_code, pspr_sspr_code, pspr_scl_code,
                      pspr_sect_code, pspr_sect_sht_desc, pspr_per_code,
                      pspr_per_sht_desc, pspr_mandatory, pspr_peril_limit,
                      pspr_peril_type, pspr_si_or_limit, pspr_sec_code,
                      pspr_excess_type, pspr_excess, pspr_excess_min,
                      pspr_excess_max, pspr_expire_on_claim, pspr_bind_code,
                      pspr_person_limit, pspr_claim_limit, pspr_desc,
                      pspr_bind_type, pspr_pol_batch_no, pspr_salvage_pct,
                      pspr_tl_excess_type, pspr_tl_excess,
                      pspr_tl_excess_min, pspr_tl_excess_max,
                      pspr_pl_excess_type, pspr_pl_excess,
                      pspr_pl_excess_min, pspr_pl_excess_max,
                      pspr_claim_excess_min, pspr_claim_excess_max,
                      pspr_depend_loss_type, pspr_claim_excess_type,
                      pspr_ttd_ben_pcts)
            SELECT gin_pspr_code_seq.NEXTVAL, sspr_code, sspr_scl_code,
                   ssprm_sect_code, ssprm_sect_sht_desc, sspr_per_code,
                   sspr_per_sht_desc, sspr_mandatory, sspr_peril_limit,
                   sspr_peril_type, sspr_si_or_limit, ssprm_sec_code,
                   sspr_excess_type, sspr_excess, sspr_excess_min,
                   sspr_excess_max, sspr_expire_on_claim, ssprm_bind_code,
                   sspr_person_limit, sspr_claim_limit, sspr_desc,
                   ssprm_bind_type, v_batch_no, sspr_salvage_pct,
                   sspr_tl_excess_type, sspr_tl_excess, sspr_tl_excess_min,
                   sspr_tl_excess_max, sspr_pl_excess_type, sspr_pl_excess,
                   sspr_pl_excess_min, sspr_pl_excess_max,
                   sspr_claim_excess_min, sspr_claim_excess_max,
                   sspr_depend_loss_type, sspr_claim_excess_type,
                   sspr_ttd_ben_pcts
              FROM gin_subcl_sction_perils, gin_subcl_sction_perils_map
             WHERE sspr_bind_type = v_bind_type
               AND sspr_code = ssprm_sspr_code
               AND sspr_scl_code IN (SELECT clp_scl_code
                                       FROM gin_product_sub_classes
                                      WHERE clp_pro_code = v_pro_code)
               AND sspr_code NOT IN (SELECT pspr_sspr_code
                                       FROM gin_policy_section_perils
                                      WHERE pspr_pol_batch_no = v_batch_no);
      END IF;
   END;
--