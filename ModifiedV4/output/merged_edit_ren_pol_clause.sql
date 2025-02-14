```sql
PROCEDURE edit_ren_pol_clause (
    v_plcl_code        IN   NUMBER,
    v_pol_code         IN   NUMBER,
    v_clause           IN   VARCHAR2,
    v_clause_heading   IN   VARCHAR2
)
IS
BEGIN
    UPDATE gin_ren_policy_lvl_clauses
    SET plcl_clause = v_clause,
        plcl_heading = v_clause_heading
    WHERE plcl_sbcl_cls_code = v_plcl_code
    AND plcl_pol_batch_no = v_pol_code;
END;
```