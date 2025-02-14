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

        --v_err_pos := 'Risk Level tables';
        v_error := 'Error deleting risk details';

        BEGIN
            DELETE FROM gin_policy_ren_risk_services
                  WHERE prs_ipu_code = v_ipu_code;
        EXCEPTION
            WHEN OTHERS
            THEN
                RETURN;
        END;

        v_error := 'Error deleting policy clauses';

        BEGIN
            DELETE FROM gin_ren_policy_clauses
                  WHERE pocl_ipu_code = v_ipu_code;
        EXCEPTION
            WHEN OTHERS
            THEN
                RETURN;
        END;

        v_error := 'Error deleting policy premium items';

        BEGIN
            DELETE FROM gin_ren_policy_insured_limits
                  WHERE pil_ipu_code = v_ipu_code;
        EXCEPTION
            WHEN OTHERS
            THEN
                RETURN;
        END;

        v_error := 'Error deleting policy perils';

        BEGIN
            DELETE FROM gin_ren_pol_sec_perils
                  WHERE gpsp_ipu_code = v_ipu_code;
        EXCEPTION
            WHEN OTHERS
            THEN
                RETURN;
        END;

        v_error := 'Error deleting risk excess';

        BEGIN
            DELETE FROM gin_ren_risk_excess
                  WHERE re_ipu_code = v_ipu_code;
        EXCEPTION
            WHEN OTHERS
            THEN
                RETURN;
        END;

        v_error := 'Error deleting risk limits';

        BEGIN
            DELETE FROM gin_ren_policy_risk_schedules
                  WHERE polrs_ipu_code = v_ipu_code;
        EXCEPTION
            WHEN OTHERS
            THEN
                RETURN;
        END;

        v_error := 'Error deleting risk section perils';

        BEGIN
            DELETE FROM gin_pol_ren_rsk_section_perils
                  WHERE prspr_ipu_code = v_ipu_code;
        EXCEPTION
            WHEN OTHERS
            THEN
                RETURN;
        END;

        v_error := 'Error deleting risk services';

        BEGIN
            DELETE FROM gin_policy_ren_risk_services
                  WHERE prs_ipu_code = v_ipu_code;
        EXCEPTION
            WHEN OTHERS
            THEN
                RETURN;
        END;

        --    v_err_pos := 'Deleting Risk';
        v_error := 'Error deleting risk services';

        BEGIN
            DELETE FROM gin_ren_insured_property_unds
                  WHERE ipu_code = v_ipu_code;
        EXCEPTION
            WHEN OTHERS
            THEN
                RETURN;
        END;
    END;