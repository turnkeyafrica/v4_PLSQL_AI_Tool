PROCEDURE checkagentstatus (v_agn_code     IN NUMBER,
                                v_trans_type   IN VARCHAR2 DEFAULT NULL)
    IS
        v_agn_status   VARCHAR2 (50);
    BEGIN
        ---CHECK THE AGENT STATUS IF INACTIVE OR ACTIVE
        BEGIN
            SELECT NVL (agn_status, 'XXX')
              INTO v_agn_status
              FROM tqc_agencies
             WHERE agn_code = v_agn_code;
        EXCEPTION
            WHEN OTHERS
            THEN
                raise_error ('Error getting agent status...........');
        END;

        --     RAISE_ERROR('v_trans_type='||v_trans_type);
        IF     v_agn_status != 'ACTIVE'
           AND NVL (v_trans_type, 'XX') NOT IN ('CO', 'CN')
        THEN
            raise_error (
                'Error : Cannot raise a transaction  on an INACTIVE agent........');
        END IF;
    END;