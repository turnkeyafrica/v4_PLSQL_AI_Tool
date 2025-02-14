PROCEDURE gin_ipu_stp_prc090216 (v_batchno        IN     NUMBER,
                                     v_bind_code      IN     NUMBER,
                                     v_property_id    IN     VARCHAR2,
                                     v_ipu_desc       IN     VARCHAR2,
                                     -- v_limit      IN      NUMBER,
                                     v_user           IN     VARCHAR2,
                                     --v_rsk_sect_data               IN   web_sect_tab,
                                     v_scl_code       IN     NUMBER,
                                     v_covt_code      IN     NUMBER,
                                     v_new_ipu_code      OUT NUMBER)
    IS
        v_loaded                   VARCHAR2 (1) DEFAULT 'N';
        v_ipu_ncd_cert_no          VARCHAR2 (30) DEFAULT NULL;
        v_del_sect                 VARCHAR2 (1) DEFAULT NULL;
        v_cnt                      NUMBER;
        v_new_polin_code           NUMBER;
        v_uw_yr                    VARCHAR2 (1);
        v_wef_date                 DATE;
        v_wet_date                 DATE;
        v_cover_days               NUMBER;
        v_bind_name                VARCHAR2 (100);
        v_cert_no                  VARCHAR2 (35);
        v_quz_sht_desc             VARCHAR2 (35);
        --v_count                                NUMBER;
        v_uw_trans                 VARCHAR2 (1);
        v_ren_cnt                  NUMBER;
        v_ipu_prev_status          VARCHAR2 (35);
        v_ipu_prorata              VARCHAR2 (2);
        v_pol_tot_instlmt          NUMBER;
        v_pymnt_tot_instlmt        NUMBER;
        v_install_pct              NUMBER;
        v_ipu_id                   NUMBER;
        v_cer_cnt                  NUMBER;
        v_ct_code                  NUMBER;
        v_error                    VARCHAR2 (200);
        v_cer_cnt                  NUMBER;
        v_ipu_id                   NUMBER;
        v_install_period           NUMBER;
        v_polc_code                NUMBER;
        v_risk_pymt_install_pcts   VARCHAR2 (50);
        v_susp_reinst_type         VARCHAR2 (5);
        v_suspend_wef              DATE;
        v_suspend_wet              DATE;
        v_new_pol_wet              DATE;
        v_rsk_trans_type           VARCHAR2 (3);
        v_pol_instal_wet           DATE;
        v_wef                      DATE;
        v_prev_install_period      NUMBER;
        v_increment_by             NUMBER;
        v_increment                VARCHAR2 (2);
        v_interface_type           VARCHAR2 (50);
        v_cnt1                     NUMBER;
        v_risk_id_format           VARCHAR2 (50);
        v_risk_id_format_param     VARCHAR2 (50);
        v_id_reg_no                VARCHAR2 (50);
        v_clnt_pin_no              VARCHAR2 (50);
        v_ipu_covt_code            NUMBER;
        v_clnt_passport_no         VARCHAR2 (50);
        v_agent_code               NUMBER;
        v_agn_pin                  VARCHAR2 (50);
        v_max_exposure             NUMBER;
        v_pol_status               VARCHAR2 (10);
        v_enforce_covt_prem        VARCHAR2 (1);
        v_cert_autogen             VARCHAR2 (1);
        v_agnt_agent_code          NUMBER;
        v_trans_type               VARCHAR2 (5);
        v_covt_sht_desc            VARCHAR2 (20);

        CURSOR pol_cur IS
            SELECT gin_policies.*,
                   NVL (pro_expiry_period, 'Y')     pro_expiry_period,
                   NVL (pol_open_cover, 'N')        pro_open_cover,
                   NVL (pro_earthquake, 'N')        pro_earthquake,
                   NVL (pro_moto_verfy, 'N')        pro_moto_verfy,
                   NVL (pro_stp, 'N')               pro_stp
              FROM gin_policies, gin_products
             WHERE pro_code = pol_pro_code AND pol_batch_no = v_batchno;
    BEGIN
        v_trans_type := 'NB';

        SELECT bind_name
          INTO v_bind_name
          FROM gin_binders
         WHERE bind_code = v_bind_code;

        --RAISE_eRROR(v_bind_code|| ' = '||v_scl_code);
        --                    SELECT db_covt_code
        --                      INTO v_covt_code
        --                      FROM gin_binder_details
        --                     WHERE db_bind_code = v_bind_code;
        SELECT covt_sht_desc
          INTO v_covt_sht_desc
          FROM gin_cover_types
         WHERE covt_code = v_covt_code;

        SELECT scl_bond_subclass
          INTO v_cert_autogen
          FROM gin_sub_classes
         WHERE scl_code = v_scl_code;

        FOR pol_cur_rec IN pol_cur
        LOOP
            IF pol_cur_rec.pol_policy_status = 'NB'
            THEN
                v_enforce_covt_prem := 'Y';
            END IF;

            IF    NVL (pol_cur_rec.pol_binder_policy, 'N') = 'Y'
               OR NVL (pol_cur_rec.pro_open_cover, 'N') = 'Y'
            THEN
                v_uw_yr := 'R';
            ELSE
                v_uw_yr := 'P';
            END IF;

            v_wef_date := pol_cur_rec.pol_policy_cover_from;
            v_wet_date := pol_cur_rec.pol_policy_cover_to;
            -- raise_error(pol_cur_rec.pol_policy_cover_from||' = '||pol_cur_rec.pol_policy_cover_to);
            v_wef := v_wef_date;

            BEGIN
                IF v_pol_instal_wet != pol_cur_rec.pol_paid_to_date
                THEN
                    UPDATE gin_policies
                       SET pol_paid_to_date = v_pol_instal_wet
                     WHERE pol_batch_no = v_batchno;
                END IF;
            END;