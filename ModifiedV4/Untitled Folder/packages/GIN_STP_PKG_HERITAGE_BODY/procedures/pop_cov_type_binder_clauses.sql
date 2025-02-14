PROCEDURE pop_cov_type_binder_clauses (
      v_pol_policy_no   IN   VARCHAR2,
      v_pol_endos_no    IN   VARCHAR2,
      v_pol_batch_no    IN   NUMBER,
      v_pro_code        IN   NUMBER
   )
   IS
      v_clause   LONG;

      CURSOR clause
      IS
         SELECT cls_heading, sbcl_cls_sht_desc, sbcl_cls_code, cls_type,
                DECODE (cls_type,
                        'CL', 'Clause',
                        'WR', 'Warranty',
                        'SC', 'Special Conditions'
                       ) type_desc,
                clp_pro_code, clp_pro_sht_desc, clp_scl_code,
                cls_editable                                 --,--CLS_WORDING
           FROM gin_subcl_clauses, gin_product_sub_classes, gin_clause
          WHERE clp_scl_code = sbcl_scl_code
            AND sbcl_cls_code = cls_code
            AND cls_code IN (
                   SELECT bsccl_cls_code
                     FROM gin_binder_subcl_clauses, gin_policies
                    WHERE pol_bind_code = bsccl_bind_code
                      AND pol_batch_no = v_pol_batch_no
                      AND NVL (pol_binder_policy, 'N') = 'Y')
            AND clp_pro_code = v_pro_code
            --AND NVL(SBCL_CLS_MANDATORY,'N') = 'Y'
            AND cls_code NOT IN (SELECT plcl_sbcl_cls_code
                                   FROM gin_policy_lvl_clauses
                                  WHERE plcl_pol_batch_no = v_pol_batch_no)
         UNION
         SELECT cls_heading, scvtmc_cls_sht_desc, scvtmc_cls_code, cls_type,
                DECODE (cls_type,
                        'CL', 'Clause',
                        'WR', 'Warranty',
                        'SC', 'Special Conditions'
                       ) type_desc,
                clp_pro_code, clp_pro_sht_desc, clp_scl_code,
                cls_editable                                  --,--CLS_WORDING
           FROM gin_scl_cvt_mand_clauses, gin_product_sub_classes, gin_clause
          WHERE clp_scl_code = scvtmc_scl_code
            AND scvtmc_cls_code = cls_code
            AND clp_pro_code = v_pro_code
            AND NVL (scvmtc_cls_mandatory, 'N') = 'Y'
            AND cls_code NOT IN (SELECT plcl_sbcl_cls_code
                                   FROM gin_policy_lvl_clauses
                                  WHERE plcl_pol_batch_no = v_pol_batch_no)
            AND scvtmc_cls_code NOT IN (
                                      SELECT sbcl_cls_code
                                        FROM gin_subcl_clauses
                                       WHERE NVL (sbcl_cls_mandatory, 'N') =
                                                                           'Y');
   BEGIN
      FOR cls IN clause
      LOOP
         INSERT INTO gin_policy_lvl_clauses
                     (plcl_sbcl_cls_code, plcl_sbcl_scl_code,
                      plcl_pro_sht_desc, plcl_pro_code,
                      plcl_pol_policy_no, plcl_pol_ren_endos_no,
                      plcl_pol_batch_no, plcl_sbcl_cls_sht_desc,
                      plcl_cls_type,                            --PLCL_CLAUSE,
                                    plcl_cls_editable, plcl_new,
                      plcl_header, plcl_rownum, plcl_product_appl,
                      plcl_heading
                     )
              VALUES (cls.sbcl_cls_code, cls.clp_scl_code,
                      cls.clp_pro_sht_desc, cls.clp_pro_code,
                      v_pol_policy_no, v_pol_endos_no,
                      v_pol_batch_no, cls.sbcl_cls_sht_desc,
                      cls.cls_type,                             --PLCL_CLAUSE,
                                   cls.cls_editable, 'Y',
                      NULL, NULL, 'Y',
                      cls.cls_heading
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