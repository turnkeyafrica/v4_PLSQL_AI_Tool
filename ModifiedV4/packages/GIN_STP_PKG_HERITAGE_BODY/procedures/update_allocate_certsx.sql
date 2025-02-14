PROCEDURE update_allocate_certsx (
      v_action                        VARCHAR2,
      v_polc_code                     gin_policy_certs.polc_code%TYPE,
      v_polc_pol_policy_no            gin_policy_certs.polc_pol_policy_no%TYPE,
      v_polc_pol_ren_endos_no         gin_policy_certs.polc_pol_ren_endos_no%TYPE,
      v_polc_pol_batch_no             gin_policy_certs.polc_pol_batch_no%TYPE,
      v_polc_ipu_code                 gin_policy_certs.polc_ipu_code%TYPE,
      v_ipu_id                        gin_policy_certs.polc_ipu_id%TYPE,
      v_polc_ct_code                  gin_policy_certs.polc_ct_code%TYPE,
      v_polc_ct_sht_desc              gin_policy_certs.polc_ct_sht_desc%TYPE,
      v_polc_cer_cert_no              gin_policy_certs.polc_cer_cert_no%TYPE,
      v_polc_lot_id                   gin_policy_certs.polc_lot_id%TYPE,
      v_polc_issue_dt                 gin_policy_certs.polc_issue_dt%TYPE,
      v_polc_cert_year                gin_policy_certs.polc_cert_year%TYPE,
      v_polc_status                   gin_policy_certs.polc_status%TYPE,
      v_polc_print_status             gin_policy_certs.polc_print_status%TYPE,
      v_polc_print_dt                 gin_policy_certs.polc_print_dt%TYPE,
      v_polc_wef                      gin_policy_certs.polc_wef%TYPE,
      v_polc_wet                      gin_policy_certs.polc_wet%TYPE,
      v_polc_check_cert               gin_policy_certs.polc_check_cert%TYPE,
      v_polc_reason_cancelled         gin_policy_certs.polc_reason_cancelled%TYPE,
      v_polc_cancel_dt                gin_policy_certs.polc_cancel_dt%TYPE,
      v_user                          VARCHAR,
      v_err                     OUT   VARCHAR2
   )
   IS
      v_new_polc_code              NUMBER;
      v_new_pcq_code               NUMBER;
      --  v_wef            DATE;
      v_wet                        DATE;
      v_ipu_wef                    DATE;
      v_ipu_wet                    DATE;
      v_ipu_eff_wet                DATE;
      v_unsubmtd_docs              NUMBER;
      v_short_period               NUMBER;
      v_cert_wef                   DATE;
      v_rqrd_docs                  NUMBER;
      --v_rqrd_doc       VARCHAR2(1);
      v_ipu_prev_ipu_code          NUMBER;
      v_error                      VARCHAR2 (200);
      v_polc_passenger_no          gin_policy_certs.polc_passenger_no%TYPE;
      v_polc_tonnage               gin_policy_certs.polc_tonnage%TYPE;
      v_ipu_clp_code               gin_insured_property_unds.ipu_clp_code%TYPE;
      v_ipu_eff_wef                gin_insured_property_unds.ipu_eff_wef%TYPE;
      v_ipu_covt_sht_desc          gin_insured_property_unds.ipu_covt_sht_desc%TYPE;
      v_insured                    VARCHAR2 (300);
      v_comp_name                  VARCHAR2 (100);
      v_uw_certs                   VARCHAR2 (1);
      --v_cert_sht_period Number;
      v_cover_code                 NUMBER;
      v_cert_desc                  VARCHAR2 (50);
      v_ct_type                    VARCHAR2 (10);
      v_cert_no                    VARCHAR2 (20);
      v_ipu_sec_scl_code           gin_insured_property_unds.ipu_sec_scl_code%TYPE;
      v_brn_code                   gin_policies.pol_brn_code%TYPE;
      v_pol_uw_year                gin_policies.pol_uw_year%TYPE;
      v_pol_tran_type              gin_policies.pol_tran_type%TYPE;
      v_agn_agent_code             tqc_agencies.agn_code%TYPE;
      v_agnt_sht_desc              tqc_agencies.agn_sht_desc%TYPE;
      v_ipu_property_id            gin_insured_property_unds.ipu_property_id%TYPE;
      v_pol_client_policy_number   gin_policies.pol_client_policy_number%TYPE;
      v_ipu_prp_code               gin_insured_property_unds.ipu_prp_code%TYPE;
      v_cnt                        NUMBER;
      cert_status                  VARCHAR2 (1);
      cert_wef                     DATE;
      cert_wet                     DATE;
      print_cert_status            VARCHAR2 (1);
      v_polc_ipu_id                NUMBER;
      v_pol_prem_computed          VARCHAR2 (10);
      v_pol_statusi                VARCHAR2 (10);
      v_clnt_code                  NUMBER;
      v_agn_code                   NUMBER;
      v_backdating_of_certs_param VARCHAR2 (1);
   BEGIN
      BEGIN
         SELECT pol_prp_code, pol_agnt_agent_code
           INTO v_clnt_code, v_agn_code
           FROM gin_policies
          WHERE pol_batch_no = v_polc_pol_batch_no;
      EXCEPTION
         WHEN OTHERS
         THEN
            raise_error ('Error getting policy details...');
      END;
      
       BEGIN
         v_backdating_of_certs_param :=
                 gin_parameters_pkg.get_param_varchar ('ALLOW_BACKDATING_OF_CERTS');
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_backdating_of_certs_param := 'N';
         WHEN OTHERS
         THEN
            v_backdating_of_certs_param := 'N';
        END;

      IF gin_parameters_pkg.get_param_varchar ('ALLOW_CERTIFICATE_BALANCES') =
                                                                           'N'
      THEN
         IF gis_accounts_utilities.getpaidprem (v_polc_pol_batch_no,
                                                v_agn_code,
                                                v_clnt_code,
                                                'B'
                                               ) > 0
         THEN
            v_err :=
                  'Cannot Allocate Certificate when there is pending balance';
            RETURN;
         END IF;
      END IF;

      SELECT pol_prem_computed, pol_policy_status
        INTO v_pol_prem_computed, v_pol_statusi
        FROM gin_policies
       WHERE pol_batch_no = v_polc_pol_batch_no;

      --raise_error(' v_pol_prem_computed '||v_pol_prem_computed);
