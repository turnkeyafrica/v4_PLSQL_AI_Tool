PROCEDURE saveserviceproviderdetails (v_action                VARCHAR2,
                                          v_gsp_code              NUMBER,
                                          v_gsp_spr_code          NUMBER,
                                          v_gsp_spt_code       IN NUMBER,
                                          v_gsp_pol_batch_no   IN NUMBER)
    IS
    BEGIN
        -- RAISE_ERROR('v_cgpte_pol_batch_no'||v_cgpte_pol_batch_no);
        IF v_action = 'A'
        THEN
            BEGIN
                INSERT INTO gin_service_providers (gsp_code,
                                                   gsp_spr_code,
                                                   gsp_spt_code,
                                                   gsp_pol_batch_no)
                     VALUES (gin_gsp_code_seq.NEXTVAL,
                             v_gsp_spr_code,
                             v_gsp_spt_code,
                             v_gsp_pol_batch_no);
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error (
                        'Error inserting Service Provider Details...');
            END;