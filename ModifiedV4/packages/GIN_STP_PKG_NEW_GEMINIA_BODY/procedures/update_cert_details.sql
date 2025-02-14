PROCEDURE update_cert_details (v_ipu_code       IN NUMBER,
                                   v_tonnage        IN NUMBER,
                                   v_carry_cap      IN NUMBER DEFAULT NULL,
                                   v_pol_batch_no   IN NUMBER DEFAULT NULL)
    IS
        v_polc_pll      NUMBER;
        v_ct_sht_desc   VARCHAR2 (30);
        v_count1        NUMBER;
        v_scl_code      NUMBER;
        v_covt_code     NUMBER;
        v_ct_code       NUMBER;
    BEGIN
        --        BEGIN
        --
        --
        --            SELECT PCQ_CT_SHT_DESC
        --            INTO v_ct_sht_desc
        --            FROM GIN_PRINT_CERT_QUEUE
        --            WHERE PCQ_IPU_CODE = v_ipu_code
        --            AND PCQ_CODE IN (SELECT MAX(PCQ_CODE) FROM GIN_PRINT_CERT_QUEUE WHERE PCQ_IPU_CODE = v_ipu_code);
        --        EXCEPTION
        --        WHEN OTHERS THEN
        --              SELECT POLC_CT_SHT_DESC INTO v_ct_sht_desc
        --              FROM  GIN_POLICY_CERTS
        --              WHERE POLC_POL_BATCH_NO=v_pol_batch_no;
        --
        --        END;
        BEGIN
            SELECT ipu_sec_scl_code, ipu_covt_code
              INTO v_scl_code, v_covt_code
              FROM gin_insured_property_unds
             WHERE ipu_code = v_ipu_code;

            SELECT ct_code, ct_sht_desc
              INTO v_ct_code, v_ct_sht_desc
              FROM gin_subclass_cert_types, gin_cert_types
             WHERE     sct_ct_code = ct_code
                   AND sct_scl_code = v_scl_code
                   AND sct_covt_code = v_covt_code
                   AND NVL (ct_pass_dep, 'N') = 'Y'
                   AND ct_max_pass = v_carry_cap;

            IF v_ct_code IS NULL
            THEN
                BEGIN
                    SELECT pcq_ct_sht_desc
                      INTO v_ct_sht_desc
                      FROM gin_print_cert_queue
                     WHERE     pcq_ipu_code = v_ipu_code
                           AND pcq_code IN (SELECT MAX (pcq_code)
                                              FROM gin_print_cert_queue
                                             WHERE pcq_ipu_code = v_ipu_code);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        SELECT polc_ct_sht_desc
                          INTO v_ct_sht_desc
                          FROM gin_policy_certs
                         WHERE polc_pol_batch_no = v_pol_batch_no;
                END;
            ELSE
                UPDATE gin_policy_certs
                   SET polc_ct_sht_desc = v_ct_sht_desc,
                       polc_ct_code = v_ct_code
                 WHERE polc_ipu_code = v_ipu_code;

                UPDATE gin_print_cert_queue
                   SET pcq_ct_sht_desc = v_ct_sht_desc,
                       pcq_ct_code = v_ct_code
                 WHERE     pcq_ipu_code = v_ipu_code
                       AND pcq_code IN (SELECT MAX (pcq_code)
                                          FROM gin_print_cert_queue
                                         WHERE pcq_ipu_code = v_ipu_code);
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                BEGIN
                    SELECT pcq_ct_sht_desc
                      INTO v_ct_sht_desc
                      FROM gin_print_cert_queue
                     WHERE     pcq_ipu_code = v_ipu_code
                           AND pcq_code IN (SELECT MAX (pcq_code)
                                              FROM gin_print_cert_queue
                                             WHERE pcq_ipu_code = v_ipu_code);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        SELECT polc_ct_sht_desc
                          INTO v_ct_sht_desc
                          FROM gin_policy_certs
                         WHERE polc_pol_batch_no = v_pol_batch_no;
                END;
        END;

        --   RAISE_ERROR('v_ct_sht_desc=='||);

        --   RAISE_ERROR('v_ct_sht_desc=='||v_ct_sht_desc);
        IF v_ct_sht_desc = 'COMM'
        THEN
            IF gis_web_pkg.haspll (v_ipu_code)
            THEN
                SELECT pil_multiplier_rate
                  INTO v_polc_pll
                  FROM gin_policy_insured_limits
                 WHERE     pil_sect_sht_desc = 'PLL'
                       AND pil_ipu_code = v_ipu_code;

                UPDATE gin_print_cert_queue
                   SET pcq_passenger_no = v_polc_pll, pcq_tonnage = v_tonnage
                 WHERE pcq_ipu_code = v_ipu_code;

                UPDATE gin_policy_certs
                   SET polc_passenger_no = v_polc_pll,
                       polc_tonnage = v_tonnage
                 WHERE polc_ipu_code = v_ipu_code;
            ELSE
                UPDATE gin_print_cert_queue
                   SET pcq_passenger_no = v_carry_cap,
                       pcq_tonnage = v_tonnage
                 WHERE pcq_ipu_code = v_ipu_code;

                UPDATE gin_policy_certs
                   SET polc_passenger_no = v_carry_cap,
                       polc_tonnage = v_tonnage
                 WHERE polc_ipu_code = v_ipu_code;
            END IF;
        ELSE
            UPDATE gin_print_cert_queue
               SET pcq_passenger_no = v_carry_cap, pcq_tonnage = v_tonnage
             WHERE pcq_ipu_code = v_ipu_code AND pcq_status != 'P';

            UPDATE gin_policy_certs
               SET polc_passenger_no = v_carry_cap, polc_tonnage = v_tonnage
             WHERE polc_ipu_code = v_ipu_code;
        END IF;
    END;