PROCEDURE process_stp_rsk_limits (v_new_ipu_code    IN NUMBER,
                                      v_scl_code        IN NUMBER,
                                      v_bind_code       IN NUMBER,
                                      v_sect_code       IN NUMBER,
                                      v_limit           IN NUMBER,
                                      v_row             IN NUMBER,
                                      v_add_edit        IN VARCHAR2,
                                      v_rsk_sect_data   IN rsk_sect_tab)
    IS
        v_sect_sht_desc            VARCHAR2 (30);
        v_sect_desc                VARCHAR2 (80);
        v_sect_type                VARCHAR2 (30);
        v_type_desc                VARCHAR2 (30);
        v_prr_rate_type            VARCHAR2 (10);
        v_prr_rate                 NUMBER;
        v_terr_description         VARCHAR2 (30);
        v_prr_prem_minimum_amt     NUMBER;
        v_prr_multiplier_rate      NUMBER;
        v_prr_division_factor      NUMBER;
        v_prr_multplier_div_fact   NUMBER;
        v_prr_rate_desc            VARCHAR2 (30);
        v_batch_no                 NUMBER;
        v_prr_max_rate             NUMBER;
        v_prr_min_rate             NUMBER;

        CURSOR pil_cur (vsectcode   IN NUMBER,
                        vbindcode   IN NUMBER,
                        vsclcode    IN NUMBER)
        IS
            SELECT sect_sht_desc,
                   sect_desc,
                   sect_type,
                   type_desc,
                   prr_rate_type,
                   prr_rate,
                   terr_description,
                   prr_prem_minimum_amt,
                   prr_multiplier_rate,
                   prr_division_factor,
                   prr_multplier_div_fact,
                   prr_rate_desc,
                   prr_max_rate,
                   prr_min_rate
              FROM (SELECT DISTINCT
                           sect_sht_desc,
                           sect_code,
                           sect_desc                      sect_desc,
                           sect_type,
                           DECODE (sect_type,
                                   'ES', 'EXTENSION SI',
                                   'EL', 'EXTENSION LIMIT',
                                   'SS', 'SECTION SI',
                                   'SL', 'SECTION LIMIT',
                                   'DS', 'DISCOUNT',
                                   'LO', 'LOADING',
                                   'EC', 'ESCALATION')    type_desc,
                           prr_rate_type,
                           prr_rate,
                           prr_rate                       rate,
                           '0'                            terr_description,
                           prr_prem_minimum_amt,
                           prr_multiplier_rate,
                           prr_division_factor,
                           prr_multplier_div_fact,
                           prr_rate_desc,
                           prr_max_rate,
                           prr_min_rate
                      FROM gin_premium_rates, gin_sections
                     WHERE     prr_sect_code = sect_code
                           AND sect_code = vsectcode
                           AND prr_bind_code = vbindcode
                           AND prr_scl_code = vsclcode
                           AND sect_type != 'ND'
                           AND prr_rate_type = 'FXD'
                    UNION
                    SELECT DISTINCT
                           sect_sht_desc,
                           sect_code,
                           sect_desc
                               sect_desc,
                           sect_type,
                           DECODE (sect_type,
                                   'ES', 'EXTENSION SI',
                                   'EL', 'EXTENSION LIMIT',
                                   'SS', 'SECTION SI',
                                   'SL', 'SECTION LIMIT',
                                   'DS', 'DISCOUNT',
                                   'LO', 'LOADING',
                                   'EC', 'ESCALATION')
                               type_desc,
                           prr_rate_type,
                           0
                               prr_rate,
                           0
                               rate,
                           '0'
                               terr_description,
                           0
                               prr_prem_minimum_amt,
                           1
                               prr_multiplier_rate,
                           1
                               prr_division_factor,
                           1
                               prr_multplier_div_fact,
                           prr_rate_desc,
                           prr_max_rate,
                           prr_min_rate
                      FROM gin_premium_rates, gin_sections
                     WHERE     prr_sect_code = sect_code
                           AND sect_code = vsectcode
                           AND prr_bind_code = vbindcode
                           AND prr_scl_code = vsclcode
                           AND sect_type != 'ND'
                           AND prr_rate_type IN ('SRG', 'RCU')
                    UNION
                    SELECT DISTINCT
                           sect_sht_desc,
                           sect_code,
                           sect_desc
                               sect_desc,
                           sect_type,
                           DECODE (sect_type,
                                   'ES', 'EXTENSION SI',
                                   'EL', 'EXTENSION LIMIT',
                                   'SS', 'SECTION SI',
                                   'SL', 'SECTION LIMIT',
                                   'DS', 'DISCOUNT',
                                   'LO', 'LOADING',
                                   'EC', 'ESCALATION')
                               type_desc,
                           prr_rate_type,
                           0
                               prr_rate,
                           0
                               rate,
                           '0'
                               terr_description,
                           0
                               prr_prem_minimum_amt,
                           1
                               prr_multiplier_rate,
                           1
                               prr_division_factor,
                           1
                               prr_multplier_div_fact,
                           prr_rate_desc,
                           prr_max_rate,
                           prr_min_rate
                      FROM gin_premium_rates, gin_sections
                     WHERE     prr_sect_code = sect_code
                           AND sect_code = vsectcode
                           AND prr_bind_code = vbindcode
                           AND prr_scl_code = vsclcode
                           AND sect_type != 'ND'
                           AND prr_rate_type = 'ARG'
                    UNION
                    SELECT DISTINCT
                           sect_sht_desc,
                           sect_code,
                           sect_desc
                               sect_desc,
                           sect_type,
                           DECODE (sect_type, 'ND', 'NCD')
                               type_desc,
                           prr_rate_type,
                           prr_rate,
                           prr_rate
                               rate,
                           '0'
                               terr_description,
                           prr_prem_minimum_amt,
                           prr_multiplier_rate,
                           prr_division_factor,
                           prr_multplier_div_fact,
                           prr_rate_desc,
                           prr_max_rate,
                           prr_min_rate
                      FROM gin_premium_rates, gin_sections
                     WHERE     prr_sect_code = sect_code
                           AND sect_code = vsectcode
                           AND prr_bind_code = vbindcode
                           AND prr_scl_code = vsclcode
                           AND sect_type = 'ND');
    BEGIN
        BEGIN
            ---RAISE_ERROR('v_sect_code'||v_sect_code||'v_bind_code'||v_bind_code||'v_scl_code'||v_scl_code);
            OPEN pil_cur (v_sect_code, v_bind_code, v_scl_code);

            LOOP
                EXIT WHEN pil_cur%NOTFOUND;

                FETCH pil_cur
                    INTO v_sect_sht_desc,
                         v_sect_desc,
                         v_sect_type,
                         v_type_desc,
                         v_prr_rate_type,
                         v_prr_rate,
                         v_terr_description,
                         v_prr_prem_minimum_amt,
                         v_prr_multiplier_rate,
                         v_prr_division_factor,
                         v_prr_multplier_div_fact,
                         v_prr_rate_desc,
                         v_prr_max_rate,
                         v_prr_min_rate;
            END LOOP;

            CLOSE pil_cur;
        EXCEPTION
            WHEN OTHERS
            THEN
                raise_error (
                       'Error getting the premium rates for 1st section..'
                    || v_sect_code
                    || '-'
                    || v_bind_code
                    || '-'
                    || v_scl_code);
        END;