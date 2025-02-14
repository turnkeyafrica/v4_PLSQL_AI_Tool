PROCEDURE gin_ipu_stp_prc (
      v_batchno        IN       NUMBER,
      v_bind_code      IN       NUMBER,
      v_property_id    IN       VARCHAR2,
      v_ipu_desc       IN       VARCHAR2,
      -- v_limit      IN      NUMBER,
      v_user           IN       VARCHAR2,
      --v_rsk_sect_data               IN   web_sect_tab,
      v_scl_code       IN       NUMBER,
      v_covt_code      IN       NUMBER,
      v_new_ipu_code   OUT      NUMBER,
      v_db_code        IN       NUMBER
   )
   IS
      v_loaded                   VARCHAR2 (1)   DEFAULT 'N';
      v_ipu_ncd_cert_no          VARCHAR2 (30)  DEFAULT NULL;
      v_del_sect                 VARCHAR2 (1)   DEFAULT NULL;
      v_cnt                      NUMBER;
      v_new_polin_code           NUMBER;
      v_uw_yr                    VARCHAR2 (1);
      v_wef_date                 DATE;
      v_wet_date                 DATE;
      v_cover_days               NUMBER;
      v_bind_name                VARCHAR2 (100);
      v_cert_no                  VARCHAR2 (35);
      v_quz_sht_desc             VARCHAR2 (35);
      --v_count                                NUMBER;
      v_uw_trans                 VARCHAR2 (1);
      v_ren_cnt                  NUMBER;
      v_ipu_prev_status          VARCHAR2 (35);
      v_ipu_prorata              VARCHAR2 (2);
      v_pol_tot_instlmt          NUMBER;
      v_pymnt_tot_instlmt        NUMBER;
      v_install_pct              NUMBER;
      v_ipu_id                   NUMBER;
      v_cer_cnt                  NUMBER;
      v_ct_code                  NUMBER;
      v_error                    VARCHAR2 (200);
      v_cer_cnt                  NUMBER;
      v_ipu_id                   NUMBER;
      v_install_period           NUMBER;
      v_polc_code                NUMBER;
      v_risk_pymt_install_pcts   VARCHAR2 (50);
      v_susp_reinst_type         VARCHAR2 (5);
      v_suspend_wef              DATE;
      v_suspend_wet              DATE;
      v_new_pol_wet              DATE;
      v_rsk_trans_type           VARCHAR2 (3);
      v_pol_instal_wet           DATE;
      v_wef                      DATE;
      v_prev_install_period      NUMBER;
      v_increment_by             NUMBER;
      v_increment                VARCHAR2 (2);
      v_interface_type           VARCHAR2 (50);
      v_cnt1                     NUMBER;
      v_risk_id_format           VARCHAR2 (50);
      v_risk_id_format_param     VARCHAR2 (50);
      v_id_reg_no                VARCHAR2 (50);
      v_clnt_pin_no              VARCHAR2 (50);
      v_ipu_covt_code            NUMBER;
      v_clnt_passport_no         VARCHAR2 (50);
      v_agent_code               NUMBER;
      v_agn_pin                  VARCHAR2 (50);
      v_max_exposure             NUMBER;
      v_pol_status               VARCHAR2 (10);
      v_enforce_covt_prem        VARCHAR2 (1);
      v_cert_autogen             VARCHAR2 (1);
      v_agnt_agent_code          NUMBER;
      v_trans_type               VARCHAR2 (5);
      v_covt_sht_desc            VARCHAR2 (20);

      CURSOR pol_cur
      IS
         SELECT gin_policies.*,
                NVL (pro_expiry_period, 'Y') pro_expiry_period,
                NVL (pol_open_cover, 'N') pro_open_cover,
                NVL (pro_earthquake, 'N') pro_earthquake,
                NVL (pro_moto_verfy, 'N') pro_moto_verfy,
                NVL (pro_stp, 'N') pro_stp
           FROM gin_policies, gin_products
          WHERE pro_code = pol_pro_code AND pol_batch_no = v_batchno;
   BEGIN
      v_trans_type := 'NB';

      SELECT bind_name
        INTO v_bind_name
        FROM gin_binders
       WHERE bind_code = v_bind_code;

