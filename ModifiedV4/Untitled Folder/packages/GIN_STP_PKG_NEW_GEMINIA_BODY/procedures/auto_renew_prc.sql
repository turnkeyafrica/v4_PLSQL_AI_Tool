PROCEDURE auto_renew_prc (v_renewal_batch IN NUMBER)
    IS
        v_endos_prem      NUMBER;
        v_pol_batch_no    NUMBER;
        v_user            VARCHAR2 (30);
        v_batch_no        NUMBER;
        v_balance         NUMBER;
        v_trans_no        NUMBER;
        v_cr_bal          NUMBER;
        v_cr_com          NUMBER;
        v_mtran_dr_no     NUMBER;
        v_com_inclusive   VARCHAR2 (1) := 'N';
        v_itb_code        NUMBER;

        CURSOR rcpt IS
            SELECT *
              FROM gin_master_transactions
             WHERE mtran_pol_batch_no = v_batch_no AND mtran_balance <> 0;
    BEGIN
        -- RAISE_ERROR(v_renewal_batch);
        BEGIN
            SELECT pol_tot_endos_diff_amt, pol_batch_no, pol_prepared_by
              INTO v_endos_prem, v_pol_batch_no, v_user
              FROM gin_ren_policies
             WHERE pol_renewal_batch = v_renewal_batch;
        EXCEPTION
            WHEN OTHERS
            THEN
                raise_error ('Error fetching renewal record....');
        END;