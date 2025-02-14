PROCEDURE transfer_to_uw_21052019 (
   v_pol_batch_no   IN       NUMBER,
   v_user           IN       VARCHAR2,
   v_batch_no       OUT      NUMBER
)
IS
   v_pol_no                      VARCHAR2 (26);
   v_ends_no                     VARCHAR2 (26);
   next_ggt_trans_no             NUMBER;
   v_endos_sr                    NUMBER (15);
   v_pol_prefix                  VARCHAR2 (15);
   v_new_ipu_code                NUMBER;
   v_pol_status                  VARCHAR2 (5);
   v_pmode_code                  NUMBER;
   v_base_cur_code               NUMBER;
   v_cnt                         NUMBER;
   v_dates_error                 VARCHAR2 (200);
   v_endos_count                 NUMBER;
   v_curr_batch_no               NUMBER;
   v_pro_sht_desc                VARCHAR2 (50);
   v_noyrstautoradclient_param   NUMBER;
   v_auto_grad_clnt_param        VARCHAR2 (1)   := 'N';
   v_renewal_cnt                 NUMBER;
   next_ggts_trans_no            NUMBER;
   v_rn_cnt                      NUMBER;
   v_pdl_code                    NUMBER;
   v_re_cnt                      NUMBER;
   v_count                       NUMBER;
   v_agent_code                  NUMBER;
   v_agents_status               VARCHAR (15);

   CURSOR cur_taxes (v_batch NUMBER, vtranstype VARCHAR2, vprocode NUMBER)
   IS
      SELECT ptx_trac_scl_code, ptx_trac_trnt_code, ptx_pol_policy_no,
             ptx_pol_ren_endos_no, ptx_pol_batch_no, ptx_rate, ptx_amount,
             ptx_tl_lvl_code, ptx_rate_type, ptx_rate_desc,
             ptx_endos_diff_amt, ptx_tax_type
        FROM gin_ren_policy_taxes, gin_transaction_types
       WHERE ptx_trac_trnt_code = trnt_code
         AND ptx_pol_batch_no = v_batch
         AND NVL (DECODE (vtranstype,
                          'NB', trnt_apply_nb,
                          'SP', trnt_apply_sp,
                          'RN', trnt_apply_rn,
                          'EN', trnt_apply_en,
                          'CN', trnt_apply_cn,
                          'EX', trnt_apply_ex,
                          'DC', trnt_apply_dc,
                          'RE', trnt_apply_re
                         ),
                  'N'
                 ) = 'Y'
         AND trnt_code NOT IN (SELECT petx_trnt_code
                                 FROM gin_product_excluded_taxes
                                WHERE petx_pro_code = vprocode);

   --TRNT_RENEWAL_ENDOS != 'N';
   CURSOR cur_coinsurer (v_batch NUMBER)
   IS
      SELECT *
        FROM gin_ren_coinsurers
       WHERE coin_pol_batch_no = v_batch;

   CURSOR cur_facre_dtls (v_batch NUMBER)
   IS
      SELECT *
        FROM gin_ren_facre_in_dtls
       WHERE fid_pol_batch_no = v_batch;

   CURSOR cur_conditions (v_batch NUMBER)
   IS
      SELECT *
        FROM gin_ren_policy_lvl_clauses
       WHERE plcl_pol_batch_no = v_batch;

   CURSOR cur_schedule_values (v_batch NUMBER)
   IS
      SELECT *
        FROM gin_ren_pol_schedule_values
       WHERE schpv_pol_batch_no = v_batch;

   CURSOR cur_pol_perils (v_batch NUMBER)
   IS
      SELECT *
        FROM gin_ren_policy_section_perils
       WHERE pspr_pol_batch_no = v_batch;

   CURSOR cur_insureds (v_batch NUMBER)
   IS
      SELECT *
        FROM gin_ren_policy_insureds
       WHERE polin_pol_batch_no = v_batch;

   CURSOR cur_ipu (v_batch NUMBER, v_polin_code NUMBER)
   IS
      SELECT *
        FROM gin_ren_insured_property_unds
       WHERE ipu_pol_batch_no = v_batch AND ipu_polin_code = v_polin_code;

   CURSOR cur_limits (v_ipu NUMBER)
   IS
      SELECT   *
          FROM gin_ren_policy_insured_limits
         WHERE pil_ipu_code = v_ipu
      ORDER BY pil_code, pil_calc_group, pil_row_num;

   CURSOR cur_clauses (v_ipu NUMBER)
   IS
      SELECT *
        FROM gin_ren_policy_clauses
       WHERE pocl_ipu_code = v_ipu;

   CURSOR cur_rsk_perils (v_ipu VARCHAR2)
   IS
      SELECT *
        FROM tq_gis.gin_pol_ren_rsk_section_perils
       WHERE prspr_ipu_code = v_ipu;

   CURSOR perils (v_ipu NUMBER)
   IS
      SELECT gpsp_per_code, gpsp_per_sht_desc, gpsp_sec_sect_code,
             gpsp_sect_sht_desc, gpsp_sec_scl_code, gpsp_ipp_code,
             gpsp_ipu_code, gpsp_limit_amt, gpsp_excess_amt
        FROM gin_ren_pol_sec_perils
       WHERE gpsp_ipu_code = v_ipu;

   CURSOR risk_excesses (v_ipu NUMBER)
   IS
      SELECT *
        FROM gin_ren_risk_excess
       WHERE re_ipu_code = v_ipu;

   CURSOR schedules (v_ipu NUMBER)
   IS
      SELECT *
        FROM gin_ren_policy_risk_schedules
       WHERE polrs_ipu_code = v_ipu;

   CURSOR pol
   IS
      SELECT gin_ren_policies.*, 'Y' pol_pop_taxes
        FROM gin_ren_policies
       WHERE pol_batch_no = v_pol_batch_no;

   CURSOR cur_coagencies
   IS
      SELECT *
        FROM gin_policy_coagencies
       WHERE coagn_pol_batch_no = v_pol_batch_no;

  /* CURSOR cur_rcpt
   IS
      SELECT *
        FROM gin_master_transactions
       WHERE mtran_pol_batch_no = v_pol_batch_no
         AND mtran_tran_type = 'RC'
         AND mtran_balance <> 0;*/

          CURSOR cur_rcpt
   IS
      SELECT gin_master_transactions.*
        FROM gin_master_transactions,gin_gis_transmitals
       WHERE mtran_tran_type = 'RC'
         AND mtran_pol_batch_no = v_pol_batch_no
      --  AND ggts_pol_renewal_batch=p.pol_renewal_batch
         AND ggts_pol_batch_no=mtran_pol_batch_no
         AND  ggts_uw_clm_tran = 'RN'
         AND mtran_balance = mtran_net_amt;
        
   CURSOR pol_dtls
   IS
      SELECT *
        FROM gin_renwl_sbudtls
       WHERE pdl_pol_batch_no = v_pol_batch_no;

   CURSOR risk_services (v_ipu NUMBER)
   IS
      SELECT *
        FROM gin_policy_ren_risk_services
       WHERE prs_ipu_code = v_ipu;

--
--      CURSOR cur_other_rn_trans (v_pol_policy_no IN VARCHAR2, v_uw_yr IN NUMBER)
--      IS
--         SELECT   pol_policy_cover_to, pol_policy_cover_from
--             FROM gin_policies
--            WHERE pol_batch_no = v_pol_batch_no;
--              AND pol_uw_year = v_uw_yr
--              AND pol_current_status != 'CO'
--         ORDER BY pol_wef_dt;
BEGIN
   --RAISE_ERROR('I');
   IF v_user IS NULL
   THEN
      raise_error ('User not defined.');
   END IF;

   v_dates_error :=
                  gin_uw_author_proc.check_ren_pol_coverdates (v_pol_batch_no);

   IF v_dates_error IS NOT NULL
   THEN
      raise_error (v_dates_error);
   END IF;

   FOR p IN pol
   LOOP
      BEGIN
         v_auto_grad_clnt_param :=
                gin_parameters_pkg.get_param_varchar ('AUTO_GRADUATE_CLIENT');
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_auto_grad_clnt_param := 'N';
         WHEN OTHERS
         THEN
            raise_error ('Error getting parameter AUTO_GRADUATE_CLIENT');
      END;