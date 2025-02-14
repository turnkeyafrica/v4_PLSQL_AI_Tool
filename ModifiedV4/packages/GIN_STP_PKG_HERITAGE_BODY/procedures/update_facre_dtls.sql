PROCEDURE update_facre_dtls (
      v_fid_code                   NUMBER,
      v_action                     VARCHAR2,
      v_fid_pol_batch_no           NUMBER,
      v_pol_no                     VARCHAR2,
      v_ren_endors_no              VARCHAR2,
      v_ced_pol_no                 gin_facre_in_dtls.fid_cede_comp_policy_no%TYPE,
      v_si                         gin_facre_in_dtls.fid_sum_insured%TYPE,
      v_gross_rate                 gin_facre_in_dtls.fid_gross_rate%TYPE,
      v_first_prem                 gin_facre_in_dtls.fid_cede_comp_first_prem%TYPE,
      v_ren_prem                   gin_facre_in_dtls.fid_cede_company_ren_prem%TYPE,
      v_wef                        gin_facre_in_dtls.fid_wef%TYPE,
      v_wet                        gin_facre_in_dtls.fid_wet%TYPE,
      v_rein_terms                 gin_facre_in_dtls.fid_rein_terms_from%TYPE,
      v_rein_terms_to              gin_facre_in_dtls.fid_reins_term_to%TYPE,
      v_gross_ret                  gin_facre_in_dtls.fid_cede_comp_gross_ret%TYPE,
      v_rein_amt                   gin_facre_in_dtls.fid_cede_comp_rein_amt%TYPE,
      v_amt                        gin_facre_in_dtls.fid_amt_perc_sum_insured%TYPE,
      v_sign_dt                    gin_facre_in_dtls.fid_cede_sign_dt%TYPE,
      v_fid_primary_broker         gin_facre_in_dtls.fid_primary_broker%TYPE,
      v_err                  OUT   VARCHAR2
   )
   IS
      v_new_fid_code   NUMBER;
      v_status         VARCHAR2 (10);
   BEGIN
  -- raise_error('v_si'||v_si);
      BEGIN
         SELECT pol_authosrised
           INTO v_status
           FROM gin_policies
          WHERE pol_batch_no = v_fid_pol_batch_no;
      END;

      IF v_status = 'A'
      THEN
         v_err := 'Cannot Make Changes to an authorized Policy ...';
         RETURN;
      END IF;

      IF v_action = 'A'
      THEN
         BEGIN
            SELECT gin_fid_code_seq.NEXTVAL
              INTO v_new_fid_code
              FROM DUAL;

            INSERT INTO gin_facre_in_dtls
                        (fid_code, fid_pol_batch_no, fid_pol_ren_endos_no,
                         fid_pol_policy_no, fid_cede_comp_policy_no,
                         fid_sum_insured, fid_gross_rate,
                         fid_cede_comp_first_prem, fid_cede_company_ren_prem,
                         fid_wef, fid_wet, fid_rein_terms_from, fid_reins_term_to,
                         fid_cede_comp_gross_ret, fid_cede_comp_rein_amt,
                         fid_cede_sign_dt, fid_amt_perc_sum_insured,
                         fid_primary_broker
                        )
                 VALUES (v_new_fid_code, v_fid_pol_batch_no, v_ren_endors_no,
                         v_pol_no, v_ced_pol_no,
                         v_si, v_gross_rate,
                         v_first_prem, v_ren_prem,
                         v_wef, v_wet, v_rein_terms, v_rein_terms_to,
                         v_gross_ret, v_rein_amt,
                         v_sign_dt, v_amt,
                         v_fid_primary_broker
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               v_err :=
                     'Error occurred on inserting facre details ...'
                  || SQLERRM (SQLCODE);
               RETURN;
         END;
      ELSIF v_action = 'E'
      THEN
         BEGIN
            UPDATE gin_facre_in_dtls
               SET
                   --pspr_QR_QUOT_CODE = NVL(v_pspr_qr_quot_code,pspr_QR_QUOT_CODE),
                         --pspr_QR_CODE = NVL(v_pspr_qr_code,pspr_QR_CODE),
                   fid_cede_comp_policy_no =
                                   NVL (v_ced_pol_no, fid_cede_comp_policy_no),
                   fid_sum_insured = NVL (v_si, fid_sum_insured),
                   fid_gross_rate = NVL (v_gross_rate, fid_gross_rate),
                   fid_cede_comp_first_prem =
                                  NVL (v_first_prem, fid_cede_comp_first_prem),
                   fid_cede_company_ren_prem =
                                   NVL (v_ren_prem, fid_cede_company_ren_prem),
                   fid_wef = NVL (v_wef, fid_wef),
                   fid_wet = NVL (v_wet, fid_wet),
                   fid_rein_terms_from = NVL (v_rein_terms, fid_rein_terms_from),
                   fid_reins_term_to =
                                      NVL (v_rein_terms_to, fid_reins_term_to),
                   fid_cede_comp_gross_ret =
                                    NVL (v_gross_ret, fid_cede_comp_gross_ret),
                   fid_cede_comp_rein_amt =
                                      NVL (v_rein_amt, fid_cede_comp_rein_amt),
                   fid_cede_sign_dt = NVL (v_sign_dt, fid_cede_sign_dt),
                   fid_amt_perc_sum_insured =
                                         NVL (v_amt, fid_amt_perc_sum_insured),
                   fid_primary_broker = v_fid_primary_broker
             WHERE fid_code = v_fid_code;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_err :=
                     'Unable to retrieve facre details for update  ...'
                  || v_ced_pol_no
                  || '..'
                  || SQLERRM (SQLCODE);
               RETURN;
            WHEN OTHERS
            THEN
               v_err :=
                     'Error occurred on updating facre details ...'
                  || SQLERRM (SQLCODE);
               RETURN;
         END;
      ELSIF v_action = 'D'
      THEN
         BEGIN
            DELETE FROM gin_facre_in_dtls
                  WHERE fid_code = v_fid_code;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_err :=
                     'Unable to facre details for DELETION  ...'
                  || v_ced_pol_no
                  || '..'
                  || SQLERRM (SQLCODE);
               RETURN;
            WHEN OTHERS
            THEN
               v_err :=
                     'Error occurred on DELETING facre details ...'
                  || SQLERRM (SQLCODE);
               RETURN;
         END;
      END IF;
   END update_facre_dtls;