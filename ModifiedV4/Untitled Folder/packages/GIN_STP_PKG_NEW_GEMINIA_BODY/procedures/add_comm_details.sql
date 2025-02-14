PROCEDURE add_comm_details (v_trans_code   IN VARCHAR2,
                                v_trnt_code    IN VARCHAR2,
                                v_ipucode      IN NUMBER)
    IS
        v_pol_batch_no          NUMBER;
        v_pol_agnt_agent_code   NUMBER;
        v_bind_lta_type         VARCHAR (1);
        v_bind_comm_type        VARCHAR (1);
        v_agn_act_code          NUMBER;
        v_type                  NUMBER;
        v_count                 NUMBER;
    BEGIN
        BEGIN
            SELECT pol_batch_no,
                   pol_agnt_agent_code,
                   bind_lta_type,
                   bind_comm_type,
                   agn_act_code
              INTO v_pol_batch_no,
                   v_pol_agnt_agent_code,
                   v_bind_lta_type,
                   v_bind_comm_type,
                   v_agn_act_code
              FROM gin_policies,
                   gin_insured_property_unds,
                   gin_binders,
                   tqc_agencies
             WHERE     pol_batch_no = ipu_pol_batch_no
                   AND ipu_code = v_ipucode
                   AND agn_code = pol_agnt_agent_code
                   AND ipu_bind_code = bind_code;
        EXCEPTION
            WHEN OTHERS
            THEN
                raise_error ('Error fetching policy details ');
        END;