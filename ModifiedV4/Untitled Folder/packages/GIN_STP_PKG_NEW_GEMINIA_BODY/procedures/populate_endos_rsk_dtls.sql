PROCEDURE populate_endos_rsk_dtls (
        v_old_batch_no       IN     NUMBER,
        v_trans_type         IN     VARCHAR2,
        v_new_batch_no       IN     NUMBER,
        v_old_ipu_code       IN     NUMBER,
        v_ipu_add_edit       IN     VARCHAR2,
        v_new_ipu_code          OUT NUMBER,
        v_action_type        IN     VARCHAR2,
        --S Suspend, C Cancel RT Reinstate R Revise
        v_del_date           IN     DATE DEFAULT NULL,
        v_susp_reinst_type   IN     VARCHAR2 DEFAULT 'PREM',
        -- Reinstate by refund premium (PREM) or Extending days (DAYS)
        v_rcpt_amt           IN     NUMBER DEFAULT NULL,
        -- cash basis  functionality
        v_sclcode            IN     NUMBER DEFAULT NULL,
        v_bindcode           IN     NUMBER DEFAULT NULL,
        v_covtcode           IN     NUMBER DEFAULT NULL,
        v_dtfrom             IN     DATE DEFAULT NULL,
        v_dtto               IN     DATE DEFAULT NULL,
        v_no_of_months       IN     NUMBER DEFAULT NULL)
    IS
        CURSOR cur_ipu IS
            SELECT DISTINCT
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
                   ipu_bp,
                   ipu_fp,
                   ipu_gross_comp_retention,
                   ipu_prev_prem,
                   ipu_com_retention_rate,
                   ipu_prp_code,
                   ipu_tot_endos_prem_dif,
                   ipu_tot_gp,
                   ipu_tot_value,
                   ipu_ri_agnt_com_rate,
                   ipu_cover_days,
                   ipu_ri_agnt_comm_amt,
                   ipu_tot_fap,
                   ipu_max_exposure,
                   ipu_uw_yr,
                   ipu_tot_first_loss,
                   ipu_accumulation_limit,
                   ipu_reinsure_amt,
                   ipu_compute_max_exposure,
                   ipu_paid_premium,
                   ipu_trans_count,
                   ipu_paid_tl,
                   ipu_inception_uwyr,
                   ipu_endos_remove,
                   ipu_eml_based_on,
                   ipu_aggregate_limits,
                   ipu_rc_sht_desc,
                   ipu_rc_code,
                   ipu_survey_date,
                   ipu_item_details,
                   ipu_override_ri_retention,
                   ipu_conveyance_type,
                   ipu_prorata_sect_prem,
                   ipu_nonprorata_sect_prem,
                   ipu_prev_prorata_sect_prem,
                   ipu_prev_nonprorata_sect_prem,
                   ipu_tot_prorata_sect_prem,
                   ipu_tot_nonprorata_sect_prem,
                   ipu_prev_tot_prorata_s_prem,
                   ipu_prev_tot_nonprorata_s_prem,
                   ipu_status,
                   ipu_cover_suspended,
                   ipu_suspend_wef,
                   ipu_suspend_wet,
                   ipu_install_period,
                   ipu_pymt_install_pcts,
                   ipu_rs_code,
                   ipu_rescue_mem,
                   ipu_rescue_charge,
                   ipu_instal_prem,
                   ipu_health_tax,
                   ipu_road_safety_tax,
                   ipu_certchg,
                   ipu_motor_levy,
                   ipu_client_vat_amt,
                   ipu_cashback_appl,
                   ipu_cashback_level,
                   ipu_vehicle_model,
                   ipu_vehicle_make,
                   ipu_vehicle_model_code,
                   ipu_vehicle_make_code,
                   ipu_loc_town,
                   ipu_prop_address,
                   ipu_risk_note,
                   ipu_other_com_charges,
                   ipu_model_yr,
                   ipu_cert_no,
                   NVL (ipu_insured_driver, 'Y')     ipu_insured_driver,
                   ipu_maintenance_period_type,
                   ipu_maintenance_period,
                   ipu_other_client_deductibles,
                   ipu_coin_other_client_charges,
                   ipu_survey_agnt_code,
                   ipu_survey,
                   ipu_marine_type
              FROM gin_insured_property_unds
             WHERE ipu_code = v_old_ipu_code;

        --AND session_id = v_session_id
        --AND prp_code = v_prp;
        CURSOR cur_limits (v_ipu VARCHAR2)
        IS
              SELECT *
                FROM gin_policy_insured_limits
               WHERE pil_ipu_code = v_ipu
            ORDER BY pil_code, pil_calc_group, pil_row_num;

        CURSOR security_docs (vipu_code NUMBER)
        IS
            SELECT *
              FROM gin_risk_security_documents
             WHERE rsd_ipu_code = vipu_code;

        CURSOR cur_clauses (v_ipu VARCHAR2)
        IS
            SELECT *
              FROM gin_policy_clauses
             WHERE pocl_ipu_code = v_ipu;

        CURSOR cur_rsk_perils (v_ipu VARCHAR2)
        IS
            SELECT *
              FROM gin_pol_risk_section_perils
             WHERE prspr_ipu_code = v_ipu;

        CURSOR cur_perils (v_ipu IN NUMBER)
        IS
            SELECT *
              FROM gin_pol_sec_perils
             WHERE gpsp_ipu_code = v_ipu;

        CURSOR cur_endors_pol IS
            SELECT *
              FROM gin_policies
             WHERE pol_batch_no = v_old_batch_no;

        CURSOR risk_services (v_ipu NUMBER)
        IS
            SELECT *
              FROM gin_policy_risk_services
             WHERE prs_ipu_code = v_ipu;

        --v_new_ipu_code NUMBER;
        v_cnt                      NUMBER := 0;
        v_ipu_status               VARCHAR2 (2);
        v_ipu_wet                  DATE;
        v_risk_uw_yr               NUMBER;
        v_ipu_eff_wef              DATE;
        v_ipu_wef                  DATE;
        v_ipu_prev_prem            NUMBER;
        v_dup_rec                  EXCEPTION;
        v_ipu_prev_ri_amt          NUMBER;
        v_pil_prem_amt             NUMBER;
        v_pil_prev_limit           NUMBER;
        v_compute                  VARCHAR2 (2);
        v_pil_code                 NUMBER;
        v_new_pol_no               VARCHAR2 (30);
        v_new_endr_no              VARCHAR2 (30);
        v_pol_wet                  DATE;
        v_pol_wef                  DATE;
        -- v_trans_eff_date DATE;
        v_polin_code               NUMBER;
        vipuwef                    DATE;
        vipueffwef                 DATE;
        vipuwet                    DATE;
        vipueffwet                 DATE;
        vprevipucode               NUMBER;
        vprevprem                  NUMBER;
        vipupaidprem               NUMBER;
        vipupaidtl                 NUMBER;
        viputranstype              VARCHAR2 (10);
        v_pol_uw_year              NUMBER;
        v_suspend                  VARCHAR2 (1) := 'N';
        v_suspend_wef              DATE;
        v_suspend_wet              DATE;
        v_pol_cover_from           DATE;
        v_pol_cover_to             DATE;
        v_pol_tot_instlmt          NUMBER;
        v_install_period           NUMBER;
        v_cvt_install_type         gin_subclass_cover_types.sclcovt_install_type%TYPE;
        v_cvt_max_installs         gin_subclass_cover_types.sclcovt_max_installs%TYPE;
        v_cvt_pymt_install_pcts    gin_subclass_cover_types.sclcovt_pymt_install_pcts%TYPE;
        v_cvt_install_periods      gin_subclass_cover_types.sclcovt_install_periods%TYPE;
        v_install_pct              NUMBER;
        v_suspend_days             NUMBER;
        v_rsks_count               NUMBER;
        v_pymnt_tot_instlmt        NUMBER;
        v_pro_expiry_period        VARCHAR2 (3);
        v_risk_pymt_install_pcts   VARCHAR2 (35);
        v_cover_days               NUMBER;
        v_max_susp_period          NUMBER;
        v_new_pol_wet              DATE;
        v_pol_instal_wet           DATE;
        v_downgrade_on_sus_param   VARCHAR2 (1) := 'N';
        -- v_covt_code                NUMBER;
        --v_covt_sht_desc            VARCHAR2 (10);
        v_covt_downgrade           VARCHAR2 (1) := 'N';
        v_covt_downgrade_to        VARCHAR2 (10);
        v_id_reg_no                VARCHAR2 (30);
        v_clnt_pin_no              VARCHAR2 (30);
        v_clnt_passport_no         VARCHAR2 (50);
        v_agent_code               NUMBER;
        v_agn_regulator_number     VARCHAR2 (50);
        v_maturity_date            DATE;
        v_agt                      NUMBER;
        v_sht_desc                 VARCHAR2 (50);
        v_cnt1                     NUMBER;
        v_count                    NUMBER;
        v_no_inst                  NUMBER;
        v_instal_prem              NUMBER;
        v_fp_prem                  NUMBER;
        v_excpt_count              NUMBER;
        act_type                   NUMBER;
        v_factor                   NUMBER;
        v_scl_code                 NUMBER;
        v_covt_code                NUMBER;
        v_covt_sht_desc            VARCHAR2 (25);
        v_bind_code                NUMBER;
        v_prev_status              VARCHAR2 (5);
        ipu_prev_status            VARCHAR2 (5);
        v_pol_status               VARCHAR2 (5);
        v_cert_autogen             VARCHAR2 (1);
        v_certificate_period       VARCHAR2 (1);
        v_pol_pymt_install_pcts    VARCHAR2 (50);
        v_tot_pct                  NUMBER;
        v_months                   NUMBER;
        v_ex_valuation_param       VARCHAR2 (1);
        v_valuationcount           NUMBER;
        V_ISMOTORPRODUCT           VARCHAR2 (1);
    BEGIN
        --       RAISE_ERROR('v_action_type '||v_action_type||' v_old_batch_no '|| v_old_batch_no||' v_old_ipu_code '||v_old_ipu_code );
        v_ipu_status := 'EN';

        IF v_trans_type IN ('CN', 'CO')
        THEN
            RETURN;
        END IF;

        IF v_new_batch_no IS NULL
        THEN
            raise_error ('Error... Batch number is null...');
        END IF;

        IF v_old_ipu_code IS NULL
        THEN
            raise_error ('Error. No risk to endorse...');
        END IF;

        BEGIN
            SELECT pol_policy_no,
                   pol_ren_endos_no,
                   pol_wef_dt,
                   pol_wet_dt,
                   pol_uw_year,
                   pol_policy_cover_from,
                   pol_policy_cover_to,
                   pol_tot_instlmt,
                   pro_expiry_period,
                   pol_paid_to_date,
                   pro_cert_period,
                   pol_pymt_install_pcts
              INTO v_new_pol_no,
                   v_new_endr_no,
                   v_pol_wef,
                   v_pol_wet,
                   v_pol_uw_year,
                   v_pol_cover_from,
                   v_pol_cover_to,
                   v_pol_tot_instlmt,
                   v_pro_expiry_period,
                   v_pol_instal_wet,
                   v_certificate_period,
                   v_pol_pymt_install_pcts
              FROM gin_policies, gin_products
             WHERE pol_batch_no = v_new_batch_no AND pol_pro_code = pro_code;
        EXCEPTION
            WHEN OTHERS
            THEN
                raise_error ('Error fetching policy details...');
        END;