PROCEDURE update_cert_details (
      v_ipu_code       IN   NUMBER,
      v_tonnage        IN   NUMBER,
      v_carry_cap      IN   NUMBER DEFAULT NULL,
      v_pol_batch_no   IN   NUMBER DEFAULT NULL
   )
   IS
      v_polc_pll      NUMBER;
      v_ct_sht_desc   VARCHAR2 (30);
      v_count1        NUMBER;
      v_scl_code      NUMBER;
      v_covt_code     NUMBER;
      v_ct_code       NUMBER;
   BEGIN
       --        BEGIN
--
--
--            SELECT PCQ_CT_SHT_DESC
--            INTO v_ct_sht_desc
--            FROM GIN_PRINT_CERT_QUEUE
--            WHERE PCQ_IPU_CODE = v_ipu_code
--            AND PCQ_CODE IN (SELECT MAX(PCQ_CODE) FROM GIN_PRINT_CERT_QUEUE WHERE PCQ_IPU_CODE = v_ipu_code);
--        EXCEPTION
--        WHEN OTHERS THEN
--              SELECT POLC_CT_SHT_DESC INTO v_ct_sht_desc
--              FROM  GIN_POLICY_CERTS
--              WHERE POLC_POL_BATCH_NO=v_pol_batch_no;
--
--        END;