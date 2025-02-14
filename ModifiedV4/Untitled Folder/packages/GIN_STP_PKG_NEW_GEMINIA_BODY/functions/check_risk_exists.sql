FUNCTION check_risk_exists (v_pol_batch_no       IN     NUMBER,
                                v_scl_code           IN     NUMBER,
                                v_property_id        IN     VARCHAR2,
                                v_wef                IN     DATE,
                                v_wet                IN     DATE,
                                v_allow_duplicates      OUT VARCHAR2,
                                v_add_edit           IN     VARCHAR2)
        RETURN VARCHAR2
    IS
        v_cnt     NUMBER;
        v_msg     VARCHAR2 (2000);
        v_id      NUMBER;
        v_count   NUMBER;
    BEGIN
        --      IF NVL (v_add_edit, 'N') = 'E'
        --      THEN
        --         RETURN NULL;
        --      END IF;
        BEGIN
            v_allow_duplicates :=
                gin_parameters_pkg.get_param_varchar (
                    'ALLOW_DUPLICATION_OF_RISKS');
        EXCEPTION
            WHEN OTHERS
            THEN
                v_allow_duplicates := 'Y';
        END;