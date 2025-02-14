PROCEDURE pop_ren_taxes (
      v_pol_policy_no   IN   VARCHAR2,
      v_pol_endos_no    IN   VARCHAR2,
      v_pol_batch_no    IN   NUMBER,
      v_pro_code        IN   NUMBER,
      v_pol_binder      IN   VARCHAR2 DEFAULT 'N',
      v_trans_type      IN   VARCHAR2
   )
   IS
      CURSOR taxes
      IS
         SELECT *
           FROM gin_taxes_types_view
          WHERE (   scl_code IS NULL
                 OR scl_code IN (SELECT clp_scl_code
                                   FROM gin_product_sub_classes
                                  WHERE clp_pro_code = v_pro_code)
                )
            AND trnt_mandatory = 'Y'
            AND trnt_type IN ('UTX', 'UTL', 'EX', 'PHFUND','PRM-VAT','ROAD','HEALTH','CERTCHG','MOTORTX')            --'SD',
            AND taxr_trnt_code NOT IN (
                                       SELECT ptx_trac_trnt_code
                                         FROM gin_ren_policy_taxes
                                        WHERE ptx_pol_batch_no =
                                                                v_pol_batch_no)
            AND NVL (DECODE (v_trans_type,
                             'NB', trnt_apply_nb,
                             'SP', trnt_apply_sp,
                             'RN', trnt_apply_rn,
                             'EN', trnt_apply_en,
                             'CN', trnt_apply_cn,
                             'EX', trnt_apply_ex,
                             'DC', trnt_apply_dc,
                             'RE', trnt_apply_re
                            ),
                     'N'
                    ) = 'Y'
            AND trnt_code NOT IN (SELECT petx_trnt_code
                                    FROM gin_product_excluded_taxes
                                   WHERE petx_pro_code = v_pro_code);
   BEGIN
      FOR taxes_rec IN taxes
      LOOP
         IF NOT (taxes_rec.trnt_type = 'SD' AND NVL (v_pol_binder, 'N') = 'Y'
                )
         THEN
            BEGIN
               INSERT INTO gin_ren_policy_taxes
                           (ptx_trac_scl_code, ptx_trac_trnt_code,
                            ptx_pol_policy_no, ptx_pol_ren_endos_no,
                            ptx_pol_batch_no, ptx_rate, ptx_amount,
                            ptx_tl_lvl_code, ptx_rate_type,
                            ptx_rate_desc, ptx_endos_diff_amt,
                            ptx_tax_type, ptx_risk_pol_level
                           )
                    VALUES (taxes_rec.taxr_scl_code, taxes_rec.trnt_code,
                            v_pol_policy_no, v_pol_endos_no,
                            v_pol_batch_no, taxes_rec.taxr_rate, NULL,
                            'UP', taxes_rec.taxr_rate_type,
                            taxes_rec.taxr_rate_desc, NULL,
                            taxes_rec.trnt_type, 'P'
                           );
            EXCEPTION
               WHEN OTHERS
               THEN
                  raise_error ('Error applying taxes..');
            END;