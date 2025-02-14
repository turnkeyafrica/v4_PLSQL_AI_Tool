PROCEDURE gin_rsk_limits_stp (
      v_new_ipu_code   IN   NUMBER,
      v_scl_code       IN   NUMBER,
      v_bind_code      IN   NUMBER,
      v_sect_code      IN   NUMBER,
      v_covt_code      IN   NUMBER,
      v_row            IN   NUMBER,
      v_add_edit       IN   VARCHAR2,
      v_renewal        IN   VARCHAR2,
      v_ncd_level      IN   NUMBER,
      v_limit      IN   NUMBER DEFAULT NULL
   )
   IS
      v_rsk_sect_data            web_sect_tab;
      sect_cursor                sys_refcursor;
      v_sect_sht_desc            gin_sections.sect_sht_desc%TYPE;
      v_sec_code                 gin_sections.sect_code%TYPE;
      v_sect_desc                gin_sections.sect_desc%TYPE;
      v_sect_type                gin_sections.sect_type%TYPE;
      v_type_desc                VARCHAR2 (25);
      v_prr_rate_type            gin_premium_rates.prr_rate_type%TYPE;
      v_prr_rate                 gin_premium_rates.prr_rate%TYPE;
      v_terr_description         VARCHAR2 (5);
      v_prr_prem_minimum_amt     gin_premium_rates.prr_prem_minimum_amt%TYPE;
      v_prr_multiplier_rate      gin_premium_rates.prr_multiplier_rate%TYPE;
      v_prr_division_factor      gin_premium_rates.prr_division_factor%TYPE;
      v_prr_multplier_div_fact   gin_premium_rates.prr_multplier_div_fact%TYPE;
      v_prr_rate_desc            gin_premium_rates.prr_rate_desc%TYPE;
      v_prr_free_limit           gin_premium_rates.prr_free_limit%TYPE;
      v_sec_declaration          gin_subcl_sections.sec_declaration%TYPE;
      v_scvts_order              gin_subcl_covt_sections.scvts_order%TYPE;
      v_prr_prorated_full        gin_premium_rates.prr_prorated_full%TYPE;
      v_prr_si_limit_type        gin_premium_rates.prr_si_limit_type%TYPE;
      v_prr_si_rate              gin_premium_rates.prr_si_rate%TYPE;
   BEGIN
--   RAISE_ERROR(v_scl_code||';;v_sect_code'||v_sect_code||'v_covt_code'||v_covt_code||'v_bind_code'||v_bind_code||'v_new_ipu_code'||v_new_ipu_code);
      sect_cursor :=
         gis_web_pkg.get_sections (v_scl_code,
                                   v_covt_code,
                                   v_bind_code,
                                   v_sect_code,
                                   v_new_ipu_code,
                                   v_ncd_level
                                  );

      LOOP
         EXIT WHEN sect_cursor%NOTFOUND;

         FETCH sect_cursor
          INTO v_sect_sht_desc, v_sec_code, v_sect_desc, v_sect_type,
               v_type_desc, v_prr_rate_type, v_prr_rate, v_terr_description,
               v_prr_prem_minimum_amt, v_prr_multiplier_rate,
               v_prr_division_factor, v_prr_multplier_div_fact,
               v_prr_rate_desc, v_prr_free_limit, v_sec_declaration,
               v_scvts_order, v_prr_prorated_full, v_prr_si_limit_type,
               v_prr_si_rate;

--RAISE_ERROR('v_sect_sht_desc ==== '||v_sect_sht_desc);
         v_rsk_sect_data := web_sect_tab ();
         v_rsk_sect_data.EXTEND (1);
         v_rsk_sect_data (1) :=
            web_sect_rec (NULL,
                          v_new_ipu_code,
                          v_sect_code,
                          v_sect_sht_desc,
                          NULL,
                          v_limit,--NULL,
                          v_prr_rate,
                          NULL,
                          v_prr_rate_type,
                          v_sect_type,
                          v_prr_prem_minimum_amt,
                          NULL,
                          v_prr_multiplier_rate,
                          v_prr_multplier_div_fact,
                          NULL,
                          v_prr_division_factor,
                          'Y',
                          'N',
                          0,
                          v_sec_declaration,
                          v_prr_free_limit,
                          NULL,
                          NULL,
                          v_prr_prorated_full,
                          NULL,
                          v_sect_desc,
                          v_prr_si_limit_type,
                          v_prr_si_rate,
                          NULL,
                          NULL,
                          NULL,
                          NULL,
                          NULL,
                          NULL,
                          NULL,
                          NULL,
                          NULL
                         );
      --RAISE_ERROR(v_rsk_sect_data.COUNT);
      END LOOP;

      IF v_renewal = 'RN'
      THEN
         gin_ren_rsk_limits (v_new_ipu_code,
                             v_scl_code,
                             v_bind_code,
                             v_sect_code,
                             NULL,
                             v_row,
                             'A',
                             v_rsk_sect_data
                            );
      ELSE
         gin_rsk_limits (v_new_ipu_code,
                         v_scl_code,
                         v_bind_code,
                         v_sect_code,
                        NULL,
                         v_row,
                         'A',
                         v_rsk_sect_data
                        );
      END IF;
   END;