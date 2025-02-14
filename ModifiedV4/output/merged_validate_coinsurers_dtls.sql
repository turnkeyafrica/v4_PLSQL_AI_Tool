```sql
PROCEDURE validate_coinsurers_dtls (v_pol_batch_no IN NUMBER)
    IS
        v_pol_coin_share   NUMBER;
        v_coin_perc        NUMBER;
        v_coinsurance      VARCHAR2 (2);
        v_pol_leader       VARCHAR2 (2);
        v_leader_count     NUMBER;
        v_sum              NUMBER;
    BEGIN
        BEGIN
            SELECT pol_coinsurance_share,
                   pol_coinsurance,
                   pol_coinsure_leader
              INTO v_pol_coin_share, v_coinsurance, v_pol_leader
              FROM gin_policies
             WHERE pol_batch_no = v_pol_batch_no;
        EXCEPTION
            WHEN OTHERS
            THEN
                raise_error ('Error fetching policy details...');
        END;

        IF NVL (v_coinsurance, 'N') = 'Y'
        THEN
            BEGIN
                SELECT SUM (NVL (coin_perct, 0))
                  INTO v_coin_perc
                  FROM gin_coinsurers
                 WHERE coin_pol_batch_no = v_pol_batch_no;
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error (
                        'Error determining coinsurance total percentage....');
            END;

            IF NVL (v_pol_leader, 'N') = 'Y'
            THEN
                BEGIN
                    SELECT COUNT (*)
                      INTO v_leader_count
                      FROM gin_coinsurers
                     WHERE     coin_pol_batch_no = v_pol_batch_no
                           AND NVL (coin_lead, 'N') = 'Y';
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error (
                            'Error determining coinsurance total percentage....');
                END;

                IF NVL (v_leader_count, 0) >= 1
                THEN
                    raise_error (
                        'You cannot have more than one leader on a coinsurance policy. Please check...');
                END IF;
            ELSIF NVL (v_pol_leader, 'N') = 'N'
            THEN
                BEGIN
                    SELECT COUNT (*)
                      INTO v_leader_count
                      FROM gin_coinsurers
                     WHERE     coin_pol_batch_no = v_pol_batch_no
                           AND NVL (coin_lead, 'N') = 'Y';
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        raise_error (
                            'Error determining coinsurance total percentage....');
                END;

                IF NVL (v_leader_count, 0) = 0
                THEN
                    raise_error (
                        'No leader specified for this coinsurance policy. Please check...');
                ELSIF NVL (v_leader_count, 0) > 1
                THEN
                    raise_error (
                        'You cannot have more than one leader on a coinsurance policy. Please check...');
                END IF;
            END IF;

            IF NVL (v_coin_perc, 0) + NVL (v_pol_coin_share, 0) > 100
            THEN
                v_sum := NVL (v_coin_perc, 0) + NVL (v_pol_coin_share, 0);
                raise_error (
                       'Error:- Coinsurance percentages cannot be greater than 100%=== '
                    || v_sum);
            ELSIF NVL (v_coin_perc, 0) + NVL (v_pol_coin_share, 0) < 100
            THEN
                raise_error (
                    'Error:- Coinsurance percentages cannot be less than 100%... ');
            END IF;
        END IF;
    END;

```