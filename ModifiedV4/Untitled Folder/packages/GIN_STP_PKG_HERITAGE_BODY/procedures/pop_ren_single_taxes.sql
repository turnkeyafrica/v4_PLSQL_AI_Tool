PROCEDURE pop_ren_single_taxes (
      v_pol_policy_no    IN   VARCHAR2,
      v_pol_endos_no     IN   VARCHAR2,
      v_pol_batch_no     IN   NUMBER,
      v_pro_code         IN   NUMBER,
      v_pol_binder       IN   VARCHAR2 DEFAULT 'N',
      v_taxr_trnt_code   IN   VARCHAR2,
      v_tax_type         IN   VARCHAR2,
      v_trans_lvl        IN   VARCHAR2,
      v_comp_lvl         IN   VARCHAR2,
      v_rate             IN   NUMBER,
      v_amt              IN   NUMBER,
      v_add_edit         IN   VARCHAR2
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
            --AND TRNT_MANDATORY = 'Y'
            --AND TRNT_TYPE IN ('UTX','SD','UTL','EX','PHFUND')
            AND taxr_trnt_code = v_taxr_trnt_code;
   /*AND taxr_trnt_code NOT IN
       (SELECT ptx_trac_trnt_code
          FROM gin_ren_policy_taxes
         WHERE ptx_pol_batch_no = v_pol_batch_no)*/
   BEGIN
      FOR taxes_rec IN taxes
      LOOP
         IF v_add_edit = 'A'
         THEN
            IF NOT (taxes_rec.trnt_type = 'SD'
                    AND NVL (v_pol_binder, 'N') = 'Y'
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
                               v_pol_batch_no, v_rate, v_amt,
                               v_trans_lvl, taxes_rec.taxr_rate_type,
                               taxes_rec.taxr_rate_desc, NULL,
                               v_tax_type, v_comp_lvl
                              );
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     raise_error ('Error applying taxes..');
               END;