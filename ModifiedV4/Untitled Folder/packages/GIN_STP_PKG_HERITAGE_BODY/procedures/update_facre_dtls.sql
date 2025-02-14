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