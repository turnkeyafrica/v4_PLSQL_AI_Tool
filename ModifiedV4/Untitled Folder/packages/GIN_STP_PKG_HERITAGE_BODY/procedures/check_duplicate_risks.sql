PROCEDURE check_duplicate_risks (v_pol_batch_no IN NUMBER)
   IS
      v_cnt                NUMBER;
      v_allow_duplicates   VARCHAR2 (5);
      v_msg                VARCHAR2 (2000);

      CURSOR dup_risk
      IS
         SELECT   ipu_pol_batch_no, ipu_property_id
             FROM gin_insured_property_unds, gin_policy_active_risks
            WHERE ipu_code = polar_ipu_code
              AND polar_pol_batch_no = v_pol_batch_no
           HAVING COUNT (1) > 1
         GROUP BY ipu_pol_batch_no, ipu_property_id;
   BEGIN
      raise_error ('INNNNNNNNNN11111');

      BEGIN
         v_allow_duplicates :=
            gin_parameters_pkg.get_param_varchar
                                                ('ALLOW_DUPLICATION_OF_RISKS');
      EXCEPTION
         WHEN OTHERS
         THEN
            v_allow_duplicates := 'Y';
      END;