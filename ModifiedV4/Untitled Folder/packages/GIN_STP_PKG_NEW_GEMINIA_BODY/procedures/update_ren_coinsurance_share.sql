PROCEDURE update_ren_coinsurance_share (
        v_pol_batch_no   IN NUMBER,
        v_leader         IN VARCHAR2,
        v_share          IN NUMBER,
        v_fee            IN NUMBER,
        v_fac_appl       IN VARCHAR2 DEFAULT 'N',
        v_fac_pcnt       IN NUMBER DEFAULT NULL)
    IS
        v_cnt   NUMBER;
    BEGIN
        IF NVL (v_leader, 'N') = 'Y'
        THEN
            BEGIN
                SELECT COUNT (*)
                  INTO v_cnt
                  FROM gin_ren_coinsurers
                 WHERE     coin_pol_batch_no = v_pol_batch_no
                       AND NVL (coin_lead, 'N') = 'Y';
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    v_cnt := 0;
                WHEN OTHERS
                THEN
                    raise_error ('Error fetching the existing coinsurers...');
            END;