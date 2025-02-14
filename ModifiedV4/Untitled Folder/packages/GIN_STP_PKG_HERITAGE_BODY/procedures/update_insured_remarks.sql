PROCEDURE update_insured_remarks (v_polin_code NUMBER, v_comment VARCHAR2)
   IS
   BEGIN
      UPDATE gin_policy_insureds
         SET polin_comment = v_comment
       WHERE polin_code = v_polin_code;
   END;