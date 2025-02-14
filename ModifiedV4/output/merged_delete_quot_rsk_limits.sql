```sql
PROCEDURE delete_quot_rsk_limits (v_qr_code IN NUMBER)
IS
BEGIN
    DELETE gin_quot_risk_limits
    WHERE qrl_qr_code = v_qr_code
    AND qrl_sect_type IN ('SC', 'CC', 'VA');
END;
```