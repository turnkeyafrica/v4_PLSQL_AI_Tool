PROCEDURE edit_ren_risk_clause (v_pocl_code   IN NUMBER,
                                    v_ipu_code    IN NUMBER,
                                    v_clause      IN VARCHAR2)
    IS
    BEGIN
        UPDATE gin_ren_policy_clauses
           SET pocl_clause = v_clause                   --NVL(null, QC_CLAUSE)
         WHERE     pocl_sbcl_cls_code = v_pocl_code
               AND pocl_ipu_code = v_ipu_code;
    END;