PROCEDURE import_data (v_brn_code        IN     NUMBER,
                           v_brn_sht_desc    IN     VARCHAR2,
                           v_fxd_exch_rate   IN     VARCHAR2,
                           v_psd_code        IN     NUMBER DEFAULT NULL,
                           v_tot_rec            OUT NUMBER,
                           v_success            OUT NUMBER)
    IS
        v_cnt             NUMBER;
        v_prp_code        NUMBER;
        v_sect_code       NUMBER;
        v_sect_desc       VARCHAR2 (35);
        v_pol_tab         gin_stp_pkg.policy_tab;
        v_rsk_tab         gin_stp_pkg.risk_tab;
        v_cur_code        NUMBER;
        v_cur_symbol      VARCHAR2 (35);
        v_agent_code      NUMBER;
        v_agnt_sht_desc   VARCHAR2 (35);
        v_errmsg          VARCHAR2 (400);
        v_pol_batch_no    NUMBER;

        --v_user        VARCHAR2(35):=Pkg_Global_Vars.get_pvarchar2 ('PKG_GLOBAL_VARS.PVG_USERNAME');
        CURSOR cur_recs IS
            SELECT *
              FROM gin_pol_stp_data
             WHERE     NVL (psd_transfered, 'N') != 'Y'
                   AND psd_code =
                       DECODE (NVL (v_psd_code, 0),
                               0, psd_code,
                               NVL (v_psd_code, 0));
    --CURSOR cur_clnts(vpsd_agnt_client_id IN NUMBER) IS SELECT * FROM GIN_POL_STP_CLNT_DATA WHERE PSC_AGNT_CLNT_ID = vpsd_agnt_client_id;
    BEGIN
        v_tot_rec := 0;
        v_success := 0;

        FOR crecs IN cur_recs
        LOOP
            v_tot_rec := NVL (v_tot_rec, 0) + 1;

            BEGIN
                BEGIN
                    SELECT COUNT (1)
                      INTO v_cnt
                      FROM gin_pol_stp_clnt_data
                     WHERE psc_agnt_clnt_id = crecs.psd_agnt_client_id;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        v_errmsg :=
                            'Error retrieving insured details..' || SQLERRM;
                        raise_application_error (-20001, v_errmsg);
                END;