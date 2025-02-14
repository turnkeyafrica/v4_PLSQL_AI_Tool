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

        BEGIN
            SELECT DECODE (
                       DECODE (v_trnt_code,
                               'LTA-U', v_bind_lta_type,
                               v_bind_comm_type),
                       'B', 1,
                       2)    order_type
              INTO v_type
              FROM DUAL;
        EXCEPTION
            WHEN OTHERS
            THEN
                raise_error ('Error fetching binder details ');
        END;

        BEGIN
            SELECT COUNT (*)
              INTO v_count
              FROM gin_policy_risk_commissions
             WHERE     prc_ipu_code = v_ipucode
                   AND prc_trans_code = v_trans_code
                   AND prc_trnt_code = v_trnt_code;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                v_count := 0;
            WHEN OTHERS
            THEN
                raise_error ('Error fetching commission details ');
        END;

        IF (v_pol_agnt_agent_code != 0)
        THEN
            IF v_count = 0
            THEN
                BEGIN
                    INSERT INTO gin_policy_risk_commissions (
                                    prc_code,
                                    prc_ipu_code,
                                    prc_pol_batch_no,
                                    prc_agn_code,
                                    prc_trans_code,
                                    prc_act_code,
                                    prc_trnt_code,
                                    prc_group)
                         VALUES (tq_gis.prc_code_seq.NEXTVAL,
                                 v_ipucode,
                                 v_pol_batch_no,
                                 v_pol_agnt_agent_code,
                                 v_trans_code,
                                 v_agn_act_code,
                                 v_trnt_code,
                                 v_type);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error ('Error inserting commission Details. ');
                END;
            ELSE
                raise_error ('Commission type already exists ');
            END IF;
        ELSE
            raise_error ('Commission not applicable to direct bussiness.');
        END IF;
    END;