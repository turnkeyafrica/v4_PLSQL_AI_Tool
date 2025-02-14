PROCEDURE edit_endors_details (v_pol_batch_no   IN NUMBER,
                                   v_prp_code       IN NUMBER,
                                   v_comment        IN VARCHAR2,
                                   v_type           IN VARCHAR2,
                                   v_end_code       IN NUMBER)
    IS
        v_text         VARCHAR2 (4000);
        v_pol_status   VARCHAR2 (5);
    BEGIN
        -- RAISE_ERROR('v_text ; '||v_pol_batch_no);
        BEGIN
            -- RAISE_ERROR('TEST'||v_comment);
            IF v_type = 'RN'
            THEN
                v_text := merge_ren_policies_text (v_pol_batch_no, v_comment);
            -- RAISE_ERROR('v_text'||v_text);
            ELSE
                v_text := merge_policies_text (v_pol_batch_no, v_comment);
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                v_text := v_comment;
        --RAISE_ERROR('Error Occured while saving Endorsement Details...'||SQLERRM(SQLCODE));
        END;