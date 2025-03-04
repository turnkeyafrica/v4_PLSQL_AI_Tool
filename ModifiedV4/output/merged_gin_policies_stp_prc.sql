```sql
PROCEDURE gin_policies_stp_prc (
    v_pro_code        IN   NUMBER,
    v_brn_code        IN   NUMBER,
    v_cover_from      IN   DATE,
    v_cover_to        IN   DATE,
    v_user            IN   VARCHAR2,
    v_cur_code        IN   NUMBER,
    v_prp_code        IN   NUMBER,
    v_bind_code       IN   NUMBER,
    v_rsk_data        IN   web_risk_tab,
    v_uni_code        IN   NUMBER,
    v_loc_code        IN   NUMBER,
    v_agnt_code       IN   NUMBER,
    v_pop_taxes       IN   VARCHAR2,
    v_batchno         OUT  NUMBER
)
IS
    v_cnt                    NUMBER;
    v_new_polin_code         NUMBER;
    v_exp_flag               VARCHAR2 (2);
    v_uw_yr                  VARCHAR2 (1);
    v_open_cover             VARCHAR2 (2);
    v_pol_status             VARCHAR2 (5);
    v_trans_no               NUMBER;
    v_stp_code               NUMBER;
    v_wet_date               DATE;
    v_pol_renewal_dt         DATE;
    v_new_ipu_code          NUMBER;
    v_client_pol_no          VARCHAR2 (45);
    v_end_no                 VARCHAR2 (45);
    v_cur_symbol             VARCHAR2 (15);
    v_cur_rate               NUMBER;
    v_pwet_dt                DATE;
    v_pol_uwyr               NUMBER;
    v_policy_doc             VARCHAR2 (200);
    v_brn_sht_desc           VARCHAR2 (15);
    v_endrsd_rsks_tab        gin_stp_pkg.endrsd_rsks_tab;
    v_rsk_sect_data          web_sect_tab;
    v_admin_fee_applicable   VARCHAR2 (1);
    v_ren_cnt                NUMBER;
    v_admin_disc             NUMBER;
    v_pro_min_prem           NUMBER;
    v_uw_trans               VARCHAR2 (1);
    v_valid_trans            VARCHAR2 (1);
    v_inception_dt           DATE;
    v_inception_yr           NUMBER;
    y                        NUMBER;
    vuser                    VARCHAR2 (35) := pkg_global_vars.get_pvarchar2 ('PKG_GLOBAL_VARS.pvg_username');
    v_seqno                  VARCHAR2 (35);
    v_brn_sht_length         NUMBER;
    v_growth_type            VARCHAR2 (5);
    v_pol_loaded             VARCHAR2 (5);
    v_policy_status          VARCHAR2 (5);
    v_prev_tot_instlmt       NUMBER;
    v_install_pct            NUMBER;
    v_pymnt_tot_instlmt      NUMBER;
    v_ipu_wef                DATE;
    v_ipu_wet                DATE;
    v_install_period         NUMBER;
    v_cover_days             NUMBER;
    v_pro_sht_desc           gin_products.pro_sht_desc%TYPE;
    next_ggts_trans_no       NUMBER;
    v_old_act_code           NUMBER;
    v_new_act_code           NUMBER;
    v_pro_travel_cnt         NUMBER;
    v_ren_wef_dt             DATE;
    v_ren_wet_dt             DATE;
    v_pdl_code               NUMBER;
    v_agnt_agent_code        NUMBER;
    v_seq                    NUMBER;
    v_pol_seq_type           VARCHAR2 (100);
    v_trans_type             VARCHAR2 (5);
    vcur_code                NUMBER;
    v_coinsurance            VARCHAR2 (1);
    v_div_code               NUMBER;
    v_pol_no                 VARCHAR2 (50);
    v_serial_no              NUMBER;
    v_policy_type            VARCHAR2 (50);
    v_binder_policy          VARCHAR2 (2);
    v_agent_code             NUMBER;
    v_agnt_sht_desc          VARCHAR2 (50);
    v_outside_system         VARCHAR2 (1);
    v_interface_type         VARCHAR2 (50);
    v_row                    NUMBER;
    v_comm_allowed           VARCHAR2 (1);
    v_tran_ref_no            VARCHAR2 (100);
    v_serial                 VARCHAR2 (100);
    v_cashback_lvl           NUMBER;
    v_cashback_rate          NUMBER;
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
    
    IF vuser IS NULL THEN
        raise_error('User unknown...');
    END IF;
    
    BEGIN
        SELECT brn_sht_desc
        INTO v_brn_sht_desc
        FROM tqc_branches
        WHERE brn_code = v_brn_code;
    EXCEPTION
        WHEN OTHERS THEN
        raise_error('ERROR GETTING BRANCH DETAILS');
    END;
    
    BEGIN
        SELECT bind_agnt_agent_code
        INTO v_agent_code
        FROM gin_binders
        WHERE bind_code = v_bind_code;
    EXCEPTION
        WHEN OTHERS THEN
        raise_error('ERROR GETTING BINDER DETAILS');
    END;
    
    BEGIN
        SELECT agn_sht_desc
        INTO v_agnt_sht_desc
        FROM tqc_agencies
        WHERE agn_code = v_agnt_code;
    EXCEPTION
        WHEN OTHERS THEN
        raise_error('ERROR GETTING AGENT DETAILS');
    END;
    
    BEGIN
        SELECT pro_interface_type
        INTO v_interface_type
        FROM gin_products
        WHERE pro_code = v_pro_code;
    EXCEPTION
        WHEN OTHERS THEN
        raise_error('ERROR GETTING BINDER DETAILS');
    END;
    
    IF v_cover_from IS NULL OR v_cover_to IS NULL THEN
        raise_error('PROVIDE COVER PERIOD');
    END IF;
    
    v_wet_date := v_cover_to;
    v_cur_rate := v_cur_rate;
    v_pol_renewal_dt := get_renewal_date(v_pro_code, v_wet_date);
    v_uw_trans := 'Y';
    v_trans_type := 'NB';
    v_uw_yr := 'P';
    v_pol_status := 'NB';
    
    IF v_pro_code IS NULL THEN
        raise_error('SELECT THE POLICY PRODUCT ...');
    END IF;
    
    DBMS_OUTPUT.put_line(23);
    
    IF v_bind_code IS NULL THEN
        raise_error('YOU HAVE NOT DEFINED THE BORDEREAUX CODE ..');
    END IF;
    
    v_pol_uwyr := TO_NUMBER(TO_CHAR(v_cover_from, 'RRRR'));
    v_inception_dt := v_cover_from;
    v_inception_yr := v_pol_uwyr;
    DBMS_OUTPUT.put_line(25);
    v_pol_renewal_dt := get_renewal_date(v_pro_code, v_wet_date);
    
    IF v_cur_code IS NULL THEN
        v_cur_rate := NULL;
        BEGIN
            SELECT org_cur_code, cur_symbol
            INTO vcur_code, v_cur_symbol
            FROM tqc_organizations, tqc_systems, tqc_currencies
            WHERE org_code = sys_org_code
            AND org_cur_code = cur_code
            AND sys_code = 37;
        EXCEPTION
            WHEN OTHERS THEN
            raise_error('UNABLE TO RETRIEVE THE BASE CURRENCY');
        END;
        
        IF vcur_code IS NULL THEN
            raise_error('THE BASE CURRENCY HAVE NOT BEEN DEDFINED. CANNOT PROCEED.');
        END IF;
    ELSE
        SELECT cur_code, cur_symbol
        INTO vcur_code, v_cur_symbol
        FROM tqc_currencies
        WHERE cur_code = v_cur_code;
    END IF;
    
    IF v_cur_rate IS NULL THEN
        v_cur_rate := get_exchange_rate(v_cur_code, v_cur_code);
    END IF;
    
    BEGIN
        SELECT NVL(pro_expiry_period, 'Y'), NVL(pro_open_cover, 'N')
        INTO v_exp_flag, v_open_cover
        FROM gin_products
        WHERE pro_code = v_pro_code;
    EXCEPTION
        WHEN OTHERS THEN
        raise_error('ERROR SECURING OPEN COVER STATUS..');
    END;
    
    IF v_pol_no IS NULL OR v_end_no IS NULL OR v_batchno IS NULL THEN
        BEGIN
            gen_pol_numbers(
                v_pro_code,
                v_brn_code,
                v_pol_uwyr,
                v_pol_status,
                v_pol_no,
                v_end_no,
                v_batchno,
                v_serial_no,
                v_policy_type,
                v_coinsurance,
                v_div_code
            );
        EXCEPTION
            WHEN OTHERS THEN
            raise_error('UNABLE TO GENERATE THE POLICY NUMBER...');
        END;
    END IF;
    
    BEGIN
        check_policy_unique(v_pol_no);
    EXCEPTION
        WHEN OTHERS THEN
        BEGIN
            SELECT TO_NUMBER(
                SUBSTR(
                    v_pol_no,
                    DECODE(
                        gin_parameters_pkg.get_param_varchar('POL_SERIAL_AT_END'),
                        'N', DECODE(
                            DECODE(v_policy_type, 'N', 'P', 'F'),
                            'P', gin_parameters_pkg.get_param_varchar('POL_SERIAL_POS'),
                            gin_parameters_pkg.get_param_varchar('POL_FAC_SERIAL_POS')
                        ),
                        LENGTH(v_pol_no) - gin_parameters_pkg.get_param_varchar('POLNOSRLENGTH') + 1
                    ),
                    gin_parameters_pkg.get_param_varchar('POLNOSRLENGTH')
                )
            )
            INTO v_seq
            FROM DUAL;
        EXCEPTION
            WHEN OTHERS THEN
            raise_error('Error Selecting Used Sequence...1');
        END;
        
        BEGIN
            SELECT DECODE(v_policy_type, 'N', 'P', 'F')
            INTO v_pol_seq_type
            FROM DUAL;
            
            gin_sequences_pkg.update_used_sequence(
                v_pol_seq_type,
                v_pro_code,
                v_brn_code,
                v_pol_uwyr,
                v_pol_status,
                v_seq,
                v_pol_no
            );
        EXCEPTION
            WHEN OTHERS THEN
            BEGIN
               SELECT TO_NUMBER(
                   SUBSTR(
                       v_pol_no,
                       DECODE(
                           gin_parameters_pkg.get_param_varchar('POL_SERIAL_AT_END'),
                           'N', DECODE(
                               DECODE(v_policy_type, 'N', 'P', 'F'),
                               'P', gin_parameters_pkg.get_param_varchar('POL_SERIAL_POS'),
                               gin_parameters_pkg.get_param_varchar('POL_FAC_SERIAL_POS')
                           ),
                           LENGTH(v_pol_no) - gin_parameters_pkg.get_param_varchar('POLNOSRLENGTH') + 1
                       ),
                       gin_parameters_pkg.get_param_varchar('POLNOSRLENGTH')
                   )
               )
               INTO v_seqno
               FROM DUAL;
            EXCEPTION
               WHEN OTHERS THEN
               raise_error('Error Selecting Used Sequence...2');
            END;
        
            BEGIN
               SELECT LENGTH(brn_sht_desc)
               INTO v_brn_sht_length
               FROM tqc_branches
               WHERE brn_code = v_brn_code;
            EXCEPTION
                WHEN OTHERS THEN
                    NULL;
            END;
            
            IF NVL(v_brn_sht_length, 0) = 2 THEN
                BEGIN
                    v_seq := TO_NUMBER(v_seqno);
                EXCEPTION
                    WHEN OTHERS THEN
                        NULL;
                END;
            ELSIF NVL(v_brn_sht_length, 0) = 3 THEN
                BEGIN
                    v_seq := TO_NUMBER(SUBSTR(v_seqno, 2));
                EXCEPTION
                    WHEN OTHERS THEN
                        NULL;
                END;
            ELSE
               raise_error('Error here....');
            END IF;
    
            BEGIN
                SELECT DECODE(v_policy_type, 'N', 'P', 'F')
                INTO v_pol_seq_type
                FROM DUAL;
                
               gin_sequences_pkg.update_used_sequence(
                    v_pol_seq_type,
                    v_pro_code,
                    v_brn_code,
                    v_pol_uwyr,
                    v_pol_status,
                    v_seq,
                    v_pol_no
                );
            EXCEPTION
                WHEN OTHERS THEN
                raise_error('ERROR UPDATING USED SEQUENCE...');
            END;
        END;
        raise_error('Error generating Policy number  at step 2' || v_pol_no);
    END;
    
     BEGIN
        SELECT TO_NUMBER(
            SUBSTR(
                v_pol_no,
                 DECODE(
                     gin_parameters_pkg.get_param_varchar('POL_SERIAL_AT_END'),
                     'N', DECODE(
                         DECODE(v_policy_type, 'N', 'P', 'F'),
                         'P', gin_parameters_pkg.get_param_varchar('POL_SERIAL_POS'),
                         gin_parameters_pkg.get_param_varchar('POL_FAC_SERIAL_POS')
                    ),
                    LENGTH(v_pol_no) - gin_parameters_pkg.get_param_varchar('POLNOSRLENGTH') + 1
                 ),
                 gin_parameters_pkg.get_param_varchar('POLNOSRLENGTH')
            )
        )
        INTO v_seq
        FROM DUAL;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END;
    
    BEGIN
        SELECT DECODE(v_policy_type, 'N', 'P', 'F')
        INTO v_pol_seq_type
        FROM DUAL;
        
        gin_sequences_pkg.update_used_sequence(
            v_pol_seq_type,
            v_pro_code,
            v_brn_code,
            v_pol_uwyr,
            v_pol_status,
            v_seq,
            v_pol_no
        );
    EXCEPTION
         WHEN OTHERS THEN
             BEGIN
                SELECT (SUBSTR(
                           v_pol_no,
                           DECODE(
                               gin_parameters_pkg.get_param_varchar('POL_SERIAL_AT_END'),
                               'N', DECODE(
                                   DECODE(v_policy_type, 'N', 'P', 'F'),
                                    'P', gin_parameters_pkg.get_param_number('POL_SERIAL_POS'),
                                    gin_parameters_pkg.get_param_number('POL_FAC_SERIAL_POS')
                               ),
                               LENGTH(v_pol_no) - gin_parameters_pkg.get_param_number('POLNOSRLENGTH') + 1
                           ),
                           gin_parameters_pkg.get_param_varchar('POLNOSRLENGTH')
                       )
                   )
                 INTO v_seqno
                 FROM DUAL;
            EXCEPTION
               WHEN OTHERS THEN
                    raise_error('ERROR SELECTING USED SEQUENCE...');
             END;
           
            BEGIN
               SELECT LENGTH(brn_sht_desc)
                 INTO v_brn_sht_length
               FROM tqc_branches
               WHERE brn_code = v_brn_code;
             EXCEPTION
               WHEN OTHERS THEN
                 NULL;
            END;
             
        IF NVL(v_brn_sht_length, 0) = 2 THEN
            BEGIN
                v_seq := TO_NUMBER(v_seqno);
            EXCEPTION
                WHEN OTHERS THEN
                    NULL;
            END;
        ELSIF NVL(v_brn_sht_length, 0) = 3 THEN
            BEGIN
                v_seq := TO_NUMBER(SUBSTR(v_seqno, 2));
            EXCEPTION
                WHEN OTHERS THEN
                    NULL;
            END;
        ELSE
            raise_error('Error here....');
        END IF;
        
        BEGIN
            SELECT DECODE(v_policy_type, 'N', 'P', 'F')
            INTO v_pol_seq_type
            FROM DUAL;
            
            gin_sequences_pkg.update_used_sequence(
                v_pol_seq_type,
                v_pro_code,
                v_brn_code,
                v_pol_uwyr,
                v_pol_status,
                v_seq,
                v_pol_no
            );
        EXCEPTION
            WHEN OTHERS THEN
                raise_error('ERROR UPDATING USED SEQUENCE...');
        END;
    END;
    
    IF NVL(v_binder_policy, 'N') = 'Y' AND tqc_parameters_pkg.get_org_type(37) NOT IN ('INS') THEN
        BEGIN
            SELECT bind_policy_no
            INTO v_client_pol_no
            FROM gin_binders
            WHERE bind_code = v_bind_code;
        EXCEPTION
            WHEN OTHERS THEN
            raise_error('Error getting the Contract policy no...');
        END;
    ELSE
        IF tqc_interfaces_pkg.get_org_type(37) IN ('INS') THEN
            v_client_pol_no := v_pol_no;
        ELSE
            v_client_pol_no := 'TBA';
        END IF;
    END IF;
    
    DBMS_OUTPUT.put_line(4);
    v_policy_doc := v_policy_doc;
    
    IF v_policy_doc IS NULL THEN
        BEGIN
            SELECT SUBSTR(pro_policy_word_doc, 1, 30), pro_min_prem
            INTO v_policy_doc, v_pro_min_prem
            FROM gin_products
            WHERE pro_code = v_pro_code;
        EXCEPTION
            WHEN OTHERS THEN
            raise_error('Error getting the default policy document..');
        END;
    END IF;
    
    SELECT pro_sht_desc
    INTO v_pro_sht_desc
    FROM gin_products
    WHERE pro_code = v_pro_code;
    
    BEGIN
        check_policy_unique(v_pol_no);
    EXCEPTION
        WHEN OTHERS THEN
        raise_error(SQLERRM(SQLCODE));
    END;
    
    v_admin_fee_applicable := 'N';
    v_growth_type := gin_stp_uw_pkg.get_growth_type(v_prp_code, v_pol_status, v_pol_no, v_batchno);
    
    IF v_agnt_code = 0 THEN
        v_comm_allowed := 'N';
    ELSE
        v_comm_allowed := 'Y';
    END IF;
    
    BEGIN
        v_cashback_lvl := 0;
        v_cashback_rate := 0;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            raise_error('Unable to generate CASH BACK...');
    END;
    
    BEGIN
        INSERT INTO gin_policies (
            pol_policy_no, pol_ren_endos_no, pol_batch_no,
            pol_agnt_agent_code, pol_agnt_sht_desc, pol_bind_code,
            pol_wef_dt, pol_wet_dt, pol_uw_year,
            pol_policy_status, pol_inception_dt, pol_cur_code,
            pol_prepared_by, pol_prepared_date, pol_policy_type,
            pol_client_policy_number, pol_brn_code,
            pol_cur_rate, pol_coinsurance, pol_coinsure_leader,
            pol_cur_symbol, pol_brn_sht_desc, pol_prp_code,
            pol_current_status, pol_authosrised, pol_post_status,
            pol_inception_uwyr, pol_pro_code, pol_your_ref,
            pol_prop_holding_co_prp_code, pol_oth_int_parties,
            pol_pro_sht_desc, pol_prev_batch_no,
            pol_uwyr_length,
            pol_binder_policy, pol_renewable,
            pol_policy_cover_from, pol_policy_cover_to,
            pol_coinsurance_share, pol_renewal_dt,
            pol_trans_eff_wet, pol_ri_agent_comm_rate,
            pol_ri_agnt_sht_desc, pol_ri_agnt_agent_code,
            pol_policy_doc, pol_commission_allowed, pol_coin_fee,
            pol_sub_agn_code, pol_sub_agn_sht_desc, pol_div_code,
            pol_pmod_code, pol_adm_fee_applicable, pol_aga_code,
            pol_clna_code, pol_sub_aga_code,
            pol_admin_fee_disc_rate, pol_med_policy_type,
            pol_freq_of_payment, pol_min_prem,
            pol_coin_leader_combined, pol_declaration_type,
            pol_mktr_agn_code, pol_curr_rate_type, pol_coin_gross,
            pol_past_period_endos, pol_bussiness_growth_type,
            pol_subagent, pol_ipf_nof_instals, pol_coagent,
            pol_coagent_main_pct, pol_agn_discounted,
            pol_agn_disc_type, pol_agn_discount, pol_pip_pf_code,
            pol_tot_instlmt, pol_uw_period,
            pol_ipf_down_pymt_type, pol_ipf_down_pymt_amt,
            pol_ipf_interest_rate, pol_outside_system,
            pol_open_cover, pol_endors_status, pol_open_policy,
            pol_pip_code, pol_policy_debit, pol_scheme_policy,
            pol_pro_interface_type, pol_checkoff_agnt_sht_desc,
            pol_checkoff_agnt_code, pol_pymt_faci_agnt_code,
            pol_old_policy_no, pol_old_agent, pol_joint,
            pol_joint_prp_code, pol_intro_code, pol_instlmt_day,
            pol_pop_taxes, pol_bdiv_code, pol_regional_endors,
            pol_cashback_level, pol_cashback_rate, pol_admin_fee_allowed
        )
        VALUES (
            v_pol_no, v_end_no, v_batchno,
            v_agnt_code, v_agnt_sht_desc, v_bind_code,
            v_cover_from,
            v_cover_to, v_pol_uwyr,
            v_pol_status, v_inception_dt, v_cur_code,
            vuser, TRUNC(SYSDATE), NVL(v_policy_type, 'N'),
            NVL(v_pol_no, v_client_pol_no), v_brn_code,
            v_cur_rate, NVL(v_coinsurance, 'N'),
            NULL,
            v_cur_symbol, v_brn_sht_desc, v_prp_code,
            'D', 'N', 'N',
            v_inception_yr, v_pro_code, NULL,
            NULL,
            NULL,
            NVL(v_pro_sht_desc, v_pro_sht_desc), v_batchno,
            CEIL(MONTHS_BETWEEN(v_cover_to, v_cover_from)),
            v_binder_policy,
            'Y',
            v_cover_from, v_cover_to,
            NULL,
            get_renewal_date(v_pro_code, v_cover_to),
            v_wet_date, NULL,
            NULL,
            NULL,
            v_policy_doc, v_comm_allowed,
            NULL,
            NULL,
            NULL,
            NULL,
            v_admin_fee_applicable, NULL,
            NULL,
            NULL,
            v_admin_disc,
            NULL,
            'A', NULL,
            NULL,
            NULL,
            NULL,
            'N', v_growth_type,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            1,
            NULL,
            NULL,
            NULL,
            NULL,
            'N',
            NULL,
            NULL,
            NULL,
            NULL,
            v_interface_type,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NVL(v_pop_taxes, 'N'), v_div_code, NULL,
            v_cashback_lvl, v_cashback_rate,'N'
        );
    EXCEPTION
        WHEN OTHERS THEN
        raise_error('ERROR CREATING POLICY RECORD..');
    END;
    
    BEGIN
        pop_sbu_dtls(v_batchno, v_uni_code, v_loc_code, 'A');
    EXCEPTION
        WHEN OTHERS THEN
        raise_error('Error Creating Policy Other Details Record..');
    END;
    
    BEGIN
        SELECT TO_NUMBER(TO_CHAR(SYSDATE, 'RRRR') || ggt_trans_no_seq.NEXTVAL)
        INTO v_trans_no
        FROM DUAL;
        
        INSERT INTO gin_gis_transactions (
            ggt_doc_ref, ggt_trans_no, ggt_pol_policy_no,
            ggt_cmb_claim_no, ggt_pro_code, ggt_pol_batch_no,
            ggt_pro_sht_desc, ggt_btr_trans_code, ggt_done_by,
            ggt_done_date, ggt_client_policy_number,
            ggt_uw_clm_tran, ggt_trans_date, ggt_trans_authorised,
            ggt_trans_authorised_by, ggt_trans_authorise_date,
            ggt_old_tran_no, ggt_effective_date
        )
        VALUES (
            v_pol_no,
            v_trans_no, v_pol_no,
            NULL, v_pro_code, v_batchno,
            v_pro_sht_desc, 'NB', vuser,
            TRUNC(SYSDATE), v_client_pol_no,
            'U', TRUNC(SYSDATE), 'N',
            NULL, NULL,
            NULL, TRUNC(SYSDATE)
        );
    EXCEPTION
        WHEN OTHERS THEN
            raise_error('Error Creating Transaction Record..');
    END;
    
    BEGIN
        v_tran_ref_no := gin_sequences_pkg.get_number_format(
            'BARCODE',
            v_pro_code,
            v_brn_code,
             TO_NUMBER(TO_CHAR(SYSDATE, 'RRRR')),
            'NB',
            v_serial
        );
    EXCEPTION
        WHEN OTHERS THEN
            raise_error('unable to generate transmittal number.Contact the system administrator...');
    END;
    
    BEGIN
        SELECT TO_NUMBER(TO_CHAR(SYSDATE, 'RRRR')) || ggts_tran_no_seq.NEXTVAL
        INTO next_ggts_trans_no
        FROM DUAL;
    
        INSERT INTO gin_gis_transmitals (
            ggts_tran_no, ggts_pol_policy_no, ggts_cmb_claim_no,
            ggts_pol_batch_no, ggts_done_by, ggts_done_date,
            ggts_uw_clm_tran, ggts_pol_renewal_batch,
            ggts_tran_ref_no,GGTS_IPAY_ALPHANUMERIC
        )
        VALUES (
            next_ggts_trans_no, v_pol_no, NULL,
            v_batchno, v_user, SYSDATE,
            'U', NULL,
            v_tran_ref_no,'Y'
        );
    EXCEPTION
        WHEN OTHERS THEN
            raise_error('TRANSMITAL ERROR. CONTACT THE SYSTEM ADMINISTRATOR...');
    END;
    
    IF v_serial_no IS NOT NULL AND v_outside_system = 'Y' THEN
        BEGIN
            gin_manage_exceptions.proc_certs_excepts(
                v_batchno,
                v_trans_no,
                TRUNC(SYSDATE),
                'NB',
                'UW'
            );
        EXCEPTION
           WHEN OTHERS THEN
               raise_when_others('ERROR CREATING CERTIFICATE EXCEPTION ....');
        END;
    END IF;
    
    BEGIN
        SELECT COUNT(1)
        INTO v_cnt
        FROM gin_file_master
        WHERE film_file_no = v_pol_no;
    EXCEPTION
        WHEN OTHERS THEN
            raise_error('ERROR CHECKING IF POLICY FILE ALREADY EXISTS..');
    END;
    
    IF NVL(v_cnt, 0) = 0 THEN
        BEGIN
            INSERT INTO gin_file_master (
                film_file_no, film_file_desc, film_type,
                film_open_dt, film_location, film_location_dept,
                film_home_shelf_no
            )
            SELECT DISTINCT pol_policy_no,
                clnt_name || ' ' || clnt_other_names, 'U',
                NVL(pol_inception_dt, TRUNC(SYSDATE)),
                'HOME', 'HOME', NULL
            FROM gin_policies, tqc_clients
            WHERE pol_prp_code = clnt_code
            AND pol_batch_no = v_batchno;
        EXCEPTION
            WHEN OTHERS THEN
            raise_error('ERROR CREATING A FILE RECORD FOR THIS POLICY..');
        END;
    END IF;
    
    IF NVL(v_pop_taxes, 'Y') = 'Y' THEN
        BEGIN
            pop_taxes(
                v_pol_no,
                v_end_no,
                v_batchno,
                v_pro_code,
                v_binder_policy,
                v_pol_status
            );
        EXCEPTION
            WHEN OTHERS THEN
                raise_error('ERROR UPDATING TAXES..');
        END;
    END IF;
    
    BEGIN
        pop_clauses(v_pol_no, v_end_no, v_batchno, v_pro_code);
    EXCEPTION
        WHEN OTHERS THEN
        raise_error('ERROR CREATING POPULATING CLAUSES');
    END;
    
    FOR x IN 1 .. v_rsk_data.COUNT LOOP
        BEGIN
            gin_ipu_stp_prc(
                v_batchno,
                v_bind_code,
                v_rsk_data(x).ipu_property_id,
                v_rsk_data(x).ipu_desc,
                v_user,
                v_rsk_data(x).ipu_scl_code,
                v_rsk_data(x).ipu_cvt_code,
                v_new_

```sql
ipu_code,
                v_rsk_data(x).ipu_db_code
            );
        END;
        
        BEGIN
           sect_cursor := gis_web_pkg.get_bouquet_sections(
                v_rsk_data(x).ipu_scl_code,
                v_rsk_data(x).ipu_cvt_code,
                v_bind_code,
                v_rsk_data(x).ipu_db_code,
                v_new_ipu_code
           );
           
           LOOP
               EXIT WHEN sect_cursor%NOTFOUND;
               
               FETCH sect_cursor
               INTO v_sect_sht_desc, v_sec_code, v_sect_desc, v_sect_type,
                    v_type_desc, v_prr_rate_type, v_prr_rate, v_terr_description,
                    v_prr_prem_minimum_amt, v_prr_multiplier_rate,
                    v_prr_division_factor, v_prr_multplier_div_fact,
                    v_prr_rate_desc, v_prr_free_limit, v_sec_declaration,
                    v_scvts_order, v_prr_prorated_full, v_prr_si_limit_type,
                    v_prr_si_rate;
                
                v_rsk_sect_data := web_sect_tab();
                v_rsk_sect_data.EXTEND(1);
                v_rsk_sect_data(1) := web_sect_rec(
                    NULL,
                    v_new_ipu_code,
                    v_sec_code,
                    v_sect_sht_desc,
                    NULL,
                    0,
                    v_prr_rate,
                    NULL,
                    v_prr_rate_type,
                    v_sect_type,
                    v_prr_prem_minimum_amt,
                    NULL,
                    v_prr_multiplier_rate,
                    v_prr_multplier_div_fact,
                    NULL,
                    v_prr_division_factor,
                    'Y',
                    'N',
                    0,
                    v_sec_declaration,
                    v_prr_free_limit,
                    NULL,
                    NULL,
                    NVL(v_prr_prorated_full,'P'),
                     NULL,
                    v_sect_desc,
                     v_prr_si_limit_type,
                    v_prr_si_rate,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    'N',
                    'A',
                    NULL,
                    NULL,
                    NULL
               );
           END LOOP;
           
           gin_rsk_stp_limits(
                v_new_ipu_code,
                v_rsk_data(x).ipu_scl_code,
                v_bind_code,
                v_row,
                'A',
                v_rsk_data(x).ipu_cvt_code,
                v_rsk_sect_data,
                v_rsk_data(x).ipu_db_code
            );
        END;
    END LOOP;
END;

```