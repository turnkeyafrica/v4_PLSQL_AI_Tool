PROCEDURE update_ren_risk_excesses (
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
      v_prspr_ssprm_code                gin_pol_risk_section_perils.prspr_ssprm_code%TYPE,
      v_ipu_code                        NUMBER,
      v_err                       OUT   VARCHAR2
   )
   IS                                              --GIN_POLICY_SECTION_PERILS
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
         SELECT sspr_scl_code, ssprm_sect_code sspr_sect_code,
                ssprm_sect_sht_desc sspr_sect_sht_desc, sspr_per_code,
                sspr_per_sht_desc, ssprm_sec_code sspr_sec_code,
                ssprm_bind_type sspr_bind_type,
                ssprm_bind_code sspr_bind_code, sspr_mandatory
           INTO v_pspr_scl_code, v_pspr_sect_code,
                v_pspr_sect_sht_desc, v_pspr_per_code,
                v_pspr_per_sht_desc, v_pspr_sec_code,
                v_pspr_bind_type,
                v_pspr_bind_code, v_pspr_mandatory
           FROM gin_subcl_sction_perils, gin_subcl_sction_perils_map
          WHERE sspr_code = v_sspr_code
            AND ssprm_sspr_code = sspr_code
            AND ssprm_code = v_prspr_ssprm_code;
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

            INSERT INTO gin_ren_pol_risk_sect_perils
                        (prspr_code, prspr_pol_batch_no,
                         prspr_scl_code, prspr_sect_code,
                         prspr_sect_sht_desc, prspr_per_code,
                         prspr_per_sht_desc, prspr_mandatory,
                         prspr_peril_limit, prspr_peril_type,
                         prspr_si_or_limit, prspr_sec_code,
                         prspr_excess_type, prspr_excess,
                         prspr_excess_min, prspr_excess_max,
                         prspr_expire_on_claim, prspr_bind_code,
                         prspr_person_limit, prspr_claim_limit,
                         prspr_desc, prspr_bind_type, prspr_sspr_code,
                         prspr_tl_excess_type, prspr_tl_excess,
                         prspr_tl_excess_min, prspr_tl_excess_max,
                         prspr_pl_excess_type, prspr_pl_excess,
                         prspr_pl_excess_min, prspr_pl_excess_max,
                         prspr_salvage_pct, prspr_claim_excess_type,
                         prspr_claim_excess_min, prspr_claim_excess_max,
                         prspr_depend_loss_type, prspr_ttd_ben_pcts,
                         prspr_ssprm_code
                        )
                 VALUES (v_new_pspr_code, v_pspr_pol_batch_no,
                         v_pspr_scl_code, v_pspr_sect_code,
                         v_pspr_sect_sht_desc, v_pspr_per_code,
                         v_pspr_per_sht_desc, v_pspr_mandatory,
                         v_pspr_peril_limit, v_pspr_peril_type,
                         v_pspr_si_or_limit, v_pspr_sec_code,
                         v_pspr_excess_type, v_pspr_excess,
                         v_pspr_excess_min, v_pspr_excess_max,
                         v_pspr_expire_on_claim, v_pspr_bind_code,
                         v_pspr_person_limit, v_pspr_claim_limit,
                         v_pspr_desc, v_pspr_bind_type, v_sspr_code,
                         v_pspr_tl_excess_type, v_pspr_tl_excess,
                         v_pspr_tl_excess_min, v_pspr_tl_excess_max,
                         v_pspr_pl_excess_type, v_pspr_pl_excess,
                         v_pspr_pl_excess_min, v_pspr_pl_excess_max,
                         v_prspr_salvage_pct, v_prspr_claim_excess_type,
                         v_prspr_claim_excess_min, v_prspr_claim_excess_max,
                         v_prspr_depend_loss_type, v_prspr_ttd_ben_pcts,
                         v_prspr_ssprm_code
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
            UPDATE gin_ren_pol_risk_sect_perils
               SET
                   --pspr_QR_QUOT_CODE = NVL(v_pspr_qr_quot_code,pspr_QR_QUOT_CODE),
                         --pspr_QR_CODE = NVL(v_pspr_qr_code,pspr_QR_CODE),
                   prspr_scl_code = NVL (v_pspr_scl_code, prspr_scl_code),
                   prspr_sect_code = NVL (v_pspr_sect_code, prspr_sect_code),
                   prspr_sect_sht_desc =
                               NVL (v_pspr_sect_sht_desc, prspr_sect_sht_desc),
                   prspr_per_code = NVL (v_pspr_per_code, prspr_per_code),
                   prspr_per_sht_desc =
                                 NVL (v_pspr_per_sht_desc, prspr_per_sht_desc),
                   prspr_mandatory = NVL (v_pspr_mandatory, prspr_mandatory),
                   prspr_peril_limit = v_pspr_peril_limit,
                   prspr_peril_type = v_pspr_peril_type,
                   prspr_si_or_limit = v_pspr_si_or_limit,
                   prspr_sec_code = v_pspr_sec_code,
                   prspr_excess_type = v_pspr_excess_type,
                   prspr_excess = v_pspr_excess,
                   prspr_excess_min = v_pspr_excess_min,
                   prspr_excess_max = v_pspr_excess_max,
                   prspr_expire_on_claim = v_pspr_expire_on_claim,
                   prspr_bind_code = v_pspr_bind_code,
                   prspr_person_limit = v_pspr_person_limit,
                   prspr_claim_limit = v_pspr_claim_limit,
                   prspr_desc = v_pspr_desc,
                   prspr_bind_type = NVL (v_pspr_bind_type, prspr_bind_type),
                   prspr_tl_excess_type = v_pspr_tl_excess_type,
                   prspr_tl_excess = v_pspr_tl_excess,
                   prspr_tl_excess_min = v_pspr_tl_excess_min,
                   prspr_tl_excess_max = v_pspr_tl_excess_max,
                   prspr_pl_excess_type = v_pspr_pl_excess_type,
                   prspr_pl_excess = v_pspr_pl_excess,
                   prspr_pl_excess_min = v_pspr_pl_excess_min,
                   prspr_pl_excess_max = v_pspr_pl_excess_max,
                   prspr_salvage_pct = v_prspr_salvage_pct,
                   prspr_claim_excess_type = v_prspr_claim_excess_type,
                   prspr_claim_excess_min = v_prspr_claim_excess_min,
                   prspr_claim_excess_max = v_prspr_claim_excess_max,
                   prspr_depend_loss_type = v_prspr_depend_loss_type,
                   prspr_ttd_ben_pcts = v_prspr_ttd_ben_pcts,
                   prspr_ssprm_code = v_prspr_ssprm_code
             WHERE prspr_code = v_pspr_code;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_err :=
                     'Unable to retrieve excess for update  ...'
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
            DELETE FROM gin_ren_pol_risk_sect_perils
                  WHERE prspr_code = v_pspr_code;
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
   END update_ren_risk_excesses;