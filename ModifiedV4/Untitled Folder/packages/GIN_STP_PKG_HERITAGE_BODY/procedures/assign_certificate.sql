PROCEDURE assign_certificate (
      v_ipu_code                IN       NUMBER,
      v_ct_code                 IN       NUMBER,
      v_wef_date                IN       DATE,
      v_wet_date                IN       DATE,
      v_error                   OUT      VARCHAR2,
      v_add_edit                IN       VARCHAR DEFAULT 'A',
      v_pass_no                 IN       VARCHAR2 DEFAULT NULL,
      v_tonnage                 IN       VARCHAR2 DEFAULT NULL,
      v_polc_cod                IN       NUMBER DEFAULT NULL,
      v_polc_status             IN       VARCHAR2 DEFAULT NULL,
      v_print_status            IN       VARCHAR2 DEFAULT NULL,
      v_polc_reason_cancelled   IN       VARCHAR2 DEFAULT NULL
   )
   IS
      CURSOR rsk
      IS
         SELECT ipu_code, ipu_property_id, ipu_wef, ipu_wet,
                ipu_pol_policy_no, ipu_pol_ren_endos_no, ipu_pol_batch_no,
                pol_agnt_agent_code, pol_agnt_sht_desc,
                gis_utilities.clnt_name (clnt_name, clnt_other_names)
                                                                     insured,
                ipu_covt_code, ipu_sec_scl_code, ipu_eff_wef, ipu_eff_wet,
                ipu_id, pol_brn_code, ipu_covt_sht_desc, ipu_prp_code,
                pol_uw_year, pol_policy_status, pol_binder_policy,
                pol_pro_code, ipu_prev_ipu_code, ipu_cover_suspended,
                ipu_risk_note
           FROM gin_policies,
                gin_insured_property_unds,
                gin_policy_insureds,
                tqc_clients
          WHERE ipu_pol_batch_no = pol_batch_no
            AND ipu_polin_code = polin_code
            AND polin_prp_code = clnt_code
            AND ipu_code = v_ipu_code;

      v_wef                  DATE;
      v_wet                  DATE;
      v_ct_sht_desc          VARCHAR2 (25);
      v_pol_status           VARCHAR2 (5);
      v_user                 VARCHAR2 (35)
             := pkg_global_vars.get_pvarchar2 ('PKG_GLOBAL_VARS.PVG_USERNAME');
      v_cnt                  NUMBER;
      v_polc_code            NUMBER;
      v_cert_no              VARCHAR2 (30);
      v_comp_name            VARCHAR2 (75)
                              := tqc_interfaces_pkg.organizationname (37, 'N');
      v_uw_certs             VARCHAR2 (5);
      v_cert_sht_period      NUMBER;
      v_rqrd_docs            NUMBER;
      v_ipu_eff_wet          DATE;
      v_pol_batch_no         NUMBER;
      v_pol_prem_computed    VARCHAR2 (10);
      v_pol_statusi          VARCHAR2 (10);
      v_polc_passenger_no    VARCHAR2 (10);
      v_polc_passenger_no2   VARCHAR2 (10);
      v_polc_tonnage         NUMBER;
      v_polc_pll             NUMBER;
      v_backdating_of_certs_param VARCHAR2 (1);
      v_loaded_cert number;
      v_loadedcert_no    VARCHAR2 (30);
      v_ct_type   VARCHAR2 (30);
      v_print_date date;
      v_polc_print_status  VARCHAR2 (1);
      v_polc_loaded  VARCHAR2 (1);
      v_polc_lot_id  VARCHAR2 (100);
      v_gnr_ct_sht_desc  VARCHAR2 (100);
      v_gnr_ct_code number;
   BEGIN
--RAISE_ERROR('IN');
      /*IF gin_parameters_pkg.get_param_varchar ('ALLOW_CERTIFICATE_BALANCES') =
                                                                          'N'
      THEN
         BEGIN
            SELECT ipu_pol_batch_no
              INTO v_pol_batch_no
              FROM gin_insured_property_unds
             WHERE ipu_code = v_ipu_code;

            IF gis_accounts_utilities.get_pdr_balance (v_pol_batch_no) > 0
            THEN
               v_error :=
                  'Cannot Allocate Certificate when there is pending balance';
               RETURN;
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               NULL;
         END;