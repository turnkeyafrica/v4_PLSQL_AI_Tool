PROCEDURE delete_pol_risk_services (
   v_action         IN   VARCHAR2,
   v_prs_code       IN   NUMBER,
   v_ipu_code       IN   NUMBER
)
IS
BEGIN
   
   IF NVL(v_action, 'X') = 'D'
   THEN
--          raise_error('testing-error');
          DELETE FROM GIN_POLICY_RISK_SERVICES
                WHERE prs_ipu_code = v_ipu_code
                  AND prs_code = v_prs_code;
   END IF;
   
EXCEPTION
   WHEN OTHERS
   THEN
      raise_error (SQLERRM);
END;