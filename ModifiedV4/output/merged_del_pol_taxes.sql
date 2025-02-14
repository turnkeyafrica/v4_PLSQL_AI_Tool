```sql
PROCEDURE del_pol_taxes (v_trnt_code IN VARCHAR2, v_pol_code IN NUMBER)
IS
BEGIN
    DELETE gin_policy_taxes
    WHERE ptx_trac_trnt_code = v_trnt_code
    AND ptx_pol_batch_no = v_pol_code;
END;
```