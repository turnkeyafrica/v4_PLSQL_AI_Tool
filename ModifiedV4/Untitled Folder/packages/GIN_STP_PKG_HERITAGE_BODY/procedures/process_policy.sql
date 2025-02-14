PROCEDURE process_policy (
      v_pol_data       IN       policy_tab,
      v_risks_data     IN       risk_tab,
      v_agentcontact   IN       VARCHAR2,
      v_pol_batch_no   OUT      NUMBER
   )
   IS
      v_cnt               NUMBER;
      v_new_ipu_code      NUMBER;
      v_new_polin_code    NUMBER;
      v_exp_flag          VARCHAR2 (2);
      v_uw_yr             VARCHAR2 (1);
      v_open_cover        VARCHAR2 (2);
      v_user              VARCHAR2 (35)
            := pkg_global_vars.get_pvarchar2 ('PKG_GLOBAL_VARS.PVG_USERNAME');
      v_pol_status        VARCHAR2 (5);
      v_row               NUMBER                      := 0;
      v_trans_no          NUMBER;
      v_stp_code          NUMBER;
      v_scl_desc          VARCHAR2 (75);
      v_bind_desc         VARCHAR2 (75);
      v_wet_date          DATE;
      v_pol_renewal_dt    DATE;
      v_pol_no            VARCHAR2 (45);
      v_end_no            VARCHAR2 (45);
      v_batchno           NUMBER;
      v_cur_code          NUMBER;
      v_cur_symbol        VARCHAR2 (15);
      v_cur_rate          NUMBER;
      v_pol_uwyr          NUMBER;
      v_policy_doc        VARCHAR2 (45);
      v_tran_ref_no        VARCHAR2 (45);
      v_serial             VARCHAR2 (45);
      v_endrsd_rsks_tab   gin_stp_pkg.endrsd_rsks_tab;
      v_rsk_sect_data     rsk_sect_tab;
       next_ggts_trans_no    NUMBER;  
      CURSOR rsks
      IS
         SELECT DISTINCT stpr_gis_ipu_code, stpr_action_type, stpr_stp_code,
                         stpr_property_id, stpr_desc, stpr_scl_code,
                         stpr_scl_desc, stpr_cvt_code, stpr_cvt_desc,
                         stpr_bind_code, stpr_bind_desc
                    FROM gin_risk_stp_temp_data
                   WHERE stpr_stp_code = v_stp_code;

      CURSOR rsk_limits (rsk_prp_id IN VARCHAR2)
      IS
         SELECT DISTINCT stpr_stp_code, stpr_property_id, stpr_desc,
                         stpr_scl_code, stpr_scl_desc, stpr_cvt_code,
                         stpr_cvt_desc, stpr_bind_code, stpr_bind_desc,
                         stpr_sect_code, stpr_sect_desc, stpr_limit
                    FROM gin_risk_stp_temp_data
                   WHERE stpr_stp_code = v_stp_code
                     AND stpr_property_id = rsk_prp_id;
   BEGIN
      v_user := NVL (v_agentcontact, v_user);

