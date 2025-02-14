FUNCTION checkProductExpired (
       v_pol_batch_no      IN   NUMBER
    )
    RETURN VARCHAR2
    IS
        v_pro_wet_date   DATE;
        v_pol_status     VARCHAR2 (10);
        v_value          VARCHAR2 (5) := 'N';
        v_cnt            NUMBER;
        
    BEGIN
        BEGIN
            SELECT COUNT (1)
              INTO v_cnt
              FROM gin_ren_policies,
                   gin_products,
                   gin_ren_insured_property_unds,
                   gin_sub_classes
             WHERE     pol_pro_code = pro_code
                   AND IPU_POL_BATCH_NO = POL_BATCH_NO
                   AND IPU_SEC_SCL_CODE = SCL_CODE
                   AND scl_wet < TRUNC (SYSDATE)
                   AND pol_batch_no = v_pol_batch_no;
        EXCEPTION
            WHEN OTHERS
            THEN
                raise_error (SQLERRM);
        END;