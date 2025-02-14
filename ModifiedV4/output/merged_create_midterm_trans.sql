```sql
PROCEDURE create_midterm_trans (
    v_old_batch   IN   NUMBER,
    v_batch_no       OUT   NUMBER,
    v_user        IN   VARCHAR2,
    v_eff_date    IN   DATE
)
IS
    v_serial             NUMBER (10);
    v_pol_no             VARCHAR2 (26);
    v_ends_no            VARCHAR2 (26);
    v_pol_prefix         VARCHAR2 (15);
    v_new_ipu_code       NUMBER;
    vdummy               NUMBER;
    v_tran_no            NUMBER;
    v_prrd_code          NUMBER;
    v_wef                DATE;
    v_wet                DATE;
    v_ren_date           DATE;
    v_year               NUMBER;
    next_ggts_trans_no   NUMBER;
    v_serialno           VARCHAR2 (26);
    v_tran_ref_no        VARCHAR2 (26);

    CURSOR cur_pol IS
        SELECT *
          FROM gin_policies
         WHERE pol_batch_no = v_old_batch;

    CURSOR cur_taxes IS
        SELECT *
          FROM gin_policy_taxes
         WHERE     ptx_pol_batch_no = v_old_batch
               AND NVL (ptx_trac_trnt_code, 'XX') != 'SD';

    CURSOR cur_coinsurer IS
        SELECT *
          FROM gin_coinsurers
         WHERE coin_pol_batch_no = v_old_batch;

    CURSOR cur_facre_dtls IS
        SELECT *
          FROM gin_facre_in_dtls
         WHERE fid_pol_batch_no = v_old_batch;

    CURSOR cur_conditions IS
        SELECT *
          FROM gin_policy_lvl_clauses
         WHERE plcl_pol_batch_no = v_old_batch;

    CURSOR cur_insureds IS
        SELECT *
          FROM gin_policy_insureds
         WHERE polin_pol_batch_no = v_old_batch;

    CURSOR cur_ipu (v_polin_code NUMBER) IS
        SELECT *
          FROM gin_insured_property_unds
         WHERE     ipu_pol_batch_no = v_old_batch
               AND ipu_polin_code = v_polin_code;

    CURSOR cur_limits (v_ipu NUMBER) IS
        SELECT *
          FROM gin_policy_insured_limits
         WHERE pil_ipu_code = v_ipu;

    CURSOR cur_clauses (v_ipu NUMBER) IS
        SELECT *
          FROM gin_policy_clauses
         WHERE pocl_ipu_code = v_ipu;

    CURSOR perils (v_ipu NUMBER) IS
        SELECT gpsp_per_code,
               gpsp_per_sht_desc,
               gpsp_sec_sect_code,
               gpsp_sect_sht_desc,
               gpsp_sec_scl_code,
               gpsp_ipp_code,
               gpsp_ipu_code,
               gpsp_limit_amt,
               gpsp_excess_amt
          FROM gin_pol_sec_perils
         WHERE gpsp_ipu_code = v_ipu;

    CURSOR risk_excesses (v_ipu NUMBER) IS
        SELECT *
          FROM gin_risk_excess
         WHERE re_ipu_code = v_ipu;

    CURSOR schedules (v_ipu NUMBER) IS
        SELECT *
          FROM gin_policy_risk_schedules
         WHERE polrs_ipu_code = v_ipu;
BEGIN
    IF v_user IS NULL
    THEN
        raise_error ('User not defined.');
    END IF;

    FOR cur_pol_rec IN cur_pol
    LOOP
        IF     NVL (cur_pol_rec.pol_reinsured, 'N') != 'Y'
           AND NVL (cur_pol_rec.pol_loaded, 'N') = 'N'
           AND tqc_interfaces_pkg.get_org_type (37) = 'INS'
        THEN
            raise_error (
                'Reinsurance for the previous transaction on this policy has not been performed/Authorised. Cannot continue..'
            );
        END IF;

        BEGIN
            SELECT pro_policy_prefix
              INTO v_pol_prefix
              FROM gin_products
             WHERE pro_code = cur_pol_rec.pol_pro_code;

            IF v_pol_prefix IS NULL
            THEN
                ROLLBACK;
                raise_error (
                    'The policy prefix for the product '
                    || cur_pol_rec.pol_pro_sht_desc
                    || ' is not defined in the setup'
                );
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                ROLLBACK;
                raise_error (
                    'The product '
                    || cur_pol_rec.pol_pro_sht_desc
                    || ' is not defined in the setup'
                );
            WHEN OTHERS
            THEN
                ROLLBACK;
                raise_error (
                    'Unable to retrieve the policy prefix for the product '
                    || cur_pol_rec.pol_pro_sht_desc
                );
        END;

        IF cur_pol_rec.pol_policy_type = 'N'
        THEN
            v_ends_no :=
                gin_sequences_pkg.get_number_format (
                    'E',
                    cur_pol_rec.pol_pro_code,
                    cur_pol_rec.pol_brn_code,
                    TO_NUMBER (TO_CHAR (SYSDATE, 'RRRR')),
                    'EN',
                    v_serial,
                    'N',
                    cur_pol_rec.pol_policy_no
                );
        ELSE
            v_ends_no :=
                gin_sequences_pkg.get_number_format (
                    'ER',
                    cur_pol_rec.pol_pro_code,
                    cur_pol_rec.pol_brn_code,
                    TO_NUMBER (TO_CHAR (SYSDATE, 'RRRR')),
                    'EN',
                    v_serial
                );
        END IF;

        BEGIN
            SELECT COUNT (1)
              INTO vdummy
              FROM gin_policies
             WHERE     pol_policy_no = cur_pol_rec.pol_policy_no
                   AND pol_ren_endos_no = v_ends_no;
        EXCEPTION
            WHEN OTHERS
            THEN
                NULL;
        END;

        IF NVL (vdummy, 0) > 0
        THEN
            v_ends_no := v_ends_no || '-' || vdummy;
        END IF;

        v_wef := v_eff_date;
        v_wet := get_wet_date (cur_pol_rec.pol_pro_code, v_wef);
        v_ren_date := get_renewal_date (cur_pol_rec.pol_pro_code, v_wet);
        v_year := TO_NUMBER (TO_CHAR (v_wef, 'RRRR'));

        IF cur_pol_rec.pol_paid_to_date > v_wef
        THEN
            raise_error (
                'ME effective date '
                || TO_CHAR (v_wef, 'DD/MM/RRRR')
                || ' cannot be less than the policy paid to date '
                || TO_CHAR (cur_pol_rec.pol_paid_to_date, 'DD/MM/RRRR')
            );
        ELSIF v_wef > cur_pol_rec.pol_policy_cover_to
        THEN
            raise_error (
                'ME effective date '
                || TO_CHAR (v_wef, 'DD/MM/RRRR')
                || ' cannot be beyond the current policy cover to date '
                || TO_CHAR (cur_pol_rec.pol_policy_cover_to, 'DD/MM/RRRR')
            );
        END IF;

        SELECT    TO_NUMBER (TO_CHAR (SYSDATE, 'RRRR'))
               || gin_pol_batch_no_seq.NEXTVAL
          INTO v_batch_no
          FROM DUAL;

        --Insert intO policies table
        BEGIN
            INSERT INTO gin_policies (
                pol_policy_no,
                pol_ren_endos_no,
                pol_batch_no,
                pol_agnt_agent_code,
                pol_agnt_sht_desc,
                pol_pmod_code,
                pol_bind_code,
                pol_wef_dt,
                pol_wet_dt,
                pol_uw_year,
                pol_total_sum_insured,
                pol_policy_status,
                pol_comm_amt,
                pol_comm_rate,
                pol_inception_dt,
                pol_tran_type,
                pol_acpr_code,
                pol_acpr_sht_desc,
                pol_alp_proposal_no,
                pol_basic_premium,
                pol_nett_premium,
                pol_cur_code,
                pol_prepared_by,
                pol_prepared_date,
                pol_checked_by,
                pol_check_date,
                pol_policy_type,
                pol_conversion_rate,
                pol_client_policy_number,
                pol_brn_code,
                pol_business_type,
                pol_cur_rate,
                pol_curr_rate_type,
                pol_comm_endos_diff_amt,
                pol_total_fap,
                pol_total_gp,
                pol_tot_endos_diff_amt,
                pol_coinsurance,
                pol_coinsure_leader,
                pol_fp,
                pol_post_status,
                pol_drcr_no,
                pol_cur_symbol,
                pol_post_ok,
                pol_brn_sht_desc,
                pol_prp_code,
                pol_current_status,
                pol_authosrised,
                pol_cancel_dt,
                pol_inception_uwyr,
                pol_pro_code,
                pol_btr_code,
                pol_btr_trans_code,
                pol_your_ref,
                pol_prop_holding_co_prp_code,
                pol_oth_int_parties,
                pol_pro_sht_desc,
                pol_prev_batch_no,
                pol_uwyr_length,
                pol_binder_policy,
                pol_bind_pro_code,
                pol_bind_pro_sht_desc,
                pol_remarks,
                pol_coinsure_pct,
                pol_renewed_rec,
                pol_renewable,
                pol_policy_cover_to,
                pol_policy_cover_from,
                pol_si_diff,
                pol_wtht,
                pol_prem_tax,
                pol_mar_cert_no,
                pol_coinsurance_share,
                pol_coin_tot_prem,
                pol_coin_endos_prem,
                pol_coin_tot_si,
                pol_renewal_dt,
                pol_prev_prem,
                pol_ri_agnt_agent_code,
                pol_ri_agnt_sht_desc,
                pol_ri_agent_comm_rate,
                pol_trans_eff_wet,
                pol_tot_tl,
                pol_tl,
                pol_coin_fee,
                pol_coin_fee_amt,
                pol_coin_policy_no,
                pol_annual_tl,
                pol_duties,
                pol_extras,
                pol_old_policy_no,
                pol_commission_allowed,
                pol_edp_batch,
                pol_pip_code,
                pol_tot_phfund,
                pol_phfund,
                pol_vat_amt,
                pol_vat_rate,
                pol_prem_computed,
                pol_bussiness_growth_type,
                pol_coin_leader_combined,
                pol_open_cover,
                pol_co_phfund,
                pol_policy_debit,
                pol_scheme_policy,
                pol_pro_interface_type,
                pol_freq_of_payment,
                pol_policy_doc,
                pol_health_tax,
                pol_road_safety_tax,
                pol_certchg,
                pol_motor_levy,
                pol_admin_fee_allowed,
                pol_pop_taxes,
                pol_debiting_type,
                pol_debt_owner,
                pol_credit_limit,
                pol_promise_date
            )
             VALUES (
                cur_pol_rec.pol_policy_no,
                v_ends_no,
                v_batch_no,
                cur_pol_rec.pol_agnt_agent_code,
                cur_pol_rec.pol_agnt_sht_desc,
                cur_pol_rec.pol_pmod_code,
                cur_pol_rec.pol_bind_code,
                v_wef,
                v_wet,
                TO_NUMBER (TO_CHAR (v_wef, 'RRRR')),
                cur_pol_rec.pol_total_sum_insured,
                'ME',
                NVL (cur_pol_rec.pol_comm_amt, 0),
                cur_pol_rec.pol_comm_rate,
                cur_pol_rec.pol_inception_dt,
                cur_pol_rec.pol_tran_type,
                cur_pol_rec.pol_acpr_code,
                cur_pol_rec.pol_acpr_sht_desc,
                cur_pol_rec.pol_alp_proposal_no,
                NVL (cur_pol_rec.pol_basic_premium, 0),
                NVL (cur_pol_rec.pol_nett_premium, 0),
                cur_pol_rec.pol_cur_code,
                v_user,
                TRUNC (SYSDATE),
                NULL,
                NULL,
                cur_pol_rec.pol_policy_type,
                cur_pol_rec.pol_conversion_rate,
                cur_pol_rec.pol_client_policy_number,
                cur_pol_rec.pol_brn_code,
                cur_pol_rec.pol_business_type,
                cur_pol_rec.pol_cur_rate,
                cur_pol_rec.pol_curr_rate_type,
                NVL (cur_pol_rec.pol_comm_endos_diff_amt, 0),
                NVL (cur_pol_rec.pol_total_fap, 0),
                NVL (cur_pol_rec.pol_total_gp, 0),
                cur_pol_rec.pol_tot_endos_diff_amt,
                cur_pol_rec.pol_coinsurance,
                cur_pol_rec.pol_coinsure_leader,
                cur_pol_rec.pol_fp,
                'N',
                NULL,
                cur_pol_rec.pol_cur_symbol,
                cur_pol_rec.pol_post_ok,
                cur_pol_rec.pol_brn_sht_desc,
                cur_pol_rec.pol_prp_code,
                'D',
                'R',
                cur_pol_rec.pol_cancel_dt,
                cur_pol_rec.pol_inception_uwyr,
                cur_pol_rec.pol_pro_code,
                cur_pol_rec.pol_btr_code,
                cur_pol_rec.pol_btr_trans_code,
                cur_pol_rec.pol_your_ref,
                cur_pol_rec.pol_prop_holding_co_prp_code,
                cur_pol_rec.pol_oth_int_parties,
                cur_pol_rec.pol_pro_sht_desc,
                v_old_batch,
                cur_pol_rec.pol_uwyr_length,
                cur_pol_rec.pol_binder_policy,
                cur_pol_rec.pol_bind_pro_code,
                cur_pol_rec.pol_bind_pro_sht_desc,
                cur_pol_rec.pol_remarks,
                cur_pol_rec.pol_coinsure_pct,
                cur_pol_rec.pol_renewed_rec,
                cur_pol_rec.pol_renewable,
                v_wet,
                v_wef,
                NVL (cur_pol_rec.pol_si_diff, 0),
                NVL (cur_pol_rec.pol_wtht, 0),
                cur_pol_rec.pol_prem_tax,
                cur_pol_rec.pol_mar_cert_no,
                cur_pol_rec.pol_coinsurance_share,
                cur_pol_rec.pol_coin_tot_prem,
                cur_pol_rec.pol_coin_endos_prem,
                cur_pol_rec.pol_coin_tot_si,
                v_ren_date,
                NVL (cur_pol_rec.pol_prev_prem, 0),
                cur_pol_rec.pol_ri_agnt_agent_code,
                cur_pol_rec.pol_ri_agnt_sht_desc,
                cur_pol_rec.pol_ri_agent_comm_rate,
                v_wet,
                cur_pol_rec.pol_tot_tl,
                cur_pol_rec.pol_tl,
                cur_pol_rec.pol_coin_fee,
                cur_pol_rec.pol_coin_fee_amt,
                cur_pol_rec.pol_coin_policy_no,
                cur_pol_rec.pol_annual_tl,
                cur_pol_rec.pol_duties,
                cur_pol_rec.pol_extras,
                cur_pol_rec.pol_old_policy_no,
                cur_pol_rec.pol_commission_allowed,
                cur_pol_rec.pol_edp_batch,
                 cur_pol_rec.pol_oth_int_parties,
                cur_pol_rec.pol_tot_phfund,
                cur_pol_rec.pol_phfund,
                cur_pol_rec.pol_vat_amt,
                cur_pol_rec.pol_vat_rate,
                'Y',
                gin_stp_uw_pkg.get_growth_type (
                    cur_pol_rec.pol_prp_code,
                    'EN',
                    cur_pol_rec.pol_policy_no,
                    v_batch_no
                ),
                cur_pol_rec.pol_coin_leader_combined,
                cur_pol_rec.pol_open_cover,
                cur_pol_rec.pol_co_phfund,
                cur_pol_rec.pol_policy_debit,
                cur_pol_rec.pol_scheme_policy,
                cur_pol_rec.pol_pro_interface_type,
                cur_pol_rec.pol_freq_of_payment,
                cur_pol_rec.pol_policy_doc,
                 cur_pol_rec.pol_health_tax,
                cur_pol_rec.pol_road_safety_tax,
                 cur_pol_rec.pol_certchg,
                cur_pol_rec.pol_motor_levy,
                cur_pol_rec.pol_admin_fee_allowed,
                'Y',
                 cur_pol_rec.pol_debiting_type,
                 cur_pol_rec.pol_debt_owner,
                 cur_pol_rec.pol_credit_limit,
                 cur_pol_rec.pol_promise_date
            );
        EXCEPTION
            WHEN OTHERS
            THEN
                ROLLBACK;
                raise_error (
                    ' Error creating policy endorsement record. Contact the system administrator...'
                );
        END;

        --OPEN CUR_TAXES
        FOR cur_tax_rec IN cur_taxes
        LOOP
            BEGIN
                pop_taxes (
                    cur_pol_rec.pol_policy_no,
                    v_ends_no,
                    v_old_batch,
                    cur_pol_rec.pol_pro_code,
                    'N',
                    'ME'
                );
            EXCEPTION
                WHEN OTHERS
                THEN
                    ROLLBACK;
                    raise_error (
                        ' Error creating policy tax record. Contact the system administrator...'
                    );
            END;
        END LOOP;

        /****** Insert FACRE IN Details ********/
        BEGIN
            SELECT TO_NUMBER (TO_CHAR (SYSDATE, 'YY') || ggt_trans_no_seq.NEXTVAL)
              INTO v_tran_no
              FROM DUAL;

            INSERT INTO gin_gis_transactions (
                ggt_trans_no,
                ggt_pol_policy_no,
                ggt_pol_batch_no,
                ggt_pro_sht_desc,
                ggt_btr_trans_code,
                ggt_done_by,
                ggt_client_policy_number,
                ggt_uw_clm_tran,
                ggt_trans_date,
                ggt_old_tran_no,
                ggt_effective_date
            )
                SELECT
                    v_tran_no,
                    cur_pol_rec.pol_policy_no,
                    v_batch_no,
                    cur_pol_rec.pol_pro_sht_desc,
                    'ME',
                    v_user,
                    cur_pol_rec.pol_client_policy_number,
                    'U',
                    TRUNC (SYSDATE),
                    ggt_old_tran_no,
                    NVL (v_eff_date, SYSDATE)
                  FROM gin_gis_transactions
                 WHERE     ggt_pol_batch_no = v_old_batch
                       AND ggt_uw_clm_tran = 'U';
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                ROLLBACK;
                raise_error (
                    'No previous record found for contra; policy No.'
                    || cur_pol_rec.pol_policy_no
                );
            WHEN OTHERS
            THEN
                ROLLBACK;
                raise_error (
                    'Unable to retrieve and create record for contra..'
                );
        END;

        BEGIN
            FOR cur_facre_dtls_rec IN cur_facre_dtls
            LOOP
                INSERT INTO gin_facre_in_dtls (
                    fid_pol_policy_no,
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
                    fid_cede_sign_dt
                )
                 VALUES (
                    cur_facre_dtls_rec.fid_pol_policy_no,
                    v_ends_no,
                    v_batch_no,
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
                    TO_NUMBER (TO_CHAR (SYSDATE, 'RRRR')) || gin_fid_code_seq.NEXTVAL,
                    cur_facre_dtls_rec.fid_cede_comp_policy_no,
                    cur_facre_dtls_rec.fid_cede_comp_term_frm,
                    cur_facre_dtls_rec.fid_cede_comp_term_to,
                    cur_facre_dtls_rec.fid_cede_company_ren_prem,
                    cur_facre_dtls_rec.fid_reins_term_to,
                    cur_facre_dtls_rec.fid_cede_sign_dt
                );
            END LOOP;
        EXCEPTION
            WHEN OTHERS
            THEN
                ROLLBACK;
                raise_error (' Unable to insert facre details...');
        END;

        /*insert facre details*/
        BEGIN
            v_tran_ref_no :=
                gin_sequences_pkg.get_number_format (
                    'BARCODE',
                    cur_pol_rec.pol_pro_code,
                    cur_pol_rec.pol_brn_code,
                    TO_NUMBER (TO_CHAR (SYSDATE, 'RRRR')),
                    'NB',
                    v_serialno
                );
        EXCEPTION
            WHEN OTHERS
            THEN
                raise_error (
                    'unable to generate transmittal number.Contact the system administrator...'
                );
        END;

        BEGIN
            SELECT    TO_NUMBER (TO_CHAR (SYSDATE, 'RRRR'))
                   || ggts_tran_no_seq.NEXTVAL
              INTO next_ggts_trans_no
              FROM DUAL;

            INSERT INTO gin_gis_transmitals (
                ggts_tran_no,
                ggts_pol_policy_no,
                ggts_cmb_claim_no,
                ggts_pol_batch_no,
                ggts_done_by,
                ggts_done_date,
                ggts_uw_clm_tran,
                ggts_pol_renewal_batch,
                ggts_tran_ref_no,
                ggts_ipay_alphanumeric
            )
                 VALUES (
                    next_ggts_trans_no,
                    cur_pol_rec.pol_policy_no,
                    NULL,
                    v_batch_no,
                    v_user,
                    SYSDATE,
                    'U',
                    NULL,
                    v_tran_ref_no,
                    'Y'
                );
        EXCEPTION
            WHEN OTHERS
            THEN
                raise_error (
                    'Error unable to creaete a transaction record. Contact the system administrator...'
                );
        END;

        FOR cur_coinsurer_rec IN cur_coinsurer
        LOOP
            --INSERT INTO GIN_COINSURERS
            BEGIN
                INSERT INTO gin_coinsurers (
                    coin_agnt_agent_code,
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
                    coin_commission,
                    coin_whtx,
                    coin_prem_tax,
                    coin_annual_prem,
                    coin_fee_type,
                    coin_aga_code,
                    coin_aga_sht_desc,
                    coin_com_disc_amt,
                    coin_vat_amt,
                    coin_optional_comm,
                    coin_comm_rate
                )
                  VALUES (
                    cur_coinsurer_rec.coin_agnt_agent_code,
                    cur_coinsurer_rec.coin_agnt_sht_desc,
                    cur_coinsurer_rec.coin_gl_code,
                    cur_coinsurer_rec.coin_lead,
                    cur_coinsurer_rec.coin_perct,
                    NVL (cur_coinsurer_rec.coin_prem, 0),
                    cur_coinsurer_rec.coin_pol_policy_no,
                    v_ends_no,
                    v_batch_no,
                    cur_coinsurer_rec.coin_fee_rate,
                    cur_coinsurer_rec.coin_fee_amt,
                    cur_coinsurer_rec.coin_duties,
                    cur_coinsurer_rec.coin_si,
                    cur_coinsurer_rec.coin_commission,
                    cur_coinsurer_rec.coin_whtx,
                    cur_coinsurer_rec.coin_prem_tax,
                    cur_coinsurer_rec.coin_annual_prem,
                    cur_coinsurer_rec.coin_fee_type,
                    cur_coinsurer_rec.coin_aga_code,
                    cur_coinsurer_rec.coin_aga_sht_desc,
                    cur_coinsurer_rec.coin_com_disc_amt,
                    cur_coinsurer_rec.coin_vat_amt,
                    cur_coinsurer_rec.coin_optional_comm,
                    cur_coinsurer_rec.coin_comm_rate
                );
            EXCEPTION
                WHEN OTHERS
                THEN
                    ROLLBACK;
                    raise_error (
                        '  Error creating policy coinsurance record. Contact the system administrator...'
                    );
            END;
        END LOOP;

        --OPEN CONDITIONS
        FOR cur_conditions_rec IN cur_conditions
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
                    plcl_heading
                )
                 VALUES (
                    cur_conditions_rec.plcl_sbcl_cls_code,
                    cur_conditions_rec.plcl_sbcl_scl_code,
                    cur_conditions_rec.plcl_pro_sht_desc,
                    cur_conditions_rec.plcl_pro_code,
                    cur_conditions_rec.plcl_pol_policy_no,
                    v_ends_no,
                    v_batch_no,
                    cur_conditions_rec.plcl_sbcl_cls_sht_desc,
                    cur_conditions_rec.plcl_cls_type,
                    cur_conditions_rec.plcl_clause,
                    cur_conditions_rec.plcl_cls_editable,
                    cur_conditions_rec.plcl_new,
                    cur_conditions_rec.plcl_heading
                );
            EXCEPTION
                WHEN OTHERS
                THEN
                    ROLLBACK;
                    raise_error (
                        '  Error creating policy clauses record. Contact the system administrator...'
                    );
            END;
        END LOOP;

        --OPEN cur_insureds
        FOR cur_insureds_rec IN cur_insureds
        LOOP
            BEGIN
                INSERT INTO gin_policy_insureds (
                    polin_code,
                    polin_pa,
                    polin_pol_policy_no,
                    polin_pol_ren_endos_no,
                    polin_pol_batch_no,
                    polin_category,
                    polin_prp_code
                )
                  VALUES (
                    TO_NUMBER (
                        TO_CHAR (SYSDATE, 'RRRR') || polin_code_seq.NEXTVAL
                    ),
                    NULL,
                    cur_pol_rec.pol_policy_no,
                    v_ends_no,
                    v_batch_no,
                    NULL,
                    cur_insureds_rec.polin_prp_code
                );
            EXCEPTION
                WHEN OTHERS
                THEN
                    ROLLBACK;
                    raise_error (
                        ' Error creating insureds record. Contact the system administrator...'
                    );
            END;

            FOR cur_ipu_rec IN cur_ipu (cur_insureds_rec.polin_code)
            LOOP
                SELECT TO_NUMBER (TO_CHAR (SYSDATE, 'RRRR') || gin_ipu_code_seq.NEXTVAL)
                  INTO v_new_ipu_code
                  FROM DUAL;

                -- DO YOUR INSERTS INTO ipu
                BEGIN
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
                        ipu_basic_premium,
                        ipu_nett_premium,
                        ipu_compulsory_excess,
                        ipu_add_theft_excess,
                        ipu_add_exp_excess,
                        ipu_prr_rate,
                        ipu_comp_retention,
                        ipu_pol_est_max_loss,
                        ipu_avail_fulc_bal,
                        ipu_endos_diff_amt,
                        ipu_prem_wef,
                        ipu_earth_quake_cover,
                        ipu_earth_quake_prem,
                        ipu_location,
                        ipu_itl,
                        ipu_polin_code,

```sql
                        ipu_sec_sect_code,
                        ipu_sect_sht_desc,
                        ipu_sec_scl_code,
                        ipu_ncd_status,
                        ipu_cert_issued,
                        ipu_related_ipu_code,
                        ipu_prorata,
                        ipu_bp,
                        ipu_gp,
                        ipu_fp,
                        ipu_fap,
                        ipu_prev_ipu_code,
                        ipu_cummulative_reins,
                        ipu_eml_si,
                        ipu_reinsured,
                        ipu_ct_code,
                        ipu_sht_desc,
                        ipu_quz_code,
                        ipp_quz_sht_desc,
                        ipu_quz_sht_desc,
                        ipu_ncl_level,
                        ipu_ncd_level,
                        ipu_id,
                        ipu_gross_comp_retention,
                        ipu_bind_code,
                        ipu_commission,
                        ipu_comm_endos_diff_amt,
                        ipu_facre_amount,
                        ipu_clp_code,
                        ipu_excess_rate,
                        ipu_excess_type,
                        ipu_excess_rate_type,
                        ipu_excess_min,
                        ipu_excess_max,
                        ipu_prereq_ipu_code,
                        ipu_escalation_rate,
                        ipu_endos_remove,
                        ipu_comm_rate,
                        ipu_prev_batch_no,
                        ipu_cur_code,
                        ipu_relr_code,
                        ipu_relr_sht_desc,
                        ipu_reinsure_amt,
                        ipu_prp_code,
                        ipu_max_exposure,
                        ipu_com_retention_rate,
                        ipu_retro_cover,
                        ipu_retro_wef,
                        ipu_eff_wef,
                        ipu_eff_wet,
                        ipu_comments,
                        ipu_covt_code,
                        ipu_covt_sht_desc,
                        ipu_si_diff,
                        ipu_terr_code,
                        ipu_terr_desc,
                        ipu_from_time,
                        ipu_to_time,
                        ipu_tot_endos_prem_dif,
                        ipu_tot_gp,
                        ipu_tot_value,
                        ipu_cover_days,
                        ipu_grp_si_risk_pct,
                        ipu_grp_top_loc,
                        ipu_grp_comp_gross_ret,
                        ipu_grp_comp_net_ret,
                        ipu_prev_prem,
                        ipu_ri_agnt_com_rate,
                        ipu_uw_yr,
                        ipu_status,
                        ipu_paid_tl,
                        ipu_paid_premium,
                        ipu_trans_count,
                        ipu_rate_change_comment,
                        ipu_prem_tax,
                        ipu_trans_eff_wet,
                        ipu_compute_max_exposure,
                        ipu_endose_fap_or_bc,
                        ipu_tot_first_loss,
                        ipu_accumulation_limit,
                        ipu_inception_uwyr,
                        ipu_eml_based_on,
                        ipu_aggregate_limits,
                        ipu_rc_sht_desc,
                        ipu_rc_code,
                        ipu_survey_date,
                        ipu_item_details,
                        ipu_contrad_ipu_code,
                        ipu_prev_tot_fap,
                        ipu_prev_fap,
                        ipu_override_ri_retention,
                        ipu_ri_agnt_comm_amt,
                        ipu_earthqke_prem_diff,
                         ipu_tot_fap,
                        ipu_coin_tl,
                        ipu_mktr_com_amt,
                        ipu_mktr_com_rate,
                        ipu_vat_rate,
                        ipu_vat_amt,
                         ipu_prev_status,
                        ipu_rs_code,
                         ipu_rescue_mem,
                         ipu_rescue_charge,
                         ipu_health_tax,
                         ipu_road_safety_tax,
                         ipu_certchg,
                         ipu_motor_levy,
                         ipu_maintenance_period_type,
                         ipu_maintenance_period,
                          ipu_other_client_deductibles,
                          ipu_coin_other_client_charges,
                         ipu_survey_agnt_code,
                         ipu_survey,
                         ipu_marine_type

                    )
                    VALUES (
                        v_new_ipu_code,
                        cur_ipu_rec.ipu_property_id,
                        cur_ipu_rec.ipu_item_desc,
                        cur_ipu_rec.ipu_qty,
                        NVL (cur_ipu_rec.ipu_value, 0),
                        v_wef,
                        v_wet,
                        cur_pol_rec.pol_policy_no,
                        v_ends_no,
                        v_batch_no,
                        NVL (cur_ipu_rec.ipu_basic_premium, 0),
                        NVL (cur_ipu_rec.ipu_nett_premium, 0),
                        cur_ipu_rec.ipu_compulsory_excess,
                        cur_ipu_rec.ipu_add_theft_excess,
                        cur_ipu_rec.ipu_add_exp_excess,
                        cur_ipu_rec.ipu_prr_rate,
                        NVL (cur_ipu_rec.ipu_comp_retention, 0),
                        cur_ipu_rec.ipu_pol_est_max_loss,
                        NVL (cur_ipu_rec.ipu_avail_fulc_bal, 0),
                        NVL (cur_ipu_rec.ipu_endos_diff_amt, 0),
                        v_wef,
                        cur_ipu_rec.ipu_earth_quake_cover,
                        cur_ipu_rec.ipu_earth_quake_prem,
                        cur_ipu_rec.ipu_location,
                        NVL (cur_ipu_rec.ipu_itl, 0),
                        TO_NUMBER (
                            TO_CHAR (SYSDATE, 'RRRR') || polin_code_seq.CURRVAL
                        ),
                        cur_ipu_rec.ipu_sec_sect_code,
                        cur_ipu_rec.ipu_sect_sht_desc,
                        cur_ipu_rec.ipu_sec_scl_code,
                        cur_ipu_rec.ipu_ncd_status,
                        cur_ipu_rec.ipu_cert_issued,
                        cur_ipu_rec.ipu_related_ipu_code,
                        cur_ipu_rec.ipu_prorata,
                        NVL (cur_ipu_rec.ipu_bp, 0),
                        NVL (cur_ipu_rec.ipu_gp, 0),
                        NULL,
                        NVL (cur_ipu_rec.ipu_fap, 0),
                        cur_ipu_rec.ipu_prev_ipu_code,
                        cur_ipu_rec.ipu_cummulative_reins,
                        cur_ipu_rec.ipu_eml_si,
                        1,
                        cur_ipu_rec.ipu_ct_code,
                        cur_ipu_rec.ipu_sht_desc,
                        cur_ipu_rec.ipu_quz_code,
                        cur_ipu_rec.ipp_quz_sht_desc,
                        cur_ipu_rec.ipu_quz_sht_desc,
                        cur_ipu_rec.ipu_ncl_level,
                        cur_ipu_rec.ipu_ncd_level,
                        cur_ipu_rec.ipu_id,
                        NVL (cur_ipu_rec.ipu_gross_comp_retention, 0),
                        cur_ipu_rec.ipu_bind_code,
                        NVL (cur_ipu_rec.ipu_commission, 0),
                        NVL (cur_ipu_rec.ipu_comm_endos_diff_amt, 0),
                        NVL (cur_ipu_rec.ipu_facre_amount, 0),
                        cur_ipu_rec.ipu_clp_code,
                        cur_ipu_rec.ipu_excess_rate,
                        cur_ipu_rec.ipu_excess_type,
                        cur_ipu_rec.ipu_excess_rate_type,
                        cur_ipu_rec.ipu_excess_min,
                        cur_ipu_rec.ipu_excess_max,
                        cur_ipu_rec.ipu_prereq_ipu_code,
                        cur_ipu_rec.ipu_escalation_rate,
                        cur_ipu_rec.ipu_endos_remove,
                        cur_ipu_rec.ipu_comm_rate,
                        cur_ipu_rec.ipu_prev_batch_no,
                        cur_ipu_rec.ipu_cur_code,
                        cur_ipu_rec.ipu_relr_code,
                        cur_ipu_rec.ipu_relr_sht_desc,
                        NVL (cur_ipu_rec.ipu_reinsure_amt, 0),
                        cur_ipu_rec.ipu_prp_code,
                        NVL (cur_ipu_rec.ipu_max_exposure, 0),
                        cur_ipu_rec.ipu_com_retention_rate,
                        cur_ipu_rec.ipu_retro_cover,
                        cur_ipu_rec.ipu_retro_wef,
                        v_wef,
                        v_wet,
                        cur_ipu_rec.ipu_comments,
                        cur_ipu_rec.ipu_covt_code,
                        cur_ipu_rec.ipu_covt_sht_desc,
                        NVL (cur_ipu_rec.ipu_si_diff, 0),
                        cur_ipu_rec.ipu_terr_code,
                        cur_ipu_rec.ipu_terr_desc,
                        cur_ipu_rec.ipu_from_time,
                        cur_ipu_rec.ipu_to_time,
                        NVL (cur_ipu_rec.ipu_tot_endos_prem_dif, 0),
                        NVL (cur_ipu_rec.ipu_tot_gp, 0),
                        NVL (cur_ipu_rec.ipu_tot_value, 0),
                        cur_ipu_rec.ipu_cover_days,
                        cur_ipu_rec.ipu_grp_si_risk_pct,
                        NVL (cur_ipu_rec.ipu_grp_top_loc, 0),
                        NVL (cur_ipu_rec.ipu_grp_comp_gross_ret, 0),
                        NVL (cur_ipu_rec.ipu_grp_comp_net_ret, 0),
                        NVL (cur_ipu_rec.ipu_prev_prem, 0),
                        cur_ipu_rec.ipu_ri_agnt_com_rate,
                         TO_NUMBER (TO_CHAR (v_wef, 'RRRR')),
                        cur_ipu_rec.ipu_status,
                        NVL (cur_ipu_rec.ipu_paid_tl, 0),
                        NVL (cur_ipu_rec.ipu_paid_premium, 0),
                        NVL (cur_ipu_rec.ipu_trans_count, 0) + 1,
                        cur_ipu_rec.ipu_rate_change_comment,
                         NVL (cur_ipu_rec.ipu_prem_tax, 0),
                         v_wet,
                         cur_ipu_rec.ipu_compute_max_exposure,
                         cur_ipu_rec.ipu_endose_fap_or_bc,
                           NVL(cur_ipu_rec.ipu_tot_first_loss,0),
                           NVL(cur_ipu_rec.ipu_accumulation_limit,0),
                           cur_ipu_rec.ipu_inception_uwyr,
                          cur_ipu_rec.ipu_eml_based_on,
                          cur_ipu_rec.ipu_aggregate_limits,
                           cur_ipu_rec.ipu_rc_sht_desc,
                           cur_ipu_rec.ipu_rc_code,
                           cur_ipu_rec.ipu_survey_date,
                            cur_ipu_rec.ipu_item_details,
                           cur_ipu_rec.ipu_code,
                             NVL (cur_ipu_rec.ipu_prev_tot_fap, 0),
                             NVL (cur_ipu_rec.ipu_prev_fap, 0),
                             cur_ipu_rec.ipu_override_ri_retention,
                             cur_ipu_rec.ipu_ri_agnt_comm_amt,
                             cur_ipu_rec.ipu_earthqke_prem_diff,
                               cur_ipu_rec.ipu_tot_fap,
                               cur_ipu_rec.ipu_coin_tl,
                               cur_ipu_rec.ipu_mktr_com_amt,
                                cur_ipu_rec.ipu_mktr_com_rate,
                                cur_ipu_rec.ipu_vat_rate,
                                cur_ipu_rec.ipu_vat_amt,
                                 cur_ipu_rec.ipu_status,
                                cur_ipu_rec.ipu_rs_code,
                                cur_ipu_rec.ipu_rescue_mem,
                                cur_ipu_rec.ipu_rescue_charge,
                                 cur_ipu_rec.ipu_health_tax,
                                  cur_ipu_rec.ipu_road_safety_tax,
                                   cur_ipu_rec.ipu_certchg,
                                  cur_ipu_rec.ipu_motor_levy,
                                  cur_ipu_rec.ipu_maintenance_period_type,
                                   cur_ipu_rec.ipu_maintenance_period,
                                   cur_ipu_rec.ipu_other_client_deductibles,
                                  cur_ipu_rec.ipu_coin_other_client_charges,
                                    cur_ipu_rec.ipu_survey_agnt_code,
                                    cur_ipu_rec.ipu_survey,
                                    cur_ipu_rec.ipu_marine_type
                    );
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        ROLLBACK;
                        raise_error (
                            ' Error creating risk contra record. Contact the system administrator...'
                        );
                END;

                --OPEN LIMITS
                FOR cur_limits_rec IN cur_limits (cur_ipu_rec.ipu_code)
                LOOP
                    -- DO YOUR INSERTS INTO limits
                    BEGIN
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
                            pil_comment,
                            pil_multiplier_rate,
                            pil_multiplier_div_factor,
                            pil_annual_premium,
                            pil_rate_div_fact,
                            pil_min_premium,
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
                            pil_declaration_section,
                            pil_prev_limit,
                            pil_actual_prem,
                            pil_prev_prem_prorata,
                            pil_annual_actual_prem,
                            pil_eml_pct,
                            pil_top_loc_rate,
                            pil_top_loc_div_fact,
                            pil_limit_prd,
                            pil_free_limit,
                             pil_prev_endr_prem_rate,
                            pil_prev_endr_rate_div_fact,
                             pil_prev_endr_mult_rate,
                             pil_prev_endr_mult_div_fact,
                            pil_expired,
                            pil_firstloss,
                             pil_firstloss_amt_pcnt,
                             pil_firstloss_value
                        )
                         VALUES (
                            TO_NUMBER (
                                TO_CHAR (SYSDATE, 'RRRR') || gin_pil_code_seq.NEXTVAL
                            ),
                            v_new_ipu_code,
                            cur_limits_rec.pil_sect_code,
                            cur_limits_rec.pil_sect_sht_desc,
                            cur_limits_rec.pil_row_num,
                            cur_limits_rec.pil_calc_group,
                            NVL (cur_limits_rec.pil_limit_amt, 0),
                            cur_limits_rec.pil_prem_rate,
                            NVL (cur_limits_rec.pil_prem_amt, 0),
                            cur_limits_rec.pil_rate_type,
                            cur_limits_rec.pil_rate_desc,
                            cur_limits_rec.pil_sect_type,
                            cur_limits_rec.pil_sect_excess_detail,
                            cur_limits_rec.pil_original_prem_rate,
                            cur_limits_rec.pil_rate_change_remarks,
                            cur_limits_rec.pil_change_done_by,
                            cur_limits_rec.pil_comment,
                            cur_limits_rec.pil_multiplier_rate,
                            cur_limits_rec.pil_multiplier_div_factor,
                            NVL (cur_limits_rec.pil_annual_premium, 0),
                            cur_limits_rec.pil_rate_div_fact,
                            NVL (cur_limits_rec.pil_min_premium, 0),
                            cur_limits_rec.pil_desc,
                            cur_limits_rec.pil_compute,
                            NVL (cur_limits_rec.pil_used_limit, 0),
                            cur_limits_rec.pil_indem_prd,
                            cur_limits_rec.pil_prd_type,
                            cur_limits_rec.pil_indem_fstprd,
                            cur_limits_rec.pil_indem_fstprd_pct,
                            cur_limits_rec.pil_indem_remprd_pct,
                            cur_limits_rec.pil_dual_basis,
                            NVL (cur_limits_rec.pil_prem_accumulation, 0),
                            cur_limits_rec.pil_declaration_section,
                            NVL (cur_limits_rec.pil_prev_limit, 0),
                            NVL (cur_limits_rec.pil_actual_prem, 0),
                            NVL (cur_limits_rec.pil_prev_prem_prorata, 0),
                            NVL (cur_limits_rec.pil_annual_actual_prem, 0),
                            cur_limits_rec.pil_eml_pct,
                            cur_limits_rec.pil_top_loc_rate,
                            cur_limits_rec.pil_top_loc_div_fact,
                            cur_limits_rec.pil_limit_prd,
                            cur_limits_rec.pil_free_limit,
                             cur_limits_rec.pil_prem_rate,
                              cur_limits_rec.pil_rate_div_fact,
                               cur_limits_rec.pil_multiplier_rate,
                                 cur_limits_rec.pil_multiplier_div_factor,
                            cur_limits_rec.pil_expired,
                             cur_limits_rec.pil_firstloss,
                             cur_limits_rec.pil_firstloss_amt_pcnt,
                               cur_limits_rec.pil_firstloss_value
                        );
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            ROLLBACK;
                            raise_error (
                                '  Error creating risk section record. Contact the system administrator...'
                            );
                    END;
                END LOOP;

                --OPEN CLAUSES
                FOR cur_clauses_rec IN cur_clauses (cur_ipu_rec.ipu_code)
                LOOP
                    -- DO YOUR INSERTS INTO clauses
                    BEGIN
                        INSERT INTO gin_policy_clauses (
                            pocl_sbcl_cls_code,
                            pocl_sbcl_scl_code,
                            pocl_cls_sht_desc,
                            pocl_pol_policy_no,
                            pocl_pol_ren_endos_no,
                            pocl_pol_batch_no,
                            pocl_ipu_code,
                            plcl_cls_type,
                            pocl_clause,
                            pocl_cls_editable,
                            pocl_new,
                            pocl_heading
                        )
                         VALUES (
                            cur_clauses_rec.pocl_sbcl_cls_code,
                            cur_clauses_rec.pocl_sbcl_scl_code,
                            cur_clauses_rec.pocl_cls_sht_desc,
                            cur_pol_rec.pol_policy_no,
                            v_ends_no,
                            v_batch_no,
                            v_new_ipu_code,
                            cur_clauses_rec.plcl_cls_type,
                            cur_clauses_rec.pocl_clause,
                            cur_clauses_rec.pocl_cls_editable,
                            cur_clauses_rec.pocl_new,
                            cur_clauses_rec.pocl_heading
                        );
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            ROLLBACK;
                            raise_error (
                                '  Error creating risk clauses record. Contact the system administrator...'
                            );
                    END;
                END LOOP;

                FOR cur_perils_rec IN perils (cur_ipu_rec.ipu_code)
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
                            gpsp_excess_amt
                        )
                         VALUES (
                            cur_perils_rec.gpsp_per_code,
                            cur_perils_rec.gpsp_per_sht_desc,
                            cur_perils_rec.gpsp_sec_sect_code,
                            cur_perils_rec.gpsp_sect_sht_desc,
                            cur_perils_rec.gpsp_sec_scl_code,
                            cur_perils_rec.gpsp_ipp_code,
                            v_new_ipu_code,
                            cur_perils_rec.gpsp_limit_amt,
                            cur_perils_rec.gpsp_excess_amt
                        );
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            ROLLBACK;
                            raise_error (
                                '  Error creating risk perils record. Contact the system administrator...'
                            );
                    END;
                END LOOP;

                FOR risk_excesses_rec IN risk_excesses (cur_ipu_rec.ipu_code)
                LOOP
                    BEGIN
                        INSERT INTO gin_risk_excess (
                            re_ipu_code,
                            re_excess_rate,
                            re_excess_type,
                            re_excess_rate_type,
                            re_excess_min,
                            re_excess_max,
                            re_comments
                        )
                          VALUES (
                            v_new_ipu_code,
                            risk_excesses_rec.re_excess_rate,
                            risk_excesses_rec.re_excess_type,
                            risk_excesses_rec.re_excess_rate_type,
                            risk_excesses_rec.re_excess_min,
                            risk_excesses_rec.re_excess_max,
                            risk_excesses_rec.re_comments
                        );
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            raise_error (
                                '  Error creating risk excess record. Contact the system administrator...'
                            );
                    END;
                END LOOP;

                FOR schedules_rec IN schedules (cur_ipu_rec.ipu_code)
                LOOP
                    BEGIN
                        INSERT INTO gin_policy_risk_schedules (
                            polrs_code,
                            polrs_ipu_code,
                            polrs_pol_batch_no,
                            polrs_schedule
                        )
                         VALUES (
                            TO_NUMBER (
                                TO_CHAR (SYSDATE, 'RRRR') || gin_polrs_code_seq.NEXTVAL
                            ),
                            v_new_ipu_code,
                            v_batch_no,
                            schedules_rec.polrs_schedule
                        );
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            ROLLBACK;
                            raise_error (
                                ' Error creating risk schedules record. Contact the system administrator...'
                            );
                    END;
                END LOOP;
            END LOOP;
        END LOOP;
    END LOOP;
END;
/

```