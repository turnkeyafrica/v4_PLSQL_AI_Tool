PROCEDURE gin_rsk_stp_limits (
      v_new_ipu_code    IN   NUMBER,
      v_scl_code        IN   NUMBER,
      v_bind_code       IN   NUMBER,
      v_row             IN   NUMBER,
      v_add_edit        IN   VARCHAR2,
      v_covt_code       IN   NUMBER,
      v_rsk_sect_data   IN   web_sect_tab,
      v_dbcode          IN   NUMBER
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
      v_batch_no                 NUMBER;
      v_count                    NUMBER        := 0;
      v_dec_section              VARCHAR2 (5);

      CURSOR pil_cur (
         v_db_code     IN   NUMBER,
         vrange        IN   NUMBER,
         vfreg         IN   VARCHAR2,
         v_sect_code        NUMBER
      )
      IS
         SELECT sect_sht_desc, sect_desc, sect_type, type_desc,
                prr_rate_type, prr_rate, terr_description,
                prr_prem_minimum_amt, prr_multiplier_rate,
                prr_division_factor, prr_multplier_div_fact, prr_rate_desc,
                prr_max_rate, prr_min_rate, prr_prorated_full,
                prr_free_limit, sect_code, prr_si_limit_type
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
                                 prr_max_rate, prr_min_rate,
                                 prr_prorated_full, prr_free_limit,
                                 prr_si_limit_type
                            FROM gin_premium_rates, gin_sections
                           WHERE prr_sect_code = sect_code
                             AND prr_sect_code = v_sect_code
                             AND sect_sht_desc != 'NCD'
                             AND sect_type NOT IN
                                    ('GR', 'GD', 'OM', 'OD', 'VD', 'VL', 'LD',
                                     'L', 'UD', 'VU', 'NA', 'DL', 'DL', 'MM',
                                     'MD', 'ND', 'CL', 'NC', 'VH', 'TL')
                             AND prr_db_code = v_db_code
                             AND NVL (prr_rate_freq_type, 'A') =
                                                              NVL (vfreg, 'A')
                             AND prr_rate_type = 'FXD'
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
                                 prr_max_rate, prr_min_rate,
                                 prr_prorated_full, prr_free_limit,
                                 prr_si_limit_type
                            FROM gin_premium_rates, gin_sections
                           WHERE prr_sect_code = sect_code
                             AND prr_db_code = v_db_code
                             AND prr_sect_code = v_sect_code
                             AND sect_type NOT IN
                                    ('GR', 'GD', 'OM', 'OD', 'VD', 'VL', 'LD',
                                     'L', 'UD', 'VU', 'NA', 'DL', 'DL', 'MM',
                                     'MD', 'ND', 'CL', 'NC', 'VH', 'TL')
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
                                 prr_max_rate, prr_min_rate,
                                 prr_prorated_full, prr_free_limit,
                                 prr_si_limit_type
                            FROM gin_premium_rates, gin_sections
                           WHERE prr_sect_code = sect_code
                             AND prr_db_code = v_db_code
                             AND prr_sect_code = v_sect_code
                             AND sect_type != 'ND'
                             AND sect_type NOT IN
                                    ('GR', 'GD', 'OM', 'OD', 'VD', 'VL', 'LD',
                                     'L', 'UD', 'VU', 'NA', 'DL', 'DL', 'MM',
                                     'MD', 'ND', 'CL', 'NC', 'VH', 'TL')
                             AND prr_rate_type = 'ARG'
                 UNION
                 SELECT DISTINCT sect_sht_desc, sect_code,
                                 sect_desc sect_desc, sect_type,
                                 DECODE (sect_type, 'ND', 'NCD') type_desc,
                                 prr_rate_type, prr_rate, prr_rate rate,
                                 '0' terr_description, prr_prem_minimum_amt,
                                 prr_multiplier_rate, prr_division_factor,
                                 prr_multplier_div_fact, prr_rate_desc,
                                 prr_max_rate, prr_min_rate,
                                 prr_prorated_full, prr_free_limit,
                                 prr_si_limit_type
                            FROM gin_premium_rates, gin_sections
                           WHERE prr_sect_code = sect_code
                             AND prr_sect_code = v_sect_code
                             AND prr_db_code = v_db_code
                             AND sect_type NOT IN
                                    ('GR', 'GD', 'OM', 'OD', 'VD', 'VL', 'LD',
                                     'L', 'UD', 'VU', 'NA', 'DL', 'DL', 'MM',
                                     'MD', 'ND', 'CL', 'NC', 'VH', 'TL')
                             AND sect_type = 'ND');

      v_freq                     VARCHAR2 (2);
      v_range                    NUMBER;
      v_alb_required             VARCHAR2 (2);
      v_pol_status               VARCHAR2 (10);
      v_prr_prorated_full        VARCHAR2 (10);
      v_prr_free_limit           NUMBER;
      v_sect_code                NUMBER;
      v_prr_si_limit_type        VARCHAR2 (10);
   -- v_dbcode                   NUMBER;
   BEGIN
--      BEGIN
--         SELECT db_code
--           INTO v_dbcode
--           FROM gin_binder_details
--          WHERE db_bind_code = v_bind_code
--            AND db_scl_code = v_scl_code
--            AND db_covt_code = v_covt_code;

      --         IF v_dbcode IS NULL
--         THEN
--            raise_error ('Binder Details have not been set up');
--         END IF;
--      EXCEPTION
--         WHEN OTHERS
--         THEN
--            raise_error ('Error getting the premium rates for 1st section..');
--      END;