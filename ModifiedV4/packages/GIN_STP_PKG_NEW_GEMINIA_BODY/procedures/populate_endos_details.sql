PROCEDURE populate_endos_details (
        v_pol_no             IN     VARCHAR2,
        v_old_pol_batch_no   IN     NUMBER,
        v_trans_type         IN     VARCHAR2,
        v_trans_eff_date     IN     DATE,
        v_extend_to_date     IN     DATE,
        v_rsks_tab           IN     risk_tab,
        v_agentcontact       IN     VARCHAR2,
        v_endrsd_rsks_tab       OUT endrsd_rsks_tab,
        v_new_batch_no          OUT NUMBER,
        v_end_no                OUT VARCHAR2,
        v_past_period        IN     VARCHAR2,
        v_end_comm_allowed   IN     VARCHAR2,
        v_cancelled_by       IN     VARCHAR2,
        v_endors_status      IN     VARCHAR2,
        v_regional_endors    IN     VARCHAR2)
    IS
        --ncd_final_val   NUMBER(5) := 0;
        --v_prp_code    NUMBER ;
        cnt                      NUMBER := 0;
        --cnt2 NUMBER :=0;
        v_ipu_wet                DATE;
        v_ipu_wef                DATE;
        v_ipu_eff_wef            DATE;
        v_dup_rec                EXCEPTION;
        v_user                   VARCHAR2 (35)
            := pkg_global_vars.get_pvarchar2 ('PKG_GLOBAL_VARS.PVG_USERNAME');
        v_new_ipu_code           NUMBER;
        v_risk_uw_yr             NUMBER (4);
        v_pil_prem_amt           NUMBER := 0;
        v_compute                VARCHAR2 (1) := 'Y';
        v_ipu_prev_prem          NUMBER := 0;
        v_pil_prev_limit         NUMBER := 0;
        v_pil_code               NUMBER (20);
        v_ipu_prev_ri_amt        NUMBER;
        v_session_id             NUMBER;
        v_new_pol_batch_no       NUMBER;
        v_pol_status             VARCHAR2 (5);
        v_pol_wef                DATE;
        v_pol_wet                DATE;
        v_pol_uw_yr              NUMBER;
        v_pol_cover_from         DATE;
        v_pol_cover_to           DATE;
        v_pol_uwyr_length        NUMBER;
        v_cancel_date            DATE;
        v_endors_min_prem        NUMBER;
        v_cnt                    NUMBER;
        v_pdl_code               NUMBER;
        v_cnt2                   NUMBER;
        v_pol_renewal_dt         DATE;
        vipuwef                  DATE;
        vipueffwef               DATE;
        vipuwet                  DATE;
        vipueffwet               DATE;
        vprevipucode             NUMBER;
        vprevprem                NUMBER;
        vipupaidprem             NUMBER;
        vipupaidtl               NUMBER;
        viputranstype            VARCHAR2 (10);
        v_endos_wht_prev_rein    VARCHAR2 (1) := 'N';
        v_val_pol                VARCHAR2 (1);
        v_shortp_pol             VARCHAR2 (1);
        v_balance                NUMBER := 0;
        v_sp_cnt                 NUMBER;
        v_sp_cnt_param           NUMBER;
        v_ipu_covt_sht_desc      VARCHAR2 (100);
        v_count                  NUMBER;
        v_covt_code              NUMBER;
        v_allow_cert_bal         VARCHAR2 (1);
        v_sch_status             VARCHAR2 (1);
        v_prorata                VARCHAR2 (1);
        v_allow_ext_with_bal     VARCHAR2 (1) := 'Y';
        v_policy_debit           VARCHAR2 (1);
        v_cur_reg_endors         VARCHAR2 (1) := 'N';
        v_cert_autogen           VARCHAR2 (1);
        v_rs_cnt                 NUMBER;
        v_com_allowed            VARCHAR2 (1);
        v_valuationcount         NUMBER;
        v_ex_valuation_param     VARCHAR2 (1);
        v_auto_populate_limits   VARCHAR2 (1);
        v_param_ext              VARCHAR2 (1) := 'N';

        --GIS-11824 To take care of normal endorsement done after regional endorsement is COMESA
        CURSOR cur_coinsurer (v_btch NUMBER)
        IS
            SELECT *
              FROM gin_coinsurers
             WHERE coin_pol_batch_no = v_btch;

        CURSOR cur_active_risks (v_polcy_no VARCHAR2, v_new_btch NUMBER)
        IS
            SELECT DISTINCT polar_ipu_code          ipu_code,
                            polar_prev_batch_no     ipu_prev_batch_no,
                            polar_ipu_id            ipu_id,
                            ipu_pol_policy_no,
                            ipu_prp_code
              FROM gin_policy_active_risks,
                   gin_insured_property_unds,
                   gin_policies
             WHERE     polar_ipu_code = ipu_code
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

        CURSOR cur_subclass_conditions (v_btch NUMBER)
        IS
            SELECT *
              FROM gin_policy_subclass_clauses
             WHERE poscl_pol_batch_no = v_btch;

        CURSOR cur_schedule_values (v_btch NUMBER)
        IS
            SELECT *
              FROM gin_pol_schedule_values
             WHERE schpv_pol_batch_no = v_btch;

        CURSOR cur_taxes (v_btch_no NUMBER, vprocode IN NUMBER)
        IS
            SELECT ptx_trac_scl_code,
                   ptx_trac_trnt_code,
                   ptx_pol_policy_no,
                   ptx_pol_ren_endos_no,
                   ptx_pol_batch_no,
                   ptx_rate,
                   ptx_amount,
                   ptx_tl_lvl_code,
                   ptx_rate_type,
                   ptx_rate_desc,
                   ptx_endos_diff_amt,
                   ptx_tax_type,
                   ptx_risk_pol_level,
                   ptx_override,
                   ptx_override_amt
              FROM gin_policy_taxes, gin_transaction_types
             WHERE     ptx_trac_trnt_code = trnt_code
                   AND ptx_pol_batch_no = v_btch_no
                   AND NVL (
                           DECODE (v_trans_type,
                                   'NB', trnt_apply_nb,
                                   'SP', trnt_apply_sp,
                                   'RN', trnt_apply_rn,
                                   'EN', trnt_apply_en,
                                   'CN', trnt_apply_cn,
                                   'EX', trnt_apply_ex,
                                   'DC', trnt_apply_dc,
                                   'RE', trnt_apply_re),
                           'N') =
                       'Y'
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

        CURSOR cur_insureds IS
            SELECT DISTINCT prp_code
              FROM gin_temp_trans
             WHERE pol_batch_no = v_new_pol_batch_no;

        CURSOR cur_ipu (v_prp NUMBER)
        IS
            SELECT DISTINCT a.ipu_code,
                            b.ipu_status,
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
                            ipu_action_type,
                            ipu_risk_oth_int_parties,
                            ipu_conveyance_type,
                            ipu_prorata_sect_prem,
                            ipu_nonprorata_sect_prem,
                            ipu_prev_prorata_sect_prem,
                            ipu_prev_nonprorata_sect_prem,
                            ipu_tot_prorata_sect_prem,
                            ipu_tot_nonprorata_sect_prem,
                            ipu_prev_tot_prorata_s_prem,
                            ipu_prev_tot_nonprorata_s_prem,
                            ipu_install_period,
                            ipu_rescue_charge,
                            ipu_rescue_mem,
                            ipu_rs_code,
                            ipu_motor_levy,
                            ipu_health_tax,
                            ipu_road_safety_tax,
                            ipu_certchg,
                            ipu_cashback_appl,
                            ipu_cashback_level,
                            ipu_vehicle_model_code,
                            ipu_vehicle_make_code,
                            ipu_vehicle_model,
                            ipu_vehicle_make,
                            ipu_model_yr,
                            a.ipu_cert_no,
                            ipu_maintenance_period_type,
                            ipu_maintenance_period,
                            ipu_other_client_deductibles,
                            ipu_coin_other_client_charges,
                            ipu_survey_agnt_code,
                            ipu_survey
              FROM gin_insured_property_unds a, gin_temp_trans b
             WHERE     a.ipu_code = b.ipu_code
                   AND session_id = v_session_id
                   AND prp_code = v_prp;

        CURSOR cur_limits (v_ipu VARCHAR2)
        IS
              SELECT *
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

        CURSOR cur_endors_pol IS
            SELECT *
              FROM gin_policies
             WHERE pol_batch_no = v_old_pol_batch_no;

        CURSOR cur_all_active_risks IS
            SELECT ipu_pol_batch_no,
                   ipu_code,
                   ipu_prev_batch_no,
                   ipu_id,
                   ipu_pol_policy_no,
                   ipu_prp_code     ipu_prp_code
              FROM gin_insured_property_unds, gin_policy_active_risks
             WHERE     ipu_code = polar_ipu_code
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

        CURSOR cur_sbu_dtls IS
            SELECT *
              FROM gin_policy_sbu_dtls
             WHERE pdl_pol_batch_no = v_old_pol_batch_no;

        CURSOR risk_services (v_ipu NUMBER)
        IS
            SELECT *
              FROM gin_policy_risk_services
             WHERE prs_ipu_code = v_ipu;

        CURSOR driver_details (v_ipu NUMBER)
        IS
            SELECT *
              FROM gin_clm_drv_dtls
             WHERE cdr_ipu_code = v_ipu AND cdr_module = 'U';
    BEGIN
        v_user := NVL (v_agentcontact, v_user);

        --    raise_error ('v_trans_type='||v_trans_type||'= '||v_regional_endors);
        BEGIN
            SELECT gin_parameters_pkg.get_param_varchar (
                       'ENDOS_WHT_PREV_REIN')
              INTO v_endos_wht_prev_rein
              FROM DUAL;
        EXCEPTION
            WHEN OTHERS
            THEN
                v_endos_wht_prev_rein := 'N';
        END;

        BEGIN
            SELECT gin_parameters_pkg.get_param_varchar (
                       'ALLOW_EXTENSION_WITH_BAL')
              INTO v_allow_ext_with_bal
              FROM DUAL;
        EXCEPTION
            WHEN OTHERS
            THEN
                v_allow_ext_with_bal := 'Y';
        END;

        BEGIN
            SELECT gin_parameters_pkg.get_param_varchar (
                       'ALLOW_CERTIFICATE_BALANCES')
              INTO v_allow_cert_bal
              FROM DUAL;
        EXCEPTION
            WHEN OTHERS
            THEN
                v_allow_cert_bal := 'Y';
        END;

        BEGIN
            SELECT gin_parameters_pkg.get_param_varchar (
                       'SHORT_PERIOD_NO_OF_ENDORS')
              INTO v_sp_cnt_param
              FROM DUAL;
        EXCEPTION
            WHEN OTHERS
            THEN
                v_sp_cnt_param := 0;
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

        BEGIN
            SELECT gin_parameters_pkg.get_param_varchar (
                       'EX_TO_PICK_CURRENT_UWYR')
              INTO v_param_ext
              FROM DUAL;
        EXCEPTION
            WHEN OTHERS
            THEN
                v_param_ext := 'N';
        END;

        FOR cur_endors_pol_rec IN cur_endors_pol
        LOOP
            ---CHECK THE AGENT STATUS IF INACTIVE OR ACTIVE
            checkagentstatus (cur_endors_pol_rec.pol_agnt_agent_code,
                              v_trans_type);

            IF     NVL (cur_endors_pol_rec.pol_reinsured, 'N') != 'Y'
               AND NVL (cur_endors_pol_rec.pol_loaded, 'N') = 'N'
               AND tqc_interfaces_pkg.get_org_type (37) = 'INS'
            THEN
                IF v_endos_wht_prev_rein = 'N'
                THEN
                    raise_error (
                        'Reinsurance for the previous transaction on this policy has not been performed/Authorised. Cannot continue..');
                ELSE
                    NULL;
                END IF;
            END IF;

            --RAISE_eRROR(v_trans_type||' = '||v_sp_cnt_param);
            IF NVL (v_trans_type, 'NB') = 'EX'
            THEN
                IF NVL (v_sp_cnt_param, 0) > 0
                THEN
                    v_shortp_pol :=
                        gis_web_pkg.validate_shortperiod_ext (
                            cur_endors_pol_rec.pol_batch_no,
                            v_sp_cnt_param);

                    IF v_shortp_pol = 'Y'
                    THEN
                        raise_error (
                               'This Policy has < '
                            || v_sp_cnt_param
                            || ' > Extension(s) which is the maximum number of extensions..');
                    END IF;
                END IF;

                -- RAISE_eRROR(' v_trans_type= '||v_trans_type||' = '||v_sp_cnt_param||' = '||v_allow_ext_with_bal);
                IF NVL (v_allow_ext_with_bal, 'N') != 'Y'
                THEN
                    v_balance :=
                        gis_accounts_utilities.getpaidprem (
                            cur_endors_pol_rec.pol_prev_batch_no,
                            cur_endors_pol_rec.pol_agnt_agent_code,
                            cur_endors_pol_rec.pol_prp_code,
                            'B');

                    IF v_balance != 0
                    THEN
                        raise_error (
                               'Previous transaction on Policy '
                            || cur_endors_pol_rec.pol_policy_no
                            || ' is not Fully Settled Cannot continue wiht extension');
                    END IF;

                    v_balance := 0;
                END IF;
            END IF;

            BEGIN
                SELECT COUNT (1)
                  INTO v_cnt
                  FROM gin_policies
                 WHERE     pol_policy_no = cur_endors_pol_rec.pol_policy_no
                       AND NVL (pol_current_status, 'D') = 'A';
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error ('Error checking policy duplicates..');
            END;

            IF NVL (v_cnt, 0) > 1
            THEN
                raise_error (
                       'The current policy has '
                    || v_cnt
                    || ' active endorsement. Only One active endorsement allowed.');
            END IF;

            BEGIN
                SELECT COUNT (1)
                  INTO v_cnt
                  FROM gin_policies
                 WHERE     pol_policy_no = cur_endors_pol_rec.pol_policy_no
                       AND pol_current_status = 'D';

                SELECT COUNT (1)
                  INTO v_cnt2
                  FROM gin_gis_transactions
                 WHERE     ggt_pol_policy_no =
                           cur_endors_pol_rec.pol_policy_no
                       AND ggt_uw_clm_tran = 'U'
                       AND NVL (ggt_trans_authorised, 'N') != 'Y';
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error (
                        'Error checking un authorised transaction on this policy..');
            END;

            IF v_trans_type IN ('EN')
            THEN
                IF     cur_endors_pol_rec.pol_binder_policy = 'Y'
                   AND NVL (cur_endors_pol_rec.pol_policy_debit, 'Y') = 'Y'
                THEN
                    v_policy_debit := 'N';
                END IF;
            END IF;

            --         IF NVL (v_cnt, 0) != 0 OR NVL (v_cnt2, 0) != 0
            --         THEN
            --            raise_error ('This Policy has Another Unfinished Transaction..4..');
            --         END IF;
            v_val_pol :=
                gis_web_pkg.validate_transaction (
                    cur_endors_pol_rec.pol_policy_no);

            --         IF v_val_pol = 'Y'
            --         THEN
            --            raise_error
            --               ('This Policy has Another Unfinished Transaction in the renewal working area....'
            --               );
            --         END IF;
            IF v_trans_type NOT IN ('CN', 'CO')
            THEN
                BEGIN
                    SELECT ggt_sch_status
                      INTO v_sch_status
                      FROM gin_gis_transactions
                     WHERE     ggt_pol_batch_no = v_old_pol_batch_no
                           AND ggt_uw_clm_tran = 'U';
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error (
                            'Error getting schedule status for policy....');
                END;

                IF NVL (v_sch_status, 'O') != 'A'
                THEN
                    raise_error (
                        'Authorise schedule for previous endorsement to continue....');
                END IF;
            END IF;

            IF v_trans_type = 'RN'
            THEN
                v_pol_status := 'RN';
                v_pol_wef := v_trans_eff_date;
                v_pol_wet := ADD_MONTHS (cur_endors_pol_rec.pol_wef_dt, 12);
                v_pol_uw_yr := TO_NUMBER (TO_CHAR (v_pol_wef, 'RRRR'));
                v_pol_cover_from := v_pol_wef;
                v_pol_cover_to := v_pol_wet;
                v_pol_uwyr_length :=
                    CEIL (MONTHS_BETWEEN (v_pol_cover_to, v_pol_cover_from));
            ELSIF v_trans_type = 'EN'
            THEN
                v_pol_status := 'EN';
                v_pol_wef :=
                    NVL (v_trans_eff_date,
                         cur_endors_pol_rec.pol_policy_cover_from);
                v_pol_wet := cur_endors_pol_rec.pol_wet_dt;
                v_pol_uw_yr := cur_endors_pol_rec.pol_uw_year;
                v_pol_cover_from := cur_endors_pol_rec.pol_policy_cover_from;
                v_pol_cover_to := cur_endors_pol_rec.pol_policy_cover_to;
                v_pol_uwyr_length := cur_endors_pol_rec.pol_uwyr_length;
            ELSIF v_trans_type = 'EX'
            THEN
                v_pol_status := 'EX';
                v_pol_wef := v_trans_eff_date;
                v_pol_wet := v_extend_to_date;

                IF NVL (v_param_ext, 'N') = 'Y'
                THEN
                    v_pol_uw_yr := TO_NUMBER (TO_CHAR (v_pol_wef, 'RRRR'));
                ELSE
                    v_pol_uw_yr := cur_endors_pol_rec.pol_uw_year;
                END IF;

                v_pol_cover_from := v_pol_wef;
                v_pol_cover_to := v_pol_wet;
                v_pol_uwyr_length :=
                    CEIL (MONTHS_BETWEEN (v_pol_cover_to, v_pol_cover_from));
            ELSIF v_trans_type = 'RE'
            THEN
                v_pol_status := 'RE';
                v_pol_wef := cur_endors_pol_rec.pol_policy_cover_to;
                v_pol_wet :=
                    get_wet_date (cur_endors_pol_rec.pol_pro_code,
                                  cur_endors_pol_rec.pol_wef_dt);
                v_pol_uw_yr :=
                    TO_NUMBER (
                        TO_CHAR (cur_endors_pol_rec.pol_policy_cover_from,
                                 'RRRR'));
                v_pol_cover_from := v_pol_wef;
                v_pol_cover_to := v_pol_wet;
                v_pol_uwyr_length :=
                    CEIL (MONTHS_BETWEEN (v_pol_cover_to, v_pol_cover_from));
            ELSIF v_trans_type = 'CN'
            THEN
                v_pol_status := 'CN';

                IF v_trans_eff_date NOT BETWEEN cur_endors_pol_rec.pol_policy_cover_from
                                            AND cur_endors_pol_rec.pol_policy_cover_to
                THEN
                    raise_error (
                        'The cancellation effective date must be between policy cover period..');
                END IF;

                v_pol_wef := v_trans_eff_date;
                v_pol_wet := v_trans_eff_date;
                v_pol_uw_yr := cur_endors_pol_rec.pol_uw_year;
                v_pol_cover_from := cur_endors_pol_rec.pol_policy_cover_from;
                v_pol_cover_to := v_trans_eff_date;
                v_pol_uwyr_length := cur_endors_pol_rec.pol_uwyr_length;
                v_cancel_date := TRUNC (SYSDATE);

                IF v_pol_wef > v_pol_cover_to
                THEN
                    raise_error (
                        'The cancellation effective from date cannot be greater that the policy cover to date...');
                END IF;

                IF v_pol_wet > v_pol_cover_to
                THEN
                    raise_error (
                        'The cancellation effective to date cannot be greater that the policy cover to date...');
                END IF;
            ELSIF v_trans_type = 'DC'
            THEN
                v_pol_status := 'DC';
                v_pol_wef := cur_endors_pol_rec.pol_policy_cover_from;
                v_pol_wet := cur_endors_pol_rec.pol_wet_dt;
                v_pol_uw_yr := cur_endors_pol_rec.pol_uw_year;
                v_pol_cover_from := cur_endors_pol_rec.pol_policy_cover_from;
                v_pol_cover_to := cur_endors_pol_rec.pol_policy_cover_to;
                v_pol_uwyr_length := cur_endors_pol_rec.pol_uwyr_length;
                v_cancel_date := NULL;
            ELSIF v_trans_type IN ('NB', 'SP')
            THEN
                raise_error (
                       'Transaction type '
                    || v_trans_type
                    || ' not catered for..');
            END IF;

            v_pol_renewal_dt :=
                get_renewal_date (cur_endors_pol_rec.pol_pro_code, v_pol_wet);

            IF v_trans_type = 'RN'
            THEN
                IF v_pol_wef < cur_endors_pol_rec.pol_policy_cover_to
                THEN
                    raise_error (
                        'The Policy Renewal Cover From Date Cannot Be Less Than The Previous Policy Cover To Date...');
                END IF;
            ELSIF v_trans_type IN ('EN', 'SP', 'DC')
            THEN
                IF v_pol_wef NOT BETWEEN v_pol_cover_from AND v_pol_cover_to
                THEN
                    raise_error (
                           'The Policy endorsement cover from date '
                        || v_pol_wef
                        || ' must be between the policies cover from  '
                        || v_pol_cover_from
                        || ' and cover to dates  '
                        || v_pol_cover_to
                        || '...'
                        || v_old_pol_batch_no
                        || '');
                ELSIF v_pol_wet NOT BETWEEN v_pol_cover_from
                                        AND v_pol_cover_to
                THEN
                    raise_error (
                           'The Policy endorsement cover to date  '
                        || v_pol_wet
                        || ' must be between the policies cover from  '
                        || v_pol_cover_from
                        || ' and cover to dates  '
                        || v_pol_cover_to
                        || '...');
                END IF;
            ELSIF v_trans_type = 'EX'
            THEN
                IF v_pol_wef < cur_endors_pol_rec.pol_policy_cover_to
                THEN
                    raise_error (
                           'The Policy extension cover from date '
                        || v_pol_wef
                        || ' must be greater or equal to the previous policies cover to dates.'
                        || cur_endors_pol_rec.pol_policy_cover_to
                        || '..');
                ELSIF v_pol_wet <= v_pol_wef
                THEN
                    raise_error (
                           'The Policy extension cover to date '
                        || v_pol_wet
                        || ' must be greater than the policies cover from dates '
                        || v_pol_wef
                        || '...');
                END IF;
            END IF;

            BEGIN
                SELECT NVL (pro_endos_min_prem, 0)
                  INTO v_endors_min_prem --:GIN_POLICIES_RENEWAL.POL_END_MIN_PREM
                  FROM gin_products
                 WHERE pro_code = cur_endors_pol_rec.pol_pro_code;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    v_endors_min_prem := 0;
                WHEN OTHERS
                THEN
                    raise_error (
                        'Error :- Unable to retrieve the policy endorsement minimum premium...');
            END;

            IF cur_endors_pol_rec.pol_policy_type = 'N'
            THEN
                -- RAISE_ERROR('IN');
                v_end_no :=
                    gin_sequences_pkg.get_number_format (
                        'E',
                        cur_endors_pol_rec.pol_pro_code,
                        cur_endors_pol_rec.pol_brn_code,
                        TO_NUMBER (TO_CHAR (SYSDATE, 'RRRR')),
                        v_trans_type,
                        NULL,
                        'N',
                        cur_endors_pol_rec.pol_policy_no);
            ELSE
                v_end_no :=
                    gin_sequences_pkg.get_number_format (
                        'ER',
                        cur_endors_pol_rec.pol_pro_code,
                        cur_endors_pol_rec.pol_brn_code,
                        TO_NUMBER (TO_CHAR (SYSDATE, 'RRRR')),
                        v_trans_type,
                        NULL,
                        'N',
                        cur_endors_pol_rec.pol_policy_no);
            END IF;

            IF NVL (v_regional_endors, 'N') = 'Y'
            THEN
                v_com_allowed := 'N';
            ELSE
                v_com_allowed := 'Y';
            END IF;

            SELECT    TO_NUMBER (TO_CHAR (SYSDATE, 'RRRR'))
                   || gin_pol_batch_no_seq.NEXTVAL
              INTO v_new_pol_batch_no
              FROM DUAL;

            v_new_batch_no := v_new_pol_batch_no;

            BEGIN
                SELECT COUNT (1)
                  INTO v_cnt
                  FROM gin_policies
                 WHERE     pol_policy_no = cur_endors_pol_rec.pol_policy_no
                       AND pol_ren_endos_no = v_end_no;
            EXCEPTION
                WHEN OTHERS
                THEN
                    NULL;
            END;

            IF NVL (v_cnt, 0) > 0
            THEN
                v_end_no := v_end_no || '-' || v_cnt;
            END IF;

            --raise_error(v_end_comm_allowed||'='||v_regional_endors);
            BEGIN
                INSERT INTO gin_policies (pol_policy_no,
                                          pol_client_policy_number,
                                          pol_ren_endos_no,
                                          pol_batch_no,
                                          pol_coin_fee,
                                          pol_renewable,
                                          pol_prev_batch_no,
                                          pol_authosrised,
                                          pol_current_status,
                                          pol_post_status,
                                          pol_renewal_dt,
                                          pol_comm_rate,
                                          pol_pro_code,
                                          pol_pro_sht_desc,
                                          pol_policy_type,
                                          pol_binder_policy,
                                          pol_bind_pro_code,
                                          pol_bind_pro_sht_desc,
                                          pol_coinsurance_share,
                                          pol_quot_no,
                                          pol_comm_amt,
                                          pol_cur_code,
                                          pol_cur_symbol,
                                          pol_agnt_agent_code,
                                          pol_bind_code,
                                          pol_pmod_code,
                                          pol_agnt_sht_desc,
                                          pol_brn_code,
                                          pol_brn_sht_desc,
                                          pol_prp_code,
                                          pol_total_sum_insured,
                                          pol_basic_premium,
                                          pol_nett_premium,
                                          pol_comm_endos_diff_amt,
                                          pol_total_fap,
                                          pol_total_gp,
                                          pol_tot_endos_diff_amt,
                                          pol_coinsurance,
                                          pol_coinsure_leader,
                                          pol_coinsure_pct,
                                          pol_inception_dt,
                                          pol_ri_agnt_agent_code,
                                          pol_ri_agnt_sht_desc,
                                          pol_ri_agent_comm_rate,
                                          pol_coin_tot_prem,
                                          pol_coin_endos_prem,
                                          pol_coin_tot_si,
                                          pol_prepared_by,
                                          pol_prepared_date,
                                          pol_pip_code,
                                          pol_oth_int_parties,
                                          pol_policy_status,
                                          pol_wef_dt,
                                          pol_wet_dt,
                                          pol_uw_year,
                                          pol_policy_cover_to,
                                          pol_policy_cover_from,
                                          pol_uwyr_length,
                                          pol_trans_eff_wet,
                                          pol_old_policy_no,
                                          pol_commission_allowed,
                                          pol_inception_uwyr,
                                          pol_aga_code,
                                          pol_clna_code,
                                          pol_sub_aga_code,
                                          pol_admin_fee_disc_rate,
                                          pol_admin_fee_disc_amt,
                                          pol_coin_leader_combined,
                                          pol_coin_fee_trans,
                                          pol_lta_comm_disc_amt,
                                          pol_med_policy_type,
                                          pol_paid_up_date,
                                          pol_os_prem_bal_amt,
                                          pol_maturity_date,
                                          pol_paid_instlmt_no,
                                          pol_freq_of_payment,
                                          pol_instlmt_amt,
                                          pol_os_instlmt_no,
                                          pol_instlmt_prem,
                                          pol_paid_to_date,
                                          pol_tot_instlmt,
                                          pol_last_prem_due_date,
                                          pol_instlmt_day,
                                          pol_policy_doc,
                                          pol_past_period_endos,
                                          pol_endorse_comm_allowed,
                                          pol_coin_gross,
                                          pol_uw_period,
                                          pol_cancelled_by,
                                          pol_open_cover,
                                          pol_policy_debit,
                                          pol_scheme_policy,
                                          pol_pro_interface_type,
                                          pol_joint_prp_code,
                                          pol_joint,
                                          pol_intro_code,
                                          pol_force_sf_compute,
                                          pol_enforce_sf_param,
                                          pol_open_policy,
                                          pol_old_agent,
                                          pol_pymt_faci_agnt_code,
                                          pol_old_policy_number,
                                          pol_div_code,
                                          pol_bdiv_code,
                                          pol_regional_endors,
                                          pol_endors_status,
                                          pol_cr_date_notified,
                                          pol_cr_note_number,
                                          pol_pop_taxes,
                                          pol_admin_fee_allowed,
                                          pol_cashback_appl,
                                          pol_uw_only,
                                          pol_debiting_type,
                                          pol_debt_owner,
                                          pol_credit_limit,
                                          pol_promise_date,
                                          pol_src_direct_business)
                         VALUES (
                                    cur_endors_pol_rec.pol_policy_no,
                                    cur_endors_pol_rec.pol_client_policy_number,
                                    v_end_no,
                                    v_new_pol_batch_no,
                                    cur_endors_pol_rec.pol_coin_fee,
                                    cur_endors_pol_rec.pol_renewable,
                                    v_old_pol_batch_no,
                                    'N',
                                    'D',
                                    'N',
                                    v_pol_renewal_dt,
                                    0,
                                    cur_endors_pol_rec.pol_pro_code,
                                    cur_endors_pol_rec.pol_pro_sht_desc,
                                    cur_endors_pol_rec.pol_policy_type,
                                    cur_endors_pol_rec.pol_binder_policy,
                                    cur_endors_pol_rec.pol_bind_pro_code,
                                    cur_endors_pol_rec.pol_bind_pro_sht_desc,
                                    cur_endors_pol_rec.pol_coinsurance_share,
                                    cur_endors_pol_rec.pol_quot_no,
                                    0,
                                    cur_endors_pol_rec.pol_cur_code,
                                    cur_endors_pol_rec.pol_cur_symbol,
                                    cur_endors_pol_rec.pol_agnt_agent_code,
                                    cur_endors_pol_rec.pol_bind_code,
                                    cur_endors_pol_rec.pol_pmod_code,
                                    cur_endors_pol_rec.pol_agnt_sht_desc,
                                    cur_endors_pol_rec.pol_brn_code,
                                    cur_endors_pol_rec.pol_brn_sht_desc,
                                    cur_endors_pol_rec.pol_prp_code,
                                    cur_endors_pol_rec.pol_total_sum_insured,
                                    cur_endors_pol_rec.pol_basic_premium,
                                    cur_endors_pol_rec.pol_nett_premium,
                                    cur_endors_pol_rec.pol_comm_endos_diff_amt,
                                    cur_endors_pol_rec.pol_total_fap,
                                    cur_endors_pol_rec.pol_total_gp,
                                    cur_endors_pol_rec.pol_tot_endos_diff_amt,
                                    cur_endors_pol_rec.pol_coinsurance,
                                    cur_endors_pol_rec.pol_coinsure_leader,
                                    cur_endors_pol_rec.pol_coinsure_pct,
                                    cur_endors_pol_rec.pol_inception_dt,
                                    cur_endors_pol_rec.pol_ri_agnt_agent_code,
                                    cur_endors_pol_rec.pol_ri_agnt_sht_desc,
                                    cur_endors_pol_rec.pol_ri_agent_comm_rate,
                                    cur_endors_pol_rec.pol_coin_tot_prem,
                                    cur_endors_pol_rec.pol_coin_endos_prem,
                                    cur_endors_pol_rec.pol_coin_tot_si,
                                    v_user,
                                    TRUNC (SYSDATE),
                                    cur_endors_pol_rec.pol_pip_code,
                                    cur_endors_pol_rec.pol_oth_int_parties,
                                    v_pol_status,
                                    v_pol_wef,
                                    v_pol_wet,
                                    v_pol_uw_yr,
                                    v_pol_cover_to,
                                    v_pol_cover_from,
                                    v_pol_uwyr_length,
                                    v_pol_wet,
                                    cur_endors_pol_rec.pol_old_policy_no,
                                    DECODE (
                                        v_end_comm_allowed,
                                        'Y', 'N',
                                        --GIS-11824 To take care of normal endorsement done after regional endorsement is COMESA
                                        NVL (
                                            v_com_allowed,
                                            cur_endors_pol_rec.pol_commission_allowed)),
                                    cur_endors_pol_rec.pol_inception_uwyr,
                                    cur_endors_pol_rec.pol_aga_code,
                                    cur_endors_pol_rec.pol_clna_code,
                                    cur_endors_pol_rec.pol_sub_aga_code,
                                    cur_endors_pol_rec.pol_admin_fee_disc_rate,
                                    cur_endors_pol_rec.pol_admin_fee_disc_amt,
                                    cur_endors_pol_rec.pol_coin_leader_combined,
                                    cur_endors_pol_rec.pol_coin_fee_trans,
                                    cur_endors_pol_rec.pol_lta_comm_disc_amt,
                                    cur_endors_pol_rec.pol_med_policy_type,
                                    cur_endors_pol_rec.pol_paid_up_date,
                                    cur_endors_pol_rec.pol_os_prem_bal_amt,
                                    cur_endors_pol_rec.pol_maturity_date,
                                    cur_endors_pol_rec.pol_paid_instlmt_no,
                                    cur_endors_pol_rec.pol_freq_of_payment,
                                    cur_endors_pol_rec.pol_instlmt_amt,
                                    cur_endors_pol_rec.pol_os_instlmt_no,
                                    cur_endors_pol_rec.pol_instlmt_prem,
                                    cur_endors_pol_rec.pol_paid_to_date,
                                    cur_endors_pol_rec.pol_tot_instlmt,
                                    cur_endors_pol_rec.pol_last_prem_due_date,
                                    cur_endors_pol_rec.pol_instlmt_day,
                                    cur_endors_pol_rec.pol_policy_doc,
                                    NVL (v_past_period, 'N'),
                                    DECODE (v_end_comm_allowed,
                                            'Y', 'N',
                                            'Y'),
                                    cur_endors_pol_rec.pol_coin_gross,
                                    cur_endors_pol_rec.pol_uw_period,
                                    v_cancelled_by,
                                    cur_endors_pol_rec.pol_open_cover,
                                    NVL (v_policy_debit,
                                         cur_endors_pol_rec.pol_policy_debit),
                                    cur_endors_pol_rec.pol_scheme_policy,
                                    cur_endors_pol_rec.pol_pro_interface_type,
                                    cur_endors_pol_rec.pol_joint_prp_code,
                                    cur_endors_pol_rec.pol_joint,
                                    cur_endors_pol_rec.pol_intro_code,
                                    cur_endors_pol_rec.pol_force_sf_compute,
                                    cur_endors_pol_rec.pol_enforce_sf_param,
                                    cur_endors_pol_rec.pol_open_policy,
                                    cur_endors_pol_rec.pol_old_agent,
                                    cur_endors_pol_rec.pol_pymt_faci_agnt_code,
                                    cur_endors_pol_rec.pol_old_policy_number,
                                    cur_endors_pol_rec.pol_div_code,
                                    cur_endors_pol_rec.pol_bdiv_code,
                                    NVL (
                                        v_regional_endors,
                                        cur_endors_pol_rec.pol_regional_endors),
                                    v_endors_status,
                                    cur_endors_pol_rec.pol_cr_date_notified,
                                    cur_endors_pol_rec.pol_cr_note_number,
                                    cur_endors_pol_rec.pol_pop_taxes,
                                    cur_endors_pol_rec.pol_admin_fee_allowed,
                                    cur_endors_pol_rec.pol_cashback_appl,
                                    cur_endors_pol_rec.pol_uw_only,
                                    cur_endors_pol_rec.pol_debiting_type,
                                    cur_endors_pol_rec.pol_debt_owner,
                                    cur_endors_pol_rec.pol_credit_limit,
                                    cur_endors_pol_rec.pol_promise_date,
                                    cur_endors_pol_rec.pol_src_direct_business);
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error ('Error inserting policy record..');
            END;

            SELECT TO_NUMBER (
                          TO_CHAR (SYSDATE, 'RRRR')
                       || gin_session_id_seq.NEXTVAL)
              INTO v_session_id
              FROM DUAL;

            BEGIN
                DELETE gin_temp_trans
                 WHERE pol_batch_no = v_new_pol_batch_no;
            EXCEPTION
                WHEN v_dup_rec
                THEN
                    raise_error ('Unable to refresh transaction...');
            END;

            BEGIN
                UPDATE gin_policy_subclass_clauses
                   SET poscl_new = 'N'
                 WHERE poscl_pol_policy_no = v_pol_no;
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error ('Unable to update subclass clauses');
            END;

            FOR x IN 1 .. v_rsks_tab.COUNT
            LOOP
                BEGIN
                    INSERT INTO gin_temp_trans (session_id,
                                                ipu_code,
                                                polin_code,
                                                prp_code,
                                                pol_batch_no,
                                                ipu_status,
                                                ipu_action_type)
                         VALUES (v_session_id,
                                 v_rsks_tab (x).gis_ipu_code,
                                 v_rsks_tab (x).polin_code,
                                 v_rsks_tab (x).prp_code,
                                 v_new_pol_batch_no,
                                 v_rsks_tab (x).ipu_status,
                                 v_rsks_tab (x).ipu_action_type);
                EXCEPTION
                    WHEN v_dup_rec
                    THEN
                        raise_error (
                               'The Risk code '
                            || v_rsks_tab (x).gis_ipu_code
                            || ' does not have a defined insured...');
                END;
            END LOOP;

            /*-----------------------------------------------------------------------------
            COMMENTED OUT BY JIM 29April2010 to stop creation of Active Risks for endorsement at this Point.
            They will be created at Populate_endors_rsk_dtls s
            Subsequently uncommented by Kizito on 251010 for it was meant to be there in the first place.
            -------------------------------------------------------------------------------*/
            IF v_trans_type != 'RN'
            THEN
                FOR cur_all_active_risks_rec IN cur_all_active_risks
                LOOP
                    BEGIN
                        INSERT INTO gin_policy_active_risks (
                                        polar_pol_batch_no,
                                        polar_ipu_code,
                                        polar_prev_batch_no,
                                        polar_ipu_id,
                                        polar_pol_policy_no,
                                        polar_prp_code)
                                 VALUES (
                                            v_new_pol_batch_no,
                                            cur_all_active_risks_rec.ipu_code,
                                            cur_all_active_risks_rec.ipu_prev_batch_no,
                                            cur_all_active_risks_rec.ipu_id,
                                            cur_all_active_risks_rec.ipu_pol_policy_no,
                                            cur_all_active_risks_rec.ipu_prp_code);
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            raise_error (
                                'Unable to insert active risks details, ...');
                    END;
                END LOOP;
            END IF;

            --         Raise_error(' cur_endors_pol_rec.pol_binder_policy'|| cur_endors_pol_rec.pol_binder_policy||'v_old_pol_batch_no'||v_old_pol_batch_no);
            --                         BEGIN
            --                   IF cur_endors_pol_rec.pol_policy_no = '100504011000077'
            --                   THEN
            --                      raise_error (   'v_trans_type'
            --                                   || v_trans_type
            --                                   || 'cur_endors_pol_rec.pol_binder_policy'
            --                                   || cur_endors_pol_rec.pol_binder_policy
            --                                   ||'v_new_pol_batch_no'
            --                                   ||v_new_pol_batch_no
            --
            --                                  );
            --                   END IF;
            --                END;
            IF v_trans_type != 'RN'
            THEN
                IF cur_endors_pol_rec.pol_binder_policy = 'Y'
                THEN
                    FOR cur_all_active_risks_rec
                        IN cur_active_risks (
                               cur_endors_pol_rec.pol_policy_no,
                               v_old_pol_batch_no)
                    LOOP
                        BEGIN
                            SELECT COUNT (1)
                              INTO v_rs_cnt
                              FROM gin_policy_active_risks
                             WHERE     polar_pol_batch_no =
                                       v_new_pol_batch_no
                                   AND polar_ipu_id =
                                       cur_all_active_risks_rec.ipu_id;

                            IF NVL (v_rs_cnt, 0) < 1
                            THEN
                                INSERT INTO gin_policy_active_risks (
                                                polar_pol_batch_no,
                                                polar_ipu_code,
                                                polar_prev_batch_no,
                                                polar_ipu_id,
                                                polar_pol_policy_no,
                                                polar_prp_code)
                                         VALUES (
                                                    v_new_pol_batch_no,
                                                    cur_all_active_risks_rec.ipu_code,
                                                    cur_all_active_risks_rec.ipu_prev_batch_no,
                                                    cur_all_active_risks_rec.ipu_id,
                                                    cur_all_active_risks_rec.ipu_pol_policy_no,
                                                    cur_all_active_risks_rec.ipu_prp_code);
                            END IF;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                NULL;
                        --                  THEN
                        --                     raise_error
                        --                                ('Unable to insert active risks details, ...'||cur_all_active_risks_rec.ipu_id||';'||v_old_pol_batch_no);
                        END;
                    END LOOP;
                END IF;
            END IF;

            FOR cur_sbu_dtls_rec IN cur_sbu_dtls
            LOOP
                BEGIN
                    SELECT    TO_NUMBER (TO_CHAR (SYSDATE, 'YYYY'))
                           || gin_pdl_code_seq.NEXTVAL
                      INTO v_pdl_code
                      FROM DUAL;

                    INSERT INTO gin_policy_sbu_dtls (pdl_code,
                                                     pdl_pol_batch_no,
                                                     pdl_unit_code,
                                                     pdl_location_code,
                                                     pdl_prepared_date)
                         VALUES (v_pdl_code,
                                 v_new_pol_batch_no,
                                 cur_sbu_dtls_rec.pdl_unit_code,
                                 cur_sbu_dtls_rec.pdl_location_code,
                                 TRUNC (SYSDATE));
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        NULL;
                    WHEN OTHERS
                    THEN
                        raise_error (
                            'Error Creating Policy Other Details Record..');
                END;
            END LOOP;

            FOR cur_facre_dtls_rec IN cur_facre_dtls (v_old_pol_batch_no)
            LOOP
                INSERT INTO gin_facre_in_dtls (fid_pol_policy_no,
                                               fid_pol_ren_endos_no,
                                               fid_pol_batch_no,
                                               fid_agnt_agent_code,
                                               fid_agnt_sht_desc,
                                               fid_prp_code,
                                               fid_sum_insured,
                                               fid_gross_rate,
                                               fid_cede_comp_first_prem,
                                               fid_cede_comp_terms,
                                               fid_rein_terms,
                                               fid_cede_comp_gross_ret,
                                               fid_cede_comp_rein_amt,
                                               fid_amt_perc_sum_insured,
                                               fid_wef,
                                               fid_wet,
                                               fid_code,
                                               fid_cede_comp_policy_no,
                                               fid_cede_comp_term_frm,
                                               fid_cede_comp_term_to,
                                               fid_cede_company_ren_prem,
                                               fid_reins_term_to,
                                               fid_cede_sign_dt)
                         VALUES (
                                    cur_facre_dtls_rec.fid_pol_policy_no,
                                    v_end_no,
                                    v_new_pol_batch_no,
                                    cur_facre_dtls_rec.fid_agnt_agent_code,
                                    cur_facre_dtls_rec.fid_agnt_sht_desc,
                                    cur_facre_dtls_rec.fid_prp_code,
                                    cur_facre_dtls_rec.fid_sum_insured,
                                    cur_facre_dtls_rec.fid_gross_rate,
                                    cur_facre_dtls_rec.fid_cede_comp_first_prem,
                                    cur_facre_dtls_rec.fid_cede_comp_terms,
                                    cur_facre_dtls_rec.fid_rein_terms,
                                    cur_facre_dtls_rec.fid_cede_comp_gross_ret,
                                    cur_facre_dtls_rec.fid_cede_comp_rein_amt,
                                    cur_facre_dtls_rec.fid_amt_perc_sum_insured,
                                    cur_facre_dtls_rec.fid_wef,
                                    cur_facre_dtls_rec.fid_wet,
                                       TO_NUMBER (TO_CHAR (SYSDATE, 'RRRR'))
                                    || gin_fid_code_seq.NEXTVAL,
                                    cur_facre_dtls_rec.fid_cede_comp_policy_no,
                                    cur_facre_dtls_rec.fid_cede_comp_term_frm,
                                    cur_facre_dtls_rec.fid_cede_comp_term_to,
                                    cur_facre_dtls_rec.fid_cede_company_ren_prem,
                                    cur_facre_dtls_rec.fid_reins_term_to,
                                    cur_facre_dtls_rec.fid_cede_sign_dt);
            END LOOP;

            FOR cur_coinsurer_rec IN cur_coinsurer (v_old_pol_batch_no)
            LOOP
                --INSERT INTO GIN_REN_COINSURERS
                BEGIN
                    INSERT INTO gin_coinsurers (coin_agnt_agent_code,
                                                coin_agnt_sht_desc,
                                                coin_gl_code,
                                                coin_lead,
                                                coin_perct,
                                                coin_prem,
                                                coin_pol_policy_no,
                                                coin_pol_ren_endos_no,
                                                coin_pol_batch_no,
                                                coin_fee_rate,
                                                coin_fee_amt,
                                                coin_duties,
                                                coin_si,
                                                coin_optional_comm,
                                                coin_comm_rate,
                                                coin_comm_type)
                         VALUES (cur_coinsurer_rec.coin_agnt_agent_code,
                                 cur_coinsurer_rec.coin_agnt_sht_desc,
                                 cur_coinsurer_rec.coin_gl_code,
                                 cur_coinsurer_rec.coin_lead,
                                 cur_coinsurer_rec.coin_perct,
                                 cur_coinsurer_rec.coin_prem,
                                 cur_coinsurer_rec.coin_pol_policy_no,
                                 v_end_no,
                                 v_new_pol_batch_no,
                                 cur_coinsurer_rec.coin_fee_rate,
                                 0,
                                 cur_coinsurer_rec.coin_duties,
                                 cur_coinsurer_rec.coin_si,
                                 cur_coinsurer_rec.coin_optional_comm,
                                 cur_coinsurer_rec.coin_comm_rate,
                                 cur_coinsurer_rec.coin_comm_type);
                EXCEPTION
                    WHEN DUP_VAL_ON_INDEX
                    THEN
                        raise_error (
                               'System attempted to illegaly duplicate '
                            || cur_coinsurer_rec.coin_agnt_sht_desc
                            || ' coinsurer record. Please contact System Administrator for support...');
                    WHEN OTHERS
                    THEN
                        raise_error (
                            'Unable to insert coinsurance details, ...');
                END;
            END LOOP;

            FOR cur_conditions_rec IN cur_conditions (v_old_pol_batch_no)
            LOOP
                BEGIN
                    INSERT INTO gin_policy_lvl_clauses (
                                    plcl_sbcl_cls_code,
                                    plcl_sbcl_scl_code,
                                    plcl_pro_sht_desc,
                                    plcl_pro_code,
                                    plcl_pol_policy_no,
                                    plcl_pol_ren_endos_no,
                                    plcl_pol_batch_no,
                                    plcl_sbcl_cls_sht_desc,
                                    plcl_cls_type,
                                    plcl_clause,
                                    plcl_cls_editable,
                                    plcl_new,
                                    plcl_header,
                                    plcl_heading)
                         VALUES (cur_conditions_rec.plcl_sbcl_cls_code,
                                 cur_conditions_rec.plcl_sbcl_scl_code,
                                 cur_conditions_rec.plcl_pro_sht_desc,
                                 cur_conditions_rec.plcl_pro_code,
                                 cur_conditions_rec.plcl_pol_policy_no,
                                 v_end_no,
                                 v_new_pol_batch_no,
                                 cur_conditions_rec.plcl_sbcl_cls_sht_desc,
                                 cur_conditions_rec.plcl_cls_type,
                                 cur_conditions_rec.plcl_clause,
                                 cur_conditions_rec.plcl_cls_editable,
                                 'N',
                                 cur_conditions_rec.plcl_header,
                                 cur_conditions_rec.plcl_heading);
                EXCEPTION
                    WHEN DUP_VAL_ON_INDEX
                    THEN
                        raise_error (
                               'System attempted to illegaly duplicate '
                            || cur_conditions_rec.plcl_sbcl_cls_sht_desc
                            || ' clause record. Please contact Turnkey Africa for support...');
                    WHEN OTHERS
                    THEN
                        raise_error (
                            'Unable to insert policy level clauses details, ...');
                END;
            END LOOP;

            FOR cur_subclass_conditions_rec
                IN cur_subclass_conditions (v_old_pol_batch_no)
            LOOP
                BEGIN
                    INSERT INTO gin_policy_subclass_clauses (
                                    poscl_cls_code,
                                    poscl_sht_desc,
                                    poscl_heading,
                                    poscl_scl_code,
                                    poscl_pol_policy_no,
                                    poscl_cls_type,
                                    poscl_clause,
                                    poscl_cls_editable,
                                    poscl_new,
                                    poscl_pol_batch_no,
                                    poscl_code)
                             VALUES (
                                        cur_subclass_conditions_rec.poscl_cls_code,
                                        cur_subclass_conditions_rec.poscl_sht_desc,
                                        cur_subclass_conditions_rec.poscl_heading,
                                        cur_subclass_conditions_rec.poscl_scl_code,
                                        cur_subclass_conditions_rec.poscl_pol_policy_no,
                                        cur_subclass_conditions_rec.poscl_cls_type,
                                        cur_subclass_conditions_rec.poscl_clause,
                                        cur_subclass_conditions_rec.poscl_cls_editable,
                                        cur_subclass_conditions_rec.poscl_new,
                                        v_new_pol_batch_no,
                                           TO_NUMBER (
                                               TO_CHAR (SYSDATE, 'RRRR'))
                                        || gin_poscl_code_seq.NEXTVAL);
                EXCEPTION
                    WHEN DUP_VAL_ON_INDEX
                    THEN
                        raise_error (
                               'System attempted to illegaly duplicate '
                            || cur_subclass_conditions_rec.poscl_sht_desc
                            || ' clause record. Please contact Turnkey Africa for support...');
                    WHEN OTHERS
                    THEN
                        raise_error (
                            'Unable to insert policy level sub class clauses details, ...');
                END;
            END LOOP;

            FOR cur_schedule_values_rec
                IN cur_schedule_values (v_old_pol_batch_no)
            LOOP
                --RAISE_ERROR('v_old_pol_batch_no'||v_old_pol_batch_no);
                BEGIN
                    INSERT INTO gin_pol_schedule_values (schpv_code,
                                                         schpv_schv_code,
                                                         schpv_pol_batch_no,
                                                         schpv_value,
                                                         schpv_narration)
                         VALUES (gin_schpv_code_seq.NEXTVAL,
                                 cur_schedule_values_rec.schpv_schv_code,
                                 v_new_pol_batch_no,
                                 cur_schedule_values_rec.schpv_value,
                                 cur_schedule_values_rec.schpv_narration);
                EXCEPTION
                    WHEN DUP_VAL_ON_INDEX
                    THEN
                        raise_error (
                               'System attempted to illegaly duplicate '
                            || cur_schedule_values_rec.schpv_schv_code
                            || ' clause record. Please contact Turnkey Africa for support...');
                    WHEN OTHERS
                    THEN
                        raise_error (
                            'Unable to insert policy level clauses details, ...');
                END;
            END LOOP;

            BEGIN
                UPDATE gin_policy_subclass_clauses
                   SET poscl_new = 'N'
                 WHERE poscl_pol_policy_no = v_pol_no;
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error ('Unable to update subclass clause status');
            END;

            FOR cur_pol_perils_rec IN cur_pol_perils (v_old_pol_batch_no)
            LOOP
                BEGIN
                    INSERT INTO gin_policy_section_perils (
                                    pspr_code,
                                    pspr_scl_code,
                                    pspr_sect_code,
                                    pspr_sect_sht_desc,
                                    pspr_per_code,
                                    pspr_per_sht_desc,
                                    pspr_mandatory,
                                    pspr_peril_limit,
                                    pspr_peril_type,
                                    pspr_si_or_limit,
                                    pspr_sec_code,
                                    pspr_excess_type,
                                    pspr_excess,
                                    pspr_excess_min,
                                    pspr_excess_max,
                                    pspr_expire_on_claim,
                                    pspr_bind_code,
                                    pspr_person_limit,
                                    pspr_claim_limit,
                                    pspr_desc,
                                    pspr_bind_type,
                                    pspr_pol_batch_no,
                                    pspr_sspr_code,
                                    pspr_depreciation_pct,
                                    pspr_tl_excess_type,
                                    pspr_tl_excess,
                                    pspr_tl_excess_min,
                                    pspr_tl_excess_max,
                                    pspr_pl_excess_type,
                                    pspr_pl_excess,
                                    pspr_pl_excess_min,
                                    pspr_pl_excess_max,
                                    pspr_claim_excess_min,
                                    pspr_claim_excess_max,
                                    pspr_depend_loss_type,
                                    pspr_claim_excess_type,
                                    pspr_ttd_ben_pcts)
                         VALUES (gin_pspr_code_seq.NEXTVAL,
                                 cur_pol_perils_rec.pspr_scl_code,
                                 cur_pol_perils_rec.pspr_sect_code,
                                 cur_pol_perils_rec.pspr_sect_sht_desc,
                                 cur_pol_perils_rec.pspr_per_code,
                                 cur_pol_perils_rec.pspr_per_sht_desc,
                                 cur_pol_perils_rec.pspr_mandatory,
                                 cur_pol_perils_rec.pspr_peril_limit,
                                 cur_pol_perils_rec.pspr_peril_type,
                                 cur_pol_perils_rec.pspr_si_or_limit,
                                 cur_pol_perils_rec.pspr_sec_code,
                                 cur_pol_perils_rec.pspr_excess_type,
                                 cur_pol_perils_rec.pspr_excess,
                                 cur_pol_perils_rec.pspr_excess_min,
                                 cur_pol_perils_rec.pspr_excess_max,
                                 cur_pol_perils_rec.pspr_expire_on_claim,
                                 cur_pol_perils_rec.pspr_bind_code,
                                 cur_pol_perils_rec.pspr_person_limit,
                                 cur_pol_perils_rec.pspr_claim_limit,
                                 cur_pol_perils_rec.pspr_desc,
                                 cur_pol_perils_rec.pspr_bind_type,
                                 v_new_pol_batch_no,
                                 cur_pol_perils_rec.pspr_sspr_code,
                                 cur_pol_perils_rec.pspr_depreciation_pct,
                                 cur_pol_perils_rec.pspr_tl_excess_type,
                                 cur_pol_perils_rec.pspr_tl_excess,
                                 cur_pol_perils_rec.pspr_tl_excess_min,
                                 cur_pol_perils_rec.pspr_tl_excess_max,
                                 cur_pol_perils_rec.pspr_pl_excess_type,
                                 cur_pol_perils_rec.pspr_pl_excess,
                                 cur_pol_perils_rec.pspr_pl_excess_min,
                                 cur_pol_perils_rec.pspr_pl_excess_max,
                                 cur_pol_perils_rec.pspr_claim_excess_min,
                                 cur_pol_perils_rec.pspr_claim_excess_max,
                                 cur_pol_perils_rec.pspr_depend_loss_type,
                                 cur_pol_perils_rec.pspr_claim_excess_type,
                                 cur_pol_perils_rec.pspr_ttd_ben_pcts);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error ('Error updating policy perils..');
                END;
            END LOOP;

            FOR cur_taxes_rec
                IN cur_taxes (v_old_pol_batch_no,
                              cur_endors_pol_rec.pol_pro_code)
            LOOP
                BEGIN
                    INSERT INTO gin_policy_taxes (ptx_trac_scl_code,
                                                  ptx_trac_trnt_code,
                                                  ptx_pol_policy_no,
                                                  ptx_pol_ren_endos_no,
                                                  ptx_pol_batch_no,
                                                  ptx_rate,
                                                  ptx_amount,
                                                  ptx_tl_lvl_code,
                                                  ptx_rate_type,
                                                  ptx_rate_desc,
                                                  ptx_endos_diff_amt,
                                                  ptx_tax_type,
                                                  ptx_risk_pol_level,
                                                  ptx_override,
                                                  ptx_override_amt)
                         VALUES (cur_taxes_rec.ptx_trac_scl_code,
                                 cur_taxes_rec.ptx_trac_trnt_code,
                                 v_pol_no,
                                 v_end_no,
                                 v_new_pol_batch_no --, cur_taxes_rec.PTX_POL_POLICY_NO
                                                   --, cur_taxes_rec.PTX_POL_REN_ENDOS_NO
                                                   --, cur_taxes_rec.PTX_POL_BATCH_NO
                                                   ,
                                 cur_taxes_rec.ptx_rate,
                                 cur_taxes_rec.ptx_amount,
                                 cur_taxes_rec.ptx_tl_lvl_code,
                                 cur_taxes_rec.ptx_rate_type,
                                 cur_taxes_rec.ptx_rate_desc,
                                 cur_taxes_rec.ptx_endos_diff_amt,
                                 cur_taxes_rec.ptx_tax_type,
                                 cur_taxes_rec.ptx_risk_pol_level,
                                 cur_taxes_rec.ptx_override,
                                 cur_taxes_rec.ptx_override_amt);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error ('Unable to populate taxes...');
                END;
            END LOOP;

            BEGIN
                insert_policy_spec_details (cur_endors_pol_rec.pol_pro_code,
                                            v_old_pol_batch_no,
                                            v_new_pol_batch_no,
                                            'U');
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error (
                        'Unable to populate policy specific details');
            END;

            FOR cur_insureds_rec IN cur_insureds
            LOOP
                cnt := cnt + 1;

                BEGIN
                    INSERT INTO gin_policy_insureds (polin_code,
                                                     polin_pol_policy_no,
                                                     polin_pol_ren_endos_no,
                                                     polin_pol_batch_no,
                                                     polin_prp_code,
                                                     polin_new_insured)
                         VALUES (polin_code_seq.NEXTVAL,
                                 cur_endors_pol_rec.pol_policy_no,
                                 v_end_no,
                                 v_new_pol_batch_no,
                                 cur_insureds_rec.prp_code,
                                 'N');
                EXCEPTION
                    WHEN v_dup_rec
                    THEN
                        raise_error (
                            'Error :- Attempted to create a duplicate record of the insureds....');
                    WHEN OTHERS
                    THEN
                        raise_error (
                            'Unable to insert insureds details, ...');
                END;

                FOR cur_ipu_rec IN cur_ipu (cur_insureds_rec.prp_code)
                LOOP
                    SELECT scl_cert_autogen
                      INTO v_cert_autogen
                      FROM gin_sub_classes
                     WHERE scl_code = cur_ipu_rec.ipu_sec_scl_code;

                    v_ipu_wet := NULL;

                    IF v_trans_type = 'EX'
                    THEN
                        v_ipu_wet := v_pol_wet;
                        v_ipu_wef := v_pol_wef;
                        v_ipu_eff_wef := v_ipu_wef; -- cur_ipu_rec.ipu_eff_wef;
                    ELSIF v_trans_type = 'CN'
                    THEN
                        v_ipu_wet := v_pol_wet;
                        v_ipu_wef := v_pol_wef;
                        v_ipu_eff_wef := v_pol_wef;

                        IF v_cancelled_by = 'C'
                        THEN
                            v_prorata := 'S';
                        END IF;
                    ELSIF v_trans_type = 'DC'
                    THEN
                        v_ipu_wet := cur_ipu_rec.ipu_eff_wet;
                        v_ipu_wef := cur_ipu_rec.ipu_eff_wef;
                        v_ipu_eff_wef := cur_ipu_rec.ipu_eff_wef;
                    ELSE
                        IF NVL (cur_ipu_rec.ipu_action_type, 'A') != 'D'
                        THEN
                            v_ipu_wet := cur_ipu_rec.ipu_eff_wet;
                            v_ipu_wef := v_pol_wef;
                            v_ipu_eff_wef := cur_ipu_rec.ipu_eff_wef;
                        ELSE
                            v_ipu_wet := v_trans_eff_date;
                            v_ipu_wef := v_pol_wef;
                            v_ipu_eff_wef := cur_ipu_rec.ipu_eff_wef;
                        END IF;
                    END IF;

                    v_risk_uw_yr := NULL;
                    v_ipu_prev_prem := cur_ipu_rec.ipu_prev_prem;

                    IF     NVL (cur_endors_pol_rec.pol_binder_policy, 'N') =
                           'Y'
                       AND cur_ipu_rec.ipu_status = 'RN'
                    THEN
                        v_ipu_eff_wef :=
                            get_renewal_date (
                                cur_endors_pol_rec.pol_pro_code,
                                cur_ipu_rec.ipu_eff_wet);
                        v_ipu_wef := v_ipu_eff_wef;
                        v_ipu_wet :=
                            get_wet_date (cur_endors_pol_rec.pol_pro_code,
                                          v_ipu_eff_wef);
                        v_ipu_prev_prem := 0;
                        v_risk_uw_yr :=
                            TO_NUMBER (TO_CHAR (v_ipu_eff_wef, 'RRRR'));
                    ELSE
                        IF     NVL (v_trans_type, 'NB') = 'EX'
                           AND v_param_ext = 'Y'
                        THEN
                            v_risk_uw_yr :=
                                TO_NUMBER (TO_CHAR (v_ipu_eff_wef, 'RRRR'));
                        ELSE
                            v_risk_uw_yr := cur_ipu_rec.ipu_uw_yr;
                        END IF;
                    END IF;

                    SELECT    TO_NUMBER (TO_CHAR (SYSDATE, 'RRRR'))
                           || gin_ipu_code_seq.NEXTVAL
                      INTO v_new_ipu_code
                      FROM DUAL;

                    BEGIN
                        v_ipu_prev_ri_amt := 0;

                        IF NVL (cur_endors_pol_rec.pol_binder_policy, 'N') !=
                           'Y'
                        THEN
                            IF cur_endors_pol_rec.pol_policy_status IN
                                   ('NB', 'RN', 'SP')
                            THEN
                                v_ipu_prev_ri_amt :=
                                    cur_ipu_rec.ipu_reinsure_amt;
                            ELSE
                                v_ipu_prev_ri_amt := 0;
                            --cur_ipu_rec.IPU_REINSURE_AMT;
                            END IF;
                        ELSE
                            IF cur_ipu_rec.ipu_status IN ('NB', 'RN', 'SP')
                            THEN
                                v_ipu_prev_ri_amt :=
                                    cur_ipu_rec.ipu_reinsure_amt;
                            ELSE
                                v_ipu_prev_ri_amt := 0;
                            --cur_ipu_rec.IPU_REINSURE_AMT;
                            END IF;
                        END IF;

                        IF    v_trans_type = 'DC'
                           OR NVL (cur_ipu_rec.ipu_endos_remove, 'N') = 'N'
                        THEN
                            vipuwef := v_ipu_wef;
                            vipueffwef := v_ipu_eff_wef;
                            vipuwet := v_ipu_wet;
                            vipueffwet := v_ipu_wet;
                            vprevipucode := cur_ipu_rec.ipu_code;
                            vprevprem := v_ipu_prev_prem;
                            vipupaidprem := cur_ipu_rec.ipu_paid_premium;
                            vipupaidtl := cur_ipu_rec.ipu_paid_tl;
                        ELSE
                            vipuwef := cur_ipu_rec.ipu_eff_wet + 1;
                            vipueffwef := cur_ipu_rec.ipu_eff_wet + 1;
                            vipuwet := cur_ipu_rec.ipu_eff_wet + 1;
                            vipueffwet := cur_ipu_rec.ipu_eff_wet + 1;
                            vprevipucode := v_new_ipu_code;
                            vprevprem := 0;
                            vipupaidprem := 0;
                            vipupaidtl := 0;
                        END IF;

                        IF v_trans_type = 'DC'
                        THEN
                            viputranstype := 'DC';
                        ELSIF NVL (cur_endors_pol_rec.pol_binder_policy, 'N') =
                              'N'
                        THEN
                            IF NVL (cur_ipu_rec.ipu_endos_remove, 'N') = 'N'
                            THEN
                                viputranstype := 'EN';
                            ELSE
                                --viputranstype := 'NB';
                                viputranstype := 'EN';
                            END IF;
                        ELSE
                            viputranstype := cur_ipu_rec.ipu_status;
                        END IF;

                        v_covt_code := cur_ipu_rec.ipu_covt_code;
                        v_ipu_covt_sht_desc := cur_ipu_rec.ipu_covt_sht_desc;

                        --      raise_error('pol_cancelled_by='||v_cancelled_by||'='||v_prorata);
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
                                        ipu_override_ri_retention,
                                        ipu_prev_reinsure_amt,
                                        ipu_risk_oth_int_parties,
                                        ipu_conveyance_type,
                                        ipu_prev_prorata_sect_prem,
                                        ipu_prorata_sect_prem,
                                        ipu_nonprorata_sect_prem,
                                        ipu_prev_nonprorata_sect_prem,
                                        ipu_tot_prorata_sect_prem,
                                        ipu_tot_nonprorata_sect_prem,
                                        ipu_prev_tot_prorata_s_prem,
                                        ipu_prev_tot_nonprorata_s_prem,
                                        ipu_prev_status,
                                        ipu_install_period,
                                        ipu_rs_code,
                                        ipu_rescue_mem,
                                        ipu_rescue_charge,
                                        ipu_health_tax,
                                        ipu_road_safety_tax,
                                        ipu_certchg,
                                        ipu_motor_levy,
                                        ipu_cashback_appl,
                                        ipu_cashback_level,
                                        ipu_vehicle_model_code,
                                        ipu_vehicle_make_code,
                                        ipu_vehicle_model,
                                        ipu_vehicle_make,
                                        ipu_model_yr,
                                        ipu_cert_no,
                                        ipu_maintenance_period_type,
                                        ipu_maintenance_period,
                                        ipu_other_client_deductibles,
                                        ipu_coin_other_client_charges,
                                        ipu_survey_agnt_code,
                                        ipu_survey)
                                 VALUES (
                                            v_new_ipu_code,
                                            cur_ipu_rec.ipu_property_id,
                                            cur_ipu_rec.ipu_item_desc,
                                            cur_ipu_rec.ipu_qty,
                                            cur_ipu_rec.ipu_value,
                                            --DECODE(:GIN_POLICIES_RENEWAL.POL_POLICY_STATUS,'DC',v_ipu_wef,DECODE(NVL(cur_ipu_rec.IPU_ENDOS_REMOVE,'N'),'CN',v_ipu_wef,DECODE(NVL(cur_ipu_rec.IPU_ENDOS_REMOVE,'N'),'N',v_ipu_wef,cur_ipu_rec.IPU_EFF_WET + 1)),
                                            --DECODE(:GIN_POLICIES_RENEWAL.POL_POLICY_STATUS,'DC',v_ipu_wet,DECODE(NVL(cur_ipu_rec.IPU_ENDOS_REMOVE,'N'),'CN',v_ipu_wef,DECODE(NVL(cur_ipu_rec.IPU_ENDOS_REMOVE,'N'),'N',v_ipu_wet,cur_ipu_rec.IPU_EFF_WET+ 1)),
                                            vipuwef,
                                            --DECODE(v_trans_type,'DC',v_ipu_wef,DECODE(NVL(cur_ipu_rec.IPU_ENDOS_REMOVE,'N'),'N',v_ipu_wef,cur_ipu_rec.IPU_EFF_WET + 1)),
                                            vipuwet,
                                            --DECODE(v_trans_type,'DC',v_ipu_wet,DECODE(NVL(cur_ipu_rec.IPU_ENDOS_REMOVE,'N'),'N',v_ipu_wet,cur_ipu_rec.IPU_EFF_WET+ 1)),
                                            cur_ipu_rec.ipu_pol_policy_no,
                                            v_end_no,
                                            v_new_pol_batch_no,
                                            cur_ipu_rec.ipu_earth_quake_cover,
                                            cur_ipu_rec.ipu_earth_quake_prem,
                                            cur_ipu_rec.ipu_location,
                                            polin_code_seq.CURRVAL,
                                            cur_ipu_rec.ipu_sec_scl_code,
                                            cur_ipu_rec.ipu_ncd_status,
                                            cur_ipu_rec.ipu_related_ipu_code,
                                            DECODE (
                                                v_trans_type,
                                                'CN', DECODE (
                                                          v_cancelled_by,
                                                          'C', v_prorata,
                                                          cur_ipu_rec.ipu_prorata),
                                                cur_ipu_rec.ipu_prorata),
                                            cur_ipu_rec.ipu_gp,
                                            cur_ipu_rec.ipu_fap,
                                            vprevipucode,
                                            --DECODE(v_trans_type,'DC',cur_ipu_rec.ipu_code,DECODE(NVL(cur_ipu_rec.IPU_ENDOS_REMOVE,'N'),'N',cur_ipu_rec.ipu_code,v_new_ipu_code)),
                                            cur_ipu_rec.ipu_ncd_level,
                                            cur_ipu_rec.ipu_quz_code,
                                            cur_ipu_rec.ipu_quz_sht_desc,
                                            cur_ipu_rec.ipu_sht_desc,
                                            cur_ipu_rec.ipu_id,
                                            cur_ipu_rec.ipu_bind_code,
                                            cur_ipu_rec.ipu_excess_rate,
                                            cur_ipu_rec.ipu_excess_type,
                                            cur_ipu_rec.ipu_excess_rate_type,
                                            cur_ipu_rec.ipu_excess_min,
                                            cur_ipu_rec.ipu_excess_max,
                                            cur_ipu_rec.ipu_prereq_ipu_code,
                                            cur_ipu_rec.ipu_escalation_rate,
                                            cur_ipu_rec.ipu_comm_rate,
                                            cur_ipu_rec.ipu_pol_batch_no,
                                            cur_ipu_rec.ipu_cur_code,
                                            cur_ipu_rec.ipu_relr_code,
                                            cur_ipu_rec.ipu_relr_sht_desc,
                                            DECODE (
                                                cur_ipu_rec.ipu_pol_est_max_loss,
                                                NULL, 100,
                                                0, 100,
                                                cur_ipu_rec.ipu_pol_est_max_loss),
                                            vipueffwef,
                                            --DECODE(v_trans_type,'DC',v_ipu_eff_wef,DECODE(NVL(cur_ipu_rec.IPU_ENDOS_REMOVE,'N'),'N',v_ipu_eff_wef,cur_ipu_rec.IPU_EFF_WET + 1)),
                                            vipueffwet,
                                            --DECODE(v_trans_type,'DC',v_ipu_wet,DECODE(NVL(cur_ipu_rec.IPU_ENDOS_REMOVE,'N'),'N',v_ipu_wet,cur_ipu_rec.IPU_EFF_WET + 1)),
                                            cur_ipu_rec.ipu_retro_cover,
                                            cur_ipu_rec.ipu_retro_wef,
                                            v_covt_code,
                                            v_ipu_covt_sht_desc,
                                            cur_ipu_rec.ipu_si_diff,
                                            cur_ipu_rec.ipu_terr_code,
                                            cur_ipu_rec.ipu_terr_desc,
                                            cur_ipu_rec.ipu_from_time,
                                            cur_ipu_rec.ipu_to_time,
                                            cur_ipu_rec.ipu_mar_cert_no,
                                            cur_ipu_rec.ipu_comp_retention,
                                            cur_ipu_rec.ipu_gross_comp_retention,
                                            cur_ipu_rec.ipu_com_retention_rate,
                                            cur_ipu_rec.ipu_prp_code,
                                            cur_ipu_rec.ipu_tot_endos_prem_dif,
                                            cur_ipu_rec.ipu_tot_gp,
                                            cur_ipu_rec.ipu_tot_value,
                                            cur_ipu_rec.ipu_ri_agnt_com_rate,
                                            cur_ipu_rec.ipu_cover_days,
                                            cur_ipu_rec.ipu_bp,
                                            vprevprem,
                                            --DECODE(v_trans_type,'DC',v_ipu_prev_prem,DECODE(NVL(cur_ipu_rec.IPU_ENDOS_REMOVE,'N'),'N',v_ipu_prev_prem ,0) ),
                                            cur_ipu_rec.ipu_ri_agnt_comm_amt,
                                            cur_ipu_rec.ipu_tot_fap,
                                            cur_ipu_rec.ipu_max_exposure,
                                            viputranstype,
                                            --DECODE(v_trans_type,'DC','DC',DECODE(NVL(cur_endors_pol_rec.POL_BINDER_POLICY,'N'),'N',DECODE(NVL(cur_ipu_rec.IPU_ENDOS_REMOVE,'N'),'N','EN','NB'),cur_ipu_rec.IPU_STATUS)),
                                            v_risk_uw_yr,
                                            cur_ipu_rec.ipu_tot_first_loss,
                                            cur_ipu_rec.ipu_accumulation_limit,
                                            cur_ipu_rec.ipu_compute_max_exposure,
                                            cur_ipu_rec.ipu_reinsure_amt,
                                            vipupaidprem,
                                              --DECODE(v_trans_type,'DC',cur_ipu_rec.IPU_PAID_PREMIUM,DECODE(NVL(cur_ipu_rec.IPU_ENDOS_REMOVE,'N'),'N',cur_ipu_rec.IPU_PAID_PREMIUM,0)),
                                              NVL (
                                                  cur_ipu_rec.ipu_trans_count,
                                                  0)
                                            + 1,
                                            vipupaidtl,
                                            --DECODE(v_trans_type,'DC',cur_ipu_rec.IPU_PAID_TL,DECODE(NVL(cur_ipu_rec.IPU_ENDOS_REMOVE,'N'),'N',cur_ipu_rec.IPU_PAID_TL,0)),
                                            cur_ipu_rec.ipu_inception_uwyr,
                                            vipuwet,
                                            --DECODE(v_trans_type,'DC',v_ipu_wet,DECODE(NVL(cur_ipu_rec.IPU_ENDOS_REMOVE,'N'),'N',v_ipu_wet,cur_ipu_rec.IPU_EFF_WET + 1)),
                                            cur_ipu_rec.ipu_eml_based_on,
                                            cur_ipu_rec.ipu_aggregate_limits,
                                            cur_ipu_rec.ipu_rc_sht_desc,
                                            cur_ipu_rec.ipu_rc_code,
                                            cur_ipu_rec.ipu_survey_date,
                                            cur_ipu_rec.ipu_item_details,
                                            cur_ipu_rec.ipu_tot_fap,
                                            cur_ipu_rec.ipu_fap,
                                            cur_ipu_rec.ipu_override_ri_retention,
                                            v_ipu_prev_ri_amt,
                                            cur_ipu_rec.ipu_risk_oth_int_parties,
                                            cur_ipu_rec.ipu_conveyance_type,
                                            cur_ipu_rec.ipu_prorata_sect_prem,
                                            cur_ipu_rec.ipu_nonprorata_sect_prem,
                                            cur_ipu_rec.ipu_prorata_sect_prem,
                                            cur_ipu_rec.ipu_nonprorata_sect_prem,
                                            cur_ipu_rec.ipu_tot_prorata_sect_prem,
                                            cur_ipu_rec.ipu_tot_nonprorata_sect_prem,
                                            cur_ipu_rec.ipu_tot_prorata_sect_prem,
                                            cur_ipu_rec.ipu_tot_nonprorata_sect_prem,
                                            cur_ipu_rec.ipu_status,
                                            cur_ipu_rec.ipu_install_period,
                                            cur_ipu_rec.ipu_rs_code,
                                            cur_ipu_rec.ipu_rescue_mem,
                                            cur_ipu_rec.ipu_rescue_charge,
                                            cur_ipu_rec.ipu_health_tax,
                                            cur_ipu_rec.ipu_road_safety_tax,
                                            cur_ipu_rec.ipu_certchg,
                                            cur_ipu_rec.ipu_motor_levy,
                                            cur_ipu_rec.ipu_cashback_appl,
                                            cur_ipu_rec.ipu_cashback_level,
                                            cur_ipu_rec.ipu_vehicle_model_code,
                                            cur_ipu_rec.ipu_vehicle_make_code,
                                            cur_ipu_rec.ipu_vehicle_model,
                                            cur_ipu_rec.ipu_vehicle_make,
                                            cur_ipu_rec.ipu_model_yr,
                                            cur_ipu_rec.ipu_cert_no,
                                            cur_ipu_rec.ipu_maintenance_period_type,
                                            cur_ipu_rec.ipu_maintenance_period,
                                            cur_ipu_rec.ipu_other_client_deductibles,
                                            cur_ipu_rec.ipu_coin_other_client_charges,
                                            cur_ipu_rec.ipu_survey_agnt_code,
                                            cur_ipu_rec.ipu_survey);

                        v_endrsd_rsks_tab (1).ipu_code := v_new_ipu_code;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            raise_error (
                                'Unable to populate risk details, ..11.');
                    END;

                    FOR risk_services_rec
                        IN risk_services (cur_ipu_rec.ipu_code)
                    LOOP
                        BEGIN
                            INSERT INTO gin_policy_risk_services (
                                            prs_code,
                                            prs_ipu_code,
                                            prs_pol_batch_no,
                                            prs_pol_policy_no,
                                            prs_pol_endors_no,
                                            prs_rss_code,
                                            prs_rs_code,
                                            prs_status)
                                 VALUES (gin_prs_code_seq.NEXTVAL,
                                         v_new_ipu_code,
                                         v_new_pol_batch_no,
                                         risk_services_rec.prs_pol_policy_no,
                                         v_end_no,
                                         risk_services_rec.prs_rss_code,
                                         risk_services_rec.prs_rs_code,
                                         risk_services_rec.prs_status);
                        --commit;
                        EXCEPTION
                            WHEN DUP_VAL_ON_INDEX
                            THEN
                                ROLLBACK;
                                raise_error (
                                    'System attempted to illegaly duplicate  risk services record. Please contact Turnkey Africa for support...');
                            WHEN OTHERS
                            THEN
                                raise_error (
                                    'Unable to populate the risk services.');
                        END;
                    END LOOP;

                    FOR driver_details_rec
                        IN driver_details (cur_ipu_rec.ipu_code)
                    LOOP
                        BEGIN
                            INSERT INTO gin_clm_drv_dtls (
                                            cdr_code,
                                            cdr_name,
                                            cdr_gender,
                                            cdr_dob,
                                            cdr_rship,
                                            cdr_pin,
                                            cdr_id_no,
                                            cdr_passport_no,
                                            cdr_driving_license_no,
                                            cdr_tel,
                                            cdr_occupation,
                                            cdr_driver_experience,
                                            cdr_third_party_self,
                                            cdr_module,
                                            cdr_insured_driver,
                                            cdr_dr_code,
                                            cdr_ipu_code)
                                     VALUES (
                                                gin_cdr_code_seq.NEXTVAL,
                                                driver_details_rec.cdr_name,
                                                driver_details_rec.cdr_gender,
                                                driver_details_rec.cdr_dob,
                                                driver_details_rec.cdr_rship,
                                                driver_details_rec.cdr_pin,
                                                driver_details_rec.cdr_id_no,
                                                driver_details_rec.cdr_passport_no,
                                                driver_details_rec.cdr_driving_license_no,
                                                driver_details_rec.cdr_tel,
                                                driver_details_rec.cdr_occupation,
                                                driver_details_rec.cdr_driver_experience,
                                                driver_details_rec.cdr_third_party_self,
                                                driver_details_rec.cdr_module,
                                                driver_details_rec.cdr_insured_driver,
                                                driver_details_rec.cdr_dr_code,
                                                v_new_ipu_code);
                        --commit;
                        EXCEPTION
                            WHEN DUP_VAL_ON_INDEX
                            THEN
                                ROLLBACK;
                                raise_error (
                                    'System attempted to illegaly duplicate  risk services record. Please contact Turnkey Africa for support...');
                            WHEN OTHERS
                            THEN
                                raise_error (
                                    'Unable to populate the risk services.');
                        END;
                    END LOOP;

                    BEGIN
                        gin_schedules_pkg.insert_spec_details (
                            cur_endors_pol_rec.pol_pro_code,
                            cur_ipu_rec.ipu_code,
                            v_new_ipu_code,
                            'N',
                            'UW-UW');
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            raise_error (
                                'Unable to bring foward the specific details');
                    END;

                    IF v_trans_type NOT IN ('CO', 'CN', 'DC')
                    THEN
                        IF NVL (v_cert_autogen, 'N') = 'Y'
                        THEN
                            BEGIN
                                auto_assign_certs (v_new_ipu_code,
                                                   vipuwef,
                                                   vipuwet,
                                                   NULL,
                                                   NULL);
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    NULL;
                            END;
                        END IF;

                        BEGIN
                            gin_stp_uw_pkg.populate_cert_to_print (
                                v_new_batch_no);
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                raise_error (
                                       'Error allocating certificates at step 1....'
                                    || SQLERRM (SQLCODE));
                        END;
                    END IF;

                    IF NVL (v_auto_populate_limits, 'N') = 'Y'
                    THEN
                        BEGIN
                            gin_stp_uw_pkg.autopopulate_schedules (
                                cur_endors_pol_rec.pol_batch_no,
                                cur_ipu_rec.ipu_sec_scl_code);
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                raise_error (
                                       'Error inserting mandatory clauses....'
                                    || SQLERRM (SQLCODE));
                        END;
                    END IF;

                    FOR cur_limits_rec IN cur_limits (cur_ipu_rec.ipu_code)
                    LOOP
                        v_pil_prem_amt := 0;
                        v_compute := 'Y';

                        IF     v_trans_type = 'DC'
                           AND cur_limits_rec.pil_sect_type IN ('SS',
                                                                'EL',
                                                                'SL',
                                                                'ES')
                           AND NVL (cur_limits_rec.pil_declaration_section,
                                    'N') !=
                               'Y'
                        THEN
                            v_pil_prem_amt :=
                                cur_limits_rec.pil_prem_accumulation;
                            v_compute := 'Y';
                        ELSE
                            v_pil_prem_amt := cur_limits_rec.pil_prem_amt;
                            v_compute :=
                                NVL (cur_limits_rec.pil_compute, 'Y');
                        END IF;

                        BEGIN
                            v_pil_prev_limit := 0;

                            IF v_trans_type IN ('NB', 'RN', 'DC')
                            THEN
                                v_pil_prev_limit := 0;
                            ELSE
                                IF NVL (cur_ipu_rec.ipu_status, 'NB') IN
                                       ('EX', 'RN', 'RE')
                                THEN
                                    v_pil_prev_limit := 0;
                                ELSE
                                    v_pil_prev_limit :=
                                        cur_limits_rec.pil_used_limit;
                                END IF;
                            END IF;

                            SELECT    TO_NUMBER (TO_CHAR (SYSDATE, 'RRRR'))
                                   || gin_pil_code_seq.NEXTVAL
                              INTO v_pil_code
                              FROM DUAL;

                            INSERT INTO gin_policy_insured_limits (
                                            pil_code,
                                            pil_ipu_code,
                                            pil_sect_code,
                                            pil_sect_sht_desc,
                                            pil_row_num,
                                            pil_calc_group,
                                            pil_limit_amt,
                                            pil_prem_rate,
                                            pil_prem_amt,
                                            pil_rate_type,
                                            pil_rate_desc,
                                            pil_sect_type,
                                            pil_sect_excess_detail,
                                            pil_original_prem_rate,
                                            pil_rate_change_remarks,
                                            pil_change_done_by,
                                            pil_min_premium,
                                            pil_comment,
                                            pil_multiplier_rate,
                                            pil_multiplier_div_factor,
                                            pil_annual_premium,
                                            pil_rate_div_fact,
                                            pil_desc,
                                            pil_compute,
                                            pil_used_limit,
                                            pil_indem_prd,
                                            pil_prd_type,
                                            pil_indem_fstprd,
                                            pil_indem_fstprd_pct,
                                            pil_indem_remprd_pct,
                                            pil_dual_basis,
                                            pil_prem_accumulation,
                                            pil_prev_prem,
                                            pil_declaration_section,
                                            pil_prev_limit,
                                            pil_prev_prem_prorata,
                                            pil_annual_actual_prem,
                                            pil_eml_pct,
                                            pil_top_loc_rate,
                                            pil_top_loc_div_fact,
                                            pil_limit_prd,
                                            pil_free_limit,
                                            pil_prorata_full,
                                            pil_expired,
                                            pil_si_limit_type,
                                            pil_si_rate,
                                            pil_cover_type,
                                            pil_prev_endr_prem_rate,
                                            pil_prev_endr_rate_div_fact,
                                            pil_prev_endr_mult_rate,
                                            pil_prev_endr_mult_div_fact,
                                            pil_firstloss,
                                            pil_firstloss_amt_pcnt,
                                            pil_firstloss_value)
                                     VALUES (
                                                v_pil_code,
                                                v_new_ipu_code,
                                                cur_limits_rec.pil_sect_code,
                                                cur_limits_rec.pil_sect_sht_desc,
                                                cur_limits_rec.pil_row_num,
                                                cur_limits_rec.pil_calc_group,
                                                cur_limits_rec.pil_limit_amt,
                                                cur_limits_rec.pil_prem_rate,
                                                v_pil_prem_amt,
                                                cur_limits_rec.pil_rate_type,
                                                cur_limits_rec.pil_rate_desc,
                                                cur_limits_rec.pil_sect_type,
                                                cur_limits_rec.pil_sect_excess_detail,
                                                cur_limits_rec.pil_original_prem_rate,
                                                cur_limits_rec.pil_rate_change_remarks,
                                                cur_limits_rec.pil_change_done_by,
                                                cur_limits_rec.pil_min_premium,
                                                cur_limits_rec.pil_comment,
                                                cur_limits_rec.pil_multiplier_rate,
                                                cur_limits_rec.pil_multiplier_div_factor,
                                                cur_limits_rec.pil_annual_premium,
                                                cur_limits_rec.pil_rate_div_fact,
                                                cur_limits_rec.pil_desc,
                                                v_compute,
                                                cur_limits_rec.pil_used_limit,
                                                cur_limits_rec.pil_indem_prd,
                                                cur_limits_rec.pil_prd_type,
                                                cur_limits_rec.pil_indem_fstprd,
                                                cur_limits_rec.pil_indem_fstprd_pct,
                                                cur_limits_rec.pil_indem_remprd_pct,
                                                cur_limits_rec.pil_dual_basis,
                                                DECODE (
                                                    v_trans_type,
                                                    'DC', cur_limits_rec.pil_prem_accumulation,
                                                    DECODE (
                                                        NVL (
                                                            cur_ipu_rec.ipu_endos_remove,
                                                            'N'),
                                                        'N', cur_limits_rec.pil_prem_accumulation,
                                                        0)),
                                                cur_limits_rec.pil_annual_premium,
                                                cur_limits_rec.pil_declaration_section,
                                                DECODE (
                                                    v_trans_type,
                                                    'DC', v_pil_prev_limit,
                                                    DECODE (
                                                        NVL (
                                                            cur_ipu_rec.ipu_endos_remove,
                                                            'N'),
                                                        'N', v_pil_prev_limit,
                                                        0)),
                                                cur_limits_rec.pil_prem_prorata,
                                                cur_limits_rec.pil_annual_actual_prem,
                                                cur_limits_rec.pil_eml_pct,
                                                cur_limits_rec.pil_top_loc_rate,
                                                cur_limits_rec.pil_top_loc_div_fact,
                                                cur_limits_rec.pil_limit_prd,
                                                cur_limits_rec.pil_free_limit,
                                                cur_limits_rec.pil_prorata_full,
                                                cur_limits_rec.pil_expired,
                                                cur_limits_rec.pil_si_limit_type,
                                                cur_limits_rec.pil_si_rate,
                                                cur_limits_rec.pil_cover_type,
                                                cur_limits_rec.pil_prem_rate,
                                                cur_limits_rec.pil_rate_div_fact,
                                                cur_limits_rec.pil_multiplier_rate,
                                                cur_limits_rec.pil_multiplier_div_factor,
                                                cur_limits_rec.pil_firstloss,
                                                cur_limits_rec.pil_firstloss_amt_pcnt,
                                                cur_limits_rec.pil_firstloss_value);
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                raise_error (
                                       'Unable to insert risk sections details, ipu_code='
                                    || v_new_ipu_code
                                    || ' pilcode='
                                    || v_pil_code);
                        END;
                    END LOOP;

                    FOR cur_clauses_rec IN cur_clauses (cur_ipu_rec.ipu_code)
                    LOOP
                        BEGIN
                            INSERT INTO gin_policy_clauses (
                                            pocl_sbcl_cls_code,
                                            pocl_sbcl_scl_code,
                                            pocl_cls_sht_desc,
                                            pocl_pol_policy_no,
                                            pocl_pol_ren_endos_no,
                                            pocl_pol_batch_no,
                                            pocl_ipu_code,
                                            pocl_new,
                                            plcl_cls_type,
                                            pocl_clause,
                                            pocl_cls_editable,
                                            pocl_heading)
                                 VALUES (cur_clauses_rec.pocl_sbcl_cls_code,
                                         cur_ipu_rec.ipu_sec_scl_code,
                                         cur_clauses_rec.pocl_cls_sht_desc,
                                         v_pol_no,
                                         v_end_no,
                                         v_new_pol_batch_no,
                                         v_new_ipu_code,
                                         'N',
                                         cur_clauses_rec.plcl_cls_type,
                                         cur_clauses_rec.pocl_clause,
                                         cur_clauses_rec.pocl_cls_editable,
                                         cur_clauses_rec.pocl_heading);
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                raise_error (
                                    'Unable to insert risk level clause details, ...');
                        END;
                    END LOOP;

                    FOR cur_rsk_perils_rec
                        IN cur_rsk_perils (cur_ipu_rec.ipu_code)
                    LOOP
                        -- DO YOUR INSERTS INTO clauses
                        BEGIN
                            --    message('inserting risk GIN_POLICY_CLAUSES ...');pause;
                            INSERT INTO gin_pol_risk_section_perils (
                                            prspr_code,
                                            prspr_pol_batch_no,
                                            prspr_ipu_code,
                                            prspr_scl_code,
                                            prspr_sect_code,
                                            prspr_sect_sht_desc,
                                            prspr_per_code,
                                            prspr_per_sht_desc,
                                            prspr_mandatory,
                                            prspr_peril_limit,
                                            prspr_peril_type,
                                            prspr_si_or_limit,
                                            prspr_sec_code,
                                            prspr_excess_type,
                                            prspr_excess,
                                            prspr_excess_min,
                                            prspr_excess_max,
                                            prspr_expire_on_claim,
                                            prspr_bind_code,
                                            prspr_person_limit,
                                            prspr_claim_limit,
                                            prspr_desc,
                                            prspr_bind_type,
                                            prspr_sspr_code,
                                            prspr_salvage_pct,
                                            prspr_claim_excess_type,
                                            prspr_tl_excess_type,
                                            prspr_tl_excess,
                                            prspr_tl_excess_min,
                                            prspr_tl_excess_max,
                                            prspr_pl_excess_type,
                                            prspr_pl_excess,
                                            prspr_pl_excess_min,
                                            prspr_pl_excess_max,
                                            prspr_claim_excess_min,
                                            prspr_claim_excess_max,
                                            prspr_depend_loss_type,
                                            prspr_ttd_ben_pcts,
                                            prspr_ssprm_code,
                                            prspr_prem_rate,
                                            prspr_premium_amt,
                                            prspr_pil_code,
                                            prspr_annual_premium,
                                            prspr_prem_prorata,
                                            prspr_actual_rate_prem,
                                            prspr_rate_div_fact,
                                            prspr_free_limit_amt,
                                            prspr_prorata_full,
                                            prspr_min_premium,
                                            prspr_multiplier_rate,
                                            prspr_multiplier_div_factor)
                                     VALUES (
                                                   TO_CHAR (SYSDATE, 'RRRR')
                                                || gin_prspr_code_seq.NEXTVAL,
                                                v_new_pol_batch_no,
                                                v_new_ipu_code,
                                                cur_rsk_perils_rec.prspr_scl_code,
                                                cur_rsk_perils_rec.prspr_sect_code,
                                                cur_rsk_perils_rec.prspr_sect_sht_desc,
                                                cur_rsk_perils_rec.prspr_per_code,
                                                cur_rsk_perils_rec.prspr_per_sht_desc,
                                                cur_rsk_perils_rec.prspr_mandatory,
                                                cur_rsk_perils_rec.prspr_peril_limit,
                                                cur_rsk_perils_rec.prspr_peril_type,
                                                cur_rsk_perils_rec.prspr_si_or_limit,
                                                cur_rsk_perils_rec.prspr_sec_code,
                                                cur_rsk_perils_rec.prspr_excess_type,
                                                cur_rsk_perils_rec.prspr_excess,
                                                cur_rsk_perils_rec.prspr_excess_min,
                                                cur_rsk_perils_rec.prspr_excess_max,
                                                cur_rsk_perils_rec.prspr_expire_on_claim,
                                                cur_rsk_perils_rec.prspr_bind_code,
                                                cur_rsk_perils_rec.prspr_person_limit,
                                                cur_rsk_perils_rec.prspr_claim_limit,
                                                cur_rsk_perils_rec.prspr_desc,
                                                cur_rsk_perils_rec.prspr_bind_type,
                                                cur_rsk_perils_rec.prspr_sspr_code,
                                                cur_rsk_perils_rec.prspr_salvage_pct,
                                                cur_rsk_perils_rec.prspr_claim_excess_type,
                                                cur_rsk_perils_rec.prspr_tl_excess_type,
                                                cur_rsk_perils_rec.prspr_tl_excess,
                                                cur_rsk_perils_rec.prspr_tl_excess_min,
                                                cur_rsk_perils_rec.prspr_tl_excess_max,
                                                cur_rsk_perils_rec.prspr_pl_excess_type,
                                                cur_rsk_perils_rec.prspr_pl_excess,
                                                cur_rsk_perils_rec.prspr_pl_excess_min,
                                                cur_rsk_perils_rec.prspr_pl_excess_max,
                                                cur_rsk_perils_rec.prspr_claim_excess_min,
                                                cur_rsk_perils_rec.prspr_claim_excess_max,
                                                cur_rsk_perils_rec.prspr_depend_loss_type,
                                                cur_rsk_perils_rec.prspr_ttd_ben_pcts,
                                                cur_rsk_perils_rec.prspr_ssprm_code,
                                                cur_rsk_perils_rec.prspr_prem_rate,
                                                cur_rsk_perils_rec.prspr_premium_amt,
                                                cur_rsk_perils_rec.prspr_pil_code,
                                                cur_rsk_perils_rec.prspr_annual_premium,
                                                cur_rsk_perils_rec.prspr_prem_prorata,
                                                cur_rsk_perils_rec.prspr_actual_rate_prem,
                                                cur_rsk_perils_rec.prspr_rate_div_fact,
                                                cur_rsk_perils_rec.prspr_free_limit_amt,
                                                cur_rsk_perils_rec.prspr_prorata_full,
                                                cur_rsk_perils_rec.prspr_min_premium,
                                                cur_rsk_perils_rec.prspr_multiplier_rate,
                                                cur_rsk_perils_rec.prspr_multiplier_div_factor);
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                raise_error (
                                    'Unable to insert risk level clause details, ...');
                        END;
                    END LOOP;

                    FOR cur_perils_rec IN cur_perils (cur_ipu_rec.ipu_code)
                    LOOP
                        BEGIN
                            INSERT INTO gin_pol_sec_perils (
                                            gpsp_per_code,
                                            gpsp_per_sht_desc,
                                            gpsp_sec_sect_code,
                                            gpsp_sect_sht_desc,
                                            gpsp_sec_scl_code,
                                            gpsp_ipp_code,
                                            gpsp_ipu_code,
                                            gpsp_limit_amt,
                                            gpsp_excess_amt)
                                 VALUES (cur_perils_rec.gpsp_per_code,
                                         cur_perils_rec.gpsp_per_sht_desc,
                                         cur_perils_rec.gpsp_sec_sect_code,
                                         cur_perils_rec.gpsp_sect_sht_desc,
                                         cur_perils_rec.gpsp_sec_scl_code,
                                         cur_perils_rec.gpsp_ipp_code,
                                         v_new_ipu_code,
                                         cur_perils_rec.gpsp_limit_amt,
                                         cur_perils_rec.gpsp_excess_amt);
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                raise_error (
                                    'Unable to insert risk peril details, ...');
                        END;
                    END LOOP;

                    FOR cur_fam_rec IN cur_fam_dtls (cur_ipu_rec.ipu_code)
                    LOOP
                        INSERT INTO gin_pol_med_cat_family_details (
                                        pmcfd_code,
                                        pmcfd_pol_batch_no,
                                        pmcfd_ipu_code,
                                        pmcfd_fam_size,
                                        pmcfd_units,
                                        pmcfd_males,
                                        pmcfd_females,
                                        pmcfd_prem_amt,
                                        pmcfd_si)
                             VALUES (pmcfd_code_seq.NEXTVAL,
                                     v_new_pol_batch_no,
                                     v_new_ipu_code,
                                     cur_fam_rec.pmcfd_fam_size,
                                     cur_fam_rec.pmcfd_units,
                                     cur_fam_rec.pmcfd_males,
                                     cur_fam_rec.pmcfd_females,
                                     cur_fam_rec.pmcfd_prem_amt,
                                     cur_fam_rec.pmcfd_si);

                        FOR cur_fam_limit_rec
                            IN cur_fam_limit_dtls (cur_ipu_rec.ipu_code)
                        LOOP                            -- think through again
                            INSERT INTO gin_pol_med_fam_insured_limits (
                                            pmfil_code,
                                            pmfil_pmcfd_code,
                                            pmfil_pol_batch_no,
                                            pmfil_ipu_code,
                                            pmfil_pil_code,
                                            pmfil_fam_size,
                                            pmfil_limit,
                                            pmfil_limit_type,
                                            pmfil_prem_amt,
                                            pmfil_si)
                                 VALUES (gin_pmfil_code_seq.NEXTVAL,
                                         pmcfd_code_seq.CURRVAL,
                                         v_new_pol_batch_no,
                                         v_new_ipu_code,
                                         v_pil_code,
                                         cur_fam_limit_rec.pmfil_fam_size,
                                         cur_fam_limit_rec.pmfil_limit,
                                         cur_fam_limit_rec.pmfil_limit_type,
                                         cur_fam_limit_rec.pmfil_prem_amt,
                                         cur_fam_limit_rec.pmfil_si);
                        END LOOP;
                    END LOOP;
                END LOOP;
            END LOOP;
        END LOOP;
    END;