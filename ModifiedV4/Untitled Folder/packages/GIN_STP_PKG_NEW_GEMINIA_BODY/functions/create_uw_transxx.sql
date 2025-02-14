FUNCTION create_uw_transxx (
        clientname                IN VARCHAR2,
        clientpin                 IN VARCHAR2,
        clienttype                IN VARCHAR2,
        clienttitle               IN VARCHAR2,
        policynumber              IN VARCHAR2,
        policyendorsementnumber   IN VARCHAR2,
        policyagentcode           IN NUMBER,    -- this was change to agn_code
        policycoverfrom           IN DATE,
        policycoverto             IN DATE,
        policyunderwritingyear    IN NUMBER,
        policytransactiontype     IN VARCHAR2,
        --  NB  - New business, EN  - Endorsements, RN  - Renewals
        policybranchcode          IN VARCHAR2,
        policydebitnotenumber     IN VARCHAR2,     -- same as the endos number
        policyproduct             IN VARCHAR2,
        policystampduty           IN NUMBER,
        v_risk_rec                IN med_risk_tab,
        v_ped_code                IN NUMBER,
        v_post_trans              IN VARCHAR2 DEFAULT 'Y')
        RETURN VARCHAR2
    IS
        vcount           NUMBER;
        vreturn          VARCHAR2 (1);
        vclntcode        NUMBER;
        vprocnt          NUMBER;
        r_no             NUMBER;
        r_pol_no         NUMBER;
        v_pol_rec        gin_policies_loading_tab := gin_policies_loading_tab ();
        v_pol_dtls_rec   gin_load_policy_dtls_tbl
                             := gin_load_policy_dtls_tbl ();
        v_new_ipu_code   NUMBER;
        v_pol_recd       web_pol_tab := web_pol_tab ();
        v_poll_code      NUMBER;
        v_batch_no       NUMBER;
        v_user           VARCHAR2 (30)
            := pkg_global_vars.get_pvarchar2 ('PKG_GLOBAL_VARS.PVG_USERNAME');
        v_exceptions     VARCHAR2 (10);
        v_policy_no      VARCHAR2 (30);
        v_pol_wef        DATE;
        v_pol_wet        DATE;
        v_rn_id          NUMBER;
        v_batchno        NUMBER;
        v_trans_no       NUMBER;
        v_covt_type      VARCHAR2 (30);
        v_itb_code       NUMBER;

        CURSOR taxes (vbatchno IN NUMBER)
        IS
            SELECT *
              FROM gin_policy_taxes
             WHERE ptx_pol_batch_no = vbatchno;

        v_tl             NUMBER;
        v_phfund         NUMBER;
        v_scl_code       NUMBER;
        v_covt_code      NUMBER;
        v_pro_sht_desc   VARCHAR2 (10);
    BEGIN
        /*This function create a policy  from client creation to authorization*/
        IF policytransactiontype = 'NB'
        THEN
            BEGIN
                SELECT pro_sht_desc
                  INTO v_pro_sht_desc
                  FROM gin_products
                 WHERE pro_ext_map_code = policyproduct;
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error ('Product mapping issue...');
            END;