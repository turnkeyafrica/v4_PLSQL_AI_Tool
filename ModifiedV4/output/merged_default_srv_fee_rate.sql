```sql
PROCEDURE default_srv_fee_rate (v_fee_rate OUT NUMBER)
   IS
   BEGIN
      BEGIN
         SELECT gin_parameters_pkg.get_param_number ('DEFAULTSRVFEERATE')
           INTO v_fee_rate
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_fee_rate := NULL;
      END;
   END;
```