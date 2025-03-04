```sql
PROCEDURE update_pol_coinsurers (
    v_batch_no             IN NUMBER,
    v_agent_code           IN NUMBER,
    v_leader                  VARCHAR2,
    v_perc                 IN NUMBER,
    v_fee_rate             IN NUMBER,
    v_aga_code             IN NUMBER,
    v_policy_no            IN VARCHAR2,
    v_force_compute        IN VARCHAR2,
    v_coin_optional_comm   IN VARCHAR2,
    --to take care of optional_comm either Y OR N for a coinsurer
    v_comm_rate            IN NUMBER DEFAULT NULL,
    --enable overridding commission at coinsurance level for inhouse agents
    v_comm_type            IN VARCHAR2 DEFAULT 'R',
    v_COIN_FAC_CESSION     IN VARCHAR2 DEFAULT 'N',
    v_COIN_FAC_PC          IN NUMBER DEFAULT NULL
)
IS
    v_pol_leader     VARCHAR2 (1);
    v_pol_coin_pct   NUMBER;
    v_coin_perct     NUMBER;
    v_cnt            NUMBER;
    v_aga_sht_desc   VARCHAR2 (15);
BEGIN
    BEGIN
        SELECT pol_coinsure_leader, pol_coinsure_pct
        INTO v_pol_leader, v_pol_coin_pct
        FROM gin_policies
        WHERE pol_batch_no = v_batch_no;
    EXCEPTION
        WHEN OTHERS
        THEN
            raise_error (
                'Error determining if the policy is for a leader....');
    END;

    IF NVL (v_leader, 'N') = 'Y'
    THEN
        BEGIN
            SELECT COUNT (*)
            INTO v_cnt
            FROM gin_coinsurers
            WHERE     coin_pol_batch_no = v_batch_no
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
            BEGIN
                UPDATE gin_coinsurers
                    SET coin_lead = 'N'
                WHERE     NVL (coin_lead, 'N') = 'Y'
                AND coin_pol_batch_no = v_batch_no;
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error (
                        'Error updating the previous coinsurance leader details....');
            END;
        --RAISE_ERROR('Error:- A coinsurance leader already exists. Please check....');
        END IF;

        IF NVL (v_pol_leader, 'N') = 'Y'
        THEN
            raise_error (
                'Error:- The policy belongs to the leader already. Please check....');
        END IF;
    ELSE
        BEGIN
            SELECT COUNT (*)
            INTO v_cnt
            FROM gin_coinsurers
            WHERE     coin_pol_batch_no = v_batch_no
            AND NVL (coin_lead, 'N') = 'Y';
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                v_cnt := 0;
            WHEN OTHERS
            THEN
                raise_error ('Error fetching the existing coinsurers...');
        END;

        IF NVL (v_cnt, 0) > 1
        THEN
            raise_error (
                'You cannot have more than one coinsurance leader on a transaction...');
        END IF;
    END IF;

    IF v_aga_code IS NOT NULL
    THEN
        SELECT aga_sht_desc
        INTO v_aga_sht_desc
        FROM tqc_agency_accounts
        WHERE aga_code = v_aga_code;
    END IF;

    BEGIN
        UPDATE gin_coinsurers
            SET coin_lead = NVL (v_leader, coin_lead),
                coin_perct = v_perc,              --NVL(v_perc,COIN_PERCT),
                coin_fee_rate = v_fee_rate, --NVL(v_fee_rate,COIN_FEE_RATE)
                coin_aga_code = v_aga_code,
                coin_aga_sht_desc = v_aga_sht_desc,
                coin_coinsurers_polno = v_policy_no,
                coin_force_sf_compute = v_force_compute,
                coin_optional_comm = v_coin_optional_comm,
                coin_comm_rate = v_comm_rate,
                coin_comm_type = v_comm_type,
                COIN_FAC_CESSION = v_COIN_FAC_CESSION,
                COIN_FAC_PC = v_COIN_FAC_PC
        WHERE     coin_agnt_agent_code = v_agent_code
        AND coin_pol_batch_no = v_batch_no;
    EXCEPTION
        WHEN OTHERS
        THEN
            raise_error ('Error updating coinsurance details....');
    END;

    BEGIN
        UPDATE gin_policies
            SET pol_prem_computed = 'N'
        WHERE pol_batch_no = v_batch_no;
    EXCEPTION
        WHEN OTHERS
        THEN
            raise_error (
                'Error updating policy premium status to changed');
    END;

    BEGIN
        SELECT SUM (NVL (coin_perct, 0))
        INTO v_coin_perct
        FROM gin_coinsurers
        WHERE coin_pol_batch_no = v_batch_no;
    EXCEPTION
        WHEN OTHERS
        THEN
            raise_error (
                'Error determinig the total coinsurance percentage....');
    END;

    IF NVL (v_coin_perct, 0) + NVL (v_pol_coin_pct, 0) > 100
    THEN
        raise_error (
            'Error:- Coinaurance percentages should not be more than 100....');
    END IF;
END;

```