PROCEDURE check_duplicate_quot_risks (v_quot_code IN NUMBER)
    IS
        v_cnt                NUMBER;
        v_allow_duplicates   VARCHAR2 (5);
        v_msg                VARCHAR2 (2000);
        v_count              NUMBER;

        CURSOR dup_risk IS
            SELECT qr_quot_code, qr_property_id, qr_scl_code
              FROM gin_quot_risks
             WHERE qr_quot_code = v_quot_code;

        CURSOR dup_distinct_risk IS
            SELECT DISTINCT qr_quot_code, qr_property_id, qr_scl_code
              FROM gin_quot_risks
             WHERE qr_quot_code = v_quot_code;
    BEGIN
        BEGIN
            v_allow_duplicates :=
                gin_parameters_pkg.get_param_varchar (
                    'ALLOW_DUPLICATION_OF_RISKS');
        EXCEPTION
            WHEN OTHERS
            THEN
                v_allow_duplicates := 'Y';
        END;