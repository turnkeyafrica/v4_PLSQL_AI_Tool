PROCEDURE edit_pol_taxes (
      v_trnt_code   IN   VARCHAR2,
      v_pol_code    IN   NUMBER,
      v_tax_type    IN   VARCHAR2,
      v_trans_lvl   IN   VARCHAR2,
      v_comp_lvl    IN   VARCHAR2,
      v_rate        IN   NUMBER,
      v_amt         IN   NUMBER
   )
   IS
   BEGIN
      UPDATE gin_policy_taxes
         SET ptx_rate = NVL (v_rate, ptx_rate),
             ptx_amount = NVL (v_amt, ptx_amount),
             ptx_tl_lvl_code = NVL (v_trans_lvl, ptx_tl_lvl_code),
             ptx_tax_type = NVL (v_tax_type, ptx_tax_type),
             ptx_risk_pol_level = NVL (v_comp_lvl, ptx_risk_pol_level)
       WHERE ptx_trac_trnt_code = v_trnt_code
             AND ptx_pol_batch_no = v_pol_code;
   END;