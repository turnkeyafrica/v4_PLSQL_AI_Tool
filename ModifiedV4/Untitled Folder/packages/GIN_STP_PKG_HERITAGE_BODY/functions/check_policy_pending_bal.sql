FUNCTION check_policy_pending_bal (v_pol_batch_no NUMBER)
      RETURN VARCHAR2
   IS
      v_error       VARCHAR2 (200);
      v_clnt_code   NUMBER;
      v_agn_code    NUMBER;
      v_count       NUMBER;
   BEGIN
      v_error := '';

      BEGIN
         SELECT pol_prp_code, pol_agnt_agent_code
           INTO v_clnt_code, v_agn_code
           FROM gin_policies
          WHERE pol_batch_no = v_pol_batch_no;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_error := 'Error getting policy details...' || v_pol_batch_no;
            RETURN v_error;
      END;