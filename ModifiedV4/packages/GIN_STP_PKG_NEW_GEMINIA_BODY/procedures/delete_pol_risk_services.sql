PROCEDURE delete_pol_risk_services (v_action     IN VARCHAR2,
                                        v_prs_code   IN NUMBER,
                                        v_ipu_code   IN NUMBER)
    IS
    BEGIN
        IF NVL (v_action, 'X') = 'D'
        THEN
            DELETE FROM gin_policy_risk_services
                  WHERE prs_ipu_code = v_ipu_code AND prs_code = v_prs_code;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            raise_error (SQLERRM);
    END;