--      IF NVL (v_pol_prem_computed, 'N') != 'Y' AND v_pol_statusi != 'CO'
--      THEN
--         -- RAISE_ERROR('here.......idiot*10');
--         v_err :=
--            'Please compute premium on policy. Changes have been made on the policy..';
--         RETURN;
--      END IF;
      BEGIN
         SELECT pol_brn_code, pol_uw_year, pol_tran_type,
                pol_agnt_agent_code, pol_agnt_sht_desc,
                pol_client_policy_number
           INTO v_brn_code, v_pol_uw_year, v_pol_tran_type,
                v_agn_agent_code, v_agnt_sht_desc,
                v_pol_client_policy_number
           FROM gin_policies
          WHERE pol_batch_no = v_polc_pol_batch_no;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_err :=
                  'Error retrieving policy for certificate allocation ...'
               || SQLERRM (SQLCODE);
            RETURN;
         WHEN OTHERS
         THEN
            v_err :=
                    'Error Occurred at policy Level ...' || SQLERRM (SQLCODE);
            RETURN;
      END;

      BEGIN
         SELECT ipu_wef, ipu_wet, ipu_prev_ipu_code, ipu_eff_wet,
                ipu_eff_wef, ipu_sec_scl_code, ipu_clp_code,
                ipu_covt_sht_desc, ipu_property_id, ipu_prp_code,
                gis_utilities.clnt_name (clnt_name, clnt_other_names) insured,
                ipu_id
           INTO v_ipu_wef, v_ipu_wet, v_ipu_prev_ipu_code, v_ipu_eff_wet,
                v_ipu_eff_wef, v_ipu_sec_scl_code, v_ipu_clp_code,
                v_ipu_covt_sht_desc, v_ipu_property_id, v_ipu_prp_code,
                v_insured,
                v_polc_ipu_id
           FROM gin_insured_property_unds, tqc_clients
          WHERE ipu_code = v_polc_ipu_code
            AND ipu_pol_batch_no = v_polc_pol_batch_no
            AND ipu_prp_code = clnt_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_err :=
                  'Error retrieving risk for certificate At Risk Level ...ipu='
               || v_polc_ipu_code
               || '= batch='
               || v_polc_pol_batch_no
               || SQLERRM (SQLCODE);
            RETURN;
         WHEN OTHERS
         THEN
            v_err := 'Error Occurred Risk Level ...' || SQLERRM (SQLCODE);
            RETURN;
      END;

      BEGIN
         SELECT polc_status, polc_wef, polc_wet, polc_print_status
           INTO cert_status, cert_wef, cert_wet, print_cert_status
           FROM gin_policy_certs
          WHERE polc_code = v_polc_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            NULL;
         WHEN OTHERS
         THEN
            v_err :=
                  'Error Occurred getting the allocated certificate ...'
               || SQLERRM (SQLCODE);
            RETURN;
      END;

      BEGIN
         SELECT MAX (wef_dt)
           INTO v_cert_wef
           FROM (SELECT MAX (NVL ((polc_wet + 1), v_ipu_wef)) wef_dt
                   FROM gin_policy_certs
                  WHERE polc_ipu_code(+) = v_polc_ipu_code
                        AND polc_status != 'C'
                 UNION
                 SELECT MAX (NVL ((polc_wet + 1), v_ipu_wef)) wef_dt
                   FROM gin_policy_certs
                  WHERE polc_ipu_code(+) = v_ipu_prev_ipu_code
                        AND polc_status != 'C'
                 UNION
                 SELECT TRUNC (SYSDATE)
                   FROM DUAL);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_cert_wef := NULL;
      END;

      IF v_cert_wef IS NOT NULL
      THEN
         NULL;                                          -- v_wef:=v_cert_wef;
      ELSE
         NULL;                 --v_wef := GREATEST(v_ipu_wef,TRUNC(SYSDATE));
      END IF;

      BEGIN
         SELECT COUNT (*)
           INTO v_unsubmtd_docs
           FROM gin_uw_doc_reqrd_submtd
          WHERE usdocr_ipu_code = v_polc_ipu_code AND usdocr_submited = 'N';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_unsubmtd_docs := 0;
      END;

      BEGIN
         SELECT param_value
           INTO v_short_period
           FROM gin_parameters
          WHERE param_name = 'CERT_SHT_PERIOD';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            NULL;
      END;

      IF v_unsubmtd_docs > 0 AND v_short_period > 0
      THEN
         SELECT MIN (wet_dt)
           INTO v_wet
           FROM (SELECT (v_polc_wef + v_short_period) wet_dt
                   FROM DUAL
                 UNION
                 SELECT v_ipu_wet wet_dt
                   FROM DUAL);
      ELSE
         NULL;                                          --v_wet := v_ipu_wet;
      END IF;
    IF NVL(v_backdating_of_certs_param,'N')!='Y' THEN
     IF NVL (v_action, 'A') = 'A' OR NVL (v_action, 'A') = 'E'
      THEN
         IF v_polc_wef IS NULL OR v_polc_wet IS NULL
         THEN
            v_err := 'Must specify certificates cover effective dates..';
         ELSIF v_polc_wef > v_polc_wet
         THEN
            v_err :=
               'The Wet date entered is earlier than the ''Wef'' Date.  Please Re-enter';
            RETURN;
         ELSIF v_polc_wef < GREATEST (v_ipu_wef, TRUNC (SYSDATE))
         THEN
            v_err :=
               ' Certificate effective dates can not be before todays date or the risk cover from date..';
            RETURN;
         END IF;
      END IF;
    ELSE
     IF NVL (v_action, 'A') = 'A' OR NVL (v_action, 'A') = 'E'
      THEN
         IF v_polc_wef IS NULL OR v_polc_wet IS NULL
         THEN
            v_err := 'Must specify certificates cover effective dates..';
         ELSIF v_polc_wef > v_polc_wet
         THEN
            v_err :=
               'The Wet date entered is earlier than the ''Wef'' Date.  Please Re-enter';
            RETURN;
          END IF;
     END IF;
    
    END IF;  
      

      IF v_action = 'A'
      THEN
         IF v_polc_print_status = 'P'
         THEN
            v_err :=
               'This certificate has already been printed and can not be allocated again..';
            RETURN;
         END IF;

         IF v_polc_ct_sht_desc IS NULL
         THEN
            v_err := 'Select certificate type first..';
            RETURN;
         END IF;

         IF v_polc_wet > v_ipu_eff_wet
         THEN
            v_err :=
               'You Cannot Have A Certificate For A Cover Period, Outside The Risk Cover....';
            RETURN;
         END IF;

         BEGIN
            check_dup_certificates (v_polc_wef,
                                    v_polc_wet,
                                    v_polc_status,
                                    v_polc_ipu_id,
                                    v_error,
                                    v_polc_ipu_code
                                   );
         EXCEPTION
            WHEN OTHERS
            THEN
               v_err :=
                     'Error on Checking duplicate certificates....'
                  || SQLERRM (SQLCODE);
               RETURN;
         END;

         IF v_error IS NOT NULL
         THEN
            v_err := v_error;
            RETURN;
         END IF;

         IF v_short_period IS NOT NULL
         THEN
            BEGIN
