PROCEDURE pop_ren_loading_rsk_limits (v_new_ipu_code   IN NUMBER,
                                          v_scl_code       IN NUMBER,
                                          v_bind_code      IN NUMBER,
                                          v_cvt_code       IN NUMBER,
                                          v_batch_no       IN NUMBER,
                                          v_sect_type      IN VARCHAR2,
                                          v_range          IN NUMBER)
    IS
        v_pil_declaration_section   VARCHAR2 (30);
        v_row                       NUMBER;
        v_pol_binder                VARCHAR2 (2);

        CURSOR pil_cur_ncd IS
            SELECT *
              FROM gin_ren_policy_insured_limits
             WHERE     pil_ipu_code = v_new_ipu_code
                   AND pil_sect_type = v_sect_type;
    BEGIN
        --RAISE_ERROR(v_scl_code||'='||v_bind_code||'='||v_new_ipu_code||'=v_range'||v_range);
        BEGIN
            SELECT pol_binder_policy
              INTO v_pol_binder
              FROM gin_ren_policies, gin_ren_insured_property_unds
             WHERE     pol_batch_no = ipu_pol_batch_no
                   AND ipu_code = v_new_ipu_code
                   AND pol_batch_no = v_batch_no;
        EXCEPTION
            WHEN OTHERS
            THEN
                raise_error ('Error determining the policy binder...');
        END;