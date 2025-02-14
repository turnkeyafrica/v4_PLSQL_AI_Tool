FUNCTION create_uw_trans_func (
      clientname                IN   VARCHAR2,
      clientpin                 IN   VARCHAR2,
      clienttype                IN   VARCHAR2,
      clienttitle               IN   VARCHAR2,
      policynumber              IN   VARCHAR2,
      policyendorsementnumber   IN   VARCHAR2,
      policyagentcode           IN   VARCHAR2,
      policycoverfrom           IN   DATE,
      policycoverto             IN   DATE,
      policyunderwritingyear    IN   NUMBER,
      policytransactiontype     IN   VARCHAR2,
                    --  NB  - New business, EN  - Endorsements, RN  - Renewals
      policypreparedby          IN   VARCHAR2,
      policyauthorizedby        IN   VARCHAR2,
      policybranchcode          IN   VARCHAR2,
      policydebitnotenumber     IN   VARCHAR2,
      policyproduct             IN   VARCHAR2,
      policystampduty           IN   NUMBER,
      policycurrency            IN   VARCHAR2,
      riskid                    IN   VARCHAR2,
      riskdesc                  IN   VARCHAR2,
      risksubclass              IN   VARCHAR2,
      riskcovertype             IN   VARCHAR2,
      risksuminsured            IN   NUMBER,
      riskbasicpremium          IN   NUMBER,
      --This is premium inclusive of commission but not inclusive of the taxes
      riskcommissionamount      IN   NUMBER,
      risktraininglevy          IN   NUMBER,
      policyphcf                IN   NUMBER,
      premsection               IN   NUMBER
   )
      RETURN VARCHAR2
   IS
      vcount           NUMBER;
      vreturn          VARCHAR2 (1);
      vclntcode        NUMBER;
      vprocnt          NUMBER;
      r_no             NUMBER;
      r_pol_no         NUMBER;
      v_pol_rec        gin_policies_loading_tab
                                               := gin_policies_loading_tab
                                                                          ();
      v_pol_dtls_rec   gin_load_policy_dtls_tbl
                                               := gin_load_policy_dtls_tbl
                                                                          ();
      v_new_ipu_code   NUMBER;
      v_pol_recd       web_pol_tab              := web_pol_tab ();
      v_poll_code      NUMBER;
      v_batch_no       NUMBER;
      v_user           VARCHAR2 (30)            := 'VMUGO';
      v_exceptions     VARCHAR2 (10);
      v_policy_no      VARCHAR2 (30);
      v_pol_wef        DATE;
      v_pol_wet        DATE;
      v_rn_id          NUMBER;
      v_batchno        NUMBER;
      v_trans_no       NUMBER;
   BEGIN
/*This function create a policy  from client creation to authorization*/
      IF policytransactiontype = 'NB'
      THEN
         SELECT gin_poll_code_seq.NEXTVAL
           INTO v_poll_code
           FROM DUAL;

         INSERT INTO gin_policies_loading
                     (poll_code, poll_old_policy_no, poll_old_branch,
                      poll_old_class, poll_old_clnt_sht_desc,
                      poll_name_of_insured, poll_old_agn_sht_desc,
                      poll_cover_from, poll_cover_to, poll_renewal_date,
                      poll_risk_id, poll_cover_type, poll_sum_insured,
                      poll_premium, poll_stamp_duty, poll_training_levy,
                      poll_phcf, poll_new_policy_no, poll_new_branch,
                      poll_new_class, poll_new_clnt_sht_desc,
                      poll_new_agn_sht_desc, poll_status, poll_agn_code,
                      poll_clnt_code, poll_brn_code, poll_currency,
                      poll_cur_code, poll_pro_code, poll_ready, poll_remarks,
                      poll_load, poll_group, poll_agn_sht_desc,
                      poll_brn_sht_desc, poll_pro_sht_desc, poll_cover_wef,
                      poll_cover_wet, poll_wef, poll_wet, poll_ren_date,
                      poll_scl_code, poll_covt_code, poll_covt_sht_desc,
                      poll_scl_desc, poll_coinsurance, pol_bdiv_code,
                      poll_bind_code, poll_binder_policy, poll_date_issued,
                      poll_clnt_surname, poll_clnt_othernames,
                      poll_receipt_no, poll_dob, poll_destination,
                      poll_agn_name, poll_type, poll_brn_name,
                      poll_passport_no, poll_schengen, poll_cert_no,
                      poll_id_no, poll_pin_no, poll_postal_addr,
                      poll_res_addr, poll_postal_code, poll_email_addr,
                      poll_phone_no, poll_mobile_no
                     )
              VALUES (v_poll_code, policynumber, policybranchcode,
                      policyproduct, clientpin,
                      clientname, policyagentcode,
                      policycoverfrom, policycoverto, NULL,
                      riskid, riskcovertype, risksuminsured,
                      riskbasicpremium, policystampduty, risktraininglevy,
                      policyphcf, NULL, NULL,
                      risksubclass, NULL,
                      policyagentcode, policytransactiontype, NULL,
                      NULL, NULL, policycurrency,
                      NULL, NULL, NULL, NULL,
                      'N', NULL, NULL,
                      NULL, NULL, policycoverfrom,
                      policycoverto, policycoverfrom, policycoverto, NULL,
                      risksubclass, NULL, NULL,
                      NULL, 'N', NULL,
                      NULL, 'N', NULL,
                      clientname, NULL,
                      NULL, NULL, NULL,
                      policyagentcode, 'N', policybranchcode,
                      NULL, NULL, NULL,
                      NULL, clientpin, NULL,
                      NULL, NULL, NULL,
                      NULL, NULL
                     );

         BEGIN
            gin_loading_utilities.check_pol_data (v_poll_code,
                                                  v_user,
                                                  'Y',
                                                  FALSE,
                                                  TRUE
                                                 );
         END;