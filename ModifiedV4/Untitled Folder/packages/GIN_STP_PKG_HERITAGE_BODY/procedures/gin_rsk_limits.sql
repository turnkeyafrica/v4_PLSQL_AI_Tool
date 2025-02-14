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