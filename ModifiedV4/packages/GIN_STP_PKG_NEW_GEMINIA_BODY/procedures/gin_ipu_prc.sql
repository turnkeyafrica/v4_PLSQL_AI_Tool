PROCEDURE gin_ipu_prc (v_batch_no          IN     NUMBER,
                           v_trans_type        IN     VARCHAR2,
                           v_pol_add_edit      IN     VARCHAR2,
                           v_ipu_data          IN     web_risk_tab,
                           v_user              IN     VARCHAR2,
                           v_new_ipu_code         OUT NUMBER,
                           v_renewal_area      IN     VARCHAR2,
                           v_loaded            IN     VARCHAR2 DEFAULT 'N',
                           v_ipu_ncd_cert_no   IN     VARCHAR2 DEFAULT NULL,
                           v_del_sect          IN     VARCHAR2 DEFAULT NULL)
    IS
        v_cnt                       NUMBER;
        v_new_polin_code            NUMBER;
        v_uw_yr                     VARCHAR2 (1);
        v_stp_code                  NUMBER;
        v_wef_date                  DATE;
        v_wet_date                  DATE;
        v_cover_days                NUMBER;
        v_bind_code                 NUMBER;
        v_bind_name                 VARCHAR2 (100);
        v_cert_no                   VARCHAR2 (35);
        v_quz_sht_desc              VARCHAR2 (35);
        --v_count                                NUMBER;
        v_uw_trans                  VARCHAR2 (1);
        v_ren_cnt                   NUMBER;
        v_ipu_prev_status           VARCHAR2 (35);
        v_ipu_prorata               VARCHAR2 (2);
        v_cvt_install_type          gin_subclass_cover_types.sclcovt_install_type%TYPE;
        v_cvt_max_installs          gin_subclass_cover_types.sclcovt_max_installs%TYPE;
        v_cvt_pymt_install_pcts     gin_subclass_cover_types.sclcovt_pymt_install_pcts%TYPE;
        v_cvt_install_periods       gin_subclass_cover_types.sclcovt_install_periods%TYPE;
        v_pol_tot_instlmt           NUMBER;
        v_pymnt_tot_instlmt         NUMBER;
        v_install_pct               NUMBER;
        v_ipu_id                    NUMBER;
        v_cer_cnt                   NUMBER;
        v_ct_code                   NUMBER;
        v_error                     VARCHAR2 (200);
        v_cer_cnt                   NUMBER;
        v_ipu_id                    NUMBER;
        v_install_period            NUMBER;
        v_polc_code                 NUMBER;
        v_risk_pymt_install_pcts    VARCHAR2 (50);
        v_susp_reinst_type          VARCHAR2 (5);
        v_suspend_wef               DATE;
        v_suspend_wet               DATE;
        v_new_pol_wet               DATE;
        v_rsk_trans_type            VARCHAR2 (3);
        v_pol_instal_wet            DATE;
        v_wef                       DATE;
        v_prev_install_period       NUMBER;
        v_increment_by              NUMBER;
        v_increment                 VARCHAR2 (2);
        v_interface_type            VARCHAR2 (50);
        v_cnt1                      NUMBER;
        v_risk_id_format            VARCHAR2 (50);
        v_risk_id_format_param      VARCHAR2 (50);
        v_id_reg_no                 VARCHAR2 (50);
        v_clnt_pin_no               VARCHAR2 (50);
        v_ipu_covt_code             NUMBER;
        v_clnt_passport_no          VARCHAR2 (50);
        v_agent_code                NUMBER;
        v_agn_pin                   VARCHAR2 (50);
        v_max_exposure              NUMBER;
        v_pol_status                VARCHAR2 (10);
        v_enforce_covt_prem         VARCHAR2 (1);
        v_covt_code                 NUMBER;
        v_cvt_desc                  VARCHAR2 (4000);
        v_cert_autogen              VARCHAR2 (1);
        v_autopopltsections_param   VARCHAR2 (1);
        v_agnt_agent_code           NUMBER;
        v_franch_agn_code           NUMBER;
        v_franch_act_code           NUMBER;
        v_loaded_cert               NUMBER;
        v_scl_motor_verify          VARCHAR2 (1);
        v_driver_name               VARCHAR2 (100);
        v_auto_populate_limits      VARCHAR2 (2);
        v_error_msg                 VARCHAR2 (200);
        v_quake_mandatory           VARCHAR2 (1);
        v_claim_cnt                 NUMBER;
        
        CURSOR pol_cur IS
            SELECT gin_policies.*,
                   NVL (pro_expiry_period, 'Y')     pro_expiry_period,
                   --NVL (pro_open_cover, 'N') pro_open_cover
                   NVL (pol_open_cover, 'N')        pro_open_cover,
                   NVL (pro_earthquake, 'N')        pro_earthquake,
                   NVL (pro_moto_verfy, 'N')        pro_moto_verfy,
                   NVL (pro_stp, 'N')               pro_stp,
                   a.agn_act_code,
                   b.agn_act_code                   mkt
              FROM gin_policies,
                   gin_products,
                   tqc_agencies  a,
                   tqc_agencies  b
             WHERE     pro_code = pol_pro_code
                   AND a.agn_code(+) = pol_agnt_agent_code
                   AND pol_mktr_agn_code = b.agn_code(+)
                   AND pol_batch_no = v_batch_no;

        CURSOR pol_ren_cur IS
            SELECT gin_ren_policies.*,
                   NVL (pro_expiry_period, 'Y')     pro_expiry_period,
                   NVL (pol_open_cover, 'N')        pro_open_cover,
                   NVL (pro_moto_verfy, 'N')        pro_moto_verfy,
                   NVL (pro_stp, 'N')               pro_stp
              FROM gin_ren_policies, gin_products
             WHERE pro_code = pol_pro_code AND pol_batch_no = v_batch_no;

        CURSOR comm (v_scl_code        NUMBER,
                     v_act_code        NUMBER,
                     v_bind_code       NUMBER,
                     v_lta_app         VARCHAR2,
                     v_franch_agn_cd   NUMBER)
        IS
            SELECT trans_code,
                   comm_act_code,
                   trnt_code,
                   DECODE (
                       DECODE (trnt_code,
                               'LTA-U', bind_lta_type,
                               bind_comm_type),
                       'B', 1,
                       2)    order_type
              FROM gin_trans_type,
                   gin_transaction_types,
                   gin_commissions,
                   gin_binders
             WHERE     trans_code = trnt_trans_code
                   AND comm_trnt_code = trnt_code
                   AND comm_trans_code = trans_code
                   AND comm_bind_code = bind_code
                   AND trnt_code NOT IN
                           DECODE (NVL (v_lta_app, 'N'),
                                   'N', 'LTA-U',
                                   'Y', 'ALL')
                   AND comm_trnt_code IN
                           DECODE (NVL (v_franch_agn_cd, 0),
                                   0, 'UC-U',
                                   comm_trnt_code)
                   AND comm_trnt_code NOT IN
                           DECODE (NVL (v_franch_agn_cd, 0),
                                   0, 'UNDIFINED',
                                   'UC-U')
                   AND comm_trnt_code NOT IN
                           DECODE (NVL (v_franch_agn_cd, 0),
                                   0, 'UNDIFINED',
                                   'LTA-U')
                   AND comm_scl_code = v_scl_code
                   AND comm_act_code = v_act_code
                   AND comm_bind_code = v_bind_code
            UNION ALL
            SELECT trans_code,
                   comm_act_code,
                   trnt_code,
                   DECODE (
                       DECODE (trnt_code,
                               'LTA-U', bind_lta_type,
                               bind_comm_type),
                       'B', 1,
                       2)    order_type
              FROM gin_trans_type,
                   gin_transaction_types,
                   gin_commissions,
                   gin_binders
             WHERE     trans_code = trnt_trans_code
                   AND comm_trnt_code = trnt_code
                   AND comm_trans_code = trans_code
                   AND comm_bind_code = bind_code
                   AND trnt_code IN
                           DECODE (NVL (v_lta_app, 'N'),
                                   'N', 'LTA-U',
                                   'Y', 'ALL')
                   AND comm_trnt_code NOT IN
                           DECODE (NVL (v_franch_agn_cd, 0),
                                   0, 'UC-U',
                                   comm_trnt_code)
                   AND comm_trnt_code NOT IN
                           DECODE (NVL (v_franch_agn_cd, 0),
                                   0, 'UNDIFINED',
                                   'UC-U')
                   AND comm_trnt_code NOT IN
                           DECODE (NVL (v_franch_agn_cd, 0),
                                   0, 'UNDIFINED',
                                   'LTA-U')
                   AND comm_scl_code = v_scl_code
                   AND comm_act_code = v_act_code
                   AND comm_bind_code = v_bind_code;
    BEGIN
        SELECT gin_stp_code_seq.NEXTVAL INTO v_stp_code FROM DUAL;

        IF v_ipu_data.COUNT = 0
        THEN
            raise_error ('No Risk data provided..');
        END IF;

        BEGIN
            SELECT param_value
              INTO v_autopopltsections_param
              FROM gin_parameters
             WHERE param_name = 'AUTO_POPLT_MAND_SECTIONS';
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                v_autopopltsections_param := 'Y';
            WHEN OTHERS
            THEN
                v_autopopltsections_param := 'Y';
        END;

        BEGIN
            SELECT param_value
              INTO v_auto_populate_limits
              FROM gin_parameters
             WHERE param_name = 'AUTO_POPLT_LIMITS_OF_LIABILITY';
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                v_auto_populate_limits := 'Y';
            WHEN OTHERS
            THEN
                v_auto_populate_limits := 'Y';
        END;

        IF v_trans_type != 'CO' AND NVL (v_pol_add_edit, 'N') != 'D'
        THEN
            FOR i IN 1 .. v_ipu_data.COUNT
            LOOP
                BEGIN
                    SELECT scl_quake_region_required
                      INTO v_quake_mandatory
                      FROM gin_sub_classes
                     WHERE scl_code = v_ipu_data (i).ipu_scl_code;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error (
                            'Error checking if earth quake is mandatory for the subclass');
                END;

                IF     v_quake_mandatory = 'Y'
                   AND v_ipu_data (i).ipu_quz_code IS NULL
                THEN
                    raise_error (
                        'Quake/ Flood Zone is mandatory for this sub class. Please add the quake zone or check the setup!');
                END IF;

                IF v_ipu_data (i).ipu_quz_code IS NOT NULL
                THEN
                    BEGIN
                        SELECT quz_sht_desc
                          INTO v_quz_sht_desc
                          FROM gin_quake_zones
                         WHERE quz_code = v_ipu_data (i).ipu_quz_code;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            raise_error ('Error getting quake_zone');
                    END;
                END IF;

                IF v_ipu_data (i).ipu_scl_code IS NOT NULL
                THEN
                    BEGIN
                        SELECT scl_cert_autogen
                          INTO v_cert_autogen
                          FROM gin_sub_classes
                         WHERE scl_code = v_ipu_data (i).ipu_scl_code;
                    EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                            v_cert_autogen := 'N';
                        WHEN OTHERS
                        THEN
                            raise_error ('Error getting autogen cert');
                    END;
                END IF;

                BEGIN
                    SELECT COUNT (1)
                      INTO v_loaded_cert
                      FROM gin_returned_certificates
                     WHERE     NVL (gnr_allocated, 'N') != 'Y'
                           AND gnr_risk_id = v_ipu_data (i).ipu_property_id
                           AND gnr_risk_note = v_ipu_data (i).ipu_risk_note
                           AND NVL (gnr_processed, 'N') = 'Y';
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        v_loaded_cert := 0;
                END;

                BEGIN
                    SELECT pol_agnt_agent_code
                      INTO v_agent_code
                      FROM gin_policies
                     WHERE pol_batch_no = v_batch_no;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error (
                               'Error Getting Agent Details .. '
                            || v_batch_no
                            || ' .. v_agent_code == '
                            || v_agent_code);
                END;

                IF (v_agent_code IS NOT NULL OR NVL (v_agent_code, 0) != 0)
                THEN
                    BEGIN
                        SELECT agn_pin
                          INTO v_agn_pin
                          FROM tqc_agencies
                         WHERE agn_code = v_agent_code;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            raise_error ('Error Getting Agent Details');
                    END;
                END IF;

                IF v_ipu_data (i).prp_code IS NOT NULL
                THEN
                    BEGIN
                        SELECT clnt_id_reg_no, clnt_pin, clnt_passport_no
                          INTO v_id_reg_no, v_clnt_pin_no, v_clnt_passport_no
                          FROM tqc_clients
                         WHERE clnt_code = v_ipu_data (i).prp_code;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            raise_error ('Error Getting Client Details');
                    END;
                END IF;

                BEGIN
                    SELECT COUNT (1)
                      INTO v_cnt1
                      FROM gin_blacklist_item
                     WHERE     (   bi_desc = v_ipu_data (i).ipu_property_id
                                OR bi_desc = v_id_reg_no
                                OR bi_desc = v_clnt_pin_no
                                OR bi_desc = v_clnt_passport_no
                                OR bi_desc = v_agn_pin)
                           AND SYSDATE BETWEEN blt_wef
                                           AND NVL (blt_wet, SYSDATE);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        v_cnt1 := 0;
                END;

                IF NVL (v_cnt1, 0) > 0
                THEN
                    raise_error ('Error Item Black Listed..');
                END IF;

                v_bind_code := v_ipu_data (i).ipu_bind_code;
                v_bind_name := v_ipu_data (i).ipu_bind_desc;

                IF v_trans_type = 'RN'
                THEN
                    BEGIN
                        SELECT COUNT (*)
                          INTO v_ren_cnt
                          FROM gin_ren_policies
                         WHERE pol_batch_no = v_batch_no;
                    EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                            v_ren_cnt := 0;
                    END;

                    IF NVL (v_ren_cnt, 0) > 0
                    THEN
                        v_uw_trans := 'N';
                    ELSE
                        BEGIN
                            SELECT COUNT (*)
                              INTO v_ren_cnt
                              FROM gin_policies
                             WHERE pol_batch_no = v_batch_no;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                raise_error (
                                    'Error fetching renewal policy details...');
                        END;

                        v_uw_trans := 'Y';
                    END IF;
                END IF;

                BEGIN
                    SELECT scl_motor_verify
                      INTO v_scl_motor_verify
                      FROM gin_sub_classes
                     WHERE scl_code = v_ipu_data (i).ipu_scl_code;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        v_scl_motor_verify := 'N';
                END;

                IF     NVL (v_ipu_data (i).ipu_add_edit, 'A') = 'A'
                   AND NVL (v_renewal_area, 'N') = 'N'
                THEN
                    IF NVL (v_ipu_data (i).ipu_compute_max_exposure, 'N') =
                       'N'
                    THEN
                        v_max_exposure := v_ipu_data (i).ipu_max_exposure;
                    ELSE
                        v_max_exposure := 0;
                    END IF;

                    SELECT pol_policy_status
                      INTO v_pol_status
                      FROM gin_policies
                     WHERE pol_batch_no = v_batch_no;

                    IF v_pol_status = 'NB'
                    THEN
                        v_enforce_covt_prem := 'Y';
                    END IF;

                    FOR pol_cur_rec IN pol_cur
                    LOOP
                        IF    NVL (pol_cur_rec.pol_binder_policy, 'N') = 'Y'
                           OR NVL (pol_cur_rec.pro_open_cover, 'N') = 'Y'
                        THEN
                            v_uw_yr := 'R';
                        ELSE
                            v_uw_yr := 'P';
                        END IF;

                        v_risk_pymt_install_pcts :=
                            NVL (v_ipu_data (i).ipu_pymt_install_pcts,
                                 v_cvt_pymt_install_pcts);
                        v_wef_date :=
                            NVL (v_ipu_data (i).ipu_wef,
                                 pol_cur_rec.pol_wef_dt);
                        v_wet_date :=
                            NVL (v_ipu_data (i).ipu_wet,
                                 pol_cur_rec.pol_wet_dt);

                        SELECT pro_interface_type
                          INTO v_interface_type
                          FROM gin_policies, gin_products
                         WHERE     pol_pro_code = pro_code
                               AND pol_batch_no = v_batch_no;

                        IF NVL (v_interface_type, 'ACCRUAL') = 'CASH'
                        THEN
                            v_install_period :=
                                get_current_instal_period (
                                    v_wef_date,
                                    pol_cur_rec.pol_policy_cover_from,
                                    pol_cur_rec.pol_policy_cover_to,
                                    NVL (pol_cur_rec.pol_tot_instlmt, 0),
                                    v_wef_date,
                                    v_wet_date);
                        END IF;

                        v_pol_instal_wet :=
                            NVL (pol_cur_rec.pol_paid_to_date, v_wet_date);
                        get_risk_dates (
                            v_ipu_data (i).ipu_scl_code,
                            v_ipu_data (i).ipu_cvt_code,
                            NVL (pol_cur_rec.pol_tot_instlmt, 0),
                            NVL (pol_cur_rec.pro_expiry_period, 'Y'),
                            pol_cur_rec.pol_policy_cover_from,
                            pol_cur_rec.pol_policy_cover_to,
                            'N',
                            NULL,
                            'N',
                            v_susp_reinst_type,
                            v_risk_pymt_install_pcts,
                            v_wef_date,
                            v_wet_date,
                            v_install_period,
                            v_cover_days,
                            v_suspend_wef,
                            v_suspend_wet,
                            v_new_pol_wet,
                            v_pol_instal_wet);

                        v_wef := v_wef_date;

                        IF     v_ipu_data (i).ipu_install_period IS NOT NULL
                           AND v_install_period !=
                               v_ipu_data (i).ipu_install_period
                        THEN
                            IF     v_install_period + 1 !=
                                   v_ipu_data (i).ipu_install_period
                               AND NVL (pol_cur_rec.pol_loaded, 'N') != 'Y'
                            THEN
                                raise_error (
                                       'Value entered '
                                    || v_ipu_data (i).ipu_install_period
                                    || ' not allowed. Can only increment the current installment '
                                    || v_install_period
                                    || ' by one..');
                            ELSE
                                get_risk_dates (
                                    v_ipu_data (i).ipu_scl_code,
                                    v_ipu_data (i).ipu_cvt_code,
                                    NVL (pol_cur_rec.pol_tot_instlmt, 0),
                                    NVL (pol_cur_rec.pro_expiry_period, 'Y'),
                                    pol_cur_rec.pol_policy_cover_from,
                                    pol_cur_rec.pol_policy_cover_to,
                                    'Y',
                                    1,
                                    'N',
                                    v_susp_reinst_type,
                                    v_risk_pymt_install_pcts,
                                    v_wef_date,
                                    v_wet_date,
                                    v_install_period,
                                    v_cover_days,
                                    v_suspend_wef,
                                    v_suspend_wet,
                                    v_new_pol_wet,
                                    v_pol_instal_wet);

                                v_wef_date := v_wef;
                            END IF;
                        END IF;

                        BEGIN
                            IF v_pol_instal_wet !=
                               pol_cur_rec.pol_paid_to_date
                            THEN
                                UPDATE gin_policies
                                   SET pol_paid_to_date = v_pol_instal_wet
                                 WHERE pol_batch_no = v_batch_no;
                            END IF;
                        END;

                        BEGIN
                            SELECT COUNT (1)
                              INTO v_cnt
                              FROM gin_policy_insureds
                             WHERE     polin_pol_batch_no = v_batch_no
                                   AND polin_prp_code =
                                       v_ipu_data (i).prp_code;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                raise_error (
                                    'Error checking if insured already exists');
                        END;

                        IF NVL (v_cnt, 0) = 0
                        THEN
                            BEGIN
                                SELECT    TO_NUMBER (
                                              TO_CHAR (SYSDATE, 'RRRR'))
                                       || polin_code_seq.NEXTVAL
                                  INTO v_new_polin_code
                                  FROM DUAL;

                                INSERT INTO gin_policy_insureds (
                                                polin_code,
                                                polin_pol_policy_no,
                                                polin_pol_ren_endos_no,
                                                polin_pol_batch_no,
                                                polin_prp_code,
                                                polin_new_insured)
                                     VALUES (v_new_polin_code,
                                             pol_cur_rec.pol_policy_no,
                                             pol_cur_rec.pol_ren_endos_no,
                                             v_batch_no,
                                             v_ipu_data (i).prp_code,
                                             'Y');
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    raise_error (
                                        'ERROR SAVING INSURED DETAILS..');
                            END;
                        ELSE
                            BEGIN
                                SELECT polin_code
                                  INTO v_new_polin_code
                                  FROM gin_policy_insureds
                                 WHERE     polin_pol_batch_no = v_batch_no
                                       AND polin_prp_code =
                                           v_ipu_data (i).prp_code;
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    raise_error (
                                        'Error checking if insured already exists');
                            END;
                        END IF;

                        IF pol_cur_rec.pol_policy_status = 'SP'
                        THEN
                            v_ipu_prorata := 'S';
                        ELSE
                            v_ipu_prorata :=
                                NVL (v_ipu_data (i).ipu_prorata, 'P');
                        END IF;

                        IF v_wef_date NOT BETWEEN pol_cur_rec.pol_policy_cover_from
                                              AND pol_cur_rec.pol_policy_cover_to
                        THEN
                            raise_error (
                                   'The Risk cover dates provided must be within the policy cover periods. '
                                || pol_cur_rec.pol_policy_cover_from
                                || ' TO '
                                || pol_cur_rec.pol_policy_cover_to);
                        END IF;

                        IF v_wet_date NOT BETWEEN pol_cur_rec.pol_policy_cover_from
                                              AND pol_cur_rec.pol_policy_cover_to
                        THEN
                            raise_error (
                                   'The Risk cover dates provided must be within the policy cover periods. '
                                || pol_cur_rec.pol_policy_cover_from
                                || ' TO '
                                || pol_cur_rec.pol_policy_cover_to);
                        END IF;

                        IF v_ipu_data (i).ipu_suspend_wef != NULL
                        THEN
                            IF v_ipu_data (i).ipu_suspend_wef NOT BETWEEN v_wef_date
                                                                      AND v_wet_date
                            THEN
                                raise_error (
                                    'Risk Suspend Wef Date must be between Risk Dates..');
                            END IF;
                        END IF;

                        IF v_ipu_data (i).ipu_suspend_wet != NULL
                        THEN
                            IF v_ipu_data (i).ipu_suspend_wet NOT BETWEEN v_wef_date
                                                                      AND v_wet_date
                            THEN
                                raise_error (
                                    'Risk Suspend Wet Date must be between Risk Dates..');
                            END IF;
                        END IF;

                        IF v_ipu_data (i).ipu_suspend_wet <
                           v_ipu_data (i).ipu_suspend_wef
                        THEN
                            raise_error (
                                'Risk Suspend Wet Date Cannot be less than Risk Suspend Wef Date..');
                        END IF;

                        BEGIN
                            SELECT COUNT (1)
                              INTO v_cnt1
                              FROM gin_blacklist_item
                             WHERE bi_desc = v_ipu_data (i).ipu_property_id;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                v_cnt1 := 0;
                        END;

                        IF NVL (v_cnt1, 0) > 0
                        THEN
                            raise_error (
                                   'Error.. Risk '
                                || v_ipu_data (i).ipu_property_id
                                || ' is Black Listed..');
                        END IF;

                        BEGIN
                            SELECT    TO_NUMBER (TO_CHAR (SYSDATE, 'RRRR'))
                                   || gin_ipu_code_seq.NEXTVAL
                              INTO v_new_ipu_code
                              FROM DUAL;

                            INSERT INTO gin_schedule_mapping
                                     VALUES (v_new_ipu_code,
                                             -(v_ipu_data (i).gis_ipu_code),
                                             v_batch_no);

                            BEGIN
                                SELECT pol_policy_status
                                  INTO v_ipu_prev_status
                                  FROM gin_policies
                                 WHERE pol_batch_no =
                                       pol_cur_rec.pol_prev_batch_no;
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    v_ipu_prev_status := 'NB';
                            END;

                            INSERT INTO gin_insured_property_unds (
                                            ipu_code,
                                            ipu_property_id,
                                            ipu_item_desc,
                                            ipu_qty,
                                            ipu_value,
                                            ipu_wef,
                                            ipu_wet,
                                            ipu_pol_policy_no,
                                            ipu_pol_ren_endos_no,
                                            ipu_pol_batch_no,
                                            ipu_earth_quake_cover,
                                            ipu_earth_quake_prem,
                                            ipu_location,
                                            ipu_polin_code,
                                            ipu_sec_scl_code,
                                            ipu_ncd_status,
                                            ipu_related_ipu_code,
                                            ipu_prorata,
                                            ipu_gp,
                                            ipu_fap,
                                            ipu_prev_ipu_code,
                                            ipu_ncd_level,
                                            ipu_quz_code,
                                            ipu_quz_sht_desc,
                                            ipu_sht_desc,
                                            ipu_id,
                                            ipu_bind_code,
                                            ipu_excess_rate,
                                            ipu_excess_type,
                                            ipu_excess_rate_type,
                                            ipu_excess_min,
                                            ipu_excess_max,
                                            ipu_prereq_ipu_code,
                                            ipu_escalation_rate,
                                            ipu_comm_rate,
                                            ipu_prev_batch_no,
                                            ipu_cur_code,
                                            ipu_relr_code,
                                            ipu_relr_sht_desc,
                                            ipu_pol_est_max_loss,
                                            ipu_eff_wef,
                                            ipu_eff_wet,
                                            ipu_retro_cover,
                                            ipu_retro_wef,
                                            ipu_covt_code,
                                            ipu_covt_sht_desc,
                                            ipu_si_diff,
                                            ipu_terr_code,
                                            ipu_terr_desc,
                                            ipu_from_time,
                                            ipu_to_time,
                                            ipu_mar_cert_no,
                                            ipu_comp_retention,
                                            ipu_gross_comp_retention,
                                            ipu_com_retention_rate,
                                            ipu_prp_code,
                                            ipu_tot_endos_prem_dif,
                                            ipu_tot_gp,
                                            ipu_tot_value,
                                            ipu_ri_agnt_com_rate,
                                            ipu_cover_days,
                                            ipu_bp,
                                            ipu_prev_prem,
                                            ipu_ri_agnt_comm_amt,
                                            ipu_tot_fap,
                                            ipu_max_exposure,
                                            ipu_status,
                                            ipu_uw_yr,
                                            ipu_tot_first_loss,
                                            ipu_accumulation_limit,
                                            ipu_compute_max_exposure,
                                            ipu_reinsure_amt,
                                            ipu_paid_premium,
                                            ipu_trans_count,
                                            ipu_paid_tl,
                                            ipu_inception_uwyr,
                                            ipu_trans_eff_wet,
                                            ipu_eml_based_on,
                                            ipu_aggregate_limits,
                                            ipu_rc_sht_desc,
                                            ipu_rc_code,
                                            ipu_survey_date,
                                            ipu_item_details,
                                            ipu_prev_tot_fap,
                                            ipu_prev_fap,
                                            ipu_prev_reinsure_amt,
                                            ipu_free_limit,
                                            ipu_fp,
                                            ipu_conveyance_type,
                                            ipu_endose_fap_or_bc,
                                            ipu_mktr_com_rate,
                                            ipu_prev_status,
                                            ipu_ncd_cert_no,
                                            ipu_install_period,
                                            ipu_pymt_install_pcts,
                                            ipu_susp_reinstmt_type,
                                            ipu_cover_suspended,
                                            ipu_suspend_wef,
                                            ipu_suspend_wet,
                                            ipu_post_retro_wet,
                                            ipu_post_retro_cover,
                                            ipu_previous_insurer,
                                            ipu_enforce_cvt_min_prem,
                                            ipu_eml_si,
                                            ipu_cashback_appl,
                                            ipu_cashback_level,
                                            ipu_vehicle_model,
                                            ipu_vehicle_make,
                                            ipu_vehicle_model_code,
                                            ipu_vehicle_make_code,
                                            ipu_loc_town,
                                            ipu_prop_address,
                                            ipu_risk_note,
                                            ipu_model_yr,
                                            ipu_insured_driver,
                                            ipu_validate_ucr,
                                            ipu_ucr_code,
                                            ipu_pip_code,
                                            ipu_pip_pf_code,
                                            ipu_survey_agnt_code,
                                            ipu_maintenance_period_type,
                                            ipu_maintenance_period,
                                            ipu_marine_type)
                                     VALUES (
                                                TO_NUMBER (v_new_ipu_code), --IPU_CODE,
                                                v_ipu_data (i).ipu_property_id,
                                                --IPU_PROPERTY_ID,
                                                v_ipu_data (i).ipu_desc, --IPU_ITEM_DESC,
                                                NULL,               --IPU_QTY,
                                                NULL,
                                                --IPU_VALUE,
                                                v_wef_date,         --IPU_WEF,
                                                v_wet_date,         --IPU_WET,
                                                pol_cur_rec.pol_policy_no,
                                                --IPU_POL_POLICY_NO,
                                                pol_cur_rec.pol_ren_endos_no,
                                                --IPU_POL_REN_ENDOS_NO,
                                                v_batch_no,
                                                --IPU_POL_BATCH_NO,
                                                NULL, --IPU_EARTH_QUAKE_COVER,
                                                NULL,  --IPU_EARTH_QUAKE_PREM,
                                                v_ipu_data (i).ipu_location,
                                                --IPU_LOCATION,
                                                v_new_polin_code,
                                                --IPU_POLIN_CODE,
                                                v_ipu_data (i).ipu_scl_code,
                                                --IPU_SEC_SCL_CODE,
                                                v_ipu_data (i).ipu_ncd_status,
                                                --IPU_NCD_STATUS,
                                                NULL,
                                                --IPU_RELATED_IPU_CODE,
                                                v_ipu_prorata,
                                                --IPU_PRORATA,
                                                NULL,                --IPU_GP,
                                                NULL,               --IPU_FAP,
                                                TO_NUMBER (v_new_ipu_code),
                                                --ipu_prev_ipu_code,
                                                v_ipu_data (i).ipu_ncd_lvl, --IPU_NCD_LEVEL,
                                                v_ipu_data (i).ipu_quz_code, --IPU_QUZ_CODE,
                                                v_quz_sht_desc,
                                                --IPU_QUZ_SHT_DESC,
                                                NULL,          --IPU_SHT_DESC,
                                                   TO_NUMBER (
                                                       TO_CHAR (SYSDATE,
                                                                'RRRR'))
                                                || gin_ipu_id_seq.NEXTVAL, --IPU_ID,
                                                v_bind_code,
                                                -- THIS IS ONLY APPLICABLE FOR BINDER POLICIES. CHECK THE BINDER LOV ON UND_QUERY TO ADD