--                      SELECT COUNT(USDOCR_ID) Into     v_rqrd_docs
--                          FROM GIN_UW_DOC_REQRD_SUBMTD
--                          WHERE USDOCR_IPU_CODE=v_polc_ipu_code
--                          AND USDOCR_SUBMITED='N'
--                          AND USDOCR_DOCR_ID IN
--                          (SELECT DOCR_ID
--                          FROM GIN_DOCUMENTS_REQRD
--                          WHERE DOCR_MANDTRY='Y'
--                          AND DOCR_CERT_DOC='Y'
--                          AND DOCR_LEVEL='UW'
--                          AND DOCR_CLP_CODE=v_ipu_clp_code);
               SELECT COUNT (usdocr_code)
                 INTO v_rqrd_docs
                 FROM gin_uw_doc_reqrd_submtd
                WHERE usdocr_ipu_code = v_polc_ipu_code
                  AND usdocr_submited = 'N'
                  AND usdocr_docr_id IN (
                         SELECT sclrd_code
                           FROM gin_reqrd_documents, gin_subclass_req_docs
                          WHERE rdoc_mandtry = 'Y'
                            AND rdoc_cert_doc = 'Y'
                            AND rdoc_id = sclrd_rdoc_id
                            AND sclrd_scl_code = v_ipu_sec_scl_code);
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  NULL;
               WHEN OTHERS
               THEN
                  v_err := 'CERTIFICATE PRE-INSERT ERROR....';
                  RETURN;
            END;
         END IF;

         IF     NVL (v_rqrd_docs, 0) > 0
            AND (TO_NUMBER (v_polc_wet - v_polc_wef) > NVL (v_short_period, 0)
                )
         THEN
            --message('All documents not provided....');pause;
            NULL;                                          --v_rqrd_doc:='Y';
            v_err :=
               'Cannot Issue full term certificate without the mandatory documents!';

            IF v_short_period IS NOT NULL
            THEN
               IF NVL (v_short_period, 0) >=
                                          TO_NUMBER (v_polc_wet - v_polc_wef)
               THEN
                  v_err :=
                     'Certificate issued for one month and no mandatory documents Submitted!';
               /*:SYSTEM.MESSAGE_LEVEL := 25;
               COMMIT;
               :SYSTEM.MESSAGE_LEVEL := 0;*/
               ELSIF TO_NUMBER (v_polc_wet - v_polc_wef) >
                                                       NVL (v_short_period, 0)
               THEN
                  --:GIN_POLICY_CERTS.POLC_CHECK_CERT:='N';
                  v_err :=
                        'Cannot Issue certificate without the mandatory documents and past '
                     || v_short_period
                     || 'days!! ...';
                  RETURN;
               END IF;
            END IF;
         ELSE
            NULL;                                          --v_rqrd_doc:='Y';
         END IF;

         IF     v_polc_status = 'A'
            AND v_ipu_eff_wef > v_polc_wef
            AND v_ipu_eff_wet < v_polc_wet
         THEN
            v_err :=
               'One cannot allocate a cert when the certificate cover period does not match the risk cover period.';
            RETURN;
         END IF;

         IF     NVL (v_rqrd_docs, 0) > 0
            AND (TO_NUMBER (v_polc_wet - v_polc_wef) > NVL (v_short_period, 0)
                )
            AND NVL (v_short_period, 0) < TO_NUMBER (v_polc_wet - v_polc_wef)
         THEN
            --  :GIN_POLICY_CERTS.POLC_CHECK_CERT:='N';
            v_err :=
               'Cannot Issue full term certificate without the mandatory documents!';
            RETURN;
         ELSE
            --message('All documents provided start....');pause;
            BEGIN
               v_uw_certs :=
                            gin_parameters_pkg.get_param_varchar ('UW_CERTS');
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_uw_certs := 'N';
            END;

            -----------------------------------------------------------ADDED BY KIMOTHO FOR CERTS FOR NIGER
            IF NVL (v_uw_certs, 'N') = 'Y'
            THEN
               BEGIN
                  SELECT covt_code
                    INTO v_cover_code
                    FROM gin_cover_types
                   WHERE covt_sht_desc = v_ipu_covt_sht_desc;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_err :=
                        'Error Getting Cover Code for the risk certificate.....';
                     RETURN;
               END;

               BEGIN
                  v_cert_no :=
                     gin_sequences_pkg.get_cert_number_format
                                                         ('C',
                                                          v_ipu_sec_scl_code,
                                                          v_brn_code,
                                                          v_pol_uw_year,
                                                          v_pol_tran_type,
                                                          v_cover_code
                                                         );
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     NULL;
               END;
            END IF;

