procedure  updatePctRiskDates(v_pol_batch_no in number,v_wef_dt in DATE, v_wet_dt in DATE) 
   is
   v_current_ipu_code NUMBER;
   v_pol_batch_nos  NUMBER;
   begin
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