--raise_error ('No policy data provided..');
      SELECT gin_stp_code_seq.NEXTVAL
        INTO v_stp_code
        FROM DUAL;

      IF v_pol_data.COUNT = 0
      THEN
         raise_error ('No policy data provided..');
      END IF;

      IF v_risks_data.COUNT = 0
      THEN
         raise_error ('No Risk data provided..');
      END IF;

      DBMS_OUTPUT.put_line (1);

      FOR x IN 1 .. v_risks_data.COUNT
      LOOP
         v_scl_desc := v_risks_data (x).ipu_scl_desc;

         IF v_scl_desc IS NULL
         THEN
            SELECT scl_sht_desc
              INTO v_scl_desc
              FROM gin_sub_classes
             WHERE scl_code = v_risks_data (x).ipu_scl_code;
         END IF;

         v_bind_desc := v_risks_data (x).ipu_bind_desc;

         IF v_bind_desc IS NULL
         THEN
            SELECT bind_name
              INTO v_bind_desc
              FROM gin_binders
             WHERE bind_code = v_risks_data (x).ipu_bind_code;
         END IF;

         INSERT INTO gin_risk_stp_temp_data
                     (stpr_stp_code, stpr_property_id,
                      stpr_desc,
                      stpr_scl_code, stpr_scl_desc,
                      stpr_cvt_code,
                      stpr_cvt_desc,
                      stpr_bind_code, stpr_bind_desc,
                      stpr_sect_code,
                      stpr_sect_desc,
                      stpr_limit,
                      stpr_gis_ipu_code,
                      stpr_action_type
                     )
              VALUES (v_stp_code, v_risks_data (x).ipu_property_id,
                      v_risks_data (x).ipu_desc,
                      v_risks_data (x).ipu_scl_code, v_scl_desc,
                      v_risks_data (x).ipu_cvt_code,
                      v_risks_data (x).ipu_cvt_desc,
                      v_risks_data (x).ipu_bind_code, v_bind_desc,
                      v_risks_data (x).ipu_sect_code,
                      v_risks_data (x).ipu_sect_desc,
                      v_risks_data (x).ipu_limit,
                      v_risks_data (x).gis_ipu_code,
                      v_risks_data (x).ipu_action_type
                     );
      END LOOP;

      DBMS_OUTPUT.put_line (2);

      FOR pcount IN 1 .. v_pol_data.COUNT
      LOOP
         IF v_pol_data (pcount).pol_brn_sht_desc IS NULL
         THEN
            raise_error ('PROVIDE THE BRANCH ...');
         END IF;

         IF v_pol_data (pcount).pol_pro_code IS NULL
         THEN
            raise_error ('SELECT THE POLICY PRODUCT ...');
         END IF;

         IF v_pol_data (pcount).pol_wef_dt IS NULL
         THEN
            raise_error ('PROVIDE THE COVER FROM DATE ...');
         END IF;

         DBMS_OUTPUT.put_line (21);
         v_wet_date := v_pol_data (pcount).pol_wet_dt;

         IF v_wet_date IS NULL
         THEN
            v_wet_date :=
               get_wet_date (v_pol_data (pcount).pol_pro_code,
                             v_pol_data (pcount).pol_wef_dt
                            );
         END IF;

         DBMS_OUTPUT.put_line (22);

         IF v_wet_date IS NULL
         THEN
            raise_error ('PROVIDE THE COVER TO DATE ...');
         END IF;

         DBMS_OUTPUT.put_line (23);

         IF     NVL (v_pol_data (pcount).pol_binder_policy, 'N') = 'Y'
            AND v_pol_data (pcount).pol_bind_code IS NULL
         THEN
            raise_error ('YOU HAVE NOT DEFINED THE BORDEREAUX CODE ..');
         END IF;

         DBMS_OUTPUT.put_line (v_pol_data (pcount).pol_wef_dt);
         DBMS_OUTPUT.put_line (TO_CHAR (v_pol_data (pcount).pol_wef_dt));
         DBMS_OUTPUT.put_line
                           (TO_NUMBER (TO_CHAR (v_pol_data (pcount).pol_wef_dt,
                                                'RRRR'
                                               )
                                      )
                           );
         v_pol_uwyr :=
                  TO_NUMBER (TO_CHAR (v_pol_data (pcount).pol_wef_dt, 'RRRR'));
         /*IF v_pol_Data(pcount).POL_UW_YEAR IS NULL OR v_pol_Data(pcount).POL_UW_YEAR = 0 THEN
             RAISE_ERROR('THE UNDERWRITING YEAR MUST BE A VALID YEAR...');
         END IF;*/
         DBMS_OUTPUT.put_line (25);
         v_pol_renewal_dt :=
               get_renewal_date (v_pol_data (pcount).pol_pro_code, v_wet_date);
         v_cur_code := v_pol_data (pcount).pol_cur_code;
         v_cur_rate := v_pol_data (pcount).pol_cur_rate;

         IF v_cur_code IS NULL
         THEN
            v_cur_rate := NULL;

            BEGIN
               SELECT org_cur_code, cur_symbol
                 INTO v_cur_code, v_cur_symbol
                 FROM tqc_organizations, tqc_systems, tqc_currencies
                WHERE org_code = sys_org_code
                  AND org_cur_code = cur_code
                  AND sys_code = 37;
            EXCEPTION
               WHEN OTHERS
               THEN
                  raise_error ('UNABLE TO RETRIEVE THE BASE CURRENCY');
            END;