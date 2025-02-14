PROCEDURE populate_binder_renewals (v_pol_batch_no VARCHAR2)
    IS
        CURSOR cur_pol IS
            SELECT *
              FROM gin_policies
             WHERE pol_batch_no = v_pol_batch_no;

        v_bind_code         NUMBER;
        v_rate              NUMBER;
        v_sect_code         NUMBER;
        v_prem_rate         NUMBER;
        v_coin_pct          NUMBER;
        v_min_prem_factor   NUMBER := 1;
        v_rnd               NUMBER := 2;
        v_param             VARCHAR2 (1);
        act_type            VARCHAR2 (5);
        v_cnt               NUMBER;
    BEGIN
        FOR cur_pol_rec IN cur_pol
        LOOP
            BEGIN
                SELECT NVL (
                           gin_parameters_pkg.get_param_varchar (
                               'ALLOW_PREM_COMP_BINDERS'),
                           'N')
                  INTO v_param
                  FROM DUAL;
            EXCEPTION
                WHEN OTHERS
                THEN
                    v_param := 'N';
            END;