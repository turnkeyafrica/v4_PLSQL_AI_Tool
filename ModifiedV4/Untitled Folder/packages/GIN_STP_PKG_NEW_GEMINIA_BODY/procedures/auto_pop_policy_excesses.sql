PROCEDURE auto_pop_policy_excesses (
        v_pspr_pol_batch_no   gin_policy_section_perils.pspr_pol_batch_no%TYPE)
    IS
        v_status          VARCHAR2 (200);
        v_pol_loaded      VARCHAR2 (200);
        v_new_pspr_code   NUMBER;
        v_prev_scl        NUMBER;

        CURSOR pilicy_risks_ref IS
              SELECT *
                FROM gin_insured_property_unds
               WHERE ipu_pol_batch_no = v_pspr_pol_batch_no
            ORDER BY ipu_sec_scl_code;
    BEGIN
        --RAISE_ERROR('v_pspr_pol_batch_no'||v_pspr_pol_batch_no);
        BEGIN
            SELECT pol_authosrised, pol_loaded
              INTO v_status, v_pol_loaded
              FROM gin_policies
             WHERE pol_batch_no = v_pspr_pol_batch_no;
        END;