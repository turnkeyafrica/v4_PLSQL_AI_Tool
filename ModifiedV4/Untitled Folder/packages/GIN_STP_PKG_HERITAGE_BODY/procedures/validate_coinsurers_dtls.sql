PROCEDURE validate_coinsurers_dtls (v_pol_batch_no IN NUMBER)
   IS
      v_pol_coin_share   NUMBER;
      v_coin_perc        NUMBER;
      v_coinsurance      VARCHAR2 (2);
      v_pol_leader       VARCHAR2 (2);
      v_leader_count     NUMBER;
      v_sum              NUMBER;
   BEGIN
      BEGIN
         SELECT pol_coinsurance_share, pol_coinsurance, pol_coinsure_leader
           INTO v_pol_coin_share, v_coinsurance, v_pol_leader
           FROM gin_policies
          WHERE pol_batch_no = v_pol_batch_no;
      EXCEPTION
         WHEN OTHERS
         THEN
            raise_error ('Error fetching policy details...');
      END;