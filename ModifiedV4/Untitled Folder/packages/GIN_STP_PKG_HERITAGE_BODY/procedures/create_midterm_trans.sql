PROCEDURE create_midterm_trans (
      v_old_batch   IN       NUMBER,
      v_batch_no    OUT      NUMBER,
      v_user        IN       VARCHAR2,
      v_eff_date    IN       DATE
   )
   IS
      v_serial             NUMBER (10);
      v_pol_no             VARCHAR2 (26);
      v_ends_no            VARCHAR2 (26);
      v_pol_prefix         VARCHAR2 (15);
      v_new_ipu_code       NUMBER;
      vdummy               NUMBER;
      v_tran_no            NUMBER;
      v_prrd_code          NUMBER;
      v_wef                DATE;
      v_wet                DATE;
      v_ren_date           DATE;
      v_year               NUMBER;
      next_ggts_trans_no   NUMBER;
      v_serialno           VARCHAR2 (26);
      v_tran_ref_no        VARCHAR2 (26); 

      CURSOR cur_pol
      IS
         SELECT *
           FROM gin_policies
          WHERE pol_batch_no = v_old_batch;

      CURSOR cur_taxes
      IS
         SELECT *
           FROM gin_policy_taxes
          WHERE ptx_pol_batch_no = v_old_batch
            AND NVL (ptx_trac_trnt_code, 'XX') != 'SD';

      CURSOR cur_coinsurer
      IS
         SELECT *
           FROM gin_coinsurers
          WHERE coin_pol_batch_no = v_old_batch;

      CURSOR cur_facre_dtls
      IS
         SELECT *
           FROM gin_facre_in_dtls
          WHERE fid_pol_batch_no = v_old_batch;

      CURSOR cur_conditions
      IS
         SELECT *
           FROM gin_policy_lvl_clauses
          WHERE plcl_pol_batch_no = v_old_batch;

      CURSOR cur_insureds
      IS
         SELECT *
           FROM gin_policy_insureds
          WHERE polin_pol_batch_no = v_old_batch;

      CURSOR cur_ipu (v_polin_code NUMBER)
      IS
         SELECT *
           FROM gin_insured_property_unds
          WHERE ipu_pol_batch_no = v_old_batch
            AND ipu_polin_code = v_polin_code;

      CURSOR cur_limits (v_ipu NUMBER)
      IS
         SELECT *
           FROM gin_policy_insured_limits
          WHERE pil_ipu_code = v_ipu;

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
   BEGIN
--      raise_error ('v_old_batch' || v_old_batch);

      IF v_user IS NULL
      THEN
         raise_error ('User not defined.');
      END IF;

      FOR cur_pol_rec IN cur_pol
      LOOP
         IF     NVL (cur_pol_rec.pol_reinsured, 'N') != 'Y'
            AND NVL (cur_pol_rec.pol_loaded, 'N') = 'N'
            AND tqc_interfaces_pkg.get_org_type (37) = 'INS'
         THEN
            raise_error
               ('Reinsurance for the previous transaction on this policy has not been performed/Authorised. Cannot continue..'
               );
         END IF;

         BEGIN
            SELECT pro_policy_prefix
              INTO v_pol_prefix
              FROM gin_products
             WHERE pro_code = cur_pol_rec.pol_pro_code;

            IF v_pol_prefix IS NULL
            THEN
               ROLLBACK;
               raise_error (   'The policy prefix for the product '
                            || cur_pol_rec.pol_pro_sht_desc
                            || ' is not defined in the setup'
                           );
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               ROLLBACK;
               raise_error (   'The product '
                            || cur_pol_rec.pol_pro_sht_desc
                            || ' is not defined in the setup'
                           );
            WHEN OTHERS
            THEN
               ROLLBACK;
               raise_error
                  (   'Unable to retrieve the policy prefix for the product '
                   || cur_pol_rec.pol_pro_sht_desc
                  );
         END;