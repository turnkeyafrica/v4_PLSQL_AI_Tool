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