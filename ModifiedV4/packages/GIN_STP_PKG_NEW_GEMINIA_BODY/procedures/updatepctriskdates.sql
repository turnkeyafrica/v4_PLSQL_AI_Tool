PROCEDURE updatepctriskdates (v_pol_batch_no   IN NUMBER,
                                  v_wef_dt         IN DATE,
                                  v_wet_dt         IN DATE)
    IS
        v_current_ipu_code   NUMBER;
        v_pol_batch_nos      NUMBER;
    BEGIN
        -- BEGIN
        --   select   pol_batch_no  into v_pol_batch_nos  from gin_policies   where
        --    --ipu_code=v_ipu_code
        --    pol_batch_no=v_pol_batch_no
        --   -- and ipu_pol_batch_no=pol_batch_no
        --    and pol_policy_status='NB';
        --
        --    EXCEPTION WHEN OTHERS  THEN
        --    raise_error('ERROR updating current risk dates');
        --    END;
        IF v_pol_batch_no IS NOT NULL
        THEN
            UPDATE gin_insured_property_unds
               SET ipu_eff_wef = v_wef_dt, ipu_eff_wet = v_wet_dt
             WHERE ipu_pol_batch_no = v_pol_batch_nos;
        END IF;
    END;