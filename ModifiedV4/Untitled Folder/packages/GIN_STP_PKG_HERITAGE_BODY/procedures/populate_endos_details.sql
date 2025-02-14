PROCEDURE populate_endos_details (
   v_pol_no             IN       VARCHAR2,
   v_old_pol_batch_no   IN       NUMBER,
   v_trans_type         IN       VARCHAR2,
   v_trans_eff_date     IN       DATE,
   v_extend_to_date     IN       DATE,
   v_rsks_tab           IN       risk_tab,
   v_agentcontact       IN       VARCHAR2,
   v_endrsd_rsks_tab    OUT      endrsd_rsks_tab,
   v_new_batch_no       OUT      NUMBER,
   v_end_no             OUT      VARCHAR2,
   v_past_period        IN       VARCHAR2,
   v_end_comm_allowed   IN       VARCHAR2,
   v_cancelled_by       IN       VARCHAR2,
   v_endors_status      IN       VARCHAR2,
   v_regional_endors    IN       VARCHAR2
)
IS
   --ncd_final_val   NUMBER(5) := 0;
   --v_prp_code    NUMBER ;
   cnt                     NUMBER        := 0;
   --cnt2 NUMBER :=0;
   v_ipu_wet               DATE;
   v_ipu_wef               DATE;
   v_ipu_eff_wef           DATE;
   v_dup_rec               EXCEPTION;
   v_user                  VARCHAR2 (35)
            := pkg_global_vars.get_pvarchar2 ('PKG_GLOBAL_VARS.PVG_USERNAME');
   v_new_ipu_code          NUMBER;
   v_risk_uw_yr            NUMBER (4);
   v_pil_prem_amt          NUMBER        := 0;
   v_compute               VARCHAR2 (1)  := 'Y';
   v_ipu_prev_prem         NUMBER        := 0;
   v_pil_prev_limit        NUMBER        := 0;
   v_pil_code              NUMBER (20);
   v_ipu_prev_ri_amt       NUMBER;
   v_session_id            NUMBER;
   v_new_pol_batch_no      NUMBER;
   v_pol_status            VARCHAR2 (5);
   v_pol_wef               DATE;
   v_pol_wet               DATE;
   v_pol_uw_yr             NUMBER;
   v_pol_cover_from        DATE;
   v_pol_cover_to          DATE;
   v_pol_uwyr_length       NUMBER;
   v_cancel_date           DATE;
   v_endors_min_prem       NUMBER;
   v_cnt                   NUMBER;
   v_pdl_code              NUMBER;
   v_cnt2                  NUMBER;
   v_pol_renewal_dt        DATE;
   vipuwef                 DATE;
   vipueffwef              DATE;
   vipuwet                 DATE;
   vipueffwet              DATE;
   vprevipucode            NUMBER;
   vprevprem               NUMBER;
   vipupaidprem            NUMBER;
   vipupaidtl              NUMBER;
   viputranstype           VARCHAR2 (10);
   v_endos_wht_prev_rein   VARCHAR2 (1)  := 'N';
   v_val_pol               VARCHAR2 (1);
   v_shortp_pol            VARCHAR2 (1);
   v_balance               NUMBER        := 0;
   v_sp_cnt                NUMBER;
   v_sp_cnt_param          NUMBER;
   v_ipu_covt_sht_desc     VARCHAR2 (10);
   v_count                 NUMBER;
   v_covt_code             NUMBER;
   v_allow_cert_bal        VARCHAR2 (1);
   v_sch_status            VARCHAR2 (1);
   v_prorata               VARCHAR2 (1);
   v_allow_ext_with_bal    VARCHAR2 (1)  := 'Y';
   v_policy_debit          VARCHAR2 (1);
   v_cur_reg_endors        VARCHAR2 (1)  := 'N';
   v_cert_autogen          VARCHAR2 (1);
   v_rs_cnt                NUMBER;
   v_com_allowed           VARCHAR2 (1);
   v_intro_status          VARCHAR2 (2);
   v_pro_change_uw_on_ex   VARCHAR2 (2);
   

