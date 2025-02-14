PROCEDURE pop_sbu_dtls (
      v_pol_batch_no    IN   NUMBER,
      v_pol_unit_code        IN   VARCHAR2,
      v_pol_location_code      IN   VARCHAR2,
      v_pol_add_edit  IN   VARCHAR2
   )
   IS
    v_pdl_code number;  
    v_cnt  number;  
   BEGIN
   
          SELECT    TO_NUMBER (TO_CHAR (SYSDATE, 'YYYY'))
                   || gin_pdl_code_seq.NEXTVAL
              INTO v_pdl_code
              FROM DUAL;
   
     IF NVL(v_pol_add_edit,'E')='A' THEN

         BEGIN

            INSERT INTO gin_policy_sbu_dtls
                        (PDL_CODE, PDL_POL_BATCH_NO, PDL_UNIT_CODE, PDL_LOCATION_CODE, PDL_PREPARED_DATE
                        )
                 VALUES (v_pdl_code,v_pol_batch_no,v_pol_unit_code, v_pol_location_code, TRUNC (SYSDATE)
                        );
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               NULL;
            WHEN OTHERS
            THEN
               raise_error ('Error Creating Policy Other Details Record..');
         END;