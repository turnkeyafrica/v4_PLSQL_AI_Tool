PROCEDURE gin_coinsurers_prc (v_batch_no        IN NUMBER,
                                  v_pol_coins_tab   IN web_pol_coins_tab)
    IS
        CURSOR pol_cur IS
            SELECT *
              FROM gin_policies
             WHERE pol_batch_no = v_batch_no;

        v_coin_perc          NUMBER;
        v_default_serv_fee   VARCHAR2 (1);
        v_def_serv           VARCHAR2 (1);
        v_trans_type         VARCHAR2 (5);
    BEGIN
        FOR pol_rec IN pol_cur
        LOOP
            IF NVL (pol_rec.pol_coinsurance, 'N') = 'Y'
            THEN
                FOR x IN 1 .. v_pol_coins_tab.COUNT
                LOOP                                      -- IN pol_coins LOOP
                    BEGIN
                        BEGIN
                            v_default_serv_fee :=
                                gin_parameters_pkg.get_param_varchar (
                                    'DEFAULT_COMPUTE_SERV_FEE');
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                v_default_serv_fee := 'N';
                        END;