--RAISE_eRROR(v_bind_code|| ' = '||v_scl_code);
--                    SELECT db_covt_code
--                      INTO v_covt_code
--                      FROM gin_binder_details
--                     WHERE db_bind_code = v_bind_code;
      SELECT covt_sht_desc
        INTO v_covt_sht_desc
        FROM gin_cover_types
       WHERE covt_code = v_covt_code;

      SELECT scl_bond_subclass
        INTO v_cert_autogen
        FROM gin_sub_classes
       WHERE scl_code = v_scl_code;

      FOR pol_cur_rec IN pol_cur
      LOOP
         IF pol_cur_rec.pol_policy_status = 'NB'
         THEN
            v_enforce_covt_prem := 'Y';
         END IF;

         IF    NVL (pol_cur_rec.pol_binder_policy, 'N') = 'Y'
            OR NVL (pol_cur_rec.pro_open_cover, 'N') = 'Y'
         THEN
            v_uw_yr := 'R';
         ELSE
            v_uw_yr := 'P';
         END IF;
         
         SELECT DB_MAX_LIMIT INTO v_max_exposure
         FROM GIN_BINDER_DETAILS
         WHERE DB_CODE = v_db_code;

         v_wef_date := pol_cur_rec.pol_policy_cover_from;
         v_wet_date := pol_cur_rec.pol_policy_cover_to;
         -- raise_error(pol_cur_rec.pol_policy_cover_from||' = '||pol_cur_rec.pol_policy_cover_to);
         v_wef := v_wef_date;

         BEGIN
            IF v_pol_instal_wet != pol_cur_rec.pol_paid_to_date
            THEN
               UPDATE gin_policies
                  SET pol_paid_to_date = v_pol_instal_wet
                WHERE pol_batch_no = v_batchno;
            END IF;
         END;

         BEGIN
            SELECT COUNT (1)
              INTO v_cnt
              FROM gin_policy_insureds
             WHERE polin_pol_batch_no = v_batchno
               AND polin_prp_code = pol_cur_rec.pol_prp_code;
         EXCEPTION
            WHEN OTHERS
            THEN
               raise_error ('Error checking if insured already exists');
         END;

         IF NVL (v_cnt, 0) = 0
         THEN
            BEGIN
               SELECT    TO_NUMBER (TO_CHAR (SYSDATE, 'RRRR'))
                      || polin_code_seq.NEXTVAL
                 INTO v_new_polin_code
                 FROM DUAL;

               INSERT INTO gin_policy_insureds
                           (polin_code, polin_pol_policy_no,
                            polin_pol_ren_endos_no, polin_pol_batch_no,
                            polin_prp_code, polin_new_insured
                           )
                    VALUES (v_new_polin_code, pol_cur_rec.pol_policy_no,
                            pol_cur_rec.pol_ren_endos_no, v_batchno,
                            pol_cur_rec.pol_prp_code, 'Y'
                           );
            EXCEPTION
               WHEN OTHERS
               THEN
                  raise_error ('ERROR SAVING INSURED DETAILS..');
            END;
         ELSE
            BEGIN
               SELECT polin_code
                 INTO v_new_polin_code
                 FROM gin_policy_insureds
                WHERE polin_pol_batch_no = v_batchno
                  AND polin_prp_code = pol_cur_rec.pol_prp_code;
            EXCEPTION
               WHEN OTHERS
               THEN
                  raise_error ('ERROR CHECKING IF INSURED ALREADY EXISTS');
            END;
         END IF;

         v_ipu_prorata := 'P';       -- NVL (v_ipu_data (i).ipu_prorata, 'P');

         IF v_wef_date NOT BETWEEN pol_cur_rec.pol_policy_cover_from
                               AND pol_cur_rec.pol_policy_cover_to
         THEN
            raise_error
               (   'THE RISK COVER DATES PROVIDED MUST BE WITHIN THE POLICY COVER PERIODS. '
                || pol_cur_rec.pol_policy_cover_from
                || ' TO '
                || pol_cur_rec.pol_policy_cover_to
               );
         END IF;

         IF v_wet_date NOT BETWEEN pol_cur_rec.pol_policy_cover_from
                               AND pol_cur_rec.pol_policy_cover_to
         THEN
            raise_error
               (   'THE RISK COVER DATES PROVIDED MUST BE WITHIN THE POLICY COVER PERIODS. '
                || pol_cur_rec.pol_policy_cover_from
                || ' TO '
                || pol_cur_rec.pol_policy_cover_to
               );
         END IF;

         BEGIN
            SELECT    TO_NUMBER (TO_CHAR (SYSDATE, 'RRRR'))
                   || gin_ipu_code_seq.NEXTVAL
              INTO v_new_ipu_code
              FROM DUAL;

            INSERT INTO gin_schedule_mapping
                 VALUES (v_new_ipu_code, NULL, v_batchno);

            -- raise_Error('7777v_batch_no='||v_batchno);
            INSERT INTO gin_insured_property_unds
                        (ipu_code, ipu_property_id,
                         ipu_item_desc, ipu_qty, ipu_value, ipu_wef, ipu_wet,
                         ipu_pol_policy_no,
                         ipu_pol_ren_endos_no, ipu_pol_batch_no,
                         ipu_earth_quake_cover, ipu_earth_quake_prem,
                         ipu_location, ipu_polin_code, ipu_sec_scl_code,
                         ipu_ncd_status, ipu_related_ipu_code, ipu_prorata,
                         ipu_gp, ipu_fap, ipu_prev_ipu_code, ipu_ncd_level,
                         ipu_quz_code, ipu_quz_sht_desc, ipu_sht_desc,
                         ipu_id,
                         ipu_bind_code, ipu_excess_rate, ipu_excess_type,
                         ipu_excess_rate_type, ipu_excess_min,
                         ipu_excess_max, ipu_prereq_ipu_code,
                         ipu_escalation_rate, ipu_comm_rate,
                         ipu_prev_batch_no, ipu_cur_code, ipu_relr_code,
                         ipu_relr_sht_desc, ipu_pol_est_max_loss,
                         ipu_eff_wef, ipu_eff_wet, ipu_retro_cover,
                         ipu_retro_wef, ipu_covt_code, ipu_covt_sht_desc,
                         ipu_si_diff, ipu_terr_code, ipu_terr_desc,
                         ipu_from_time, ipu_to_time, ipu_mar_cert_no,
                         ipu_comp_retention, ipu_gross_comp_retention,
                         ipu_com_retention_rate, ipu_prp_code,
                         ipu_tot_endos_prem_dif, ipu_tot_gp, ipu_tot_value,
                         ipu_ri_agnt_com_rate, ipu_cover_days, ipu_bp,
                         ipu_prev_prem, ipu_ri_agnt_comm_amt, ipu_tot_fap,
                         ipu_max_exposure, ipu_status,
                         ipu_uw_yr,
                         ipu_tot_first_loss, ipu_accumulation_limit,
                         ipu_compute_max_exposure, ipu_reinsure_amt,
                         ipu_paid_premium, ipu_trans_count, ipu_paid_tl,
                         ipu_inception_uwyr,
                         ipu_trans_eff_wet, ipu_eml_based_on,
                         ipu_aggregate_limits, ipu_rc_sht_desc, ipu_rc_code,
                         ipu_survey_date, ipu_item_details, ipu_prev_tot_fap,
                         ipu_prev_fap, ipu_prev_reinsure_amt, ipu_free_limit,
                         ipu_fp, ipu_conveyance_type, ipu_endose_fap_or_bc,
                         ipu_mktr_com_rate, ipu_prev_status, ipu_ncd_cert_no,
                         ipu_install_period, ipu_pymt_install_pcts,
                         ipu_susp_reinstmt_type, ipu_cover_suspended,
                         ipu_suspend_wef, ipu_suspend_wet, ipu_rs_code,
                         ipu_rescue_mem, ipu_rescue_charge,
                         ipu_post_retro_wet, ipu_post_retro_cover,
                         ipu_previous_insurer, ipu_enforce_cvt_min_prem,
                         ipu_eml_si, ipu_db_code
                        )
                 VALUES (TO_NUMBER (v_new_ipu_code),               --IPU_CODE,
                                                    v_property_id,
                         --IPU_PROPERTY_ID,
                         v_ipu_desc,                          --IPU_ITEM_DESC,
                                    NULL,                           --IPU_QTY,
                                         NULL,
                                              --IPU_VALUE,
                                              v_wef_date,           --IPU_WEF,
                                                         v_wet_date,
                         --IPU_WET,
                         pol_cur_rec.pol_policy_no,
                         --IPU_POL_POLICY_NO,
                         pol_cur_rec.pol_ren_endos_no,
                                                      --IPU_POL_REN_ENDOS_NO,
                                                      v_batchno,
                         --IPU_POL_BATCH_NO,
                         NULL,                        --IPU_EARTH_QUAKE_COVER,
                              NULL,                    --IPU_EARTH_QUAKE_PREM,
                         NULL,         --     v_ipu_data (i).ipu_risk_address,
                              --IPU_LOCATION,
                              v_new_polin_code,              --IPU_POLIN_CODE,
                                               v_scl_code,
                         --IPU_SEC_SCL_CODE,
                         NULL,                --v_ipu_data (i).ipu_ncd_status,
                              --IPU_NCD_STATUS,
                         NULL,
                              --IPU_RELATED_IPU_CODE,
                              v_ipu_prorata,
                         --IPU_PRORATA,
                         NULL,                                       --IPU_GP,
                              NULL,                                 --IPU_FAP,
                                   TO_NUMBER (v_new_ipu_code),
                                                              --ipu_prev_ipu_code,
                         NULL,  --v_ipu_data (i).ipu_ncd_lvl, --IPU_NCD_LEVEL,
                         NULL,  --v_ipu_data (i).ipu_quz_code, --IPU_QUZ_CODE,
                              NULL,
                                   --v_quz_sht_desc,          --IPU_QUZ_SHT_DESC,
                         NULL,                                 --IPU_SHT_DESC,
                            TO_NUMBER (TO_CHAR (SYSDATE, 'RRRR'))
                         || gin_ipu_id_seq.NEXTVAL,                  --IPU_ID,
                         v_bind_code,
                                     -- THIS IS ONLY APPLICABLE FOR BINDER POLICIES. CHECK THE BINDER LOV ON UND_QUERY TO ADD