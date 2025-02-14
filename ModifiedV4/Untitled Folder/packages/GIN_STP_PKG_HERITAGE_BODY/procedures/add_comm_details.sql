PROCEDURE add_comm_details (
      v_trans_code                  in   varchar2,
      v_trnt_code                 in   varchar2,
      v_ipucode                   in   number
   )
   IS
   V_POL_BATCH_NO               NUMBER;
   V_POL_AGNT_AGENT_CODE        NUMBER;
   V_BIND_LTA_TYPE              VARCHAR(1);
   V_BIND_COMM_TYPE             VARCHAR(1);
   V_AGN_ACT_CODE               NUMBER;
   V_TYPE                       NUMBER;
   v_count                      number;
BEGIN

    BEGIN
    SELECT 
    POL_BATCH_NO,POL_AGNT_AGENT_CODE,BIND_LTA_TYPE,BIND_COMM_TYPE,AGN_ACT_CODE 
    INTO
    V_POL_BATCH_NO,V_POL_AGNT_AGENT_CODE,V_BIND_LTA_TYPE,V_BIND_COMM_TYPE,V_AGN_ACT_CODE
    FROM GIN_POLICIES, GIN_INSURED_PROPERTY_UNDS,GIN_BINDERS,tqc_agencies
    WHERE POL_BATCH_NO=IPU_POL_BATCH_NO
    AND IPU_CODE=v_ipucode
    AND AGN_CODE=POL_AGNT_AGENT_CODE
    AND IPU_BIND_CODE=BIND_CODE;
    EXCEPTION WHEN OTHERS THEN
    RAISE_ERROR('Error fetching policy details ' );
    END;