PROCEDURE update_comm_details (
      v_add_edit                  in   varchar2,
      v_prc_code                  in   number,
      v_prc_group                 in   number,
      v_prc_used_rate             in   number,
      v_prc_disc_type             in   varchar2,
      v_prc_disc_rate             in   number,
      v_ipucode                   in   number
   )
   IS
   BEGIN
   --RAISE_ERROR('HERE');
    IF v_add_edit='E' THEN
    BEGIN 
    UPDATE gin_policy_risk_commissions SET
    PRC_GROUP =V_PRC_GROUP, 
    PRC_USED_RATE =V_PRC_USED_RATE, 
    PRC_DISC_TYPE =V_PRC_DISC_TYPE, 
    PRC_DISC_RATE =V_PRC_DISC_RATE
    WHERE PRC_CODE=V_PRC_CODE;
    EXCEPTION WHEN OTHERS THEN
    RAISE_ERROR('Error updating Commission Details.');
    END;