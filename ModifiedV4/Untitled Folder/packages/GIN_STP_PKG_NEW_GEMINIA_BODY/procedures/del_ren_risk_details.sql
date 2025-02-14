PROCEDURE del_ren_risk_details (v_pol_batch_no   IN     NUMBER,
                                    v_ipu_code       IN     NUMBER,
                                    v_pro_code              NUMBER,
                                    v_error             OUT VARCHAR2)
    IS
        v_successful   NUMBER;
    BEGIN
        --RAISE_ERROR('v_pol_batch_no '||v_pol_batch_no);
        --v_err_pos := 'Specific Details';
        v_error := 'Error deleting schedule details';

        BEGIN
            del_spec_details (v_pro_code, v_ipu_code);
        EXCEPTION
            WHEN OTHERS
            THEN
                RETURN;
        END;