```sql
PROCEDURE pop_clauses (
    v_pol_policy_no   IN VARCHAR2,
    v_pol_endos_no    IN VARCHAR2,
    v_pol_batch_no    IN NUMBER,
    v_pro_code        IN NUMBER
)
IS
    v_clause           CLOB;
    v_pro_mult_class   VARCHAR2 (1);
    v_rownum           NUMBER := 0;
    v_scl_cnt          NUMBER;

    CURSOR clause IS
        SELECT cls_heading,
               sbcl_cls_sht_desc,
               sbcl_cls_code,
               cls_type,
               DECODE (cls_type,
                       'CL', 'Clause',
                       'WR', 'Warranty',
                       'SC', 'Special Conditions'
                      )    type_desc,
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
                       'SC', 'Special Conditions'
                      )    type_desc,
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
                       'SC', 'Special Conditions'
                      )    type_desc,
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
                       'SC', 'Special Conditions'
                      )    type_desc,
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
                       'SC', 'Special Conditions'
                      )    type_desc,
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

    IF NVL (v_pro_mult_class, 'N') = 'N'  
    THEN
        FOR cls IN clause
        LOOP
            v_rownum := v_rownum + 1;
            INSERT INTO gin_policy_lvl_clauses (
                plcl_sbcl_cls_code,
                plcl_sbcl_scl_code,
                plcl_pro_sht_desc,
                plcl_pro_code,
                plcl_pol_policy_no,
                plcl_pol_ren_endos_no,
                plcl_pol_batch_no,
                plcl_sbcl_cls_sht_desc,
                plcl_cls_type,
                plcl_cls_editable,
                plcl_new,
                plcl_header,
                plcl_rownum,
                plcl_product_appl,
                plcl_heading
            )
            VALUES (
                cls.sbcl_cls_code,
                cls.clp_scl_code,
                cls.clp_pro_sht_desc,
                cls.clp_pro_code,
                v_pol_policy_no,
                v_pol_endos_no,
                v_pol_batch_no,
                cls.sbcl_cls_sht_desc,
                cls.cls_type,
                cls.cls_editable,
                'Y',
                NULL,
                v_rownum,
                'Y',
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

                UPDATE gin_policy_lvl_clauses
                   SET plcl_clause = v_clause
                 WHERE     plcl_sbcl_cls_code = cls.sbcl_cls_code
                       AND plcl_pol_batch_no = v_pol_batch_no;
            END IF;
        END LOOP;
    ELSE
        FOR pcls IN pckge_clauses
        LOOP
            IF     NVL (pcls.sclcnt, 0) = NVL (pcls.clscnt, 0)
               AND NVL (pcls.clscnt, 0) != 0
            THEN
                INSERT INTO gin_policy_lvl_clauses (
                    plcl_sbcl_cls_code,
                    plcl_sbcl_scl_code,
                    plcl_pro_sht_desc,
                    plcl_pro_code,
                    plcl_pol_policy_no,
                    plcl_pol_ren_endos_no,
                    plcl_pol_batch_no,
                    plcl_sbcl_cls_sht_desc,
                    plcl_cls_type,
                    plcl_cls_editable,
                    plcl_new,
                    plcl_header,
                    plcl_rownum,
                    plcl_product_appl,
                    plcl_heading
                )
                VALUES (
                    pcls.sbcl_cls_code,
                    pcls.clp_scl_code,
                    pcls.pro_sht_desc,
                    pcls.pro_code,
                    v_pol_policy_no,
                    v_pol_endos_no,
                    v_pol_batch_no,
                    pcls.sbcl_cls_sht_desc,
                    pcls.cls_type,
                    pcls.cls_editable,
                    'Y',
                    NULL,
                    NULL,
                    'Y',
                    pcls.cls_heading
                );

                IF NVL (pcls.cls_editable, 'N') = 'Y'
                THEN
                    SELECT cls_wording
                      INTO v_clause
                      FROM gin_clause
                     WHERE cls_code = pcls.sbcl_cls_code;

                    BEGIN
                        v_clause :=
                            merge_policies_text (v_pol_batch_no, v_clause);
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            NULL;
                    END;

                    UPDATE gin_policy_lvl_clauses
                       SET plcl_clause = v_clause
                     WHERE     plcl_sbcl_cls_code = pcls.sbcl_cls_code
                           AND plcl_pol_batch_no = v_pol_batch_no;
                END IF;
            END IF;
        END LOOP;

        FOR cls IN clause2
        LOOP
            INSERT INTO gin_policy_subclass_clauses (
                poscl_cls_code,
                poscl_sht_desc,
                poscl_heading,
                poscl_scl_code,
                poscl_pol_policy_no,
                poscl_cls_type,
                poscl_cls_editable,
                poscl_new,
                poscl_pol_batch_no,
                poscl_code
            )
            VALUES (
                cls.sbcl_cls_code,
                cls.sbcl_cls_sht_desc,
                cls.cls_heading,
                cls.clp_scl_code,
                v_pol_policy_no,
                cls.cls_type,
                cls.cls_editable,
                'Y',
                v_pol_batch_no,
                 TO_NUMBER (TO_CHAR (SYSDATE, 'RRRR'))
                || gin_poscl_code_seq.NEXTVAL
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

                UPDATE gin_policy_subclass_clauses
                   SET poscl_clause = v_clause
                 WHERE     poscl_cls_code = cls.sbcl_cls_code
                       AND poscl_pol_policy_no = v_pol_policy_no;
            END IF;
        END LOOP;

        FOR cls IN clause_autofill
        LOOP
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
            END IF;
        END LOOP;
    END IF;
END;

```