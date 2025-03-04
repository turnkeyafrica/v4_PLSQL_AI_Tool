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

        IF NVL (v_add_edit, 'A') = 'A'
        THEN
            BEGIN
                INSERT INTO gin_policy_insured_limits (
                                pil_code,
                                pil_ipu_code,
                                pil_sect_code,
                                pil_sect_sht_desc,
                                pil_desc,
                                pil_row_num,
                                pil_calc_group,
                                pil_limit_amt,
                                pil_prem_rate,
                                pil_prem_amt,
                                pil_rate_type,
                                pil_rate_desc,
                                pil_sect_type,
                                pil_original_prem_rate,
                                pil_multiplier_rate,
                                pil_multiplier_div_factor,
                                pil_annual_premium,
                                pil_rate_div_fact,
                                --PIL_DESC,
                                pil_compute,
                                pil_prd_type,
                                pil_dual_basis,
                                pil_prem_accumulation,
                                pil_declaration_section,
                                pil_annual_actual_prem,
                                pil_comment,
                                pil_free_limit,
                                pil_limit_prd,
                                pil_prorata_full,
                                pil_prr_max_rate,
                                pil_prr_min_rate)
                         VALUES (
                                       TO_NUMBER (TO_CHAR (SYSDATE, 'RRRR'))
                                    || gin_pil_code_seq.NEXTVAL,
                                    v_new_ipu_code,
                                    v_sect_code,
                                    v_sect_sht_desc,
                                    v_sect_desc,
                                    v_row,
                                    NVL (v_rsk_sect_data (1).pil_calc_group,
                                         1),
                                    NVL (v_rsk_sect_data (1).pil_limit_amt,
                                         v_limit),
                                    NVL (v_rsk_sect_data (1).pil_prem_rate,
                                         v_prr_rate),
                                    NVL (v_rsk_sect_data (1).pil_prem_amt, 0),
                                    v_prr_rate_type,
                                    v_prr_rate_desc,
                                    v_sect_type,
                                    v_prr_rate,
                                    NVL (
                                        v_rsk_sect_data (1).pil_multiplier_rate,
                                        v_prr_multiplier_rate),
                                    NVL (
                                        v_rsk_sect_data (1).pil_multiplier_div_factor,
                                        v_prr_multplier_div_fact),
                                    0,
                                    NVL (
                                        v_rsk_sect_data (1).pil_rate_div_fact,
                                        v_prr_division_factor),
                                    --v_type_desc,
                                    NVL (v_rsk_sect_data (1).pil_compute,
                                         'Y'),
                                    NULL,
                                    NVL (v_rsk_sect_data (1).pil_dual_basis,
                                         'N'),
                                    0,
                                    NVL (
                                        v_rsk_sect_data (1).pil_declaration_section,
                                        'N'),
                                    0,
                                    v_rsk_sect_data (1).pil_comment,
                                    v_rsk_sect_data (1).pil_free_limit_amt,
                                    v_rsk_sect_data (1).pil_limit_prd,
                                    v_rsk_sect_data (1).pil_prorata_full,
                                    v_prr_max_rate,
                                    v_prr_min_rate);
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error ('Error inserting risk sections..4');
            END;
        ELSE
            BEGIN
                UPDATE gin_policy_insured_limits
                   SET pil_limit_amt =
                           NVL (v_rsk_sect_data (1).pil_limit_amt, v_limit),
                       pil_prem_rate =
                           NVL (v_rsk_sect_data (1).pil_prem_rate,
                                v_prr_rate),
                       pil_sect_type = v_sect_type,
                       pil_min_premium = v_prr_prem_minimum_amt,
                       pil_rate_type = v_prr_rate_type,
                       pil_rate_desc = v_prr_rate_desc,
                       pil_rate_div_fact =
                           NVL (v_rsk_sect_data (1).pil_rate_div_fact,
                                v_prr_division_factor),
                       pil_multiplier_rate =
                           NVL (v_rsk_sect_data (1).pil_multiplier_rate,
                                v_prr_multiplier_rate),
                       pil_multiplier_div_factor =
                           NVL (
                               v_rsk_sect_data (1).pil_multiplier_div_factor,
                               v_prr_multplier_div_fact),
                       pil_row_num = v_row,
                       pil_compute =
                           NVL (v_rsk_sect_data (1).pil_compute, 'Y'),
                       pil_desc = v_sect_desc,
                       pil_dual_basis =
                           NVL (v_rsk_sect_data (1).pil_dual_basis, 'N'),
                       pil_calc_group =
                           NVL (v_rsk_sect_data (1).pil_calc_group, 1),
                       pil_prem_amt =
                           NVL (v_rsk_sect_data (1).pil_prem_amt, 0),
                       pil_comment = v_rsk_sect_data (1).pil_comment,
                       pil_declaration_section =
                           NVL (v_rsk_sect_data (1).pil_declaration_section,
                                'N'),
                       pil_free_limit_amt =
                           v_rsk_sect_data (1).pil_free_limit_amt,
                       pil_limit_prd = v_rsk_sect_data (1).pil_limit_prd,
                       pil_prorata_full =
                           v_rsk_sect_data (1).pil_prorata_full,
                       pil_prr_max_rate = v_prr_max_rate,
                       pil_prr_min_rate = v_prr_min_rate
                 WHERE     pil_ipu_code = v_new_ipu_code
                       AND pil_code = v_rsk_sect_data (1).pil_code;
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error ('Error updating risk sections..');
            END;
        END IF;
    END;