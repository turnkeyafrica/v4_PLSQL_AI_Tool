```sql
PROCEDURE del_risk_clause (v_pocl_code IN NUMBER, v_ipu_code IN NUMBER)
IS
BEGIN
  DELETE gin_policy_clauses
  WHERE pocl_sbcl_cls_code = v_pocl_code
  AND pocl_ipu_code = v_ipu_code;
END;
```