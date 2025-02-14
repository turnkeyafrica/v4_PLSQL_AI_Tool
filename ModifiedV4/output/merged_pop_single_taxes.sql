```sql
PROCEDURE pop_single_taxes (
    v_pol_policy_no    IN VARCHAR2,
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
    v_override_rate    IN VARCHAR2 DEFAULT 'N'
)
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
        WHERE (   scl_code IS NULL
                OR scl_code IN (
                    SELECT clp_scl_code
                    FROM gin_product_sub_classes
                    WHERE clp_pro_code = v_pro_code
                    AND clp_scl_code = v_scl_code
                )
            )
        AND taxr_trnt_code = v_taxr_trnt_code
        AND taxr_trnt_code NOT IN (
            SELECT ptx_trac_trnt_code
            FROM gin_policy_taxes
            WHERE ptx_pol_batch_no = v_pol_batch_no
        );
    
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
        INTO v_pol_policy_type, v_pol_coinsurance, v_pol_coinsure_leader
        FROM gin_policies
        WHERE pol_batch_no = v_pol_batch_no;
    EXCEPTION
        WHEN OTHERS THEN
            raise_error ('Error Checking the policy ...');
    END;

    BEGIN
        v_allowsdonfacrein_param :=
            gin_parameters_pkg.get_param_varchar ('ALLOW_SD_ON_FACREIN');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_allowsdonfacrein_param := 'N';
        WHEN OTHERS THEN
            v_allowsdonfacrein_param := 'N';
    END;

    BEGIN
        v_allowsdoncoinfollower_param :=
            gin_parameters_pkg.get_param_varchar (
                'ALLOW_SD_ON_COINSURER_FOLLOWER'
            );
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_allowsdoncoinfollower_param := 'N';
        WHEN OTHERS THEN
            v_allowsdoncoinfollower_param := 'N';
    END;

    FOR sub_class_rec IN sub_class
    LOOP
        FOR taxes_rec IN taxes (sub_class_rec.ipu_sec_scl_code)
        LOOP
           IF     NVL (v_allowsdonfacrein_param, 'N') = 'N'
               AND NVL (v_pol_policy_type, 'N') = 'F'
               AND taxes_rec.trnt_type = 'SD'
            THEN
                raise_error (
                    'You cannot add Stamp Duty on this policy...'
                );
            END IF;

            IF     NVL (v_allowsdoncoinfollower_param, 'N') = 'N'
               AND NVL (v_pol_coinsurance, 'N') = 'Y'
               AND NVL (v_pol_coinsure_leader, 'N') = 'N'
               AND taxes_rec.trnt_type = 'SD'
            THEN
                raise_error (
                    'You cannot add Stamp Duty on this policy...'
                );
            END IF;
            
            IF v_add_edit = 'A' THEN
                IF NOT (
                    taxes_rec.trnt_type = 'SD'
                    AND NVL (v_pol_binder, 'N') = 'Y'
                ) THEN
                    BEGIN
                        INSERT INTO gin_policy_taxes (
                            ptx_trac_scl_code,
                            ptx_trac_trnt_code,
                            ptx_pol_policy_no,
                            ptx_pol_ren_endos_no,
                            ptx_pol_batch_no,
                            ptx_rate,
                            ptx_amount,
                            ptx_tl_lvl_code,
                            ptx_rate_type,
                            ptx_rate_desc,
                            ptx_endos_diff_amt,
                            ptx_tax_type,
                            ptx_risk_pol_level,
                            ptx_override,
                            ptx_override_amt
                        ) VALUES (
                            taxes_rec.taxr_scl_code,
                            taxes_rec.trnt_code,
                            v_pol_policy_no,
                            v_pol_endos_no,
                            v_pol_batch_no,
                            NVL (v_rate, taxes_rec.taxr_rate),
                            v_amt,
                            NVL (v_trans_lvl, 'UP'),
                            taxes_rec.taxr_rate_type,
                            taxes_rec.taxr_rate_desc,
                            NULL,
                            taxes_rec.trnt_type,
                            NVL (v_comp_lvl, 'P'),
                            v_override_rate,
                            v_amt
                        );
                    EXCEPTION
                        WHEN OTHERS THEN
                            raise_error ('Error applying taxes..');
                    END;
                END IF;
            ELSIF v_add_edit = 'E' THEN
              BEGIN
                    UPDATE gin_policy_taxes
                       SET ptx_trac_scl_code = taxes_rec.taxr_scl_code,
                           ptx_pol_policy_no = v_pol_policy_no,
                           ptx_pol_ren_endos_no = ptx_pol_ren_endos_no,
                           ptx_rate = NVL (v_rate, taxes_rec.taxr_rate),
                           ptx_amount = v_amt,
                           ptx_tl_lvl_code = NVL (v_trans_lvl, 'UP'),
                           ptx_rate_type = taxes_rec.taxr_rate_type,
                           ptx_rate_desc = taxes_rec.taxr_rate_desc,
                           ptx_endos_diff_amt = NULL,
                           ptx_tax_type = taxes_rec.trnt_type,
                           ptx_risk_pol_level = NVL (v_comp_lvl, 'P'),
                           ptx_override = v_override_rate,
                           ptx_override_amt = v_amt
                     WHERE     ptx_pol_batch_no = v_pol_batch_no
                           AND ptx_trac_trnt_code = v_taxr_trnt_code;
                  EXCEPTION
                        WHEN OTHERS THEN
                           raise_error ('Error applying taxes..');
                  END;
            END IF;
        END LOOP;
    END LOOP;
    
      FOR sub_class_rec IN sub_class
        LOOP
            FOR taxes_rec IN edit_taxes (sub_class_rec.ipu_sec_scl_code)
            LOOP
                IF v_add_edit = 'E'
                THEN
                    BEGIN
                        UPDATE gin_policy_taxes
                           SET ptx_trac_scl_code = taxes_rec.taxr_scl_code,
                               ptx_pol_policy_no = v_pol_policy_no,
                               ptx_pol_ren_endos_no = ptx_pol_ren_endos_no,
                               ptx_rate = NVL (v_rate, taxes_rec.taxr_rate),
                               ptx_amount = v_amt,
                               ptx_tl_lvl_code = NVL (v_trans_lvl, 'UP'),
                               ptx_rate_type = taxes_rec.taxr_rate_type,
                               ptx_rate_desc = taxes_rec.taxr_rate_desc,
                               ptx_endos_diff_amt = NULL,
                               ptx_tax_type = taxes_rec.trnt_type,
                               ptx_risk_pol_level = NVL (v_comp_lvl, 'P'),
                               ptx_override = v_override_rate,
                               ptx_override_amt = v_amt
                         WHERE     ptx_pol_batch_no = v_pol_batch_no
                               AND ptx_trac_trnt_code = v_taxr_trnt_code;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            raise_error ('Error applying taxes..');
                    END;
                END IF;
            END LOOP;
        END LOOP;
END;

```