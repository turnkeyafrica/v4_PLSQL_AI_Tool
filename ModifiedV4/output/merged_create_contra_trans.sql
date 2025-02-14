```sql
PROCEDURE create_contra_trans (v_old_batch   IN     NUMBER,
                                   v_batch_no       OUT NUMBER,
                                   v_user        IN     VARCHAR2,
                                   v_eff_date    IN     DATE)
    IS
        v_serial         NUMBER (10);
        v_pol_no         VARCHAR2 (26);
        v_ends_no        VARCHAR2 (26);
        --next_ggt_trans_no number;
        v_pol_prefix     VARCHAR2 (15);
        v_new_ipu_code   NUMBER;
        vdummy           NUMBER;
        v_tran_no        NUMBER;
        v_prrd_code      NUMBER;
        v_pdl_code       NUMBER;
        v_count_contra   NUMBER;

        CURSOR cur_pol IS
            SELECT *
              FROM gin_policies
             WHERE pol_batch_no = v_old_batch;

        CURSOR cur_taxes IS
            SELECT *
              FROM gin_policy_taxes
             WHERE ptx_pol_batch_no = v_old_batch;

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

        CURSOR cur_ipu (v_polin_code NUMBER)
        IS
            SELECT *
              FROM gin_insured_property_unds
             WHERE     ipu_pol_batch_no = v_old_batch
                   AND ipu_polin_code = v_polin_code;

        CURSOR cur_rsk_perils (v_ipu VARCHAR2)
        IS
            SELECT *
              FROM gin_pol_risk_section_perils
             WHERE prspr_ipu_code = v_ipu;

        CURSOR cur_limits (v_ipu NUMBER)
        IS
            SELECT *
              FROM gin_policy_insured_limits
             WHERE pil_ipu_code = v_ipu;

        CURSOR cur_clauses (v_ipu NUMBER)
        IS
            SELECT *
              FROM gin_policy_clauses
             WHERE pocl_ipu_code = v_ipu;

        CURSOR perils (v_ipu NUMBER)
        IS
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

        CURSOR risk_excesses (v_ipu NUMBER)
        IS
            SELECT *
              FROM gin_risk_excess
             WHERE re_ipu_code = v_ipu;

        CURSOR schedules (v_ipu NUMBER)
        IS
            SELECT *
              FROM gin_policy_risk_schedules
             WHERE polrs_ipu_code = v_ipu;

        CURSOR cur_prrd (v_cur_prrd NUMBER)
        IS
            SELECT *
              FROM gin_policy_risk_ri_dtls
             WHERE prrd_code = v_cur_prrd;

        CURSOR cur_facre (v_prrd NUMBER)
        IS
            SELECT *
              FROM gin_facre_cessions
             WHERE fc_prrd_code = v_prrd;

        CURSOR cur_pool (v_prrd NUMBER)
        IS
            SELECT *
              FROM gin_pol_rein_pool_risk_details
             WHERE prprd_prrd_code = v_prrd;

        CURSOR cur_rein (v_prrd NUMBER)
        IS
            SELECT *
              FROM gin_policy_rein_risk_details
             WHERE ptotr_prrd_code = v_prrd;

        CURSOR cur_part (v_ptotr NUMBER)
        IS
            SELECT *
              FROM gin_participations
             WHERE part_ptotr_code = v_ptotr;

        CURSOR cur_rcpt IS
            SELECT *
              FROM gin_prem_receipts
             WHERE prm_pol_batch_no = v_old_batch;

        CURSOR cur_pol_sbu_dtls IS
            SELECT *
              FROM gin_policy_sbu_dtls
             WHERE pdl_pol_batch_no = v_old_batch;

        CURSOR cur_riskcommissions (v_ipu NUMBER)
        IS
            SELECT *
              FROM gin_policy_risk_commissions
             WHERE prc_ipu_code = v_ipu;
    BEGIN
        IF v_old_batch IS NULL
        THEN
            raise_error ('Select old transaction!!...');
        END IF;

        IF v_user IS NULL
        THEN
            raise_error ('User not defined.');
        END IF;

        FOR cur_pol_rec IN cur_pol
        LOOP
            BEGIN
                SELECT COUNT ('X')
                  INTO vdummy
                  FROM gin_claim_master_bookings
                 WHERE     cmb_pol_batch_no = v_old_batch
                       AND NVL (cmb_claim_status, 'B') NOT IN ('U', 'N');
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error (
                        'Error checking claim on the transaction to contra..');
            END;

            IF vdummy > 0
            THEN
                BEGIN
                    vdummy := 0;

                    SELECT COUNT ('X')
                      INTO vdummy
                      FROM gin_claim_master_bookings
                     WHERE     cmb_pol_batch_no = v_old_batch
                           AND NVL (cmb_claim_status, 'N') != 'U';
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error (
                            'Error checking claims contras on the transaction to contra..');
                END;

                IF NVL (vdummy, 0) > 0
                THEN
                    BEGIN
                        UPDATE gin_claim_master_bookings
                           SET cmb_claim_status = 'U'
                         WHERE     cmb_pol_batch_no = v_old_batch
                               AND NVL (cmb_claim_status, 'N') != 'U';
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            raise_error (
                                'Error updating claim on policy record..');
                    END;
                END IF;
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
                        || ' is not defined in the setup');
                END IF;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    ROLLBACK;
                    raise_error (
                           'The product '
                        || cur_pol_rec.pol_pro_sht_desc
                        || ' is not defined in the setup');
                WHEN OTHERS
                THEN
                    ROLLBACK;
                    raise_error (
                           'Unable to retrieve the policy prefix for the product '
                        || cur_pol_rec.pol_pro_sht_desc);
            END;

            IF cur_pol_rec.pol_policy_type = 'N'
            THEN
                v_ends_no :=
                    gin_sequences_pkg.get_number_format (
                        'E',
                        cur_pol_rec.pol_pro_code,
                        cur_pol_rec.pol_brn_code,
                        TO_NUMBER (TO_CHAR (SYSDATE, 'RRRR')),
                        'CO',
                        v_serial,
                        'N',
                        cur_pol_rec.pol_policy_no);
            ELSE
                v_ends_no :=
                    gin_sequences_pkg.get_number_format (
                        'ER',
                        cur_pol_rec.pol_pro_code,
                        cur_pol_rec.pol_brn_code,
                        TO_NUMBER (TO_CHAR (SYSDATE, 'RRRR')),
                        'CO',
                        v_serial,
                        'N',
                        cur_pol_rec.pol_policy_no);
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
            
            IF cur_pol_rec.pol_policy_debit = 'Y'
            THEN
                BEGIN
                    SELECT COUNT(1)
                        INTO v_count_contra
                    FROM gin_policies 
                        WHERE pol_policy_no=cur_pol_rec.pol_policy_no
                            AND POL_PREV_BATCH_NO=v_old_batch
                            AND POL_POLICY_STATUS ='CO';
                EXCEPTION
                WHEN OTHERS
                THEN
                    v_count_contra :=0;
                END;
            END IF;
            IF NVL (v_count_contra, 0) > 0
            THEN
                RAISE_ERROR('ERROR : System trying to duplicate Contra transaction on the same policy. ');
            END IF;

            SELECT    TO_NUMBER (TO_CHAR (SYSDATE, 'RRRR'))
                   || gin_pol_batch_no_seq.NEXTVAL
              INTO v_batch_no
              FROM DUAL;

            --Insert intO policies table
            BEGIN
                INSERT INTO gin_policies (pol_policy_no,
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
                                          pol_policy_doc,
                                          pol_pro_interface_type,
                                          pol_health_tax,
                                          pol_road_safety_tax,
                                          pol_certchg,
                                          pol_motor_levy,
                                          pol_client_vat_amt,
                                          pol_cr_date_notified,
                                          pol_cr_note_number,
                                          pol_admin_fee_allowed,
                                          pol_cashback_appl,
                                          pol_uw_only,
                                          pol_debiting_type,
                                          pol_lta_comm_amt,
                                          pol_lta_wtht,
                                          pol_other_client_deductibles,
                                          pol_coin_other_client_charges,
                                          pol_div_code)
                     VALUES (cur_pol_rec.pol_policy_no,
                             v_ends_no,
                             v_batch_no,
                             cur_pol_rec.pol_agnt_agent_code,
                             cur_pol_rec.pol_agnt_sht_desc,
                             cur_pol_rec.pol_pmod_code,
                             cur_pol_rec.pol_bind_code,
                             cur_pol_rec.pol_wef_dt,
                             cur_pol_rec.pol_wet_dt,
                             cur_pol_rec.pol_uw_year,
                             cur_pol_rec.pol_total_sum_insured,
                             'CO',
                             -NVL (cur_pol_rec.pol_comm_amt, 0),
                             cur_pol_rec.pol_comm_rate,
                             cur_pol_rec.pol_inception_dt,
                             cur_pol_rec.pol_tran_type,
                             cur_pol_rec.pol_acpr_code,
                             cur_pol_rec.pol_acpr_sht_desc,
                             cur_pol_rec.pol_alp_proposal_no,
                             -NVL (cur_pol_rec.pol_basic_premium, 0),
                             -NVL (cur_pol_rec.pol_nett_premium, 0),
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
                             -NVL (cur_pol_rec.pol_comm_endos_diff_amt, 0),
                             -NVL (cur_pol_rec.pol_total_fap, 0),
                             -NVL (cur_pol_rec.pol_total_gp, 0),
                             -cur_pol_rec.pol_tot_endos_diff_amt,
                             cur_pol_rec.pol_coinsurance,
                             cur_pol_rec.pol_coinsure_leader,
                             -cur_pol_rec.pol_fp,
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
                             cur_pol_rec.pol_policy_cover_to,
                             cur_pol_rec.pol_policy_cover_from,
                             -NVL (cur_pol_rec.pol_si_diff, 0),
                             -NVL (cur_pol_rec.pol_wtht, 0),
                             -cur_pol_rec.pol_prem_tax,
                             cur_pol_rec.pol_mar_cert_no,
                             cur_pol_rec.pol_coinsurance_share,
                             -cur_pol_rec.pol_coin_tot_prem,
                             -cur_pol_rec.pol_coin_endos_prem,
                             -cur_pol_rec.pol_coin_tot_si,
                             cur_pol_rec.pol_renewal_dt,
                             -NVL (cur_pol_rec.pol_prev_prem, 0),
                             cur_pol_rec.pol_ri_agnt_agent_code,
                             cur_pol_rec.pol_ri_agnt_sht_desc,
                             cur_pol_rec.pol_ri_agent_comm_rate,
                             cur_pol_rec.pol_trans_eff_wet,
                             -cur_pol_rec.pol_tot_tl,
                             -cur_pol_rec.pol_tl,
                             -cur_pol_rec.pol_coin_fee,
                             -cur_pol_rec.pol_coin_fee_amt,
                             cur_pol_rec.pol_coin_policy_no,
                             -cur_pol_rec.pol_annual_tl,
                             -cur_pol_rec.pol_duties,
                             -cur_pol_rec.pol_extras,
                             cur_pol_rec.pol_old_policy_no,
                             cur_pol_rec.pol_commission_allowed,
                             cur_pol_rec.pol_edp_batch,
                             cur_pol_rec.pol_pip_code,
                             -cur_pol_rec.pol_tot_phfund,
                             -cur_pol_rec.pol_phfund,
                             -cur_pol_rec.pol_vat_amt,
                             cur_pol_rec.pol_vat_rate,
                             'Y',
                             gin_stp_uw_pkg.get_growth_type (
                                 cur_pol_rec.pol_prp_code,
                                 'CO',
                                 cur_pol_rec.pol_policy_no,
                                 v_batch_no),
                             cur_pol_rec.pol_coin_leader_combined,
                             cur_pol_rec.pol_open_cover,
                             -cur_pol_rec.pol_co_phfund,
                             cur_pol_rec.pol_policy_debit,
                             cur_pol_rec.pol_scheme_policy,
                             cur_pol_rec.pol_policy_doc,
                             cur_pol_rec.pol_pro_interface_type,
                             -cur_pol_rec.pol_health_tax,
                             -cur_pol_rec.pol_road_safety_tax,
                             -cur_pol_rec.pol_certchg,
                             -cur_pol_rec.pol_motor_levy,
                             -cur_pol_rec.pol_client_vat_amt,
                             cur_pol_rec.pol_cr_date_notified,
                             cur_pol_rec.pol_cr_note_number,
                             cur_pol_rec.pol_admin_fee_allowed,
                             cur_pol_rec.pol_cashback_appl,
                             cur_pol_rec.pol_uw_only,
                             cur_pol_rec.pol_debiting_type,
                             -cur_pol_rec.pol_lta_comm_amt,
                             -cur_pol_rec.pol_lta_wtht,
                            -cur_pol_rec.pol_other_client_deductibles,
                            -cur_pol_rec.pol_coin_other_client_charges,
                             cur_pol_rec.pol_div_code);
            EXCEPTION
                WHEN OTHERS
                THEN
                    ROLLBACK;
                    raise_error (
                           ' Error creating policy endorsement record. Contact the system administrator...2'
                        || v_ends_no
                        || '==='
                        || v_serial);
            END;

            --OPEN CUR_TAXES
            FOR cur_tax_rec IN cur_taxes
            LOOP
                --INSERTING INTO GIN_POLICY_TAXES
                BEGIN
                    INSERT INTO gin_policy_taxes (
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
                                    ptx_trac_scl_code,
                                     ptx_coin_other_client_chrgs,
                                    ptx_override,
                                    ptx_override_amt)
                         VALUES (cur_tax_rec.ptx_trac_trnt_code,
                                 cur_tax_rec.ptx_pol_policy_no,
                                 v_ends_no,
                                 v_batch_no,
                                 cur_tax_rec.ptx_rate,
                                 -NVL (cur_tax_rec.ptx_amount, 0),
                                 cur_tax_rec.ptx_tl_lvl_code,
                                 cur_tax_rec.ptx_rate_type,
                                 cur_tax_rec.ptx_rate_desc,
                                 -cur_tax_rec.ptx_endos_diff_amt,
                                 cur_tax_rec.ptx_tax_type,
                                 cur_tax_rec.ptx_trac_scl_code,
                                  -cur_tax_rec.ptx_coin_other_client_chrgs,
                                 cur_tax_rec.ptx_override,
                                -cur_tax_rec.ptx_override_amt);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        ROLLBACK;
                        raise_error (
                            ' Error creating policy tax record. Contact the system administrator...');
                END;
            END LOOP;                                            --cur_tax_rec

            /****** Insert FACRE IN Details ********/
            BEGIN
                SELECT TO_NUMBER (
                              TO_CHAR (SYSDATE, 'YY')
                           || ggt_trans_no_seq.NEXTVAL)
                  INTO v_tran_no
                  FROM DUAL;

                INSERT INTO gin_gis_transactions (ggt_trans_no,
                                                  ggt_pol_policy_no,
                                                  ggt_pol_batch_no,
                                                  ggt_pro_sht_desc,
                                                  ggt_btr_trans_code,
                                                  ggt_done_by,
                                                  ggt_client_policy_number,
                                                  ggt_uw_clm_tran,
                                                  ggt_trans_date,
                                                  ggt_old_tran_no,
                                                  ggt_effective_date)
                    SELECT v_tran_no,
                           cur_pol_rec.pol_policy_no,
                           v_batch_no,
                           cur_pol_rec.pol_pro_sht_desc,
                           'CO',
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
                        || cur_pol_rec.pol_policy_no);
                WHEN OTHERS
                THEN
                    ROLLBACK;
                    raise_error (
                        'Unable to retrieve and create record for contra..');
            END;

            FOR cur_pol_sbu_rec IN cur_pol_sbu_dtls
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
                                 v_batch_no,
                                 cur_pol_sbu_rec.pdl_unit_code,
                                 cur_pol_sbu_rec.pdl_location_code,
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

            BEGIN
                FOR cur_facre_dtls_rec IN cur_facre_dtls
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
                                           TO_NUMBER (
                                               TO_CHAR (SYSDATE, 'RRRR'))
                                        || gin_fid_code_seq.NEXTVAL,
                                        cur_facre_dtls_rec.fid_cede_comp_policy_no,
                                        cur_facre_dtls_rec.fid_cede_comp_term_frm,
                                        cur_facre_dtls_rec.fid_cede_comp_term_to,
                                        cur_facre_dtls_rec.fid_cede_company_ren_prem,
                                        cur_facre_dtls_rec.fid_reins_term_to,
                                        cur_facre_dtls_rec.fid_cede_sign_dt);
                END LOOP;                                 --cur_facre_dtls_rec
            EXCEPTION
                WHEN OTHERS
                THEN
                    ROLLBACK;
                    raise_error (' Unable to insert facre details...');
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
                                    coin_comm_rate,
                                     coin_other_client_deductibles,
                                    coin_premium_tax)
                             VALUES (
                                        cur_coinsurer_rec.coin_agnt_agent_code,
                                        cur_coinsurer_rec.coin_agnt_sht_desc,
                                        cur_coinsurer_rec.coin_gl_code,
                                        cur_coinsurer_rec.coin_lead,
                                        cur_coinsurer_rec.coin_perct,
                                        -NVL (cur_coinsurer_rec.coin_prem, 0),
                                        cur_coinsurer_rec.coin_pol_policy_no,
                                        v_ends_no,
                                        v_batch_no,
                                        cur_coinsurer_rec.coin_fee_rate,
                                        -cur_coinsurer_rec.coin_fee_amt,
                                        -cur_coinsurer_rec.coin_duties,
                                        -cur_coinsurer_rec.coin_si,
                                        -cur_coinsurer

```sql
                                 rec.coin_commission,
                                        -cur_coinsurer_rec.coin_whtx,
                                        -cur_coinsurer_rec.coin_prem_tax,
                                        -cur_coinsurer_rec.coin_annual_prem,
                                        cur_coinsurer_rec.coin_fee_type,
                                        cur_coinsurer_rec.coin_aga_code,
                                        cur_coinsurer_rec.coin_aga_sht_desc,
                                        -cur_coinsurer_rec.coin_com_disc_amt,
                                        -cur_coinsurer_rec.coin_vat_amt,
                                        cur_coinsurer_rec.coin_optional_comm,
                                        -cur_coinsurer_rec.coin_comm_rate,
                                         -cur_coinsurer_rec.coin_other_client_deductibles,
                                        -cur_coinsurer_rec.coin_premium_tax);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        ROLLBACK;
                        raise_error (
                            '  Error creating policy coinsurance record. Contact the system administrator...');
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
                                    plcl_heading)
                         VALUES (cur_conditions_rec.plcl_sbcl_cls_code,
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
                                 cur_conditions_rec.plcl_heading);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        ROLLBACK;
                        raise_error (
                            '  Error creating policy clauses record. Contact the system administrator...');
                END;
            END LOOP;

            FOR cur_rctp_rec IN cur_rcpt
            LOOP
                INSERT INTO gin_prem_receipts (prm_code,
                                               prm_trans_no,
                                               prm_date,
                                               prm_cheque_no,
                                               prm_amt,
                                               prm_pol_batch_no,
                                               prm_pol_policy_no,
                                               prm_receipt_no,
                                               prm_receipt_date,
                                               prm_allocated_amt,
                                               prm_refund_amt,
                                               prm_pay_method,
                                               prm_prem_pymt_amt,
                                               prm_remarks,
                                               prm_authorised,
                                               prm_authorised_by,
                                               prm_prem_comm,
                                               prm_pens_comm,
                                               prm_chk_comm,
                                               prm_prem_tax,
                                               prm_drcr,
                                               prm_status,
                                               prm_done_by,
                                               prm_fully_refunded,
                                               prm_source,
                                               prm_receipt_trans_code,
                                               prm_production_date,
                                               prm_chk_comm_rate,
                                               prm_reinst_int_amt,
                                               prm_fund_posted,
                                               prm_additional_prem,
                                               prm_pof_code,
                                               prm_other_taxes,
                                               prm_rcpt_rfnd_amt,
                                               prm_rfnd_prodctn_date,
                                               prm_within_system,
                                               prm_fund_posted_by,
                                               prm_fund_post_date,
                                               prm_origin,
                                               prm_alloc_to,
                                               prm_prem_tax_posted,
                                               prm_prem_tax_posted_by,
                                               prm_prem_tax_posted_date,
                                               prm_policy_fee,
                                               prm_chk_agen_code,
                                               prm_prev_unalloc,
                                               prm_tracking_no)
                         VALUES (
                                TO_NUMBER (TO_CHAR (SYSDATE, 'YYYY'))
                             || gin_prm_code_seq.NEXTVAL,
                             cur_rctp_rec.prm_trans_no,
                             SYSDATE,
                             cur_rctp_rec.prm_cheque_no,
                             -cur_rctp_rec.prm_amt,
                             v_batch_no,
                             cur_rctp_rec.prm_pol_policy_no,
                             cur_rctp_rec.prm_receipt_no,
                             cur_rctp_rec.prm_receipt_date,
                             -cur_rctp_rec.prm_allocated_amt,
                             NULL,
                             cur_rctp_rec.prm_pay_method,
                             NULL,
                             cur_rctp_rec.prm_remarks,
                             NULL,
                             NULL,
                             -cur_rctp_rec.prm_prem_comm,
                             -cur_rctp_rec.prm_pens_comm,
                             -cur_rctp_rec.prm_chk_comm,
                             -cur_rctp_rec.prm_prem_tax,
                             'D',
                             cur_rctp_rec.prm_status,
                             cur_rctp_rec.prm_done_by,
                             cur_rctp_rec.prm_fully_refunded,
                             cur_rctp_rec.prm_source,
                             cur_rctp_rec.prm_receipt_trans_code,
                             cur_rctp_rec.prm_production_date,
                             cur_rctp_rec.prm_chk_comm_rate,
                             -cur_rctp_rec.prm_reinst_int_amt,
                             cur_rctp_rec.prm_fund_posted,
                             -cur_rctp_rec.prm_additional_prem,
                             cur_rctp_rec.prm_pof_code,
                             cur_rctp_rec.prm_other_taxes,
                             -cur_rctp_rec.prm_rcpt_rfnd_amt,
                             cur_rctp_rec.prm_rfnd_prodctn_date,
                             cur_rctp_rec.prm_within_system,
                             cur_rctp_rec.prm_fund_posted_by,
                             cur_rctp_rec.prm_fund_post_date,
                             cur_rctp_rec.prm_origin,
                             cur_rctp_rec.prm_alloc_to,
                             cur_rctp_rec.prm_prem_tax_posted,
                             cur_rctp_rec.prm_prem_tax_posted_by,
                             cur_rctp_rec.prm_prem_tax_posted_date,
                             cur_rctp_rec.prm_policy_fee,
                             cur_rctp_rec.prm_chk_agen_code,
                             cur_rctp_rec.prm_prev_unalloc,
                             cur_rctp_rec.prm_tracking_no);
            END LOOP;

            --OPEN cur_insureds
            FOR cur_insureds_rec IN cur_insureds
            LOOP
                BEGIN
                    INSERT INTO gin_policy_insureds (polin_code,
                                                     polin_pa,
                                                     polin_pol_policy_no,
                                                     polin_pol_ren_endos_no,
                                                     polin_pol_batch_no,
                                                     polin_category,
                                                     polin_prp_code)
                             VALUES (
                                        TO_NUMBER (
                                               TO_CHAR (SYSDATE, 'RRRR')
                                            || polin_code_seq.NEXTVAL),
                                        NULL,
                                        cur_pol_rec.pol_policy_no,
                                        v_ends_no,
                                        v_batch_no,
                                        NULL,
                                        cur_insureds_rec.polin_prp_code);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        ROLLBACK;
                        raise_error (
                            ' Error creating insureds record. Contact the system administrator...');
                END;

                FOR cur_ipu_rec IN cur_ipu (cur_insureds_rec.polin_code)
                LOOP
                    SELECT TO_NUMBER (
                                  TO_CHAR (SYSDATE, 'RRRR')
                               || gin_ipu_code_seq.NEXTVAL)
                      INTO v_new_ipu_code
                      FROM DUAL;

                    -- DO YOUR INSERTS INTO ipu
                    BEGIN
                        --  RAISE_ERROR('YEAR'||cur_ipu_rec.ipu_model_yr||'MODEL'|| cur_ipu_rec.ipu_vehicle_model
                        --  ||'MAKE' ||cur_ipu_rec.ipu_vehicle_make);
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
                                        ipu_phfund,
                                       ipu_wtht, ---- ADDED ON 03_11_2022 TO RESOLVE CONTRA TRANSACTIONS THAT DO NOT REVERSE THE WHTX AMOUNT
                                        ipu_co_phfund,
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
                                         ipu_insured_driver,
                                        ipu_cert_no,
                                       ipu_lta_endos_com_amt,
                                       ipu_lta_commission,
                                       ipu_lta_comm_rate,
                                       ipu_maintenance_period_type,
                                      ipu_maintenance_period,
                                      ipu_other_client_deductibles,
                                      ipu_coin_other_client_charges,
                                      ipu_survey_agnt_code,
                                        ipu_survey,
                                        ipu_marine_type)
                                 VALUES (
                                     v_new_ipu_code,
                                     cur_ipu_rec.ipu_property_id,
                                     cur_ipu_rec.ipu_item_desc,
                                     cur_ipu_rec.ipu_qty,
                                     -NVL (cur_ipu_rec.ipu_value, 0),
                                     cur_ipu_rec.ipu_wef,
                                     cur_ipu_rec.ipu_wet,
                                     cur_pol_rec.pol_policy_no,
                                     v_ends_no,
                                     v_batch_no,
                                     -NVL (
                                          cur_ipu_rec.ipu_basic_premium,
                                         0),
                                     -NVL (
                                          cur_ipu_rec.ipu_nett_premium,
                                         0),
                                     cur_ipu_rec.ipu_compulsory_excess,
                                     cur_ipu_rec.ipu_add_theft_excess,
                                     cur_ipu_rec.ipu_add_exp_excess,
                                     cur_ipu_rec.ipu_prr_rate,
                                     -NVL (
                                          cur_ipu_rec.ipu_comp_retention,
                                          0),
                                     cur_ipu_rec.ipu_pol_est_max_loss,
                                     -NVL (
                                          cur_ipu_rec.ipu_avail_fulc_bal,
                                          0),
                                     -NVL (
                                         cur_ipu_rec.ipu_endos_diff_amt,
                                         0),
                                     cur_ipu_rec.ipu_prem_wef,
                                     cur_ipu_rec.ipu_earth_quake_cover,
                                     cur_ipu_rec.ipu_earth_quake_prem,
                                     cur_ipu_rec.ipu_location,
                                     -NVL (cur_ipu_rec.ipu_itl, 0),
                                     TO_NUMBER (
                                            TO_CHAR (SYSDATE, 'RRRR')
                                         || polin_code_seq.CURRVAL),
                                     cur_ipu_rec.ipu_sec_sect_code,
                                     cur_ipu_rec.ipu_sect_sht_desc,
                                     cur_ipu_rec.ipu_sec_scl_code,
                                     cur_ipu_rec.ipu_ncd_status,
                                     cur_ipu_rec.ipu_cert_issued,
                                     cur_ipu_rec.ipu_related_ipu_code,
                                     cur_ipu_rec.ipu_prorata,
                                     -NVL (cur_ipu_rec.ipu_bp, 0),
                                     -NVL (cur_ipu_rec.ipu_gp, 0),
                                     -NVL (cur_ipu_rec.ipu_fp, 0),
                                     -NVL (cur_ipu_rec.ipu_fap, 0),
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
                                     -NVL (
                                          cur_ipu_rec.ipu_gross_comp_retention,
                                          0),
                                     cur_ipu_rec.ipu_bind_code,
                                     -NVL (cur_ipu_rec.ipu_commission,
                                         0),
                                     -NVL (
                                          cur_ipu_rec.ipu_comm_endos_diff_amt,
                                          0),
                                     -NVL (
                                          cur_ipu_rec.ipu_facre_amount,
                                          0),
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
                                     -NVL (
                                          cur_ipu_rec.ipu_reinsure_amt,
                                          0),
                                     cur_ipu_rec.ipu_prp_code,
                                     -NVL (
                                          cur_ipu_rec.ipu_max_exposure,
                                          0),
                                     cur_ipu_rec.ipu_com_retention_rate,
                                     cur_ipu_rec.ipu_retro_cover,
                                     cur_ipu_rec.ipu_retro_wef,
                                     cur_ipu_rec.ipu_eff_wef,
                                     cur_ipu_rec.ipu_eff_wet,
                                     cur_ipu_rec.ipu_comments,
                                     cur_ipu_rec.ipu_covt_code,
                                     cur_ipu_rec.ipu_covt_sht_desc,
                                     -NVL (cur_ipu_rec.ipu_si_diff, 0),
                                     cur_ipu_rec.ipu_terr_code,
                                     cur_ipu_rec.ipu_terr_desc,
                                     cur_ipu_rec.ipu_from_time,
                                     cur_ipu_rec.ipu_to_time,
                                     -NVL (
                                          cur_ipu_rec.ipu_tot_endos_prem_dif,
                                          0),
                                     -NVL (cur_ipu_rec.ipu_tot_gp, 0),
                                     -NVL (cur_ipu_rec.ipu_tot_value,
                                         0),
                                     cur_ipu_rec.ipu_cover_days,
                                     cur_ipu_rec.ipu_grp_si_risk_pct,
                                     -NVL (
                                          cur_ipu_rec.ipu_grp_top_loc,
                                         0),
                                     -NVL (
                                          cur_ipu_rec.ipu_grp_comp_gross_ret,
                                          0),
                                     -NVL (
                                         cur_ipu_rec.ipu_grp_comp_net_ret,
                                          0),
                                     -NVL (cur_ipu_rec.ipu_prev_prem,
                                         0),
                                     cur_ipu_rec.ipu_ri_agnt_com_rate,
                                     cur_ipu_rec.ipu_uw_yr,
                                     cur_ipu_rec.ipu_status,
                                     -NVL (cur_ipu_rec.ipu_paid_tl, 0),
                                    -NVL (
                                         cur_ipu_rec.ipu_paid_premium,
                                         0),
                                      NVL (
                                          cur_ipu_rec.ipu_trans_count,
                                          0)
                                     + 1,
                                     cur_ipu_rec.ipu_rate_change_comment,
                                     -NVL (cur_ipu_rec.ipu_prem_tax,
                                         0),
                                     cur_ipu_rec.ipu_trans_eff_wet,
                                     cur_ipu_rec.ipu_compute_max_exposure,
                                     cur_ipu_rec.ipu_endose_fap_or_bc,
                                     -NVL (
                                          cur_ipu_rec.ipu_tot_first_loss,
                                          0),
                                     -NVL (
                                         cur_ipu_rec.ipu_accumulation_limit,
                                          0),
                                     cur_ipu_rec.ipu_inception_uwyr,
                                     cur_ipu_rec.ipu_eml_based_on,
                                     cur_ipu_rec.ipu_aggregate_limits,
                                     cur_ipu_rec.ipu_rc_sht_desc,
                                     cur_ipu_rec.ipu_rc_code,
                                     cur_ipu_rec.ipu_survey_date,
                                     cur_ipu_rec.ipu_item_details,
                                     cur_ipu_rec.ipu_code,
                                      -NVL (
                                          cur_ipu_rec.ipu_prev_tot_fap,
                                         0),
                                      -NVL (cur_ipu_rec.ipu_prev_fap,
                                          0),
                                     cur_ipu_rec.ipu_override_ri_retention,
                                    -cur_ipu_rec.ipu_ri_agnt_comm_amt,
                                   -cur_ipu_rec.ipu_earthqke_prem_diff,
                                    cur_ipu_rec.ipu_tot_fap,
                                    -cur_ipu_rec.ipu_coin_tl,
                                   -cur_ipu_rec.ipu_mktr_com_amt,
                                     cur_ipu_rec.ipu_mktr_com_rate,
                                    cur_ipu_rec.ipu_vat_rate,
                                     -cur_ipu_rec.ipu_vat_amt,
                                     cur_ipu_rec.ipu_status,
                                    cur_ipu_rec.ipu_rs_code,
                                    cur_ipu_rec.ipu_rescue_mem,
                                    -cur_ipu_rec.ipu_rescue_charge,
                                    -cur_ipu_rec.ipu_phfund,
                                       cur_ipu_rec.IPU_WTHT, ---- ADDED ON 03_11_2022 TO RESOLVE CONTRA TRANSACTIONS THAT DO NOT REVERSE THE WHTX AMOUNT
                                   -cur_ipu_rec.ipu_co_phfund,
                                    -cur_ipu_rec.ipu_health_tax,
                                     -cur_ipu_rec.ipu_road_safety_tax,
                                    -cur_ipu_rec.ipu_certchg,
                                     -cur_ipu_rec.ipu_motor_levy,
                                    -cur_ipu_rec.ipu_client_vat_amt,
                                      cur_ipu_rec.ipu_cashback_appl,
                                      cur_ipu_rec.ipu_cashback_level,
                                      cur_ipu_rec.ipu_vehicle_model,
                                      cur_ipu_rec.ipu_vehicle_make,
                                    cur_ipu_rec.ipu_vehicle_model_code,
                                      cur_ipu_rec.ipu_vehicle_make_code,
                                       cur_ipu_rec.ipu_loc_town,
                                    cur_ipu_rec.ipu_prop_address,
                                      cur_ipu_rec.ipu_risk_note,
                                     cur_ipu_rec.ipu_other_com_charges,
                                     cur_ipu_rec.ipu_model_yr,
                                       cur_ipu_rec.ipu_insured_driver,
                                       cur_ipu_rec.ipu_cert_no,
                                      -cur_ipu_rec.ipu_lta_endos_com_amt,
                                     -cur_ipu_rec.ipu_lta_commission,
                                      cur_ipu_rec.ipu_lta_comm_rate,
                                       cur_ipu_rec.ipu_maintenance_period_type,
                                       cur_ipu_rec.ipu_maintenance_period,
                                       -cur_ipu_rec.ipu_other_client_deductibles,
                                       -cur_ipu_rec.ipu_coin_other_client_charges,
                                       cur_ipu_rec.ipu_survey_agnt_code,
                                       cur_ipu_rec.ipu_survey,
                                        cur_ipu_rec.ipu_marine_type);
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            ROLLBACK;
                            raise_error (
                                   ' Error creating risk contra record. Contact the system administrator...'
                                || 'PHF FUND='
                                || cur_ipu_rec.ipu_co_phfund);
                    END;

                    --               CONTRA COMMISSION
                    FOR cur_comm_rec
                        IN cur_riskcommissions (cur_ipu_rec.ipu_code)
                    LOOP
                        BEGIN
                            INSERT INTO gin_policy_risk_commissions (
                                            PRC_CODE,
                                            PRC_IPU_CODE,
                                            PRC_POL_BATCH_NO,
                                            PRC_AGN_CODE,
                                            PRC_TRANS_CODE,
                                            PRC_ACT_CODE,
                                            PRC_AMOUNT,
                                            PRC_SETUP_RATE,
                                            PRC_USED_RATE,
                                            PRC_WHTAX_AMOUNT,
                                            PRC_WHTAX_RATE,
                                            PRC_TRNT_CODE,
                                            PRC_DISC_TYPE,
                                            PRC_DISC_RATE,
                                            PRC_DISC_AMOUNT,
                                            PRC_GROUP,
                                            PRC_PREMIUM_AMT,
                                            PRC_ALLOWED_AMT,
                                            PRC_ROUNDS)
                                 VALUES (tq_gis.prc_code_seq.NEXTVAL,
                                         v_new_ipu_code,
                                         v_batch_no,
                                         cur_comm_rec.PRC_AGN_CODE,
                                         cur_comm_rec.PRC_TRANS_CODE,
                                         cur_comm_rec.PRC_ACT_CODE,
                                         -cur_comm_rec.PRC_AMOUNT,
                                         cur_comm_rec.PRC_SETUP_RATE,
                                         cur_comm_rec.PRC_USED_RATE,
                                         -cur_comm_rec.PRC_WHTAX_AMOUNT,
                                         cur_comm_rec.PRC_WHTAX_RATE,
                                         cur_comm_rec.PRC_TRNT_CODE,
                                         cur_comm_rec.PRC_DISC_TYPE,
                                         cur_comm_rec.PRC_DISC_RATE,
                                         cur_comm_rec.PRC_DISC_AMOUNT,
                                         cur_comm_rec.PRC_GROUP,
                                         -cur_comm_rec.PRC_PREMIUM_AMT,
                                         -cur_comm_rec.PRC_ALLOWED_AMT,
                                         cur_comm_rec.PRC_ROUNDS);
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                ROLLBACK;
                                raise_error (
                                    '  Error creating risk section record. Contact the system administrator...');
                        END;
                    END LOOP;

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
                                            pil_prev_endr_mult_div

