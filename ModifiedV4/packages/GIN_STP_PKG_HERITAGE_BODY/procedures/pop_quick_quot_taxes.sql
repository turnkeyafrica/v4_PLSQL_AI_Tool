PROCEDURE pop_quick_quot_taxes (v_qqtn_code IN NUMBER, v_prod_code IN NUMBER,v_con_type IN VARCHAR2 DEFAULT NULL)
   IS
      x   NUMBER := 0;

      CURSOR taxes
      IS
         SELECT *
           FROM gin_taxes_types_view
          WHERE (   scl_code IS NULL
                 OR scl_code IN (SELECT clp_scl_code
                                   FROM gin_product_sub_classes
                                  WHERE clp_pro_code = v_prod_code)
                )
            -- AND trnt_mandatory = 'Y'
            --AND trnt_type IN ('PHFUND', 'SD', 'UTL', 'EX','MPSD','MSD','COPHFUND')
            AND trnt_type IN
                   ('UTX', 'SD', 'UTL', 'EX', 'PHFUND','MPSD','MSD', 'ROAD', 'HEALTH',
                    'CERTCHG', 'MOTORTX')
            AND taxr_trnt_code NOT IN (SELECT qqtt_trac_trnt_code
                                         FROM gin_quick_quot_taxes
                                        WHERE qqtt_qqtn_code = v_qqtn_code)
            AND NVL (trnt_apply_nb, 'N') = 'Y'
            AND trnt_code NOT IN (SELECT petx_trnt_code
                                    FROM gin_product_excluded_taxes
                                   WHERE petx_pro_code = v_prod_code);
   BEGIN
--      RAISE_ERROR(v_qqtn_code ||'='|| v_prod_code);
      FOR txs IN taxes
      LOOP
         x := NVL (x, 0) + 1;
--        IF txs.trnt_type='MSD' THEN
--        RAISE_ERROR(v_qqtn_code ||'='|| v_prod_code);
--       END IF;
         INSERT INTO gin_quick_quot_taxes
                     (qqtt_code, qqtt_trac_trnt_code,
                      qqtt_rate, qqtt_rate_type, qqtt_trnt_renewal_endos,
                      qqtt_taxr_code, qqtt_qqtn_code, qqtt_tax_type,
                      qqtt_tl_lvl_code, qqtt_risk_prod_level
                     )
              VALUES (gin_qqtt_code_seq.NEXTVAL, txs.trnt_code,
                      txs.taxr_rate, txs.taxr_rate_type, NULL,
                      txs.taxr_code, v_qqtn_code, 'UTX',
                      'UP', 'P'
                     );
      END LOOP;
   
     IF NVL(TRIM(v_con_type),'XYZ')='SEA' THEN
         DELETE gin_quick_quot_taxes WHERE QQTT_TRAC_TRNT_CODE ='SD'
        AND qqtt_qqtn_code=v_qqtn_code; 
        UPDATE gin_quick_quot_taxes SET qqtt_tl_lvl_code ='SI' 
        WHERE qqtt_trac_trnt_code ='MPSD'
         AND qqtt_qqtn_code=v_qqtn_code;
     END IF; 
        
     IF NVL(TRIM(v_con_type),'XYZ')='AIR' THEN
        DELETE gin_quick_quot_taxes WHERE QQTT_TRAC_TRNT_CODE ='MPSD'
        AND qqtt_qqtn_code=v_qqtn_code;
     END IF;
     
    
   END;