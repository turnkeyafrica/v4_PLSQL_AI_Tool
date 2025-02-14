```sql
PROCEDURE delete_ren_risk_section (
      v_pil_code   IN   NUMBER,
      v_batch_no   IN   NUMBER DEFAULT NULL
   )
   IS
   BEGIN
      DELETE      gin_ren_policy_insured_limits
            WHERE pil_code = v_pil_code;
   END;
```