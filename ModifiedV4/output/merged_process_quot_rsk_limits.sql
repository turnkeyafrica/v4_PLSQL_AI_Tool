```sql
PROCEDURE process_quot_rsk_limits (
    v_qr_code         IN   NUMBER,
    v_qp_code         IN   NUMBER,
    v_quot_code       IN   NUMBER,
    v_pro_code        IN   NUMBER,
    v_scl_code        IN   NUMBER,
    v_bind_code       IN   NUMBER,
    v_sect_code       IN   NUMBER,
    v_limit           IN   NUMBER,
    v_row             IN   NUMBER,
    v_add_edit        IN   VARCHAR2,
    v_rsk_sect_data   IN   rsk_sect_tab
)
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

    CURSOR pil_cur (
        vsectcode   IN   NUMBER,
        vbindcode   IN   NUMBER,
        vsclcode    IN   NUMBER
    )
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
               prr_rate_desc
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
                       prr_rate_desc
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
                       prr_rate_desc
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
                       prr_rate_desc
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
                       prr_rate_desc
                  FROM gin_premium_rates, gin_sections
                 WHERE     prr_sect_code = sect_code
                       AND sect_code = vsectcode
                       AND prr_bind_code = vbindcode
                       AND prr_scl_code = vsclcode
                       AND sect_type = 'ND');
BEGIN
    BEGIN
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
                     v_prr_rate_desc;
        END LOOP;

        CLOSE pil_cur;
    EXCEPTION
        WHEN OTHERS
        THEN
            raise_error (
                   'Error getting the premium rates for section: '
                || v_sect_code
                || '-'
                || v_bind_code
                || '-'
                || v_scl_code);
    END;

    IF NVL (v_add_edit, 'A') = 'A'
    THEN
        BEGIN
            INSERT INTO gin_quot_risk_limits (
                qrl_code,
                qrl_ipu_code,
                qrl_sect_code,
                qrl_sect_sht_desc,
                qrl_limit_amt,
                qrl_prem_rate,
                qrl_prem_amt,
                qrl_qr_code,
                qrl_qr_quot_code,
                qrl_qp_pro_code,
                qrl_qp_code,
                qrl_sect_type,
                qrl_min_premium,
                qrl_rate_type,
                qrl_rate_desc,
                qrl_rate_div_factor,
                qrl_multiplier_rate,
                qrl_multiplier_div_factor,
                qrl_row_num,
                qrl_calc_group,
                qrl_compute,
                qrl_annual_prem,
                qrl_used_limit,
                qrl_desc,
                qrl_dual_basis,
                qrl_indem_prd,
                qrl_prd_type,
                qrl_indem_fstprd,
                qrl_indem_fstprd_pct,
                qrl_indem_remprd_pct,
                qrl_free_limit
            ) VALUES (
                TO_NUMBER (TO_CHAR (SYSDATE, 'YYYY') || gin_qrl_code_seq.NEXTVAL),
                NULL,
                v_sect_code,
                v_sect_sht_desc,
                NVL (v_rsk_sect_data (1).pil_limit_amt, v_limit),
                NVL (v_rsk_sect_data (1).pil_prem_rate, v_prr_rate),
                NVL (v_rsk_sect_data (1).pil_prem_amt, 0),
                v_qr_code,
                v_quot_code,
                v_pro_code,
                v_qp_code,
                v_sect_type,
                v_prr_prem_minimum_amt,
                v_prr_rate_type,
                v_prr_rate_desc,
                NVL (v_rsk_sect_data (1).pil_rate_div_fact, v_prr_division_factor),
                NVL (v_rsk_sect_data (1).pil_multiplier_rate, v_prr_multiplier_rate),
                NVL (v_rsk_sect_data (1).pil_multiplier_div_factor, v_prr_multplier_div_fact),
                v_row,
                NVL (v_rsk_sect_data (1).pil_calc_group, 1),
                NVL (v_rsk_sect_data (1).pil_compute, 'Y'),
                0,
                NULL,
                v_sect_desc,
                NVL (v_rsk_sect_data (1).pil_dual_basis, 'N'),
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                v_rsk_sect_data (1).pil_free_limit_amt
            );
        EXCEPTION
            WHEN OTHERS
            THEN
                raise_error ('Error inserting risk sections..');
        END;
    ELSE
        BEGIN
            UPDATE gin_quot_risk_limits
               SET 
                   qrl_limit_amt = NVL (v_rsk_sect_data (1).pil_limit_amt, v_limit),
                   qrl_prem_rate = NVL (v_rsk_sect_data (1).pil_prem_rate, v_prr_rate),
                   qrl_qp_pro_code = v_pro_code,
                   qrl_sect_type = v_sect_type,
                   qrl_min_premium = v_prr_prem_minimum_amt,
                   qrl_rate_type = v_prr_rate_type,
                   qrl_rate_desc = v_prr_rate_desc,
                   qrl_rate_div_factor =
                       NVL (v_rsk_sect_data (1).pil_rate_div_fact, v_prr_division_factor),
                   qrl_multiplier_rate =
                       NVL (v_rsk_sect_data (1).pil_multiplier_rate, v_prr_multiplier_rate),
                   qrl_multiplier_div_factor =
                       NVL (
                           v_rsk_sect_data (1).pil_multiplier_div_factor,
                           v_prr_multplier_div_fact
                       ),
                   qrl_row_num = v_row,
                   qrl_calc_group = NVL (v_rsk_sect_data (1).pil_calc_group, 1),
                   qrl_compute = NVL (v_rsk_sect_data (1).pil_compute, 'Y'),
                   qrl_desc = v_sect_desc,
                   qrl_dual_basis = NVL (v_rsk_sect_data (1).pil_dual_basis, 'N'),
                   qrl_prem_amt = NVL (v_rsk_sect_data (1).pil_prem_amt, 0),
                   qrl_free_limit = v_rsk_sect_data (1).pil_free_limit_amt
             WHERE qrl_qr_code = v_qr_code
               AND qrl_code = v_rsk_sect_data (1).pil_code;
        EXCEPTION
            WHEN OTHERS
            THEN
                raise_error ('Error updating risk sections..');
        END;
    END IF;
END;

```