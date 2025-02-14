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

      FOR cls IN clause (v_scl_code)
      LOOP
         SELECT cls_wording
           INTO v_clause
           FROM gin_clause
          WHERE cls_code = cls.sbcl_cls_code;

         INSERT INTO gin_policy_clauses
                     (pocl_sbcl_cls_code, pocl_cls_sht_desc,
                      pocl_sbcl_scl_code, pocl_pol_policy_no,
                      pocl_pol_ren_endos_no, pocl_pol_batch_no,
                      pocl_ipu_code, plcl_cls_type, pocl_clause,
                      pocl_cls_editable, pocl_new, pocl_heading
                     )
              VALUES (cls.sbcl_cls_code, cls.sbcl_cls_sht_desc,
                      cls.clp_scl_code, v_pol_policy_no,
                      v_pol_endos_no, v_pol_batch_no,
                      v_ipu_code, cls.cls_type, v_clause,
                      cls.cls_editable, 'Y', cls.cls_heading
                     );

         IF NVL (cls.cls_editable, 'N') = 'Y'
         THEN
            SELECT cls_wording
              INTO v_clause
              FROM gin_clause
             WHERE cls_code = cls.sbcl_cls_code;

            BEGIN
               v_clause := merge_policies_text (v_pol_batch_no, v_clause);
            EXCEPTION
               WHEN OTHERS
               THEN
                  NULL;
            END;

            UPDATE gin_policy_clauses
               SET pocl_clause = v_clause
             WHERE pocl_sbcl_cls_code = cls.sbcl_cls_code
               AND pocl_ipu_code = v_ipu_code;
         END IF;
      END LOOP;
   END;