PROCEDURE update_comm_details (v_add_edit        IN VARCHAR2,
                                   v_prc_code        IN NUMBER,
                                   v_prc_group       IN NUMBER,
                                   v_prc_used_rate   IN NUMBER,
                                   v_prc_disc_type   IN VARCHAR2,
                                   v_prc_disc_rate   IN NUMBER,
                                   v_ipucode         IN NUMBER,
                                   v_override_comm   IN VARCHAR2 DEFAULT 'N',
                                   v_prc_amount      IN NUMBER DEFAULT NULL)
    IS
    BEGIN
        IF v_add_edit = 'E'
        THEN
            BEGIN
                UPDATE gin_policy_risk_commissions
                   SET prc_group = v_prc_group,
                       prc_used_rate = v_prc_used_rate,
                       prc_disc_type = v_prc_disc_type,
                       prc_disc_rate = v_prc_disc_rate,
                       prc_override_comm = v_override_comm,
                       prc_amount = v_prc_amount
                 WHERE prc_code = v_prc_code;
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error ('Error updating Commission Details.');
            END;
        END IF;

        IF v_add_edit = 'D'
        THEN
            BEGIN
                DELETE FROM gin_policy_risk_commissions
                      WHERE prc_code = v_prc_code;
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error ('Error updating Commission Details.');
            END;
        END IF;
    END;