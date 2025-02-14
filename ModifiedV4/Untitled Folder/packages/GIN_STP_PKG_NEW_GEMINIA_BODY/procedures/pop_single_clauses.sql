PROCEDURE pop_single_clauses (v_pol_policy_no   IN VARCHAR2,
                                  v_pol_endos_no    IN VARCHAR2,
                                  v_cls_code        IN VARCHAR2,
                                  v_pol_batch_no    IN NUMBER,
                                  v_pro_code        IN NUMBER)
    IS
        v_clause   CLOB;
        v_cnt      NUMBER;

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
                   AND cls_code = v_cls_code
                   AND ROWNUM = 1
                   AND cls_code NOT IN
                           (SELECT plcl_sbcl_cls_code
                              FROM gin_policy_lvl_clauses
                             WHERE plcl_pol_batch_no = v_pol_batch_no);
    BEGIN
        FOR cls IN clause
        LOOP
            BEGIN
                SELECT COUNT (1)
                  INTO v_cnt
                  FROM gin_policy_lvl_clauses
                 WHERE     plcl_sbcl_cls_code = cls.sbcl_cls_code
                       AND plcl_pol_batch_no = v_pol_batch_no;
            EXCEPTION
                WHEN OTHERS
                THEN
                    NULL;
            END;