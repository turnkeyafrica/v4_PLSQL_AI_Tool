```sql
PROCEDURE gin_rsk_stp_limits090216 (
    v_new_ipu_code    IN   NUMBER,
    v_scl_code        IN   NUMBER,
    v_bind_code       IN   NUMBER,
    v_row             IN   NUMBER,
    v_add_edit        IN   VARCHAR2,
    v_covt_code       IN   NUMBER,
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
    v_batch_no                 NUMBER;
    v_count                    NUMBER := 0;
    v_dec_section              VARCHAR2 (5);
    
    CURSOR pil_cur (
        v_bind_code   IN   NUMBER,
        v_scl_code    IN   NUMBER,
        vrange      IN   NUMBER,
        vfreg       IN   VARCHAR2,
        v_covt_code IN   NUMBER
    )
    IS
        SELECT sect_sht_desc, sect_desc, sect_type, type_desc,
                prr_rate_type, prr_rate, terr_description,
                prr_prem_minimum_amt, prr_multiplier_rate,
                prr_division_factor, prr_multplier_div_fact, prr_rate_desc,
                prr_max_rate, prr_min_rate,prr_prorated_full,prr_free_limit,
                sect_code    ,prr_si_limit_type            
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
                                 prr_max_rate, prr_min_rate,prr_prorated_full
                                 ,prr_free_limit,prr_si_limit_type
                             FROM gin_premium_rates,
                            gin_sections,
                            gin_subcl_sections,
                            gin_subcl_covt_sections,
                         gin_binders,
                         gin_binder_details
                      WHERE prr_sect_code = sect_code
                        AND sec_sect_code = prr_sect_code
                        AND sec_scl_code = prr_scl_code
                        AND sect_sht_desc != 'NCD'
                        AND bind_code = db_bind_code     
                         AND sect_type NOT IN('GR','GD','OM','OD','VD',
                           'VL','LD','L','UD','VU','NA','DL','DL','MM','MD','ND','CL','NC','VH')
                     AND bind_type = 'Q'
                     AND db_scl_code = prr_scl_code
                     AND db_covt_code = scvts_covt_code
                     and  db_covt_code =v_covt_code
                     AND prr_scl_code = v_scl_code
                     AND prr_bind_code = v_bind_code
                     AND scvts_scl_code = v_scl_code
                     AND sect_code = scvts_sect_code
                     AND NVL (prr_rate_freq_type, 'A') = NVL (vfreg,'A')
                      AND prr_rate_type = 'FXD'
                     AND NVL (vrange, 0) BETWEEN NVL (prr_range_from, 0)
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
                                 prr_max_rate, prr_min_rate,prr_prorated_full
                                 ,prr_free_limit,prr_si_limit_type
                            FROM gin_premium_rates, gin_sections,
                                                 gin_binders,
                                                 gin_binder_details
                           WHERE prr_sect_code = sect_code
                             AND prr_bind_code = v_bind_code
                             AND prr_scl_code = v_scl_code
                                 and  db_covt_code =v_covt_code
                             AND bind_code = db_bind_code
                             
                     AND bind_type = 'Q'
                     AND db_scl_code = prr_scl_code
                     AND sect_type NOT IN('GR','GD','OM','OD','VD',
                           'VL','LD','L','UD','VU','NA','DL','DL','MM','MD','ND','CL','NC','VH')
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
                                 prr_max_rate, prr_min_rate,prr_prorated_full
                                 ,prr_free_limit,prr_si_limit_type
                            FROM gin_premium_rates, gin_sections,
                                                 gin_binders,
                                                 gin_binder_details
                           WHERE prr_sect_code = sect_code
                             AND prr_bind_code = v_bind_code
                             AND prr_scl_code = v_scl_code
                              AND bind_type = 'Q'
                             AND db_scl_code = prr_scl_code
                              AND bind_code = db_bind_code
                                  and  db_covt_code =v_covt_code
                             AND sect_type != 'ND'
                                AND sect_type NOT IN('GR','GD','OM','OD','VD',
                           'VL','LD','L','UD','VU','NA','DL','DL','MM','MD','ND','CL','NC','VH')
                             AND prr_rate_type = 'ARG'
                 UNION
                 SELECT DISTINCT sect_sht_desc, sect_code,
                                 sect_desc sect_desc, sect_type,
                                 DECODE (sect_type, 'ND', 'NCD') type_desc,
                                 prr_rate_type, prr_rate, prr_rate rate,
                                 '0' terr_description, prr_prem_minimum_amt,
                                 prr_multiplier_rate, prr_division_factor,
                                 prr_multplier_div_fact, prr_rate_desc,
                                 prr_max_rate, prr_min_rate,prr_prorated_full
                                 ,prr_free_limit,prr_si_limit_type
                            FROM gin_premium_rates, gin_sections,
                                                 gin_binders,
                                                 gin_binder_details
                           WHERE prr_sect_code = sect_code
                             AND prr_bind_code = v_bind_code
                             AND prr_scl_code = v_scl_code
                             AND bind_type = 'Q'
                             AND sect_type NOT IN('GR','GD','OM','OD','VD',
                           'VL','LD','L','UD','VU','NA','DL','DL','MM','MD','ND','CL','NC','VH')
                             AND db_scl_code = prr_scl_code
                             AND bind_code = db_bind_code
                             AND  db_covt_code =v_covt_code
                             AND sect_type = 'ND');

    v_freq                     VARCHAR2 (2);
    v_range                    NUMBER;
    v_alb_required             VARCHAR2 (2);
    v_pol_status               VARCHAR2 (10);
    v_prr_prorated_full  VARCHAR2 (10);
    v_prr_free_limit number;
    v_sect_code  NUMBER;
    v_prr_si_limit_type VARCHAR2 (10);
BEGIN
    BEGIN
        OPEN pil_cur ( v_bind_code, v_scl_code, v_range, v_freq,v_covt_code);
        LOOP
            EXIT WHEN pil_cur%NOTFOUND;
            
            FETCH pil_cur
                INTO v_sect_sht_desc, v_sect_desc, v_sect_type, v_type_desc,
                     v_prr_rate_type, v_prr_rate, v_terr_description,
                     v_prr_prem_minimum_amt, v_prr_multiplier_rate,
                     v_prr_division_factor, v_prr_multplier_div_fact,
                     v_prr_rate_desc, v_prrd_max_rate, v_prrd_min_rate,
                     v_prr_prorated_full,v_prr_free_limit,v_sect_code,
                     v_prr_si_limit_type;
        END LOOP;
        CLOSE pil_cur;
    EXCEPTION
        WHEN OTHERS
        THEN
            raise_error
                      ('Error getting the premium rates for 1st section..'  );
    END;
    
    FOR p IN pil_cur( v_bind_code, v_scl_code, v_range, v_freq,v_covt_code) LOOP  
        IF NVL (v_add_edit, 'A') = 'A'
        THEN
            BEGIN
               IF v_prr_rate_type IS NULL
               THEN
                  raise_error
                        ('Error getting Rate Type...Please specify rate type..2..');
               END IF;

               IF v_pol_status = 'DC'
               THEN
                  raise_error ('You cannot add a section to a declaration...');
               END IF;
               
               INSERT INTO gin_policy_insured_limits
                           (pil_code,
                            pil_ipu_code, 
                            pil_sect_code, 
                            pil_sect_sht_desc,
                            pil_desc,
                            pil_row_num,
                            pil_calc_group,
                            pil_limit_amt,
                            pil_prem_rate,
                            pil_rate_type, 
                            pil_rate_desc, 
                            pil_sect_type,
                            pil_original_prem_rate,
                            pil_multiplier_rate,
                            pil_multiplier_div_factor,
                            pil_annual_premium,
                            pil_rate_div_fact,
                            pil_compute,
                            pil_prem_accumulation,
                            pil_annual_actual_prem,
                            pil_free_limit,
                            pil_limit_prd,
                            pil_prorata_full,
                            pil_si_limit_type,
                            pil_min_premium,
                            pil_prr_max_rate, 
                            pil_prr_min_rate
                           )
                    VALUES (   TO_NUMBER (TO_CHAR (SYSDATE, 'RRRR'))
                            || gin_pil_code_seq.NEXTVAL,
                            v_new_ipu_code, 
                            v_sect_code,
                            v_sect_sht_desc,
                            v_sect_desc,
                            NVL(v_rsk_sect_data(1).pil_row_num,1),
                             NVL(v_rsk_sect_data(1).pil_calc_group,1),
                            v_rsk_sect_data(1).pil_limit_amt,
                            v_prr_rate,
                            v_prr_rate_type, 
                            v_prr_rate_desc, 
                            v_sect_type,
                            v_prr_rate,
                            v_prr_multiplier_rate,
                            v_prr_multplier_div_fact,
                            0,
                            v_prr_division_factor,
                            'Y',
                             0,
                            0, 
                            v_prr_free_limit,
                            0,
                            v_prr_prorated_full,
                            v_prr_si_limit_type,
                            v_prr_prem_minimum_amt,
                            v_prrd_max_rate, 
                            v_prrd_min_rate
                           );
            EXCEPTION
               WHEN OTHERS
               THEN
                  raise_error ('Error inserting risk sections..');
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
    END LOOP;
END;
```