PROCEDURE update_ren_pol_coinsurers (
        v_batch_no             IN NUMBER,
        v_agent_code           IN NUMBER,
        v_leader                  VARCHAR2,
        v_perc                 IN NUMBER,
        v_fee_rate             IN NUMBER,
        v_policy_no            IN VARCHAR2,
        v_pol_coin_policy_no   IN VARCHAR2 DEFAULT NULL,
        v_force_compute        IN VARCHAR2,
        v_comm_type            IN VARCHAR2 DEFAULT 'R',
        v_COIN_FAC_CESSION     IN VARCHAR2 DEFAULT 'N',
        v_COIN_FAC_PC          IN NUMBER DEFAULT NULL)
    IS
        v_pol_leader     VARCHAR2 (1);
        v_pol_coin_pct   NUMBER;
        v_coin_perct     NUMBER;
        v_cnt            NUMBER;
    BEGIN
        BEGIN
            SELECT pol_coinsure_leader, pol_coinsure_pct
              INTO v_pol_leader, v_pol_coin_pct
              FROM gin_ren_policies
             WHERE pol_batch_no = v_batch_no;
        EXCEPTION
            WHEN OTHERS
            THEN
                raise_error (
                    'Error determining if the policy is for a leader....');
        END;