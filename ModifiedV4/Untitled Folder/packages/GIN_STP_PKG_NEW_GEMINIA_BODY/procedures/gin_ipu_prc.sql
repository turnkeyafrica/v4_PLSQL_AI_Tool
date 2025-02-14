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