----------------------------------------------------------------------------------------------------------
            BEGIN
               SELECT COUNT (1)
                 INTO v_cnt
                 FROM gin_policy_certs
                WHERE polc_pol_batch_no = v_polc_pol_batch_no
                  AND polc_ipu_code = v_polc_ipu_code
                  AND polc_print_status != 'P';
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_err :=
                         'Error checking for other allocations on the risk..';
                  RETURN;
            END;

            IF NVL (v_cnt, 0) != 0
            THEN
               v_err :=
                  'This risk has another certificate allocation awaiting printing..';
               RETURN;
            END IF;

            IF     NVL (v_polc_check_cert, 'N') = 'Y'
               AND NVL (v_polc_print_status, 'N') = 'N'
            THEN
               --SET_ALERT_PROPERTY('CANCEL',ALERT_MESSAGE_TEXT,'Do You Realy Want to Print Certificate ?');
               --al_id := SHOW_ALERT('CANCEL');
               --    IF al_id = ALERT_BUTTON1 THEN
               BEGIN
                  SELECT TO_CHAR (SYSDATE, 'YYYY') ||certificate_no_seq.NEXTVAL
                    INTO v_new_polc_code
                    FROM DUAL;

                  INSERT INTO gin_policy_certs
                              (polc_code,
                               polc_issue_dt,
                               polc_pol_policy_no, polc_pol_ren_endos_no,
                               polc_pol_batch_no, polc_ct_code,
                               polc_agnt_agent_code, polc_agnt_sht_desc,
                               polc_property_id, polc_ipu_code,
                               polc_status, polc_print_dt, polc_wef,
                               polc_wet, polc_scl_code, polc_cert_year,
                               polc_client_policy_no,
                               polc_ct_sht_desc, polc_print_status,
                               polc_check_cert, polc_ipu_id,
                               polc_prp_code, pocl_covt_sht_desc,
                               polc_alloc_by, polc_brn_code, polc_cer_cert_no
                              )
                       VALUES (v_new_polc_code,
                               NVL (v_polc_issue_dt, SYSDATE),
                               v_polc_pol_policy_no, v_polc_pol_ren_endos_no,
                               v_polc_pol_batch_no, v_polc_ct_code,
                               v_agn_agent_code, v_agnt_sht_desc,
                               v_ipu_property_id, v_polc_ipu_code,
                               v_polc_status, v_polc_print_dt, v_polc_wef,
                               v_polc_wet, v_ipu_sec_scl_code, v_pol_uw_year,
                               v_pol_client_policy_number,
                               v_polc_ct_sht_desc, v_polc_print_status,
                               v_polc_check_cert, v_polc_ipu_id,
                               v_ipu_prp_code, v_ipu_covt_sht_desc,
                               v_user, v_brn_code, v_cert_no
                              );
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     ROLLBACK;
                     v_err :=
                           'Error inserting risk in allocation for certificates ..'
                        || SQLERRM (SQLCODE);
                     RETURN;
               END;

               -----------------------------------------------------------ADDED BY KIMOTHO FOR CERTS FOR NIGER
               IF NVL (v_uw_certs, 'N') = 'Y'
               THEN
                  -- :POLC_CER_CERT_NO:=v_cert_no;
                  NULL;
               END IF;

