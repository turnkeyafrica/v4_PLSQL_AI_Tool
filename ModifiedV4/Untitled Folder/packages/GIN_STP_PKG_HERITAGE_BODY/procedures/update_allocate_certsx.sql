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