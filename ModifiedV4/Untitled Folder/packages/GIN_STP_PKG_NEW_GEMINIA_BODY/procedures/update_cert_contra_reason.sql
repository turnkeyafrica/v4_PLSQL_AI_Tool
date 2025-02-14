PROCEDURE update_cert_contra_reason (
        v_accl_contra_pol_batch_no   IN aki_cert_cancellation_log.accl_contra_pol_batch_no%TYPE,
        v_reason                     IN aki_cert_cancellation_log.accl_not_cancelled_reason%TYPE --,
                                                                                                ----  v_err                           OUT VARCHAR2
                                                                                                )
    IS
        v_cnt     NUMBER;
        v_count   NUMBER := 0;

        CURSOR active_certs IS
            SELECT *
              FROM gin_aki_policy_cert_dtls
             WHERE     apcd_pol_policy_no IN
                           (SELECT pol_policy_no
                              FROM gin_policies
                             WHERE pol_batch_no = v_accl_contra_pol_batch_no)
                   AND ROWNUM = 1
                   AND apcd_cert_cancelled != 'Y'
                   AND apcd_wet >= TRUNC (SYSDATE)
                   AND NVL (apcd_cert_allocated, 'N') = 'Y';
    BEGIN
        FOR contra_cert IN active_certs
        LOOP
            BEGIN
                SELECT COUNT (*)
                  INTO v_cnt
                  FROM aki_cert_cancellation_log
                 WHERE     accl_apcd_code = contra_cert.apcd_code
                       AND accl_contra_pol_batch_no =
                           v_accl_contra_pol_batch_no;
            EXCEPTION
                WHEN OTHERS
                THEN
                    NULL;      ----v_err := 'Getting cert cancellation count';
            END;