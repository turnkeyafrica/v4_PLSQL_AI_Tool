PROCEDURE pop_insured (v_pol_policy_no   IN VARCHAR2,
                           v_pol_endos_no    IN VARCHAR2,
                           v_pol_batch_no    IN NUMBER,
                           v_prp_code        IN NUMBER)
    IS
    BEGIN
        INSERT INTO gin_policy_insureds (polin_code,
                                         polin_pol_policy_no,
                                         polin_pol_ren_endos_no,
                                         polin_pol_batch_no,
                                         polin_prp_code)
                 VALUES (
                               TO_NUMBER (TO_CHAR (SYSDATE, 'RRRR'))
                            || polin_code_seq.NEXTVAL,
                            v_pol_policy_no,  ---:GIN_POLICIES1.POL_POLICY_NO,
                            v_pol_endos_no,
                            ---:GIN_POLICIES1.POL_REN_ENDOS_NO,
                            v_pol_batch_no,    ---:GIN_POLICIES1.POL_BATCH_NO,
                            v_prp_code);      ---:GIN_POLICIES1.POL_PRP_CODE);
    EXCEPTION
        WHEN OTHERS
        THEN
            raise_error ('Error inserting Insureds..');
    END;