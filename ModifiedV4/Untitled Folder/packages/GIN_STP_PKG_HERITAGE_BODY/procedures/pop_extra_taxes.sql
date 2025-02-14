PROCEDURE pop_extra_taxes (
      v_pol_policy_no   IN   VARCHAR2,
      v_pol_endos_no    IN   VARCHAR2,
      v_pol_batch_no    IN   NUMBER,
      v_pro_code        IN   NUMBER,
      v_pol_binder      IN   VARCHAR2 DEFAULT 'N'
   )
   IS
      CURSOR taxes
      IS
         SELECT   COUNT (1) cnt, trnt_code, taxr_rate, taxr_rate_desc,
                  trnt_type, rs_sht_desc, taxr_rate_type, rs_appl_lvl
             FROM gin_taxes_types_view,
                  gin_rescue_services,
                  gin_insured_property_unds,
                  gin_resc_srv_subcl
            WHERE taxr_scl_code IS NULL
              AND rss_rs_code = ipu_rs_code
              AND rss_scl_code = ipu_sec_scl_code
              AND taxr_trnt_code = rs_sht_desc
              AND ipu_pol_batch_no = v_pol_batch_no
              AND ipu_rs_code = rs_code
              AND NVL (rss_apply_as_discount, 'N') = 'Y'
              AND trnt_type IN ('RSC')
              AND taxr_trnt_code NOT IN (
                                       SELECT ptx_trac_trnt_code
                                         FROM gin_policy_taxes
                                        WHERE ptx_pol_batch_no =
                                                                v_pol_batch_no)
         GROUP BY trnt_code,
                  taxr_rate,
                  taxr_rate_desc,
                  trnt_type,
                  rs_sht_desc,
                  trnt_type,
                  taxr_rate_type,
                  rs_appl_lvl;

      v_apply_as_discount   VARCHAR2 (1);
   BEGIN
      FOR taxes_rec IN taxes
      LOOP
         IF taxes_rec.trnt_type IN ('RSC')
         THEN
            --null;
            BEGIN
               INSERT INTO gin_policy_taxes
                           (ptx_trac_scl_code, ptx_trac_trnt_code,
                            ptx_pol_policy_no, ptx_pol_ren_endos_no,
                            ptx_pol_batch_no, ptx_rate, ptx_amount,
                            ptx_tl_lvl_code, ptx_rate_type,
                            ptx_rate_desc, ptx_endos_diff_amt,
                            ptx_tax_type, ptx_risk_pol_level
                           )
                    VALUES (NULL, taxes_rec.trnt_code,
                            v_pol_policy_no, v_pol_endos_no,
                            v_pol_batch_no, taxes_rec.taxr_rate, NULL,
                            'UP', taxes_rec.taxr_rate_type,
                            taxes_rec.taxr_rate_desc, NULL,
                            taxes_rec.trnt_type, taxes_rec.rs_appl_lvl
                           );
            EXCEPTION
               WHEN OTHERS
               THEN
                  raise_error ('Error applying taxes..');
            END;