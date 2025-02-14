PROCEDURE update_ren_coinsurance_share (
      v_pol_batch_no   IN   NUMBER,
      v_leader         IN   VARCHAR2,
      v_share          IN   NUMBER,
      v_fee            IN   NUMBER
   )
   IS
      v_cnt   NUMBER;
   BEGIN
      IF NVL (v_leader, 'N') = 'Y'
      THEN
         BEGIN
            SELECT COUNT (*)
              INTO v_cnt
              FROM gin_ren_coinsurers
             WHERE coin_pol_batch_no = v_pol_batch_no
               AND NVL (coin_lead, 'N') = 'Y';
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_cnt := 0;
            WHEN OTHERS
            THEN
               raise_error ('Error fetching the existing coinsurers...');
         END;

         IF NVL (v_cnt, 0) > 0
         THEN
            raise_error
               ('Error:- A coinsurance leader already exists. Please check....'
               );
         END IF;
      END IF;

      UPDATE gin_ren_policies
         SET pol_coinsurance_share = v_share,
             --NVL(v_share, POL_COINSURANCE_SHARE),
             pol_coin_fee = v_fee,                 --NVL(v_fee, POL_COIN_FEE),
             pol_coinsure_leader = v_leader
       --NVL(v_leader, POL_COINSURE_LEADER)
      WHERE  pol_batch_no = v_pol_batch_no;
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_error ('error updating insured details....');
   END;