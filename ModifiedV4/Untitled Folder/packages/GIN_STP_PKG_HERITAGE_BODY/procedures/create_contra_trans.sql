PROCEDURE create_contra_trans (v_old_batch   IN     NUMBER,
                                   v_batch_no       OUT NUMBER,
                                   v_user        IN     VARCHAR2,
                                   v_eff_date    IN     DATE)
    IS
        v_serial            NUMBER (10);
        v_pol_no            VARCHAR2 (26);
        v_ends_no           VARCHAR2 (26);
        --next_ggt_trans_no number;
        v_pol_prefix        VARCHAR2 (15);
        v_new_ipu_code      NUMBER;
        vdummy              NUMBER;
        v_tran_no           NUMBER;
        v_prrd_code         NUMBER;
        v_pdl_code          NUMBER;
        v_part_prxrd_code   NUMBER;
        v_count_contra      NUMBER;

        CURSOR cur_pol IS
            SELECT *
              FROM gin_policies
             WHERE pol_batch_no = v_old_batch;

        CURSOR cur_taxes IS
            SELECT *
              FROM gin_policy_taxes
             WHERE ptx_pol_batch_no = v_old_batch;

        CURSOR cur_coinsurer IS
            SELECT *
              FROM gin_coinsurers
             WHERE coin_pol_batch_no = v_old_batch;

        CURSOR cur_facre_dtls IS
            SELECT *
              FROM gin_facre_in_dtls
             WHERE fid_pol_batch_no = v_old_batch;

        CURSOR cur_conditions IS
            SELECT *
              FROM gin_policy_lvl_clauses
             WHERE plcl_pol_batch_no = v_old_batch;

        CURSOR cur_insureds IS
            SELECT *
              FROM gin_policy_insureds
             WHERE polin_pol_batch_no = v_old_batch;

        CURSOR cur_ipu (v_polin_code NUMBER)
        IS
            SELECT *
              FROM gin_insured_property_unds
             WHERE     ipu_pol_batch_no = v_old_batch
                   AND ipu_polin_code = v_polin_code;

        CURSOR cur_rsk_perils (v_ipu VARCHAR2)
        IS
            SELECT *
              FROM gin_pol_risk_section_perils
             WHERE prspr_ipu_code = v_ipu;

        CURSOR cur_limits (v_ipu NUMBER)
        IS
            SELECT *
              FROM gin_policy_insured_limits
             WHERE pil_ipu_code = v_ipu;

        CURSOR cur_riskcommissions (v_ipu NUMBER)
        IS
            SELECT *
              FROM gin_policy_risk_commissions
             WHERE prc_ipu_code = v_ipu;

        CURSOR cur_clauses (v_ipu NUMBER)
        IS
            SELECT *
              FROM gin_policy_clauses
             WHERE pocl_ipu_code = v_ipu;

        CURSOR perils (v_ipu NUMBER)
        IS
            SELECT gpsp_per_code,
                   gpsp_per_sht_desc,
                   gpsp_sec_sect_code,
                   gpsp_sect_sht_desc,
                   gpsp_sec_scl_code,
                   gpsp_ipp_code,
                   gpsp_ipu_code,
                   gpsp_limit_amt,
                   gpsp_excess_amt
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

        CURSOR cur_prrd (v_cur_prrd NUMBER)
        IS
            SELECT *
              FROM gin_policy_risk_ri_dtls
             WHERE prrd_code = v_cur_prrd;

        CURSOR cur_facre (v_prrd NUMBER)
        IS
            SELECT *
              FROM gin_facre_cessions
             WHERE fc_prrd_code = v_prrd;

        CURSOR cur_pool (v_prrd NUMBER)
        IS
            SELECT *
              FROM gin_pol_rein_pool_risk_details
             WHERE prprd_prrd_code = v_prrd;

        CURSOR cur_rein (v_prrd NUMBER)
        IS
            SELECT *
              FROM gin_policy_rein_risk_details
             WHERE ptotr_prrd_code = v_prrd;

        CURSOR cur_part (v_ptotr NUMBER)
        IS
            SELECT *
              FROM gin_participations
             WHERE part_ptotr_code = v_ptotr;

        CURSOR cur_rcpt IS
            SELECT *
              FROM gin_prem_receipts
             WHERE prm_pol_batch_no = v_old_batch;

        CURSOR cur_pol_sbu_dtls IS
            SELECT *
              FROM gin_policy_sbu_dtls
             WHERE pdl_pol_batch_no = v_old_batch;

        CURSOR cur_xol (v_prrd NUMBER)
        IS
            SELECT *
              FROM GIN_POL_REIN_XOL_RISK_DETAILS
             WHERE PRXRD_prrd_code = v_prrd;

        CURSOR curxol_participants (v_ptotr NUMBER)
        IS
            SELECT *
              FROM gin_xol_participations
             WHERE XPART_PRXRD_CODE = v_ptotr;
    BEGIN

        IF v_old_batch IS NULL
        THEN
            raise_error ('Select old transaction!!...');
        END IF;

        IF v_user IS NULL
        THEN
            raise_error ('User not defined.');
        END IF;

        FOR cur_pol_rec IN cur_pol
        LOOP
            --         IF     NVL (cur_pol_rec.pol_reinsured, 'N') != 'Y'
            --            AND NVL (cur_pol_rec.pol_loaded, 'N') = 'N'
            --            AND tqc_interfaces_pkg.get_org_type (37) = 'INS'
            --         THEN
            --            raise_error
            --               ('Reinsurance for the previous transaction on this policy has not been performed/Authorised. Cannot continue..'
            --               );
            --         END IF;  One of the main rasons for doing a contra is to reverse the old transaction so there is no need of this check
            BEGIN
                SELECT COUNT ('X')
                  INTO vdummy
                  FROM gin_claim_master_bookings
                 WHERE     cmb_pol_batch_no = v_old_batch
                       AND NVL (cmb_claim_status, 'B') NOT IN ('U', 'N');
            --AND (cmb_claim_status != 'U' OR cmb_claim_status != 'N');
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error (
                        'Error checking claim on the transaction to contra..');
            END;