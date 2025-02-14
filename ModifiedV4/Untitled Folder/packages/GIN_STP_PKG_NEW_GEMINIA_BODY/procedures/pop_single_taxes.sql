PROCEDURE pop_single_taxes (v_pol_policy_no    IN VARCHAR2,
                                v_pol_endos_no     IN VARCHAR2,
                                v_pol_batch_no     IN NUMBER,
                                v_pro_code         IN NUMBER,
                                v_pol_binder       IN VARCHAR2 DEFAULT 'N',
                                v_taxr_trnt_code   IN VARCHAR2,
                                v_tax_type         IN VARCHAR2,
                                v_trans_lvl        IN VARCHAR2,
                                v_comp_lvl         IN VARCHAR2,
                                v_rate             IN NUMBER,
                                v_amt              IN NUMBER,
                                v_add_edit         IN VARCHAR2,
                                v_override_rate    IN VARCHAR2 DEFAULT 'N')
    IS
        v_pol_policy_type               VARCHAR2 (1);
        v_allowsdonfacrein_param        VARCHAR2 (1);
        v_allowsdoncoinfollower_param   VARCHAR2 (1);
        v_pol_coinsurance               VARCHAR2 (1);
        v_pol_coinsure_leader           VARCHAR2 (1);

        CURSOR sub_class IS
            SELECT ipu_sec_scl_code
              FROM gin_insured_property_unds
             WHERE ipu_pol_batch_no = v_pol_batch_no;

        CURSOR taxes (v_scl_code NUMBER)
        IS
            SELECT *
              FROM gin_taxes_types_view
             WHERE     (   scl_code IS NULL
                        OR scl_code IN
                               (SELECT clp_scl_code
                                  FROM gin_product_sub_classes
                                 WHERE     clp_pro_code = v_pro_code
                                       AND clp_scl_code = v_scl_code))
                   --AND TRNT_MANDATORY = 'Y'
                   --AND TRNT_TYPE IN ('UTX','SD','UTL','EX','PHFUND')
                   AND taxr_trnt_code = v_taxr_trnt_code
                   AND taxr_trnt_code NOT IN
                           (SELECT ptx_trac_trnt_code
                              FROM gin_policy_taxes
                             WHERE ptx_pol_batch_no = v_pol_batch_no);

        CURSOR edit_taxes (v_scl_code NUMBER)
        IS
            SELECT *
              FROM gin_taxes_types_view
             WHERE     (   scl_code IS NULL
                        OR scl_code IN
                               (SELECT clp_scl_code
                                  FROM gin_product_sub_classes
                                 WHERE     clp_pro_code = v_pro_code
                                       AND clp_scl_code = v_scl_code))
                   AND taxr_trnt_code = v_taxr_trnt_code;
    BEGIN
        BEGIN
            SELECT pol_policy_type, pol_coinsurance, pol_coinsure_leader
              INTO v_pol_policy_type,
                   v_pol_coinsurance,
                   v_pol_coinsure_leader
              FROM gin_policies
             WHERE pol_batch_no = v_pol_batch_no;
        EXCEPTION
            WHEN OTHERS
            THEN
                raise_error ('Error Checking the policy ...');
        END;