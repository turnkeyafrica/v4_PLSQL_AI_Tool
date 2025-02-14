PROCEDURE delete_rsk_limits (
      v_ipu_code   IN   NUMBER
   )
   IS
   BEGIN
     DELETE gin_policy_insured_limits
     WHERE pil_ipu_code=v_ipu_code
     AND pil_sect_type   IN('SC','CC','VA');
   END;