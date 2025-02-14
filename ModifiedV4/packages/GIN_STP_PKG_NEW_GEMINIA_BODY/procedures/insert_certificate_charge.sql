PROCEDURE insert_certificate_charge (
        v_pol_policy_no   IN VARCHAR2,
        v_pol_endos_no    IN VARCHAR2,
        v_pol_batch_no    IN NUMBER,
        v_pro_code        IN NUMBER,
        v_pol_binder      IN VARCHAR2 DEFAULT 'N')
    IS
        v_cert_charge      VARCHAR2 (5);
        v_cert_tran_code   VARCHAR2 (15);
        v_tax_type         VARCHAR2 (10);
        v_cnt              NUMBER;
        v_taxr_rate        NUMBER;
    BEGIN
        v_cert_charge :=
            gin_parameters_pkg.get_param_varchar ('CERTIFICATE_CHARGE_ON_EN');
        DBMS_OUTPUT.put_line ('v_cert_charge' || v_cert_charge);

        IF NVL (v_cert_charge, 'N') = 'Y'
        THEN
            v_cert_tran_code :=
                gin_parameters_pkg.get_param_varchar (
                    'CERTIFICATE_CHARGE_TRAN_CODE');
            DBMS_OUTPUT.put_line ('v_cert_tran_code' || v_cert_tran_code);

            IF v_cert_tran_code IS NOT NULL
            THEN
                BEGIN
                    SELECT trnt_type, taxr_rate
                      INTO v_tax_type, v_taxr_rate
                      FROM gin_taxes_types_view
                     WHERE taxr_trnt_code = v_cert_tran_code;
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        raise_error (
                               'Certificate charge code '
                            || v_cert_tran_code
                            || ' not defined in setups..');
                    WHEN TOO_MANY_ROWS
                    THEN
                        raise_error (
                               'More than one Certificate charge code '
                            || v_cert_tran_code
                            || '  defined in setups..');
                END;

                DBMS_OUTPUT.put_line ('v_tax_type' || v_tax_type);

                IF v_tax_type IS NOT NULL
                THEN
                    SELECT COUNT (1)
                      INTO v_cnt
                      FROM gin_policy_taxes
                     WHERE     ptx_pol_batch_no = v_pol_batch_no
                           AND ptx_trac_trnt_code = v_cert_tran_code;

                    DBMS_OUTPUT.put_line ('v_cnt' || v_cnt);

                    IF NVL (v_cnt, 0) = 0
                    THEN
                        pop_single_taxes (v_pol_policy_no,
                                          v_pol_endos_no,
                                          v_pol_batch_no,
                                          v_pro_code,
                                          v_pol_binder,
                                          v_cert_tran_code,
                                          v_tax_type,
                                          'UP',
                                          'P',
                                          v_taxr_rate,
                                          v_taxr_rate,
                                          'A');
                    END IF;
                END IF;
            END IF;
        END IF;
    END;