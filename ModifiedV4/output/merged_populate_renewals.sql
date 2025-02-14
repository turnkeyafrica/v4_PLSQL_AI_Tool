```sql
PROCEDURE populate_renewals (v_trans_id IN NUMBER, v_user VARCHAR2)
    IS
        v_pol_wet_date                 DATE;
        v_ren_polin_code               NUMBER;
        v_pol_wef                      DATE;
        --v_ren_param VARCHAR2(5);
        v_new_ipu_code                 NUMBER;
        --v_del_err NUMBER;
        v_ren_date                     DATE;
        v_cnt                          NUMBER;
        v_msg                          VARCHAR2 (200);
        v_ncd_status                   NUMBER := 0;
        v_ncd_level                    NUMBER := 0;
        v_max_ncd_level                NUMBER := 0;
        v_prr_rate                     NUMBER := 0;
        v_prr_multiplier_rate          NUMBER := 0;
        v_prr_division_factor          NUMBER := 0;
        v_prr_multplier_div_fact       NUMBER := 0;
        v_sect_desc                    VARCHAR2 (30);
        v_ncd_rate                     NUMBER := 0;
        v_process_ncd                  VARCHAR (1);
        v_old_risk                     VARCHAR (1);
        v_ncd_created                  BOOLEAN := TRUE;
        v_sect_type                    VARCHAR2 (10);
        v_sect_sht_desc                VARCHAR2 (30);
        v_check_max                    BOOLEAN := FALSE;
        v_new_sect_code                NUMBER;
        v_cnt_ncd                      NUMBER := 0;
        v_new_rate                     VARCHAR2 (1);
        v_count                        NUMBER;
        v_load_sect_code               VARCHAR2 (30);
        v_decload_created              BOOLEAN := TRUE;
        v_new_prr_rate_desc            VARCHAR2 (30);
        v_new_prr_rate_type            VARCHAR2 (30);
        v_new_prr_rate                 NUMBER;
        v_new_prr_multiplier_rate      NUMBER;
        v_new_prr_division_factor      NUMBER;
        v_new_prr_multplier_div_fact   NUMBER;
        v_new_sect_type                VARCHAR2 (30);
        v_new_sect_desc                VARCHAR2 (30);
        v_serial                       VARCHAR2 (30);
        v_tran_ref_no                  VARCHAR2 (30);
        next_ggts_trans_no             NUMBER;
        v_pdl_code                     NUMBER;
        v_clms_cnt                     NUMBER;
        v_risk_cnt                     NUMBER;
        -- v_ncd_status                   NUMBER         := 0;
        v_cashback_level               NUMBER := 0;
        v_max_cashback_level           NUMBER := 0;
        v_renewal_param                VARCHAR2 (1) := 'N';

        v_prr_prem_minimum_amt         gin_premium_rates.prr_prem_minimum_amt%TYPE;
        v_prr_rate_desc                gin_premium_rates.prr_rate_desc%TYPE;
        v_prr_free_limit               gin_premium_rates.prr_free_limit%TYPE;
        v_sec_declaration              gin_subcl_sections.sec_declaration%TYPE;
        v_scvts_order                  gin_subcl_covt_sections.scvts_order%TYPE;
        v_prr_prorated_full            gin_premium_rates.prr_prorated_full%TYPE;
        v_prr_si_limit_type            gin_premium_rates.prr_si_limit_type%TYPE;
        v_prr_si_rate                  gin_premium_rates.prr_si_rate%TYPE;
        v_sc_range                     NUMBER;
        v_scvts_order1                 NUMBER;
        v_scvts_calc_group             NUMBER;
        sect_cursor                    SYS_REFCURSOR;
        v_motor_prd                    VARCHAR2 (1);
        v_sec_code                     gin_sections.sect_code%TYPE;
        -- v_sect_type                gin_sections.sect_type%TYPE;
        v_type_desc                    VARCHAR2 (25);
        v_prr_rate_type                gin_premium_rates.prr_rate_type%TYPE;
        --v_prr_rate                 gin_premium_rates.prr_rate%TYPE;
        v_terr_description             VARCHAR2 (5);
        v_butcharge_fap                VARCHAR2 (5);

        CURSOR cur_taxes (v_batch NUMBER, vprocode NUMBER)
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
                   ptx_coin_other_client_chrgs,
                   ptx_override,
                   ptx_override_amt
              FROM gin_policy_taxes, gin_transaction_types
             WHERE     ptx_trac_trnt_code = trnt_code
                   AND ptx_pol_batch_no = v_batch
                   AND NVL (trnt_apply_rn, 'Y') = 'Y'
                   AND trnt_code NOT IN (SELECT petx_trnt_code
                                           FROM gin_product_excluded_taxes
                                          WHERE petx_pro_code = vprocode);

        CURSOR renewals IS
            SELECT *
              FROM gin_web_renewals, gin_policies
             WHERE     webr_pol_batch_no = pol_batch_no
                   AND webr_trans_id = v_trans_id;

        CURSOR cur_coinsurer (v_batch NUMBER)
        IS
            SELECT *
              FROM gin_coinsurers
             WHERE coin_pol_batch_no = v_batch;

        CURSOR cur_facre_dtls (v_batch NUMBER)
        IS
            SELECT *
              FROM gin_facre_in_dtls
             WHERE fid_pol_batch_no = v_batch;

        CURSOR cur_conditions (v_batch NUMBER)
        IS
            SELECT *
              FROM gin_policy_lvl_clauses
             WHERE plcl_pol_batch_no = v_batch;

        CURSOR cur_subclass_conditions (v_btch NUMBER)
        IS
            SELECT *
              FROM gin_policy_subclass_clauses
             WHERE poscl_pol_batch_no = v_btch;

        CURSOR cur_schedule_values (v_batch NUMBER)
        IS
            SELECT *
              FROM gin_pol_schedule_values
             WHERE schpv_pol_batch_no = v_batch;

        CURSOR cur_pol_perils (v_batch NUMBER)
        IS
            SELECT *
              FROM gin_policy_section_perils
             WHERE pspr_pol_batch_no = v_batch;

        CURSOR cur_insureds (v_batch NUMBER)
        IS
            SELECT DISTINCT polin_prp_code
              FROM gin_policy_insureds
             WHERE EXISTS
                       (SELECT ipu_polin_code
                          FROM gin_insured_property_unds
                         WHERE     ipu_polin_code = polin_code
                               AND EXISTS
                                       (SELECT polar_ipu_code
                                          FROM gin_policy_active_risks
                                         WHERE     polar_ipu_code = ipu_code
                                               AND polar_pol_batch_no =
                                                   v_batch));

        CURSOR cur_ipu (v_batch      NUMBER,
                        vv_pol_wet   DATE,
                        v_prp_code   NUMBER,
                        v_loaded     VARCHAR2)
        IS
            SELECT *
              FROM gin_insured_property_unds,
                   gin_policy_insureds,
                   gin_sub_classes
             WHERE     ipu_code IN (SELECT polar_ipu_code
                                      FROM gin_policy_active_risks
                                     WHERE polar_pol_batch_no = v_batch)
                   --AND ipu_eff_wet = vv_pol_wet
                   AND ipu_eff_wet =
                       DECODE (v_loaded, 'N', vv_pol_wet, ipu_eff_wet)
                   AND polin_code = ipu_polin_code
                   AND polin_prp_code = v_prp_code
                   AND NVL (ipu_endos_remove, 'N') = 'N'
                   AND gin_stp_claims_pkg.claim_total_loss (ipu_id) != 'Y'
                   AND ipu_sec_scl_code = scl_code;

        CURSOR cur_limits (v_ipu NUMBER)
        IS
              SELECT *
                FROM gin_policy_insured_limits
               WHERE pil_ipu_code = v_ipu
            ORDER BY pil_code;

        CURSOR new_cur_limits (v_new_ipu_code   NUMBER,
                               v_scl_code       NUMBER,
                               v_bind_code      NUMBER,
                               v_cvt_code       NUMBER,
                               v_sect_code      NUMBER)
        IS
            SELECT DISTINCT
                   sect_sht_desc,
                   sect_code,
                   sect_desc || ' ' || prr_ncd_level
                       sect_desc,
                   sect_type,
                   DECODE (sect_type,
                           'ND', 'NCD ' || prr_ncd_level,
                           'ES', 'Extension SI',
                           'EL', 'Extension Limit',
                           'SS', 'Section SI',
                           'SL', 'Section Limit',
                           'DS', 'Discount',
                           'LO', 'Loading',
                           'EC', 'Escalation')
                       type_desc,
                   prr_rate_type,
                   DECODE (prr_rate_type,  'SRG', 0,  'RCU', 0,  prr_rate)
                       prr_rate,
                   DECODE (prr_rate_type,  'SRG', 0,  'RCU', 0,  prr_rate)
                       rate,
                   '0'
                       terr_description,
                   DECODE (prr_rate_type,
                           'SRG', 0,
                           'RCU', 0,
                           prr_prem_minimum_amt)
                       prr_prem_minimum_amt,
                   DECODE (prr_rate_type,
                           'SRG', 1,
                           'RCU', 1,
                           prr_multiplier_rate)
                       prr_multiplier_rate,
                   DECODE (prr_rate_type,
                           'SRG', 1,
                           'RCU', 1,
                           prr_division_factor)
                       prr_division_factor,
                   DECODE (prr_rate_type,
                           'SRG', 1,
                           'RCU', 1,
                           prr_multplier_div_fact)
                       prr_multplier_div_fact,
                   prr_rate_desc,
                   prr_free_limit,
                   prr_prorated_full
              FROM gin_premium_rates, gin_sections
             WHERE     prr_sect_code = v_sect_code
                   AND prr_scl_code = v_scl_code
                   AND prr_bind_code = v_bind_code
                   AND prr_ncd_level = 0
                   AND sect_type = 'ND'
                   AND sect_code IN
                           (SELECT scvts_sect_code
                              FROM gin_subcl_covt_sections
                             WHERE     scvts_scl_code = v_scl_code
                                   AND scvts_covt_code = v_cvt_code)
                   AND sect_code NOT IN
                           (SELECT pil_sect_code
                              FROM gin_ren_policy_insured_limits
                             WHERE pil_ipu_code = v_new_ipu_code);

        CURSOR cur_clauses (v_ipu NUMBER)
        IS
            SELECT *
              FROM gin_policy_clauses
             WHERE pocl_ipu_code = v_ipu;

        CURSOR cur_rsk_perils (v_ipu VARCHAR2)
        IS
            SELECT *
              FROM gin_pol_risk_section_perils
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

        CURSOR cur_pol_dtls (v_batch NUMBER)
        IS
            SELECT *
              FROM gin_policy_sbu_dtls
             WHERE pdl_pol_batch_no = v_batch;

        CURSOR risk_services (v_ipu NUMBER)
        IS
            SELECT *
              FROM gin_policy_risk_services
             WHERE prs_ipu_code = v_ipu;
    /*CURSOR cur_superintendent
        IS SELECT *
          FROM GIN_POL_SUPERINTENDENT
          WHERE PSURT_POL_BATCH_NO=v_batch;*/
    /*CURSOR cur_ncd_sec(v_scl_code NUMBER,v_bind_code NUMBER, v_level NUMBER)
                        IS SELECT DISTINCT PRR_RATE,
                        PRR_MULTIPLIER_RATE,PRR_DIVISION_FACTOR,
                        PRR_MULTPLIER_DIV_FACT
                        FROM GIN_PREMIUM_RATES,GIN_SECTIONS
                        WHERE  PRR_SECT_CODE = SECT_CODE
                        AND PRR_SCL_CODE = v_scl_code
                        AND PRR_BIND_CODE = v_bind_code
                        AND SECT_TYPE ='ND'
                        AND PRR_NCD_LEVEL =v_level;*/
    BEGIN
        --       raise_error ('User not defined.');
        IF v_user IS NULL
        THEN
            raise_error ('User not defined.');
        END IF;

        BEGIN
            v_renewal_param :=
                GIN_PARAMETERS_PKG.GET_PARAM_VARCHAR (
                    'RENEWAL_BASED_ON_SETUP');
        EXCEPTION
            WHEN OTHERS
            THEN
                v_renewal_param := 'N';
        END;

        BEGIN
            SELECT param_value
              INTO v_butcharge_fap
              FROM gin_parameters
             WHERE param_name = 'BUT_CHARGE_FAP' AND param_status = 'ACTIVE';
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                v_butcharge_fap := 'N';
            WHEN OTHERS
            THEN
                raise_error (
                    'Error fetching the BUT_CHARGE_FAP parameter,Check parameter setup...');
        END;


        FOR pr IN renewals
        LOOP
            BEGIN
                del_ren_pol_proc (pr.pol_batch_no);
            EXCEPTION
                WHEN OTHERS
                THEN
                    ROLLBACK;
                    raise_error (
                        'Unable to execute del_ren_pol_proc for batch:' || pr.pol_batch_no ||
                        'Error:' || sqlerrm);
            END;

            SELECT pol_wet, pol_wef, pol_ren_date
              INTO v_pol_wet_date, v_pol_wef, v_ren_date
              FROM gin_policies
             WHERE pol_batch_no = pr.pol_batch_no;

            SELECT COUNT (*)
              INTO v_cnt
              FROM gin_ren_policies
             WHERE pol_batch_no = pr.pol_batch_no;

            IF v_cnt > 0
            THEN
                v_msg := 'Renewal Already Created for the Policy Batch No: ' ||
                         pr.pol_batch_no;
                raise_application_error (-20001, v_msg);
            END IF;

            INSERT INTO gin_ren_policies (
                pol_batch_no,
                pol_renewal_status,
                pol_renewal_date,
                pol_created_by,
                pol_created_date
            ) VALUES (
                pr.pol_batch_no,
                'P',
                v_ren_date,
                v_user,
                SYSDATE
            );

            -- Policy Level Taxes
            FOR tx IN cur_taxes (pr.pol_batch_no, pr.pol_pro_code)
            LOOP
                INSERT INTO gin_ren_policy_taxes (
                    ptx_trac_scl_code,
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
                    ptx_coin_other_client_chrgs,
                    ptx_override,
                    ptx_override_amt
                ) VALUES (
                    tx.ptx_trac_scl_code,
                    tx.ptx_trac_trnt_code,
                    tx.ptx_pol_policy_no,
                    tx.ptx_pol_ren_endos_no,
                    pr.pol_batch_no,
                    tx.ptx_rate,
                    tx.ptx_amount,
                    tx.ptx_tl_lvl_code,
                    tx.ptx_rate_type,
                    tx.ptx_rate_desc,
                    tx.ptx_endos_diff_amt,
                    tx.ptx_tax_type,
                    tx.ptx_coin_other_client_chrgs,
                     tx.ptx_override,
                     tx.ptx_override_amt
                );
            END LOOP;
            -- End Policy Level Taxes

            -- Coinsurers
            FOR cr IN cur_coinsurer (pr.pol_batch_no)
            LOOP
                INSERT INTO gin_ren_coinsurers (
                    coin_pol_batch_no,
                    coin_code,
                    coin_share,
                    coin_created_by,
                    coin_created_date
                ) VALUES (
                    pr.pol_batch_no,
                    cr.coin_code,
                    cr.coin_share,
                    v_user,
                    SYSDATE
                );
            END LOOP;
            -- End Coinsurers
            --Fac Re Details
            FOR fr IN cur_facre_dtls (pr.pol_batch_no)
            LOOP
                INSERT INTO gin_ren_facre_in_dtls (
                    fid_pol_batch_no,
                    fid_fac_code,
                    fid_share,
                    fid_created_by,
                    fid_created_date
                ) VALUES (
                    pr.pol_batch_no,
                    fr.fid_fac_code,
                    fr.fid_share,
                    v_user,
                    SYSDATE
                );
            END LOOP;
            --End Fac Re Details
            -- Policy Level Clauses
            FOR cnd IN cur_conditions (pr.pol_batch_no)
            LOOP
                INSERT INTO gin_ren_policy_lvl_clauses (
                    plcl_pol_batch_no,
                    plcl_clau_code,
                    plcl_created_by,
                    plcl_created_date
                ) VALUES (
                    pr.pol_batch_no,
                    cnd.plcl_clau_code,
                    v_user,
                    SYSDATE
                );
            END LOOP;
            -- End Policy Level Clauses

            -- Policy Subclass Clauses
            FOR scnd IN cur_subclass_conditions (pr.pol_batch_no)
            LOOP
                INSERT INTO gin_ren_policy_subclass_clauses (
                    poscl_pol_batch_no,
                    poscl_clau_code,
                    poscl_created_by,
                    poscl_created_date
                ) VALUES (
                    pr.pol_batch_no,
                    scnd.poscl_clau_code,
                    v_user,
                    SYSDATE
                );
            END LOOP;
            -- End Policy Subclass Clauses

            -- Policy Schedule Values
            FOR schv IN cur_schedule_values (pr.pol_batch_no)
            LOOP
                INSERT INTO gin_ren_pol_schedule_values (
                    schpv_pol_batch_no,
                    schpv_schd_code,
                    schpv_value,
                    schpv_created_by,
                    schpv_created_date
                ) VALUES (
                    pr.pol_batch_no,
                    schv.schpv_schd_code,
                    schv.schpv_value,
                    v_user,
                    SYSDATE
                );
            END LOOP;
            -- End Policy Schedule Values
            -- Policy Section Perils
            FOR pprl IN cur_pol_perils (pr.pol_batch_no)
            LOOP
                INSERT INTO gin_ren_policy_section_perils (
                    pspr_pol_batch_no,
                    pspr_per_code,
                    pspr_created_by,
                    pspr_created_date
                ) VALUES (
                    pr.pol_batch_no,
                    pprl.pspr_per_code,
                    v_user,
                    SYSDATE
                );
            END LOOP;
            --End Policy Section Perils
            --Policy SBU Details
            FOR pdtl IN cur_pol_dtls (pr.pol_batch_no)
            LOOP
                INSERT INTO gin_ren_policy_sbu_dtls (
                    pdl_pol_batch_no,
                    pdl_sbu_code,
                    pdl_created_by,
                    pdl_created_date
                ) VALUES (
                    pr.pol_batch_no,
                    pdtl.pdl_sbu_code,
                    v_user,
                    SYSDATE
                );
            END LOOP;
            --End Policy SBU Details
            -- Insured Properties
            FOR ins IN cur_insureds (pr.pol_batch_no)
            LOOP
                FOR ipu_rec IN cur_ipu (pr.pol_batch_no, v_pol_wet_date,
                                       ins.polin_prp_code,
                                       v_renewal_param)
                LOOP
                    v_ncd_created := TRUE;
                    v_decload_created := TRUE;
                    v_new_ipu_code := NULL;
                    v_new_sect_code := NULL;
                    v_new_rate := 'N';
                    v_load_sect_code := NULL;

                    SELECT   NVL (MAX (ggts_trans_no), 0) + 1
                      INTO next_ggts_trans_no
                      FROM gin_global_temp_seq;

                    INSERT INTO gin_global_temp_seq (ggts_trans_no)
                         VALUES (next_ggts_trans_no);

                    INSERT INTO gin_ren_insured_property_unds (
                        ipu_code,
                        ipu_polin_code,
                        ipu_eff_wet,
                        ipu_eff_wep,
                        ipu_sec_scl_code,
                        ipu_location,
                        ipu_created_by,
                        ipu_created_date,
                        ipu_sum_insured,
                        ipu_endos_remove
                    ) VALUES (
                        next_ggts_trans_no,
                        ipu_rec.ipu_polin_code,
                        ipu_rec.ipu_eff_wet,
                        ipu_rec.ipu_eff_wep,
                        ipu_rec.ipu_sec_scl_code,
                        ipu_rec.ipu_location,
                        v_user,
                        SYSDATE,
                        ipu_rec.ipu_sum_insured,
                        ipu_rec.ipu_endos_remove
                    );

                    v_new_ipu_code := next_ggts_trans_no;
                    --NCD Calculation
                    SELECT COUNT (*)
                      INTO v_cnt_ncd
                      FROM gin_sub_classes
                     WHERE scl_code = ipu_rec.ipu_sec_scl_code
                           AND nvl(scl_process_ncd,'N') = 'Y';

                    IF v_cnt_ncd > 0
                    THEN
                        v_process_ncd := 'Y';
                    ELSE
                        v_process_ncd := 'N';
                    END IF;


                    IF v_process_ncd = 'Y'
                    THEN
                        SELECT   NVL (MAX (ncd_level), 0)
                          INTO v_max_ncd_level
                          FROM gin_policy_ncd_dtls
                         WHERE     ncd_ipu_code = ipu_rec.ipu_code
                               AND ncd_pol_batch_no = pr.pol_batch_no;

                        IF v_max_ncd_level > 0
                        THEN
                            v_ncd_level := v_max_ncd_level;
                        ELSE
                            v_ncd_level := 0;
                        END IF;

                        SELECT   NVL (MAX (ncd_level), 0)
                          INTO v_cashback_level
                          FROM gin_policy_cashback_dtls
                         WHERE     ncd_ipu_code = ipu_rec.ipu_code
                               AND ncd_pol_batch_no = pr.pol_batch_no;

                        SELECT   NVL (MAX (ncd_level), 0)
                          INTO v_max_cashback_level
                          FROM gin_premium_rates
                         WHERE     prr_scl_code = ipu_rec.ipu_sec_scl_code
                               AND prr_bind_code = pr.pol_bind_code
                               AND prr_rate_type = 'CBK';

                        IF v_cashback_level < v_max_cashback_level
                        THEN
                            v_cashback_level := v_cashback_level + 1;
                        END IF;

                        SELECT   prr_rate,
                                 prr_multiplier_rate,
                                 prr_division_factor,
                                 prr_multplier_div_fact
                          INTO v_prr_rate,
                               v_prr_multiplier_rate,
                               v_prr_division_factor,
                               v_prr_multplier_div_fact
                          FROM gin_premium_rates, gin_sections
                         WHERE     prr_sect_code = sect_code
                               AND prr_scl_code = ipu_rec.ipu_sec_scl_code
                               AND prr_bind_code = pr.pol_bind_code
                               AND sect_type = 'ND'
                               AND prr_ncd_level = v_ncd_level;

                        INSERT INTO gin_ren_policy_ncd_dtls (
                            ncd_ipu_code,
                            ncd_pol_batch_no,
                            ncd_level,
                            ncd_rate,
                            ncd_multiplier_rate,
                            ncd_division_factor,
                            ncd_multplier_div_fact,
                            ncd_created_by,
                            ncd_created_date
                        ) VALUES (
                            v_new_ipu_code,
                            pr.pol_batch_no,
                            v_ncd_level,
                            v_prr_rate,
                            v_prr_multiplier_rate,
                            v_prr_division_factor,
                            v_prr_multplier_div_fact,
                            v_user,
                            SYSDATE
                        );
                        
                         INSERT INTO gin_ren_policy_cashback_dtls (
                                    ncd_ipu_code,
                                    ncd_pol_batch_no,
                                    ncd_level,
                                     ncd_created_by,
                                    ncd_created_date
                                ) VALUES (
                                    v_new_ipu_code,
                                    pr.pol_batch_no,
                                    v_cashback_level,
                                    v_user,
                                    SYSDATE
                                );
                    END IF;
					
					--NCD Calculation Ends
                    --limits
                    FOR lmt IN cur_limits (ipu_rec.ipu_code)
                    LOOP
                        INSERT INTO gin_ren_policy_insured_limits (
                            pil_ipu_code,
                            pil_sect_code,
                            pil_limit_amt,
                            pil_created_by,
                            pil_created_date
                        ) VALUES (
                            v_new_ipu_code,
                            lmt.pil_sect_code,
                            lmt.pil_limit_amt,
                            v_user,
                            SYSDATE
                        );
                    END LOOP;

                    --new Limits
                    FOR nwlmt IN new_cur_limits (
                        v_new_ipu_code,
                        ipu_rec.ipu_sec_scl_code,
                        pr.pol_bind_code,
                        ipu_rec.ipu_covt_code,
                        ipu_rec.ipu_sect_code
                    )
                    LOOP
                        INSERT INTO gin_ren_policy_insured_limits (
                            pil_ipu_code,
                            pil_sect_code,
                            pil_limit_amt,
                            pil_created_by,
                            pil_created_date
                        ) VALUES (
                            v_new_ipu_code,
                            nwlmt.sect_code,
                            0,
                            v_user,
                            SYSDATE
                        );
                    END LOOP;
                    --end new limits
                    --clauses
                    FOR clau IN cur_clauses (ipu_rec.ipu_code)
                    LOOP
                        INSERT INTO gin_ren_policy_clauses (
                            pocl_ipu_code,
                            pocl_clau_code,
                            pocl_created_by,
                            pocl_created_date
                        ) VALUES (
                            v_new_ipu_code,
                            clau.pocl_clau_code,
                            v_user,
                            SYSDATE
                        );
                    END LOOP;
                    --end clauses
                    --perils
                    FOR perl IN perils (ipu_rec.ipu_code)
                    LOOP
                        INSERT INTO gin_ren_pol_sec_perils (
                            gpsp_per_code,
                            gpsp_per_sht_desc,
                            gpsp_sec_sect_code,
                            gpsp_sect_sht_desc,
                            gpsp_sec_scl_code,
                            gpsp_ipp_code,
                            gpsp_ipu_code,
                            gpsp_limit_amt,
                            gpsp_excess_amt,
                            gpsp_created_by,
                            gpsp_created_date
                        ) VALUES (
                            perl.gpsp_per_code,
                            perl.gpsp_per_sht_desc,
                            perl.gpsp_sec_sect_code,
                            perl.gpsp_sect_sht_desc,
                            perl.gpsp_sec_scl_code,
                            perl.gpsp_ipp_code,
                            v_new_ipu_code,
                            perl.gpsp_limit_amt,
                            perl.gpsp_excess_amt,
                            v_user,
                            SYSDATE
                        );
                    END LOOP;
                    --end perils
                    --risk excesses
                    FOR rex IN risk_excesses (ipu_rec.ipu_code)
                    LOOP
                        INSERT INTO gin_ren_risk_excess (
                            re_ipu_code,
                            re_excess_code,
                            re_excess_amt,
                            re_created_by,
                            re_created_date
                        ) VALUES (
                            v_new_ipu_code,
                            rex.re_excess_code,
                            rex.re_excess_amt,
                            v_user,
                            SYSDATE
                        );
                    END LOOP;
                    --end risk excesses
                    --risk schedules
                    FOR schd IN schedules (ipu_rec.ipu_code)
                    LOOP
                        INSERT INTO gin_ren_policy_risk_schedules (
                            polrs_ipu_code,
                            polrs_schd_code,
                            polrs_value,
                            polrs_created_by,
                            polrs_created_date
                        ) VALUES (
                            v_new_ipu_code,
                            schd.polrs_schd_code,
                            schd.polrs_value,
                            v_user,
                            SYSDATE
                        );
                    END LOOP;
                    --end risk schedules
                    --risk services
                    FOR rser IN risk_services (ipu_rec.ipu_code)
                    LOOP
                        INSERT INTO gin_ren_policy_risk_services (
                            prs_ipu_code,
                            prs_serv_code,
                            prs_created_by,
                            prs_created_date
                        ) VALUES (
                            v_new_ipu_code,
                            rser.prs_serv_code,
                            v_user,
                            SYSDATE
                        );
                    END LOOP;
					--end risk services
                   --risk perils
                    FOR rprl IN cur_rsk_perils(ipu_rec.ipu_code)
                    LOOP
                       INSERT INTO  gin_ren_pol_risk_section_perils (
                            prspr_ipu_code,
                            prspr_per_code,
                            prspr_created_by,
                            prspr_created_date
                       ) VALUES (
                            v_new_ipu_code,
                            rprl.prspr_per_code,
                            v_user,
                            SYSDATE
                       );
                    END LOOP;
                    --end risk perils

```sql
                END LOOP;
            END LOOP;
            --End Insured Properties
            
            UPDATE gin_ren_policies
               SET pol_renewal_status = 'S'
             WHERE pol_batch_no = pr.pol_batch_no;
        END LOOP;

        COMMIT;
    EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
            raise_error (
                'Error in populate_renewals procedure, error is:' || sqlerrm);
    END;

```