PROCEDURE pop_taxes (
        v_pol_policy_no   IN VARCHAR2,
        v_pol_endos_no    IN VARCHAR2,
        v_pol_batch_no    IN NUMBER,
        v_pro_code        IN NUMBER,
        v_pol_binder      IN VARCHAR2 DEFAULT 'N',
        v_trans_type      IN VARCHAR2
    ) IS

        v_cnt                      NUMBER;
        v_pol_policy_type          VARCHAR2(1);
        v_pop_taxes                VARCHAR2(1);
        v_scl_code                 NUMBER;
        v_allowsdonfacrein_param   VARCHAR2(1);
        v_con_type                 VARCHAR2(100) := NULL;
        CURSOR sub_class IS SELECT
                                *
                            FROM
                                gin_insured_property_unds
                            WHERE
                                ipu_pol_batch_no = v_pol_batch_no;

        CURSOR taxes (
            v_scl_code NUMBER
        ) IS SELECT
                 *
             FROM
                 gin_taxes_types_view
             WHERE
                 ( scl_code IS NULL
                   OR scl_code IN (
                     SELECT
                         clp_scl_code
                     FROM
                         gin_product_sub_classes
                     WHERE
                         clp_pro_code = v_pro_code
                         AND clp_scl_code = v_scl_code
                 ) )
                 AND trnt_mandatory = 'Y'
                 AND trnt_type IN (
                     'UTX',
                     'SD',
                     'UTL',
                     'EX',
                     'PHFUND',
                     'MPSD',
                     'MSD',
                     'COPHFUND',
                     'PRM-VAT',
                     'ROAD',
                     'HEALTH',
                     'CERTCHG',
                     'MOTORTX'
                 )
                 AND taxr_trnt_code NOT IN (
                     SELECT
                         ptx_trac_trnt_code
                     FROM
                         gin_policy_taxes
                     WHERE
                         ptx_pol_batch_no = v_pol_batch_no
                 )
                 AND nvl(DECODE(v_trans_type,'NB',trnt_apply_nb,'SP',trnt_apply_sp,'RN',trnt_apply_rn,'EN',trnt_apply_en,'CN',trnt_apply_cn
                ,'EX',trnt_apply_ex,'DC',trnt_apply_dc,'RE',trnt_apply_re,'ME',trnt_apply_re /*This was added to resolve ME policies which were not populating taxes*/),'N') = 'Y'
                 AND trnt_code NOT IN (
                     SELECT
                         petx_trnt_code
                     FROM
                         gin_product_excluded_taxes
                     WHERE
                         petx_pro_code = v_pro_code
                 );

    BEGIN
        BEGIN
            SELECT
                pol_policy_type,
                nvl(pol_pop_taxes,'Y')
            INTO
                v_pol_policy_type,
                v_pop_taxes
            FROM
                gin_policies
            WHERE
                pol_batch_no = v_pol_batch_no;

        EXCEPTION
            WHEN OTHERS THEN
                raise_error('Error Checking the policy ...');
        END;