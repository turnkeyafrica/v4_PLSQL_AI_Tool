PROCEDURE update_declarations (v_batch_no    IN NUMBER,
                                   v_policy_no   IN VARCHAR2,
                                   v_uw_yr       IN NUMBER,
                                   v_ipu_code    IN NUMBER DEFAULT NULL)
    IS
        v_cnt   NUMBER;

        CURSOR decl_cur IS
              SELECT poldc_policy_no,
                     poldc_uw_yr,
                     rskdc_ipu_id,
                     rltdc_sect_code,
                     SUM (NVL (rltdc_decl_amount, 0))     decl_amnt
                FROM gin_policy_declarations,
                     gin_risks_declarations,
                     gin_risk_limits_declarations
               WHERE     poldc_code = rskdc_poldc_code
                     AND rskdc_code = rltdc_rskdc_code
                     AND poldc_policy_no = v_policy_no
                     AND poldc_uw_yr = v_uw_yr
                     AND rskdc_ipu_id =
                         DECODE (NVL (v_ipu_code, 0),
                                 0, rskdc_ipu_id,
                                 (SELECT ipu_id
                                    FROM gin_insured_property_unds
                                   WHERE ipu_code = v_ipu_code))
            GROUP BY poldc_policy_no,
                     poldc_uw_yr,
                     rskdc_ipu_id,
                     rltdc_sect_code;
    BEGIN
        FOR decl_rec IN decl_cur
        LOOP
            BEGIN
                SELECT COUNT (1)
                  INTO v_cnt
                  FROM gin_insured_property_unds, gin_policies
                 WHERE     pol_batch_no = ipu_pol_batch_no
                       AND pol_batch_no = v_batch_no
                       AND ipu_id = decl_rec.rskdc_ipu_id;
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error ('Error verifying underwriting year..');
            END;

            IF NVL (v_cnt, 0) > 1
            THEN
                raise_error ('Risk or sections duplicated ..');
            END IF;

            UPDATE gin_policy_insured_limits
               SET pil_limit_amt = decl_rec.decl_amnt
             WHERE     pil_sect_code = decl_rec.rltdc_sect_code
                   AND pil_ipu_code =
                       (SELECT ipu_code
                          FROM gin_insured_property_unds, gin_policies
                         WHERE     pol_batch_no = ipu_pol_batch_no
                               AND pol_batch_no = v_batch_no
                               AND ipu_id = decl_rec.rskdc_ipu_id);
        END LOOP;
    END;