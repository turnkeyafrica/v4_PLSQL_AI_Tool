PROCEDURE delete_ren_coinsurer_agent (
      v_batch_no   IN   NUMBER,
      v_agn_code   IN   NUMBER
   )
   IS
   BEGIN
      DELETE      gin_ren_coinsurers
            WHERE coin_agnt_agent_code = v_agn_code
              AND coin_pol_batch_no = v_batch_no;
   END;