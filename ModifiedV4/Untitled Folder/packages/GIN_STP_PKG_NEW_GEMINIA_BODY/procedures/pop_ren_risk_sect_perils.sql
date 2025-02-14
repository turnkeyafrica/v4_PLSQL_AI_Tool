PROCEDURE pop_ren_risk_sect_perils (v_ipu_code    IN NUMBER,
                                        v_pil_code    IN NUMBER,
                                        v_sect_code   IN NUMBER)
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
              INTO v_scl_code,
                   v_bind_code,
                   v_cvt_code,
                   v_batch_no
              FROM gin_ren_insured_property_unds
             WHERE ipu_code = v_ipu_code;
        EXCEPTION
            WHEN OTHERS
            THEN
                raise_error ('Error at risk dtls selection');
        END;