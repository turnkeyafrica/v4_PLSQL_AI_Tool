PROCEDURE transfer_to_uw (v_pol_batch_no   IN     NUMBER,
                              v_user           IN     VARCHAR2,
                              v_batch_no          OUT NUMBER)
    IS
        v_pol_no                      VARCHAR2 (26);
        v_ends_no                     VARCHAR2 (26);
        next_ggt_trans_no             NUMBER;
        v_endos_sr                    NUMBER (15);
        v_pol_prefix                  VARCHAR2 (15);
        v_new_ipu_code                NUMBER;
        v_pol_status                  VARCHAR2 (5);
        v_pmode_code                  NUMBER;
        v_base_cur_code               NUMBER;
        v_cnt                         NUMBER;
        v_dates_error                 VARCHAR2 (200);
        v_endos_count                 NUMBER;
        v_curr_batch_no               NUMBER;
        v_pro_sht_desc                VARCHAR2 (50);
        v_noyrstautoradclient_param   NUMBER;
        v_auto_grad_clnt_param        VARCHAR2 (1) := 'N';
        v_renewal_cnt                 NUMBER;
        next_ggts_trans_no            NUMBER;
        v_rn_cnt                      NUMBER;
        v_pdl_code                    NUMBER;
        v_re_cnt                      NUMBER;
        v_count                       NUMBER;
        v_agent_code                  NUMBER;
        v_agents_status               VARCHAR (15);
        v_blacklist_status            VARCHAR2 (400) := 'N';

        CURSOR cur_taxes (v_batch      NUMBER,
                          vtranstype   VARCHAR2,
                          vprocode     NUMBER)
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
                   ptx_tax_type
              FROM gin_ren_policy_taxes, gin_transaction_types
             WHERE     ptx_trac_trnt_code = trnt_code
                   AND ptx_pol_batch_no = v_batch
                   AND NVL (
                           DECODE (vtranstype,
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

        --TRNT_RENEWAL_ENDOS != 'N';
        CURSOR cur_coinsurer (v_batch NUMBER)
        IS
            SELECT *
              FROM gin_ren_coinsurers
             WHERE coin_pol_batch_no = v_batch;

        CURSOR cur_facre_dtls (v_batch NUMBER)
        IS
            SELECT *
              FROM gin_ren_facre_in_dtls
             WHERE fid_pol_batch_no = v_batch;

        CURSOR cur_conditions (v_batch NUMBER)
        IS
            SELECT *
              FROM gin_ren_policy_lvl_clauses
             WHERE plcl_pol_batch_no = v_batch;

        CURSOR cur_schedule_values (v_batch NUMBER)
        IS
            SELECT *
              FROM gin_ren_pol_schedule_values
             WHERE schpv_pol_batch_no = v_batch;

        CURSOR cur_pol_perils (v_batch NUMBER)
        IS
            SELECT *
              FROM gin_ren_policy_section_perils
             WHERE pspr_pol_batch_no = v_batch;

        CURSOR cur_insureds (v_batch NUMBER)
        IS
            SELECT *
              FROM gin_ren_policy_insureds
             WHERE polin_pol_batch_no = v_batch;

        CURSOR cur_ipu (v_batch NUMBER, v_polin_code NUMBER)
        IS
            SELECT *
              FROM gin_ren_insured_property_unds
             WHERE     ipu_pol_batch_no = v_batch
                   AND ipu_polin_code = v_polin_code;

        CURSOR cur_limits (v_ipu NUMBER)
        IS
              SELECT *
                FROM gin_ren_policy_insured_limits
               WHERE pil_ipu_code = v_ipu
            ORDER BY pil_code, pil_calc_group, pil_row_num;

        CURSOR cur_clauses (v_ipu NUMBER)
        IS
            SELECT *
              FROM gin_ren_policy_clauses
             WHERE pocl_ipu_code = v_ipu;

        CURSOR cur_rsk_perils (v_ipu VARCHAR2)
        IS
            SELECT *
              FROM tq_gis.gin_pol_ren_rsk_section_perils
             WHERE prspr_ipu_code = v_ipu;

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
              FROM gin_ren_pol_sec_perils
             WHERE gpsp_ipu_code = v_ipu;

        CURSOR risk_excesses (v_ipu NUMBER)
        IS
            SELECT *
              FROM gin_ren_risk_excess
             WHERE re_ipu_code = v_ipu;

        CURSOR schedules (v_ipu NUMBER)
        IS
            SELECT *
              FROM gin_ren_policy_risk_schedules
             WHERE polrs_ipu_code = v_ipu;

        CURSOR pol IS
            SELECT gin_ren_policies.*, 'Y' pol_pop_taxes
              FROM gin_ren_policies
             WHERE pol_batch_no = v_pol_batch_no;

        CURSOR cur_coagencies IS
            SELECT *
              FROM gin_policy_coagencies
             WHERE coagn_pol_batch_no = v_pol_batch_no;

        /* CURSOR cur_rcpt
         IS
            SELECT *
              FROM gin_master_transactions
             WHERE mtran_pol_batch_no = v_pol_batch_no
               AND mtran_tran_type = 'RC'
               AND mtran_balance <> 0;*/

        CURSOR cur_rcpt (v_pol_renewal_batch NUMBER)
        IS
            SELECT gin_master_transactions.*
              FROM gin_master_transactions, gin_gis_transmitals
             WHERE     mtran_tran_type = 'RC'
                   AND mtran_pol_batch_no = v_pol_batch_no
                   AND ggts_pol_renewal_batch = v_pol_renewal_batch
                   AND ggts_pol_batch_no = mtran_pol_batch_no
                   AND ggts_uw_clm_tran = 'RN'
                   AND mtran_balance = mtran_net_amt;

        CURSOR pol_dtls IS
            SELECT *
              FROM gin_renwl_sbudtls
             WHERE pdl_pol_batch_no = v_pol_batch_no;

        CURSOR risk_services (v_ipu NUMBER)
        IS
            SELECT *
              FROM gin_policy_ren_risk_services
             WHERE prs_ipu_code = v_ipu;

        CURSOR cur_subclass_conditions (v_btch NUMBER)
        IS
            --         SELECT *
            --           FROM gin_policy_subclass_clauses
            --          WHERE poscl_pol_batch_no = v_btch;
            SELECT *
              FROM gin_policy_subclass_clauses
             WHERE     poscl_pol_batch_no = v_btch
                   AND poscl_cls_code IN
                           (SELECT DISTINCT SBCL_CLS_CODE
                              FROM gin_subcl_clauses
                             WHERE     NVL (sbcl_cls_mandatory, 'N') = 'Y'
                                   AND poscl_scl_code = sbcl_scl_code);
    --
    --      CURSOR cur_other_rn_trans (v_pol_policy_no IN VARCHAR2, v_uw_yr IN NUMBER)
    --      IS
    --         SELECT   pol_policy_cover_to, pol_policy_cover_from
    --             FROM gin_policies
    --            WHERE pol_batch_no = v_pol_batch_no;
    --              AND pol_uw_year = v_uw_yr
    --              AND pol_current_status != 'CO'
    --         ORDER BY pol_wef_dt;
    BEGIN
        --   RAISE_ERROR('I'||';'||v_pol_batch_no);
        IF v_user IS NULL
        THEN
            raise_error ('User not defined.');
        END IF;

        v_dates_error :=
            gin_uw_author_proc.check_ren_pol_coverdates (v_pol_batch_no);

        IF v_dates_error IS NOT NULL
        THEN
            raise_error (v_dates_error);
        END IF;

        FOR p IN pol
        LOOP
            BEGIN
                v_auto_grad_clnt_param :=
                    gin_parameters_pkg.get_param_varchar (
                        'AUTO_GRADUATE_CLIENT');
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    v_auto_grad_clnt_param := 'N';
                WHEN OTHERS
                THEN
                    raise_error (
                        'Error getting parameter AUTO_GRADUATE_CLIENT');
            END;

            --      RAISE_ERROR(p.pol_renewal_batch);

            IF NVL (v_auto_grad_clnt_param, 'N') = 'Y'
            THEN
                BEGIN
                    v_noyrstautoradclient_param :=
                        gin_parameters_pkg.get_param_varchar (
                            'NO_YRS_TO_AUTO_GRAD_CLIENT');
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        raise_error (
                            'The parameter NO_YRS_TO_AUTO_GRAD_CLIENT not defined');
                    WHEN OTHERS
                    THEN
                        raise_error (
                            'Error Getting parameter NO_YRS_TO_AUTO_GRAD_CLIENT');
                END;
            END IF;

            --21-02-17
            --Raise_error ('HERE'||v_pol_batch_no);
            BEGIN
                SELECT pol_agnt_agent_code
                  INTO v_agent_code
                  FROM gin_ren_policies
                 WHERE pol_batch_no = v_pol_batch_no;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    NULL;
            END;

            BEGIN
                SELECT agn_status
                  INTO v_agents_status
                  FROM tqc_agencies
                 WHERE agn_code = v_agent_code;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    NULL;
            END;

            --RAISE_ERROR('v_agents_status'||v_agents_status||'v_agent_code'||v_agent_code);
            IF NVL (v_agents_status, 'ACTIVE') = UPPER ('INACTIVE')
            THEN
                raise_error (
                    'The agent is inactive. Please update the agent to continue...');
            END IF;


            BEGIN
                SELECT NVL (
                           GIN_STP_UW_PKG.CHECK_BLACKLIST_STATUS (
                               v_pol_batch_no),
                           'N')
                  INTO v_blacklist_status
                  FROM DUAL;
            END;

            IF v_blacklist_status != 'N'
            THEN
                raise_error (
                       'The transaction has the following blacklisted items: '
                    || v_blacklist_status);
            END IF;

            --21-02-17
            BEGIN
                SELECT pro_policy_prefix, pro_sht_desc
                  INTO v_pol_prefix, v_pro_sht_desc
                  FROM gin_products
                 WHERE pro_code = p.pol_pro_code;

                IF v_pol_prefix IS NULL
                THEN
                    raise_error (
                           'The policy prefix for the product '
                        || p.pol_pro_sht_desc
                        || ' is not defined in the setup');
                END IF;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    raise_error (
                           'The product '
                        || p.pol_pro_sht_desc
                        || ' is not defined in the setup');
                WHEN OTHERS
                THEN
                    raise_error (
                           'Unable to retrieve the policy prefix for the product '
                        || p.pol_pro_sht_desc);
            END;

            IF p.pol_policy_status = 'RE'    -- further investigation required
            THEN
                BEGIN
                    SELECT COUNT (1)
                      INTO v_re_cnt
                      FROM gin_policies uw
                     WHERE     uw.pol_batch_no = p.pol_batch_no
                           AND uw.pol_policy_status IN ('L', 'CN')
                           AND uw.pol_uw_year = p.pol_uw_year
                           AND (   (    p.pol_policy_cover_from >=
                                        uw.pol_policy_cover_from
                                    AND p.pol_policy_cover_from <
                                        uw.pol_policy_cover_to)
                                OR (    p.pol_policy_cover_to >=
                                        uw.pol_policy_cover_from
                                    AND p.pol_policy_cover_to <=
                                        uw.pol_policy_cover_to)
                                OR (    uw.pol_policy_cover_from >=
                                        p.pol_policy_cover_from
                                    AND uw.pol_policy_cover_from <=
                                        p.pol_policy_cover_to)
                                OR (    uw.pol_policy_cover_to >
                                        p.pol_policy_cover_from
                                    AND uw.pol_policy_cover_to <=
                                        p.pol_policy_cover_to));
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error (
                            'Unable to retrieve policy transaction details..');
                END;
            -- raise_Error(' pol_policy_status= '||p.pol_policy_status
            --||'='||v_re_cnt||'='||p.pol_uw_year||'='||p.pol_policy_no||'='||p.pol_batch_no);
            ELSE
                BEGIN
                    SELECT COUNT (1)
                      INTO v_rn_cnt
                      FROM gin_policies
                     WHERE     pol_policy_no = p.pol_policy_no
                           AND pol_policy_status = 'RN'
                           AND pol_uw_year = p.pol_uw_year
                           AND pol_current_status != 'CO';
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error (
                            'Unable to retrieve policy transaction details..');
                END;
            END IF;

            --         IF NVL (v_re_cnt, 0) != 0
            --         THEN
            --            FOR r IN cur_other_rn_trans (p.pol_policy_no, p.pol_uw_year)
            --            LOOP
            --               IF p.pol_policy_cover_from BETWEEN r.pol_policy_cover_to
            --                                                 AND r.pol_policy_cover_from
            --                  OR p.pol_policy_cover_to BETWEEN r.pol_policy_cover_to
            --                                               AND r.pol_policy_cover_from
            --                  OR r.pol_policy_cover_to BETWEEN p.pol_policy_cover_from
            --                                               AND p.pol_policy_cover_to
            --                  OR r.pol_policy_cover_from BETWEEN p.pol_policy_cover_from
            --                                                 AND p.pol_policy_cover_to
            --               THEN
            --                  raise_error
            --                     (   'A renewal transaction for this policy for UW year '
            --                      || p.pol_uw_year
            --                      || ' and overlapping dates already exists. Cannot renew for this UW Year..'
            --                     );
            --               END IF;
            --            END LOOP;
            --         END IF;
            IF NVL (v_re_cnt, 0) != 0
            THEN
                NULL; --REINSTATEMENT OF A CANCELLED POLICY SHOULD REINSTATE THE CANCELLED PERIOD. THIS CHECK EXPERSSLY DENIES THAT.
            --         raise_error
            --            (   'A renewal transaction for this policy for UW year '
            --             || p.pol_uw_year
            --             || ' and overlapping dates already exists. Cannot renew for this UW Year..'
            --            );
            END IF;

            IF NVL (v_rn_cnt, 0) != 0
            THEN
                BEGIN
                    SELECT COUNT (1)
                      INTO v_cnt
                      FROM gin_policies uw, gin_ren_policies ren
                     WHERE     uw.pol_policy_no = ren.pol_policy_no
                           AND uw.pol_policy_no = p.pol_policy_no
                           AND uw.pol_current_status NOT IN ('CO', 'CN')
                           AND (   (    ren.pol_policy_cover_from >=
                                        uw.pol_policy_cover_from
                                    AND ren.pol_policy_cover_from <
                                        uw.pol_policy_cover_to)
                                OR (    ren.pol_policy_cover_to >=
                                        uw.pol_policy_cover_from
                                    AND ren.pol_policy_cover_to <=
                                        uw.pol_policy_cover_to)
                                OR (    uw.pol_policy_cover_from >=
                                        ren.pol_policy_cover_from
                                    AND uw.pol_policy_cover_from <=
                                        ren.pol_policy_cover_to)
                                OR (    uw.pol_policy_cover_to >
                                        ren.pol_policy_cover_from
                                    AND uw.pol_policy_cover_to <=
                                        ren.pol_policy_cover_to));
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        v_cnt := 0;
                    WHEN OTHERS
                    THEN
                        raise_error (
                            'Error checking overlapping policy cover date');
                END;

                IF NVL (v_cnt, 0) != 0
                THEN
                    raise_error (
                           'A renewal transaction for this policy for UW year '
                        || p.pol_uw_year
                        || ' and overlapping dates already exists. Cannot renew for this UW Year..');
                END IF;
            END IF;

            BEGIN
                get_endos_seq (v_pol_prefix,
                               p.pol_brn_code,
                               TO_NUMBER (TO_CHAR (p.pol_wef_dt, 'RRRR')),
                               v_endos_sr);
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error (
                        'Unable to retrieve the policy endorsement sequence number');
            END;

            v_pol_no := p.pol_policy_no;

            BEGIN
                v_ends_no :=
                    gin_sequences_pkg.get_number_format ('E',
                                                         p.pol_pro_code,
                                                         p.pol_brn_code,
                                                         p.pol_uw_year,
                                                         --TO_NUMBER(TO_CHAR(P1.POL_UW_YEAR,'RRRR')),
                                                         p.pol_policy_status,
                                                         NULL,
                                                         'N',
                                                         v_pol_no);

                BEGIN
                    SELECT COUNT (1)
                      INTO v_count
                      FROM gin_policies
                     WHERE     pol_policy_no = v_pol_no
                           AND pol_ren_endos_no = v_ends_no;

                    IF v_count > 0
                    THEN
                        v_ends_no :=
                            gin_sequences_pkg.get_number_format (
                                'E',
                                p.pol_pro_code,
                                p.pol_brn_code,
                                p.pol_uw_year,
                                --TO_NUMBER(TO_CHAR(P1.POL_UW_YEAR,'RRRR')),
                                p.pol_policy_status,
                                NULL,
                                'N',
                                p.pol_ren_endos_no);
                    END IF;
                END;
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error ('Error generating endorsement number..');
            END;

            BEGIN
                SELECT COUNT (*)
                  INTO v_endos_count
                  FROM gin_policies
                 WHERE pol_policy_no = v_pol_no;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    v_endos_count := 0;
                WHEN OTHERS
                THEN
                    raise_error ('Error Getting number of endorsements...');
            END;

            IF p.pol_ren_endos_no = v_pol_no || '/' || v_endos_count
            THEN
                v_ends_no := v_pol_no || '/' || (v_endos_count + 1);
            -- THIS IS FOR AIICO SOLO> WHERE SOME TRANSACTIONS GENERATED A WRONG ENDORSEMENT FOR ENDORSEMENT NUMBER 1
            END IF;

            SELECT    TO_NUMBER (TO_CHAR (SYSDATE, 'RRRR'))
                   || gin_pol_batch_no_seq.NEXTVAL
              INTO v_batch_no
              FROM DUAL;

            SELECT pol_pmod_code
              INTO v_pmode_code
              FROM gin_policies
             WHERE pol_batch_no = p.pol_batch_no;

            --Insert intO policies table
            ---curr rate
            IF p.pol_cur_rate IS NULL
            THEN
                BEGIN
                    SELECT org_cur_code
                      INTO v_base_cur_code
                      FROM tqc_organizations
                     WHERE org_code = 2;
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        v_cnt := 0;
                    WHEN OTHERS
                    THEN
                        raise_error ('Unable to retrieve the base currency');
                END;

                IF v_base_cur_code IS NULL
                THEN
                    raise_error (
                        'The base currency have not been dedfined. Cannot proceed.');
                END IF;

                p.pol_cur_rate :=
                    get_exchange_rate (v_base_cur_code,
                                       p.pol_cur_code,
                                       TRUNC (SYSDATE));
            END IF;

            IF p.pol_cur_rate IS NULL
            THEN
                raise_error ('Cannot proceed when currency rate is NULL');
            END IF;

            IF NVL (v_auto_grad_clnt_param, 'N') = 'Y'
            THEN
                BEGIN
                      SELECT COUNT (1)
                        INTO v_renewal_cnt
                        FROM gin_policies
                       WHERE     pol_policy_status = 'RN'
                             AND pol_policy_no = p.pol_policy_no
                    GROUP BY pol_policy_no;
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        v_renewal_cnt := 0;
                    WHEN OTHERS
                    THEN
                        raise_error ('Error Getting Renewal Count');
                END;

                --raise_error(v_auto_grad_clnt_param||'='||v_renewal_cnt||'='||v_noyrstautoradclient_param||'='||p.pol_prp_code);
                IF v_noyrstautoradclient_param = v_renewal_cnt
                THEN
                    UPDATE tqc_clients
                       SET clnt_client_level = 'V'
                     WHERE clnt_code = p.pol_prp_code;
                END IF;
            END IF;

            --This is a bug on reinstatement. Commented by Peter
            --         BEGIN
            --         SELECT POL_BATCH_NO INTO v_curr_batch_no
            --         FROM GIN_POLICIES
            --         WHERE pol_policy_no =p.pol_policy_no
            --         AND POL_CURRENT_STATUS='A';
            --         EXCEPTION
            --         WHEN NO_DATA_FOUND THEN
            --          raise_error ('There is a pending endorsement that needs to be authorised..');
            --         END;
            --RAISE_ERROR('p.pol_pro_interface_type '||p.pol_pro_interface_type);
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
                                          pol_total_sum_insured,
                                          pol_policy_status,
                                          pol_comm_amt,
                                          pol_comm_rate,
                                          pol_inception_dt,
                                          pol_tran_type,
                                          pol_acpr_code,
                                          pol_acpr_sht_desc,
                                          pol_alp_proposal_no,
                                          pol_reinsured,
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
                                          pol_old_policy_no,
                                          pol_commission_allowed,
                                          pol_pip_code,
                                          pol_pmod_code,
                                          pol_div_code,
                                          pol_sub_agn_code,
                                          pol_sub_agn_sht_desc,
                                          pol_sub_agn_comm_amt,
                                          pol_lta_comm_endos_amt,
                                          pol_lta_comm_amt,
                                          pol_mktr_agn_code,
                                          pol_mktr_com_amt,
                                          pol_bussiness_growth_type,
                                          pol_subagent,
                                          pol_ipf_nof_instals,
                                          pol_coagent,
                                          pol_coagent_main_pct,
                                          pol_agn_discounted,
                                          pol_agn_disc_type,
                                          pol_agn_discount,
                                          pol_uw_period,
                                          pol_tot_instlmt,
                                          pol_open_cover,
                                          pol_summary_remarks,
                                          pol_policy_debit,
                                          pol_scheme_policy,
                                          pol_pro_interface_type,
                                          pol_joint,
                                          pol_joint_prp_code,
                                          pol_intro_code,
                                          pol_policy_doc,
                                          pol_freq_of_payment,
                                          pol_instlmt_day,
                                          pol_enforce_sf_param,
                                          pol_pay_method,
                                          pol_old_policy_number,
                                          pol_open_policy,
                                          pol_old_agent,
                                          pol_health_tax,
                                          pol_road_safety_tax,
                                          pol_motor_levy,
                                          pol_client_vat_amt,
                                          pol_instlmt_prem,
                                          pol_instlmt_amt,
                                          pol_cr_date_notified,
                                          pol_cr_note_number,
                                          pol_admin_fee_allowed,
                                          pol_cashback_appl,
                                          pol_pop_taxes,
                                          pol_uw_only,
                                          pol_debiting_type)
                         VALUES (
                                    p.pol_policy_no,
                                    v_ends_no,
                                    v_batch_no,
                                    p.pol_agnt_agent_code,
                                    p.pol_agnt_sht_desc,
                                    p.pol_bind_code,
                                    p.pol_wef_dt,
                                    p.pol_wet_dt,
                                    p.pol_uw_year,
                                    p.pol_total_sum_insured,
                                    p.pol_policy_status,
                                    p.pol_comm_amt,
                                    p.pol_comm_rate,
                                    p.pol_inception_dt,
                                    p.pol_tran_type,
                                    p.pol_acpr_code,
                                    p.pol_acpr_sht_desc,
                                    p.pol_alp_proposal_no,
                                    'N',
                                    p.pol_basic_premium,
                                    p.pol_nett_premium,
                                    p.pol_cur_code,
                                    v_user,
                                    TRUNC (SYSDATE),
                                    --p.pol_prepared_date,
                                    p.pol_checked_by,
                                    p.pol_check_date,
                                    p.pol_policy_type,
                                    p.pol_conversion_rate,
                                    p.pol_policy_no,
                                    p.pol_brn_code,
                                    p.pol_business_type,
                                    p.pol_cur_rate,
                                    p.pol_curr_rate_type,
                                    p.pol_comm_endos_diff_amt,
                                    p.pol_total_fap,
                                    p.pol_total_gp,
                                    p.pol_tot_endos_diff_amt,
                                    p.pol_coinsurance,
                                    p.pol_coinsure_leader,
                                    p.pol_fp,
                                    p.pol_post_status,
                                    p.pol_drcr_no,
                                    p.pol_cur_symbol,
                                    p.pol_post_ok,
                                    p.pol_brn_sht_desc,
                                    p.pol_prp_code,
                                    p.pol_current_status,
                                    p.pol_authosrised,
                                    p.pol_cancel_dt,
                                    p.pol_inception_uwyr,
                                    p.pol_pro_code,
                                    p.pol_btr_code,
                                    p.pol_btr_trans_code,
                                    p.pol_your_ref,
                                    p.pol_prop_holding_co_prp_code,
                                    p.pol_oth_int_parties,
                                    NVL (p.pol_pro_sht_desc, v_pro_sht_desc),
                                    p.pol_batch_no,
                                    p.pol_uwyr_length,
                                    p.pol_binder_policy,
                                    p.pol_bind_pro_code,
                                    p.pol_bind_pro_sht_desc,
                                    p.pol_remarks,
                                    p.pol_coinsure_pct,
                                    p.pol_renewed_rec,
                                    NVL (p.pol_renewable, 'Y'),
                                    p.pol_policy_cover_to,
                                    p.pol_policy_cover_from,
                                    p.pol_si_diff,
                                    p.pol_wtht,
                                    p.pol_prem_tax,
                                    p.pol_mar_cert_no,
                                    p.pol_coinsurance_share,
                                    p.pol_coin_tot_prem,
                                    p.pol_coin_endos_prem,
                                    p.pol_coin_tot_si,
                                    p.pol_renewal_dt,
                                    p.pol_prev_prem,
                                    p.pol_ri_agnt_agent_code,
                                    p.pol_ri_agnt_sht_desc,
                                    p.pol_ri_agent_comm_rate,
                                    p.pol_wet_dt,
                                    p.pol_old_policy_no,
                                    p.pol_commission_allowed,
                                    p.pol_pip_code,
                                    v_pmode_code,
                                    p.pol_div_code,
                                    p.pol_sub_agn_code,
                                    p.pol_sub_agn_sht_desc,
                                    p.pol_sub_agn_comm_amt,
                                    p.pol_lta_comm_amt,
                                    p.pol_lta_comm_amt,
                                    p.pol_mktr_agn_code,
                                    p.pol_mktr_com_amt,
                                    gin_stp_uw_pkg.get_growth_type (
                                        p.pol_prp_code,
                                        p.pol_policy_status,
                                        p.pol_policy_no,
                                        v_batch_no),
                                    p.pol_subagent,
                                    p.pol_ipf_nof_instals,
                                    p.pol_coagent,
                                    p.pol_coagent_main_pct,
                                    p.pol_agn_discounted,
                                    p.pol_agn_disc_type,
                                    p.pol_agn_discount,
                                      NVL (p.pol_uw_period, 1)
                                    + DECODE (p.pol_policy_status,
                                              'RN', 1,
                                              'EX', 1,
                                              0),
                                    p.pol_tot_instlmt,
                                    p.pol_open_cover,
                                    p.pol_summary_remarks,
                                    p.pol_policy_debit,
                                    p.pol_scheme_policy,
                                    p.pol_pro_interface_type,
                                    p.pol_joint,
                                    p.pol_joint_prp_code,
                                    p.pol_intro_code,
                                    p.pol_policy_doc,
                                    p.pol_freq_of_payment,
                                    p.pol_instlmt_day,
                                    p.pol_enforce_sf_param,
                                    p.pol_pay_method,
                                    p.pol_old_policy_number,
                                    p.pol_open_policy,
                                    p.pol_old_agent,
                                    p.pol_health_tax,
                                    p.pol_road_safety_tax,
                                    p.pol_motor_levy,
                                    p.pol_client_vat_amt,
                                    p.pol_instlmt_prem,
                                    p.pol_instlmt_amt,
                                    p.pol_cr_date_notified,
                                    p.pol_cr_note_number,
                                    p.pol_admin_fee_allowed,
                                    p.pol_cashback_appl,
                                    NVL (p.pol_pop_taxes, 'Y'),
                                    p.pol_uw_only,
                                    p.pol_debiting_type);
            --message('after pol');pause;
            --COMMIT;
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error (
                        ' Fatal Error , creating policy endorsement record....');
            END;

            BEGIN
                --message('posting policy specific details oldbatch='||P.POL_BATCH_NO||'new batch='||v_batch_no);pause;
                insert_policy_spec_details (p.pol_pro_code,
                                            p.pol_batch_no,
                                            v_batch_no,
                                            'U');
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error (
                        'Unable to populate policy specific details');
            END;

            BEGIN
                --message('posting policy specific details oldbatch='||P.POL_BATCH_NO||'new batch='||v_batch_no);pause;
                gin_agency_web_pkg.update_uw_policydtls (p.pol_batch_no,
                                                         v_batch_no);
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error (
                        'Unable to populate policy specific details');
            END;

            BEGIN
                SELECT    TO_NUMBER (TO_CHAR (SYSDATE, 'YY'))
                       || ggt_trans_no_seq.NEXTVAL
                  INTO next_ggt_trans_no
                  FROM DUAL;

                --SELECT USER INTO v_user FROM DUAL;
                --v_user := 'MSHOTE';
                INSERT INTO gin_gis_transactions (ggt_doc_ref,
                                                  ggt_trans_no,
                                                  ggt_pol_policy_no,
                                                  ggt_cmb_claim_no,
                                                  ggt_pol_batch_no,
                                                  ggt_btr_trans_code,
                                                  ggt_done_by,
                                                  ggt_done_date,
                                                  ggt_client_policy_number,
                                                  ggt_uw_clm_tran,
                                                  ggt_trans_date,
                                                  ggt_trans_authorised,
                                                  ggt_pro_code,
                                                  ggt_pro_sht_desc)
                     VALUES ('Renewal',
                             next_ggt_trans_no,
                             p.pol_policy_no,
                             NULL,
                             v_batch_no,
                             'RN',
                             v_user,
                             SYSDATE,
                             p.pol_policy_no,
                             'U',
                             TRUNC (SYSDATE),
                             'N',
                             p.pol_pro_code,
                             p.pol_pro_sht_desc);
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error (
                        'Error unable to creaete a transaction record. Contact the system administrator...');
            END;

            FOR r IN cur_rcpt (p.pol_renewal_batch)
            LOOP
                UPDATE gin_master_transactions
                   SET mtran_pol_batch_no = v_batch_no
                 WHERE mtran_no = r.mtran_no;
            END LOOP;

            BEGIN
                UPDATE gin_gis_transmitals
                   SET ggts_pol_batch_no = v_batch_no, ggts_uw_clm_tran = 'U'
                 WHERE ggts_pol_renewal_batch = p.pol_renewal_batch;
            EXCEPTION
                WHEN OTHERS
                THEN
                    NULL;
            END;

            FOR pdl IN pol_dtls
            LOOP
                BEGIN
                    SELECT    TO_NUMBER (TO_CHAR (SYSDATE, 'YY'))
                           || gin_pdl_code_seq.NEXTVAL
                      INTO v_pdl_code
                      FROM DUAL;

                    --SELECT USER INTO v_user FROM DUAL;
                    --v_user := 'MSHOTE';
                    INSERT INTO gin_policy_sbu_dtls (pdl_code,
                                                     pdl_pol_batch_no,
                                                     pdl_unit_code,
                                                     pdl_location_code,
                                                     pdl_prepared_date)
                         VALUES (v_pdl_code,
                                 v_batch_no,
                                 pdl.pdl_unit_code,
                                 pdl.pdl_location_code,
                                 TRUNC (SYSDATE));
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error (
                            'Error unable to creaete a transaction record. Contact the system administrator...');
                END;
            END LOOP;

            --OPEN CUR_TAXES
            FOR cur_tax_rec
                IN cur_taxes (p.pol_batch_no,
                              p.pol_policy_status,
                              p.pol_pro_code)
            LOOP
                --INSERTING INTO GIN_POLICY_TAXES
                BEGIN
                    INSERT INTO gin_policy_taxes (ptx_trac_trnt_code,
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
                                                  ptx_trac_scl_code)
                         VALUES (cur_tax_rec.ptx_trac_trnt_code,
                                 cur_tax_rec.ptx_pol_policy_no,
                                 v_ends_no,
                                 v_batch_no,
                                 cur_tax_rec.ptx_rate,
                                 cur_tax_rec.ptx_amount,
                                 cur_tax_rec.ptx_tl_lvl_code,
                                 cur_tax_rec.ptx_rate_type,
                                 cur_tax_rec.ptx_rate_desc,
                                 cur_tax_rec.ptx_endos_diff_amt,
                                 cur_tax_rec.ptx_tax_type,
                                 cur_tax_rec.ptx_trac_scl_code);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error (
                            ' Error creating policy tax record. Contact the system administrator...');
                END;
            END LOOP;

            --***** Insert FACRE IN Details *******
            BEGIN
                FOR cur_facre_dtls_rec IN cur_facre_dtls (p.pol_batch_no)
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
                END LOOP;
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error (' Unable to insert facre details...');
            END;

            FOR cur_coagencies_rec IN cur_coagencies
            LOOP
                INSERT INTO gin_policy_coagencies (coagn_code,
                                                   coagn_agn_code,
                                                   coagn_pct,
                                                   coagn_pol_batch_no,
                                                   coagn_comm_amt,
                                                   coagn_prem_amt)
                     VALUES (gin_co_code_seq.NEXTVAL,
                             cur_coagencies_rec.coagn_agn_code,
                             cur_coagencies_rec.coagn_pct,
                             v_batch_no,
                             cur_coagencies_rec.coagn_comm_amt,
                             cur_coagencies_rec.coagn_prem_amt);
            END LOOP;

            --COMMIT;
            --OPEN COINSURER
            FOR cur_coinsurer_rec IN cur_coinsurer (p.pol_batch_no)
            LOOP
                --INSERT INTO GIN_COINSURERS
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
                                                coin_comm_rate)
                         VALUES (cur_coinsurer_rec.coin_agnt_agent_code,
                                 cur_coinsurer_rec.coin_agnt_sht_desc,
                                 cur_coinsurer_rec.coin_gl_code,
                                 cur_coinsurer_rec.coin_lead,
                                 cur_coinsurer_rec.coin_perct,
                                 cur_coinsurer_rec.coin_prem,
                                 cur_coinsurer_rec.coin_pol_policy_no,
                                 v_ends_no,
                                 v_batch_no,
                                 cur_coinsurer_rec.coin_fee_rate,
                                 cur_coinsurer_rec.coin_fee_amt,
                                 cur_coinsurer_rec.coin_duties,
                                 cur_coinsurer_rec.coin_si,
                                 cur_coinsurer_rec.coin_optional_comm,
                                 cur_coinsurer_rec.coin_comm_rate);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error (
                            '  Error creating policy coinsurance record. Contact the system administrator...');
                END;
            END LOOP;

            --     COMMIT;
            FOR cur_subclass_conditions_rec
                IN cur_subclass_conditions (p.pol_batch_no)
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
                                        v_batch_no,
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

            --OPEN CONDITIONS
            FOR cur_conditions_rec IN cur_conditions (p.pol_batch_no)
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
                        raise_error (
                            '  Error creating policy clauses record. Contact the system administrator...');
                END;
            END LOOP;

            FOR cur_schedule_values_rec
                IN cur_schedule_values (p.pol_batch_no)
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
                                 v_batch_no,
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

            FOR cur_pol_perils_rec IN cur_pol_perils (p.pol_batch_no)
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
                                 v_batch_no,
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

            BEGIN
                UPDATE gin_policy_subclass_clauses
                   SET poscl_new = 'N'
                 WHERE poscl_pol_policy_no = p.pol_policy_no;
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error ('Unable to update subclass clause status');
            END;

            -- Insert Insureds
            --OPEN cur_insureds
            FOR cur_insureds_rec IN cur_insureds (p.pol_batch_no)
            LOOP
                BEGIN
                    INSERT INTO gin_policy_insureds (polin_code,
                                                     polin_pa,
                                                     polin_pol_policy_no,
                                                     polin_pol_ren_endos_no,
                                                     polin_pol_batch_no,
                                                     polin_category,
                                                     polin_prp_code,
                                                     polin_new_insured)
                             VALUES (
                                        TO_NUMBER (
                                               TO_CHAR (SYSDATE, 'RRRR')
                                            || polin_code_seq.NEXTVAL),
                                        NULL,
                                        p.pol_policy_no,
                                        v_ends_no,
                                        v_batch_no,
                                        NULL,
                                        cur_insureds_rec.polin_prp_code,
                                        cur_insureds_rec.polin_new_insured);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error (
                            ' Error creating insureds record. Contact the system administrator...');
                END;

                --Insert Insured Risks
                FOR cur_ipu_rec
                    IN cur_ipu (p.pol_batch_no, cur_insureds_rec.polin_code)
                LOOP
                    SELECT TO_NUMBER (
                                  TO_CHAR (SYSDATE, 'RRRR')
                               || gin_ipu_code_seq.NEXTVAL)
                      INTO v_new_ipu_code
                      FROM DUAL;

                    -- DO YOUR INSERTS INTO ipu
                    BEGIN
                        --message('cur_ipu_rec.IPU_UW_YR='||cur_ipu_rec.IPU_UW_YR);pause;
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
                                        ipu_ri_agnt_comm_amt,
                                        ipu_tot_fap,
                                        ipu_max_dc_refund_pct,
                                        ipu_uw_yr,
                                        ipu_tot_first_loss,
                                        ipu_accumulation_limit,
                                        ipu_compute_max_exposure,
                                        ipu_status,
                                        ipu_inception_uwyr,
                                        ipu_trans_eff_wet,
                                        ipu_eml_based_on,
                                        ipu_aggregate_limits,
                                        ipu_rc_sht_desc,
                                        ipu_rc_code,
                                        ipu_survey_date,
                                        ipu_item_details,
                                        ipu_sub_agn_comm_rate,
                                        ipu_sub_agn_comm_amt,
                                        ipu_lta_endos_com_amt,
                                        ipu_lta_commission,
                                        ipu_lta_comm_rate,
                                        ipu_conveyance_type,
                                        ipu_prev_status,
                                        ipu_install_period,
                                        ipu_pymt_install_pcts,
                                        ipu_susp_reinstmt_type,
                                        ipu_rs_code,
                                        ipu_rescue_mem,
                                        ipu_rescue_charge,
                                        ipu_next_inst_prem,
                                        ipu_drcr_no,
                                        ipu_wtht,
                                        ipu_post_retro_wet,
                                        ipu_post_retro_cover,
                                        ipu_health_tax,
                                        ipu_road_safety_tax,
                                        ipu_motor_levy,
                                        ipu_client_vat_amt,
                                        ipu_cashback_appl,
                                        ipu_cashback_level,
                                        ipu_risk_note,
                                        ipu_other_com_charges,
                                        ipu_model_yr,
                                        ipu_vehicle_model,
                                        ipu_vehicle_make,
                                        ipu_vehicle_model_code,
                                        ipu_vehicle_make_code,
                                        ipu_loc_town,
                                        ipu_prop_address)
                                 VALUES (
                                            v_new_ipu_code,
                                            cur_ipu_rec.ipu_property_id,
                                            cur_ipu_rec.ipu_item_desc,
                                            cur_ipu_rec.ipu_qty,
                                            cur_ipu_rec.ipu_value,
                                            p.pol_wef_dt,
                                            p.pol_wet_dt,
                                            p.pol_policy_no,
                                            v_ends_no,
                                            v_batch_no,
                                            cur_ipu_rec.ipu_basic_premium,
                                            cur_ipu_rec.ipu_nett_premium,
                                            cur_ipu_rec.ipu_compulsory_excess,
                                            cur_ipu_rec.ipu_add_theft_excess,
                                            cur_ipu_rec.ipu_add_exp_excess,
                                            cur_ipu_rec.ipu_prr_rate,
                                            cur_ipu_rec.ipu_comp_retention,
                                            cur_ipu_rec.ipu_pol_est_max_loss,
                                            cur_ipu_rec.ipu_avail_fulc_bal,
                                            cur_ipu_rec.ipu_endos_diff_amt,
                                            cur_ipu_rec.ipu_prem_wef,
                                            cur_ipu_rec.ipu_earth_quake_cover,
                                            cur_ipu_rec.ipu_earth_quake_prem,
                                            cur_ipu_rec.ipu_location,
                                            cur_ipu_rec.ipu_itl,
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
                                            cur_ipu_rec.ipu_bp,
                                            cur_ipu_rec.ipu_gp,
                                            DECODE (cur_ipu_rec.ipu_fp,
                                                    0, NULL,
                                                    cur_ipu_rec.ipu_fp),
                                            cur_ipu_rec.ipu_fap,
                                            cur_ipu_rec.ipu_prev_ipu_code,
                                            cur_ipu_rec.ipu_cummulative_reins,
                                            cur_ipu_rec.ipu_eml_si,
                                            cur_ipu_rec.ipu_reinsured,
                                            cur_ipu_rec.ipu_ct_code,
                                            cur_ipu_rec.ipu_sht_desc,
                                            cur_ipu_rec.ipu_quz_code,
                                            cur_ipu_rec.ipp_quz_sht_desc,
                                            cur_ipu_rec.ipu_quz_sht_desc,
                                            cur_ipu_rec.ipu_ncl_level,
                                            cur_ipu_rec.ipu_ncd_level,
                                            cur_ipu_rec.ipu_id,
                                            cur_ipu_rec.ipu_gross_comp_retention,
                                            cur_ipu_rec.ipu_bind_code,
                                            cur_ipu_rec.ipu_commission,
                                            cur_ipu_rec.ipu_comm_endos_diff_amt,
                                            cur_ipu_rec.ipu_facre_amount,
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
                                            cur_ipu_rec.ipu_reinsure_amt,
                                            cur_ipu_rec.ipu_prp_code,
                                            cur_ipu_rec.ipu_max_exposure,
                                            cur_ipu_rec.ipu_com_retention_rate,
                                            cur_ipu_rec.ipu_retro_cover,
                                            cur_ipu_rec.ipu_retro_wef,
                                            cur_ipu_rec.ipu_eff_wef,
                                            cur_ipu_rec.ipu_eff_wet,
                                            cur_ipu_rec.ipu_comments,
                                            cur_ipu_rec.ipu_covt_code,
                                            cur_ipu_rec.ipu_covt_sht_desc,
                                            cur_ipu_rec.ipu_si_diff,
                                            cur_ipu_rec.ipu_terr_code,
                                            cur_ipu_rec.ipu_terr_desc,
                                            cur_ipu_rec.ipu_from_time,
                                            cur_ipu_rec.ipu_to_time,
                                            cur_ipu_rec.ipu_tot_endos_prem_dif,
                                            cur_ipu_rec.ipu_tot_gp,
                                            cur_ipu_rec.ipu_tot_value,
                                            cur_ipu_rec.ipu_cover_days,
                                            cur_ipu_rec.ipu_grp_si_risk_pct,
                                            cur_ipu_rec.ipu_grp_top_loc,
                                            cur_ipu_rec.ipu_grp_comp_gross_ret,
                                            cur_ipu_rec.ipu_grp_comp_net_ret,
                                            cur_ipu_rec.ipu_prev_prem,
                                            cur_ipu_rec.ipu_ri_agnt_com_rate,
                                            cur_ipu_rec.ipu_ri_agnt_comm_amt,
                                            cur_ipu_rec.ipu_tot_fap,
                                            cur_ipu_rec.ipu_max_dc_refund_pct,
                                            cur_ipu_rec.ipu_uw_yr,
                                            cur_ipu_rec.ipu_tot_first_loss,
                                            cur_ipu_rec.ipu_accumulation_limit,
                                            cur_ipu_rec.ipu_compute_max_exposure,
                                            'RN',
                                            cur_ipu_rec.ipu_inception_uwyr,
                                            p.pol_wet_dt,
                                            cur_ipu_rec.ipu_eml_based_on,
                                            cur_ipu_rec.ipu_aggregate_limits,
                                            cur_ipu_rec.ipu_rc_sht_desc,
                                            cur_ipu_rec.ipu_rc_code,
                                            cur_ipu_rec.ipu_survey_date,
                                            cur_ipu_rec.ipu_item_details,
                                            cur_ipu_rec.ipu_sub_agn_comm_rate,
                                            cur_ipu_rec.ipu_sub_agn_comm_amt,
                                            cur_ipu_rec.ipu_lta_commission,
                                            cur_ipu_rec.ipu_lta_commission,
                                            cur_ipu_rec.ipu_lta_comm_rate,
                                            cur_ipu_rec.ipu_conveyance_type,
                                            'RN',
                                            cur_ipu_rec.ipu_install_period,
                                            cur_ipu_rec.ipu_pymt_install_pcts,
                                            cur_ipu_rec.ipu_susp_reinstmt_type,
                                            cur_ipu_rec.ipu_rs_code,
                                            cur_ipu_rec.ipu_rescue_mem,
                                            cur_ipu_rec.ipu_rescue_charge,
                                            cur_ipu_rec.ipu_next_inst_prem,
                                            cur_ipu_rec.ipu_drcr_no,
                                            cur_ipu_rec.ipu_wtht,
                                            cur_ipu_rec.ipu_post_retro_wet,
                                            cur_ipu_rec.ipu_post_retro_cover,
                                            cur_ipu_rec.ipu_health_tax,
                                            cur_ipu_rec.ipu_road_safety_tax,
                                            cur_ipu_rec.ipu_motor_levy,
                                            cur_ipu_rec.ipu_client_vat_amt,
                                            cur_ipu_rec.ipu_cashback_appl,
                                            cur_ipu_rec.ipu_cashback_level,
                                            cur_ipu_rec.ipu_risk_note,
                                            cur_ipu_rec.ipu_other_com_charges,
                                            cur_ipu_rec.ipu_model_yr,
                                            cur_ipu_rec.ipu_vehicle_model,
                                            cur_ipu_rec.ipu_vehicle_make,
                                            cur_ipu_rec.ipu_vehicle_model_code,
                                            cur_ipu_rec.ipu_vehicle_make_code,
                                            cur_ipu_rec.ipu_loc_town,
                                            cur_ipu_rec.ipu_prop_address);
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            raise_error (
                                ' Error creating risk endorsement record. Contact the system administrator...');
                    END;

                    BEGIN
                        gin_stp_uw_pkg.populate_cert_to_print (v_batch_no);
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            raise_error (
                                   'Error allocating certificates at step 1....'
                                || SQLERRM (SQLCODE));
                    END;

                    /*    -- POPULATE MANDATORY SECTIONS
                        BEGIN
                            Gin_Stp_Pkg.pop_mand_policy_rsk_limits(cur_ipu_rec.ipu_code,
                                                                                                    cur_ipu_rec.ipu_sec_scl_code,
                                                                                                    cur_ipu_rec.ipu_bind_code,
                                                                                                    cur_ipu_rec.ipu_covt_code);
                        EXCEPTION
                                WHEN OTHERS THEN
                                    raise_error('Error populating mandatory sections...');
                        END;*/
                    --OPEN LIMITS
                    FOR cur_peril_rec
                        IN cur_rsk_perils (cur_ipu_rec.ipu_code)
                    LOOP
                        --                  BEGIN
                        --                  --    message('inserting risk GIN_POLICY_CLAUSES ...');pause;
                        --                  INSERT INTO gin_pol_risk_section_perils
                        --                              (prspr_code, prspr_pol_batch_no,
                        --                               prspr_ipu_code,
                        --                               prspr_scl_code,
                        --                               prspr_sect_code,
                        --                               prspr_sect_sht_desc,
                        --                               prspr_per_code,
                        --                               prspr_per_sht_desc,
                        --                               prspr_mandatory,
                        --                               prspr_peril_limit,
                        --                               prspr_peril_type,
                        --                               prspr_si_or_limit,
                        --                               prspr_sec_code,
                        --                               prspr_excess_type,
                        --                               prspr_excess,
                        --                               prspr_excess_min,
                        --                               prspr_excess_max,
                        --                               prspr_expire_on_claim,
                        --                               prspr_bind_code,
                        --                               prspr_person_limit,
                        --                               prspr_claim_limit,
                        --                               prspr_desc,
                        --                               prspr_bind_type,
                        --                               prspr_sspr_code,
                        --                               prspr_salvage_pct,
                        --                               prspr_claim_excess_type,
                        --                               prspr_tl_excess_type,
                        --                               prspr_tl_excess,
                        --                               prspr_tl_excess_min,
                        --                               prspr_tl_excess_max,
                        --                               prspr_pl_excess_type,
                        --                               prspr_pl_excess,
                        --                               prspr_pl_excess_min,
                        --                               prspr_pl_excess_max,
                        --                               prspr_claim_excess_min,
                        --                               prspr_claim_excess_max,
                        --                               prspr_depend_loss_type,
                        --                             prspr_ttd_ben_pcts
                        --                              )
                        --                       VALUES (gin_prspr_code_seq.NEXTVAL, v_batch_no,
                        --                               v_new_ipu_code,
                        --                               cur_rsk_perils_rec.prspr_scl_code,
                        --                               cur_rsk_perils_rec.prspr_sect_code,
                        --                               cur_rsk_perils_rec.prspr_sect_sht_desc,
                        --                               cur_rsk_perils_rec.prspr_per_code,
                        --                               cur_rsk_perils_rec.prspr_per_sht_desc,
                        --                               cur_rsk_perils_rec.prspr_mandatory,
                        --                               cur_rsk_perils_rec.prspr_peril_limit,
                        --                               cur_rsk_perils_rec.prspr_peril_type,
                        --                               cur_rsk_perils_rec.prspr_si_or_limit,
                        --                               cur_rsk_perils_rec.prspr_sec_code,
                        --                               cur_rsk_perils_rec.prspr_excess_type,
                        --                               cur_rsk_perils_rec.prspr_excess,
                        --                               cur_rsk_perils_rec.prspr_excess_min,
                        --                               cur_rsk_perils_rec.prspr_excess_max,
                        --                               cur_rsk_perils_rec.prspr_expire_on_claim,
                        --                               cur_rsk_perils_rec.prspr_bind_code,
                        --                               cur_rsk_perils_rec.prspr_person_limit,
                        --                               cur_rsk_perils_rec.prspr_claim_limit,
                        --                               cur_rsk_perils_rec.prspr_desc,
                        --                               cur_rsk_perils_rec.prspr_bind_type,
                        --                               cur_rsk_perils_rec.prspr_sspr_code,
                        --                               cur_rsk_perils_rec.prspr_salvage_pct,
                        --                               cur_rsk_perils_rec.prspr_claim_excess_type,
                        --                               cur_rsk_perils_rec.prspr_tl_excess_type,
                        --                               cur_rsk_perils_rec.prspr_tl_excess,
                        --                               cur_rsk_perils_rec.prspr_tl_excess_min,
                        --                               cur_rsk_perils_rec.prspr_tl_excess_max,
                        --                               cur_rsk_perils_rec.prspr_pl_excess_type,
                        --                               cur_rsk_perils_rec.prspr_pl_excess,
                        --                               cur_rsk_perils_rec.prspr_pl_excess_min,
                        --                               cur_rsk_perils_rec.prspr_pl_excess_max,
                        --                               cur_rsk_perils_rec.prspr_claim_excess_min,
                        --                               cur_rsk_perils_rec.prspr_claim_excess_max,
                        --                               cur_rsk_perils_rec.prspr_depend_loss_type,
                        --                               cur_rsk_perils_rec.prspr_ttd_ben_pcts
                        --                              );
                        --               EXCEPTION
                        --                  WHEN OTHERS
                        --                  THEN
                        --                     raise_error
                        --                           ('Unable to insert risk level clause details, ...');
                        --               END;
                        NULL;
                    END LOOP;

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
                                            pil_eml_pct,
                                            pil_top_loc_rate,
                                            pil_top_loc_div_fact,
                                            pil_declaration_section,
                                            pil_free_limit,
                                            pil_prorata_full,
                                            pil_prr_max_rate,
                                            pil_prr_min_rate,
                                            pil_free_limit_amt,
                                            pil_prev_endr_prem_rate,
                                            pil_prev_endr_rate_div_fact,
                                            pil_prev_endr_mult_rate,
                                            pil_prev_endr_mult_div_fact)
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
                                                cur_limits_rec.pil_limit_amt,
                                                cur_limits_rec.pil_prem_rate,
                                                cur_limits_rec.pil_prem_amt,
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
                                                cur_limits_rec.pil_annual_premium,
                                                cur_limits_rec.pil_rate_div_fact,
                                                cur_limits_rec.pil_min_premium,
                                                cur_limits_rec.pil_desc,
                                                cur_limits_rec.pil_compute,
                                                cur_limits_rec.pil_used_limit,
                                                cur_limits_rec.pil_indem_prd,
                                                cur_limits_rec.pil_prd_type,
                                                cur_limits_rec.pil_indem_fstprd,
                                                cur_limits_rec.pil_indem_fstprd_pct,
                                                cur_limits_rec.pil_indem_remprd_pct,
                                                cur_limits_rec.pil_dual_basis,
                                                cur_limits_rec.pil_eml_pct,
                                                cur_limits_rec.pil_top_loc_rate,
                                                cur_limits_rec.pil_top_loc_div_fact,
                                                cur_limits_rec.pil_declaration_section,
                                                cur_limits_rec.pil_free_limit,
                                                NVL (
                                                    cur_limits_rec.pil_prorata_full,
                                                    'F'),
                                                cur_limits_rec.pil_prr_max_rate,
                                                cur_limits_rec.pil_prr_min_rate,
                                                cur_limits_rec.pil_free_limit_amt,
                                                cur_limits_rec.pil_prem_rate,
                                                cur_limits_rec.pil_rate_div_fact,
                                                cur_limits_rec.pil_multiplier_rate,
                                                cur_limits_rec.pil_multiplier_div_factor);
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                raise_error (
                                    '  Error creating risk section record. Contact the system administrator...');
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
                                            pocl_heading)
                                 VALUES (cur_clauses_rec.pocl_sbcl_cls_code,
                                         cur_clauses_rec.pocl_sbcl_scl_code,
                                         cur_clauses_rec.pocl_cls_sht_desc,
                                         p.pol_policy_no,
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
                                raise_error (
                                    '  Error creating risk clauses record. Contact the system administrator...');
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
                    END LOOP;

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
                    END LOOP;

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
                                raise_error (
                                    ' Error creating risk schedules record. Contact the system administrator...');
                        END;
                    END LOOP;

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
                                         v_batch_no,
                                         p.pol_policy_no,
                                         v_ends_no,
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

                    BEGIN
                        gin_schedules_pkg.insert_spec_details (
                            p.pol_pro_code,
                            cur_ipu_rec.ipu_code,
                            v_new_ipu_code,
                            'Y',
                            'RN-UW');
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            ROLLBACK;
                            raise_error (
                                ' Unable to insert specific details...');
                    END;
                END LOOP;
            END LOOP;

            BEGIN
                UPDATE gin_policy_renewals
                   SET pren_status = 'U'
                 WHERE pren_pol_batch_no = p.pol_batch_no;
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_when_others (
                        'Unbale to update the renewal status..2');
            END;

            UPDATE gin_policies
               SET pol_renewed_rec = 'Y'
             WHERE pol_batch_no = p.pol_batch_no;

            BEGIN
                --DEL_RENWL_TABLES_POL_DETAILS ( P.POL_POLICY_NO);
                --MESSAGE('=TTTTTTT='||P.POL_batch_no);PAUSE;
                BEGIN
                    SELECT pol_policy_status
                      INTO v_pol_status
                      FROM gin_policies
                     WHERE     pol_batch_no = p.pol_batch_no
                           AND pol_policy_no = p.pol_policy_no;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        v_pol_status := 'RN';
                --raise_error('Unable to retrieve policy status..');
                END;

                --MESSAGE(P.POL_batch_no);PAUSE;
                --   commit;
                --RAISE_ERROR(v_pol_status||';'||P.POL_batch_no);
                --IF NVL(v_pol_status,'XX') IN  ('RN','RE') THEN

                BEGIN
                    UPDATE GIN_REN_POLICIES_LOGS
                       SET POL_POLICY_RENEWED = 'Y',
                           POL_RENEWED_BY = v_user,
                           POL_RENEWED_DATE = TRUNC (SYSDATE)
                     WHERE     POL_RENEWAL_BATCH = P.POL_RENEWAL_BATCH
                           AND POL_BATCH_NO = P.POL_BATCH_NO;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        NULL;
                END;

                del_ren_pol_proc (p.pol_batch_no);
            --END IF;
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error (
                           ' Unable to clear the renewal record...'
                        || p.pol_batch_no
                        || 'p.pol_batch_no');
            END;
        END LOOP;
    END;