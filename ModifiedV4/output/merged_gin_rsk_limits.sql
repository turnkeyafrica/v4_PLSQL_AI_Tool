```sql
PROCEDURE gin_rsk_limits (
    v_new_ipu_code    IN   NUMBER,
    v_scl_code        IN   NUMBER,
    v_bind_code       IN   NUMBER,
    v_sect_code       IN   NUMBER,
    v_limit           IN   NUMBER,
    v_row             IN   NUMBER,
    v_add_edit        IN   VARCHAR2,
    v_rsk_sect_data   IN   web_sect_tab
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
    v_cnt                      NUMBER;
    v_cover_days               NUMBER;
    v_prrd_max_rate            NUMBER;
    v_prrd_min_rate            NUMBER;
    v_age                      NUMBER;
    v_cur_code                 NUMBER;
    v_rsk_travel_sect_data     gin_travel_stp_pkg.rsk_sect_tab;
    v_batch_no                 NUMBER;
    v_count                    NUMBER                          := 0;
    v_dec_section              VARCHAR2 (5);
    v_calc_group               NUMBER := 1;
    v_calc_row                 NUMBER := 1;
    
    CURSOR pil_cur (
        vsectcode   IN   NUMBER,
        vbindcode   IN   NUMBER,
        vsclcode    IN   NUMBER,
        vrange      IN   NUMBER,
        vfreg       IN   VARCHAR2,
        v_cashbck_lvl IN NUMBER
    )
    IS
        SELECT sect_sht_desc, sect_desc, sect_type, type_desc,
               prr_rate_type, prr_rate, terr_description,
               prr_prem_minimum_amt, prr_multiplier_rate,
               prr_division_factor, prr_multplier_div_fact, prr_rate_desc,
               prr_max_rate, prr_min_rate
          FROM (SELECT DISTINCT sect_sht_desc, sect_code,
                                sect_desc sect_desc, sect_type,
                                DECODE (sect_type,
                                        'ES', 'EXTENSION SI',
                                        'EL', 'EXTENSION LIMIT',
                                        'SS', 'SECTION SI',
                                        'SL', 'SECTION LIMIT',
                                        'DS', 'DISCOUNT',
                                        'LO', 'LOADING',
                                        'EC', 'ESCALATION',
                                        'RS', 'Rider Section'
                                       ) type_desc,
                                prr_rate_type, prr_rate, prr_rate rate,
                                '0' terr_description, prr_prem_minimum_amt,
                                prr_multiplier_rate, prr_division_factor,
                                prr_multplier_div_fact, prr_rate_desc,
                                prr_max_rate, prr_min_rate
                           FROM gin_premium_rates, gin_sections
                          WHERE prr_sect_code = sect_code
                            AND sect_code = vsectcode
                            AND prr_bind_code = vbindcode
                            AND prr_scl_code = vsclcode
                            AND sect_type NOT IN ('ND','CB')
                            AND prr_rate_type IN ('FXD', 'RT')
                            AND PRR_TYPE ='N'
                            AND NVL (prr_rate_freq_type, 'A') = vfreg
                            AND NVL (vrange, 0) BETWEEN NVL (prr_range_from,
                                                             0
                                                            )
                                                    AND NVL (prr_range_to, 0)
                UNION
                SELECT DISTINCT sect_sht_desc, sect_code,
                                sect_desc sect_desc, sect_type,
                                DECODE (sect_type,
                                        'ES', 'EXTENSION SI',
                                        'EL', 'EXTENSION LIMIT',
                                        'SS', 'SECTION SI',
                                        'SL', 'SECTION LIMIT',
                                        'DS', 'DISCOUNT',
                                        'LO', 'LOADING',
                                        'EC', 'ESCALATION',
                                        'RS', 'Rider Section'
                                       ) type_desc,
                                prr_rate_type, 0 prr_rate, 0 rate,
                                '0' terr_description, 0 prr_prem_minimum_amt,
                                1 prr_multiplier_rate, 1 prr_division_factor,
                                1 prr_multplier_div_fact, prr_rate_desc,
                                prr_max_rate, prr_min_rate
                           FROM gin_premium_rates, gin_sections
                          WHERE prr_sect_code = sect_code
                            AND sect_code = vsectcode
                            AND prr_bind_code = vbindcode
                            AND prr_scl_code = vsclcode
                            AND PRR_TYPE ='N'
                            AND sect_type NOT IN ('ND','CB')
                            AND prr_rate_type IN ('SRG', 'RCU')
                UNION
                SELECT DISTINCT sect_sht_desc, sect_code,
                                sect_desc sect_desc, sect_type,
                                DECODE (sect_type,
                                        'ES', 'EXTENSION SI',
                                        'EL', 'EXTENSION LIMIT',
                                        'SS', 'SECTION SI',
                                        'SL', 'SECTION LIMIT',
                                        'DS', 'DISCOUNT',
                                        'LO', 'LOADING',
                                        'EC', 'ESCALATION',
                                        'RS', 'Rider Section'
                                       ) type_desc,
                                prr_rate_type, 0 prr_rate, 0 rate,
                                '0' terr_description, 0 prr_prem_minimum_amt,
                                1 prr_multiplier_rate, 1 prr_division_factor,
                                1 prr_multplier_div_fact, prr_rate_desc,
                                prr_max_rate, prr_min_rate
                           FROM gin_premium_rates, gin_sections
                          WHERE prr_sect_code = sect_code
                            AND sect_code = vsectcode
                            AND prr_bind_code = vbindcode
                            AND PRR_TYPE ='N'
                            AND prr_scl_code = vsclcode
                            AND sect_type NOT IN ('ND','CB')
                            AND prr_rate_type = 'ARG'
                UNION
                SELECT DISTINCT sect_sht_desc, sect_code,
                                sect_desc sect_desc, sect_type,
                                DECODE (sect_type, 'ND', 'NCD') type_desc,
                                prr_rate_type, prr_rate, prr_rate rate,
                                '0' terr_description, prr_prem_minimum_amt,
                                prr_multiplier_rate, prr_division_factor,
                                prr_multplier_div_fact, prr_rate_desc,
                                prr_max_rate, prr_min_rate
                           FROM gin_premium_rates, gin_sections
                          WHERE prr_sect_code = sect_code
                            AND sect_code = vsectcode
                            AND prr_bind_code = vbindcode
                            AND prr_scl_code = vsclcode
                            AND PRR_TYPE ='N'
                            AND sect_type = 'ND'
                            UNION
                            SELECT DISTINCT sect_sht_desc, sect_code,
                                sect_desc sect_desc, sect_type,
                                DECODE (sect_type, 'CB', 'CASHBACK')  type_desc,
                                prr_rate_type, prr_rate, prr_rate rate,
                                '0' terr_description, prr_prem_minimum_amt,
                                prr_multiplier_rate, prr_division_factor,
                                prr_multplier_div_fact, prr_rate_desc,
                                prr_max_rate, prr_min_rate
                           FROM gin_premium_rates, gin_sections
                          WHERE prr_sect_code = sect_code
                            AND sect_code = vsectcode
                            AND prr_bind_code = vbindcode
                            AND prr_scl_code = vsclcode
                            AND PRR_TYPE ='N'
                            AND NVL(prr_cashback_level,0) =v_cashbck_lvl
                            AND NVL(prr_cashback_appl,'N')='Y'
                            AND sect_type = 'CB');

    v_freq                     VARCHAR2 (2);
    v_range                    NUMBER;
    v_alb_required             VARCHAR2 (2);
    v_pol_status               VARCHAR2 (10);
    v_cashback_lvl number;
    v_pil_code  number;
BEGIN
    BEGIN
        SELECT DECODE (scl_alb_required,
                       'Y', NVL (pol_freq_of_payment, 'A'),
                       'A'
                      ),
               DECODE (scl_alb_required,
                       'Y', gin_travel_stp_pkg.get_alb (TRUNC (SYSDATE),
                                                        clnt_dob
                                                       ),
                       DECODE (NVL (scl_use_cover_period_range, 'N'),
                               'Y', (ipu_wet - ipu_wef),
                               0
                              )
                      ),
               scl_alb_required, pol_policy_status,DECODE(NVL(ipu_cashback_appl,'N'),'Y',NVL(ipu_cashback_level,0),0)
          INTO v_freq,
               v_range,
               v_alb_required, v_pol_status,v_cashback_lvl
          FROM gin_policies,
               gin_insured_property_unds,
               gin_sub_classes,
               tqc_clients
         WHERE pol_batch_no = ipu_pol_batch_no
           AND ipu_code = v_new_ipu_code
           AND clnt_code = ipu_prp_code
           AND ipu_sec_scl_code = scl_code;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            v_freq := 'A';
        WHEN OTHERS
        THEN
            v_freq := 'A';   --RAISE_ERROR('Error fetching policy freq....');
    END;

    IF NVL (v_alb_required, 'N') = 'Y' AND NVL (v_range, 0) = 0
    THEN
        raise_error
           ('Insured age is required for this subclass. Please define the insured age first....'
           );
    END IF;

    BEGIN
--      RAISE_ERROR('sect code '||v_sect_code||'bind code '||v_bind_code||'scl code '||v_scl_code||';'||v_cashback_lvl);
        OPEN pil_cur (v_sect_code, v_bind_code, v_scl_code, v_range, v_freq,v_cashback_lvl);

        LOOP
            EXIT WHEN pil_cur%NOTFOUND;

            FETCH pil_cur
             INTO v_sect_sht_desc, v_sect_desc, v_sect_type, v_type_desc,
                  v_prr_rate_type, v_prr_rate, v_terr_description,
                  v_prr_prem_minimum_amt, v_prr_multiplier_rate,
                  v_prr_division_factor, v_prr_multplier_div_fact,
                  v_prr_rate_desc, v_prrd_max_rate, v_prrd_min_rate;
        END LOOP;

--RAISE_ERROR('v_prrd_min_rate ==== '||v_prrd_min_rate);
        CLOSE pil_cur;
    EXCEPTION
        WHEN OTHERS
        THEN
            raise_error
                     (   'Error getting the premium rates for 1st section..'
                      || v_sect_code
                      || '-'
                      || v_bind_code
                      || '-'
                      || v_scl_code
                     );
    END;

    --raise_error('v_sect_sht_desc '||v_sect_code||' v_bind_code '||v_bind_code||' v_scl_code '||v_scl_code);
    IF NVL (v_add_edit, 'A') = 'A'
    THEN
        BEGIN
            SELECT COUNT (*)
              INTO v_cnt
              FROM gin_products, gin_product_sub_classes, gin_product_groups
             WHERE pro_prg_code = prg_code
               AND pro_code = clp_pro_code
               AND prg_type = 'TRAVEL'
               AND clp_scl_code = v_scl_code;
        EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
        END;

        IF NVL (v_cnt, 0) = 0
        THEN
            BEGIN
                IF v_prr_rate_type IS NULL
                THEN
                    raise_error
                       ('Error getting Rate Type...Please specify rate type..0..');
                END IF;

                IF v_pol_status = 'DC'
                THEN
                    raise_error ('You cannot add a section to a declaration...');
                END IF;
--raise_error ('v_new_ipu_code='||v_new_ipu_code);
            
             BEGIN
                        SELECT DISTINCT SCVTS_ORDER, SCVTS_CALC_GROUP
                          INTO v_calc_row, v_calc_group
                          FROM GIN_SUBCL_COVT_SECTIONS
                         WHERE     SCVTS_SECT_CODE = v_sect_code
                               AND SCVTS_SCL_CODE = v_scl_code
                               AND SCVTS_COVT_CODE IN
                                       (SELECT IPU_COVT_CODE
                                          FROM GIN_INSURED_PROPERTY_UNDS
                                         WHERE IPU_CODE = v_new_ipu_code);
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            v_calc_group := 1;
                            v_calc_row := 1;
                    END;

            
            select TO_NUMBER (TO_CHAR (SYSDATE, 'RRRR'))  || gin_pil_code_seq.NEXTVAL into v_pil_code FROM DUAL;
                INSERT INTO gin_policy_insured_limits
                            (pil_code,
                             pil_ipu_code, pil_sect_code, pil_sect_sht_desc,
                             pil_desc,
                             pil_row_num,
                             pil_calc_group,
                             pil_limit_amt,
                             pil_prem_rate,
                             pil_prem_amt,
                             pil_rate_type, pil_rate_desc, pil_sect_type,
                             pil_original_prem_rate,
                             pil_multiplier_rate,
                             pil_multiplier_div_factor,
                             pil_annual_premium,
                             pil_rate_div_fact,
                             --PIL_DESC,
                             pil_compute,
                             pil_prd_type,
                             pil_dual_basis, pil_prem_accumulation,
                             pil_declaration_section,
                             pil_annual_actual_prem, pil_comment,
                             pil_free_limit,
                             pil_limit_prd,
                             pil_prorata_full,
                             pil_si_limit_type,
                             pil_si_rate,
                             pil_cover_type,
                             pil_min_premium,
                             pil_prr_max_rate, pil_prr_min_rate,
                             pil_indem_prd,
                             pil_indem_fstprd,
                             pil_indem_fstprd_pct,
                             pil_indem_remprd_pct,
                             pil_eml_pct,
                             pil_top_loc_rate,
                             pil_top_loc_div_fact,
                             pil_firstloss,
                             pil_firstloss_amt_pcnt,
                             pil_firstloss_value
                            )
                     VALUES (  v_pil_code ,
                             v_new_ipu_code, v_sect_code, v_sect_sht_desc,
                             NVL (v_rsk_sect_data (1).pil_desc, v_sect_desc),
                              NVL (NVL (v_calc_row, v_row), 1),
                              NVL (
                                            NVL (
                                                v_calc_group,
                                                v_rsk_sect_data (1).pil_calc_group),
                                            1),
                             NVL (v_rsk_sect_data (1).pil_limit_amt, v_limit),
                             NVL (v_rsk_sect_data (1).pil_prem_rate,
                                  v_prr_rate),
                             NVL (v_rsk_sect_data (1).pil_prem_amt, 0),
                             v_prr_rate_type, v_prr_rate_desc, v_sect_type,
                             v_prr_rate,
                             NVL (v_rsk_sect_data (1).pil_multiplier_rate,
                                  v_prr_multiplier_rate
                                 ),
                             NVL (v_rsk_sect_data (1).pil_multiplier_div_factor,
                                  v_prr_multplier_div_fact
                                 ),
                             0,
                             NVL (v_rsk_sect_data (1).pil_rate_div_fact,
                                  v_prr_division_factor
                                 ),
                             --v_type_desc,
                             NVL (v_rsk_sect_data (1).pil_compute, 'Y'),
                             v_rsk_sect_data (1).pil_prd_type,
                             NVL (v_rsk_sect_data (1).pil_dual_basis, 'N'), 0,
                             NVL (v_rsk_sect_data (1).pil_declaration_section,
                                  'N'
                                 ),
                             0, v_rsk_sect_data (1).pil_comment,
                             v_rsk_sect_data (1).pil_free_limit_amt,
                             v_rsk_sect_data (1).pil_limit_prd,
                             NVL(v_rsk_sect_data (1).pil_prorata_full,'F'),
                             v_rsk_sect_data (1).pil_si_limit_type,
                             v_rsk_sect_data (1).pil_si_rate,
                             v_rsk_sect_data (1).pil_cover_type,
                             NVL (v_rsk_sect_data (1).pil_min_premium,v_prr_prem_minimum_amt),
                             v_prrd_max_rate, v_prrd_min_rate,
                             v_rsk_sect_data (1).pil_indem_prd,
                             v_rsk_sect_data (1).pil_indem_fstprd,
                             v_rsk_sect_data (1).pil_indem_fstprd_pct,
                             v_rsk_sect_data (1).pil_indem_remprd_pct,
                             v_rsk_sect_data (1).pil_eml_pct,
                             v_rsk_sect_data (1).pil_top_loc_rate,
                             v_rsk_sect_data (1).pil_top_loc_div_fact,
                              v_rsk_sect_data (1).pil_firstloss,
                             v_rsk_sect_data (1).pil_firstloss_amt_pcnt,
                             v_rsk_sect_data (1).pil_firstloss_value
                            );
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error ('Error inserting risk sections..'||v_sect_sht_desc);
            END;
            
             begin
              pop_risk_sect_perils ( v_new_ipu_code,
                                              v_pil_code,
                                              v_sect_code
                                           );
             end;
             
        ELSE
            BEGIN
                SELECT pol_cur_code,
                       NVL (ipu_cover_days,
                            TO_NUMBER (  TO_DATE (ipu_wet, 'DD/MM/RRRR')
                                       - TO_DATE (pol_policy_cover_from,
                                                  'DD/MM/RRRR'
                                                 )
                                       + DECODE (NVL (pro_expiry_period, 'Y'),
                                                 'Y', 1,
                                                 0
                                                )
                                      )
                           ),
                       gin_travel_stp_pkg.get_alb (TRUNC (SYSDATE), clnt_dob),
                       pol_batch_no
                  INTO v_cur_code,
                       v_cover_days,
                       v_age,
                       v_batch_no
                  FROM gin_insured_property_unds,
                       gin_policies,
                       tqc_clients,
                       gin_products
                 WHERE ipu_pol_batch_no = pol_batch_no
                   AND pol_prp_code = clnt_code
                   AND pro_code = pol_pro_code
                   AND ipu_code = v_new_ipu_code;
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error (   'Error fetching risk details for '
                                || v_new_ipu_code
                               );
            END;

            v_rsk_travel_sect_data (1).pil_calc_group :=
                                            v_rsk_sect_data (1).pil_calc_group;
            v_rsk_travel_sect_data (1).pil_limit_amt :=
                                             v_rsk_sect_data (1).pil_limit_amt;
            v_rsk_travel_sect_data (1).pil_prem_rate :=
                                             v_rsk_sect_data (1).pil_prem_rate;
            v_rsk_travel_sect_data (1).pil_prem_amt :=
                                              v_rsk_sect_data (1).pil_prem_amt;
            v_rsk_travel_sect_data (1).pil_comment :=
                                               v_rsk_sect_data (1).pil_comment;
            v_rsk_travel_sect_data (1).pil_multiplier_rate :=
                                       v_rsk_sect_data (1).pil_multiplier_rate;
            v_rsk_travel_sect_data (1).pil_multiplier_div_factor :=
                                 v_rsk_sect_data (1).pil_multiplier_div_factor;
            v_rsk_travel_sect_data (1).pil_rate_div_fact :=
                                         v_rsk_sect_data (1).pil_rate_div_fact;
            v_rsk_travel_sect_data (1).pil_compute :=
                                               v_rsk_sect_data (1).pil_compute;
            v_rsk_travel_sect_data (1).pil_dual_basis :=
                                            v_rsk_sect_data (1).pil_dual_basis;
            v_rsk_travel_sect_data (1).pil_declaration_section :=
                                   v_rsk_sect_data (1).pil_declaration_section;
            v_rsk_travel_sect_data (1).pil_free_limit_amt :=
                                        v_rsk_sect_data (1).pil_free_limit_amt;
            v_rsk_travel_sect_data (1).pil_limit_prd :=
                                             v_rsk_sect_data (1).pil_limit_prd;
            v_rsk_travel_sect_data (1).pil_sect_sht_desc :=
                                         v_rsk_sect_data (1).pil_sect_sht_desc;

--RAISE_ERROR(v_rsk_travel_sect_data (1).PIL_SECT_SHT_DESC);
            BEGIN
                gin_travel_stp_pkg.process_stp_rsk_limits
                                                       (v_new_ipu_code,
                                                        v_scl_code,
                                                        v_bind_code,
                                                        v_sect_code,
                                                        v_limit,
                                                        NVL (v_row, 1),
                                                        'A',
                                                        v_cover_days,
                                                        v_age,
                                                        v_cur_code,
                                                        v_rsk_travel_sect_data
                                                       );
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error ('Error Updating Risk Sections...');
            END;

            BEGIN
                gin_travel_stp_pkg.update_travel_sect_si (v_batch_no);
            EXCEPTION
                WHEN OTHERS
                THEN
                    NULL;
            END;
        END IF;
    ELSE
        BEGIN
            IF v_pol_status = 'DC'
            THEN
                SELECT pil_declaration_section
                  INTO v_dec_section
                  FROM gin_policy_insured_limits
                 WHERE pil_code = v_rsk_sect_data (1).pil_code;

                IF v_dec_section <> 'Y'
                THEN
                    raise_error ('You cannot edit a non declaration section...');
                END IF;
            END IF;

                       --RAISE_ERROR('RATE TYPE '||v_prr_rate_type||' NEW IPU CODE '||v_new_ipu_code||' PIL CODE'||v_rsk_sect_data (1).pil_code);
            --RAISE_ERROR('FREE LIMIT '||v_new_ipu_code||';'||v_rsk_sect_data (1).pil_prem_rate||';'||v_prr_rate);
            UPDATE gin_policy_insured_limits
               SET
                   --PIL_SECT_CODE=v_sect_code, PIL_SECT_SHT_DESC=v_sect_sht_desc,
                   pil_limit_amt =
                              NVL (v_rsk_sect_data (1).pil_limit_amt, v_limit),
                   pil_prem_rate =
                           NVL (v_rsk_sect_data (1).pil_prem_rate, v_prr_rate),
                   pil_sect_type =
                        NVL (v_rsk_sect_data (1).pil_sect_type, pil_sect_type),
                   pil_min_premium =
                      NVL (v_rsk_sect_data (1).pil_min_premium,
                           v_prr_prem_minimum_amt
                          ),
                   pil_rate_type =
                        NVL (v_rsk_sect_data (1).pil_rate_type, pil_rate_type),
                   pil_rate_desc = v_prr_rate_desc,
                   pil_rate_div_fact =
                      NVL (v_rsk_sect_data (1).pil_rate_div_fact,
                           v_prr_division_factor
                          ),
                   pil_multiplier_rate =
                      NVL (v_rsk_sect_data (1).pil_multiplier_rate,
                           v_prr_multiplier_rate
                          ),
                   pil_multiplier_div_factor =
                      NVL (v_rsk_sect_data (1).pil_multiplier_div_factor,
                           v_prr_multplier_div_fact
                          ),
                   pil_row_num = NVL (v_row, pil_row_num),
                   pil_compute = NVL (v_rsk_sect_data (1).pil_compute, 'Y'),
                   pil_desc = NVL (v_rsk_sect_data (1).pil_desc, v_sect_desc),
                   pil_dual_basis =
                                 NVL (v_rsk_sect_data (1).pil_dual_basis, 'N'),
                   pil_calc_group =
                                   NVL (v_rsk_sect_data (1).pil_calc_group, 1),
                   pil_prem_amt = (v_rsk_sect_data (1).pil_prem_amt),
                   pil_comment = v_rsk_sect_data (1).pil_comment,
                   pil_declaration_section =
                        NVL (v_rsk_sect_data (1).pil_declaration_section, 'N'),
                   pil_free_limit_amt = v_rsk_sect_data (1).pil_free_limit_amt,
                   pil_free_limit = v_rsk_sect_data (1).pil_free_limit_amt,
                   pil_limit_prd = v_rsk_sect_data (1).pil_limit_prd,
                   pil_prorata_full =
                      NVL (v_rsk_sect_data (1).pil_prorata_full,
                           pil_prorata_full
                          ),
                   pil_si_limit_type =
                      NVL (v_rsk_sect_data (1).pil_si_limit_type,
                           pil_si_limit_type
                          ),
                   pil_si_rate =
                            NVL (v_rsk_sect_data (1).pil_si_rate, pil_si_rate),
                   pil_cover_type =
                      NVL (v_rsk_sect_data (1).pil_cover_type, pil_cover_type),
                   pil_prd_type = v_rsk_sect_data (1).pil_prd_type,
                   pil_indem_prd = v_rsk_sect_data (1).pil_indem_prd,
                   pil_indem_fstprd = v_rsk_sect_data (1).pil_indem_fstprd,
                   pil_indem_fstprd_pct =
                                      v_rsk_sect_data (1).pil_indem_fstprd_pct,
                   pil_indem_remprd_pct =
                                      v_rsk_sect_data (1).pil_indem_remprd_pct,
                   pil_eml_pct = v_rsk_sect_data (1).pil_eml_pct,
                   pil_top_loc_rate = v_rsk_sect_data (1).pil_top_loc_rate,
                   pil_top_loc_div_fact =
                                      v_rsk_sect_data (1).pil_top_loc_div_fact,
                   pil_firstloss = v_rsk_sect_data (1).pil_firstloss,
                   pil_firstloss_amt_pcnt =
                           v_rsk_sect_data (1).pil_firstloss_amt_pcnt,
                       pil_firstloss_value =
                           v_rsk_sect_data (1).pil_firstloss_value
             WHERE pil_ipu_code = v_new_ipu_code
               AND pil_code = v_rsk_sect_data (1).pil_code;
        EXCEPTION
            WHEN OTHERS
            THEN
               raise_error ('Error updating risk sections..');
        END;
    END IF;

    BEGIN
        UPDATE gin_policies
           SET pol_prem_computed = 'N'
         WHERE pol_batch_no = (SELECT ipu_pol_batch_no
                                 FROM gin_insured_property_unds
                                WHERE ipu_code = v_new_ipu_code);
    EXCEPTION
        WHEN OTHERS
        THEN
            raise_error ('Error updating policy premium status to changed');
    END;
END;

```