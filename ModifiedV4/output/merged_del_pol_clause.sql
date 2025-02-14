```sql
PROCEDURE del_pol_clause (v_plcl_code IN NUMBER, v_pol_code IN NUMBER)
    IS
        v_cnt                NUMBER;
        v_count              NUMBER;
        v_trans_no           NUMBER;
        v_trans_code         VARCHAR2 (5);
        v_del_mand_clauses   VARCHAR2 (1) := 'N';
    BEGIN
        BEGIN
            v_del_mand_clauses :=
                gin_parameters_pkg.get_param_varchar ('DEL_MANDATORY_CLAUSE');
        EXCEPTION
            WHEN OTHERS
            THEN
                v_del_mand_clauses := 'N';
        END;

        --  RAISE_eRROR('v_plcl_code= '||v_plcl_code||'v_pol_code=='||v_pol_code);
        BEGIN
            SELECT ggt_trans_no, ggt_btr_trans_code
              INTO v_trans_no, v_trans_code
              FROM gin_gis_transactions
             WHERE ggt_pol_batch_no = v_pol_code;

            SELECT COUNT (1)
              INTO v_cnt
              FROM gin_subcl_clauses
             WHERE     sbcl_cls_code = v_plcl_code
                   AND sbcl_cls_mandatory = 'Y'
                   AND sbcl_scl_code IN
                           (SELECT ipu_sec_scl_code
                              FROM gin_insured_property_unds
                             WHERE ipu_pol_batch_no = v_pol_code);

        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                v_cnt := 0;
                v_count := 0;
            WHEN OTHERS
            THEN
                v_cnt := 0;
                v_count := 0;
        END;

        IF     NVL (v_del_mand_clauses, 'N') != 'Y'
           AND (NVL (v_count, 0) != 0 OR NVL (v_cnt, 0) != 0)
        THEN
            raise_when_others ('Error.. Cannot Delete  Mandatory Clauses');
        ELSE
            IF NVL (v_count, 0) != 0 OR NVL (v_cnt, 0) != 0
            THEN
                BEGIN
                    gin_manage_exceptions.proc_del_mand_clauses_except (
                        v_pol_code,
                        v_trans_no,
                        TRUNC (SYSDATE),
                        v_trans_code);
                END;

                DELETE gin_policy_lvl_clauses
                 WHERE     plcl_sbcl_cls_code = v_plcl_code
                       AND plcl_pol_batch_no = v_pol_code;
            ELSE
                DELETE gin_policy_lvl_clauses
                 WHERE     plcl_sbcl_cls_code = v_plcl_code
                       AND plcl_pol_batch_no = v_pol_code;
            END IF;
        END IF;
    END;

```