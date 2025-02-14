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