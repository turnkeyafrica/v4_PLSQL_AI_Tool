```sql
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

        SELECT    TO_NUMBER (TO_CHAR (SYSDATE, 'RRRR'))
               || gin_itb_code_seq.NEXTVAL
          INTO v_itb_code
          FROM DUAL;

        BEGIN
            SELECT SUM (
                       DECODE (mtran_dc,
                               'D', ABS (mtran_balance),
                               -ABS (mtran_balance)))
              INTO v_balance
              FROM gin_master_transactions
             WHERE     mtran_pol_batch_no = v_pol_batch_no
                   AND mtran_tran_type IN ('RC', 'CN')
                   AND mtran_balance <> 0;
        EXCEPTION
            WHEN OTHERS
            THEN
                raise_error ('Error fetching receipts on this renewal...');
        END;

        --  RAISE_ERROR('HERE='||v_balance||';'||v_endos_prem);
        IF ABS (v_balance) >= v_endos_prem
        THEN
            transfer_to_uw (v_pol_batch_no, v_user, v_batch_no);

            BEGIN
                SELECT ggt_trans_no
                  INTO v_trans_no
                  FROM gin_gis_transactions
                 WHERE     ggt_uw_clm_tran = 'U'
                       AND ggt_pol_batch_no = v_batch_no;
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error ('Error retrieving transaction number..');
            END;

            BEGIN
                gin_compute_prem_pkg.compute_premium (v_batch_no);
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error ('ERROR COMPUTING PREMIUM.');
            END;

            --COMMIT;
            BEGIN
                UPDATE gin_insured_property_unds
                   SET ipu_reinsured = 1
                 WHERE ipu_pol_batch_no = v_batch_no;
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error ('Error updating risk as reinsurance ready.');
            END;

            BEGIN
                UPDATE gin_master_transactions
                   SET mtran_pol_batch_no = v_batch_no
                 WHERE     mtran_pol_batch_no = v_pol_batch_no
                       AND mtran_tran_type IN ('RC', 'CN')
                       AND mtran_balance <> 0;
            EXCEPTION
                WHEN OTHERS
                THEN
                    NULL;
            END;

            --COMMIT;
            BEGIN
                gis_ri_pkg.gis_ri_prc(v_batch_no,v_itb_code);
            END;

        END IF;
    END;
/

```