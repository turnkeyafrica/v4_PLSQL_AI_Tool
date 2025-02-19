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

        --IF v_auths != 'A' then
        v_err_pos := 'SPECIFIC DETAILS';
        del_spec_details (v_pro_code, v_ipu_code);
        v_err_pos := 'RISK LEVEL TABLES';

        v_err_pos := 'ERROR DELETING RISK COMMISSIONS';

        DELETE FROM gin_policy_risk_commissions
              WHERE prc_ipu_code = v_ipu_code;

        v_err_pos := 'ERROR DELETING RISK SERVICES';

        DELETE FROM gin_policy_risk_services
              WHERE prs_ipu_code = v_ipu_code;

        v_err_pos := 'ERROR DELETING POLICY CLAUSES';

        DELETE FROM gin_policy_clauses
              WHERE pocl_ipu_code = v_ipu_code;

        v_err_pos := 'ERROR DELETING PREMIUM ITEMS';

        DELETE FROM gin_policy_insured_limits
              WHERE pil_ipu_code = v_ipu_code;

        v_err_pos := 'ERROR DELETING POLICY PERILS';

        DELETE FROM gin_pol_sec_perils
              WHERE gpsp_ipu_code = v_ipu_code;

        v_err_pos := 'ERROR DELETING RISK EXCESSES';

        DELETE FROM gin_risk_excess
              WHERE re_ipu_code = v_ipu_code;

        v_err_pos := 'ERROR DELETING RISK LIMITS OF LIABILITY';

        DELETE FROM gin_policy_risk_schedules
              WHERE polrs_ipu_code = v_ipu_code;

        v_err_pos := 'ERROR DELETING RISK PARTICIPATIONS';

        DELETE FROM gin_participations
              WHERE part_ipu_code = v_ipu_code;

        v_err_pos := 'ERROR DELETING RISK REINSURANCE POOL DETAILS';

        DELETE FROM GIN_POL_REIN_POOL_RISK_DETAILS
              WHERE PRPRD_IPU_CODE = v_ipu_code;

        v_err_pos := 'ERROR DELETING RISK REINSURANCE DETAILS';

        DELETE FROM gin_policy_rein_risk_details
              WHERE ptotr_ipu_code = v_ipu_code;

        v_err_pos := 'ERROR DELETING FACRE CESSIONS';

        DELETE FROM gin_facre_cessions
              WHERE fc_ipu_code = v_ipu_code;

        v_err_pos := 'ERROR DELETING RISK RI DETAILS';

        DELETE FROM gin_policy_risk_ri_dtls
              WHERE prrd_ipu_code = v_ipu_code;

        v_err_pos := 'ERROR DELETING POLICY EXCEPTIONS';

        DELETE FROM gin_policy_exceptions
              WHERE gpe_ipu_code = v_ipu_code;

        v_err_pos := 'ERROR DELETING POLICY ACTIVE RISK DETAILS';

        --RAISE_ERROR(v_pol_batch_no||';'||v_ipu_code); ;
        DELETE FROM
            gin_policy_active_risks
              WHERE     polar_pol_batch_no = v_pol_batch_no
                    AND polar_ipu_code = v_ipu_code;

        v_err_pos := 'ERROR DELETING RISK SECTION PERILS';

        DELETE FROM
            gin_pol_risk_section_perils
              WHERE     prspr_ipu_code = v_ipu_code
                    AND prspr_pol_batch_no = v_pol_batch_no;

        --COMMIT;
        v_err_pos := 'CERTIFICATES VALIDATION';

        BEGIN
            SELECT SUM (NVL (cnt, 0))
              INTO v_cnt
              FROM (SELECT COUNT (1)     cnt
                      FROM gin_policy_certs
                     WHERE polc_ipu_code = v_ipu_code
                    UNION
                    SELECT COUNT (1)     cnt
                      FROM gin_aki_policy_cert_dtls
                     WHERE     apcd_ipu_code = v_ipu_code
                           AND apcd_cer_cert_no IS NOT NULL);
        EXCEPTION
            WHEN OTHERS
            THEN
                v_err_pos := 'ERROR CHECKING RISK CERTIFICATES.';
        /*raise_application_error (-20001,
                                 'ERROR CHECKING RISK CERTIFICATES..'
                                );*/
        END;

        --RAISE_ERROR(v_cnt||' <<< '||v_ipu_code);

        IF NVL (v_cnt, 0) > 0
        THEN
            RAISE_ERROR (
                'YOU CAN NOT DELETE A RISK WITH AN ISSUED CERTIFICATE');
        END IF;


        /*      IF NVL (v_cnt, 0) > 0
               THEN
                   BEGIN
                       v_cert_ipu_code := NULL;

                       SELECT MAX (ipu_code)
                         INTO v_cert_ipu_code
                         FROM gin_insured_property_unds, gin_policies
                        WHERE     pol_batch_no = ipu_pol_batch_no
                              AND ipu_id = (SELECT ipu_id
                                              FROM gin_insured_property_unds
                                             WHERE ipu_code = v_ipu_code)
                              AND pol_authosrised = 'A'
                              AND ipu_code != v_ipu_code;
                   EXCEPTION
                       WHEN OTHERS
                       THEN
                           v_err_pos :=
                               'ERROR SELECTING RISK TO TRANSFER CERTIFICATES TO..';
       --            raise_application_error
       --                     (-20001,
       --                      'ERROR SELECTING RISK TO TRANSFER CERTIFICATES TO..'
       --                     );
                   END;

                   IF     v_cert_ipu_code IS NOT NULL
                      AND NVL (gin_parameters_pkg.get_param_varchar ('UW_CERTS'),
                               'N') =
                          'N'
                   THEN
                       UPDATE gin_policy_certs
                          SET (polc_pol_ren_endos_no,
                               polc_pol_batch_no,
                               polc_ipu_code) =
                                  (SELECT ipu_pol_ren_endos_no,
                                          ipu_pol_batch_no,
                                          ipu_code
                                     FROM gin_insured_property_unds
                                    WHERE     ipu_code = v_cert_ipu_code
                                          AND ipu_code = polc_ipu_code)
                        WHERE polc_ipu_code = v_ipu_code;

                       UPDATE gin_print_cert_queue
                          SET (pcq_pol_ren_endos_no, pcq_pol_batch_no, pcq_ipu_code) =
                                  (SELECT ipu_pol_ren_endos_no,
                                          ipu_pol_batch_no,
                                          ipu_code
                                     FROM gin_insured_property_unds
                                    WHERE ipu_code = v_cert_ipu_code)
                        WHERE pcq_ipu_code = v_ipu_code;
                   ELSE
       --                INSERT INTO  GIN_POLICY_CERTS_TRANSF
       --                (SELECT * FROM GIN_POLICY_CERTS WHERE POLC_IPU_CODE = v_ipu_code);
       --                INSERT INTO GIN_PRINT_CERT_QUEUE_TRANSF
       --                (SELECT * FROM  GIN_PRINT_CERT_QUEUE WHERE PCQ_IPU_CODE = v_ipu_code);
                       DELETE FROM gin_print_cert_queue
                             WHERE pcq_ipu_code = v_ipu_code;

                       DELETE FROM gin_policy_certs
                             WHERE polc_ipu_code = v_ipu_code;
                   --RAISE_APPLICATION_ERROR(-20001,'DELETION CANCELLED. THERE IS NO OTHER RISK RECORD TO TRANSFER CERTIFICATES TO..');
                   END IF;
               END IF;
       */

        BEGIN
            SELECT COUNT (1)
              INTO v_claim_cnt
              FROM gin_claim_master_bookings
             WHERE cmb_ipu_code = v_ipu_code;
        EXCEPTION
            WHEN OTHERS
            THEN
                v_error := 'ERROR CHECKING RISK CLAIMS..';
                RETURN;
        END;

        IF NVL (v_claim_cnt, 0) > 0
        THEN
            v_error :=
                'RISK ' || v_property_id || ' HAS A CLAIM ATTACHED TO IT';
            RETURN;
        END IF;

        v_err_pos := 'DELETING LOADED RISK';

        DELETE FROM GIN_RISKS_LOADING
              WHERE GRL_IPU_CODE = v_ipu_code;

        v_err_pos := 'DELETING RISK';

        DELETE FROM gin_insured_property_unds
              WHERE ipu_code = v_ipu_code;

        v_cnt := 0;

        BEGIN
            SELECT COUNT (1)
              INTO v_cnt
              FROM gin_insured_property_unds
             WHERE     ipu_polin_code = v_polin_code
                   AND ipu_pol_batch_no = v_pol_batch_no;
        EXCEPTION
            WHEN OTHERS
            THEN
                NULL;
        END;

        IF NVL (v_cnt, 0) = 0
        THEN
            DELETE gin_policy_insureds
             WHERE polin_code = v_polin_code;
        END IF;
    -- COMMIT;

    --:System.Message_Level := '0';
    EXCEPTION
        WHEN OTHERS
        THEN
            IF SQLCODE = -100501
            THEN
                v_errmsg :=
                       'THE RISK COULD NOT BE DELETED AT '
                    || v_err_pos
                    || '.....';
            ELSE
                v_errmsg :=
                       'THE RISK COULD NOT BE DELETED AT '
                    || v_err_pos
                    || ',ERROR :-'
                    || SQLERRM (SQLCODE);
            END IF;

            v_error := v_errmsg;
            RETURN;
    /*raise_error (v_errmsg);*/
    END;