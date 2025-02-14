PROCEDURE pop_clauses (v_pol_policy_no   IN VARCHAR2,
                           v_pol_endos_no    IN VARCHAR2,
                           v_pol_batch_no    IN NUMBER,
                           v_pro_code        IN NUMBER)
    IS
        v_clause           CLOB;
        v_pro_mult_class   VARCHAR2 (1);

        CURSOR clause IS
            SELECT cls_heading,
                   sbcl_cls_sht_desc,
                   sbcl_cls_code,
                   cls_type,
                   DECODE (cls_type,
                           'CL', 'Clause',
                           'WR', 'Warranty',
                           'SC', 'Special Conditions')    type_desc,
                   clp_pro_code,
                   clp_pro_sht_desc,
                   clp_scl_code,
                   cls_editable                               --,--CLS_WORDING
              FROM gin_subcl_clauses, gin_product_sub_classes, gin_clause
             WHERE     clp_scl_code = sbcl_scl_code
                   AND sbcl_cls_code = cls_code
                   AND clp_pro_code = v_pro_code
                   AND NVL (sbcl_cls_mandatory, 'N') = 'Y'
                   AND NVL (sbcl_cls_lien_clause, 'N') != 'Y'
                   AND cls_code NOT IN
                           (SELECT plcl_sbcl_cls_code
                              FROM gin_policy_lvl_clauses
                             WHERE plcl_pol_batch_no = v_pol_batch_no)
            UNION
            SELECT cls_heading,
                   scvtmc_cls_sht_desc,
                   scvtmc_cls_code,
                   cls_type,
                   DECODE (cls_type,
                           'CL', 'Clause',
                           'WR', 'Warranty',
                           'SC', 'Special Conditions')    type_desc,
                   clp_pro_code,
                   clp_pro_sht_desc,
                   clp_scl_code,
                   cls_editable                               --,--CLS_WORDING
              FROM gin_scl_cvt_mand_clauses,
                   gin_product_sub_classes,
                   gin_clause
             WHERE     clp_scl_code = scvtmc_scl_code
                   AND scvtmc_cls_code = cls_code
                   AND clp_pro_code = v_pro_code
                   AND NVL (scvmtc_cls_mandatory, 'N') = 'Y'
                   AND scvtmc_sclcovt_code IN
                           (SELECT ipu_covt_code
                              FROM gin_insured_property_unds
                             WHERE ipu_pol_batch_no = v_pol_batch_no)
                   AND cls_code NOT IN
                           (SELECT plcl_sbcl_cls_code
                              FROM gin_policy_lvl_clauses
                             WHERE plcl_pol_batch_no = v_pol_batch_no)
                   AND scvtmc_cls_code NOT IN
                           (SELECT sbcl_cls_code
                              FROM gin_subcl_clauses
                             WHERE     NVL (sbcl_cls_mandatory, 'N') = 'Y'
                                   AND sbcl_scl_code IN
                                           (SELECT ipu_sec_scl_code
                                              FROM gin_insured_property_unds
                                             WHERE ipu_pol_batch_no =
                                                   v_pol_batch_no));

        CURSOR pckge_clauses IS
            SELECT pro_code,
                   pro_sht_desc,
                   sbcl_cls_code,
                   sclcnt,
                   clscnt,
                   sbcl_cls_sht_desc,
                   cls_heading,
                   cls_type,
                   cls_editable,
                   clp_scl_code
              FROM (  SELECT pro_code,
                             pro_sht_desc,
                             MAX (clp_scl_code)     clp_scl_code,
                             COUNT (1)              sclcnt
                        FROM gin_products, gin_product_sub_classes
                       WHERE pro_code = clp_pro_code
                    --    AND pro_code = 810
                    GROUP BY pro_code, pro_sht_desc),
                   (  SELECT clp_pro_code,
                             sbcl_cls_code,
                             sbcl_cls_sht_desc,
                             cls_heading,
                             cls_type,
                             cls_editable,
                             COUNT (1)     clscnt
                        FROM gin_subcl_clauses,
                             gin_product_sub_classes,
                             gin_clause
                       WHERE     clp_scl_code = sbcl_scl_code
                             AND sbcl_cls_code = cls_code
                             AND NVL (sbcl_cls_mandatory, 'N') = 'Y'
                             AND NVL (sbcl_cls_lien_clause, 'N') != 'Y'
                    -- AND CLP_pro_code = 810
                    GROUP BY clp_pro_code,
                             sbcl_cls_code,
                             sbcl_cls_sht_desc,
                             cls_heading,
                             cls_type,
                             cls_editable) b
             WHERE     pro_code = clp_pro_code(+)
                   AND sbcl_cls_code NOT IN
                           (SELECT plcl_sbcl_cls_code
                              FROM gin_policy_lvl_clauses
                             WHERE plcl_pol_batch_no = v_pol_batch_no)
                   AND pro_code = (SELECT pol_pro_code
                                     FROM gin_policies
                                    WHERE pol_batch_no = v_pol_batch_no);

        CURSOR clause2 IS
            SELECT cls_heading,
                   sbcl_cls_sht_desc,
                   sbcl_cls_code,
                   cls_type,
                   DECODE (cls_type,
                           'CL', 'Clause',
                           'WR', 'Warranty',
                           'SC', 'Special Conditions')    type_desc,
                   clp_pro_code,
                   clp_pro_sht_desc,
                   clp_scl_code,
                   cls_editable                               --,--CLS_WORDING
              FROM gin_subcl_clauses, gin_product_sub_classes, gin_clause
             WHERE     clp_scl_code = sbcl_scl_code
                   AND sbcl_cls_code = cls_code
                   AND clp_pro_code = v_pro_code
                   AND NVL (sbcl_cls_mandatory, 'N') = 'Y'
                   AND NVL (sbcl_cls_lien_clause, 'N') != 'Y'
                   AND clp_scl_code IN
                           (SELECT ipu_sec_scl_code
                              FROM gin_insured_property_unds
                             WHERE ipu_pol_batch_no = v_pol_batch_no)
                   /* AND cls_code NOT IN
                           (SELECT plcl_sbcl_cls_code
                              FROM gin_policy_lvl_clauses
                             WHERE plcl_pol_batch_no = v_pol_batch_no)*/
                   AND NOT EXISTS
                           (SELECT poscl_scl_code, poscl_cls_code
                              FROM gin_policy_subclass_clauses
                             WHERE     poscl_pol_policy_no = v_pol_policy_no
                                   AND poscl_scl_code = clp_scl_code
                                   AND poscl_cls_code = cls_code);

        CURSOR clause_autofill IS
            SELECT cls_heading,
                   sbcl_cls_sht_desc,
                   sbcl_cls_code,
                   cls_type,
                   DECODE (cls_type,
                           'CL', 'Clause',
                           'WR', 'Warranty',
                           'SC', 'Special Conditions')    type_desc,
                   clp_pro_code,
                   clp_pro_sht_desc,
                   clp_scl_code,
                   cls_editable
              FROM gin_subcl_clauses, gin_product_sub_classes, gin_clause
             WHERE     clp_scl_code = sbcl_scl_code
                   AND sbcl_cls_code = cls_code
                   AND clp_pro_code = v_pro_code
                   AND NVL (sbcl_cls_lien_clause, 'N') != 'Y'
                   AND cls_code IN
                           (SELECT plcl_sbcl_cls_code
                              FROM gin_policy_lvl_clauses
                             WHERE plcl_pol_batch_no = v_pol_batch_no)
            UNION
            SELECT cls_heading,
                   scvtmc_cls_sht_desc,
                   scvtmc_cls_code,
                   cls_type,
                   DECODE (cls_type,
                           'CL', 'Clause',
                           'WR', 'Warranty',
                           'SC', 'Special Conditions')    type_desc,
                   clp_pro_code,
                   clp_pro_sht_desc,
                   clp_scl_code,
                   cls_editable
              FROM gin_scl_cvt_mand_clauses,
                   gin_product_sub_classes,
                   gin_clause
             WHERE     clp_scl_code = scvtmc_scl_code
                   AND scvtmc_cls_code = cls_code
                   AND clp_pro_code = v_pro_code
                   AND cls_code IN
                           (SELECT plcl_sbcl_cls_code
                              FROM gin_policy_lvl_clauses
                             WHERE plcl_pol_batch_no = v_pol_batch_no);

        v_rownum           NUMBER := 0;
        v_scl_cnt          NUMBER;
    BEGIN
        BEGIN
              SELECT pro_mult_class, COUNT (1)
                INTO v_pro_mult_class, v_scl_cnt
                FROM gin_products, gin_product_sub_classes
               WHERE pro_code = clp_pro_code AND pro_code = v_pro_code
            GROUP BY pro_mult_class;
        EXCEPTION
            WHEN OTHERS
            THEN
                NULL;
        END;