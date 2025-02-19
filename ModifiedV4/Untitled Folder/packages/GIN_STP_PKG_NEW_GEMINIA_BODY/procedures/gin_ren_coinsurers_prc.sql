PROCEDURE gin_ren_coinsurers_prc (v_batch_no        IN NUMBER,
                                      v_pol_coins_tab   IN web_pol_coins_tab)
    IS
        CURSOR pol_cur IS
            SELECT *
              FROM gin_policies
             WHERE pol_batch_no = v_batch_no;

        v_coin_perc   NUMBER;
    BEGIN
        FOR pol_rec IN pol_cur
        LOOP
            IF NVL (pol_rec.pol_coinsurance, 'N') = 'Y'
            THEN
                FOR x IN 1 .. v_pol_coins_tab.COUNT
                LOOP                                      -- IN pol_coins LOOP
                    BEGIN
                        INSERT INTO gin_ren_coinsurers (
                                        coin_agnt_agent_code,
                                        coin_agnt_sht_desc,
                                        coin_gl_code,
                                        coin_lead,
                                        coin_perct,
                                        coin_prem,
                                        coin_alp_proposal_no,
                                        coin_pol_policy_no,
                                        coin_pol_ren_endos_no,
                                        coin_pol_batch_no,
                                        coin_fee_rate,
                                        coin_fee_amt,
                                        coin_prem_tax,
                                        coin_duties,
                                        coin_si,
                                        coin_annual_prem,
                                        coin_coinsurers_polno,
                                        coin_force_sf_compute,
                                        coin_fee_type,
                                        coin_commission,
                                        coin_whtx,
                                        coin_aga_code,
                                        coin_aga_sht_desc,
                                        coin_comm_type,
                                        COIN_FAC_CESSION,
                                        COIN_FAC_PC)
                                 VALUES (
                                            v_pol_coins_tab (x).coin_agnt_agent_code,
                                            v_pol_coins_tab (x).coin_agnt_sht_desc,
                                            v_pol_coins_tab (x).coin_gl_code,
                                            v_pol_coins_tab (x).coin_lead,
                                            v_pol_coins_tab (x).coin_perct,
                                            v_pol_coins_tab (x).coin_prem,
                                            v_pol_coins_tab (x).coin_alp_proposal_no,
                                            pol_rec.pol_policy_no,
                                            pol_rec.pol_ren_endos_no,
                                            v_batch_no,
                                            v_pol_coins_tab (x).coin_fee_rate,
                                            v_pol_coins_tab (x).coin_fee_amt,
                                            v_pol_coins_tab (x).coin_prem_tax,
                                            v_pol_coins_tab (x).coin_duties,
                                            v_pol_coins_tab (x).coin_si,
                                            v_pol_coins_tab (x).coin_annual_prem,
                                            v_pol_coins_tab (x).coin_coinsurers_polno,
                                            'D',
                                            --v_pol_coins_tab (x).coin_force_sf_compute,
                                            v_pol_coins_tab (x).coin_fee_type,
                                            v_pol_coins_tab (x).coin_commission,
                                            v_pol_coins_tab (x).coin_whtx,
                                            v_pol_coins_tab (x).coin_aga_code,
                                            v_pol_coins_tab (x).coin_aga_sht_desc,
                                            v_pol_coins_tab (x).coin_comm_type,
                                            v_pol_coins_tab (x).COIN_FAC_CESSION,
                                            v_pol_coins_tab (x).COIN_FAC_PC);
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            raise_error (
                                'Error inserting coinsurance records..');
                    END;