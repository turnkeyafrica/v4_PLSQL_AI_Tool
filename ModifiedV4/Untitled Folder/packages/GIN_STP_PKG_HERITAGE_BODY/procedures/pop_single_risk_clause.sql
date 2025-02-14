PROCEDURE pop_single_risk_clause (
      v_pol_policy_no   IN   VARCHAR2,
      v_pol_endos_no    IN   VARCHAR2,
      v_cls_code        IN   VARCHAR2,
      v_pol_batch_no    IN   NUMBER,
      v_pro_code        IN   NUMBER,
      v_ipu_code        IN   NUMBER
   )
   IS
      v_clause     CLOB;
      v_scl_code   NUMBER;

      CURSOR clause (v_sclcode NUMBER)
      IS
         SELECT DISTINCT cls_heading, sbcl_cls_sht_desc, sbcl_cls_code,
                         cls_type,
                         DECODE (cls_type,
                                 'CL', 'Clause',
                                 'WR', 'Warranty',
                                 'SC', 'Special Conditions'
                                ) type_desc,
                         clp_pro_code, clp_pro_sht_desc, clp_scl_code,
                         cls_editable
                    FROM gin_subcl_clauses,
                         gin_product_sub_classes,
                         gin_clause
                   WHERE clp_scl_code = sbcl_scl_code
                     AND sbcl_cls_code = cls_code
                     AND sbcl_scl_code = v_sclcode
                     AND clp_pro_code = v_pro_code
                     AND cls_code = v_cls_code
                     AND cls_code NOT IN (
                            SELECT pocl_sbcl_cls_code
                              FROM gin_policy_clauses
                             WHERE pocl_pol_batch_no = v_pol_batch_no
                               AND pocl_ipu_code = v_ipu_code);
   BEGIN
      BEGIN
         SELECT ipu_sec_scl_code
           INTO v_scl_code
           FROM gin_insured_property_unds
          WHERE ipu_code = v_ipu_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            raise_error ('Error getting Risk Sub class');
      END;