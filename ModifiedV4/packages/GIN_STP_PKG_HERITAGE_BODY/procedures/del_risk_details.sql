PROCEDURE del_risk_details (
      v_pol_batch_no   IN   NUMBER,
      v_ipu_code       IN   NUMBER,
      v_pro_code            NUMBER
   )
   IS
      --v_successful NUMBER;
      --v_authorised VARCHAR2(2);
      v_auths           VARCHAR2 (2);
      v_err_pos         VARCHAR2 (75);
      v_errmsg          VARCHAR2 (600);
      v_cert_ipu_code   NUMBER;
      v_cnt             NUMBER;
      v_polin_code      NUMBER;
   BEGIN
      BEGIN
         SELECT pol_authosrised, ipu_polin_code
           INTO v_auths, v_polin_code
           FROM gin_policies, gin_insured_property_unds
          WHERE ipu_pol_batch_no = pol_batch_no
            AND pol_batch_no = v_pol_batch_no
            AND ipu_code = v_ipu_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            raise_application_error
                                   (-20001,
                                    'THE TRANSACTION COULD NOT BE FOUND.....'
                                   );
      END;

--IF v_auths != 'A' then
      v_err_pos := 'SPECIFIC DETAILS';
      del_spec_details (v_pro_code, v_ipu_code);
      v_err_pos := 'RISK LEVEL TABLES';

      DELETE FROM GIN_POLICY_RISK_COMMISSIONS
            WHERE PRC_IPU_CODE = v_ipu_code;
             
      DELETE FROM GIN_POLICY_RISK_SERVICES
            WHERE PRS_IPU_CODE = v_ipu_code;
             
      DELETE FROM gin_policy_clauses
            WHERE pocl_ipu_code = v_ipu_code;

      DELETE FROM gin_policy_insured_limits
            WHERE pil_ipu_code = v_ipu_code;

      DELETE FROM gin_pol_sec_perils
            WHERE gpsp_ipu_code = v_ipu_code;

      DELETE FROM gin_risk_excess
            WHERE re_ipu_code = v_ipu_code;

      DELETE FROM gin_policy_risk_schedules
            WHERE polrs_ipu_code = v_ipu_code;

      DELETE FROM gin_participations
            WHERE part_ipu_code = v_ipu_code;

      DELETE FROM gin_policy_rein_risk_details
            WHERE ptotr_ipu_code = v_ipu_code;

      DELETE FROM gin_facre_cessions
            WHERE fc_ipu_code = v_ipu_code;

      DELETE FROM gin_policy_risk_ri_dtls
            WHERE prrd_ipu_code = v_ipu_code;

      --COMMIT;
      DELETE FROM gin_policy_exceptions
            WHERE gpe_ipu_code = v_ipu_code;

      DELETE FROM gin_policy_active_risks
            WHERE polar_pol_batch_no = v_pol_batch_no
              AND polar_ipu_code = v_ipu_code;
              
       DELETE FROM GIN_POL_RISK_SECTION_PERILS 
           WHERE PRSPR_IPU_CODE = v_ipu_code 
           AND PRSPR_POL_BATCH_NO = v_pol_batch_no;
      --COMMIT;
      BEGIN
         SELECT COUNT (1)
           INTO v_cnt
           FROM gin_policy_certs
          WHERE polc_ipu_code = v_ipu_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            raise_application_error (-20001,
                                     'ERROR CHECKING RISK CERTIFICATES..'
                                    );
      END;

      IF NVL (v_cnt, 0) > 0
      THEN
         BEGIN
            v_cert_ipu_code := NULL;

            SELECT MAX (ipu_code)
              INTO v_cert_ipu_code
              FROM gin_insured_property_unds, gin_policies
             WHERE pol_batch_no = ipu_pol_batch_no
               AND ipu_id = (SELECT ipu_id
                               FROM gin_insured_property_unds
                              WHERE ipu_code = v_ipu_code)
               AND pol_authosrised = 'A'
               AND ipu_code != v_ipu_code;
         EXCEPTION
            WHEN OTHERS
            THEN
               raise_application_error
                        (-20001,
                         'ERROR SELECTING RISK TO TRANSFER CERTIFICATES TO..'
                        );
         END;

         IF     v_cert_ipu_code IS NOT NULL
            AND NVL (gin_parameters_pkg.get_param_varchar ('UW_CERTS'), 'N') =
                                                                           'N'
         THEN
            UPDATE gin_policy_certs
               SET (polc_pol_ren_endos_no, polc_pol_batch_no, polc_ipu_code) =
                      (SELECT ipu_pol_ren_endos_no, ipu_pol_batch_no,
                              ipu_code
                         FROM gin_insured_property_unds
                        WHERE ipu_code = v_cert_ipu_code
                          AND ipu_code = polc_ipu_code)
             WHERE polc_ipu_code = v_ipu_code;

            UPDATE gin_print_cert_queue
               SET (pcq_pol_ren_endos_no, pcq_pol_batch_no, pcq_ipu_code) =
                      (SELECT ipu_pol_ren_endos_no, ipu_pol_batch_no,
                              ipu_code
                         FROM gin_insured_property_unds
                        WHERE ipu_code = v_cert_ipu_code)
             WHERE pcq_ipu_code = v_ipu_code;
         ELSE
            /*INSERT INTO  GIN_POLICY_CERTS_TRANSF
            (SELECT * FROM GIN_POLICY_CERTS WHERE POLC_IPU_CODE = v_ipu_code);
            INSERT INTO GIN_PRINT_CERT_QUEUE_TRANSF
            (SELECT * FROM  GIN_PRINT_CERT_QUEUE WHERE PCQ_IPU_CODE = v_ipu_code);*/
            DELETE FROM gin_print_cert_queue
                  WHERE pcq_ipu_code = v_ipu_code;

            DELETE FROM gin_policy_certs
                  WHERE polc_ipu_code = v_ipu_code;
         --RAISE_APPLICATION_ERROR(-20001,'DELETION CANCELLED. THERE IS NO OTHER RISK RECORD TO TRANSFER CERTIFICATES TO..');
         END IF;
      END IF;
    


      -- Delete the Risk
      v_err_pos := 'DELETING RISK';

      DELETE FROM gin_insured_property_unds
            WHERE ipu_code = v_ipu_code;

      v_cnt := 0;

      BEGIN
         SELECT COUNT (1)
           INTO v_cnt
           FROM gin_insured_property_unds
          WHERE ipu_polin_code = v_polin_code
            AND ipu_pol_batch_no = v_pol_batch_no;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      IF NVL (v_cnt, 0) = 0
      THEN
         DELETE      gin_policy_insureds
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
                  'THE RISK COULD NOT BE DELETED AT ' || v_err_pos || '.....';
         ELSE
            v_errmsg :=
                  'THE RISK COULD NOT BE DELETED AT '
               || v_err_pos
               || ',ERROR :-'
               || SQLERRM (SQLCODE);
         END IF;

         raise_error (v_errmsg);
   END;