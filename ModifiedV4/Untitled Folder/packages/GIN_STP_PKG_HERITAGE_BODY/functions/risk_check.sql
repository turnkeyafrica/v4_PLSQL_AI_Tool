FUNCTION risk_check (
      v_batch_no        IN       NUMBER,
      v_prev_ipu_code   IN       NUMBER,
      v_new_ipu_code    OUT      NUMBER
   )
      RETURN VARCHAR2
   IS
      v_count   NUMBER;
   BEGIN
      BEGIN
         SELECT   COUNT (*), ipu_code
             INTO v_count, v_new_ipu_code
             FROM gin_insured_property_unds
            WHERE ipu_prev_ipu_code = v_prev_ipu_code
              AND ipu_pol_batch_no = v_batch_no
         GROUP BY ipu_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            RETURN 'N';
         WHEN OTHERS
         THEN
            raise_error ('Error determining if the risk exist....');
      END;