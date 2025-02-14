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
    
    BEGIN
    SELECT DECODE(DECODE(v_trnt_code,'LTA-U',V_BIND_LTA_TYPE,V_BIND_COMM_TYPE),'B',1,2) ORDER_TYPE INTO V_TYPE FROM DUAL;
    EXCEPTION WHEN OTHERS THEN 
    RAISE_ERROR('Error fetching binder details ');
    END;
    
    BEGIN
    select count(*) into v_count from gin_policy_risk_commissions 
    where PRC_IPU_CODE=v_ipucode
    and  PRC_TRANS_CODE=v_trans_code
    and PRC_TRNT_CODE=v_trnt_code;
    EXCEPTION WHEN no_data_found THEN 
    v_count:=0;
     WHEN others THEN 
    RAISE_ERROR('Error fetching commission details ');
    END;
   IF (V_POL_AGNT_AGENT_CODE !=0) THEN
   IF v_count=0 THEN
    BEGIN
                insert into gin_policy_risk_commissions
                (prc_code, prc_ipu_code, prc_pol_batch_no, 
                prc_agn_code, prc_trans_code, prc_act_code, 
                prc_trnt_code,prc_group)
                values
                (tq_gis.prc_code_seq.nextval,v_ipucode,V_POL_BATCH_NO,
                V_POL_AGNT_AGENT_CODE,v_trans_code,V_AGN_ACT_CODE,
                v_trnt_code,V_TYPE
                );
    EXCEPTION WHEN OTHERS THEN 
    RAISE_ERROR('Error inserting commission Details. ');
    END;
    ELSE 
    RAISE_ERROR('Commission type already exists ');
    END IF;
  ELSE
  RAISE_ERROR('Commission not applicable to direct bussiness.');
  END IF;
  END;