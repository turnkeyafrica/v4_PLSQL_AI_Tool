PROCEDURE get_policy_no (
      v_prod_code       IN       NUMBER,
      v_prod_sht_desc   IN       VARCHAR2,
      v_brn_code        IN       NUMBER,
      v_brn_sht_desc    IN       VARCHAR2,
      v_pol_binder      IN       VARCHAR2,
      v_pol_type        IN       VARCHAR2,
      v_policy_no       IN OUT   VARCHAR2,
      v_endos_no        IN OUT   VARCHAR2,
      v_batch_no        IN OUT   NUMBER
   )
   IS
      v_serial       VARCHAR2 (10);
      v_pol_prefix   VARCHAR2 (15);
   BEGIN
      DBMS_OUTPUT.put_line ('GPOL' || 1);

      IF v_policy_no IS NULL
      THEN
         BEGIN
            SELECT pro_policy_prefix
              INTO v_pol_prefix
              FROM gin_products
             WHERE pro_code = v_prod_code;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               raise_error (   'The product '
                            || v_prod_sht_desc
                            || ' is not defined in the setup'
                           );
            WHEN OTHERS
            THEN
               raise_error
                  (   'Unable to retrieve the policy prefix for the product '
                   || v_prod_sht_desc
                  );
         END;