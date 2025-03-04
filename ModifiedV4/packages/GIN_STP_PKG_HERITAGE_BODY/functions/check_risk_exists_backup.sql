FUNCTION check_risk_exists_backup (
      v_pol_batch_no       IN       NUMBER,
      v_scl_code           IN       NUMBER,
      v_property_id        IN       VARCHAR2,
      v_allow_duplicates   OUT      VARCHAR2
   )
      RETURN VARCHAR2
   IS
      v_cnt   NUMBER;
      v_msg   VARCHAR2 (2000);
      v_id    NUMBER;
   BEGIN
      raise_error ('INNNNNNNNNNNN222');

      BEGIN
         v_allow_duplicates :=
            gin_parameters_pkg.get_param_varchar
                                                ('ALLOW_DUPLICATION_OF_RISKS');
      EXCEPTION
         WHEN OTHERS
         THEN
            v_allow_duplicates := 'Y';
      END;

      BEGIN
         SELECT COUNT (1)
           INTO v_cnt
           FROM gin_policies, gin_insured_property_unds, gin_sub_classes
          WHERE pol_batch_no = ipu_pol_batch_no
            AND pol_current_status NOT IN ('CO', 'CN')
            AND pol_policy_status != 'CO'
            AND ipu_sec_scl_code = v_scl_code
            AND ipu_sec_scl_code = scl_code
            AND NVL (scl_risk_unique, 'N') = 'Y'
            AND ipu_property_id = v_property_id
            AND ipu_pol_batch_no <> v_pol_batch_no;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_msg := 'Error checking risk duplicates..';
            RETURN (v_msg);
      END;

      IF NVL (v_cnt, 0) != 0
      THEN
         v_msg :=
               'This risk/s ID '
            || v_property_id
            || ' is/are duplicated2222 '
            || v_cnt
            || ' times.';
         RETURN (v_msg);
      ELSE
         RETURN NULL;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_msg := 'Error checking risk duplicates..';
         RETURN (v_msg);
   END;