PROCEDURE gin_policies_stp_prc (v_pro_code     IN     NUMBER,
                                    v_brn_code     IN     NUMBER,
                                    v_cover_from   IN     DATE,
                                    v_cover_to     IN     DATE,
                                    v_user         IN     VARCHAR2,
                                    v_cur_code     IN     NUMBER,
                                    v_prp_code     IN     NUMBER,
                                    v_bind_code    IN     NUMBER,
                                    v_rsk_data     IN     web_risk_tab,
                                    v_uni_code     IN     NUMBER,
                                    v_loc_code     IN     NUMBER,
                                    v_agnt_code    IN     NUMBER,
                                    v_pop_taxes    IN     VARCHAR2,
                                    v_batchno         OUT NUMBER)
    IS
        v_cnt                      NUMBER;
        v_new_polin_code           NUMBER;
        v_exp_flag                 VARCHAR2 (2);
        v_uw_yr                    VARCHAR2 (1);
        v_open_cover               VARCHAR2 (2);
        v_pol_status               VARCHAR2 (5);
        v_trans_no                 NUMBER;
        v_stp_code                 NUMBER;
        v_wet_date                 DATE;
        v_pol_renewal_dt           DATE;
        v_new_ipu_code             NUMBER;
        v_client_pol_no            VARCHAR2 (45);
        v_end_no                   VARCHAR2 (45);
        --v_batchno                 NUMBER;
        v_cur_symbol               VARCHAR2 (15);
        v_cur_rate                 NUMBER;
        v_pwet_dt                  DATE;
        v_pol_uwyr                 NUMBER;
        v_policy_doc               VARCHAR2 (200);
        v_brn_sht_desc             VARCHAR2 (15);
        v_endrsd_rsks_tab          gin_stp_pkg.endrsd_rsks_tab;
        v_rsk_sect_data            web_sect_tab;
        v_admin_fee_applicable     VARCHAR2 (1);
        v_ren_cnt                  NUMBER;
        v_admin_disc               NUMBER;
        v_pro_min_prem             NUMBER;
        v_uw_trans                 VARCHAR2 (1);
        v_valid_trans              VARCHAR2 (1);
        v_inception_dt             DATE;
        v_inception_yr             NUMBER;
        y                          NUMBER;
        vuser                      VARCHAR2 (35)
            := pkg_global_vars.get_pvarchar2 ('PKG_GLOBAL_VARS.pvg_username');
        v_seqno                    VARCHAR2 (35);
        v_brn_sht_length           NUMBER;
        v_growth_type              VARCHAR2 (5);
        v_pol_loaded               VARCHAR2 (5);
        v_policy_status            VARCHAR2 (5);
        v_prev_tot_instlmt         NUMBER;
        v_install_pct              NUMBER;
        v_pymnt_tot_instlmt        NUMBER;
        v_ipu_wef                  DATE;
        v_ipu_wet                  DATE;
        v_install_period           NUMBER;
        v_cover_days               NUMBER;
        v_pro_sht_desc             gin_products.pro_sht_desc%TYPE;
        next_ggts_trans_no         NUMBER;
        v_old_act_code             NUMBER;
        v_new_act_code             NUMBER;
        v_pro_travel_cnt           NUMBER;
        v_ren_wef_dt               DATE;
        v_ren_wet_dt               DATE;
        v_pdl_code                 NUMBER;
        v_agnt_agent_code          NUMBER;
        v_seq                      NUMBER;
        v_pol_seq_type             VARCHAR2 (100);
        v_trans_type               VARCHAR2 (5);
        vcur_code                  NUMBER;
        v_coinsurance              VARCHAR2 (1);
        v_div_code                 NUMBER;
        v_pol_no                   VARCHAR2 (50);
        v_serial_no                NUMBER;
        v_policy_type              VARCHAR2 (50);
        v_binder_policy            VARCHAR2 (2);
        v_agent_code               NUMBER;
        v_agnt_sht_desc            VARCHAR2 (50);
        --v_pop_taxes              VARCHAR2 (2);
        v_outside_system           VARCHAR2 (1);
        v_interface_type           VARCHAR2 (50);
        v_row                      NUMBER;
        v_comm_allowed             VARCHAR2 (1);
        v_tran_ref_no              VARCHAR2 (100);
        v_serial                   VARCHAR2 (100);
        v_cashback_lvl             NUMBER;
        v_cashback_rate            NUMBER;
        sect_cursor                SYS_REFCURSOR;
        v_sect_sht_desc            gin_sections.sect_sht_desc%TYPE;
        v_sec_code                 gin_sections.sect_code%TYPE;
        v_sect_desc                gin_sections.sect_desc%TYPE;
        v_sect_type                gin_sections.sect_type%TYPE;
        v_type_desc                VARCHAR2 (25);
        v_prr_rate_type            gin_premium_rates.prr_rate_type%TYPE;
        v_prr_rate                 gin_premium_rates.prr_rate%TYPE;
        v_terr_description         VARCHAR2 (5);
        v_prr_prem_minimum_amt     gin_premium_rates.prr_prem_minimum_amt%TYPE;
        v_prr_multiplier_rate      gin_premium_rates.prr_multiplier_rate%TYPE;
        v_prr_division_factor      gin_premium_rates.prr_division_factor%TYPE;
        v_prr_multplier_div_fact   gin_premium_rates.prr_multplier_div_fact%TYPE;
        v_prr_rate_desc            gin_premium_rates.prr_rate_desc%TYPE;
        v_prr_free_limit           gin_premium_rates.prr_free_limit%TYPE;
        v_sec_declaration          gin_subcl_sections.sec_declaration%TYPE;
        v_scvts_order              gin_subcl_covt_sections.scvts_order%TYPE;
        v_prr_prorated_full        gin_premium_rates.prr_prorated_full%TYPE;
        v_prr_si_limit_type        gin_premium_rates.prr_si_limit_type%TYPE;
        v_prr_si_rate              gin_premium_rates.prr_si_rate%TYPE;
    BEGIN
        vuser := v_user;

        IF vuser IS NULL
        THEN
            raise_error ('User unknown...');
        END IF;

        BEGIN
            SELECT brn_sht_desc
              INTO v_brn_sht_desc
              FROM tqc_branches
             WHERE brn_code = v_brn_code;
        EXCEPTION
            WHEN OTHERS
            THEN
                raise_error ('ERROR GETTING BRANCH DETAILS');
        END;