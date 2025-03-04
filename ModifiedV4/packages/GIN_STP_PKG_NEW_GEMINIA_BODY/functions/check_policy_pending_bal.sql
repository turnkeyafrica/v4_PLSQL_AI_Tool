FUNCTION check_policy_pending_bal (v_pol_batch_no NUMBER)
        RETURN VARCHAR2
    IS
        v_error       VARCHAR2 (200);
        v_clnt_code   NUMBER;
        v_agn_code    NUMBER;
        v_count       NUMBER;
    BEGIN
        v_error := '';

        BEGIN
            SELECT pol_prp_code, pol_agnt_agent_code
              INTO v_clnt_code, v_agn_code
              FROM gin_policies
             WHERE pol_batch_no = v_pol_batch_no;
        EXCEPTION
            WHEN OTHERS
            THEN
                v_error :=
                    'Error getting policy details...' || v_pol_batch_no;
                RETURN v_error;
        END;

        IF gin_parameters_pkg.get_param_varchar (
               'ALLOW_CERTIFICATE_BALANCES') =
           'N'
        THEN
            BEGIN
                SELECT COUNT (1)
                  INTO v_count
                  FROM gin_policy_exceptions
                 WHERE     gpe_pol_batch_no = v_pol_batch_no
                       AND gpe_gge_code = 'PDR'
                       AND NVL (gpe_authorised, 'N') = 'N';

                IF NVL (v_count, 0) >= 0
                THEN
                    IF NVL (gis_accounts_utilities.getpaidprem (
                                v_pol_batch_no,
                                v_agn_code,
                                v_clnt_code,
                                'B'),
                            9) > 0
                    THEN
                        v_error :=
                               'Cannot Allocate Certificate when there is pending balance Of '
                            || NVL (gis_accounts_utilities.getpaidprem (
                                        v_pol_batch_no,
                                        v_agn_code,
                                        v_clnt_code,
                                        'B'),
                                    9);
                        RETURN v_error;
                    END IF;
                ELSE
                    v_error := '';
                END IF;
            EXCEPTION
                WHEN OTHERS
                THEN
                    v_error :=
                           'Error occured while getting certificate pending balance '
                        || SQLERRM (SQLCODE);
                    RETURN v_error;
            END;
        END IF;

        RETURN v_error;
    END;