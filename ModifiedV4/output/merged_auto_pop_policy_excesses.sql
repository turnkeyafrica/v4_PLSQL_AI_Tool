```sql
PROCEDURE auto_pop_policy_excesses (
    v_pspr_pol_batch_no   gin_policy_section_perils.pspr_pol_batch_no%TYPE
)
IS
    v_status          VARCHAR2 (200);
    v_pol_loaded      VARCHAR2 (200);
    v_new_pspr_code   NUMBER;
    v_prev_scl        NUMBER;

    CURSOR pilicy_risks_ref IS
        SELECT   *
        FROM gin_insured_property_unds
        WHERE ipu_pol_batch_no = v_pspr_pol_batch_no
        ORDER BY ipu_sec_scl_code;
BEGIN
    BEGIN
        SELECT pol_authosrised, pol_loaded
        INTO v_status, v_pol_loaded
        FROM gin_policies
        WHERE pol_batch_no = v_pspr_pol_batch_no;
    END;

    IF v_status = 'A' AND NVL (v_pol_loaded, 'N') = 'N'
    THEN
        raise_error(
            'Cannot make changes to a policy that is already authorised');
        RETURN;
    END IF;

    v_prev_scl := 0;

    FOR pilicy_risks_rec IN pilicy_risks_ref
    LOOP
        IF v_prev_scl = pilicy_risks_rec.ipu_sec_scl_code
        THEN
            CONTINUE;
        END IF;

        v_prev_scl := pilicy_risks_rec.ipu_sec_scl_code;

        DECLARE
            CURSOR sect_sub_class_per_ref IS
                SELECT *
                FROM gin_subcl_sction_perils,
                    gin_perils,
                    gin_sections,
                    gin_subcl_sction_perils_map
                WHERE sspr_scl_code =
                        NVL (pilicy_risks_rec.ipu_sec_scl_code,
                            sspr_scl_code)
                AND ssprm_per_code = per_code
                AND ssprm_sspr_code = sspr_code
                AND sspr_scl_code = ssprm_scl_code
                AND ssprm_sect_code = sect_code
                AND ssprm_bind_code IN (
                        SELECT ipu_bind_code
                        FROM gin_insured_property_unds
                        WHERE ipu_pol_batch_no = v_pspr_pol_batch_no)
                AND ssprm_sect_code IN (
                        SELECT pil_sect_code
                        FROM gin_policy_insured_limits
                        WHERE pil_ipu_code IN (
                                SELECT ipu_code
                                FROM gin_insured_property_unds
                                WHERE ipu_pol_batch_no = v_pspr_pol_batch_no))
                AND ssprm_code NOT IN (
                        SELECT pspr_ssprm_code
                        FROM gin_policy_section_perils
                        WHERE pspr_pol_batch_no = v_pspr_pol_batch_no);
        BEGIN
            FOR sect_sub_class_per_rec IN sect_sub_class_per_ref
            LOOP
                BEGIN
                    SELECT gin_pspr_code_seq.NEXTVAL
                    INTO v_new_pspr_code
                    FROM DUAL;

                    INSERT INTO gin_policy_section_perils
                        (pspr_code, pspr_pol_batch_no,
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
                        pspr_claim_limit,
                        pspr_person_limit,
                        pspr_bind_type,
                        pspr_sspr_code,
                        pspr_depend_loss_type,
                        pspr_claim_excess_type
                        )
                    VALUES (v_new_pspr_code, v_pspr_pol_batch_no,
                        pilicy_risks_rec.ipu_sec_scl_code,
                        sect_sub_class_per_rec.ssprm_sect_code,
                        sect_sub_class_per_rec.ssprm_sect_sht_desc,
                        sect_sub_class_per_rec.ssprm_per_code,
                        sect_sub_class_per_rec.per_sht_desc,
                        sect_sub_class_per_rec.sspr_mandatory,
                        sect_sub_class_per_rec.sspr_peril_limit,
                        sect_sub_class_per_rec.sspr_peril_type,
                        sect_sub_class_per_rec.sspr_si_or_limit,
                        sect_sub_class_per_rec.ssprm_sec_code,
                        NVL (
                            sect_sub_class_per_rec.sspr_excess_type,
                            sect_sub_class_per_rec.sspr_claim_excess_type
                            ),
                        sect_sub_class_per_rec.sspr_excess,
                        sect_sub_class_per_rec.sspr_excess_min,
                        sect_sub_class_per_rec.sspr_excess_max,
                        sect_sub_class_per_rec.sspr_expire_on_claim,
                        sect_sub_class_per_rec.ssprm_bind_code,
                        sect_sub_class_per_rec.sspr_claim_limit,
                        sect_sub_class_per_rec.sspr_person_limit,
                        sect_sub_class_per_rec.ssprm_bind_type,
                        sect_sub_class_per_rec.ssprm_sspr_code,
                        sect_sub_class_per_rec.sspr_depend_loss_type,
                        sect_sub_class_per_rec.sspr_claim_excess_type
                        );
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error(
                            'Error occurred on inserting Excesses ...'
                            || SQLERRM (SQLCODE)
                            );
                        RETURN;
                END;
            END LOOP;
        EXCEPTION
            WHEN OTHERS
            THEN
                raise_error ('Failed to create policy level perils');
        END;
    END LOOP;
END auto_pop_policy_excesses;

```