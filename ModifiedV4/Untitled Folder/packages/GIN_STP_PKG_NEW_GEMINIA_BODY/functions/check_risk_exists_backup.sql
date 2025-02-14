FUNCTION check_risk_exists_backup (v_pol_batch_no       IN     NUMBER,
                                       v_scl_code           IN     NUMBER,
                                       v_property_id        IN     VARCHAR2,
                                       v_allow_duplicates      OUT VARCHAR2)
        RETURN VARCHAR2
    IS
        v_cnt   NUMBER;
        v_msg   VARCHAR2 (2000);
        v_id    NUMBER;
    BEGIN
        raise_error ('INNNNNNNNNNNN222');

        BEGIN
            v_allow_duplicates :=
                gin_parameters_pkg.get_param_varchar (
                    'ALLOW_DUPLICATION_OF_RISKS');
        EXCEPTION
            WHEN OTHERS
            THEN
                v_allow_duplicates := 'Y';
        END;