PROCEDURE pop_sections (v_ipu_code NUMBER)
    IS
        v_scl_code    NUMBER;
        v_bind_code   NUMBER;
        v_covt_code   NUMBER;
        v_batch_no    NUMBER;
    BEGIN
        SELECT ipu_sec_scl_code,
               ipu_bind_code,
               ipu_covt_code,
               ipu_pol_batch_no
          INTO v_scl_code,
               v_bind_code,
               v_covt_code,
               v_batch_no
          FROM gin_insured_property_unds
         WHERE ipu_code = v_ipu_code;

        BEGIN
            DELETE gin_policy_insured_limits
             WHERE pil_ipu_code = v_ipu_code;
        EXCEPTION
            WHEN OTHERS
            THEN
                raise_error (
                    'Error deleting previously populated sections...');
        END;

        BEGIN
            gin_stp_pkg.pop_policy_rsk_limits (v_ipu_code,
                                               v_scl_code,
                                               v_bind_code,
                                               v_covt_code,
                                               v_batch_no);
        EXCEPTION
            WHEN OTHERS
            THEN
                raise_error (
                    'Error populating binder sections OR Sections already defined...');
        END;
    END;