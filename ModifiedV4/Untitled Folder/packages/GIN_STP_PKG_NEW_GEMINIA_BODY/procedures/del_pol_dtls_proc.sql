PROCEDURE del_pol_dtls_proc (v_pol_batch_no IN NUMBER)
    IS
        --v_successful NUMBER;
        v_status      VARCHAR2 (10);
        v_auths       VARCHAR2 (2);
        v_err_pos     VARCHAR2 (75);
        v_errmsg      VARCHAR2 (600);
        v_error_msg   VARCHAR2 (600);

        --v_cert_ipu_code NUMBER;
        --v_cnt NUMBER;
        CURSOR all_risks_cur IS
            SELECT ipu_code,
                   pol_pro_code,
                   ipu_id,
                   ipu_property_id
              FROM gin_insured_property_unds, gin_policies
             WHERE     ipu_pol_batch_no = pol_batch_no
                   AND ipu_pol_batch_no = v_pol_batch_no;
    BEGIN
        BEGIN
            SELECT pol_authosrised, pol_policy_status
              INTO v_auths, v_status
              FROM gin_policies
             WHERE pol_batch_no = v_pol_batch_no;
        EXCEPTION
            WHEN OTHERS
            THEN
                raise_application_error (
                    -20001,
                    'THE TRANSACTION COULD NOT FOUND.....');
        END;