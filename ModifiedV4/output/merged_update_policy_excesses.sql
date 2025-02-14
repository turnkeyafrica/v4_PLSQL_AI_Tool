```sql
PROCEDURE update_policy_excesses (
    v_pspr_code                       gin_policy_section_perils.pspr_code%TYPE,
    v_action                          VARCHAR2,
    v_pspr_pol_batch_no               gin_policy_section_perils.pspr_pol_batch_no%TYPE,
    v_sspr_code                       gin_policy_section_perils.pspr_sspr_code%TYPE,
    v_pspr_peril_limit                gin_policy_section_perils.pspr_peril_limit%TYPE,
    v_pspr_peril_type                 gin_policy_section_perils.pspr_peril_type%TYPE,
    v_pspr_si_or_limit                gin_policy_section_perils.pspr_si_or_limit%TYPE,
    v_pspr_excess_type                gin_policy_section_perils.pspr_excess_type%TYPE,
    v_pspr_excess                     gin_policy_section_perils.pspr_excess%TYPE,
    v_pspr_excess_min                 gin_policy_section_perils.pspr_excess_min%TYPE,
    v_pspr_excess_max                 gin_policy_section_perils.pspr_excess_max%TYPE,
    v_pspr_expire_on_claim            gin_policy_section_perils.pspr_expire_on_claim%TYPE,
    v_pspr_person_limit               gin_policy_section_perils.pspr_person_limit%TYPE,
    v_pspr_claim_limit                gin_policy_section_perils.pspr_claim_limit%TYPE,
    v_pspr_desc                       gin_policy_section_perils.pspr_desc%TYPE,
    v_pspr_tl_excess_type             gin_policy_section_perils.pspr_tl_excess_type%TYPE,
    v_pspr_tl_excess                  gin_policy_section_perils.pspr_tl_excess%TYPE,
    v_pspr_tl_excess_min              gin_policy_section_perils.pspr_tl_excess_min%TYPE,
    v_pspr_tl_excess_max              gin_policy_section_perils.pspr_tl_excess_max%TYPE,
    v_pspr_pl_excess_type             gin_policy_section_perils.pspr_pl_excess_type%TYPE,
    v_pspr_pl_excess                  gin_policy_section_perils.pspr_pl_excess%TYPE,
    v_pspr_pl_excess_min              gin_policy_section_perils.pspr_pl_excess_min%TYPE,
    v_pspr_pl_excess_max              gin_policy_section_perils.pspr_pl_excess_max%TYPE,
    v_prspr_salvage_pct               gin_pol_risk_section_perils.prspr_salvage_pct%TYPE,
    v_prspr_claim_excess_type         gin_pol_risk_section_perils.prspr_claim_excess_type%TYPE,
    v_prspr_claim_excess_min          gin_pol_risk_section_perils.prspr_claim_excess_min%TYPE,
    v_prspr_claim_excess_max          gin_pol_risk_section_perils.prspr_claim_excess_max%TYPE,
    v_prspr_depend_loss_type          gin_pol_risk_section_perils.prspr_depend_loss_type%TYPE,
    v_prspr_ttd_ben_pcts              gin_pol_risk_section_perils.prspr_ttd_ben_pcts%TYPE,
    v_pspr_ssprm_code                 gin_policy_section_perils.pspr_ssprm_code%TYPE,
    v_code                            NUMBER,
    v_err                       OUT   VARCHAR2
)
IS
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
                   'Perils / Excesses have NOT been defined for the subclass '
                || v_pspr_scl_code
                || '..'
                || SQLERRM (SQLCODE);
            RETURN;
        WHEN OTHERS
        THEN
            v_err :=
                   'Error on Perils / Excesses for subclass '
                || v_pspr_scl_code
                || ' ...'
                || SQLERRM (SQLCODE);
            RETURN;
    END;
    
    BEGIN
        SELECT pol_authosrised, pol_loaded
          INTO v_status, v_pol_loaded
          FROM gin_policies
         WHERE pol_batch_no = v_pspr_pol_batch_no;
    END;
    
    IF v_status = 'A' AND NVL (v_pol_loaded, 'N') = 'N'
    THEN
        v_err := 'Cannot Make Changes to an authorized Policy ...';
        RETURN;
    END IF;
    
    IF v_action = 'A'
    THEN
        BEGIN
            SELECT gin_pspr_code_seq.NEXTVAL
              INTO v_new_pspr_code
              FROM DUAL;
            
            INSERT INTO gin_policy_section_perils (
                            pspr_code,
                            pspr_pol_batch_no,
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
                            pspr_sspr_code,
                            pspr_claim_excess_type,
                            pspr_ssprm_code
                            )
                 VALUES (v_new_pspr_code,
                         v_pspr_pol_batch_no,
                         v_pspr_scl_code,
                         v_pspr_sect_code,
                         v_pspr_sect_sht_desc,
                         v_pspr_per_code,
                         v_pspr_per_sht_desc,
                         v_pspr_mandatory,
                         v_pspr_peril_limit,
                         v_pspr_peril_type,
                         v_pspr_si_or_limit,
                         v_pspr_sec_code,
                         v_pspr_excess_type,
                         v_pspr_excess,
                         v_pspr_excess_min,
                         v_pspr_excess_max,
                         v_pspr_expire_on_claim,
                         v_pspr_bind_code,
                         v_pspr_person_limit,
                         v_pspr_claim_limit,
                         v_pspr_desc,
                         v_pspr_bind_type,
                         v_sspr_code,
                         v_prspr_claim_excess_type,
                         v_pspr_ssprm_code
                         );
        EXCEPTION
            WHEN OTHERS
            THEN
                v_err :=
                       'Error occurred on inserting Excesses ...'
                    || SQLERRM (SQLCODE);
                RETURN;
        END;
    ELSIF v_action = 'E'
    THEN
        BEGIN
            UPDATE gin_policy_section_perils
               SET pspr_scl_code = NVL (v_pspr_scl_code, pspr_scl_code),
                   pspr_sect_code = NVL (v_pspr_sect_code, pspr_sect_code),
                   pspr_sect_sht_desc =
                       NVL (v_pspr_sect_sht_desc, pspr_sect_sht_desc),
                   pspr_per_code = NVL (v_pspr_per_code, pspr_per_code),
                   pspr_per_sht_desc =
                       NVL (v_pspr_per_sht_desc, pspr_per_sht_desc),
                   pspr_mandatory = NVL (v_pspr_mandatory, pspr_mandatory),
                   pspr_peril_limit =
                       NVL (v_pspr_peril_limit, pspr_peril_limit),
                   pspr_peril_type = NVL (v_pspr_peril_type, pspr_peril_type),
                   pspr_si_or_limit =
                       NVL (v_pspr_si_or_limit, pspr_si_or_limit),
                   pspr_sec_code = NVL (v_pspr_sec_code, pspr_sec_code),
                   pspr_excess_type =
                       NVL (v_pspr_excess_type, pspr_excess_type),
                   pspr_excess = NVL (v_pspr_excess, pspr_excess),
                   pspr_excess_min = NVL (v_pspr_excess_min, pspr_excess_min),
                   pspr_excess_max = NVL (v_pspr_excess_max, pspr_excess_max),
                   pspr_expire_on_claim =
                       NVL (v_pspr_expire_on_claim, pspr_expire_on_claim),
                   pspr_bind_code = NVL (v_pspr_bind_code, pspr_bind_code),
                   pspr_person_limit =
                       NVL (v_pspr_person_limit, pspr_person_limit),
                   pspr_claim_limit =
                       NVL (v_pspr_claim_limit, pspr_claim_limit),
                   pspr_desc = NVL (v_pspr_desc, pspr_desc),
                   pspr_bind_type = NVL (v_pspr_bind_type, pspr_bind_type),
                   pspr_ssprm_code = v_pspr_ssprm_code
             WHERE pspr_code = v_pspr_code;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                v_err :=
                       'Unable to retrieve excess for update ...'
                    || v_pspr_per_sht_desc
                    || '..'
                    || SQLERRM (SQLCODE);
                RETURN;
            WHEN OTHERS
            THEN
                v_err :=
                       'Error occurred on updating The Excesses ...'
                    || SQLERRM (SQLCODE);
                RETURN;
        END;
    ELSIF v_action = 'D'
    THEN
        BEGIN
            DELETE FROM gin_policy_section_perils
                  WHERE pspr_code = v_pspr_code;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                v_err :=
                       'Unable to retrieve excess for DELETION  ...'
                    || v_pspr_per_sht_desc
                    || '..'
                    || SQLERRM (SQLCODE);
                RETURN;
            WHEN OTHERS
            THEN
                v_err :=
                       'Error occurred on DELETING The Excess ...'
                    || SQLERRM (SQLCODE);
                RETURN;
        END;
    END IF;
END update_policy_excesses;

```