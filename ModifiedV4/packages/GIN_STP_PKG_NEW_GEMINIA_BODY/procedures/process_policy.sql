PROCEDURE process_policy (v_pol_data       IN     policy_tab,
                              v_risks_data     IN     risk_tab,
                              v_agentcontact   IN     VARCHAR2,
                              v_pol_batch_no      OUT NUMBER)
    IS
        v_cnt                NUMBER;
        v_new_ipu_code       NUMBER;
        v_new_polin_code     NUMBER;
        v_exp_flag           VARCHAR2 (2);
        v_uw_yr              VARCHAR2 (1);
        v_open_cover         VARCHAR2 (2);
        v_user               VARCHAR2 (35)
            := pkg_global_vars.get_pvarchar2 ('PKG_GLOBAL_VARS.PVG_USERNAME');
        v_pol_status         VARCHAR2 (5);
        v_row                NUMBER := 0;
        v_trans_no           NUMBER;
        v_stp_code           NUMBER;
        v_scl_desc           VARCHAR2 (75);
        v_bind_desc          VARCHAR2 (75);
        v_wet_date           DATE;
        v_pol_renewal_dt     DATE;
        v_pol_no             VARCHAR2 (45);
        v_end_no             VARCHAR2 (45);
        v_batchno            NUMBER;
        v_cur_code           NUMBER;
        v_cur_symbol         VARCHAR2 (15);
        v_cur_rate           NUMBER;
        v_pol_uwyr           NUMBER;
        v_policy_doc         VARCHAR2 (45);
        v_tran_ref_no        VARCHAR2 (45);
        v_serial             VARCHAR2 (45);
        v_endrsd_rsks_tab    gin_stp_pkg.endrsd_rsks_tab;
        v_rsk_sect_data      rsk_sect_tab;
        next_ggts_trans_no   NUMBER;
        v_error              VARCHAR2 (200);

        CURSOR rsks IS
            SELECT DISTINCT stpr_gis_ipu_code,
                            stpr_action_type,
                            stpr_stp_code,
                            stpr_property_id,
                            stpr_desc,
                            stpr_scl_code,
                            stpr_scl_desc,
                            stpr_cvt_code,
                            stpr_cvt_desc,
                            stpr_bind_code,
                            stpr_bind_desc
              FROM gin_risk_stp_temp_data
             WHERE stpr_stp_code = v_stp_code;

        CURSOR rsk_limits (rsk_prp_id IN VARCHAR2)
        IS
            SELECT DISTINCT stpr_stp_code,
                            stpr_property_id,
                            stpr_desc,
                            stpr_scl_code,
                            stpr_scl_desc,
                            stpr_cvt_code,
                            stpr_cvt_desc,
                            stpr_bind_code,
                            stpr_bind_desc,
                            stpr_sect_code,
                            stpr_sect_desc,
                            stpr_limit
              FROM gin_risk_stp_temp_data
             WHERE     stpr_stp_code = v_stp_code
                   AND stpr_property_id = rsk_prp_id;
    BEGIN
        v_user := NVL (v_agentcontact, v_user);

        --raise_error ('No policy data provided..');
        SELECT gin_stp_code_seq.NEXTVAL INTO v_stp_code FROM DUAL;

        IF v_pol_data.COUNT = 0
        THEN
            raise_error ('No policy data provided..');
        END IF;

        IF v_risks_data.COUNT = 0
        THEN
            raise_error ('No Risk data provided..');
        END IF;

        DBMS_OUTPUT.put_line (1);

        FOR x IN 1 .. v_risks_data.COUNT
        LOOP
            v_scl_desc := v_risks_data (x).ipu_scl_desc;

            IF v_scl_desc IS NULL
            THEN
                SELECT scl_sht_desc
                  INTO v_scl_desc
                  FROM gin_sub_classes
                 WHERE scl_code = v_risks_data (x).ipu_scl_code;
            END IF;

            v_bind_desc := v_risks_data (x).ipu_bind_desc;

            IF v_bind_desc IS NULL
            THEN
                SELECT bind_name
                  INTO v_bind_desc
                  FROM gin_binders
                 WHERE bind_code = v_risks_data (x).ipu_bind_code;
            END IF;

            INSERT INTO gin_risk_stp_temp_data (stpr_stp_code,
                                                stpr_property_id,
                                                stpr_desc,
                                                stpr_scl_code,
                                                stpr_scl_desc,
                                                stpr_cvt_code,
                                                stpr_cvt_desc,
                                                stpr_bind_code,
                                                stpr_bind_desc,
                                                stpr_sect_code,
                                                stpr_sect_desc,
                                                stpr_limit,
                                                stpr_gis_ipu_code,
                                                stpr_action_type)
                 VALUES (v_stp_code,
                         v_risks_data (x).ipu_property_id,
                         v_risks_data (x).ipu_desc,
                         v_risks_data (x).ipu_scl_code,
                         v_scl_desc,
                         v_risks_data (x).ipu_cvt_code,
                         v_risks_data (x).ipu_cvt_desc,
                         v_risks_data (x).ipu_bind_code,
                         v_bind_desc,
                         v_risks_data (x).ipu_sect_code,
                         v_risks_data (x).ipu_sect_desc,
                         v_risks_data (x).ipu_limit,
                         v_risks_data (x).gis_ipu_code,
                         v_risks_data (x).ipu_action_type);
        END LOOP;

        DBMS_OUTPUT.put_line (2);

        FOR pcount IN 1 .. v_pol_data.COUNT
        LOOP
            IF v_pol_data (pcount).pol_brn_sht_desc IS NULL
            THEN
                raise_error ('PROVIDE THE BRANCH ...');
            END IF;

            IF v_pol_data (pcount).pol_pro_code IS NULL
            THEN
                raise_error ('SELECT THE POLICY PRODUCT ...');
            END IF;

            IF v_pol_data (pcount).pol_wef_dt IS NULL
            THEN
                raise_error ('PROVIDE THE COVER FROM DATE ...');
            END IF;

            DBMS_OUTPUT.put_line (21);
            v_wet_date := v_pol_data (pcount).pol_wet_dt;

            IF v_wet_date IS NULL
            THEN
                v_wet_date :=
                    get_wet_date (v_pol_data (pcount).pol_pro_code,
                                  v_pol_data (pcount).pol_wef_dt);
            END IF;

            DBMS_OUTPUT.put_line (22);

            IF v_wet_date IS NULL
            THEN
                raise_error ('PROVIDE THE COVER TO DATE ...');
            END IF;

            DBMS_OUTPUT.put_line (23);

            IF     NVL (v_pol_data (pcount).pol_binder_policy, 'N') = 'Y'
               AND v_pol_data (pcount).pol_bind_code IS NULL
            THEN
                raise_error ('YOU HAVE NOT DEFINED THE BORDEREAUX CODE ..');
            END IF;

            DBMS_OUTPUT.put_line (v_pol_data (pcount).pol_wef_dt);
            DBMS_OUTPUT.put_line (TO_CHAR (v_pol_data (pcount).pol_wef_dt));
            DBMS_OUTPUT.put_line (
                TO_NUMBER (TO_CHAR (v_pol_data (pcount).pol_wef_dt, 'RRRR')));
            v_pol_uwyr :=
                TO_NUMBER (TO_CHAR (v_pol_data (pcount).pol_wef_dt, 'RRRR'));
            /*IF v_pol_Data(pcount).POL_UW_YEAR IS NULL OR v_pol_Data(pcount).POL_UW_YEAR = 0 THEN
                RAISE_ERROR('THE UNDERWRITING YEAR MUST BE A VALID YEAR...');
            END IF;*/
            DBMS_OUTPUT.put_line (25);
            v_pol_renewal_dt :=
                get_renewal_date (v_pol_data (pcount).pol_pro_code,
                                  v_wet_date);
            v_cur_code := v_pol_data (pcount).pol_cur_code;
            v_cur_rate := v_pol_data (pcount).pol_cur_rate;

            IF v_cur_code IS NULL
            THEN
                v_cur_rate := NULL;

                BEGIN
                    SELECT org_cur_code, cur_symbol
                      INTO v_cur_code, v_cur_symbol
                      FROM tqc_organizations, tqc_systems, tqc_currencies
                     WHERE     org_code = sys_org_code
                           AND org_cur_code = cur_code
                           AND sys_code = 37;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error ('UNABLE TO RETRIEVE THE BASE CURRENCY');
                END;

                IF v_cur_code IS NULL
                THEN
                    raise_error (
                        'THE BASE CURRENCY HAVE NOT BEEN DEDFINED. CANNOT PROCEED.');
                END IF;
            ELSE
                SELECT cur_code, cur_symbol
                  INTO v_cur_code, v_cur_symbol
                  FROM tqc_currencies
                 WHERE cur_code = v_cur_code;
            END IF;

            IF v_cur_rate IS NULL
            THEN
                v_cur_rate :=
                    get_exchange_rate (v_cur_code,
                                       v_pol_data (pcount).pol_cur_code);
            END IF;

            BEGIN
                SELECT NVL (pro_expiry_period, 'Y'),
                       NVL (pro_open_cover, 'N')
                  INTO v_exp_flag, v_open_cover
                  FROM gin_products
                 WHERE pro_code = v_pol_data (pcount).pol_pro_code;
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error ('ERROR SECURING OPEN COVER STATUS..');
            END;

            IF    NVL (v_pol_data (pcount).pol_binder_policy, 'N') = 'Y'
               OR NVL (v_open_cover, 'N') = 'Y'
            THEN
                v_uw_yr := 'R';
            ---to_number(to_char(:GIN_INSURED_PROPERTY_UNDS.IPU_WEF,'RRRR'));
            ELSE
                v_uw_yr := 'P';
            ---:GIN_INSURED_PROPERTY_UNDS.IPU_UW_YR :=  :GIN_POLICIES.POL_UW_YEAR;
            END IF;

            DBMS_OUTPUT.put_line (
                'TransType=' || v_pol_data (pcount).pol_trans_type);
            DBMS_OUTPUT.put_line (
                'ActionType=' || v_pol_data (pcount).pol_action_type);

            IF     v_pol_data (pcount).pol_trans_type = 'NB'
               AND v_pol_data (pcount).pol_action_type = 'A'
            THEN
                DBMS_OUTPUT.put_line (3);
                v_pol_no := v_pol_data (pcount).pol_policy_no;
                v_end_no := v_pol_data (pcount).pol_endos_no;
                v_batchno := NULL;          --v_pol_Data(pcount).POL_BATCH_NO;
                DBMS_OUTPUT.put_line (31);

                IF v_pol_no IS NULL OR v_end_no IS NULL OR v_batchno IS NULL
                THEN
                    BEGIN
                        --     1288=807=223=N=N=N
                        --   DBMS_OUTPUT.PUT_LINE(v_pol_Data(pcount).POL_pro_code||'='||v_pol_Data(pcount).POL_pro_sht_desc||'='||v_pol_Data(pcount).POL_brn_code||'='||
                        --                  v_pol_Data(pcount).POL_brn_sht_desc||'='||v_pol_Data(pcount).POL_BINDER_POLICY||'='||v_pol_Data(pcount).POL_POLICY_TYPE);
                        get_policy_no (v_pol_data (pcount).pol_pro_code,
                                       v_pol_data (pcount).pol_pro_sht_desc,
                                       v_pol_data (pcount).pol_brn_code,
                                       v_pol_data (pcount).pol_brn_sht_desc,
                                       v_pol_data (pcount).pol_binder_policy,
                                       v_pol_data (pcount).pol_policy_type,
                                       v_pol_no,
                                       v_end_no,
                                       v_batchno);
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            raise_error (
                                'UNABLE TO GENERATE THE POLICY NUMBER...');
                    END;
                END IF;

                IF NVL (v_pol_data (pcount).pol_short_period, 'N') = 'Y'
                THEN
                    v_pol_status := 'SP';
                ELSE
                    v_pol_status := 'NB';
                END IF;

                DBMS_OUTPUT.put_line (4);
                v_policy_doc := v_pol_data (pcount).pol_policy_doc;

                IF v_policy_doc IS NULL
                THEN
                    BEGIN
                        SELECT pro_policy_word_doc
                          INTO v_policy_doc
                          FROM gin_products
                         WHERE pro_code = v_pol_data (pcount).pol_pro_code;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            raise_error (
                                'Error getting the default policy document..');
                    END;
                END IF;

                v_pol_batch_no := v_batchno;

                BEGIN
                    INSERT INTO gin_policies (pol_policy_no,
                                              pol_ren_endos_no,
                                              pol_batch_no,
                                              pol_agnt_agent_code,
                                              pol_agnt_sht_desc,
                                              pol_bind_code,
                                              pol_wef_dt,
                                              pol_wet_dt,
                                              pol_uw_year,
                                              pol_policy_status,
                                              pol_inception_dt,
                                              pol_cur_code,
                                              pol_prepared_by,
                                              pol_prepared_date,
                                              pol_policy_type,
                                              pol_client_policy_number,
                                              pol_brn_code,
                                              pol_cur_rate,
                                              pol_coinsurance,
                                              pol_coinsure_leader,
                                              pol_cur_symbol,
                                              pol_brn_sht_desc,
                                              pol_prp_code,
                                              pol_current_status,
                                              pol_authosrised,
                                              pol_post_status,
                                              pol_inception_uwyr,
                                              pol_pro_code,
                                              pol_your_ref,
                                              pol_prop_holding_co_prp_code,
                                              pol_oth_int_parties,
                                              pol_pro_sht_desc,
                                              pol_prev_batch_no,
                                              pol_uwyr_length,
                                              pol_binder_policy,
                                              pol_renewable,
                                              pol_policy_cover_to,
                                              pol_policy_cover_from,
                                              pol_coinsurance_share,
                                              pol_renewal_dt,
                                              pol_trans_eff_wet,
                                              pol_ri_agent_comm_rate,
                                              pol_ri_agnt_sht_desc,
                                              pol_ri_agnt_agent_code,
                                              pol_policy_doc,
                                              pol_commission_allowed,
                                              pol_admin_fee_allowed        --,
                                                                   --POL_INTRO_CODE,
                                                                   --POL_EXCH_RATE_FIXED
                                                                   )
                             VALUES (
                                        v_pol_no,
                                        v_end_no,
                                        v_batchno,
                                        v_pol_data (pcount).pol_agnt_agent_code,
                                        v_pol_data (pcount).pol_agnt_sht_desc,
                                        v_pol_data (pcount).pol_bind_code,
                                        v_pol_data (pcount).pol_wef_dt,
                                        v_wet_date,
                                        v_pol_uwyr,
                                        v_pol_status,
                                        v_pol_data (pcount).pol_wef_dt,
                                        v_cur_code,
                                        v_user,
                                        TRUNC (SYSDATE),
                                        NVL (
                                            v_pol_data (pcount).pol_policy_type,
                                            'N'),
                                        v_pol_data (pcount).pol_policy_no,
                                        v_pol_data (pcount).pol_brn_code,
                                        v_cur_rate,
                                        v_pol_data (pcount).pol_coinsurance,
                                        v_pol_data (pcount).pol_coinsure_leader,
                                        v_cur_symbol,
                                        v_pol_data (pcount).pol_brn_sht_desc,
                                        v_pol_data (pcount).pol_prp_code,
                                        'D',
                                        'N',
                                        'N',
                                        v_pol_uwyr,
                                        v_pol_data (pcount).pol_pro_code,
                                        v_pol_data (pcount).pol_your_ref,
                                        v_pol_data (pcount).pol_prop_holding_co_prp_code,
                                        v_pol_data (pcount).pol_oth_int_parties,
                                        v_pol_data (pcount).pol_pro_sht_desc,
                                        v_batchno,
                                        CEIL (
                                            MONTHS_BETWEEN (
                                                v_wet_date,
                                                v_pol_data (pcount).pol_wef_dt)),
                                        v_pol_data (pcount).pol_binder_policy,
                                        v_pol_data (pcount).pol_renewable,
                                        v_wet_date,
                                        v_pol_data (pcount).pol_wef_dt,
                                        v_pol_data (pcount).pol_coinsurance_share,
                                        get_renewal_date (
                                            v_pol_data (pcount).pol_pro_code,
                                            v_wet_date),
                                        v_wet_date,
                                        v_pol_data (pcount).pol_ri_agent_comm_rate,
                                        v_pol_data (pcount).pol_ri_agnt_sht_desc,
                                        v_pol_data (pcount).pol_ri_agnt_agent_code,
                                        v_policy_doc,
                                        NVL (
                                            v_pol_data (pcount).pol_commission_allowed,
                                            'Y'),
                                        'N'                                --,
                                           --v_pol_Data(pcount).POL_INTRO_CODE,
                                           --v_pol_Data(pcount).POL_EXCH_RATE_FIXED
                                           );
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error ('ERROR CREATING POLICY RECORD..');
                END;

                BEGIN
                    SELECT TO_NUMBER (
                                  TO_CHAR (SYSDATE, 'RRRR')
                               || ggt_trans_no_seq.NEXTVAL)
                      INTO v_trans_no
                      FROM DUAL;

                    INSERT INTO gin_gis_transactions (
                                    ggt_doc_ref,
                                    ggt_trans_no,
                                    ggt_pol_policy_no,
                                    ggt_cmb_claim_no,
                                    ggt_pro_code,
                                    ggt_pol_batch_no,
                                    ggt_pro_sht_desc,
                                    ggt_btr_trans_code,
                                    ggt_done_by,
                                    ggt_done_date,
                                    ggt_client_policy_number,
                                    ggt_uw_clm_tran,
                                    ggt_trans_date,
                                    ggt_trans_authorised,
                                    ggt_trans_authorised_by,
                                    ggt_trans_authorise_date,
                                    ggt_old_tran_no,
                                    ggt_effective_date)
                         VALUES (v_pol_data (pcount).pol_your_ref,
                                 v_trans_no,
                                 v_pol_no,
                                 NULL,
                                 v_pol_data (pcount).pol_pro_code,
                                 v_batchno,
                                 v_pol_data (pcount).pol_pro_sht_desc,
                                 'NB',
                                 v_user,
                                 TRUNC (SYSDATE),
                                 v_pol_no,
                                 'U',
                                 TRUNC (SYSDATE),
                                 'N',
                                 NULL,
                                 NULL,
                                 NULL,
                                 TRUNC (SYSDATE));
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error ('ERROR CREATING TRANSACTION RECORD..');
                END;

                /*transmittal