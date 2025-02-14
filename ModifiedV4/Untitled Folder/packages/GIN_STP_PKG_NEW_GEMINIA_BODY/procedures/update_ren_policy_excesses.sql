PROCEDURE update_ren_policy_excesses (
        v_pspr_code                     gin_policy_section_perils.pspr_code%TYPE,
        v_action                        VARCHAR2,
        v_pspr_pol_batch_no             gin_policy_section_perils.pspr_pol_batch_no%TYPE,
        v_sspr_code                     gin_policy_section_perils.pspr_sspr_code%TYPE,
        v_pspr_peril_limit              gin_policy_section_perils.pspr_peril_limit%TYPE,
        v_pspr_peril_type               gin_policy_section_perils.pspr_peril_type%TYPE,
        v_pspr_si_or_limit              gin_policy_section_perils.pspr_si_or_limit%TYPE,
        v_pspr_excess_type              gin_policy_section_perils.pspr_excess_type%TYPE,
        v_pspr_excess                   gin_policy_section_perils.pspr_excess%TYPE,
        v_pspr_excess_min               gin_policy_section_perils.pspr_excess_min%TYPE,
        v_pspr_excess_max               gin_policy_section_perils.pspr_excess_max%TYPE,
        v_pspr_expire_on_claim          gin_policy_section_perils.pspr_expire_on_claim%TYPE,
        v_pspr_person_limit             gin_policy_section_perils.pspr_person_limit%TYPE,
        v_pspr_claim_limit              gin_policy_section_perils.pspr_claim_limit%TYPE,
        v_pspr_desc                     gin_policy_section_perils.pspr_desc%TYPE,
        v_pspr_tl_excess_type           gin_policy_section_perils.pspr_tl_excess_type%TYPE,
        v_pspr_tl_excess                gin_policy_section_perils.pspr_tl_excess%TYPE,
        v_pspr_tl_excess_min            gin_policy_section_perils.pspr_tl_excess_min%TYPE,
        v_pspr_tl_excess_max            gin_policy_section_perils.pspr_tl_excess_max%TYPE,
        v_pspr_pl_excess_type           gin_policy_section_perils.pspr_pl_excess_type%TYPE,
        v_pspr_pl_excess                gin_policy_section_perils.pspr_pl_excess%TYPE,
        v_pspr_pl_excess_min            gin_policy_section_perils.pspr_pl_excess_min%TYPE,
        v_pspr_pl_excess_max            gin_policy_section_perils.pspr_pl_excess_max%TYPE,
        v_prspr_salvage_pct             gin_pol_risk_section_perils.prspr_salvage_pct%TYPE,
        v_prspr_claim_excess_type       gin_pol_risk_section_perils.prspr_claim_excess_type%TYPE,
        v_prspr_claim_excess_min        gin_pol_risk_section_perils.prspr_claim_excess_min%TYPE,
        v_prspr_claim_excess_max        gin_pol_risk_section_perils.prspr_claim_excess_max%TYPE,
        v_prspr_depend_loss_type        gin_pol_risk_section_perils.prspr_depend_loss_type%TYPE,
        v_prspr_ttd_ben_pcts            gin_pol_risk_section_perils.prspr_ttd_ben_pcts%TYPE,
        v_pspr_ssprm_code               gin_pol_risk_section_perils.prspr_ssprm_code%TYPE,
        v_err                       OUT VARCHAR2)
    IS                                             --GIN_POLICY_SECTION_PERILS
        v_new_pspr_code        NUMBER;
        v_pspr_scl_code        gin_policy_section_perils.pspr_scl_code%TYPE;
        v_pspr_sect_code       gin_policy_section_perils.pspr_sect_code%TYPE;
        v_pspr_sect_sht_desc   gin_policy_section_perils.pspr_sect_sht_desc%TYPE;
        v_pspr_per_code        gin_policy_section_perils.pspr_per_code%TYPE;
        v_pspr_per_sht_desc    gin_policy_section_perils.pspr_per_sht_desc%TYPE;
        v_pspr_sec_code        gin_policy_section_perils.pspr_sec_code%TYPE;
        v_pspr_bind_type       gin_policy_section_perils.pspr_bind_type%TYPE;
        v_pspr_bind_code       gin_policy_section_perils.pspr_bind_code%TYPE;
        v_pspr_mandatory       gin_policy_section_perils.pspr_mandatory%TYPE;
        v_status               VARCHAR2 (200);
        v_pol_loaded           VARCHAR2 (1);
    BEGIN
        BEGIN
            --v_err:='test ' || v_sspr_code;
            --return;
            SELECT sspr_scl_code,
                   ssprm_sect_code         sspr_sect_code,
                   ssprm_sect_sht_desc     sspr_sect_sht_desc,
                   sspr_per_code,
                   sspr_per_sht_desc,
                   ssprm_sec_code          sspr_sec_code,
                   ssprm_bind_type         sspr_bind_type,
                   ssprm_bind_code         sspr_bind_code,
                   sspr_mandatory
              INTO v_pspr_scl_code,
                   v_pspr_sect_code,
                   v_pspr_sect_sht_desc,
                   v_pspr_per_code,
                   v_pspr_per_sht_desc,
                   v_pspr_sec_code,
                   v_pspr_bind_type,
                   v_pspr_bind_code,
                   v_pspr_mandatory
              FROM gin_subcl_sction_perils, gin_subcl_sction_perils_map
             WHERE     sspr_code = v_sspr_code
                   AND ssprm_sspr_code = sspr_code
                   AND ssprm_code = v_pspr_ssprm_code;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                v_err :=
                       'Perils / Excesses have NOT been defined for the subclass'
                    || v_pspr_scl_code
                    || '..'
                    || SQLERRM (SQLCODE);
                RETURN;
            WHEN OTHERS
            THEN
                v_err :=
                       'Error on Perils / Excesses for subclass'
                    || v_pspr_scl_code
                    || ' ...'
                    || SQLERRM (SQLCODE);
                RETURN;
        END;