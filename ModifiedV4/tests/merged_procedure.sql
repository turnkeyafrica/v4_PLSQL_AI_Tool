```sql
PROCEDURE gin_policies_prc (
    v_pol_no           IN OUT VARCHAR2,
    v_pol_data         IN     web_pol_tab,
    v_agentcontact     IN     VARCHAR2,
    v_pol_batch_no     IN OUT NUMBER,
    v_user             IN     VARCHAR2,
    v_del_sect         IN     VARCHAR2 DEFAULT NULL,
    v_mar_cert_level   IN     VARCHAR2 DEFAULT NULL
) IS
    v_cnt                          NUMBER;
    v_new_polin_code               NUMBER;
    v_exp_flag                     VARCHAR2 (2);
    v_uw_yr                        VARCHAR2 (1);
    v_open_cover                   VARCHAR2 (2);
    v_pol_status                   VARCHAR2 (5);
    v_trans_no                     NUMBER;
    v_stp_code                     NUMBER;
    v_wet_date                     DATE;
    v_pol_renewal_dt               DATE;
    v_client_pol_no                VARCHAR2 (45);
    v_end_no                       VARCHAR2 (45);
    v_batchno                      NUMBER;
    v_cur_code                     NUMBER;
    v_cur_symbol                   VARCHAR2 (15);
    v_cur_rate                     NUMBER;
    v_pwet_dt                      DATE;
    v_pol_uwyr                     NUMBER;
    v_policy_doc                   VARCHAR2 (200);
    v_brn_code                     NUMBER;
    v_brn_sht_desc                 VARCHAR2 (15);
    v_endrsd_rsks_tab              gin_stp_pkg.endrsd_rsks_tab;
    v_rsk_data                     risk_tab;
    v_admin_fee_applicable         VARCHAR2 (1);
    v_ren_cnt                      NUMBER;
    v_admin_disc                   NUMBER;
    v_pro_min_prem                 NUMBER;
    v_uw_trans                     VARCHAR2 (1);
    v_valid_trans                  VARCHAR2 (1);
    v_inception_dt                 DATE;
    v_inception_yr                 NUMBER;
    y                              NUMBER;
    vuser                          VARCHAR2 (35) := pkg_global_vars.get_pvarchar2 ('PKG_GLOBAL_VARS.pvg_username');
    v_seqno                        VARCHAR2 (35);
    v_brn_sht_length               NUMBER;
    v_growth_type                  VARCHAR2 (5);
    v_pol_loaded                   VARCHAR2 (5);
    v_policy_status                VARCHAR2 (5);
    v_prev_tot_instlmt             NUMBER;
    v_cvt_install_type             gin_subclass_cover_types.sclcovt_install_type%TYPE;
    v_cvt_max_installs             gin_subclass_cover_types.sclcovt_max_installs%TYPE;
    v_cvt_pymt_install_pcts        gin_subclass_cover_types.sclcovt_pymt_install_pcts%TYPE;
    v_cvt_install_periods          gin_subclass_cover_types.sclcovt_install_periods%TYPE;
    v_install_pct                  NUMBER;
    v_pymnt_tot_instlmt            NUMBER;
    v_ipu_wef                      DATE;
    v_ipu_wet                      DATE;
    v_install_period               NUMBER;
    v_cover_days                   NUMBER;
    v_pro_sht_desc                 gin_products.pro_sht_desc%TYPE;
    next_ggts_trans_no             NUMBER;
    v_old_act_code                 NUMBER;
    v_new_act_code                 NUMBER;
    v_pro_travel_cnt               NUMBER;
    v_act_type_id                  VARCHAR2 (5);
    v_ren_wef_dt                   DATE;
    v_ren_wet_dt                   DATE;
    v_pdl_code                     NUMBER;
    v_agnt_agent_code              NUMBER;
    v_tie_agent_pol_to_brn_param   VARCHAR2 (1) := 'N';
    v_agn_brn_code                 NUMBER;
    v_client_pin_required          VARCHAR2 (1) := 'N';
    v_clnt_pin                     VARCHAR2 (15);
    v_serial                       VARCHAR2 (35);
    v_tran_ref_no                  VARCHAR2 (35);
    v_bpn_activity_share           NUMBER;
    v_valuationcount               NUMBER;
    v_ex_valuation_param           VARCHAR2 (1);
    v_binderpols_param             VARCHAR2 (1) DEFAULT 'N';
    validatedates                  NUMBER := 0;
    v_agn_sht_desc                 tqc_agencies.agn_sht_desc%TYPE;
    v_comm_applicable              VARCHAR2 (1);
    CURSOR rsks (v_old_batch_no IN NUMBER) IS
        SELECT ipu_code, ipu_polin_code, ipu_prp_code
          FROM gin_insured_property_unds, gin_policy_active_risks
         WHERE     ipu_code = polar_ipu_code
               AND polar_pol_batch_no = v_old_batch_no
               AND gin_stp_claims_pkg.claim_total_loss (ipu_code) != 'Y';
    v_seq                          NUMBER;
    v_pol_seq_type                 VARCHAR2 (100);
    CURSOR cur_risk (vbatch IN NUMBER) IS
        SELECT ipu_code,
               ipu_sec_scl_code,
               ipu_covt_code,
               ipu_pymt_install_pcts,
               pro_expiry_period
          FROM gin_insured_property_unds, gin_policies, gin_products
         WHERE     pol_batch_no = ipu_pol_batch_no
               AND pol_pro_code = pro_code
               AND ipu_pol_batch_no = vbatch;
    CURSOR cur_rel_officer IS
        SELECT usr_code,
               usr_username,
               usr_name,
               usr_email,
               usr_cell_phone_no
          FROM tq_crm.tqc_users
         WHERE usr_username =
               gin_parameters_pkg.get_param_varchar (
                   'DEFAULT_UW_REL_OFFICER');
BEGIN
    vuser := NVL (v_user, v_agentcontact);
    IF vuser IS NULL
    THEN
        raise_error ('User unknown...');
    END IF;
    SELECT gin_stp_code_seq.NEXTVAL INTO v_stp_code FROM DUAL;
    IF v_pol_data.COUNT = 0
    THEN
        raise_error ('No policy data provided..');
    END IF;
    BEGIN
        SELECT gin_parameters_pkg.get_param_varchar (
                   'TIE_AGENT_POLICY_TO_BRANCH')
          INTO v_tie_agent_pol_to_brn_param
          FROM DUAL;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            v_tie_agent_pol_to_brn_param := 'N';
        WHEN OTHERS
        THEN
            raise_error (
                'ERROR GETTING TIE_AGENT_POLICY_TO_BRANCH PARAM DETAILS');
    END;
    BEGIN
        v_binderpols_param :=
            gin_parameters_pkg.get_param_varchar (
                'NORMAL_BINDER_POLS_USESAME_SEQ');
    EXCEPTION
        WHEN OTHERS
        THEN
            v_binderpols_param := 'N';
    END;
    FOR i IN 1 .. v_pol_data.COUNT
    LOOP
        IF v_pol_data (i).pol_trans_type IN ('RN', 'NB')
        THEN
            BEGIN
                SELECT agn_brn_code
                  INTO v_agn_brn_code
                  FROM tqc_agencies
                 WHERE agn_code = v_pol_data (i).pol_agnt_agent_code;
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error ('Error getting intermediary details');
            END;
        END IF;
        BEGIN
            SELECT agn_sht_desc
              INTO v_agn_sht_desc
              FROM tqc_agencies
             WHERE agn_code = v_pol_data (i).pol_agnt_agent_code;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                v_agn_sht_desc := NULL;
            WHEN OTHERS
            THEN
                v_agn_sht_desc := NULL;
        END;
        IF v_pol_data (i).pol_brn_code IS NULL
        THEN
            SELECT brn_code, brn_sht_desc
              INTO v_brn_code, v_brn_sht_desc
              FROM tqc_organizations, tqc_branches, tqc_systems
             WHERE     org_web_brn_code = brn_code
                   AND org_code = sys_org_code
                   AND sys_code = 37;
        ELSE
            v_brn_code := v_pol_data (i).pol_brn_code;
            v_brn_sht_desc := v_pol_data (i).pol_brn_sht_desc;
        END IF;
        IF v_pol_data (i).pol_trans_type NOT IN ('SP', 'NB')
        THEN
            IF v_pol_data (i).pol_trans_type = 'ME'
            THEN
                BEGIN
                    SELECT pol_inception_dt, pol_inception_uwyr
                      INTO v_inception_dt, v_inception_yr
                      FROM gin_policies
                     WHERE pol_batch_no = v_pol_data (i).pol_batch_no;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        NULL;
                END;
                v_pol_uwyr :=
                    TO_NUMBER (
                        TO_CHAR (v_pol_data (i).pol_wef_dt, 'RRRR'));
            ELSE
                BEGIN
                    SELECT pol_uw_year,
                           pol_inception_dt,
                           pol_inception_uwyr
                      INTO v_pol_uwyr, v_inception_dt, v_inception_yr
                      FROM gin_policies
                     WHERE pol_batch_no = v_pol_data (i).pol_batch_no;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        NULL;
                END;
            END IF;
        END IF;
        BEGIN
            SELECT act_type_id
              INTO v_act_type_id
              FROM gin_policies, tqc_agencies, tqc_account_types
             WHERE     pol_agnt_agent_code = agn_code
                   AND agn_act_code = act_code
                   AND pol_batch_no = v_pol_data (i).pol_batch_no;
        EXCEPTION
            WHEN OTHERS
            THEN
                NULL;
        END;
        IF v_pol_data (i).pol_pro_code IS NOT NULL
        THEN
            BEGIN
                SELECT pro_pin_required
                  INTO v_client_pin_required
                  FROM gin_products
                 WHERE pro_code = v_pol_data (i).pol_pro_code;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    v_client_pin_required := 'N';
                WHEN OTHERS
                THEN
                    v_client_pin_required := 'N';
            END;
        END IF;
        v_wet_date := v_pol_data (i).pol_wet_dt;
        v_cur_code := v_pol_data (i).pol_cur_code;
        v_cur_rate := v_pol_data (i).pol_cur_rate;
        v_cur_symbol := v_pol_data (i).pol_cur_symbol;
        v_pol_renewal_dt :=
            get_renewal_date (v_pol_data (i).pol_pro_code, v_wet_date);
        v_uw_trans := 'Y';
        IF     NVL (v_tie_agent_pol_to_brn_param, 'N') = 'Y'
           AND v_pol_data (i).pol_trans_type IN ('NB', 'RN')
        THEN
            IF v_pol_data (i).pol_agnt_agent_code != 0
            THEN
                IF v_agn_brn_code != v_brn_code
                THEN
                    raise_error (
                           'TRANSACTION BRANCH '
                        || v_brn_code
                        || ' CANNOT BE DIFFERENT 
                     FROM INTERMEDIARY BRANCH'
                        || v_agn_brn_code);
                END IF;
            END IF;
        END IF;
        IF     (   v_pol_data (i).pol_trans_type = 'RN'
                OR v_pol_data (i).pol_trans_type = 'RE')
           AND NVL (v_pol_data (i).pol_loaded, 'N') = 'N'
        THEN
            BEGIN
                SELECT COUNT (*)
                  INTO v_ren_cnt
                  FROM gin_ren_policies
                 WHERE pol_batch_no = v_pol_data (i).pol_batch_no;
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
                     WHERE pol_batch_no = v_pol_data (i).pol_batch_no;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error (
                            'Error fetching renewal policy details...');
                END;
                v_uw_trans := 'Y';
            END IF;
            v_pol_uwyr :=
                TO_NUMBER (TO_CHAR (v_pol_data (i).pol_wef_dt, 'RRRR'));
        ELSIF    v_pol_data (i).pol_trans_type = 'NB'
              OR (    v_pol_data (i).pol_trans_type = 'RN'
                  AND NVL (v_pol_data (i).pol_loaded, 'N') = 'Y')
        THEN
            IF v_pol_data (i).pol_pro_code IS NULL
            THEN
                raise_error ('SELECT THE POLICY PRODUCT ...');
            END IF;
            IF v_pol_data (i).pol_wef_dt IS NULL
            THEN
                raise_error ('PROVIDE THE COVER FROM DATE ...');
            END IF;
            DBMS_OUTPUT.put_line (21);
            IF     v_wet_date IS NULL
               AND v_pol_data (i).pol_trans_type = 'NB'
            THEN
                v_wet_date :=
                    get_wet_date (v_pol_data (i).pol_pro_code,
                                  v_pol_data (i).pol_wef_dt);
            END IF;
            DBMS_OUTPUT.put_line (22);
            IF v_wet_date IS NULL
            THEN
                raise_error ('PROVIDE THE COVER TO DATE ...');
            END IF;
            DBMS_OUTPUT.put_line (23);
            IF     NVL (v_pol_data (i).pol_binder_policy, 'N') = 'Y'
               AND v_pol_data (i).pol_bind_code IS NULL
            THEN
                raise_error (
                    'YOU HAVE NOT DEFINED THE BORDEREAUX CODE ..');
            END IF;
            DBMS_OUTPUT.put_line (v_pol_data (i).pol_wef_dt);
            DBMS_OUTPUT.put_line (TO_CHAR (v_pol_data (i).pol_wef_dt));
            DBMS_OUTPUT.put_line (
                TO_NUMBER (TO_CHAR (v_pol_data (i).pol_wef_dt, 'RRRR')));
            v_pol_uwyr :=
                TO_NUMBER (TO_CHAR (v_pol_data (i).pol_wef_dt, 'RRRR'));
            v_inception_dt := v_pol_data (i).pol_wef_dt;
            v_inception_yr := v_pol_uwyr;
            DBMS_OUTPUT.put_line (25);
            v_pol_renewal_dt :=
                get_renewal_date (v_pol_data (i).pol_pro_code,
                                  v_wet_date);
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
                        raise_error (
                            'UNABLE TO RETRIEVE THE BASE CURRENCY');
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
                                       v_pol_data (i).pol_cur_code);
            END IF;
            BEGIN
                SELECT NVL (pro_expiry_period, 'Y'),
                       NVL (pro_open_cover, 'N')
                  INTO v_exp_flag, v_open_cover
                  FROM gin_products
                 WHERE pro_code = v_pol_data (i).pol_pro_code;
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error ('ERROR SECURING OPEN COVER STATUS..');
            END;
            IF    NVL (v_pol_data (i).pol_binder_policy, 'N') = 'Y'
               OR NVL (v_open_cover, 'N') = 'Y'
            THEN
                v_uw_yr := 'R';
            ELSE
                v_uw_yr := 'P';
            END IF;
        END IF;
        DBMS_OUTPUT.put_line (
            'TransType=' || v_pol_data (i).pol_trans_type);
        DBMS_OUTPUT.put_line (
            'ActionType=' || v_pol_data (i).pol_add_edit);
        IF     v_pol_data (i).pol_add_edit = 'E'
           AND v_pol_data (i).pol_trans_type NOT IN ('EN')
        THEN
            BEGIN
                SELECT NVL (pro_expiry_period, 'Y')
                  INTO v_exp_flag
                  FROM gin_products
                 WHERE pro_code = v_pol_data (i).pol_pro_code;
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error (
                        'ERROR CHECKING PRODUCT EXPIRY PERIOD..');
            END;
            IF v_exp_flag = 'Y'
            THEN
                SELECT COUNT ('X')
                  INTO validatedates
                  FROM gin_policies
                 WHERE     v_pol_data (i).POL_WET_DT BETWEEN pol_wef_dt
                                                         AND pol_wet_dt
                       AND pol_policy_no = v_pol_no
                       AND pol_batch_no <> v_pol_data (i).pol_batch_no
                       AND POL_CURRENT_STATUS NOT IN ('CO', 'CN')
                       AND pol_batch_no NOT IN
                               (SELECT b.pol_prev_batch_no
                                  FROM gin_policies b
                                 WHERE     b.pol_policy_no = v_pol_no
                                       AND b.POL_CURRENT_STATUS IN
                                               ('CO', 'CN'));
            ELSE
                SELECT COUNT ('X')
                  INTO validatedates
                  FROM gin_policies
                 WHERE     v_pol_data (i).POL_WET_DT BETWEEN pol_wef_dt
                                                         AND   pol_wet_dt
                                                             - 1
                       AND pol_policy_no = v_pol_no
                       AND pol_batch_no <> v_pol_data (i).pol_batch_no
                       AND POL_CURRENT_STATUS NOT IN ('CO', 'CN')
                       AND pol_batch_no NOT IN
                               (SELECT b.pol_prev_batch_no
                                  FROM gin_policies b
                                 WHERE     b.pol_policy_no = v_pol_no
                                       AND b.POL_CURRENT_STATUS IN
                                               ('CO', 'CN'));
            END IF;
            IF validatedates > 0
            THEN
                raise_error (
                       'The COVER TO Date Provided already defined for this policy. Kindly check previous endorsements'
                    || v_pol_data (i).pol_batch_no
                    || ';'
                    || v_exp_flag
                    || ';'
                    || v_pol_data (i).POL_WET_DT
                    || 'pol_trans_type='
                    || v_pol_data (i).pol_trans_type
                    || '=pol_add_edit='
                    || v_pol_data (i).pol_add_edit);
            END IF;
        END IF;
        IF     v_pol_data (i).pol_trans_type = 'NB'
           AND v_pol_data (i).pol_add_edit = 'A'
        THEN
            DBMS_OUTPUT.put_line (3);
            v_pol_no := v_pol_data (i).pol_policy_no;
            v_end_no := NULL;
            v_batchno := NULL;
            DBMS_OUTPUT.put_line (31);
            v_valid_trans :=
                gis_web_pkg.validate_transaction (
                    v_pol_data (i).pol_gis_policy_no);
            IF v_valid_trans = 'Y'
            THEN
                raise_error (
                    'This Policy has Another Unfinished Transaction..1..');
            END IF;
            IF NVL (v_pol_data (i).pol_short_period, 'N') = 'Y'
            THEN
                v_pol_status := 'SP';
            ELSE
                v_pol_status := 'NB';
            END IF;
            IF v_pol_no IS NULL OR v_end_no IS NULL OR v_batchno IS NULL
            THEN
                BEGIN
                    gen_pol_numbers (v_pol_data (i).pol_pro_code,
                                     v_brn_code,
                                     v_pol_uwyr,
                                     v_pol_status,
                                     v_pol_no,
                                     v_end_no,
                                     v_batchno,
                                     v_pol_data (i).pol_serial_no,
                                     v_pol_data (i).pol_policy_type,
                                     v_pol_data (i).pol_coinsurance,
                                     v_pol_data (i).pol_div_code);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error (
                            'UNABLE TO GENERATE THE POLICY NUMBER...');
                END;
            END IF;
            BEGIN
                check_policy_unique (v_pol_no);
            EXCEPTION
                WHEN OTHERS
                THEN
                    BEGIN
                        SELECT TO_NUMBER (
                                   SUBSTR (
                                       v_pol_no,
                                       DECODE (
                                           gin_parameters_pkg.get_param_varchar (
                                               'POL_SERIAL_AT_END'),
                                           'N', DECODE (
                                                    DECODE (
                                                        v_pol_data (i).pol_policy_type,
                                                        'N', 'P',
                                                        'F'),
                                                    'P', gin_parameters_pkg.get_param_varchar (
                                                             'POL_SERIAL_POS'),
                                                    gin_parameters_pkg.get_param_varchar (
                                                        'POL_FAC_SERIAL_POS')),
                                             LENGTH (v_pol_no)
                                           - gin_parameters_pkg.get_param_varchar (
                                                 'POLNOSRLENGTH')
                                           + 1),
                                       gin_parameters_pkg.get_param_varchar (
                                           'POLNOSRLENGTH')))
                          INTO v_seq
                          FROM DUAL;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            raise_error (
                                'Error Selecting Used Sequence...1');
                    END;
                    BEGIN
                        SELECT DECODE (v_pol_data (i).pol_policy_type,
                                       'N', 'P',
                                       'F')
                          INTO v_pol_seq_type
                          FROM DUAL;
                        gin_sequences_pkg.update_used_sequence (
                            v_pol_seq_type,
                            v_pol_data (i).pol_pro_code,
                            v_brn_code,
                            v_pol_uwyr,
                            v_pol_status,
                            v_seq,
                            v_pol_no);
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            BEGIN
                                SELECT TO_NUMBER (
                                           SUBSTR (
                                               v_pol_no,
                                               DECODE (
                                                   gin_parameters_pkg.get_param_varchar (
                                                       'POL_SERIAL_AT_END'),
                                                   'N', DECODE (
                                                            DECODE (
                                                                v_pol_data (
                                                                    i).pol_policy_type,
                                                                'N', 'P',
                                                                'F'),
                                                            'P', gin_parameters_pkg.get_param_varchar (
                                                                     'POL_SERIAL_POS'),
                                                            gin_parameters_pkg.get_param_varchar (
                                                                'POL_FAC_SERIAL_POS')),
                                                     LENGTH (v_pol_no)
                                                   - gin_parameters_pkg.get_param_varchar (
                                                         'POLNOSRLENGTH')
                                                   + 1),
                                               gin_parameters_pkg.get_param_varchar (
                                                   'POLNOSRLENGTH')))
                                  INTO v_seqno
                                  FROM DUAL;
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    raise_error (
                                        'Error Selecting Used Sequence...2');
                            END;
                            BEGIN
                                SELECT LENGTH (brn_sht_desc)
                                  INTO v_brn_sht_length
                                  FROM tqc_branches
                                 WHERE brn_code = v_brn_code;
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    NULL;
                            END;
                            IF NVL (v_brn_sht_length, 0) = 2
                            THEN
                                BEGIN
                                    v_seq := TO_NUMBER (v_seqno);
                                EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                        NULL;
                                END;
                            ELSIF NVL (v_brn_sht_length, 0) = 3
                            THEN
                                BEGIN
                                    v_seq :=
                                        TO_NUMBER (SUBSTR (v_seqno, 2));
                                EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                        NULL;
                                END;
                            ELSE
                                raise_error ('Error here....');
                            END IF;
                            BEGIN
                                SELECT DECODE (
                                           v_pol_data (i).pol_policy_type,
                                           'N', 'P',
                                           'F')
                                  INTO v_pol_seq_type
                                  FROM DUAL;
                                gin_sequences_pkg.update_used_sequence (
                                    v_pol_seq_type,
                                    v_pol_data (i).pol_pro_code,
                                    v_brn_code,
                                    v_pol_uwyr,
                                    v_pol_status,
                                    v_seq,
                                    v_pol_no);
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    raise_error (
                                        'ERROR UPDATING USED SEQUENCE...');
                            END;
                    END;
                    raise_error (
                           'Error generating Policy number  at step 2'
                        || v_pol_no);
            END;
            BEGIN
                SELECT TO_NUMBER (
                           SUBSTR (
                               v_pol_no,
                               DECODE (
                                   gin_parameters_pkg.get_param_varchar (
                                       'POL_SERIAL_AT_END'),
                                   'N', DECODE (
                                            DECODE (
                                                v_pol_data (i).pol_policy_type,
                                                'N', 'P',
                                                'F'),
                                            'P', gin_parameters_pkg.get_param_varchar (
                                                     'POL_SERIAL_POS'),
                                            gin_parameters_pkg.get_param_varchar (
                                                'POL_FAC_SERIAL_POS')),
                                     LENGTH (v_pol_no)
                                   - gin_parameters_pkg.get_param_varchar (
                                         'POLNOSRLENGTH')
                                   + 1),
                               SUBSTR (v_pol_no, - (gin_parameters_pkg.get_param_varchar (
                                                         'POLNOSRLENGTH')))))
                  INTO v_seq
                  FROM DUAL;
            EXCEPTION
                WHEN OTHERS
                THEN
                    NULL;
            END;
            BEGIN
                SELECT DECODE (v_pol_data (i).pol_policy_type,
                               'N', 'P',
                               'F')
                  INTO v_pol_seq_type
                  FROM DUAL;
                gin_sequences_pkg.update_used_sequence (
                    v_pol_seq_type,
                    v_pol_data (i).pol_pro_code,
                    v_brn_code,
                    v_pol_uwyr,
                    v_pol_status,
                    v_seq,
                    v_pol_no);
            EXCEPTION
                WHEN OTHERS
                THEN
                    BEGIN
                        SELECT (SUBSTR (
                                    v_pol_no,
                                    DECODE (
                                        gin_parameters_pkg.get_param_varchar (
                                            'POL_SERIAL_AT_END'),
                                        'N', DECODE (
                                                 DECODE (
                                                     v_pol_data (i).pol_policy_type,
                                                     'N', 'P',
                                                     'F'),
                                                 'P', gin_parameters_pkg.get_param_number (
                                                          'POL_SERIAL_POS'),
                                                 gin_parameters_pkg.get_param_number (
                                                     'POL_FAC_SERIAL_POS')),
                                          LENGTH (v_pol_no)
                                        - gin_parameters_pkg.get_param_number (
                                              'POLNOSRLENGTH')
                                        + 1),
                                    gin_parameters_pkg.get_param_varchar (
                                        'POLNOSRLENGTH')))
                          INTO v_seqno
                          FROM DUAL;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            raise_error (
                                'ERROR SELECTING USED SEQUENCE...');
                    END;
                    BEGIN
                        SELECT LENGTH (brn_sht_desc)
                          INTO v_brn_sht_length
                          FROM tqc_branches
                         WHERE brn_code = v_brn_code;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            NULL;
                    END;
                    IF NVL (v_brn_sht_length, 0) = 2
                    THEN
                        BEGIN
                            v_seq := TO_NUMBER (v_seqno);
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                NULL;
                        END;
                    ELSIF NVL (v_brn_sht_length, 0) = 3
                    THEN
                        BEGIN
                            v_seq := TO_NUMBER (SUBSTR (v_seqno, 2));
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                NULL;
                        END;
                    ELSE
                        raise_error ('Error here....');
                    END IF;
                    BEGIN
                        SELECT DECODE (v_pol_data (i).pol_policy_type,
                                       'N', 'P',
                                       'F')
                          INTO v_pol_seq_type
                          FROM DUAL;
                        gin_sequences_pkg.update_used_sequence (
                            v_pol_seq_type,
                            v_pol_data (i).pol_pro_code,
                            v_brn_code,
                            v_pol_uwyr,
                            v_pol_status,
                            v_seq,
                            v_pol_no);
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            raise_error (
                                'ERROR UPDATING USED SEQUENCE...');
                    END;
                END;
            IF     NVL (v_pol_data (i).pol_binder_policy, 'N') = 'Y'
               AND tqc_parameters_pkg.get_org_type (37) NOT IN ('INS')
            THEN
                BEGIN
                    SELECT bind_policy_no
                      INTO v_client_pol_no
                      FROM gin_binders
                     WHERE bind_code = v_pol_data (i).pol_bind_code;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error (
                            'Error getting the Contract policy no...');
                END;
            ELSE
                IF     tqc_interfaces_pkg.get_org_type (37) IN ('INS')
                   AND NVL (v_pol_data (i).pol_binder_policy, 'N') = 'Y'
                   AND v_binderpols_param = 'Y'
                THEN
                    BEGIN
                        SELECT bind_policy_no
                          INTO v_client_pol_no
                          FROM gin_binders
                         WHERE bind_code = v_pol_data (i).pol_bind_

```sql
                   bind_code;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            v_client_pol_no := v_pol_no;          --'TBA';
                        END;
                    ELSE
                        v_client_pol_no := v_pol_no;
                    END IF;
                END IF;
            DBMS_OUTPUT.put_line (4);
            v_policy_doc := v_pol_data (i).pol_policy_doc;
            IF v_policy_doc IS NULL
            THEN
                BEGIN
                    SELECT SUBSTR (pro_policy_word_doc, 1, 30),
                           pro_min_prem
                      INTO v_policy_doc, v_pro_min_prem
                      FROM gin_products
                     WHERE pro_code = v_pol_data (i).pol_pro_code;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error (
                            'Error getting the default policy document..');
                END;
            END IF;
            IF v_pol_data (i).pol_pro_sht_desc IS NULL
            THEN
                SELECT pro_sht_desc
                  INTO v_pro_sht_desc
                  FROM gin_products
                 WHERE pro_code = v_pol_data (i).pol_pro_code;
            END IF;
            BEGIN
                check_policy_unique (v_pol_no);
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error (SQLERRM (SQLCODE));
            END;
            v_pol_batch_no := v_batchno;
            IF gin_stp_pkg.determine_admin_fee (
                   v_pol_data (i).pol_prp_code,
                   v_pol_no,
                   v_admin_disc)
            THEN
                v_admin_fee_applicable := 'Y';
            ELSE
                v_admin_fee_applicable := 'N';
            END IF;
            v_growth_type :=
                gin_stp_uw_pkg.get_growth_type (
                    v_pol_data (i).pol_prp_code,
                    v_pol_status,
                    v_pol_no,
                    v_batchno);
             v_comm_applicable :=
                NVL (v_pol_data (i).pol_commission_allowed, 'Y');
            IF     v_pol_data (i).pol_agnt_agent_code = 0
               AND v_pol_data (i).pol_intro_code IS NOT NULL
            THEN
                BEGIN
                    SELECT NVL (INTRO_FEE_ALLOWED, 'N')
                      INTO v_comm_applicable
                      FROM gin_introducer
                     WHERE intro_code = v_pol_data (i).pol_intro_code;
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        v_comm_applicable := 'N';
                    WHEN OTHERS
                    THEN
                        v_comm_applicable := 'N';
                END;
            END IF;
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
                                          pol_coin_fee,
                                          pol_sub_agn_code,
                                          pol_sub_agnt_sht_desc,
                                          pol_div_code,
                                          pol_pmod_code,
                                          pol_adm_fee_applicable,
                                          pol_aga_code,
                                          pol_clna_code,
                                          pol_sub_aga_code,
                                          pol_admin_fee_disc_rate,
                                          pol_med_policy_type,
                                          pol_freq_of_payment,
                                          pol_min_prem,
                                          pol_coin_leader_combined,
                                          pol_declaration_type,
                                          pol_mktr_agn_code,
                                          pol_curr_rate_type,
                                          pol_coin_gross,
                                          pol_past_period_endos,
                                          pol_bussiness_growth_type,
                                          pol_subagent,
                                          pol_ipf_nof_instals,
                                          pol_coagent,
                                          pol_coagent_main_pct,
                                          pol_agn_discounted,
                                          pol_agn_disc_type,
                                          pol_agn_discount,
                                          pol_pip_pf_code,
                                          pol_tot_instlmt,
                                          pol_uw_period,
                                          pol_ipf_down_pymt_type,
                                          pol_ipf_down_pymt_amt,
                                          pol_ipf_interest_rate,
                                          pol_outside_system,
                                          pol_open_cover,
                                          pol_endors_status,
                                          pol_open_policy,
                                          pol_pip_code,
                                          pol_policy_debit,
                                          pol_scheme_policy,
                                          pol_pro_interface_type,
                                          pol_checkoff_agnt_sht_desc,
                                          pol_checkoff_agnt_code,
                                          pol_pymt_faci_agnt_code,
                                          pol_old_policy_no,
                                          pol_old_agent,
                                          pol_joint,
                                          pol_joint_prp_code,
                                          pol_intro_code,
                                          pol_instlmt_day,
                                          pol_pop_taxes,
                                          pol_bdiv_code,
                                          pol_regional_endors,
                                          pol_cr_note_number,
                                          pol_cr_date_notified,
                                          pol_exch_rate_fixed,
                                          pol_loaded,
                                          pol_cashback_level,
                                          pol_cashback_rate,
                                          pol_admin_fee_allowed,
                                          pol_cashback_appl,
                                          pol_uw_only,
                                          pol_debiting_type,
                                          pol_pymt_install_pcts,
                                          pol_marine_cert_level,
                                          pol_src_direct_business,
                                          POL_COIN_FAC_CESSION,
                                          POL_COIN_FAC_PC)
                             VALUES (
                                 v_pol_no,
                                 v_end_no,
                                 v_batchno,
                                 v_pol_data (i).pol_agnt_agent_code,
                                 v_agn_sht_desc,
                                 v_pol_data (i).pol_bind_code,
                                 v_pol_data (i).pol_wef_dt,
                                 v_wet_date,
                                 v_pol_uwyr,
                                 v_pol_status,
                                 v_inception_dt,
                                 v_cur_code,
                                 vuser,
                                 TRUNC (SYSDATE),
                                 NVL (v_pol_data (i).pol_policy_type, 'N'),
                                 NVL (
                                     v_client_pol_no,
                                     v_pol_data (i).pol_client_policy_number),
                                 v_brn_code,
                                 v_cur_rate,
                                 v_pol_data (i).pol_coinsurance,
                                 v_pol_data (i).pol_coinsure_leader,
                                 v_cur_symbol,
                                 v_brn_sht_desc,
                                 v_pol_data (i).pol_prp_code,
                                 'D',
                                 'N',
                                 'N',
                                 v_inception_yr,
                                 v_pol_data (i).pol_pro_code,
                                 v_pol_data (i).pol_your_ref,
                                 v_pol_data (i).pol_prop_holding_co_prp_code,
                                 v_pol_data (i).pol_oth_int_parties,
                                 NVL (v_pol_data (i).pol_pro_sht_desc,
                                      v_pro_sht_desc),
                                 v_batchno,
                                 CEIL (
                                     MONTHS_BETWEEN (
                                         v_wet_date,
                                         v_pol_data (i).pol_wef_dt)),
                                 v_pol_data (i).pol_binder_policy,
                                 NVL (v_pol_data (i).pol_renewable, 'Y'),
                                 v_wet_date,
                                 v_pol_data (i).pol_wef_dt,
                                 v_pol_data (i).pol_coinsurance_share,
                                 get_renewal_date (
                                     v_pol_data (i).pol_pro_code,
                                     v_wet_date),
                                 v_wet_date,
                                 v_pol_data (i).pol_ri_agent_comm_rate,
                                 v_pol_data (i).pol_ri_agnt_sht_desc,
                                 v_pol_data (i).pol_ri_agnt_agent_code,
                                 v_policy_doc,
                                 NVL (v_comm_applicable /*v_pol_data (i).pol_commission_allowed*/
                                                        , 'Y'),
                                 v_pol_data (i).pol_coin_fee,
                                 v_pol_data (i).pol_sub_agn_code,
                                 v_pol_data (i).pol_sub_agnt_sht_desc,
                                 v_pol_data (i).pol_div_code,
                                 v_pol_data (i).pol_pmod_code,
                                 v_admin_fee_applicable,
                                 v_pol_data (i).pol_aga_code,
                                 v_pol_data (i).pol_clna_code,
                                 v_pol_data (i).pol_sub_aga_code,
                                 v_admin_disc,
                                 v_pol_data (i).pol_med_policy_type,
                                 NVL (v_pol_data (i).pol_freq_of_payment,
                                      'A'),
                                 v_pro_min_prem,
                                 v_pol_data (i).pol_coin_leader_combined,
                                 v_pol_data (i).pol_declaration_type,
                                 v_pol_data (i).pol_mktr_agn_code,
                                 v_pol_data (i).pol_curr_rate_type,
                                 v_pol_data (i).pol_coin_gross,
                                 NVL (v_pol_data (i).pol_past_period_endos,
                                      'N'),
                                 v_growth_type,
                                 v_pol_data (i).pol_subagent,
                                 v_pol_data (i).pol_ipf_nof_instals,
                                 v_pol_data (i).pol_coagent,
                                 v_pol_data (i).pol_coagent_main_pct,
                                 v_pol_data (i).pol_agn_discounted,
                                 v_pol_data (i).pol_agn_disc_type,
                                 v_pol_data (i).pol_agn_discount,
                                 v_pol_data (i).pol_pip_pf_code,
                                 v_pol_data (i).pol_no_installment,
                                 1,
                                 v_pol_data (i).pol_ipf_down_pymt_type,
                                 v_pol_data (i).pol_ipf_down_pymt_amt,
                                 v_pol_data (i).pol_ipf_interest_rate,
                                 v_pol_data (i).pol_outside_system,
                                 NVL (v_pol_data (i).pol_open_cover, 'N'),
                                 v_pol_data (i).pol_endors_status,
                                 v_pol_data (i).pol_open_policy,
                                 v_pol_data (i).pol_oth_int_parties,
                                 v_pol_data (i).pol_policy_debit,
                                 v_pol_data (i).pol_scheme_policy,
                                 v_pol_data (i).pol_interface_type,
                                 v_pol_data (i).pol_checkoff_agnt_sht_desc,
                                 v_pol_data (i).pol_checkoff_agnt_code,
                                 v_pol_data (i).pol_pymt_faci_agnt_code,
                                 v_pol_data (i).pol_old_policy_no,
                                 v_pol_data (i).pol_old_agent,
                                 v_pol_data (i).pol_joint,
                                 v_pol_data (i).pol_joint_prp_code,
                                 v_pol_data (i).pol_intro_code,
                                 v_pol_data (i).pol_instlmt_day,
                                 v_pol_data (i).pol_pop_taxes,
                                 v_pol_data (i).pol_bdiv_code,
                                 NVL (v_pol_data (i).pol_regional_endors,
                                      'N'),
                                 v_pol_data (i).pol_cr_note_number,
                                 v_pol_data (i).pol_cr_date_notified,
                                 v_pol_data (i).pol_curr_rate_type,
                                 NVL (v_pol_data (i).pol_loaded, 'N'),
                                 0,
                                 0,
                                 v_pol_data (i).pol_admin_fee_allowed,
                                 v_pol_data (i).pol_cashback_appl,
                                 v_pol_data (i).pol_uw_only,
                                 v_pol_data (i).pol_debiting_type,
                                 v_pol_data (i).pol_payment_plan,
                                 v_mar_cert_level,
                                 v_pol_data (i).pol_src_direct_business,
                                 NVL (
                                     v_pol_data (i).POL_COIN_FAC_CESSION,
                                     'N'),
                                 v_pol_data (i).POL_COIN_FAC_PC);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error ('ERROR CREATING POLICY RECORD..');
                END;
                BEGIN
                    v_bpn_activity_share := 100;
                    FOR rel_officer IN cur_rel_officer
                    LOOP
                        tq_gis.gis_setups_pkg.bussiness_person_proc (
                            'A',
                            gin_bpn_code_seq.NEXTVAL,
                            NULL,
                            'N/A',
                            NVL (rel_officer.usr_cell_phone_no, 070),
                            NVL (rel_officer.usr_cell_phone_no, 070),
                            rel_officer.usr_email,
                            'U',
                            NULL,
                            NULL,
                            NULL,
                            rel_officer.usr_name,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            v_pol_data (i).pol_prp_code,
                            NULL,
                            v_batchno,
                            rel_officer.usr_code,
                            v_bpn_activity_share);
                    END LOOP;
                END;
                IF gin_parameters_pkg.get_param_varchar (
                       'MULTI_AGENCY_FNC_PARAM') =
                   'Y'
                THEN
                    BEGIN
                        gin_pol_extension_pkg.post_col_non_date_val_prc (
                            v_batchno,
                            'POL_MULTI_AGENCY',
                            NVL (v_pol_data (i).pol_multi_agency, 'N'),
                            v_pol_data (i).pol_add_edit);
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            raise_error (
                                'Error Creating Policy Multi Agency Details Record..');
                    END;
                END IF;
            BEGIN
                pop_sbu_dtls (v_batchno,
                              v_pol_data (i).pol_unit_code,
                              v_pol_data (i).pol_location_code,
                              v_pol_data (i).pol_add_edit);
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error (
                        'Error Creating Policy Other Details Record..');
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
                     VALUES (
                         v_pol_data (i).pol_your_ref,
                         v_trans_no,
                         v_pol_no,
                         NULL,
                         v_pol_data (i).pol_pro_code,
                         v_batchno,
                         v_pol_data (i).pol_pro_sht_desc,
                         'NB',
                         vuser,
                         TRUNC (SYSDATE),
                         v_client_pol_no,
                         'U',
                         TRUNC (SYSDATE),
                         'N',
                         NULL,
                         NULL,
                         NULL,
                         NVL (v_pol_data (i).pol_endos_eff_date,
                              TRUNC (SYSDATE)));
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error ('Error Creating Transaction Record..');
            END;
            BEGIN
                v_tran_ref_no :=
                    gin_sequences_pkg.get_number_format (
                        'BARCODE',
                        v_pol_data (i).pol_pro_code,
                        v_pol_data (i).pol_brn_code,
                        TO_NUMBER (TO_CHAR (SYSDATE, 'RRRR')),
                        'NB',
                        v_serial);
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error (
                        'unable to generate transmittal number.Contact the system administrator...');
            END;
            BEGIN
                SELECT    TO_NUMBER (TO_CHAR (SYSDATE, 'RRRR'))
                       || ggts_tran_no_seq.NEXTVAL
                  INTO next_ggts_trans_no
                  FROM DUAL;
                INSERT INTO gin_gis_transmitals (ggts_tran_no,
                                                 ggts_pol_policy_no,
                                                 ggts_cmb_claim_no,
                                                 ggts_pol_batch_no,
                                                 ggts_done_by,
                                                 ggts_done_date,
                                                 ggts_uw_clm_tran,
                                                 ggts_pol_renewal_batch,
                                                 ggts_tran_ref_no,
                                                 ggts_ipay_alphanumeric)
                     VALUES (next_ggts_trans_no,
                             v_pol_no,
                             NULL,
                             v_batchno,
                             v_user,
                             SYSDATE,
                             'U',
                             NULL,
                             v_tran_ref_no,
                             'Y');
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error (
                        'Transmital error. Contact the system administrator...');
            END;
            IF     v_pol_data (i).pol_serial_no IS NOT NULL
               AND v_pol_data (i).pol_outside_system = 'Y'
            THEN
                BEGIN
                    gin_manage_exceptions.proc_certs_excepts (
                        v_batchno,
                        v_trans_no,
                        TRUNC (SYSDATE),
                        'NB',
                        'UW');
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_when_others (
                            'Error creating certificate exception ....');
                END;
            END IF;
            BEGIN
                SELECT COUNT (1)
                  INTO v_cnt
                  FROM gin_file_master
                 WHERE film_file_no = v_pol_no;
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error (
                        'Error checking if policy file already exists..');
            END;
            IF NVL (v_cnt, 0) = 0
            THEN
                BEGIN
                    INSERT INTO gin_file_master (film_file_no,
                                                 film_file_desc,
                                                 film_type,
                                                 film_open_dt,
                                                 film_location,
                                                 film_location_dept,
                                                 film_home_shelf_no)
                        SELECT DISTINCT
                               pol_policy_no,
                               clnt_name || ' ' || clnt_other_names,
                               'U',
                               NVL (pol_inception_dt, TRUNC (SYSDATE)),
                               'HOME',
                               'HOME',
                               NULL
                          FROM gin_policies, tqc_clients
                         WHERE     pol_prp_code = clnt_code
                               AND pol_batch_no = v_batchno;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error (
                            'Error creating a file record for this policy..');
                END;
            END IF;
            IF NVL (v_pol_data (i).pol_pop_taxes, 'Y') = 'Y'
            THEN
                BEGIN
                    pop_taxes (v_pol_no,
                               v_end_no,
                               v_batchno,
                               v_pol_data (i).pol_pro_code,
                               v_pol_data (i).pol_binder_policy,
                               v_pol_status);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error ('Error updating taxes..');
                END;
            END IF;
            BEGIN
                pop_clauses (v_pol_no,
                             v_end_no,
                             v_batchno,
                             v_pol_data (i).pol_pro_code);
            EXCEPTION
                WHEN OTHERS
                THEN
                    NULL;
            END;
            IF v_pol_data (i).pol_oth_int_parties IS NOT NULL
            THEN
                BEGIN
                    pop_lien_clauses (v_pol_no,
                                      v_end_no,
                                      v_batchno,
                                      v_pol_data (i).pol_pro_code);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error ('Error updating clauses..');
                END;
            END IF;
        ELSIF     (   v_pol_data (i).pol_trans_type IN ('EN',
                                                        'NB',
                                                        'DC',
                                                        'EX',
                                                        'ME')
                   OR (    NVL (v_pol_data (i).pol_trans_type, 'NB') IN
                               ('RN', 'RE')
                       AND NVL (v_uw_trans, 'N') = 'Y'))
              AND v_pol_data (i).pol_add_edit = 'E'
        THEN
            v_pol_no := v_pol_data (i).pol_gis_policy_no;
            v_batchno := v_pol_data (i).pol_batch_no;
            v_pol_batch_no := v_pol_data (i).pol_batch_no;
            IF     NVL (v_pol_data (i).pol_binder_policy, 'N') = 'Y'
               AND tqc_parameters_pkg.get_org_type (37) NOT IN ('INS')
            THEN
                BEGIN
                    SELECT bind_policy_no
                      INTO v_client_pol_no
                      FROM gin_binders
                     WHERE bind_code = v_pol_data (i).pol_bind_code;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error (
                            'Error getting the Contract policy no...');
                END;
            ELSE
                IF     tqc_interfaces_pkg.get_org_type (37) IN ('INS')
                   AND NVL (v_pol_data (i).pol_binder_policy, 'N') = 'Y'
                   AND v_binderpols_param = 'Y'
                THEN
                    BEGIN
                        SELECT bind_policy_no
                          INTO v_client_pol_no
                          FROM gin_binders
                         WHERE bind_code = v_pol_data (i).pol_bind_code;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            v_client_pol_no := v_pol_no;
                        END;
                    ELSE
                        v_client_pol_no := v_pol_no;
                    END IF;
                END IF;
            IF NVL (v_agnt_agent_code, -2000) !=
               NVL (v_pol_data (i).pol_agnt_agent_code, -2000)
            THEN
                UPDATE gin_insured_property_unds
                   SET ipu_comm_rate = NULL
                 WHERE ipu_pol_batch_no = v_pol_batch_no;
            END IF;
            IF v_pol_data (i).pol_trans_type = 'EN'
            THEN
                DECLARE
                    v_prev_cover_to     DATE;
                    v_prev_cover_from   DATE;
                BEGIN
                    SELECT pol_policy_cover_to,
                           pol_policy_cover_from,
                           pol_loaded,
                           pol_policy_status,
                           pol_tot_instlmt
                      INTO v_prev_cover_to,
                           v_prev_cover_from,
                           v_pol_loaded,
                           v_policy_status,
                           v_prev_tot_instlmt
                      FROM gin_policies
                     WHERE pol_batch_no = v_pol_batch_no;
                    IF     v_pol_loaded != 'Y'
                       AND NVL (v_policy_status, 'XX') = 'EN'
                    THEN
                        IF v_pol_data (i).pol_wef_dt NOT BETWEEN v_prev_cover_from
                                                             AND v_prev_cover_to
                        THEN
                            raise_error (
                                   'Endorsement cover dates must be between the current cover period :'
                                || v_prev_cover_to
                                || ' to '
                                || v_prev_cover_from);
                        ELSIF v_wet_date NOT BETWEEN v_prev_cover_from
                                                 AND v_prev_cover_to
                        THEN
                            raise_error (
                                   'Endorsement cover dates must be between the current cover period :'
                                || v_prev_cover_to
                                || ' to '
                                || v_prev_cover_from);
                        END IF;
                    END IF;
                END;
            END IF;
            IF     v_pol_data (i).pol_trans_type NOT IN
                       ('NB', 'RN', 'ME')
               AND NVL (v_prev_tot_instlmt, 0) !=
                   NVL (v_pol_data (i).pol_no_installment, 0)
            THEN
                raise_error (
                    'No of installments can only be changed at New Business and Renewal..');
            END IF;
            v_policy_doc := v_pol_data (i).pol_policy_doc;
            IF v_policy_doc IS NULL
            THEN
                BEGIN
                    SELECT SUBSTR (pro_policy_word_doc, 1, 30),
                           pro_min_prem
                      INTO v_policy_doc, v_pro_min_prem
                      FROM gin_products
                     WHERE pro_code = v_pol_data (i).pol_pro_code;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error (
                            'Error getting the default policy document..');
                END;
            END IF;
            IF v_pol_data (i).pol_pro_sht_desc IS NULL
            THEN
                SELECT pro_sht_desc
                  INTO v_pro_sht_desc
                  FROM gin_products
                 WHERE pro_code = v_pol_data (i).pol_pro_code;
            END IF;
            IF NVL (v_pol_data (i).pol_pop_taxes, 'Y') = 'N'
            THEN
                DELETE FROM
                    gin_policy_taxes
                      WHERE ptx_pol_batch_no =
                            v_pol_data (i).pol_batch_no;
            END IF;
            BEGIN
                SELECT agn_act_code
                  INTO v_old_act_code
                  FROM tqc_agencies, gin_policies
                 WHERE     agn_code = pol_agnt_agent_code
                       AND pol_batch_no = v_pol_data (i).pol_batch_no;
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error ('Error getting policy agency details');
            END;
            BEGIN
                SELECT agn_act_code
                  INTO v_new_act_code
                  FROM tqc_agencies
                 WHERE agn_code = v_pol_data (i).pol_agnt_agent_code;
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error ('Error getting policy agency details');
            END;
            IF NVL (v_new_act_code, -2000) != NVL (v_old_act_code, -2000)
            THEN
                UPDATE gin_insured_property_unds
                   SET ipu_comm_rate = NULL
                 WHERE ipu_pol_batch_no = v_pol_data (i).pol_batch_no;
            END IF;
            v_comm_applicable :=
                NVL (v_pol_data (i).pol_commission_allowed, 'Y');
            IF     v_pol_data (i).pol_agnt_agent_code = 0
               AND v_pol_data (i).pol_intro_code IS NOT NULL
            THEN
                BEGIN
                    SELECT NVL (INTRO_FEE_ALLOWED, 'N')
                      INTO v_comm_applicable
                      FROM gin_introducer
                     WHERE intro_code = v_pol_data (i).pol_intro_code;
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        v_comm_applicable := 'N';
                    WHEN OTHERS
                    THEN
                        v_comm_applicable := 'N';
                END;
            END IF;
            BEGIN
                   UPDATE gin_policies
                      SET pol_agnt_agent_code =
                              v_pol_data (i).pol_agnt_agent_code,
                          pol_agnt_sht_desc = v_agn_sht_desc,
                          pol_bind_code = v_pol_data (i).pol_bind_code,
                          pol_wef_dt = v_pol_data (i).pol_wef_dt,
                          pol_wet_dt = v_wet_date,
                          pol_uw_year = v_pol_uwyr,
                          pol_inception_dt = v_inception_dt,
                          pol_cur_code = v_cur_code,
                          pol_cur_rate = v_cur_rate,
                          pol_prepared_by = vuser,
                          pol_pip_code = v_pol_data (i).pol_pip_code,
                          pol_policy_type =
                              NVL (v_pol_data (i).pol_policy_type, 'N'),
                          pol_brn_code = v_brn_code,
                          pol_coinsurance = v_pol_data (i).pol_coinsurance,
                          pol_coinsure_leader

