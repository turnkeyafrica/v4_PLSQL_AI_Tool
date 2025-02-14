FUNCTION create_uw_trans_func (clientname                IN VARCHAR2,
                                   clientpin                 IN VARCHAR2,
                                   clienttype                IN VARCHAR2,
                                   clienttitle               IN VARCHAR2,
                                   policynumber              IN VARCHAR2,
                                   policyendorsementnumber   IN VARCHAR2,
                                   policyagentcode           IN VARCHAR2,
                                   policycoverfrom           IN DATE,
                                   policycoverto             IN DATE,
                                   policyunderwritingyear    IN NUMBER,
                                   policytransactiontype     IN VARCHAR2,
                                   --  NB  - New business, EN  - Endorsements, RN  - Renewals
                                   policypreparedby          IN VARCHAR2,
                                   policyauthorizedby        IN VARCHAR2,
                                   policybranchcode          IN VARCHAR2,
                                   policydebitnotenumber     IN VARCHAR2,
                                   policyproduct             IN VARCHAR2,
                                   policystampduty           IN NUMBER,
                                   policycurrency            IN VARCHAR2,
                                   riskid                    IN VARCHAR2,
                                   riskdesc                  IN VARCHAR2,
                                   risksubclass              IN VARCHAR2,
                                   riskcovertype             IN VARCHAR2,
                                   risksuminsured            IN NUMBER,
                                   riskbasicpremium          IN NUMBER,
                                   --This is premium inclusive of commission but not inclusive of the taxes
                                   riskcommissionamount      IN NUMBER,
                                   risktraininglevy          IN NUMBER,
                                   policyphcf                IN NUMBER,
                                   premsection               IN NUMBER)
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
        v_user           VARCHAR2 (30) := 'VMUGO';
        v_exceptions     VARCHAR2 (10);
        v_policy_no      VARCHAR2 (30);
        v_pol_wef        DATE;
        v_pol_wet        DATE;
        v_rn_id          NUMBER;
        v_batchno        NUMBER;
        v_trans_no       NUMBER;
        v_itb_code       NUMBER;
    BEGIN
        /*This