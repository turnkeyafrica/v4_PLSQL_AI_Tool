PROCEDURE populate_binder_renewals (v_pol_batch_no VARCHAR2)
   IS
      CURSOR cur_pol
      IS
         SELECT *
           FROM gin_policies
          WHERE pol_batch_no = v_pol_batch_no;

      v_bind_code         NUMBER;
      v_rate              NUMBER;
      v_sect_code         NUMBER;
      v_prem_rate         NUMBER;
      v_coin_pct          NUMBER;
      v_min_prem_factor   NUMBER       := 1;
      v_rnd               NUMBER       := 2;
      v_param             VARCHAR2 (1);
      act_type            VARCHAR2 (5);
      v_cnt               NUMBER;
   BEGIN
      FOR cur_pol_rec IN cur_pol
      LOOP
         BEGIN
            SELECT NVL
                      (gin_parameters_pkg.get_param_varchar
                                                    ('ALLOW_PREM_COMP_BINDERS'),
                       'N'
                      )
              INTO v_param
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_param := 'N';
         END;

         BEGIN
            SELECT DISTINCT agn_act_code
                       INTO act_type
                       FROM tqc_agencies
                      WHERE agn_code = cur_pol_rec.pol_agnt_agent_code;
         EXCEPTION
            WHEN OTHERS
            THEN
               raise_when_others ('Unable to retrieve the acount type...');
         END;

         IF NVL (cur_pol_rec.pol_coinsurance, 'N') = 'N'
         THEN
            v_coin_pct := 100;
         ELSE
            v_coin_pct := NVL (cur_pol_rec.pol_coinsurance_share, 100);
         END IF;

         BEGIN
            SELECT pol_bind_code
              INTO v_bind_code
              FROM gin_policies
             WHERE pol_batch_no = v_pol_batch_no;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               NULL;
         END;

         BEGIN
            SELECT COUNT (1)
              INTO v_cnt
              FROM gin_claim_master_bookings
             WHERE cmb_pol_batch_no = v_pol_batch_no
               AND cmb_claim_date BETWEEN cur_pol_rec.pol_wef_dt
                                      AND cur_pol_rec.pol_wet_dt;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_cnt := 0;
            WHEN OTHERS
            THEN
               v_cnt := 0;
         END;

         --   message('v_cnt='||v_cnt);pause;
         BEGIN
            SELECT pil_prem_rate, pil_sect_code
              INTO v_rate, v_sect_code
              FROM gin_policy_insured_limits, gin_insured_property_unds
             WHERE ipu_code = pil_ipu_code
               AND ipu_pol_batch_no = v_pol_batch_no
               AND pil_sect_type = 'SS';
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;

         BEGIN
            SELECT prr_rate
              INTO v_prem_rate
              FROM gin_premium_rates, gin_sections
             WHERE sect_code = prr_sect_code
               AND prr_sect_code = v_sect_code
               AND prr_bind_code = v_bind_code
               AND sect_type != 'ND';
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;

         IF NVL (v_param, 'N') = 'Y'
         THEN
            IF    NVL (v_rate, 0) < NVL (v_prem_rate, 0)
                  AND NVL (v_cnt, 0) != 0
               OR NVL (v_rate, 0) >= NVL (v_prem_rate, 0)
            THEN
               BEGIN
                  gin_compute_prem_pkg.gis_calc_policy_premium
                                      (v_pol_batch_no,
                                       act_type,
                                       cur_pol_rec.pol_cur_code,
                                       cur_pol_rec.pol_cur_symbol,
                                       cur_pol_rec.pol_agnt_agent_code,
                                       cur_pol_rec.pol_wef_dt,
                                       cur_pol_rec.pol_wet_dt,
                                       cur_pol_rec.pol_uw_year,
                                       cur_pol_rec.pol_policy_status,
                                       cur_pol_rec.pol_pro_code,
                                       NVL (cur_pol_rec.pol_coinsure_leader,
                                            'N'
                                           ),
                                       v_coin_pct,
                                       cur_pol_rec.pol_ri_agnt_agent_code,
                                       cur_pol_rec.pol_policy_type,
                                       cur_pol_rec.pol_min_prem,
                                       v_min_prem_factor,
                                       v_rnd,
                                       cur_pol_rec.pol_commission_allowed
                                      );
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     raise_when_others
                        (   'Unable to compute premium for binder renewals...'
                         || SQLERRM (SQLCODE)
                        );
               END;
            END IF;
         END IF;
      END LOOP;
   END;