PROCEDURE edit_pol_clause (
        v_plcl_code        IN NUMBER,
        v_pol_code         IN NUMBER,
        v_clause           IN gin_policy_lvl_clauses.plcl_clause%TYPE,
        v_clause_heading   IN VARCHAR2)
    IS
    BEGIN
        IF tqc_parameters_pkg.get_org_type (37) NOT IN ('INS')
        THEN
            UPDATE gin_policy_lvl_clauses
               SET plcl_clause = v_clause,              --NVL(null, QC_CLAUSE)
                                           plcl_heading = v_clause_heading
             WHERE     plcl_sbcl_cls_code = v_plcl_code
                   AND plcl_pol_batch_no = v_pol_code;
        ELSE
            UPDATE gin_policy_lvl_clauses
               SET plcl_clause = v_clause, plcl_heading = v_clause_heading --NVL(null, QC_CLAUSE)
             WHERE     plcl_sbcl_cls_code = v_plcl_code
                   AND plcl_pol_batch_no = v_pol_code;
        END IF;
    END;