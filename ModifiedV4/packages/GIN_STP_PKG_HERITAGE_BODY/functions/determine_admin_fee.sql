FUNCTION determine_admin_fee (
      v_clnt_code    IN       NUMBER,
      v_pol_pol_no   IN       VARCHAR2 DEFAULT NULL,
      v_admin_disc   OUT      NUMBER
   )
      RETURN BOOLEAN
   IS
      v_admin_count   NUMBER;
   BEGIN
      IF v_clnt_code IS NULL
      THEN
         raise_error ('Client not provided....');
      END IF;

      --RAISE_ERROR(v_clnt_code);
      BEGIN
         SELECT COUNT (*)
           INTO v_admin_count
           FROM gin_adminstration_fee
          WHERE adf_clnt_code = v_clnt_code
            --AND ADF_POL_POLICY_NO = v_pol_pol_no
            AND NVL (adf_policy_applicable, 'N') = 'Y'
            AND NVL (adf_authorised, 'N') = 'Y'
            AND NVL (adf_paid, 'N') = 'Y'
            AND (adf_wet IS NULL OR TRUNC (SYSDATE) <= adf_wet);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_admin_count := 0;
      END;

      IF NVL (v_admin_count, 0) = 0
      THEN
         BEGIN
            SELECT COUNT (*)
              INTO v_admin_count
              FROM gin_adminstration_fee
             WHERE adf_clnt_code = v_clnt_code
               AND NVL (adf_authorised, 'N') = 'Y'
               AND NVL (adf_paid, 'N') = 'Y'
               AND (adf_wet IS NULL OR TRUNC (SYSDATE) <= adf_wet);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_admin_count := 0;
            WHEN OTHERS
            THEN
               raise_error
                       ('Error determining administration fee applicable....');
         END;
      END IF;

      IF NVL (v_admin_count, 0) > 0
      THEN
         BEGIN
            SELECT adf_disc_rate
              INTO v_admin_disc
              FROM gin_adminstration_fee
             WHERE adf_clnt_code = v_clnt_code
               --AND ADF_POL_POLICY_NO = v_pol_pol_no
               AND NVL (adf_policy_applicable, 'N') = 'Y'
               AND NVL (adf_authorised, 'N') = 'Y'
               AND NVL (adf_paid, 'N') = 'Y'
               AND (adf_wet IS NULL OR TRUNC (SYSDATE) <= adf_wet);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               BEGIN
                  SELECT adf_disc_rate
                    INTO v_admin_disc
                    FROM gin_adminstration_fee
                   WHERE adf_clnt_code = v_clnt_code
                     AND NVL (adf_authorised, 'N') = 'Y'
                     AND NVL (adf_paid, 'N') = 'Y'
                     AND (adf_wet IS NULL OR TRUNC (SYSDATE) <= adf_wet);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_admin_disc := 0;
               END;
            WHEN OTHERS
            THEN
               raise_error ('Error determining discount....');
         END;

         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END determine_admin_fee;