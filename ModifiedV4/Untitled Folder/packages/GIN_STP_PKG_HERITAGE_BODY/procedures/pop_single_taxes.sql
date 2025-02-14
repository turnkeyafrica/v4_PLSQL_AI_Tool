PROCEDURE pop_single_taxes (
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
      CURSOR sub_class
      IS
         SELECT ipu_sec_scl_code
           FROM gin_insured_property_unds
          WHERE ipu_pol_batch_no = v_pol_batch_no;

      CURSOR taxes (v_scl_code NUMBER)
      IS
         SELECT *
           FROM gin_taxes_types_view
          WHERE (   scl_code IS NULL
                 OR scl_code IN (
                       SELECT clp_scl_code
                         FROM gin_product_sub_classes
                        WHERE clp_pro_code = v_pro_code
                          AND clp_scl_code = v_scl_code)
                )
            --AND TRNT_MANDATORY = 'Y'
            --AND TRNT_TYPE IN ('UTX','SD','UTL','EX','PHFUND')
            AND taxr_trnt_code = v_taxr_trnt_code
     AND taxr_trnt_code NOT IN
         (SELECT ptx_trac_trnt_code
            FROM gin_policy_taxes
           WHERE ptx_pol_batch_no = v_pol_batch_no);
   BEGIN
      --RAISE_ERROR(' v_pro_code '||v_pro_code||' v_taxr_trnt_code '||v_taxr_trnt_code||' v_add_edit '||v_add_edit||' v_pol_binder '||v_pol_binder);

      -- TQC_ERROR_MANAGER.RAISE_UNANTICIPATED(v_add_edit||'='||v_pol_policy_no||'='||v_pol_endos_no||'='||v_taxr_trnt_code||'='||v_pol_batch_no||'='|| v_rate);
      FOR sub_class_rec IN sub_class
      LOOP
         FOR taxes_rec IN taxes (sub_class_rec.ipu_sec_scl_code)
         LOOP
            IF v_add_edit = 'A'
            THEN
               IF NOT (    taxes_rec.trnt_type = 'SD'
                       AND NVL (v_pol_binder, 'N') = 'Y'
                      )
               THEN
                  BEGIN
                     INSERT INTO gin_policy_taxes
                                 (ptx_trac_scl_code,
                                  ptx_trac_trnt_code, ptx_pol_policy_no,
                                  ptx_pol_ren_endos_no, ptx_pol_batch_no,
                                  ptx_rate, ptx_amount,
                                  ptx_tl_lvl_code,
                                  ptx_rate_type,
                                  ptx_rate_desc, ptx_endos_diff_amt,
                                  ptx_tax_type, ptx_risk_pol_level
                                 )
                          VALUES (taxes_rec.taxr_scl_code,
                                  taxes_rec.trnt_code, v_pol_policy_no,
                                  v_pol_endos_no, v_pol_batch_no,
                                  NVL (v_rate, taxes_rec.taxr_rate), v_amt,
                                  NVL (v_trans_lvl, 'UP'),
                                  taxes_rec.taxr_rate_type,
                                  taxes_rec.taxr_rate_desc, NULL,
                                  taxes_rec.trnt_type, NVL (v_comp_lvl, 'P')
                                 );
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        raise_error ('Error applying taxes..');
                  END;