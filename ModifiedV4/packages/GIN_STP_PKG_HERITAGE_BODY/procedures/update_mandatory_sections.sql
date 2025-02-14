PROCEDURE update_mandatory_sections (
      v_new_ipu_code   IN   NUMBER,
      v_scl_code       IN   NUMBER,
      v_bind_code      IN   NUMBER,
      v_covt_code      IN   NUMBER,
      v_limit        IN   NUMBER,
      v_cashback_only IN VARCHAR2 DEFAULT 'N'
   )
   IS
      CURSOR mandatory_sections
      IS
         SELECT DISTINCT sect_code
                    FROM gin_premium_rates,
                         gin_sections,
                         gin_subcl_sections,
                         gin_subcl_covt_sections
                   WHERE prr_sect_code = sect_code
                     AND sec_sect_code = prr_sect_code
                     AND sec_scl_code = prr_scl_code
                     AND prr_scl_code = v_scl_code
                     AND prr_bind_code = v_bind_code
                     AND scvts_scl_code = v_scl_code
                     AND scvts_covt_code = v_covt_code
                     AND sect_code = scvts_sect_code
                     AND NVL (scvts_mandatory, 'N') = 'Y';
                     
   CURSOR cashback_sections
                     is
                     SELECT DISTINCT sect_code
                    FROM gin_premium_rates,
                         gin_sections,
                         gin_subcl_sections,
                         gin_subcl_covt_sections
                   WHERE prr_sect_code = sect_code
                     AND sec_sect_code = prr_sect_code
                     AND sec_scl_code = prr_scl_code
                     AND prr_scl_code = v_scl_code
                     AND prr_bind_code = v_bind_code
                     AND scvts_scl_code = v_scl_code
                     AND scvts_covt_code = v_covt_code
                     AND sect_code = scvts_sect_code
                     AND NVL (sect_type, 'SI') = 'CB';
                     
   v_ipu_cashback_appl varchar2(5);
   v_ipu_cashback_level     number;  
   v_row number;
   
   BEGIN
    BEGIN
           SELECT NVL(ipu_cashback_appl,'N'), NVL(ipu_cashback_leveL,0) 
           INTO v_ipu_cashback_appl,v_ipu_cashback_level
           FROM GIN_INSURED_PROPERTY_UNDS 
           WHERE IPU_CODE=  v_new_ipu_code;
         END;
         
           BEGIN
            SELECT COUNT(0)+1
            INTO v_row
            FROM  GIN_POLICY_INSURED_LIMITS
            WHERE PIL_IPU_CODE=v_new_ipu_code;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_row :=1;
            END;
            
    IF v_cashback_only ='N' THEN
      FOR s IN mandatory_sections
      LOOP
         gin_rsk_limits_stp (v_new_ipu_code,
                             v_scl_code,
                             v_bind_code,
                             s.sect_code,
                             v_covt_code,
                             NULL,
                             'A',
                             'UW',
                             NULL,
                             v_limit
                            );
      END LOOP;
--      IF v_ipu_cashback_appl = 'Y' AND v_ipu_cashback_level !=0 THEN
--         FOR s IN cashback_sections  LOOP
--             gin_rsk_limits_stp (v_new_ipu_code,
--                                 v_scl_code,
--                                 v_bind_code,
--                                 s.sect_code,
--                                 v_covt_code,
--                                 v_row,
--                                 'A',
--                                 'UW',
--                                 NULL,
--                                 v_limit
--                                );
--          END LOOP;
--     END IF;
    ELSE 
     IF v_ipu_cashback_appl = 'Y' AND v_ipu_cashback_level !=0 THEN
         FOR s IN cashback_sections  LOOP
             gin_rsk_limits_stp (v_new_ipu_code,
                                 v_scl_code,
                                 v_bind_code,
                                 s.sect_code,
                                 v_covt_code,
                                 v_row,
                                 'A',
                                 'UW',
                                 NULL,
                                 v_limit
                                );
          END LOOP;
     END IF;
    END IF;
   END;