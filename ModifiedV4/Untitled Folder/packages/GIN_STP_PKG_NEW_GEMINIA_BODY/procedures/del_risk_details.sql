PROCEDURE del_risk_details (v_pol_batch_no   IN     NUMBER,
                                v_ipu_code       IN     NUMBER,
                                v_pro_code              NUMBER,
                                v_error             OUT VARCHAR2)
    IS
        --v_successful NUMBER;
        --v_authorised VARCHAR2(2);
        v_auths           VARCHAR2 (2);
        v_err_pos         VARCHAR2 (75);
        v_errmsg          VARCHAR2 (600);
        v_cert_ipu_code   NUMBER;
        v_cnt             NUMBER;
        v_polin_code      NUMBER;
        v_property_id     VARCHAR2 (100);
        v_claim_cnt       NUMBER;
    BEGIN
        BEGIN
            SELECT pol_authosrised, ipu_polin_code, ipu_property_id
              INTO v_auths, v_polin_code, v_property_id
              FROM gin_policies, gin_insured_property_unds
             WHERE     ipu_pol_batch_no = pol_batch_no
                   AND pol_batch_no = v_pol_batch_no
                   AND ipu_code = v_ipu_code;
        EXCEPTION
            WHEN OTHERS
            THEN
                v_error := 'THE TRANSACTION COULD NOT BE FOUND.....';
                RETURN;
        /*raise_application_error
                              (-20001,
                               'THE TRANSACTION COULD NOT BE FOUND.....'
                              );*/
        END;