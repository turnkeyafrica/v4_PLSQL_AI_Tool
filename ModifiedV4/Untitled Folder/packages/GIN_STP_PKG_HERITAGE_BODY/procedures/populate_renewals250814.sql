PROCEDURE populate_renewals250814 (v_trans_id IN NUMBER, v_user VARCHAR2)
   IS
      v_pol_wet_date                 DATE;
      v_ren_polin_code               NUMBER;
      v_pol_wef                      DATE;
      --v_ren_param VARCHAR2(5);
      v_new_ipu_code                 NUMBER;
      --v_del_err NUMBER;
      v_ren_date                     DATE;
      v_cnt                          NUMBER;
      v_msg                          VARCHAR2 (200);
      v_ncd_status                   NUMBER         := 0;
      v_ncd_level                    NUMBER         := 0;
      v_max_ncd_level                NUMBER         := 0;
      v_prr_rate                     NUMBER         := 0;
      v_prr_multiplier_rate          NUMBER         := 0;
      v_prr_division_factor          NUMBER         := 0;
      v_prr_multplier_div_fact       NUMBER         := 0;
      v_sect_desc                    VARCHAR2 (30);
      v_ncd_rate                     NUMBER         := 0;
      v_process_ncd                  VARCHAR (1);
      v_old_risk                     VARCHAR (1);
      v_ncd_created                  BOOLEAN        := TRUE;
      v_sect_type                    VARCHAR2 (10);
      v_sect_sht_desc                VARCHAR2 (30);
      v_check_max                    BOOLEAN        := FALSE;
      v_new_sect_code                NUMBER;
      v_cnt_ncd                      NUMBER         := 0;
      v_new_rate                     VARCHAR2 (1);
      v_count                        NUMBER;
      v_load_sect_code               VARCHAR2 (30);
      v_decload_created              BOOLEAN        := TRUE;
      v_new_prr_rate_desc            VARCHAR2 (30);
      v_new_prr_rate_type            VARCHAR2 (30);
      v_new_prr_rate                 NUMBER;
      v_new_prr_multiplier_rate      NUMBER;
      v_new_prr_division_factor      NUMBER;
      v_new_prr_multplier_div_fact   NUMBER;
      v_new_sect_type                VARCHAR2 (30);
      v_new_sect_desc                VARCHAR2 (30);

      CURSOR cur_taxes (v_batch NUMBER, vprocode NUMBER)
      IS
         SELECT ptx_trac_scl_code, ptx_trac_trnt_code, ptx_pol_policy_no,
                ptx_pol_ren_endos_no, ptx_pol_batch_no, ptx_rate, ptx_amount,
                ptx_tl_lvl_code, ptx_rate_type, ptx_rate_desc,
                ptx_endos_diff_amt, ptx_tax_type
           FROM gin_policy_taxes, gin_transaction_types
          WHERE ptx_trac_trnt_code = trnt_code
            AND ptx_pol_batch_no = v_batch
            AND NVL (trnt_apply_rn, 'Y') = 'Y'
            AND trnt_code NOT IN (SELECT petx_trnt_code
                                    FROM gin_product_excluded_taxes
                                   WHERE petx_pro_code = vprocode);

      CURSOR renewals
      IS
         SELECT *
           FROM gin_web_renewals, gin_policies
          WHERE webr_pol_batch_no = pol_batch_no
                AND webr_trans_id = v_trans_id;

      CURSOR cur_coinsurer (v_batch NUMBER)
      IS
         SELECT *
           FROM gin_coinsurers
          WHERE coin_pol_batch_no = v_batch;

      CURSOR cur_facre_dtls (v_batch NUMBER)
      IS
         SELECT *
           FROM gin_facre_in_dtls
          WHERE fid_pol_batch_no = v_batch;

      CURSOR cur_conditions (v_batch NUMBER)
      IS
         SELECT *
           FROM gin_policy_lvl_clauses
          WHERE plcl_pol_batch_no = v_batch;

      CURSOR cur_schedule_values (v_batch NUMBER)
      IS
         SELECT *
           FROM gin_pol_schedule_values
          WHERE schpv_pol_batch_no = v_batch;

      CURSOR cur_pol_perils (v_batch NUMBER)
      IS
         SELECT *
           FROM gin_policy_section_perils
          WHERE pspr_pol_batch_no = v_batch;

      CURSOR cur_insureds (v_batch NUMBER)
      IS
         SELECT DISTINCT polin_prp_code
                    FROM gin_policy_insureds
                   WHERE EXISTS (
                            SELECT ipu_polin_code
                              FROM gin_insured_property_unds
                             WHERE ipu_polin_code = polin_code
                               AND EXISTS (
                                      SELECT polar_ipu_code
                                        FROM gin_policy_active_risks
                                       WHERE polar_ipu_code = ipu_code
                                         AND polar_pol_batch_no = v_batch));

      CURSOR cur_ipu (
         v_batch      NUMBER,
         vv_pol_wet   DATE,
         v_prp_code   NUMBER,
         v_loaded     VARCHAR2
      )
      IS
         SELECT *
           FROM gin_insured_property_unds,
                gin_policy_insureds,
                gin_sub_classes
          WHERE ipu_code IN (SELECT polar_ipu_code
                               FROM gin_policy_active_risks
                              WHERE polar_pol_batch_no = v_batch)
            --AND ipu_eff_wet = vv_pol_wet
            AND ipu_eff_wet = DECODE (v_loaded, 'N', vv_pol_wet, ipu_eff_wet)
            AND polin_code = ipu_polin_code
            AND polin_prp_code = v_prp_code
            AND NVL (ipu_endos_remove, 'N') = 'N'
            AND gin_stp_claims_pkg.claim_total_loss (ipu_id) != 'Y'
            AND ipu_sec_scl_code = scl_code;

      CURSOR cur_limits (v_ipu NUMBER)
      IS
         SELECT   *
             FROM gin_policy_insured_limits
            WHERE pil_ipu_code = v_ipu
         ORDER BY pil_code;

      CURSOR new_cur_limits (
         v_new_ipu_code   NUMBER,
         v_scl_code       NUMBER,
         v_bind_code      NUMBER,
         v_cvt_code       NUMBER,
         v_sect_code      NUMBER
      )
      IS
         SELECT DISTINCT sect_sht_desc, sect_code,
                         sect_desc || ' ' || prr_ncd_level sect_desc,
                         sect_type,
                         DECODE (sect_type,
                                 'ND', 'NCD ' || prr_ncd_level,
                                 'ES', 'Extension SI',
                                 'EL', 'Extension Limit',
                                 'SS', 'Section SI',
                                 'SL', 'Section Limit',
                                 'DS', 'Discount',
                                 'LO', 'Loading',
                                 'EC', 'Escalation'
                                ) type_desc,
                         prr_rate_type,
                         DECODE (prr_rate_type,
                                 'SRG', 0,
                                 'RCU', 0,
                                 prr_rate
                                ) prr_rate,
                         DECODE (prr_rate_type,
                                 'SRG', 0,
                                 'RCU', 0,
                                 prr_rate
                                ) rate,
                         '0' terr_description,
                         DECODE (prr_rate_type,
                                 'SRG', 0,
                                 'RCU', 0,
                                 prr_prem_minimum_amt
                                ) prr_prem_minimum_amt,
                         DECODE (prr_rate_type,
                                 'SRG', 1,
                                 'RCU', 1,
                                 prr_multiplier_rate
                                ) prr_multiplier_rate,
                         DECODE (prr_rate_type,
                                 'SRG', 1,
                                 'RCU', 1,
                                 prr_division_factor
                                ) prr_division_factor,
                         DECODE
                               (prr_rate_type,
                                'SRG', 1,
                                'RCU', 1,
                                prr_multplier_div_fact
                               ) prr_multplier_div_fact,
                         prr_rate_desc, prr_free_limit, prr_prorated_full
                    FROM gin_premium_rates, gin_sections
                   WHERE prr_sect_code = v_sect_code
                     AND prr_scl_code = v_scl_code
                     AND prr_bind_code = v_bind_code
                     AND prr_ncd_level = 0
                     AND sect_type = 'ND'
                     AND sect_code IN (
                            SELECT scvts_sect_code
                              FROM gin_subcl_covt_sections
                             WHERE scvts_scl_code = v_scl_code
                               AND scvts_covt_code = v_cvt_code)
                     AND sect_code NOT IN (
                                           SELECT pil_sect_code
                                             FROM gin_ren_policy_insured_limits
                                            WHERE pil_ipu_code =
                                                                v_new_ipu_code);

      CURSOR cur_clauses (v_ipu NUMBER)
      IS
         SELECT *
           FROM gin_policy_clauses
          WHERE pocl_ipu_code = v_ipu;

      CURSOR perils (v_ipu NUMBER)
      IS
         SELECT gpsp_per_code, gpsp_per_sht_desc, gpsp_sec_sect_code,
                gpsp_sect_sht_desc, gpsp_sec_scl_code, gpsp_ipp_code,
                gpsp_ipu_code, gpsp_limit_amt, gpsp_excess_amt
           FROM gin_pol_sec_perils
          WHERE gpsp_ipu_code = v_ipu;

      CURSOR risk_excesses (v_ipu NUMBER)
      IS
         SELECT *
           FROM gin_risk_excess
          WHERE re_ipu_code = v_ipu;

      CURSOR schedules (v_ipu NUMBER)
      IS
         SELECT *
           FROM gin_policy_risk_schedules
          WHERE polrs_ipu_code = v_ipu;
      /*CURSOR cur_superintendent
          IS SELECT *
            FROM GIN_POL_SUPERINTENDENT
            WHERE PSURT_POL_BATCH_NO=v_batch;*/
/*CURSOR cur_ncd_sec(v_scl_code NUMBER,v_bind_code NUMBER, v_level NUMBER)
                    IS SELECT DISTINCT PRR_RATE,
                    PRR_MULTIPLIER_RATE,PRR_DIVISION_FACTOR,
                    PRR_MULTPLIER_DIV_FACT
                    FROM GIN_PREMIUM_RATES,GIN_SECTIONS
                    WHERE  PRR_SECT_CODE = SECT_CODE
                    AND PRR_SCL_CODE = v_scl_code
                    AND PRR_BIND_CODE = v_bind_code
                    AND SECT_TYPE ='ND'
                    AND PRR_NCD_LEVEL =v_level;*/
   BEGIN
      -- raise_error ('User not defined.');
      IF v_user IS NULL
      THEN
         raise_error ('User not defined.');
      END IF;

      FOR pr IN renewals
      LOOP
         BEGIN
            del_ren_pol_proc (pr.pol_batch_no);
         EXCEPTION
            WHEN OTHERS
            THEN
               ROLLBACK;
               raise_error
                      ('Unable to execute procedure DEL_ALL_REN_POL_PROC ...');
         END;