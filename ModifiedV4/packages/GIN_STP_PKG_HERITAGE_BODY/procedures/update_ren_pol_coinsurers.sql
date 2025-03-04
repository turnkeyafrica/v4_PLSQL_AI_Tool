PROCEDURE update_ren_pol_coinsurers (
      v_batch_no             IN   NUMBER,
      v_agent_code           IN   NUMBER,
      v_leader                    VARCHAR2,
      v_perc                 IN   NUMBER,
      v_fee_rate             IN   NUMBER,
      v_policy_no            IN   VARCHAR2,
      v_pol_coin_policy_no   IN   VARCHAR2 DEFAULT NULL,
      v_force_compute        IN   VARCHAR2
   )
   IS
      v_pol_leader     VARCHAR2 (1);
      v_pol_coin_pct   NUMBER;
      v_coin_perct     NUMBER;
      v_cnt            NUMBER;
   BEGIN
      BEGIN
         SELECT pol_coinsure_leader, pol_coinsure_pct
           INTO v_pol_leader, v_pol_coin_pct
           FROM gin_ren_policies
          WHERE pol_batch_no = v_batch_no;
      EXCEPTION
         WHEN OTHERS
         THEN
            raise_error
                       ('Error determining if the policy is for a leader....');
      END;

      IF NVL (v_leader, 'N') = 'Y'
      THEN
         BEGIN
            SELECT COUNT (*)
              INTO v_cnt
              FROM gin_ren_coinsurers
             WHERE coin_pol_batch_no = v_batch_no
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
            BEGIN
               UPDATE gin_ren_coinsurers
                  SET coin_lead = 'N'
                WHERE NVL (coin_lead, 'N') = 'Y'
                  AND coin_pol_batch_no = v_batch_no;
            EXCEPTION
               WHEN OTHERS
               THEN
                  raise_error
                     ('Error updating the previous coinsurance leader details....'
                     );
            END;
         --RAISE_ERROR('Error:- A coinsurance leader already exists. Please check....');
         END IF;

         IF NVL (v_pol_leader, 'N') = 'Y'
         THEN
            raise_error
               ('Error:- The policy belongs to the leader already. Please check....'
               );
         END IF;
      END IF;

      BEGIN
         UPDATE gin_ren_coinsurers
            SET coin_lead = NVL (v_leader, coin_lead),
                coin_perct = NVL (v_perc, coin_perct),
                coin_fee_rate = NVL (v_fee_rate, coin_fee_rate),
                coin_coinsurers_polno = v_policy_no,
                coin_force_sf_compute = v_force_compute
          WHERE coin_agnt_agent_code = v_agent_code
            AND coin_pol_batch_no = v_batch_no;
      EXCEPTION
         WHEN OTHERS
         THEN
            raise_error ('Error updating coinsurance details....');
      END;

      BEGIN
         SELECT SUM (NVL (coin_perct, 0))
           INTO v_coin_perct
           FROM gin_ren_coinsurers
          WHERE coin_pol_batch_no = v_batch_no;
      EXCEPTION
         WHEN OTHERS
         THEN
            raise_error
                     ('Error determinig the total coinsurance percentage....');
      END;

      IF NVL (v_coin_perct, 0) + NVL (v_pol_coin_pct, 0) > 100
      THEN
         raise_error
            ('Error:- Coinaurance percentages should not be more than 100....'
            );
      END IF;
   END;