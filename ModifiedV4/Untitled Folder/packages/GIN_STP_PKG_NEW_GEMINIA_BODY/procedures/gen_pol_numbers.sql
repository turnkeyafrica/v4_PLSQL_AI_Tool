PROCEDURE gen_pol_numbers (v_prod_code     IN     NUMBER,
                               v_brn_code      IN     NUMBER,
                               v_uw_yr         IN     NUMBER,
                               v_trans_code    IN     VARCHAR2,
                               v_policy_no     IN OUT VARCHAR2,
                               v_endos_no      IN OUT VARCHAR2,
                               v_batch_no      IN OUT NUMBER,
                               v_serial        IN     NUMBER,
                               v_policy_type   IN     VARCHAR2,
                               v_coinsurance   IN     VARCHAR2,
                               v_div_code      IN     VARCHAR2)
    IS
        v_pol_type           VARCHAR2 (5);
        v_seq                NUMBER;
        v_seqno              VARCHAR2 (35);
        v_brn_sht_length     NUMBER;
        v_src                VARCHAR2 (1);
        v_binderpols_param   VARCHAR2 (1) DEFAULT 'N';
    BEGIN
        BEGIN
            v_binderpols_param :=
                gin_parameters_pkg.get_param_varchar (
                    'NORMAL_BINDER_POLS_USESAME_SEQ');
        EXCEPTION
            WHEN OTHERS
            THEN
                v_binderpols_param := 'N';
        END;