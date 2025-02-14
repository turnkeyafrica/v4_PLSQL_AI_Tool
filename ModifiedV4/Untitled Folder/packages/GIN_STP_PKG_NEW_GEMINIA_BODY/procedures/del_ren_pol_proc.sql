PROCEDURE del_ren_pol_proc (v_pol_batch_no IN NUMBER)
    IS
        CURSOR all_pols IS
            SELECT pol_batch_no
              FROM gin_ren_policies
             WHERE pol_policy_no = (SELECT pol_policy_no
                                      FROM gin_ren_policies
                                     WHERE pol_batch_no = v_pol_batch_no);

        CURSOR all_risks_cur (vpolbatch_no IN NUMBER)
        IS
            SELECT ipu_code, pol_pro_code
              FROM gin_ren_insured_property_unds, gin_ren_policies
             WHERE     ipu_pol_batch_no = pol_batch_no
                   AND ipu_pol_batch_no = vpolbatch_no;

        v_err_msg   VARCHAR2 (200);
    BEGIN
        FOR p IN all_pols
        LOOP
            FOR all_risks_rec IN all_risks_cur (p.pol_batch_no)
            LOOP
                del_ren_risk_details (v_pol_batch_no,
                                      all_risks_rec.ipu_code,
                                      all_risks_rec.pol_pro_code,
                                      v_err_msg);
            END LOOP;

            -- Delete The Policy Details
            DELETE FROM gin_ren_policy_diary
                  WHERE pd_pol_batch_no = p.pol_batch_no;

            DELETE FROM gin_ren_policy_lvl_clauses
                  WHERE plcl_pol_batch_no = p.pol_batch_no;

            DELETE FROM gin_ren_policy_taxes
                  WHERE ptx_pol_batch_no = p.pol_batch_no;

            DELETE FROM gin_ren_coinsurers
                  WHERE coin_pol_batch_no = p.pol_batch_no;

            DELETE FROM gin_ren_policy_insureds
                  WHERE polin_pol_batch_no = p.pol_batch_no;

            DELETE FROM gin_renwl_sbudtls
                  WHERE pdl_pol_batch_no = p.pol_batch_no;

            --Delete the Policy
            DELETE FROM gin_ren_policies
                  WHERE pol_batch_no = p.pol_batch_no;
        -- gis_utilities.close_tickets ('P', p.pol_batch_no);
        END LOOP;
    END;