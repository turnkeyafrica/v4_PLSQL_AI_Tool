```sql
PROCEDURE pop_ren_risk_sect_perils (
    v_ipu_code    IN   NUMBER,
    v_pil_code    IN   NUMBER,
    v_sect_code   IN   NUMBER
)
IS
    v_bind_type   VARCHAR2 (1);
    v_scl_code    NUMBER;
    v_bind_code   NUMBER;
    v_cvt_code    NUMBER;
    v_batch_no    NUMBER;
BEGIN
    BEGIN
        SELECT ipu_sec_scl_code,
               ipu_bind_code,
               ipu_covt_code,
               ipu_pol_batch_no
        INTO   v_scl_code,
               v_bind_code,
               v_cvt_code,
               v_batch_no
        FROM   gin_ren_insured_property_unds
        WHERE  ipu_code = v_ipu_code;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_ERROR('Error at risk dtls selection');
    END;

    INSERT INTO gin_pol_ren_rsk_section_perils (
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
        prspr_depreciation_pct,
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
        prspr_pil_code
    )
        SELECT
            gin_pspr_code_seq.NEXTVAL,
            v_batch_no,
            v_ipu_code,
            ssprm_scl_code,
            ssprm_sect_code,
            ssprm_sect_sht_desc,
            ssprm_per_code,
            ssprm_per_sht_desc,
            sspr_mandatory,
            sspr_peril_limit,
            sspr_peril_type,
            sspr_si_or_limit,
            ssprm_sec_code,
            NVL(sspr_excess_type, 'P'),
            sspr_excess,
            sspr_excess_min,
            sspr_excess_max,
            sspr_expire_on_claim,
            ssprm_bind_code,
            sspr_person_limit,
            sspr_claim_limit,
            sspr_desc,
            ssprm_bind_type,
            sspr_code,
            NULL,
            sspr_salvage_pct,
            sspr_claim_excess_type,
            sspr_tl_excess_type,
            sspr_tl_excess,
            sspr_tl_excess_min,
            sspr_tl_excess_max,
            sspr_pl_excess_type,
            sspr_pl_excess,
            sspr_pl_excess_min,
            sspr_pl_excess_min,
            sspr_claim_excess_min,
            sspr_claim_excess_max,
            sspr_depend_loss_type,
            sspr_ttd_ben_pcts,
            ssprm_code,
            pil_code
        FROM
            gin_subcl_sction_perils,
            gin_sections,
            gin_subcl_sction_perils_map,
            gin_subcl_covt_sections,
            gin_ren_policy_insured_limits
        WHERE
            ssprm_per_type = 'S'
            AND sspr_code = ssprm_sspr_code
            AND sect_code = ssprm_sect_code
            AND scvts_scl_code = ssprm_scl_code
            AND scvts_covt_code = v_cvt_code
            AND sect_code = scvts_sect_code
            AND sect_code = v_sect_code
            AND ssprm_bind_code = v_bind_code
            AND pil_code = v_pil_code
            AND pil_ipu_code = v_ipu_code
            AND pil_sect_code = sect_code
            AND ssprm_code NOT IN (
                SELECT
                    prspr_ssprm_code
                FROM
                    gin_pol_ren_rsk_section_perils
                WHERE
                    prspr_ipu_code = v_ipu_code
                    AND prspr_pol_batch_no = v_batch_no
            );

    --COMMIT;
END;

```