-----------------------------------------------------------
--added for tonnage and passengers <ken 29/10/2008>
               BEGIN
                  BEGIN
                     SELECT ct_type, ct_sht_desc
                       INTO v_ct_type, v_cert_desc
                       FROM gin_cert_types
                      WHERE ct_code = v_polc_ct_code;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        NULL;
                     WHEN OTHERS
                     THEN
                        ROLLBACK;
                        v_err := 'Error getting the cert type...';
                        RETURN;
                  END;

                  --IF v_ct_type IS NOT NULL AND v_ct_type IN ('A','B') THEN<kimotho commented this part to cater for PSV >
                  IF v_cert_desc IS NOT NULL
                     AND v_cert_desc IN ('PSV', 'COMM')
                  THEN
                     BEGIN
                        SELECT mcoms_carry_capacity, mcoms_tonnage
                          INTO v_polc_passenger_no, v_polc_tonnage
                          FROM gin_motor_commercial_sch
                         WHERE mcoms_ipu_code = v_polc_ipu_code
                           AND NVL (mcoms_acc_limit, 'N') = 'N';
                     EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                           NULL;
                        WHEN OTHERS
                        THEN
                           ROLLBACK;
                           v_err :=
                                 'Error getting tonnage/no. of passengers...';
                           RETURN;
                     END;
                  END IF;
               END;

               IF NVL (tqc_parameters_pkg.get_org_type (37), 'INS') = 'INS'
               THEN
                  BEGIN
                     SELECT org_name
                       INTO v_comp_name
                       FROM tqc_systems, tqc_organizations
                      WHERE org_code = sys_org_code AND sys_code = 37;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        ROLLBACK;
                        v_err :=
                           'The company name has not been define, first define the company name...';
                        RETURN;
                     WHEN TOO_MANY_ROWS
                     THEN
                        ROLLBACK;
                        v_err :=
                           'The company name has been defined more than once...';
                        RETURN;
                  END;
               ELSE
                  BEGIN
                     SELECT agn_name
                       INTO v_comp_name
                       FROM tqc_agencies
                      WHERE agn_code = v_agn_agent_code;
                         --<KEN TO TAKE CARE OF ALLOCATION AFTER CANCELLATION>
                  --:TQC_AGENCIES.AGN_CODE; --
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        ROLLBACK;
                        v_err := 'Error getting the insurer name...';
                        RETURN;
                  END;
               END IF;

               --        MESSAGE(':POLC_CODE ='||:POLC_CODE);PAUSE;
               IF NVL (v_uw_certs, 'N') = 'N'
               THEN
                  SELECT gin_pcq_code_seq.NEXTVAL
                    INTO v_new_pcq_code
                    FROM DUAL;

                  BEGIN
                     INSERT INTO gin_print_cert_queue
                                 (pcq_pol_policy_no,
                                  pcq_pol_ren_endos_no,
                                  pcq_pol_batch_no, pcq_ipu_code,
                                  pcq_ct_code, pcq_ct_sht_desc,
                                  pcq_ipu_property_id, pcq_date_time,
                                  pcq_agnt_agent_code, pcq_agnt_sht_desc,
                                  pcq_polc_code,
                                  pcq_client_policy_no,
                                  pcq_code, pcq_wet, pcq_status,
                                  pcq_client_name, pcq_issued_by,
                                  pcq_covt_sht_desc, pcq_scl_code,
                                  pcq_capacity, pcq_brn_code, pcq_tonnage,
                                  pcq_passenger_no, pcq_cert_no
                                 )
                          VALUES (v_polc_pol_policy_no,
                                  v_polc_pol_ren_endos_no,
                                  v_polc_pol_batch_no, v_polc_ipu_code,
                                  v_polc_ct_code, v_polc_ct_sht_desc,
                                  v_ipu_property_id, v_polc_wef,
                                  v_agn_agent_code, v_agnt_sht_desc,
                                  v_new_polc_code,
                                  v_pol_client_policy_number,
                                  v_new_pcq_code, v_polc_wet, 'N',
                                  v_insured, v_comp_name,
                                  v_ipu_covt_sht_desc, v_ipu_sec_scl_code,
                                  NULL, v_brn_code, v_polc_tonnage,
                                  v_polc_passenger_no, v_cert_no
                                 );

                     UPDATE gin_policy_certs
                        SET polc_print_status = 'R'
                      WHERE polc_code = v_new_polc_code;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        ROLLBACK;
                        v_err :=
                              'Error inserting risk in certificate queue..'
                           || SQLERRM (SQLCODE);
                        RETURN;
                  END;
               END IF;
            END IF;
         END IF;
      ELSIF v_action = 'E'
      THEN
         IF     print_cert_status = 'P'
            AND v_polc_status = 'C'
            AND (v_polc_reason_cancelled IS NULL OR v_polc_cancel_dt IS NULL
                )
         THEN
            v_err :=
               'You Cannot Cancel a Certificate without providing the reason for cancellation or date ...';
            RETURN;
         END IF;

         IF print_cert_status = 'P' AND v_polc_cer_cert_no IS NOT NULL
         THEN
            IF v_polc_print_status != print_cert_status
            THEN
               v_err :=
                  'You Cannot change the Print status for certificate once Printed ...';
               RETURN;
            END IF;

            IF cert_wef != v_polc_wef
            THEN
               v_err :=
                  'You Cannot change the WEF date if the Print status for certificate is Printed ...';
               RETURN;
            END IF;

            IF cert_wet != v_polc_wet
            THEN
               v_err :=
                  'You Cannot change the WET date if the Print status for certificate is Printed ...';
               RETURN;
            END IF;
         END IF;

         BEGIN
            UPDATE gin_policy_certs
               SET polc_status = NVL (v_polc_status, polc_status),
                   polc_reason_cancelled =
                          NVL (v_polc_reason_cancelled, polc_reason_cancelled),
                   polc_cancel_dt = NVL (v_polc_cancel_dt, polc_cancel_dt),
                   polc_wef = NVL (v_polc_wef, polc_wef),
                   polc_wet = NVL (v_polc_wet, polc_wet),
                   polc_print_status =
                                  NVL (v_polc_print_status, polc_print_status)
             WHERE polc_code = v_polc_code;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_err :=
                     'Error Retrieving the Certificate to be Updated ...'
                  || SQLERRM (SQLCODE);
               RETURN;
            WHEN OTHERS
            THEN
               v_err :=
                     'Error occured on Updating a Certificate... '
                  || SQLERRM (SQLCODE);
               RETURN;
         END;
      ELSIF v_action = 'D'
      THEN
         IF v_polc_cer_cert_no IS NOT NULL
         THEN
            v_err :=
               'You Cannot Delete a Printed certificate, it Can be cancelled ...';
            RETURN;
         END IF;

         BEGIN
            DELETE FROM gin_print_cert_queue
                  WHERE pcq_polc_code = v_polc_code;

            DELETE FROM gin_policy_certs
                  WHERE polc_code = v_polc_code;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_err :=
                     'Error Retrieving the Certificate to be deleted ...'
                  || SQLERRM (SQLCODE);
               RETURN;
            WHEN OTHERS
            THEN
               v_err :=
                     'Error occured on Deleting a Certificate... '
                  || SQLERRM (SQLCODE);
               RETURN;
         END;
      END IF;
   END update_allocate_certsx;