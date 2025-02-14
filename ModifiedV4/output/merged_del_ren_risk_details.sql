```sql
PROCEDURE del_ren_risk_details (
    v_pol_batch_no   IN   NUMBER,
    v_ipu_code       IN   NUMBER,
    v_pro_code       IN   NUMBER,
    v_error          OUT VARCHAR2
)
IS
    v_successful   NUMBER;
BEGIN
    -- Initialize error message
    v_error := 'Initial error';

    -- Delete specific details, handle exception
    BEGIN
        del_spec_details (v_pro_code, v_ipu_code);
    EXCEPTION
        WHEN OTHERS THEN
            v_error := 'Error deleting schedule details';
            RETURN;
    END;

    -- Delete from GIN_POLICY_REN_RISK_SERVICES, handle exception
    BEGIN
        DELETE FROM GIN_POLICY_REN_RISK_SERVICES WHERE PRS_IPU_CODE = v_ipu_code;
    EXCEPTION
        WHEN OTHERS THEN
            v_error := 'Error deleting risk details';
            RETURN;
    END;

     -- Delete from gin_ren_policy_clauses, handle exception
    BEGIN
       DELETE FROM gin_ren_policy_clauses WHERE pocl_ipu_code = v_ipu_code;
    EXCEPTION
        WHEN OTHERS THEN
            v_error := 'Error deleting policy clauses';
             RETURN;
    END;
    
    -- Delete from gin_ren_policy_insured_limits, handle exception
    BEGIN
        DELETE FROM gin_ren_policy_insured_limits WHERE pil_ipu_code = v_ipu_code;
    EXCEPTION
        WHEN OTHERS THEN
            v_error := 'Error deleting policy premium items';
             RETURN;
    END;

    -- Delete from gin_ren_pol_sec_perils, handle exception
    BEGIN
       DELETE FROM gin_ren_pol_sec_perils WHERE gpsp_ipu_code = v_ipu_code;
    EXCEPTION
        WHEN OTHERS THEN
            v_error := 'Error deleting policy perils';
             RETURN;
    END;

    -- Delete from gin_ren_risk_excess, handle exception
    BEGIN
        DELETE FROM gin_ren_risk_excess WHERE re_ipu_code = v_ipu_code;
    EXCEPTION
        WHEN OTHERS THEN
             v_error := 'Error deleting risk excess';
            RETURN;
    END;

    -- Delete from gin_ren_policy_risk_schedules, handle exception
    BEGIN
        DELETE FROM gin_ren_policy_risk_schedules WHERE polrs_ipu_code = v_ipu_code;
    EXCEPTION
        WHEN OTHERS THEN
            v_error := 'Error deleting risk limits';
            RETURN;
    END;

   -- Delete from gin_pol_ren_rsk_section_perils, handle exception
    BEGIN
        DELETE FROM gin_pol_ren_rsk_section_perils WHERE PRSPR_IPU_CODE = v_ipu_code;
    EXCEPTION
        WHEN OTHERS THEN
            v_error := 'Error deleting risk section perils';
             RETURN;
    END;
   
   -- Delete from gin_policy_ren_risk_services, handle exception
    BEGIN
        DELETE FROM gin_policy_ren_risk_services WHERE prs_ipu_code = v_ipu_code;
    EXCEPTION
         WHEN OTHERS THEN
            v_error := 'Error deleting risk services';
            RETURN;
    END;
    
    -- Delete from gin_ren_insured_property_unds, handle exception
    BEGIN
         DELETE FROM gin_ren_insured_property_unds WHERE ipu_code = v_ipu_code;
    EXCEPTION
        WHEN OTHERS THEN
            v_error := 'Error deleting risk services';
            RETURN;
    END;
    
    -- If no exceptions were raised set v_error to null
    v_error := NULL;

END;

```