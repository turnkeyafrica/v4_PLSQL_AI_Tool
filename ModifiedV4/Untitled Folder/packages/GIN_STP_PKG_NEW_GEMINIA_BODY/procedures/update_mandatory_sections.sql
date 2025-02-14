PROCEDURE update_mandatory_sections (
        v_new_ipu_code    IN NUMBER,
        v_scl_code        IN NUMBER,
        v_bind_code       IN NUMBER,
        v_covt_code       IN NUMBER,
        v_limit           IN NUMBER,
        v_cashback_only   IN VARCHAR2 DEFAULT 'N',
        v_module          IN VARCHAR2 DEFAULT 'P')
    IS
        CURSOR mandatory_sections IS
            SELECT DISTINCT sect_code, scvts_order, scvts_calc_group
              FROM gin_premium_rates,
                   gin_sections,
                   gin_subcl_sections,
                   gin_subcl_covt_sections
             WHERE     prr_sect_code = sect_code
                   AND sec_sect_code = prr_sect_code
                   AND sec_scl_code = prr_scl_code
                   AND prr_scl_code = v_scl_code
                   AND prr_bind_code = v_bind_code
                   AND scvts_scl_code = v_scl_code
                   AND scvts_covt_code = v_covt_code
                   AND sect_code = scvts_sect_code
                   AND NVL (scvts_mandatory, 'N') = 'Y';

        CURSOR cashback_sections IS
            SELECT DISTINCT sect_code
              FROM gin_premium_rates,
                   gin_sections,
                   gin_subcl_sections,
                   gin_subcl_covt_sections
             WHERE     prr_sect_code = sect_code
                   AND sec_sect_code = prr_sect_code
                   AND sec_scl_code = prr_scl_code
                   AND prr_scl_code = v_scl_code
                   AND prr_bind_code = v_bind_code
                   AND scvts_scl_code = v_scl_code
                   AND scvts_covt_code = v_covt_code
                   AND sect_code = scvts_sect_code
                   AND NVL (sect_type, 'SI') = 'CB';

        v_ipu_cashback_appl    VARCHAR2 (5) := 'N';
        v_ipu_cashback_level   NUMBER := 0;
        v_row                  NUMBER;
    BEGIN
        BEGIN
            SELECT NVL (ipu_cashback_appl, 'N'), NVL (ipu_cashback_level, 0)
              INTO v_ipu_cashback_appl, v_ipu_cashback_level
              FROM gin_insured_property_unds
             WHERE ipu_code = v_new_ipu_code;
        EXCEPTION
            WHEN OTHERS
            THEN
                NULL;
        END;