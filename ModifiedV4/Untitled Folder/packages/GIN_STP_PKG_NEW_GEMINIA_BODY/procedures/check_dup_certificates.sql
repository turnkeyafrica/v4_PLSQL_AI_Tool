PROCEDURE check_dup_certificates (
        v_polc_wef          gin_policy_certs.polc_wef%TYPE,
        v_polc_wet          gin_policy_certs.polc_wet%TYPE,
        v_polc_status       gin_policy_certs.polc_status%TYPE,
        v_polc_ipu_id       NUMBER,
        v_err           OUT VARCHAR2,
        v_ipu_code          NUMBER DEFAULT NULL)
    IS
        --v_curr_wef DATE;
        v_dummy    NUMBER := 0;
        v_ipu_id   NUMBER;
    BEGIN
        -- v_curr_wef :=v_polc_wef;
        IF v_polc_ipu_id IS NULL AND v_ipu_code IS NOT NULL
        THEN
            BEGIN
                SELECT IPU_ID
                  INTO v_ipu_id
                  FROM GIN_INSURED_PROPERTY_UNDS
                 WHERE IPU_CODE = v_ipu_code;
            EXCEPTION
                WHEN OTHERS
                THEN
                    v_ipu_id := NULL;
            END;