```sql
                                        pil_expired,
                                            pil_firstloss,
                                            pil_firstloss_amt_pcnt,
                                            pil_firstloss_value)
                                     VALUES (
                                                TO_NUMBER (
                                                       TO_CHAR (SYSDATE,
                                                                'RRRR')
                                                    || gin_pil_code_seq.NEXTVAL),
                                                v_new_ipu_code,
                                                cur_limits_rec.pil_sect_code,
                                                cur_limits_rec.pil_sect_sht_desc,
                                                cur_limits_rec.pil_row_num,
                                                cur_limits_rec.pil_calc_group,
                                                -NVL (
                                                     cur_limits_rec.pil_limit_amt,
                                                     0),
                                                cur_limits_rec.pil_prem_rate,
                                                -NVL (
                                                     cur_limits_rec.pil_prem_amt,
                                                     0),
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
                                                -NVL (
                                                     cur_limits_rec.pil_annual_premium,
                                                     0),
                                                cur_limits_rec.pil_rate_div_fact,
                                                -NVL (
                                                     cur_limits_rec.pil_min_premium,
                                                     0),
                                                cur_limits_rec.pil_desc,
                                                cur_limits_rec.pil_compute,
                                                -NVL (
                                                     cur_limits_rec.pil_used_limit,
                                                     0),
                                                cur_limits_rec.pil_indem_prd,
                                                cur_limits_rec.pil_prd_type,
                                                cur_limits_rec.pil_indem_fstprd,
                                                cur_limits_rec.pil_indem_fstprd_pct,
                                                cur_limits_rec.pil_indem_remprd_pct,
                                                cur_limits_rec.pil_dual_basis,
                                                -NVL (
                                                     cur_limits_rec.pil_prem_accumulation,
                                                     0),
                                                cur_limits_rec.pil_declaration_section,
                                                -NVL (
                                                     cur_limits_rec.pil_prev_limit,
                                                     0),
                                                -NVL (
                                                     cur_limits_rec.pil_actual_prem,
                                                     0),
                                                -NVL (
                                                     cur_limits_rec.pil_prev_prem_prorata,
                                                     0),
                                                -NVL (
                                                     cur_limits_rec.pil_annual_actual_prem,
                                                     0),
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
                                             cur_limits_rec.pil_firstloss_value);
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                ROLLBACK;
                                raise_error (
                                    '  Error creating risk section record. Contact the system administrator...');
                        END;
                    END LOOP;                                 --cur_limits_rec

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
                                            pocl_heading)
                                 VALUES (cur_clauses_rec.pocl_sbcl_cls_code,
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
                                         cur_clauses_rec.pocl_heading);
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                ROLLBACK;
                                raise_error (
                                    '  Error creating risk clauses record. Contact the system administrator...');
                        END;
                    END LOOP;                                --cur_clauses_rec

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
                                                v_batch_no,
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
                                                -cur_rsk_perils_rec.prspr_premium_amt,
                                                NULL,
                                                -cur_rsk_perils_rec.prspr_annual_premium,
                                                -cur_rsk_perils_rec.prspr_prem_prorata,
                                                -cur_rsk_perils_rec.prspr_actual_rate_prem,
                                                cur_rsk_perils_rec.prspr_rate_div_fact,
                                                -cur_rsk_perils_rec.prspr_free_limit_amt,
                                                cur_rsk_perils_rec.prspr_prorata_full,
                                                -cur_rsk_perils_rec.prspr_min_premium,
                                                cur_rsk_perils_rec.prspr_multiplier_rate,
                                                cur_rsk_perils_rec.prspr_multiplier_div_factor);
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                raise_error (
                                    'Unable to insert risk level clause details, ...');
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
                                ROLLBACK;
                                raise_error (
                                    '  Error creating risk perils record. Contact the system administrator...');
                        END;
                    END LOOP;                                 --Cur_perils_rec

                    FOR risk_excesses_rec
                        IN risk_excesses (cur_ipu_rec.ipu_code)
                    LOOP
                        BEGIN
                            INSERT INTO gin_risk_excess (re_ipu_code,
                                                         re_excess_rate,
                                                         re_excess_type,
                                                         re_excess_rate_type,
                                                         re_excess_min,
                                                         re_excess_max,
                                                         re_comments)
                                     VALUES (
                                         v_new_ipu_code,
                                         risk_excesses_rec.re_excess_rate,
                                         risk_excesses_rec.re_excess_type,
                                         risk_excesses_rec.re_excess_rate_type,
                                         risk_excesses_rec.re_excess_min,
                                         risk_excesses_rec.re_excess_max,
                                         risk_excesses_rec.re_comments);
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                raise_error (
                                    '  Error creating risk excess record. Contact the system administrator...');
                        END;
                    END LOOP;                              --risk_excesses_rec

                    FOR schedules_rec IN schedules (cur_ipu_rec.ipu_code)
                    LOOP
                        BEGIN
                            INSERT INTO gin_policy_risk_schedules (
                                            polrs_code,
                                            polrs_ipu_code,
                                            polrs_pol_batch_no,
                                            polrs_schedule)
                                     VALUES (
                                                   TO_NUMBER (
                                                       TO_CHAR (SYSDATE,
                                                                'RRRR'))
                                                || gin_polrs_code_seq.NEXTVAL,
                                                v_new_ipu_code,
                                                v_batch_no,
                                                schedules_rec.polrs_schedule);
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                ROLLBACK;
                                raise_error (
                                    ' Error creating risk schedules record. Contact the system administrator...');
                        END;
                    END LOOP;                                  --Schedules_rec

                    FOR cur_prrd_rec
                        IN cur_prrd (cur_ipu_rec.ipu_current_prrd_code)
                    LOOP
                        BEGIN
                            INSERT INTO gin_policy_risk_ri_dtls (
                                            prrd_code,
                                            prrd_ipu_code,
                                            prrd_idx,
                                            prrd_tran_no,
                                            prrd_wef,
                                            prrd_wet,
                                            prrd_current,
                                            prrd_comp_retention,
                                            prrd_avail_fulc_bal,
                                            prrd_gross_comp_retention,
                                            prrd_facre_amount,
                                            prrd_com_retention_rate,
                                            prrd_grp_si_risk_pct,
                                            prrd_grp_top_loc,
                                            prrd_grp_comp_gross_ret,
                                            prrd_grp_comp_net_ret,
                                            prrd_excess_pct,
                                            prrd_ri_prem,
                                            prrd_comp_net_rate,
                                            prrd_prorata_days,
                                            prrd_prev_facre_rate,
                                            prrd_refund_prem,
                                            prrd_prev_ret_rate,
                                            prrd_prev_net_rate,
                                            prrd_facre_rate,
                                            prrd_allowed_grs_comp_ret,
                                            prrd_as_uwyr,
                                            prrd_annual_prem,
                                            prrd_cover_days,
                                            prrd_prorata_prem,
                                            prrd_prev_net_retention,
                                            prrd_refund_net_prem,
                                            prrd_refund_facre_prem,
                                            prrd_net_prem,
                                            prrd_prev_prrd_code,
                                            prrd_earthquake_prem,
                                            prrd_facoblig_limit)
                                     VALUES (
                                                   TO_NUMBER (
                                                       TO_CHAR (SYSDATE,
                                                                'RRRR'))
                                                || gin_prrd_code_seq.NEXTVAL,
                                                v_new_ipu_code,
                                                1,
                                                v_tran_no,
                                                cur_prrd_rec.prrd_wef,
                                                cur_prrd_rec.prrd_wet,
                                                'Y',
                                                -NVL (
                                                     cur_prrd_rec.prrd_comp_retention,
                                                     0),
                                                0,
                                                /*** to bypass facre trigger**/
                                                -NVL (
                                                     cur_prrd_rec.prrd_gross_comp_retention,
                                                     0),
                                                -NVL (
                                                     cur_prrd_rec.prrd_facre_amount,
                                                     0),
                                                cur_prrd_rec.prrd_com_retention_rate,
                                                cur_prrd_rec.prrd_grp_si_risk_pct,
                                                -NVL (
                                                     cur_prrd_rec.prrd_grp_top_loc,
                                                     0),
                                                -NVL (
                                                     cur_prrd_rec.prrd_grp_comp_gross_ret,
                                                     0),
                                                -NVL (
                                                     cur_prrd_rec.prrd_grp_comp_net_ret,
                                                     0),
                                                cur_prrd_rec.prrd_excess_pct,
                                                -NVL (
                                                     cur_prrd_rec.prrd_ri_prem,
                                                     0),
                                                cur_prrd_rec.prrd_comp_net_rate,
                                                cur_prrd_rec.prrd_prorata_days,
                                                cur_prrd_rec.prrd_prev_facre_rate,
                                                cur_prrd_rec.prrd_refund_prem,
                                                cur_prrd_rec.prrd_prev_ret_rate,
                                                cur_prrd_rec.prrd_prev_net_rate,
                                                cur_prrd_rec.prrd_facre_rate,
                                                cur_prrd_rec.prrd_allowed_grs_comp_ret,
                                                cur_prrd_rec.prrd_as_uwyr,
                                                cur_prrd_rec.prrd_annual_prem,
                                                cur_prrd_rec.prrd_cover_days,
                                                cur_prrd_rec.prrd_prorata_prem,
                                                cur_prrd_rec.prrd_prev_net_retention,
                                                cur_prrd_rec.prrd_refund_net_prem,
                                                cur_prrd_rec.prrd_refund_facre_prem,
                                                -cur_prrd_rec.prrd_net_prem,
                                                cur_prrd_rec.prrd_code,
                                                -cur_prrd_rec.prrd_earthquake_prem,
                                                -cur_prrd_rec.prrd_facoblig_limit);

                            UPDATE gin_insured_property_unds
                               SET ipu_current_prrd_code =
                                          TO_NUMBER (
                                              TO_CHAR (SYSDATE, 'RRRR'))
                                       || gin_prrd_code_seq.CURRVAL
                             WHERE ipu_code = v_new_ipu_code;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                ROLLBACK;
                                raise_error (
                                    ' Unable to insert risk RI details...');
                        END;

                        FOR cur_rein_rec IN cur_rein (cur_prrd_rec.prrd_code)
                        LOOP
                            BEGIN
                                INSERT INTO gin_policy_rein_risk_details (
                                                ptotr_code,
                                                ptotr_risk_cur_code,
                                                ptotr_trt_cur_code,
                                                ptotr_exch_rate,
                                                ptotr_risk_si_pcur,
                                                ptotr_risk_si_tcur,
                                                ptotr_risk_prem_pcur,
                                                ptotr_risk_prem_tcur,
                                                ptotr_trt_si_pcur,
                                                ptotr_trt_si_tcur,
                                                ptotr_trt_prem_pcur,
                                                ptotr_trt_prem_tcur,
                                                ptotr_trt_share,
                                                ptotr_rei_code,
                                                ptotr_trt_code,
                                                ptotr_trt_sht_desc,
                                                ptotr_clt_scl_code,
                                                ptotr_rate,
                                                ptotr_trt_comm_pcur,
                                                ptotr_trt_comm_tcur,
                                                ptotr_cession_pct,
                                                ptotr_property_id,
                                                ptotr_uwyr,
                                                ptotr_ipu_code,
                                                ptotr_pol_batch_no,
                                                ptotr_pol_policy_no,
                                                ptotr_pol_ren_endos_no,
                                                ptotr_acpr_sht_desc,
                                                ptotr_acpr_code,
                                                ptotr_risk_cur_symbol,
                                                ptotr_trt_cur_symbol,
                                                ptotr_prem_tax_pcur,
                                                ptotr_prem_tax_tcur,
                                                ptotr_comm_tax_pcur,
                                                ptotr_comm_tax_tcur,
                                                ptotr_ta_code,
                                                ptotr_as_code,
                                                ptotr_sect_code,
                                                ptotr_trs_code,
                                                ptotr_trs_sht_desc,
                                                ptotr_rate_type,
                                                ptotr_remarks,
                                                ptotr_ggt_tran_no,
                                                ptotr_tran_type,
                                                ptotr_date,
                                                ptotr_rprem_tax_pcur,
                                                ptotr_actual_si_share,
                                                ptotr_current,
                                                ptotr_prrd_code,
                                                ptotr_prev_cession_rate,
                                                ptotr_refund_prem,
                                                ptotr_refund_com,
                                                ptotr_comm_rate,
                                                ptotr_earthqke_prem,
                                                ptotr_earthqke_comm_rate,
                                                ptotr_earthqke_comm,
                                                ptotr_net_less_eq_comm,
                                                ptotr_net_less_eq_prem)
                                         VALUES (
                                                       TO_NUMBER (
                                                           TO_CHAR (SYSDATE,
                                                                    'RRRR'))
                                                    || ptotr_code_seq.NEXTVAL,
                                                    cur_rein_rec.ptotr_risk_cur_code,
                                                    cur_rein_rec.ptotr_trt_cur_code,
                                                    cur_rein_rec.ptotr_exch_rate,
                                                    -NVL (
                                                         cur_rein_rec.ptotr_risk_si_pcur,
                                                         0),
                                                    -NVL (
                                                         cur_rein_rec.ptotr_risk_si_tcur,
                                                         0),
                                                    -NVL (
                                                         cur_rein_rec.ptotr_risk_prem_pcur,
                                                         0),
                                                    -NVL (
                                                         cur_rein_rec.ptotr_risk_prem_tcur,
                                                         0),
                                                    -NVL (
                                                         cur_rein_rec.ptotr_trt_si_pcur,
                                                         0),
                                                    -NVL (
                                                         cur_rein_rec.ptotr_trt_si_tcur,
                                                         0),
                                                    -NVL (
                                                         cur_rein_rec.ptotr_trt_prem_pcur,
                                                         0),
                                                    -NVL (
                                                         cur_rein_rec.ptotr_trt_prem_tcur,
                                                         0),
                                                    cur_rein_rec.ptotr_trt_share,
                                                    cur_rein_rec.ptotr_rei_code,
                                                    cur_rein_rec.ptotr_trt_code,
                                                    cur_rein_rec.ptotr_trt_sht_desc,
                                                    cur_rein_rec.ptotr_clt_scl_code,
                                                    cur_rein_rec.ptotr_rate,
                                                    -NVL (
                                                         cur_rein_rec.ptotr_trt_comm_pcur,
                                                         0),
                                                    -NVL (
                                                         cur_rein_rec.ptotr_trt_comm_tcur,
                                                         0),
                                                    cur_rein_rec.ptotr_cession_pct,
                                                    cur_rein_rec.ptotr_property_id,
                                                    cur_rein_rec.ptotr_uwyr,
                                                    v_new_ipu_code,
                                                    v_batch_no,
                                                    v_pol_no,
                                                    v_ends_no,
                                                    cur_rein_rec.ptotr_acpr_sht_desc,
                                                    cur_rein_rec.ptotr_acpr_code,
                                                    cur_rein_rec.ptotr_risk_cur_symbol,
                                                    cur_rein_rec.ptotr_trt_cur_symbol,
                                                    -NVL (
                                                         cur_rein_rec.ptotr_prem_tax_pcur,
                                                         0),
                                                    -NVL (
                                                         cur_rein_rec.ptotr_prem_tax_tcur,
                                                         0),
                                                    -NVL (
                                                         cur_rein_rec.ptotr_comm_tax_pcur,
                                                         0),
                                                    -NVL (
                                                         cur_rein_rec.ptotr_comm_tax_tcur,
                                                         0),
                                                    cur_rein_rec.ptotr_ta_code,
                                                    cur_rein_rec.ptotr_as_code,
                                                    cur_rein_rec.ptotr_sect_code,
                                                    cur_rein_rec.ptotr_trs_code,
                                                    cur_rein_rec.ptotr_trs_sht_desc,
                                                    cur_rein_rec.ptotr_rate_type,
                                                    cur_rein_rec.ptotr_remarks,
                                                    v_tran_no,
                                                    'CO',
                                                    TRUNC (SYSDATE),
                                                    -NVL (
                                                         cur_rein_rec.ptotr_rprem_tax_pcur,
                                                         0),
                                                    cur_rein_rec.ptotr_actual_si_share,
                                                    'N',
                                                       TO_NUMBER (
                                                           TO_CHAR (SYSDATE,
                                                                    'RRRR'))
                                                    || gin_prrd_code_seq.CURRVAL,
                                                    cur_rein_rec.ptotr_prev_cession_rate,
                                                    -NVL (
                                                         cur_rein_rec.ptotr_refund_prem,
                                                         0),
                                                    -NVL (
                                                         cur_rein_rec.ptotr_refund_com,
                                                         0),
                                                    cur_rein_rec.ptotr_comm_rate,
                                                    -NVL (
                                                         cur_rein_rec.ptotr_earthqke_prem,
                                                         0),
                                                    NVL (
                                                        cur_rein_rec.ptotr_earthqke_comm_rate,
                                                        0),
                                                    -NVL (
                                                         cur_rein_rec.ptotr_earthqke_comm,
                                                         0),
                                                    -NVL (
                                                         cur_rein_rec.ptotr_net_less_eq_comm,
                                                         0),
                                                    -NVL (
                                                         cur_rein_rec.ptotr_net_less_eq_prem,
                                                         0));
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    ROLLBACK;
                                    raise_error (
                                        ' Unable to insert treaty cession details...');
                            END;

                            FOR cur_part_rec
                                IN cur_part (cur_rein_rec.ptotr_code)
                            LOOP
                                BEGIN
                                    INSERT INTO gin_participations (
                                                    part_code,
                                                    part_cede_rate,
                                                    part_si_amt_pcur,
                                                    part_si_amt_tcur,
                                                    part_comm_amt_pcur,
                                                    part_comm_amt_tcur,
                                                    part_prem_amt_pcur,
                                                    part_prem_amt_tcur,
                                                    part_trt_code,
                                                    part_trt_sht_desc,
                                                    part_agnt_agent_code,
                                                    part_agnt_sht_desc,
                                                    part_ptotr_code,
                                                    part_rei_code,
                                                    part_pol_cur_code,
                                                    part_pol_cur_symbol,
                                                    part_uwyr,
                                                    part_pol_batch_no,
                                                    part_pol_policy_no,
                                                    part_pol_ren_endos_no,
                                                    part_ipu_code,
                                                    part_rprem_tax_pcur,
                                                    part_rprem_tax_tcur,
                                                    part_prem_tax_pcur,
                                                    part_prem_tax_tcur,
                                                    part_ta_code,
                                                    part_as_code,
                                                    part_fiscal_year,
                                                    part_acpr_code,
                                                    part_acpr_sht_desc,
                                                    part_acc_posted,
                                                    part_trs_code,
                                                    part_trs_sht_desc,
                                                    part_scl_code,
                                                    part_ggt_tran_no,
                                                    part_tran_type,
                                                    part_prrd_code,
                                                    part_prev_cede_rate,
                                                    part_refund_prem,
                                                    part_prev_com,
                                                     part_trpa_code)
                                             VALUES (
                                                           TO_NUMBER (
                                                               TO_CHAR (
                                                                   SYSDATE,
                                                                   'RRRR'))
                                                        || gin_part_code_seq.NEXTVAL,
                                                        cur_part_rec.part_cede_rate,
                                                        -NVL (
                                                             cur_part_rec.part_si_amt_pcur,
                                                             0),
                                                        -NVL (
                                                             cur_part_rec.part_si_amt_tcur,
                                                             0),
                                                        -NVL (
                                                             cur_part_rec.part_comm_amt_pcur,
                                                             0),
                                                        -NVL (
                                                             cur_part_rec.part_comm_amt_tcur,
                                                             0),
                                                        -NVL (
                                                             cur_part_rec.part_prem_amt_pcur,
                                                             0),
                                                        -NVL (
                                                             cur_part_rec.part_prem_amt_tcur,
                                                             0),
                                                        cur_part_rec.part_trt_code,
                                                        cur_part_rec.part_trt_sht_desc,
                                                        cur_part_rec.part_agnt_agent_code,
                                                        cur_part_rec.part_agnt_sht_desc,
                                                           TO_NUMBER (
                                                               TO_

```sql
                                                               TO_CHAR (
                                                                   SYSDATE,
                                                                   'RRRR'))
                                                        || ptotr_code_seq.CURRVAL,
                                                        cur_part_rec.part_rei_code,
                                                        cur_part_rec.part_pol_cur_code,
                                                        cur_part_rec.part_pol_cur_symbol,
                                                        cur_part_rec.part_uwyr,
                                                        v_batch_no,
                                                        cur_part_rec.part_pol_policy_no,
                                                        v_ends_no,
                                                        v_new_ipu_code,
                                                        -NVL (
                                                             cur_part_rec.part_rprem_tax_pcur,
                                                             0),
                                                        -NVL (
                                                             cur_part_rec.part_rprem_tax_tcur,
                                                             0),
                                                        -NVL (
                                                             cur_part_rec.part_prem_tax_pcur,
                                                             0),
                                                        -NVL (
                                                             cur_part_rec.part_prem_tax_tcur,
                                                             0),
                                                        cur_part_rec.part_ta_code,
                                                        cur_part_rec.part_as_code,
                                                        cur_part_rec.part_fiscal_year,
                                                        cur_part_rec.part_acpr_code,
                                                        cur_part_rec.part_acpr_sht_desc,
                                                        cur_part_rec.part_acc_posted,
                                                        cur_part_rec.part_trs_code,
                                                        cur_part_rec.part_trs_sht_desc,
                                                        cur_part_rec.part_scl_code,
                                                        v_tran_no,
                                                        'CO',
                                                           TO_NUMBER (
                                                               TO_CHAR (
                                                                   SYSDATE,
                                                                   'RRRR'))
                                                        || gin_prrd_code_seq.CURRVAL,
                                                        cur_part_rec.part_prev_cede_rate,
                                                        -NVL (
                                                             cur_part_rec.part_refund_prem,
                                                             0),
                                                        -NVL (
                                                             cur_part_rec.part_prev_com,
                                                             0),
                                                        cur_part_rec.part_trpa_code);
                                EXCEPTION
                                    WHEN OTHERS
                                    THEN
                                        ROLLBACK;
                                        raise_error (
                                            ' Unable to insert treaty cession participation details...');
                                END;
                            END LOOP;                               --cur_part
                        END LOOP;                                   --cur_rein
                        
                       FOR cur_facre_rec
                            IN cur_facre (cur_prrd_rec.prrd_code)
                        LOOP
                            BEGIN
                                INSERT INTO gin_facre_cessions (
                                                fc_code,
                                                fc_agnt_agent_code,
                                                fc_amount,
                                                fc_wef,
                                                fc_ipu_code,
                                                fc_agent_sht_desc,
                                                fc_rate,
                                                fc_comm_rate,
                                                fc_comm_amt,
                                                fc_don_by,
                                                fc_dc_no,
                                                fc_prem_amt,
                                                fc_pol_batch_no,
                                                fc_uwyr,
                                                fc_ggt_tran_no,
                                                fc_tran_type,
                                                fc_scl_code,
                                                fc_amt_or_rate,
                                                fc_prrd_code,
                                                fc_prev_fc_code,
                                                fc_earthqke_prem,
                                                fc_earthqke_comm_rate,
                                                fc_earthqke_comm,
                                                fc_net_less_eq_comm,
                                                fc_net_less_eq_prem,
                                                fc_accepted,
                                                fc_facre_type,
                                                fc_accepted_date,
                                                fc_prem_diff_amt,
                                                fc_remark,
                                                fc_mngmnt_type,
                                                fc_mngmnt_value,
                                                fc_rein_tax_type,
                                                fc_rein_tax_value,
                                                fc_rein_tax_amt,
                                                fc_mngmnt_amt,
                                                 fc_vat_rate,
                                                fc_vat_amt)
                                         VALUES (
                                                      TO_NUMBER (
                                                          TO_CHAR (SYSDATE,
                                                                   'RRRR'))
                                                   || gin_fc_code_seq.NEXTVAL,
                                                   cur_facre_rec.fc_agnt_agent_code,
                                                  -NVL (
                                                        cur_facre_rec.fc_amount,
                                                        0),
                                                   cur_facre_rec.fc_wef,
                                                   v_new_ipu_code,
                                                   cur_facre_rec.fc_agent_sht_desc,
                                                   cur_facre_rec.fc_rate,
                                                   cur_facre_rec.fc_comm_rate,
                                                  -NVL (
                                                      cur_facre_rec.fc_comm_amt,
                                                        0),
                                                  v_user,
                                                   cur_facre_rec.fc_dc_no,
                                                  -NVL (
                                                        cur_facre_rec.fc_prem_amt,
                                                       0),
                                                    v_batch_no,
                                                   cur_facre_rec.fc_uwyr,
                                                    v_tran_no,
                                                   'CO',
                                                   cur_facre_rec.fc_scl_code,
                                                   cur_facre_rec.fc_amt_or_rate,
                                                      TO_NUMBER (
                                                          TO_CHAR (SYSDATE,
                                                                   'RRRR'))
                                                   || gin_prrd_code_seq.CURRVAL,
                                                   cur_facre_rec.fc_code,
                                                  -cur_facre_rec.fc_earthqke_prem,
                                                   cur_facre_rec.fc_earthqke_comm_rate,
                                                   -cur_facre_rec.fc_earthqke_comm,
                                                  -cur_facre_rec.fc_net_less_eq_comm,
                                                  -cur_facre_rec.fc_net_less_eq_prem,
                                                  cur_facre_rec.fc_accepted,
                                                  cur_facre_rec.fc_facre_type,
                                                   cur_facre_rec.fc_accepted_date,
                                                  -cur_facre_rec.fc_prem_diff_amt,
                                                    cur_facre_rec.fc_remark,
                                                    cur_facre_rec.fc_mngmnt_type,
                                                   cur_facre_rec.fc_mngmnt_value,
                                                  cur_facre_rec.fc_rein_tax_type,
                                                   cur_facre_rec.fc_rein_tax_value,
                                                  -cur_facre_rec.fc_rein_tax_amt,
                                                   -cur_facre_rec.fc_mngmnt_amt,
                                                  cur_facre_rec.fc_vat_rate,
                                                  -cur_facre_rec.fc_vat_amt);
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    ROLLBACK;
                                    raise_error (
                                        ' Unable to insert facre cessions details...');
                            END;
                        END LOOP;                              --cur_facre_rec
                        
                       FOR cur_cur_pool_rec
                            IN cur_pool (cur_prrd_rec.prrd_code)
                        LOOP
                            BEGIN
                                SELECT TO_NUMBER (
                                              TO_CHAR (SYSDATE, 'YYYY')
                                           || gin_prprd_code_seq.NEXTVAL)
                                  INTO v_prrd_code
                                  FROM DUAL;

                                INSERT INTO gin_pol_rein_pool_risk_details (
                                                prprd_code,
                                                prprd_risk_prem_amt,
                                                prprd_risk_own_ret_amt,
                                                prprd_risk_cur_code,
                                                prprd_risk_exch_rate,
                                                prprd_scrpr_code,
                                                prprd_rein_pool_rate,
                                                prprd_ipu_code,
                                                prprd_scl_code,
                                                prprd_covt_code,
                                                prprd_pol_batch_no,
                                                prprd_rein_pool_amt,
                                                prprd_rein_pool_comm_rate,
                                                prprd_rein_pool_vat_rate,
                                                prprd_rein_pool_comm_amt,
                                                prprd_rein_pool_vat_amt,
                                                prprd_prev_prprd_code,
                                                prprd_ggt_tran_no,
                                                prprd_property_id,
                                                prprd_uwyr,
                                                prprd_pol_ren_endos_no,
                                                prprd_date,
                                                prprd_risk_trt_own_ret_amt,
                                                prprd_prrd_code,
                                                 prprd_pta_code,
                                                prprd_pool_si)
                                         VALUES (
                                             v_prrd_code,
                                            -NVL (
                                                  cur_cur_pool_rec.prprd_risk_prem_amt,
                                                  0),
                                             -NVL (
                                                  cur_cur_pool_rec.prprd_risk_own_ret_amt,
                                                  0),
                                             cur_cur_pool_rec.prprd_risk_cur_code,
                                             cur_cur_pool_rec.prprd_risk_exch_rate,
                                             cur_cur_pool_rec.prprd_scrpr_code,
                                            NVL (
                                                cur_cur_pool_rec.prprd_rein_pool_rate,
                                                0),
                                             v_new_ipu_code,
                                             cur_cur_pool_rec.prprd_scl_code,
                                             cur_cur_pool_rec.prprd_covt_code,
                                             v_batch_no,
                                            -NVL (
                                                  cur_cur_pool_rec.prprd_rein_pool_amt,
                                                  0),
                                             NVL (
                                                 cur_cur_pool_rec.prprd_rein_pool_comm_rate,
                                                 0),
                                            NVL (
                                                 cur_cur_pool_rec.prprd_rein_pool_vat_rate,
                                                 0),
                                             -NVL (
                                                  cur_cur_pool_rec.prprd_rein_pool_comm_amt,
                                                  0),
                                             -NVL (
                                                  cur_cur_pool_rec.prprd_rein_pool_vat_amt,
                                                  0),
                                             cur_cur_pool_rec.prprd_code,
                                             v_tran_no,
                                            cur_cur_pool_rec.prprd_property_id,
                                             cur_cur_pool_rec.prprd_uwyr,
                                              v_ends_no,
                                             SYSDATE,
                                             -NVL (
                                                  cur_cur_pool_rec.prprd_risk_trt_own_ret_amt,
                                                  0),
                                            TO_NUMBER (
                                                TO_CHAR (SYSDATE, 'RRRR'))
                                             || gin_prrd_code_seq.CURRVAL,
                                            cur_cur_pool_rec.prprd_pta_code,
                                             -cur_cur_pool_rec.prprd_pool_si);
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    raise_when_others (
                                        'Error creating risk Reinsurance Pool Details...');
                            END;
                        END LOOP;                                  -- cur pool
                    END LOOP;                                       --cur_prrd
                END LOOP;                                        --cur_ipu_rec
            END LOOP;                                       --cur_insureds_rec
        END LOOP;                                                --cur_pol_rec
    END;

```