```sql
=
                              v_pol_data (i).pol_coinsure_leader,
                          pol_cur_symbol = v_cur_symbol,
                          pol_brn_sht_desc = v_brn_sht_desc,
                          pol_prp_code = v_pol_data (i).pol_prp_code,
                          pol_inception_uwyr = v_inception_yr,
                          pol_pro_code = v_pol_data (i).pol_pro_code,
                          pol_your_ref = v_pol_data (i).pol_your_ref,
                          pol_prop_holding_co_prp_code =
                              v_pol_data (i).pol_prop_holding_co_prp_code,
                          pol_oth_int_parties =
                              v_pol_data (i).pol_oth_int_parties,
                          pol_pro_sht_desc =
                              NVL (v_pol_data (i).pol_pro_sht_desc,
                                   v_pro_sht_desc),
                          pol_uwyr_length =
                              CEIL (
                                  MONTHS_BETWEEN (v_wet_date,
                                                  v_pol_data (i).pol_wef_dt)),
                          pol_binder_policy =
                              v_pol_data (i).pol_binder_policy,
                          pol_renewable =
                              NVL (v_pol_data (i).pol_renewable, 'Y'),
                          pol_policy_cover_to = v_wet_date,
                          pol_policy_cover_from = v_pol_data (i).pol_wef_dt,
                          pol_coinsurance_share =
                              v_pol_data (i).pol_coinsurance_share,
                          pol_renewal_dt =
                              get_renewal_date (v_pol_data (i).pol_pro_code,
                                                v_wet_date),
                          pol_trans_eff_wet = v_wet_date,
                          pol_ri_agent_comm_rate =
                              v_pol_data (i).pol_ri_agent_comm_rate,
                          pol_ri_agnt_sht_desc =
                              v_pol_data (i).pol_ri_agnt_sht_desc,
                          pol_ri_agnt_agent_code =
                              v_pol_data (i).pol_ri_agnt_agent_code,
                          pol_policy_doc = v_policy_doc,
                          pol_commission_allowed =
                              NVL (v_comm_applicable /*v_pol_data (i).pol_commission_allowed*/
                                                    , 'Y'),
                          pol_coin_fee =
                              NVL (v_pol_data (i).pol_coin_fee,
                                   pol_coin_fee),
                          pol_client_policy_number =
                              NVL (
                                  NVL (
                                      v_client_pol_no,
                                      v_pol_data (i).pol_client_policy_number),
                                  pol_client_policy_number),
                          pol_div_code =
                              NVL (v_pol_data (i).pol_bdiv_code,
                                   pol_div_code),
                          pol_bdiv_code =
                              NVL (v_pol_data (i).pol_bdiv_code,
                                   pol_bdiv_code),
                          pol_pmod_code =
                              NVL (v_pol_data (i).pol_pmod_code,
                                   pol_pmod_code),
                          pol_clna_code =
                              NVL (v_pol_data (i).pol_clna_code,
                                   pol_clna_code),
                          pol_aga_code =
                              NVL (v_pol_data (i).pol_aga_code,
                                   pol_aga_code),
                          pol_sub_aga_code =
                              NVL (v_pol_data (i).pol_sub_aga_code,
                                   pol_sub_aga_code),
                          pol_sub_agn_code = v_pol_data (i).pol_sub_agn_code,
                          pol_sub_agnt_sht_desc =
                              v_pol_data (i).pol_sub_agnt_sht_desc,
                          pol_med_policy_type =
                              v_pol_data (i).pol_med_policy_type,
                          pol_freq_of_payment =
                              NVL (v_pol_data (i).pol_freq_of_payment, 'A'),
                          pol_coin_leader_combined =
                              NVL (v_pol_data (i).pol_coin_leader_combined,
                                   pol_coin_leader_combined),
                          pol_declaration_type =
                              NVL (v_pol_data (i).pol_declaration_type,
                                   pol_declaration_type),
                          pol_adm_fee_applicable =
                              NVL (v_pol_data (i).pol_fee_admissible,
                                   pol_adm_fee_applicable),
                          pol_mktr_agn_code =
                              v_pol_data (i).pol_mktr_agn_code,
                          pol_coin_gross =
                              NVL (v_pol_data (i).pol_coin_gross,
                                   pol_coin_gross),
                          pol_exch_rate_fixed =
                              NVL (v_pol_data (i).pol_curr_rate_type,
                                   pol_curr_rate_type),
                          pol_prem_computed = 'N',
                          pol_bussiness_growth_type =
                              v_pol_data (i).pol_bussiness_growth_type,
                          pol_subagent = v_pol_data (i).pol_subagent,
                          pol_ipf_nof_instals =
                              v_pol_data (i).pol_ipf_nof_instals,
                          pol_coagent = v_pol_data (i).pol_coagent,
                          pol_coagent_main_pct =
                              v_pol_data (i).pol_coagent_main_pct,
                          pol_agn_discounted =
                              v_pol_data (i).pol_agn_discounted,
                          pol_agn_disc_type =
                              v_pol_data (i).pol_agn_disc_type,
                          pol_agn_discount = v_pol_data (i).pol_agn_discount,
                          pol_pip_pf_code = v_pol_data (i).pol_pip_pf_code,
                          pol_tot_instlmt =
                              v_pol_data (i).pol_no_installment,
                          pol_ipf_down_pymt_type =
                              v_pol_data (i).pol_ipf_down_pymt_type,
                          pol_ipf_down_pymt_amt =
                              v_pol_data (i).pol_ipf_down_pymt_amt,
                          pol_ipf_interest_rate =
                              v_pol_data (i).pol_ipf_interest_rate,
                          pol_open_cover =
                              NVL (v_pol_data (i).pol_open_cover, 'N'),
                          pol_endors_status =
                              v_pol_data (i).pol_endors_status,
                          pol_open_policy =
                              NVL (v_pol_data (i).pol_open_policy, 'N'),
                          pol_policy_debit = v_pol_data (i).pol_policy_debit,
                          pol_scheme_policy =
                              v_pol_data (i).pol_scheme_policy,
                          pol_pro_interface_type =
                              NVL (v_pol_data (i).pol_interface_type,
                                   pol_pro_interface_type),
                          pol_checkoff_agnt_sht_desc =
                              v_pol_data (i).pol_checkoff_agnt_sht_desc,
                          pol_checkoff_agnt_code =
                              v_pol_data (i).pol_checkoff_agnt_code,
                          pol_pymt_faci_agnt_code =
                              v_pol_data (i).pol_pymt_faci_agnt_code,
                          pol_old_policy_no =
                              v_pol_data (i).pol_old_policy_no,
                          pol_old_agent = v_pol_data (i).pol_old_agent,
                          pol_instlmt_day = v_pol_data (i).pol_instlmt_day,
                          pol_joint = v_pol_data (i).pol_joint,
                          pol_joint_prp_code =
                              v_pol_data (i).pol_joint_prp_code,
                          pol_intro_code = v_pol_data (i).pol_intro_code,
                          pol_force_sf_compute =
                              v_pol_data (i).pol_force_sf_compute,
                          pol_enforce_sf_param =
                              v_pol_data (i).pol_enforce_sf_param,
                          pop_pip_code = v_pol_data (i).pol_oth_int_parties,
                          pol_pop_taxes = v_pol_data (i).pol_pop_taxes,
                          pol_regional_endors =
                              v_pol_data (i).pol_regional_endors,
                          pol_cr_date_notified =
                              v_pol_data (i).pol_cr_date_notified,
                          pol_cr_note_number =
                              v_pol_data (i).pol_cr_note_number,
                          pol_admin_fee_allowed =
                              v_pol_data (i).pol_admin_fee_allowed,
                          pol_cashback_appl =
                              v_pol_data (i).pol_cashback_appl,
                          pol_uw_only = v_pol_data (i).pol_uw_only,
                          pol_debiting_type =
                              v_pol_data (i).pol_debiting_type,
                          pol_pymt_install_pcts =
                              v_pol_data (i).pol_payment_plan,
                            pol_coin_fac_cession =
                                  NVL (v_pol_data (i).pol_coin_fac_cession, 'N'),
                              pol_coin_fac_pc = v_pol_data (i).pol_coin_fac_pc
                    WHERE pol_batch_no = v_pol_data (i).pol_batch_no
                RETURNING pol_ren_endos_no
                     INTO v_end_no;
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error ('Error updating policy details..');
            END;
            IF gin_parameters_pkg.get_param_varchar (
                   'MULTI_AGENCY_FNC_PARAM') =
               'Y'
            THEN
                BEGIN
                    gin_pol_extension_pkg.post_col_non_date_val_prc (
                        v_batchno,
                        'POL_MULTI_AGENCY',
                        NVL (v_pol_data (i).pol_multi_agency, 'N'),
                        v_pol_data (i).pol_add_edit);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error (
                            'Error Creating Policy Multi Agency Details Record..');
                END;
            END IF;
            BEGIN
                pop_sbu_dtls (v_pol_data (i).pol_batch_no,
                              v_pol_data (i).pol_unit_code,
                              v_pol_data (i).pol_location_code,
                              'E');
            END;
            IF v_pol_data (i).pol_oth_int_parties IS NOT NULL
            THEN
                BEGIN
                    pop_lien_clauses (v_pol_no,
                                      v_end_no,
                                      v_batchno,
                                      v_pol_data (i).pol_pro_code);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error ('Error updating clauses..');
                END;
            END IF;
            IF NVL (v_del_sect, 'N') = 'Y'
            THEN
                DELETE FROM
                    gin_policy_insured_limits
                      WHERE pil_ipu_code IN
                                (SELECT ipu_code
                                   FROM gin_insured_property_unds
                                  WHERE ipu_pol_batch_no =
                                        v_pol_data (i).pol_batch_no);
            END IF;
            IF     NVL (v_pol_data (i).pol_binder_policy, 'N') = 'Y'
               AND v_pol_data (i).pol_bind_code IS NOT NULL
            THEN
                BEGIN
                    UPDATE gin_insured_property_unds
                       SET ipu_bind_code = v_pol_data (i).pol_bind_code
                     WHERE ipu_pol_batch_no = v_pol_data (i).pol_batch_no;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        NULL;
                END;
            END IF;
            IF     v_pol_data (i).pol_trans_type IN ('NB', 'RN')
               AND NVL (v_prev_tot_instlmt, 0) !=
                   NVL (v_pol_data (i).pol_no_installment, 0)
            THEN
                FOR cur_risk_rec
                    IN cur_risk (v_pol_data (i).pol_batch_no)
                LOOP
                    BEGIN
                        SELECT sclcovt_install_type,
                               sclcovt_pymt_install_pcts
                          INTO v_cvt_install_type,
                               v_cvt_pymt_install_pcts
                          FROM gin_subclass_cover_types
                         WHERE     sclcovt_scl_code =
                                   cur_risk_rec.ipu_sec_scl_code
                               AND sclcovt_covt_code =
                                   cur_risk_rec.ipu_covt_code;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            raise_error (
                                'Error getting the minimum covertype premium..');
                    END;
                    IF NVL (v_cvt_install_type, 'NONE') IN
                           ('PYMT', 'CVRP')
                    THEN
                        IF     NVL (v_cvt_install_type, 'NONE') = 'PYMT'
                           AND NVL (v_pol_data (i).pol_no_installment, 0) >
                               1
                        THEN
                            v_install_pct :=
                                get_instalment_pct (
                                    1,
                                    NVL (
                                        cur_risk_rec.ipu_pymt_install_pcts,
                                        v_cvt_pymt_install_pcts),
                                    v_pymnt_tot_instlmt);
                            IF NVL (v_pymnt_tot_instlmt, 0) !=
                               NVL (v_pol_data (i).pol_no_installment, 0)
                            THEN
                                NULL;
                            END IF;
                        END IF;
                        IF NVL (v_pol_data (i).pol_no_installment, 0) <=
                           1
                        THEN
                            v_ipu_wef := v_pol_data (i).pol_wef_dt;
                            v_ipu_wet := v_wet_date;
                        ELSIF NVL (v_pol_data (i).pol_no_installment, 0) >
                              NVL (v_cvt_max_installs, 12)
                        THEN
                            raise_error (
                                   'Installments specified greater than allowed at cover types '
                                || NVL (v_cvt_max_installs, 12));
                        ELSE
                            v_install_period := 1;
                            v_ipu_wef := v_pol_data (i).pol_wef_dt;
                            IF NVL (v_cvt_install_periods, 'M') = 'A'
                            THEN
                                v_ipu_wet := v_wet_date;
                            ELSIF NVL (v_cvt_install_periods, 'M') = 'S'
                            THEN
                                v_ipu_wet :=
                                    ADD_MONTHS (v_ipu_wef, 6) - 1;
                            ELSIF NVL (v_cvt_install_periods, 'M') = 'Q'
                            THEN
                                v_ipu_wet :=
                                    ADD_MONTHS (v_ipu_wef, 3) - 1;
                            ELSE
                                v_ipu_wet :=
                                    ADD_MONTHS (v_ipu_wef, 1) - 1;
                            END IF;
                        END IF;
                    ELSE
                        v_ipu_wef := v_pol_data (i).pol_wef_dt;
                        v_ipu_wet := v_wet_date;
                    END IF;
                    v_cover_days := TO_NUMBER (v_ipu_wet - v_ipu_wef);
                    IF NVL (cur_risk_rec.pro_expiry_period, 'Y') = 'Y'
                    THEN
                        v_cover_days := v_cover_days + 1;
                    END IF;
                    UPDATE gin_insured_property_unds
                       SET ipu_wef = v_ipu_wef,
                            ipu_wet = v_ipu_wet,
                            ipu_eff_wef = v_ipu_wef,
                            ipu_eff_wet = v_ipu_wet,
                            ipu_uw_yr =
                                TO_NUMBER (
                                    DECODE (
                                        NVL (v_uw_yr, 'P'),
                                        'R', TO_NUMBER (
                                                 TO_CHAR (v_ipu_wef /*v_wef_date*/
                                                                   ,
                                                          'RRRR')),
                                        v_pol_uwyr)),
                            ipu_install_period = v_install_period,
                            ipu_cover_days = v_cover_days
                     WHERE ipu_code = cur_risk_rec.ipu_code;
                END LOOP;
            END IF;
            BEGIN
                SELECT COUNT (1)
                  INTO v_pro_travel_cnt
                  FROM gin_policies, gin_products
                 WHERE     pol_batch_no = v_pol_data (i).pol_batch_no
                       AND pro_code = pol_pro_code
                       AND pro_type = 'TRAVEL';
            EXCEPTION
                WHEN OTHERS
                THEN
                    v_pro_travel_cnt := 0;
            END;
            IF NVL (v_pro_travel_cnt, 0) > 0
            THEN
                BEGIN
                    gin_travel_stp_pkg.update_travel_sect_si (
                        v_pol_data (i).pol_batch_no);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error ('SI error');
                END;
            END IF;
            BEGIN
                SELECT ggt_trans_no
                  INTO v_trans_no
                  FROM gin_gis_transactions
                 WHERE     ggt_uw_clm_tran = 'U'
                       AND ggt_pol_batch_no = v_batchno;
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error ('Error retrieving transaction number..');
            END;
        ELSIF     v_pol_data (i).pol_trans_type IN ('NB',
                                                    'EN',
                                                    'CO',
                                                    'DC',
                                                    'EX')
              AND v_pol_data (i).pol_add_edit = 'D'
        THEN
            DBMS_OUTPUT.put_line (v_pol_data (i).pol_batch_no);
            BEGIN
                del_pol_dtls_proc (v_pol_data (i).pol_batch_no);
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error ('Error deleting policy..');
            END;
        ELSIF     v_pol_data (i).pol_trans_type IN ('EN',
                                                    'CN',
                                                    'EX',
                                                    'DC')
              AND v_pol_data (i).pol_add_edit = 'A'
        THEN
            IF v_pol_data (i).pol_trans_type IN ('CN', 'EX')
            THEN
                FOR rsksrec IN rsks (v_pol_data (i).pol_batch_no)
                LOOP
                    y := NVL (y, 0) + 1;
                    v_rsk_data (y).gis_ipu_code := rsksrec.ipu_code;
                    v_rsk_data (y).polin_code := rsksrec.ipu_polin_code;
                    v_rsk_data (y).prp_code := rsksrec.ipu_prp_code;
                    v_rsk_data (y).ipu_status :=
                        v_pol_data (i).pol_trans_type;
                    v_rsk_data (y).ipu_action_type := 'A';
                    IF v_pol_data (i).pol_pro_code IS NOT NULL
                    THEN
                        BEGIN
                            SELECT pro_pin_required
                              INTO v_client_pin_required
                              FROM gin_products
                             WHERE pro_code = v_pol_data (i).pol_pro_code;
                        EXCEPTION
                            WHEN NO_DATA_FOUND
                            THEN
                                v_client_pin_required := 'N';
                            WHEN OTHERS
                            THEN
                                v_client_pin_required := 'N';
                        END;
                        IF NVL (v_client_pin_required, 'N') = 'Y'
                        THEN
                            SELECT clnt_pin
                              INTO v_clnt_pin
                              FROM tqc_clients
                             WHERE clnt_code = rsksrec.ipu_prp_code;
                            IF v_clnt_pin IS NULL
                            THEN
                                raise_error (
                                    'You need the clients PINno to proceed..contact system admin');
                            END IF;
                        END IF;
                    END IF;
                END LOOP;
            END IF;
            IF v_pol_data (i).pol_trans_type IN ('CN')
            THEN
                IF gin_parameters_pkg.get_param_varchar (
                       'ALLOW_FUTURE_CANC_TRANS') =
                   'N'
                THEN
                    IF v_pol_data (i).pol_endos_eff_date >
                       TRUNC (SYSDATE)
                    THEN
                        raise_error (
                            'Cannot create cancellation when the date is in future.');
                    END IF;
                END IF;
            END IF;
             IF v_pol_data (i).pol_trans_type IN ('EX')
            THEN
                BEGIN
                    BEGIN
                        v_ex_valuation_param :=
                            gin_parameters_pkg.get_param_varchar (
                                'RESTRICT_EXTENSION_WITHOUT_VALUATION');
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            v_ex_valuation_param := 'N';
                    END;
                    SELECT COUNT ('X')
                      INTO v_valuationcount
                      FROM gin_valuation_info
                     WHERE vlt_pol_batch_no = v_pol_data (i).pol_batch_no;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error ('Error Checking Policy valuation');
                END;
                IF v_ex_valuation_param = 'Y' AND v_valuationcount = 0
                THEN
                    raise_error (
                        'POLICY NEED TO BE VALUED BEFORE DOING AN EXTENSION');
                END IF;
            END IF;
            BEGIN
                populate_endos_details (
                    v_pol_data (i).pol_gis_policy_no,
                    v_pol_data (i).pol_batch_no,
                    v_pol_data (i).pol_trans_type,
                    v_pol_data (i).pol_endos_eff_date,
                    v_pol_data (i).pol_extend_to_date,
                    v_rsk_data,
                    vuser,
                    v_endrsd_rsks_tab,
                    v_batchno,
                    v_end_no,
                    v_pol_data (i).pol_past_period_endos,
                    v_pol_data (i).pol_endorse_comm_allowed,
                    v_pol_data (i).pol_cancelled_by,
                    v_pol_data (i).pol_endors_status,
                    v_pol_data (i).pol_regional_endors);
            END;
            DBMS_OUTPUT.put_line ('after endorsement');
            v_pol_no := v_pol_data (i).pol_gis_policy_no;
            v_pol_batch_no := v_batchno;
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
                     VALUES (v_pol_data (i).pol_your_ref,
                             v_trans_no,
                             v_pol_no,
                             NULL,
                             v_pol_data (i).pol_pro_code,
                             v_batchno,
                             v_pol_data (i).pol_pro_sht_desc,
                             v_pol_data (i).pol_trans_type,
                             vuser,
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
            BEGIN
                v_tran_ref_no :=
                    gin_sequences_pkg.get_number_format (
                        'BARCODE',
                        v_pol_data (i).pol_pro_code,
                        v_pol_data (i).pol_brn_code,
                        TO_NUMBER (TO_CHAR (SYSDATE, 'RRRR')),
                        'NB',
                        v_serial);
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error (
                        'unable to generate transmittal number.Contact the system administrator...');
            END;
            BEGIN
                SELECT    TO_NUMBER (TO_CHAR (SYSDATE, 'RRRR'))
                       || ggts_tran_no_seq.NEXTVAL
                  INTO next_ggts_trans_no
                  FROM DUAL;
                INSERT INTO gin_gis_transmitals (ggts_tran_no,
                                                 ggts_pol_policy_no,
                                                 ggts_cmb_claim_no,
                                                 ggts_pol_batch_no,
                                                 ggts_done_by,
                                                 ggts_done_date,
                                                 ggts_uw_clm_tran,
                                                 ggts_pol_renewal_batch,
                                                 ggts_tran_ref_no,
                                                 ggts_ipay_alphanumeric)
                     VALUES (next_ggts_trans_no,
                             v_pol_no,
                             NULL,
                             v_batchno,
                             v_user,
                             SYSDATE,
                             'U',
                             NULL,
                             v_tran_ref_no,
                             'Y');
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error (
                        'Transmital error. Contact the system administrator...');
            END;
            FOR r IN rsks (v_pol_data (i).pol_batch_no)
            LOOP
                BEGIN
                    SELECT COUNT (1)
                      INTO v_cnt
                      FROM gin_policy_insureds
                     WHERE     polin_pol_batch_no = v_batchno
                           AND polin_prp_code = r.ipu_prp_code;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error (
                            'Error checking if insured already exists');
                END;
            END LOOP;
        ELSIF     v_pol_data (i).pol_trans_type = 'CO'
              AND v_pol_data (i).pol_add_edit = 'A'
        THEN
            raise_error (
                'take care of old trans number in gin_gis_transactions..');
            v_valid_trans :=
                gis_web_pkg.validate_transaction (
                    v_pol_data (i).pol_gis_policy_no);
            IF v_valid_trans = 'Y'
            THEN
                raise_error (
                    'This Policy has Another Unfinished Transaction..2..');
            END IF;
            SELECT TO_NUMBER (
                          TO_CHAR (SYSDATE, 'RRRR')
                       || ggt_trans_no_seq.NEXTVAL)
              INTO v_trans_no
              FROM DUAL;
            BEGIN
                create_contra_trans (v_pol_data (i).pol_batch_no,
                                     v_trans_no,
                                     v_batchno,
                                     vuser);
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error ('Error creating contra transaction.');
            END;
            v_pol_no := v_pol_data (i).pol_gis_policy_no;
            v_pol_batch_no := v_batchno;
            BEGIN
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
                     VALUES (v_pol_data (i).pol_your_ref,
                             v_trans_no,
                             v_pol_no,
                             NULL,
                             v_pol_data (i).pol_pro_code,
                             v_batchno,
                             v_pol_data (i).pol_pro_sht_desc,
                             'CO',
                             vuser,
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
                    raise_error ('Error Creating Transaction Record..');
            END;
            BEGIN
                v_tran_ref_no :=
                    gin_sequences_pkg.get_number_format (
                        'BARCODE',
                        v_pol_data (i).pol_pro_code,
                        v_pol_data (i).pol_brn_code,
                        TO_NUMBER (TO_CHAR (SYSDATE, 'RRRR')),
                        'NB',
                        v_serial);
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error (
                        'unable to generate transmittal number.Contact the system administrator...');
            END;
            BEGIN
                SELECT    TO_NUMBER (TO_CHAR (SYSDATE, 'RRRR'))
                       || ggts_tran_no_seq.NEXTVAL
                  INTO next_ggts_trans_no
                  FROM DUAL;
                INSERT INTO gin_gis_transmitals (ggts_tran_no,
                                                 ggts_pol_policy_no,
                                                 ggts_cmb_claim_no,
                                                 ggts_pol_batch_no,
                                                 ggts_done_by,
                                                 ggts_done_date,
                                                 ggts_uw_clm_tran,
                                                 ggts_pol_renewal_batch,
                                                 ggts_tran_ref_no,
                                                 ggts_ipay_alphanumeric)
                     VALUES (next_ggts_trans_no,
                             v_pol_no,
                             NULL,
                             v_batchno,
                             v_user,
                             SYSDATE,
                             'U',
                             NULL,
                             v_tran_ref_no,
                             'Y');
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error (
                        'Error unable to creaete a transaction record. Contact the system administrator...');
            END;
        ELSIF     v_pol_data (i).pol_trans_type = 'CO'
              AND v_pol_data (i).pol_add_edit = 'E'
        THEN
            v_pol_no := v_pol_data (i).pol_gis_policy_no;
            v_batchno := v_pol_data (i).pol_batch_no;
            v_pol_batch_no := v_batchno;
        ELSIF     v_pol_data (i).pol_trans_type = 'RN'
              AND NVL (v_pol_data (i).pol_loaded, 'N') = 'Y'
              AND v_pol_data (i).pol_add_edit = 'A'
        THEN
            DBMS_OUTPUT.put

```sql
_line (3);
            v_pol_no := v_pol_data (i).pol_policy_no;
            v_end_no := NULL;
            v_batchno := NULL;
            DBMS_OUTPUT.put_line (31);
            v_valid_trans :=
                gis_web_pkg.validate_transaction (
                    v_pol_data (i).pol_gis_policy_no);
            IF v_valid_trans = 'Y'
            THEN
                raise_error (
                    'This Policy has Another Unfinished Transaction..3..');
            END IF;
            IF NVL (v_pol_data (i).pol_short_period, 'N') = 'Y'
            THEN
                v_pol_status := 'SP';
            ELSE
                v_pol_status := 'NB';
            END IF;
            IF v_pol_no IS NULL OR v_end_no IS NULL OR v_batchno IS NULL
            THEN
                BEGIN
                    gen_pol_numbers (v_pol_data (i).pol_pro_code,
                                     v_brn_code,
                                     v_pol_uwyr,
                                     v_pol_status,
                                     v_pol_no,
                                     v_end_no,
                                     v_batchno,
                                     v_pol_data (i).pol_serial_no,
                                     v_pol_data (i).pol_policy_type,
                                     v_pol_data (i).pol_coinsurance,
                                     v_act_type_id);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error (
                            'UNABLE TO GENERATE THE POLICY NUMBER...');
                END;
            END IF;
            BEGIN
                check_policy_unique (v_pol_no);
            EXCEPTION
                WHEN OTHERS
                THEN
                    BEGIN
                        SELECT TO_NUMBER (
                                   SUBSTR (
                                       v_pol_no,
                                       DECODE (
                                           gin_parameters_pkg.get_param_varchar (
                                               'POL_SERIAL_AT_END'),
                                           'N', DECODE (
                                                    DECODE (
                                                        v_pol_data (i).pol_policy_type,
                                                        'N', 'P',
                                                        'F'),
                                                    'P', gin_parameters_pkg.get_param_varchar (
                                                             'POL_SERIAL_POS'),
                                                    gin_parameters_pkg.get_param_varchar (
                                                        'POL_FAC_SERIAL_POS')),
                                             LENGTH (v_pol_no)
                                           - gin_parameters_pkg.get_param_varchar (
                                                 'POLNOSRLENGTH')
                                           + 1),
                                       gin_parameters_pkg.get_param_varchar (
                                           'POLNOSRLENGTH')))
                          INTO v_seq
                          FROM DUAL;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            raise_error (
                                'Error Selecting Used Sequence...1');
                    END;
                    BEGIN
                        SELECT DECODE (v_pol_data (i).pol_policy_type,
                                       'N', 'P',
                                       'F')
                          INTO v_pol_seq_type
                          FROM DUAL;
                        gin_sequences_pkg.update_used_sequence (
                            v_pol_seq_type,
                            v_pol_data (i).pol_pro_code,
                            v_brn_code,
                            v_pol_uwyr,
                            v_pol_status,
                            v_seq,
                            v_pol_no);
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            BEGIN
                                SELECT TO_NUMBER (
                                           SUBSTR (
                                               v_pol_no,
                                               DECODE (
                                                   gin_parameters_pkg.get_param_varchar (
                                                       'POL_SERIAL_AT_END'),
                                                   'N', DECODE (
                                                            DECODE (
                                                                v_pol_data (
                                                                    i).pol_policy_type,
                                                                'N', 'P',
                                                                'F'),
                                                            'P', gin_parameters_pkg.get_param_varchar (
                                                                     'POL_SERIAL_POS'),
                                                            gin_parameters_pkg.get_param_varchar (
                                                                'POL_FAC_SERIAL_POS')),
                                                     LENGTH (v_pol_no)
                                                   - gin_parameters_pkg.get_param_varchar (
                                                         'POLNOSRLENGTH')
                                                   + 1),
                                               gin_parameters_pkg.get_param_varchar (
                                                   'POLNOSRLENGTH')))
                                  INTO v_seqno
                                  FROM DUAL;
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    raise_error (
                                        'Error Selecting Used Sequence...2');
                            END;
                            BEGIN
                                SELECT LENGTH (brn_sht_desc)
                                  INTO v_brn_sht_length
                                  FROM tqc_branches
                                 WHERE brn_code = v_brn_code;
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    NULL;
                            END;
                            IF NVL (v_brn_sht_length, 0) = 2
                            THEN
                                BEGIN
                                    v_seq := TO_NUMBER (v_seqno);
                                EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                        NULL;
                                END;
                            ELSIF NVL (v_brn_sht_length, 0) = 3
                            THEN
                                BEGIN
                                    v_seq :=
                                        TO_NUMBER (SUBSTR (v_seqno, 2));
                                EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                        NULL;
                                END;
                            ELSE
                                raise_error ('Error here....');
                            END IF;
                            BEGIN
                                SELECT DECODE (
                                           v_pol_data (i).pol_policy_type,
                                           'N', 'P',
                                           'F')
                                  INTO v_pol_seq_type
                                  FROM DUAL;
                                gin_sequences_pkg.update_used_sequence (
                                    v_pol_seq_type,
                                    v_pol_data (i).pol_pro_code,
                                    v_brn_code,
                                    v_pol_uwyr,
                                    v_pol_status,
                                    v_seq,
                                    v_pol_no);
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    raise_error (
                                        'ERROR UPDATING USED SEQUENCE...');
                            END;
                    END;
                    raise_error (
                           'Error generating Policy number  at step 2'
                        || v_pol_no);
            END;
            BEGIN
                SELECT TO_NUMBER (
                           SUBSTR (
                               v_pol_no,
                               DECODE (
                                   gin_parameters_pkg.get_param_varchar (
                                       'POL_SERIAL_AT_END'),
                                   'N', DECODE (
                                            DECODE (
                                                v_pol_data (i).pol_policy_type,
                                                'N', 'P',
                                                'F'),
                                            'P', gin_parameters_pkg.get_param_varchar (
                                                     'POL_SERIAL_POS'),
                                            gin_parameters_pkg.get_param_varchar (
                                                'POL_FAC_SERIAL_POS')),
                                     LENGTH (v_pol_no)
                                   - gin_parameters_pkg.get_param_varchar (
                                         'POLNOSRLENGTH')
                                   + 1),
                               SUBSTR (v_pol_no, - (gin_parameters_pkg.get_param_varchar (
                                                         'POLNOSRLENGTH')))))
                  INTO v_seq
                  FROM DUAL;
            EXCEPTION
                WHEN OTHERS
                THEN
                    NULL;
            END;
            BEGIN
                SELECT DECODE (v_pol_data (i).pol_policy_type,
                               'N', 'P',
                               'F')
                  INTO v_pol_seq_type
                  FROM DUAL;
                gin_sequences_pkg.update_used_sequence (
                    v_pol_seq_type,
                    v_pol_data (i).pol_pro_code,
                    v_brn_code,
                    v_pol_uwyr,
                    v_pol_status,
                    v_seq,
                    v_pol_no);
            EXCEPTION
                WHEN OTHERS
                THEN
                    BEGIN
                        SELECT (SUBSTR (
                                    v_pol_no,
                                    DECODE (
                                        gin_parameters_pkg.get_param_varchar (
                                            'POL_SERIAL_AT_END'),
                                        'N', DECODE (
                                                 DECODE (
                                                     v_pol_data (i).pol_policy_type,
                                                     'N', 'P',
                                                     'F'),
                                                 'P', gin_parameters_pkg.get_param_number (
                                                          'POL_SERIAL_POS'),
                                                 gin_parameters_pkg.get_param_number (
                                                     'POL_FAC_SERIAL_POS')),
                                          LENGTH (v_pol_no)
                                        - gin_parameters_pkg.get_param_number (
                                              'POLNOSRLENGTH')
                                        + 1),
                                    gin_parameters_pkg.get_param_varchar (
                                        'POLNOSRLENGTH')))
                          INTO v_seqno
                          FROM DUAL;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            raise_error (
                                'ERROR SELECTING USED SEQUENCE...');
                    END;
                    BEGIN
                        SELECT LENGTH (brn_sht_desc)
                          INTO v_brn_sht_length
                          FROM tqc_branches
                         WHERE brn_code = v_brn_code;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            NULL;
                    END;
                    IF NVL (v_brn_sht_length, 0) = 2
                    THEN
                        BEGIN
                            v_seq := TO_NUMBER (v_seqno);
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                NULL;
                        END;
                    ELSIF NVL (v_brn_sht_length, 0) = 3
                    THEN
                        BEGIN
                            v_seq := TO_NUMBER (SUBSTR (v_seqno, 2));
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                NULL;
                        END;
                    ELSE
                        raise_error ('Error here....');
                    END IF;
                    BEGIN
                        SELECT DECODE (v_pol_data (i).pol_policy_type,
                                       'N', 'P',
                                       'F')
                          INTO v_pol_seq_type
                          FROM DUAL;
                        gin_sequences_pkg.update_used_sequence (
                            v_pol_seq_type,
                            v_pol_data (i).pol_pro_code,
                            v_brn_code,
                            v_pol_uwyr,
                            v_pol_status,
                            v_seq,
                            v_pol_no);
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            raise_error (
                                'ERROR UPDATING USED SEQUENCE...');
                    END;
            END;
            IF     NVL (v_pol_data (i).pol_binder_policy, 'N') = 'Y'
               AND tqc_parameters_pkg.get_org_type (37) NOT IN ('INS')
            THEN
                BEGIN
                    SELECT bind_policy_no
                      INTO v_client_pol_no
                      FROM gin_binders
                     WHERE bind_code = v_pol_data (i).pol_bind_code;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error (
                            'Error getting the Contract policy no...');
                END;
            ELSE
                IF     tqc_interfaces_pkg.get_org_type (37) IN ('INS')
                   AND NVL (v_pol_data (i).pol_binder_policy, 'N') = 'Y'
                   AND v_binderpols_param = 'Y'
                THEN
                    BEGIN
                        SELECT bind_policy_no
                          INTO v_client_pol_no
                          FROM gin_binders
                         WHERE bind_code = v_pol_data (i).pol_bind_code;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            v_client_pol_no := v_pol_no;
                        END;
                    ELSE
                        v_client_pol_no := v_pol_no;
                    END IF;
                END IF;
            DBMS_OUTPUT.put_line (4);
            v_policy_doc := NULL;
            IF v_policy_doc IS NULL
            THEN
                BEGIN
                    SELECT SUBSTR (pro_policy_word_doc, 1, 30),
                           pro_min_prem
                      INTO v_policy_doc, v_pro_min_prem
                      FROM gin_products
                     WHERE pro_code = v_pol_data (i).pol_pro_code;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error (
                            'Error getting the default policy document..');
                END;
            END IF;
            v_pol_batch_no := v_batchno;
            IF gin_stp_pkg.determine_admin_fee (
                   v_pol_data (i).pol_prp_code,
                   v_pol_no,
                   v_admin_disc)
            THEN
                v_admin_fee_applicable := 'Y';
            ELSE
                v_admin_fee_applicable := 'N';
            END IF;
             IF v_pol_data (i).pol_pro_sht_desc IS NULL
                THEN
                    SELECT pro_sht_desc
                      INTO v_pro_sht_desc
                      FROM gin_products
                     WHERE pro_code = v_pol_data (i).pol_pro_code;
                END IF;
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
                                              pol_coin_fee,
                                              pol_sub_agn_code,
                                              pol_sub_agnt_sht_desc,
                                              pol_div_code,
                                              pol_pmod_code,
                                              pol_adm_fee_applicable,
                                              pol_aga_code,
                                              pol_clna_code,
                                              pol_sub_aga_code,
                                              pol_admin_fee_disc_rate,
                                              pol_med_policy_type,
                                              pol_freq_of_payment,
                                              pol_min_prem,
                                              pol_coin_leader_combined,
                                              pol_declaration_type,
                                              pol_pop_taxes,
                                              pol_exch_rate_fixed,
                                              pol_loaded,
                                              pol_reinsured,
                                              pol_tot_instlmt,
                                              pol_ipf_down_pymt_type,
                                              pol_ipf_down_pymt_amt,
                                              pol_ipf_interest_rate,
                                              pol_open_cover,
                                              pol_endors_status,
                                              pol_scheme_policy,
                                              pol_pro_interface_type,
                                              pol_checkoff_agnt_sht_desc,
                                              pol_checkoff_agnt_code,
                                              pol_pymt_faci_agnt_code,
                                              pol_old_policy_no,
                                              pol_old_agent,
                                              pol_instlmt_day,
                                              pol_bdiv_code,
                                              pol_cr_date_notified,
                                              pol_cr_note_number,
                                              pol_admin_fee_allowed,
                                              pol_cashback_appl,
                                              pol_uw_only,
                                              pol_debiting_type,
                                              pol_pymt_install_pcts,
                                             pol_coin_fac_cession,
                                              pol_coin_fac_pc)
                             VALUES (
                                 v_pol_no,
                                 v_end_no,
                                 v_batchno,
                                 v_pol_data (i).pol_agnt_agent_code,
                                 v_pol_data (i).pol_agnt_sht_desc,
                                 v_pol_data (i).pol_bind_code,
                                 v_pol_data (i).pol_wef_dt,
                                 v_wet_date,
                                 v_pol_uwyr,
                                 'RN',
                                 v_inception_dt,
                                 v_cur_code,
                                 v_user,
                                 TRUNC (SYSDATE),
                                 NVL (v_pol_data (i).pol_policy_type, 'N'),
                                 NVL (
                                     v_client_pol_no,
                                     v_pol_data (i).pol_client_policy_number),
                                 v_brn_code,
                                 v_cur_rate,
                                 v_pol_data (i).pol_coinsurance,
                                 v_pol_data (i).pol_coinsure_leader,
                                 v_cur_symbol,
                                 v_brn_sht_desc,
                                 v_pol_data (i).pol_prp_code,
                                 'A',
                                 'A',
                                 'N',
                                 v_inception_yr,
                                 v_pol_data (i).pol_pro_code,
                                 v_pol_data (i).pol_your_ref,
                                 NULL,
                                 NULL,
                                 NVL (v_pol_data (i).pol_pro_sht_desc,
                                      v_pro_sht_desc),
                                 v_batchno,
                                 CEIL (
                                     MONTHS_BETWEEN (
                                         v_wet_date,
                                         v_pol_data (i).pol_wef_dt)),
                                 v_pol_data (i).pol_binder_policy,
                                 NVL (v_pol_data (i).pol_renewable, 'Y'),
                                 v_wet_date,
                                 v_pol_data (i).pol_wef_dt,
                                 v_pol_data (i).pol_coinsurance_share,
                                 get_renewal_date (
                                     v_pol_data (i).pol_pro_code,
                                     v_wet_date),
                                 v_wet_date,
                                 v_pol_data (i).pol_ri_agent_comm_rate,
                                 v_pol_data (i).pol_ri_agnt_sht_desc,
                                 v_pol_data (i).pol_ri_agnt_agent_code,
                                 v_policy_doc,
                                 NVL (v_pol_data (i).pol_commission_allowed,
                                      'Y'),
                                 v_pol_data (i).pol_coin_fee,
                                 v_pol_data (i).pol_sub_agn_code,
                                 v_pol_data (i).pol_sub_agnt_sht_desc,
                                 v_pol_data (i).pol_div_code,
                                 v_pol_data (i).pol_pmod_code,
                                 v_admin_fee_applicable,
                                 v_pol_data (i).pol_aga_code,
                                 v_pol_data (i).pol_clna_code,
                                 v_pol_data (i).pol_sub_aga_code,
                                 v_admin_disc,
                                 v_pol_data (i).pol_med_policy_type,
                                 NVL (v_pol_data (i).pol_freq_of_payment,
                                      'A'),
                                 v_pro_min_prem,
                                 v_pol_data (i).pol_coin_leader_combined,
                                 v_pol_data (i).pol_declaration_type,
                                 v_pol_data (i).pol_pop_taxes,
                                 v_pol_data (i).pol_curr_rate_type,
                                 'Y',
                                 DECODE (
                                     NVL (v_pol_data (i).pol_loaded, 'N'),
                                     'Y', 'Y',
                                     'N'),
                                 v_pol_data (i).pol_no_installment,
                                 v_pol_data (i).pol_ipf_down_pymt_type,
                                 v_pol_data (i).pol_ipf_down_pymt_amt,
                                 v_pol_data (i).pol_ipf_interest_rate,
                                 NVL (v_pol_data (i).pol_open_cover, 'N'),
                                 v_pol_data (i).pol_endors_status,
                                 v_pol_data (i).pol_scheme_policy,
                                 v_pol_data (i).pol_interface_type,
                                 v_pol_data (i).pol_checkoff_agnt_sht_desc,
                                 v_pol_data (i).pol_checkoff_agnt_code,
                                 v_pol_data (i).pol_pymt_faci_agnt_code,
                                 v_pol_data (i).pol_old_policy_no,
                                 v_pol_data (i).pol_old_agent,
                                 v_pol_data (i).pol_instlmt_day,
                                 v_pol_data (i).pol_bdiv_code,
                                 v_pol_data (i).pol_cr_date_notified,
                                 v_pol_data (i).pol_cr_note_number,
                                 v_pol_data (i).pol_admin_fee_allowed,
                                 v_pol_data (i).pol_cashback_appl,
                                 v_pol_data (i).pol_uw_only,
                                 v_pol_data (i).pol_debiting_type,
                                 v_pol_data (i).pol_payment_plan,
                                 NVL (
                                     v_pol_data (i).POL_COIN_FAC_CESSION,
                                     'N'),
                                 v_pol_data (i).POL_COIN_FAC_PC);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error ('ERROR CREATING POLICY RECORD..');
                END;
                BEGIN
                    pop_sbu_dtls (v_batchno,
                                  v_pol_data (i).pol_unit_code,
                                  v_pol_data (i).pol_location_code,
                                  'A');
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error (
                            'Error Creating Policy Other Details Record..');
                END;
                BEGIN
                    SELECT TO_NUMBER (
                                  TO_CHAR (SYSDATE, 'YYYY')
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
                         VALUES (
                             v_pol_data (i).pol_your_ref,
                             v_trans_no,
                             v_pol_no,
                             NULL,
                             v_pol_data (i).pol_pro_code,
                             v_batchno,
                             v_pol_data (i).pol_pro_sht_desc,
                             'RN',
                             vuser,
                             TRUNC (SYSDATE),
                             v_client_pol_no,
                             'U',
                             TRUNC (SYSDATE),
                             'Y',
                             NULL,
                             NULL,
                             NULL,
                             NVL (v_pol_data (i).pol_endos_eff_date,
                                  TRUNC (SYSDATE)));
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error ('Error Creating Transaction Record..');
                END;
                BEGIN
                    v_tran_ref_no :=
                        gin_sequences_pkg.get_number_format (
                            'BARCODE',
                            v_pol_data (i).pol_pro_code,
                            v_pol_data (i).pol_brn_code,
                            TO_NUMBER (TO_CHAR (SYSDATE, 'RRRR')),
                            'NB',
                            v_serial);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error (
                            'unable to generate transmittal number.Contact the system administrator...');
                END;
                BEGIN
                    SELECT    TO_NUMBER (TO_CHAR (SYSDATE, 'RRRR'))
                           || ggts_tran_no_seq.NEXTVAL
                      INTO next_ggts_trans_no
                      FROM DUAL;
                    INSERT INTO gin_gis_transmitals (ggts_tran_no,
                                                     ggts_pol_policy_no,
                                                     ggts_cmb_claim_no,
                                                     ggts_pol_batch_no,
                                                     ggts_done_by,
                                                     ggts_done_date,
                                                     ggts_uw_clm_tran,
                                                     ggts_pol_renewal_batch,
                                                     ggts_tran_ref_no,
                                                     ggts_ipay_alphanumeric)
                         VALUES (next_ggts_trans_no,
                                 v_pol_no,
                                 NULL,
                                 v_batchno,
                                 v_user,
                                 SYSDATE,
                                 'U',
                                 NULL,
                                 v_tran_ref_no,
                                 'Y');
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error (
                            'Error unable to creaete a transaction record. Contact the system administrator...');
                END;
                BEGIN
                    IF NVL (v_pol_data (i).pol_pop_taxes, 'Y') = 'Y'
                    THEN
                        pop_taxes (v_pol_no,
                                   v_end_no,
                                   v_batchno,
                                   v_pol_data (i).pol_pro_code,
                                   v_pol_data (i).pol_binder_policy,
                                   v_pol_status);
                    END IF;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        NULL;
                END;
        ELSIF     v_pol_data (i).pol_trans_type IN ('RN', 'RE')
              AND NVL (v_uw_trans, 'N') != 'Y'
              AND v_pol_data (i).pol_add_edit = 'E'
        THEN
            v_pol_no := v_pol_data (i).pol_gis_policy_no;
            v_batchno := v_pol_data (i).pol_batch_no;
            v_pol_batch_no := v_batchno;
            IF v_pol_data (i).pol_trans_type IN ('RE')
            THEN
                BEGIN
                    SELECT pol_wet_dt
                      INTO v_pwet_dt
                      FROM gin_policies
                     WHERE     pol_prev_batch_no =
                               v_pol_data (i).pol_batch_no
                           AND pol_policy_status IN ('CN');
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        NULL;
                END;
                IF v_pol_data (i).pol_wef_dt < v_pwet_dt
                THEN
                    raise_error (
                           'Policy Wef Date Cannot be before previous cancellation Date...'
                        || v_pwet_dt);
                END IF;
            END IF;
            BEGIN
                SELECT pol_wef_dt, pol_wet_dt
                  INTO v_ren_wef_dt, v_ren_wet_dt
                  FROM gin_ren_policies
                 WHERE pol_prev_batch_no = v_pol_data (i).pol_batch_no;
            EXCEPTION
                WHEN OTHERS
                THEN
                    NULL;
            END;
            BEGIN
                   UPDATE gin_ren_policies
                      SET pol_agnt_agent_code =
                              v_pol_data (i).pol_agnt_agent_code,
                          pol_agnt_sht_desc =
                              v_pol_data (i).pol_agnt_sht_desc,
                          pol_bind_code = v_pol_data (i).pol_bind_code,
                          pol_wef_dt = v_pol_data (i).pol_wef_dt,
                          pol_wet_dt = v_wet_date,
                          pol_uw_year = v_pol_uwyr,
                          pol_inception_dt = v_pol_data (i).pol_wef_dt,
                          pol_cur_code = v_cur_code,
                          pol_cur_rate = v_cur_rate,
                          pol_prepared_by = vuser,
                          pol_policy_type =
                              NVL (v_pol_data (i).pol_policy_type, 'N'),
                          pol_brn_code = v_brn_code,
                          pol_coinsurance = v_pol_data (i).pol_coinsurance,
                          pol_coinsure_leader =
                              v_pol_data (i).pol_coinsure_leader,
                          pol_cur_symbol = v_cur_symbol,
                          pol_brn_sht_desc = v_brn_sht_desc,
                          pol_prp_code = v_pol_data (i).pol_prp_code,
                          pol_inception_uwyr = v_pol_uwyr,
                          pol_pro_code = v_pol_data (i).pol_pro_code,
                          pol_your_ref = v_pol_data (i).pol_your_ref,
                          pol_prop_holding_co_prp_code = NULL,
                          pol_oth_int_parties = NULL,
                          pol_pro_sht_desc = v_pol_data (i).pol_pro_sht_desc,
                          pol_uwyr_length =
                              CEIL (
                                  MONTHS_BETWEEN (v_wet_date,
                                                  v_pol_data (i).pol_wef_dt)),
                          pol_binder_policy =
                              v_pol_data (i).pol_binder_policy,
                          pol_renewable = v_pol_data (i).pol_renewable,
                          pol_policy_cover_to = v_wet_date,
                          pol_policy_cover_from = v_pol_data (i).pol_wef_dt,
                          pol_coinsurance_share =
                              v_pol_data (i).pol_coinsurance_share,
                          pol_renewal_dt =
                              get_renewal_date (v_pol_data (i).pol_pro_code,
                                                v_wet_date),
                          pol_trans_eff_wet = v_wet_date,
                          pol_ri_agent_comm_rate =
                              v_pol_data (i).pol_ri_agent_comm_rate,
                          pol_ri_agnt_sht_desc =
                              v_pol_data (i).pol_ri_agnt_sht_desc,
                          pol_ri_agnt_agent_code =
                              v_pol_data (i).pol_ri_agnt_agent_code,
                          pol_policy_doc = v_policy_doc,
                          pol_commission_allowed =
                              NVL (v_pol_data (i).pol_commission_allowed,
                                   'Y'),
                          pol_aga_code =
                              NVL (v_pol_data (i).pol_aga_code,
                                   pol_aga_code),
                          pol_cl

```sql
na_code =
                                  NVL (v_pol_data (i).pol_clna_code,
                                       pol_clna_code),
                          pol_sub_aga_code =
                              NVL (v_pol_data (i).pol_sub_aga_code,
                                       pol_sub_aga_code),
                          pol_med_policy_type =
                              v_pol_data (i).pol_med_policy_type,
                          pol_freq_of_payment =
                              NVL (v_pol_data (i).pol_freq_of_payment, 'A'),
                          pol_adm_fee_applicable =
                              NVL (v_pol_data (i).pol_fee_admissible,
                                   pol_adm_fee_applicable),
                          pol_mktr_agn_code =
                              NVL (v_pol_data (i).pol_mktr_agn_code,
                                       pol_mktr_agn_code),
                          pol_curr_rate_type =
                              NVL (v_pol_data (i).pol_curr_rate_type,
                                       pol_curr_rate_type),
                          pol_bussiness_growth_type =
                              v_pol_data (i).pol_bussiness_growth_type,
                          pol_subagent = v_pol_data (i).pol_subagent,
                          pol_ipf_nof_instals =
                              v_pol_data (i).pol_ipf_nof_instals,
                          pol_coagent = v_pol_data (i).pol_coagent,
                          pol_coagent_main_pct =
                              v_pol_data (i).pol_coagent_main_pct,
                          pol_agn_discounted =
                              v_pol_data (i).pol_agn_discounted,
                          pol_agn_disc_type =
                              v_pol_data (i).pol_agn_disc_type,
                          pol_agn_discount = v_pol_data (i).pol_agn_discount,
                          pol_tot_instlmt =
                              v_pol_data (i).pol_no_installment,
                          pol_ipf_down_pymt_type =
                              v_pol_data (i).pol_ipf_down_pymt_type,
                          pol_ipf_down_pymt_amt =
                              v_pol_data (i).pol_ipf_down_pymt_amt,
                          pol_ipf_interest_rate =
                              v_pol_data (i).pol_ipf_interest_rate,
                          pol_open_policy = v_pol_data (i).pol_open_policy,
                          pol_intro_code = v_pol_data (i).pol_intro_code,
                          pol_force_sf_compute =
                              v_pol_data (i).pol_force_sf_compute,
                          pol_enforce_sf_param =
                              v_pol_data (i).pol_enforce_sf_param,
                           pol_exch_rate_fixed =
                                  v_pol_data (i).pol_curr_rate_type,
                          pol_prem_computed = 'N',
                          pol_cr_date_notified =
                              v_pol_data (i).pol_cr_date_notified,
                          pol_cr_note_number =
                              v_pol_data (i).pol_cr_note_number,
                          pol_div_code =
                              NVL (v_pol_data (i).pol_bdiv_code,
                                   pol_div_code),
                          pol_bdiv_code =
                              NVL (v_pol_data (i).pol_bdiv_code,
                                   pol_bdiv_code),
                          pol_admin_fee_allowed =
                              v_pol_data (i).pol_admin_fee_allowed,
                          pol_cashback_appl =
                              v_pol_data (i).pol_cashback_appl,
                          pol_uw_only = v_pol_data (i).pol_uw_only,
                          pol_debiting_type =
                              v_pol_data (i).pol_debiting_type,
                          pol_pymt_install_pcts =
                              v_pol_data (i).pol_payment_plan
                    WHERE pol_batch_no = v_pol_data (i).pol_batch_no
                RETURNING pol_ren_endos_no
                     INTO v_end_no;
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error ('Error updating policy details..');
            END;
            BEGIN
                v_cnt := 0;
                SELECT COUNT (pdl_code)
                  INTO v_cnt
                  FROM gin_renwl_sbudtls
                 WHERE pdl_pol_batch_no = v_pol_data (i).pol_batch_no;
                IF NVL (v_cnt, 0) = 0
                THEN
                    SELECT    TO_NUMBER (TO_CHAR (SYSDATE, 'YYYY'))
                           || gin_pdl_code_seq.NEXTVAL
                      INTO v_pdl_code
                      FROM DUAL;
                    INSERT INTO gin_renwl_sbudtls (pdl_code,
                                                   pdl_pol_batch_no,
                                                   pdl_unit_code,
                                                   pdl_location_code,
                                                   pdl_prepared_date)
                         VALUES (v_pdl_code,
                                 v_pol_data (i).pol_batch_no,
                                 v_pol_data (i).pol_unit_code,
                                 v_pol_data (i).pol_location_code,
                                 TRUNC (SYSDATE));
                ELSE
                    UPDATE gin_renwl_sbudtls
                       SET pdl_unit_code =
                               NVL (v_pol_data (i).pol_unit_code,
                                    pdl_unit_code),
                            pdl_location_code =
                                NVL (v_pol_data (i).pol_location_code,
                                     pdl_location_code)
                     WHERE pdl_pol_batch_no = v_pol_data (i).pol_batch_no;
                END IF;
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error ('Error updating policy details..');
            END;
            IF     NVL (v_pol_data (i).pol_binder_policy, 'N') = 'Y'
               AND v_pol_data (i).pol_bind_code IS NOT NULL
            THEN
                BEGIN
                    UPDATE gin_ren_insured_property_unds
                       SET ipu_bind_code = v_pol_data (i).pol_bind_code
                     WHERE ipu_pol_batch_no = v_pol_data (i).pol_batch_no;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        NULL;
                END;
            END IF;
            IF v_ren_wef_dt != v_pol_data (i).pol_wef_dt
            THEN
                UPDATE gin_ren_insured_property_unds
                   SET ipu_wef = v_pol_data (i).pol_wef_dt,
                        ipu_eff_wef = v_pol_data (i).pol_wef_dt,
                        ipu_uw_yr = v_pol_uwyr
                 WHERE ipu_pol_batch_no = v_pol_data (i).pol_batch_no;
            END IF;
            IF v_ren_wet_dt != v_wet_date
            THEN
                UPDATE gin_ren_insured_property_unds
                   SET ipu_wet = v_wet_date,
                        ipu_eff_wet = v_wet_date,
                        ipu_trans_eff_wet = v_wet_date
                 WHERE ipu_pol_batch_no = v_pol_data (i).pol_batch_no;
            END IF;
            BEGIN
                SELECT ggt_trans_no
                  INTO v_trans_no
                  FROM gin_gis_transactions
                 WHERE     ggt_uw_clm_tran = 'U'
                       AND ggt_pol_batch_no = v_batchno;
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error ('Error retrieving transaction number..');
            END;
        ELSIF     v_pol_data (i).pol_trans_type IN ('RN', 'RE')
              AND NVL (v_uw_trans, 'N') != 'Y'
              AND v_pol_data (i).pol_add_edit = 'D'
        THEN
            BEGIN
                del_ren_pol_proc (v_pol_data (i).pol_batch_no);
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error ('Error deleting policy..');
            END;
            v_pol_batch_no := NULL;
        ELSIF     v_pol_data (i).pol_trans_type IN ('CT')
              AND NVL (v_uw_trans, 'N') = 'Y'
              AND v_pol_data (i).pol_add_edit = 'A'
        THEN
            create_midterm_trans (v_pol_data (i).pol_batch_no,
                                  v_pol_batch_no,
                                  vuser,
                                  v_pol_data (i).pol_endos_eff_date);
        ELSE
            raise_error (
                   'Transaction type '
                || v_pol_data (i).pol_trans_type
                || ' and Action type '
                || v_pol_data (i).pol_add_edit
                || ' not catered for.. ');
        END IF;
    END LOOP;
END;
```