PROCEDURE pop_risk_sect_perils (
      v_ipu_code    IN   NUMBER,
      v_pil_code    IN   NUMBER,
      v_sect_code   IN   NUMBER
   )
   IS
      v_bind_type   VARCHAR2 (1);
      v_scl_code NUMBER;
      v_bind_code  NUMBER;
      v_cvt_code NUMBER;
      v_batch_no number;
   BEGIN
        BEGIN
        SELECT ipu_sec_scl_code, ipu_bind_code, ipu_covt_code,ipu_pol_batch_no
        INTO  v_scl_code,v_bind_code,v_cvt_code,v_batch_no
        FROM GIN_INSURED_PROPERTY_UNDS 
        WHERE IPU_CODE=v_ipu_code;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE_ERROR('Error at risk dtls selection');
        END;