PROCEDURE update_risk_values (v_ipu_code   IN NUMBER,
                                  v_survey     IN VARCHAR2 DEFAULT 'N')
    IS
    BEGIN
        UPDATE gin_insured_property_unds
           SET ipu_survey = UPPER (v_survey)
         WHERE ipu_code = v_ipu_code;
    EXCEPTION
        WHEN OTHERS
        THEN
            raise_error ('Error updating if risk is to undergo survey');
    END;