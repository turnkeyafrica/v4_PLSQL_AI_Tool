PROCEDURE gin_quote_rsk_limits (v_qr_code         IN NUMBER,
                                    v_scl_code        IN NUMBER,
                                    v_bind_code       IN NUMBER,
                                    v_sect_code       IN NUMBER,
                                    v_limit           IN NUMBER,
                                    v_row             IN NUMBER,
                                    v_add_edit        IN VARCHAR2,
                                    v_rsk_sect_data   IN web_sect_tab)
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
        v_cnt                      NUMBER;
        v_cover_days               NUMBER;
        v_prrd_max_rate            NUMBER;
        v_prrd_min_rate            NUMBER;
        v_age                      NUMBER;
        v_cur_code                 NUMBER;
        v_rsk_travel_sect_data     gin_travel_stp_pkg.rsk_sect_tab;
        v_batch_no                 NUMBER;
        v_count                    NUMBER := 0;
        v_dec_section              VARCHAR2 (5);
        v_calc_group               NUMBER := 1;
        v_calc_row                 NUMBER := 1;

        CURSOR pil_cur (vsectcode       IN NUMBER,
                        vbindcode       IN NUMBER,
                        vsclcode        IN NUMBER,
                        vrange          IN NUMBER,
                        vfreg           IN VARCHAR2,
                        v_cashbck_lvl   IN NUMBER)
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
                                   'EC', 'ESCALATION',
                                   'RS', 'Rider Section')
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
                           AND sect_type NOT IN ('ND', 'CB')
                           AND prr_rate_type IN ('FXD', 'RT')
                           AND prr_type = 'N'
                           AND NVL (prr_rate_freq_type, 'A') = vfreg
                           AND NVL (vrange, 0) BETWEEN NVL (prr_range_from,
                                                            0)
                                                   AND NVL (prr_range_to, 0)
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
                                   'EC', 'ESCALATION',
                                   'RS', 'Rider Section')
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
                           AND prr_type = 'N'
                           AND sect_type NOT IN ('ND', 'CB')
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
                                   'EC', 'ESCALATION',
                                   'RS', 'Rider Section')
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
                           AND prr_type = 'N'
                           AND prr_scl_code = vsclcode
                           AND sect_type NOT IN ('ND', 'CB')
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
                           AND prr_type = 'N'
                           AND sect_type = 'ND'
                    UNION
                    SELECT DISTINCT
                           sect_sht_desc,
                           sect_code,
                           sect_desc
                               sect_desc,
                           sect_type,
                           DECODE (sect_type, 'CB', 'CASHBACK')
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
                           AND prr_type = 'N'
                           AND NVL (prr_cashback_level, 0) = v_cashbck_lvl
                           AND NVL (prr_cashback_appl, 'N') = 'Y'
                           AND sect_type = 'CB');

        v_freq                     VARCHAR2 (2);
        v_range                    NUMBER;
        v_alb_required             VARCHAR2 (2);
        v_pol_status               VARCHAR2 (10);
        v_cashback_lvl             NUMBER;
        v_pil_code                 NUMBER;
        v_pro_code                 NUMBER;
        v_qp_code                  NUMBER;
        v_quot_code                NUMBER;
    BEGIN
        BEGIN
            SELECT DECODE (scl_alb_required,
                           'Y', NVL (quot_freq_of_payment, 'A'),
                           'A'),
                   DECODE (
                       scl_alb_required,
                       'Y', gin_travel_stp_pkg.get_alb (TRUNC (SYSDATE),
                                                        clnt_dob),
                       DECODE (NVL (scl_use_cover_period_range, 'N'),
                               'Y', (QR_WET - QR_WEF),
                               0)),
                   scl_alb_required,
                   QUOT_STATUS,
                   'N'
                       cashback_lvl,
                   QP_PRO_CODE,
                   QP_CODE,
                   QUOT_CODE
              INTO v_freq,
                   v_range,
                   v_alb_required,
                   v_pol_status,
                   v_cashback_lvl,
                   v_pro_code,
                   v_qp_code,
                   v_quot_code
              FROM gin_quot_risks,
                   gin_quotations,
                   tqc_clients,
                   gin_sub_classes,
                   gin_quot_products
             WHERE     qr_quot_code = quot_code
                   AND qp_quot_code = quot_code
                   AND qr_prp_code = clnt_code
                   AND qp_code = qr_qp_code
                   AND qr_code = v_qr_code
                   AND qr_scl_code = scl_code;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                v_freq := 'A';
            WHEN OTHERS
            THEN
                v_freq := 'A';
        END;

        IF NVL (v_alb_required, 'N') = 'Y' AND NVL (v_range, 0) = 0
        THEN
            raise_error (
                'Insured age is required for this subclass. Please define the insured age first....');
        END IF;

        BEGIN
            --      RAISE_ERROR('sect code '||v_sect_code||'bind code '||v_bind_code||'scl code '||v_scl_code||';'||v_cashback_lvl);
            OPEN pil_cur (v_sect_code,
                          v_bind_code,
                          v_scl_code,
                          v_range,
                          v_freq,
                          v_cashback_lvl);

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
                         v_prrd_max_rate,
                         v_prrd_min_rate;
            END LOOP;

            --RAISE_ERROR('v_prrd_min_rate ==== '||v_prrd_min_rate);
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

        --raise_error('v_sect_sht_desc '||v_sect_code||' v_bind_code '||v_bind_code||' v_scl_code '||v_scl_code);
        IF NVL (v_add_edit, 'A') = 'A'
        THEN
            BEGIN
                SELECT COUNT (*)
                  INTO v_cnt
                  FROM gin_products,
                       gin_product_sub_classes,
                       gin_product_groups
                 WHERE     pro_prg_code = prg_code
                       AND pro_code = clp_pro_code
                       AND prg_type = 'TRAVEL'
                       AND clp_scl_code = v_scl_code;
            EXCEPTION
                WHEN OTHERS
                THEN
                    NULL;
            END;

            --        IF NVL (v_cnt, 0) = 0
            --        THEN
            BEGIN
                IF v_prr_rate_type IS NULL
                THEN
                    raise_error (
                        'Error getting Rate Type...Please specify rate type..0..');
                END IF;

                IF v_pol_status = 'DC'
                THEN
                    raise_error (
                        'You cannot add a section to a declaration...');
                END IF;


                BEGIN
                    SELECT DISTINCT SCVTS_ORDER, SCVTS_CALC_GROUP
                      INTO v_calc_row, v_calc_group
                      FROM GIN_SUBCL_COVT_SECTIONS
                     WHERE     SCVTS_SECT_CODE = v_sect_code
                           AND SCVTS_SCL_CODE = v_scl_code
                           AND SCVTS_COVT_CODE IN
                                   (SELECT QR_COVT_CODE
                                      FROM gin_quot_risks
                                     WHERE qr_code = v_qr_code);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        v_calc_group := 1;
                        v_calc_row := 1;
                END;

                --raise_error ('v_new_ipu_code='||v_new_ipu_code);

                --QRL_QR_CODE
                /****************************************************/
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
                                    qrl_free_limit)
                             VALUES (
                                        TO_NUMBER (
                                               TO_CHAR (SYSDATE, 'YYYY')
                                            || gin_qrl_code_seq.NEXTVAL),
                                        NULL,
                                        v_sect_code,
                                        v_sect_sht_desc,
                                        NVL (
                                            v_rsk_sect_data (1).pil_limit_amt,
                                            v_limit),
                                        NVL (
                                            v_rsk_sect_data (1).pil_prem_rate,
                                            v_prr_rate),
                                        NVL (
                                            v_rsk_sect_data (1).pil_prem_amt,
                                            0),
                                        v_qr_code,
                                        v_quot_code,
                                        v_pro_code,
                                        v_qp_code,
                                        v_sect_type,
                                        v_prr_prem_minimum_amt,
                                        v_prr_rate_type,
                                        v_prr_rate_desc,
                                        NVL (
                                            v_rsk_sect_data (1).pil_rate_div_fact,
                                            v_prr_division_factor),
                                        NVL (
                                            v_rsk_sect_data (1).pil_multiplier_rate,
                                            v_prr_multiplier_rate),
                                        NVL (
                                            v_rsk_sect_data (1).pil_multiplier_div_factor,
                                            v_prr_multplier_div_fact),
                                        v_row,
                                        1,
                                        'Y',
                                        0,
                                        NULL,
                                        NVL (v_rsk_sect_data (1).pil_desc,
                                             v_sect_desc),
                                        'N',
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        v_rsk_sect_data (1).pil_free_limit_amt);
                --raise_Error(v_qr_code||' = '||v_qr_code||' = '||v_cvt_code||'= ' ||v_cvt_code);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error ('Error inserting risk sections..');
                END;
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error (
                        'Error inserting risk sections..' || v_sect_sht_desc);
            END;
        --        END IF;
        ELSE
            NULL;
        END IF;
    END;
END gin_stp_pkg;