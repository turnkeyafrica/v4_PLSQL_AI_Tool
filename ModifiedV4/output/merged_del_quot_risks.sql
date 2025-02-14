```sql
PROCEDURE del_quot_risks (v_qr_code IN NUMBER)
IS
BEGIN
    DELETE gin_quot_risk_excess
    WHERE qre_qr_code = v_qr_code;

    DELETE gin_quot_risk_clauses
    WHERE qrc_qr_code = v_qr_code;

    DELETE gin_quot_risk_limits
    WHERE qrl_qr_code = v_qr_code;

    DELETE gin_quot_risks
    WHERE qr_code = v_qr_code;
END;
```