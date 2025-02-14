```sql
PROCEDURE update_coinsurance_share (
    v_pol_batch_no   IN NUMBER,
    v_leader         IN VARCHAR2,
    v_share          IN NUMBER,
    v_fee            IN NUMBER,
    v_fac_appl       IN VARCHAR2 DEFAULT 'N',
    v_fac_pcnt       IN NUMBER DEFAULT NULL
)
IS
    v_cnt   NUMBER;
BEGIN
    IF NVL (v_leader, 'N') = 'Y'
    THEN
        BEGIN
            SELECT COUNT (*)
              INTO v_cnt
              FROM gin_coinsurers
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

        IF NVL (v_cnt, 0) > 0
        THEN
            raise_error (
                'Error:- A coinsurance leader already exists. Please check....');
        END IF;
    END IF;

    UPDATE gin_policies
       SET pol_coinsurance_share = v_share,
           pol_coin_fee = v_fee,
           pol_coinsure_leader = v_leader,
           POL_COIN_FAC_CESSION = NVL (v_fac_appl, 'N'),
           POL_COIN_FAC_PC = v_fac_pcnt
     WHERE pol_batch_no = v_pol_batch_no;
EXCEPTION
    WHEN OTHERS
    THEN
        raise_error ('error updating insured details....');
END;

```