--GIS-11824 To take care of normal endorsement done after regional endorsement is COMESA
   CURSOR cur_coinsurer (v_btch NUMBER)
   IS
      SELECT *
        FROM gin_coinsurers
       WHERE coin_pol_batch_no = v_btch;

   CURSOR cur_active_risks (v_polcy_no VARCHAR2, v_new_btch NUMBER)
   IS
      SELECT DISTINCT polar_ipu_code ipu_code,
                      polar_prev_batch_no ipu_prev_batch_no,
                      polar_ipu_id ipu_id, ipu_pol_policy_no, ipu_prp_code
                 FROM gin_policy_active_risks,
                      gin_insured_property_unds,
                      gin_policies
                WHERE polar_ipu_code = ipu_code
                  AND ipu_pol_batch_no = pol_batch_no
                  AND pol_current_status = 'A'
                  AND polar_pol_policy_no = v_polcy_no
                  --cur_endors_pol_rec.POL_POLICY_NO
                  AND ipu_id NOT IN (SELECT polar_ipu_id
                                       FROM gin_policy_active_risks
                                      WHERE polar_pol_batch_no = v_new_btch);

   CURSOR cur_conditions (v_btch NUMBER)
   IS
      SELECT *
        FROM gin_policy_lvl_clauses
       WHERE plcl_pol_batch_no = v_btch;

   CURSOR cur_schedule_values (v_btch NUMBER)
   IS
      SELECT *
        FROM gin_pol_schedule_values
       WHERE schpv_pol_batch_no = v_btch;

   CURSOR cur_taxes (v_btch_no NUMBER, vprocode IN NUMBER)
   IS
      SELECT ptx_trac_scl_code, ptx_trac_trnt_code, ptx_pol_policy_no,
             ptx_pol_ren_endos_no, ptx_pol_batch_no, ptx_rate, ptx_amount,
             ptx_tl_lvl_code, ptx_rate_type, ptx_rate_desc,
             ptx_endos_diff_amt, ptx_tax_type, ptx_risk_pol_level
        FROM gin_policy_taxes, gin_transaction_types
       WHERE ptx_trac_trnt_code = trnt_code
         AND ptx_pol_batch_no = v_btch_no
         AND NVL (DECODE (v_trans_type,
                          'NB', trnt_apply_nb,
                          'SP', trnt_apply_sp,
                          'RN', trnt_apply_rn,
                          'EN', trnt_apply_en,
                          'CN', trnt_apply_cn,
                          'EX', trnt_apply_ex,
                          'DC', trnt_apply_dc,
                          'RE', trnt_apply_re
                         ),
                  'N'
                 ) = 'Y'
         AND trnt_code NOT IN (SELECT petx_trnt_code
                                 FROM gin_product_excluded_taxes
                                WHERE petx_pro_code = vprocode);

   -- TRNT_RENEWAL_ENDOS != 'N';
   CURSOR cur_pol_perils (v_btch_no NUMBER)
   IS
      SELECT *
        FROM gin_policy_section_perils
       WHERE pspr_pol_batch_no = v_btch_no;

   CURSOR cur_facre_dtls (v_btch_no NUMBER)
   IS
      SELECT *
        FROM gin_facre_in_dtls
       WHERE fid_pol_batch_no = v_btch_no;

   CURSOR cur_insureds
   IS
      SELECT DISTINCT prp_code
                 FROM gin_temp_trans
                WHERE pol_batch_no = v_new_pol_batch_no;

   CURSOR cur_ipu (v_prp NUMBER)
   IS
      SELECT DISTINCT a.ipu_code, b.ipu_status, ipu_property_id,
                      ipu_item_desc, ipu_qty, ipu_value, ipu_wef, ipu_wet,
                      ipu_pol_policy_no, ipu_pol_ren_endos_no,
                      ipu_pol_batch_no, ipu_earth_quake_cover,
                      ipu_earth_quake_prem, ipu_location, ipu_polin_code,
                      ipu_sec_scl_code, ipu_ncd_status, ipu_related_ipu_code,
                      ipu_prorata, ipu_gp, ipu_fap, ipu_prev_ipu_code,
                      ipu_ncd_level, ipu_quz_code, ipu_quz_sht_desc,
                      ipu_sht_desc, ipu_id, ipu_bind_code, ipu_excess_rate,
                      ipu_excess_type, ipu_excess_rate_type, ipu_excess_min,
                      ipu_excess_max, ipu_prereq_ipu_code,
                      ipu_escalation_rate, ipu_comm_rate, ipu_prev_batch_no,
                      ipu_cur_code, ipu_relr_code, ipu_relr_sht_desc,
                      ipu_pol_est_max_loss, ipu_eff_wef, ipu_eff_wet,
                      ipu_retro_cover, ipu_retro_wef, ipu_covt_code,
                      ipu_covt_sht_desc, ipu_si_diff, ipu_terr_code,
                      ipu_terr_desc, ipu_from_time, ipu_to_time,
                      ipu_mar_cert_no, ipu_comp_retention, ipu_bp, ipu_fp,
                      ipu_gross_comp_retention, ipu_prev_prem,
                      ipu_com_retention_rate, ipu_prp_code,
                      ipu_tot_endos_prem_dif, ipu_tot_gp, ipu_tot_value,
                      ipu_ri_agnt_com_rate, ipu_cover_days,
                      ipu_ri_agnt_comm_amt, ipu_tot_fap, ipu_max_exposure,
                      ipu_uw_yr, ipu_tot_first_loss, ipu_accumulation_limit,
                      ipu_reinsure_amt, ipu_compute_max_exposure,
                      ipu_paid_premium, ipu_trans_count, ipu_paid_tl,
                      ipu_inception_uwyr, ipu_endos_remove, ipu_eml_based_on,
                      ipu_aggregate_limits, ipu_rc_sht_desc, ipu_rc_code,
                      ipu_survey_date, ipu_item_details,
                      ipu_override_ri_retention, ipu_action_type,
                      ipu_risk_oth_int_parties, ipu_conveyance_type,
                      ipu_prorata_sect_prem, ipu_nonprorata_sect_prem,
                      ipu_prev_prorata_sect_prem,
                      ipu_prev_nonprorata_sect_prem,
                      ipu_tot_prorata_sect_prem, ipu_tot_nonprorata_sect_prem,
                      ipu_prev_tot_prorata_s_prem,
                      ipu_prev_tot_nonprorata_s_prem, ipu_install_period,
                      ipu_rescue_charge, ipu_rescue_mem, ipu_rs_code,
                      ipu_motor_levy, ipu_health_tax, ipu_road_safety_tax,
                      ipu_certchg, ipu_cashback_appl, ipu_cashback_level,
                      ipu_vehicle_model_code, ipu_vehicle_make_code,
                      ipu_vehicle_model, ipu_vehicle_make, ipu_model_yr,a.ipu_cert_no,
					  ipu_logbook_available,
                      ipu_lb_under_insured_name,
                      ipu_log_book_no,ipu_loc_town,ipu_prop_address,ipu_joint,ipu_joint_prp_code
                 FROM gin_insured_property_unds a, gin_temp_trans b
                WHERE a.ipu_code = b.ipu_code
                  AND session_id = v_session_id
                  AND prp_code = v_prp;

   CURSOR cur_limits (v_ipu VARCHAR2)
   IS
      SELECT   *
          FROM gin_policy_insured_limits
         WHERE pil_ipu_code = v_ipu
      ORDER BY pil_code;

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

   CURSOR cur_endors_pol
   IS
      SELECT *
        FROM gin_policies
       WHERE pol_batch_no = v_old_pol_batch_no;

   CURSOR cur_all_active_risks
   IS
      SELECT ipu_pol_batch_no, ipu_code, ipu_prev_batch_no, ipu_id,
             ipu_pol_policy_no, ipu_prp_code ipu_prp_code
        FROM gin_insured_property_unds, gin_policy_active_risks
       WHERE ipu_code = polar_ipu_code
         AND polar_pol_batch_no = v_old_pol_batch_no
         AND ipu_code NOT IN (SELECT b.ipu_code
                                FROM gin_temp_trans b
                               WHERE b.session_id = v_session_id);

   CURSOR cur_fam_dtls (v_ipu IN NUMBER)
   IS
      SELECT *
        FROM gin_pol_med_cat_family_details
       WHERE pmcfd_ipu_code = v_ipu;

   CURSOR cur_fam_limit_dtls (v_ipu IN NUMBER)
   IS
      SELECT *
        FROM gin_pol_med_fam_insured_limits
       WHERE pmfil_ipu_code = v_ipu;

   CURSOR cur_sbu_dtls
   IS
      SELECT *
        FROM gin_policy_sbu_dtls
       WHERE pdl_pol_batch_no = v_old_pol_batch_no;

   CURSOR risk_services (v_ipu NUMBER)
   IS
      SELECT *
        FROM gin_policy_risk_services
       WHERE prs_ipu_code = v_ipu;  
  cursor  driver_details(v_ipu NUMBER)
     is select *
      from gin_clm_drv_dtls
      where  CDR_IPU_CODE= v_ipu
      and  CDR_MODULE='U';
BEGIN
   v_user := NVL (v_agentcontact, v_user);

--    raise_error ('v_trans_type='||v_trans_type||'= '||v_regional_endors);
   BEGIN
      SELECT gin_parameters_pkg.get_param_varchar ('ENDOS_WHT_PREV_REIN')
        INTO v_endos_wht_prev_rein
        FROM DUAL;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_endos_wht_prev_rein := 'N';
   END;