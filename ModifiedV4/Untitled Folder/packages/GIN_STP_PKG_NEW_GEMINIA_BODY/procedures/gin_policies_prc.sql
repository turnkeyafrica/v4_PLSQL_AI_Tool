PROCEDURE gin_policies_prc (
        v_pol_no           IN OUT VARCHAR2,
        v_pol_data         IN     web_pol_tab,
        v_agentcontact     IN     VARCHAR2,
        v_pol_batch_no     IN OUT NUMBER,
        v_user             IN     VARCHAR2,
        v_del_sect         IN     VARCHAR2 DEFAULT NULL,
        v_mar_cert_level   IN     VARCHAR2 DEFAULT NULL)
    IS
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
        vuser                          VARCHAR2 (35)
            := pkg_global_vars.get_pvarchar2 ('PKG_GLOBAL_VARS.pvg_username');
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

        CURSOR rsks (v_old_batch_no IN NUMBER)
        IS
            SELECT ipu_code, ipu_polin_code, ipu_prp_code
              FROM gin_insured_property_unds, gin_policy_active_risks
             WHERE     ipu_code = polar_ipu_code
                   AND polar_pol_batch_no = v_old_batch_no
                   AND gin_stp_claims_pkg.claim_total_loss (ipu_code) != 'Y';

        v_seq                          NUMBER;
        v_pol_seq_type                 VARCHAR2 (100);

        CURSOR cur_risk (vbatch IN NUMBER)
        IS
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
        --raise_error('v_mar_cert_level ' || v_mar_cert_level);
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