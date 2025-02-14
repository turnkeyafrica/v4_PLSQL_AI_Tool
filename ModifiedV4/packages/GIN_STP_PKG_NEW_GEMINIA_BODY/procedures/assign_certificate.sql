PROCEDURE assign_certificate (
        v_ipu_code                IN     NUMBER,
        v_ct_code                 IN     NUMBER,
        v_wef_date                IN     DATE,
        v_wet_date                IN     DATE,
        v_error                      OUT VARCHAR2,
        v_add_edit                IN     VARCHAR DEFAULT 'A',
        v_pass_no                 IN     VARCHAR2 DEFAULT NULL,
        v_tonnage                 IN     VARCHAR2 DEFAULT NULL,
        v_polc_cod                IN     NUMBER DEFAULT NULL,
        v_polc_status             IN     VARCHAR2 DEFAULT NULL,
        v_print_status            IN     VARCHAR2 DEFAULT NULL,
        v_polc_reason_cancelled   IN     VARCHAR2 DEFAULT NULL)
    IS
        CURSOR rsk IS
            SELECT ipu_code,
                   ipu_property_id,
                   ipu_wef,
                   ipu_wet,
                   ipu_pol_policy_no,
                   ipu_pol_ren_endos_no,
                   ipu_pol_batch_no,
                   pol_agnt_agent_code,
                   pol_agnt_sht_desc,
                   gis_utilities.clnt_name (clnt_name, clnt_other_names)
                       insured,
                   ipu_covt_code,
                   ipu_sec_scl_code,
                   ipu_eff_wef,
                   ipu_eff_wet,
                   ipu_id,
                   pol_brn_code,
                   ipu_covt_sht_desc,
                   ipu_prp_code,
                   pol_uw_year,
                   pol_policy_status,
                   pol_binder_policy,
                   pol_pro_code,
                   ipu_prev_ipu_code,
                   ipu_cover_suspended,
                   ipu_risk_note
              FROM gin_policies,
                   gin_insured_property_unds,
                   gin_policy_insureds,
                   tqc_clients
             WHERE     ipu_pol_batch_no = pol_batch_no
                   AND ipu_polin_code = polin_code
                   AND polin_prp_code = clnt_code
                   AND ipu_code = v_ipu_code;

        v_wef                         DATE;
        v_wet                         DATE;
        v_ct_sht_desc                 VARCHAR2 (25);
        v_pol_status                  VARCHAR2 (5);
        v_user                        VARCHAR2 (35)
            := pkg_global_vars.get_pvarchar2 ('PKG_GLOBAL_VARS.PVG_USERNAME');
        v_cnt                         NUMBER;
        v_polc_code                   NUMBER;
        v_cert_no                     VARCHAR2 (30);
        v_comp_name                   VARCHAR2 (75)
                                          := tqc_interfaces_pkg.organizationname (37, 'N');
        v_uw_certs                    VARCHAR2 (5);
        v_cert_sht_period             NUMBER;
        v_rqrd_docs                   NUMBER;
        v_ipu_eff_wet                 DATE;
        v_pol_batch_no                NUMBER;
        v_pol_prem_computed           VARCHAR2 (10);
        v_pol_statusi                 VARCHAR2 (10);
        v_polc_passenger_no           VARCHAR2 (10);
        v_polc_passenger_no2          VARCHAR2 (10);
        v_polc_tonnage                NUMBER;
        v_polc_pll                    NUMBER;
        v_backdating_of_certs_param   VARCHAR2 (1);
        v_loaded_cert                 NUMBER;
        v_loadedcert_no               VARCHAR2 (30);
        v_ct_type                     VARCHAR2 (30);
        v_print_date                  DATE;
        v_polc_print_status           VARCHAR2 (1);
        v_polc_loaded                 VARCHAR2 (1);
        v_polc_lot_id                 VARCHAR2 (100);
        v_gnr_ct_sht_desc             VARCHAR2 (100);
        v_gnr_ct_code                 NUMBER;
        v_printed_status              VARCHAR2 (1);
    BEGIN
        --RAISE_ERROR('IN');
        /*IF gin_parameters_pkg.get_param_varchar ('ALLOW_CERTIFICATE_BALANCES') =
                                                                            'N'
        THEN
           BEGIN
              SELECT ipu_pol_batch_no
                INTO v_pol_batch_no
                FROM gin_insured_property_unds
               WHERE ipu_code = v_ipu_code;

              IF gis_accounts_utilities.get_pdr_balance (v_pol_batch_no) > 0
              THEN
                 v_error :=
                    'Cannot Allocate Certificate when there is pending balance';
                 RETURN;
              END IF;
           EXCEPTION
              WHEN NO_DATA_FOUND
              THEN
                 NULL;
           END;
        END IF;*/

        IF NVL (v_add_edit, 'A') = 'E'
        THEN
            /*CHECK WHETHER THE EDITTED CERTIFICATE WAS ALREADY PRINTED*/
            BEGIN
                SELECT polc_print_status
                  INTO v_printed_status
                  FROM gin_policy_certs
                 WHERE polc_code = v_polc_cod;
            EXCEPTION
                WHEN OTHERS
                THEN
                    v_printed_status := 'N';
            END;

            /*INHIBIT CANCELLING OF A PRINTED CERTIFICATE*/
            IF     NVL (v_printed_status, 'N') != 'P'
               AND NVL (v_polc_status, 'N') = 'C'
            THEN
                v_error := 'You can only cancel a printed certificate....';
                RETURN;
            END IF;

            /*INHIBIT EDITING OF PRINT STATUS OF AN ALREADY PRINTED STATUS*/
            IF     NVL (v_printed_status, 'N') = 'P'
               AND NVL (v_print_status, 'N') <> 'P'
            THEN
                v_error :=
                    'You cannot change the print status of an already printed certificate..';
                RETURN;
            END IF;
        END IF;

        BEGIN
            SELECT gin_parameters_pkg.get_param_varchar (
                       'ALLOW_BACKDATING_OF_CERTS')
              INTO v_backdating_of_certs_param
              FROM DUAL;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                v_backdating_of_certs_param := 'N';
            WHEN OTHERS
            THEN
                v_backdating_of_certs_param := 'N';
        END;

        BEGIN
            IF v_pol_batch_no IS NOT NULL
            THEN
                SELECT pol_prem_computed, pol_policy_status
                  INTO v_pol_prem_computed, v_pol_statusi
                  FROM gin_policies
                 WHERE pol_batch_no = v_pol_batch_no;

                IF     NVL (v_pol_prem_computed, 'N') != 'Y'
                   AND v_pol_statusi != 'CO'
                THEN
                    v_error :=
                        'Please compute premium on policy. Changes have been made on the policy..';
                    RETURN;
                END IF;
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                raise_error ('Error Getting Policy Details');
        END;

        BEGIN
            SELECT mcoms_carry_capacity, mcoms_tonnage
              INTO v_polc_passenger_no, v_polc_tonnage
              FROM gin_motor_commercial_sch
             WHERE mcoms_ipu_code = v_ipu_code;
        --AND NVL (mcoms_acc_limit, 'N') = 'N';
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                NULL;
            WHEN OTHERS
            THEN
                ROLLBACK;
                raise_error ('Error getting tonnage/no. of passengers...');
                RETURN;
        END;

        BEGIN
            SELECT pil_multiplier_rate
              INTO v_polc_pll
              FROM gin_policy_insured_limits
             WHERE pil_sect_sht_desc = 'PLL' AND pil_ipu_code = v_ipu_code;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                NULL;
            WHEN OTHERS
            THEN
                ROLLBACK;
                raise_error ('Error getting PLL...');
                RETURN;
        END;

        IF v_polc_pll IS NOT NULL
        THEN
            v_polc_passenger_no := v_polc_pll;
            v_polc_passenger_no2 := v_polc_pll;
        ELSE
            v_polc_passenger_no2 := v_polc_passenger_no;
            v_polc_passenger_no := NULL;
        END IF;

        IF NVL (v_polc_tonnage, 0) = 0
        THEN
            v_polc_tonnage := TO_NUMBER (v_tonnage);
        END IF;

        BEGIN
            SELECT ipu_eff_wet
              INTO v_ipu_eff_wet
              FROM gin_insured_property_unds
             WHERE ipu_code = v_ipu_code;
        EXCEPTION
            WHEN OTHERS
            THEN
                v_ipu_eff_wet := v_wet_date;
        END;

        --raise_error ('v_polc_passenger_no'||v_polc_passenger_no||'v_polc_pll'||v_polc_pll||'v_polc_tonnage'||v_polc_tonnage);
        IF NVL (v_add_edit, 'A') = 'A' AND v_ct_code IS NOT NULL
        THEN
            FOR r IN rsk
            LOOP
                IF NVL (r.ipu_cover_suspended, 'N') = 'Y'
                THEN
                    raise_error (
                        'Cannot assign a certificate to a suspended risk..');
                END IF;

                v_wef := v_wef_date;

                IF v_wef IS NULL
                THEN
                    v_wef := r.ipu_wef;
                END IF;

                v_wet := v_wet_date;

                IF NVL (v_backdating_of_certs_param, 'N') != 'Y'
                THEN
                    v_wef := GREATEST (v_wef, TRUNC (SYSDATE));

                    IF v_wet IS NULL
                    THEN
                        v_wet := r.ipu_wet;
                    END IF;

                    IF    NVL (v_add_edit, 'A') = 'A'
                       OR NVL (v_add_edit, 'A') = 'E'
                    THEN
                        IF v_wef IS NULL OR v_wet IS NULL
                        THEN
                            raise_error (
                                   'Must specify certificates cover effective dates..'
                                || v_add_edit);
                        ELSIF v_wef >= v_wet
                        THEN
                            raise_error (
                                   'The Wet date entered '
                                || v_wet
                                || ' is earlier than the ''Wef'' '
                                || v_wef
                                || ' Date.  Please Re-enter');
                        ELSIF v_wef < GREATEST (r.ipu_wef, TRUNC (SYSDATE))
                        THEN
                            raise_error (
                                '1 Certificate effective dates can not be before todays date or the risk cover from date..');
                        ELSIF v_wet >
                              GREATEST (v_ipu_eff_wet, TRUNC (SYSDATE))
                        THEN
                            raise_error (
                                'You Cannot Have A Certificate For A Cover Period, Outside The Risk Cover');
                        END IF;

                        IF     NVL (v_print_status, 'P') = 'R'
                           AND NVL (v_polc_status, 'A') = 'C'
                        THEN
                            raise_error (
                                'You Cannot Cancel A Certificate Which is Ready for Printing');
                        END IF;

                        BEGIN
                            SELECT ct_sht_desc, ct_type
                              INTO v_ct_sht_desc, v_ct_type
                              FROM gin_cert_types
                             WHERE ct_code = v_ct_code;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                tqc_error_manager.raise_unanticipated (
                                    'Error retrieving certicate type details.');
                        END;
                    END IF;
                ELSE
                    v_wef := r.ipu_wef;

                    IF v_wet IS NULL
                    THEN
                        v_wet := r.ipu_wet;
                    END IF;

                    IF    NVL (v_add_edit, 'A') = 'A'
                       OR NVL (v_add_edit, 'A') = 'E'
                    THEN
                        IF v_wef IS NULL OR v_wet IS NULL
                        THEN
                            raise_error (
                                   'Must specify certificates cover effective dates..'
                                || v_add_edit);
                        ELSIF v_wef >= v_wet
                        THEN
                            raise_error (
                                   'The Wet date entered '
                                || v_wet
                                || ' is earlier than the ''Wef'' '
                                || v_wef
                                || ' Date.  Please Re-enter');
                        ELSIF v_wef < r.ipu_wef
                        THEN
                            raise_error (
                                   'The Wet date entered '
                                || v_wet
                                || ' is earlier than the ''Wef'' '
                                || v_wef
                                || ' Date.  Please Re-enter');
                        ELSIF v_wet >
                              GREATEST (v_ipu_eff_wet, TRUNC (SYSDATE))
                        THEN
                            raise_error (
                                'You Cannot Have A Certificate For A Cover Period, Outside The Risk Cover');
                        END IF;

                        IF     NVL (v_print_status, 'P') = 'R'
                           AND NVL (v_polc_status, 'A') = 'C'
                        THEN
                            raise_error (
                                'You Cannot Cancel A Certificate Which is Ready for Printing');
                        END IF;

                        BEGIN
                            SELECT ct_sht_desc, ct_type
                              INTO v_ct_sht_desc, v_ct_type
                              FROM gin_cert_types
                             WHERE ct_code = v_ct_code;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                tqc_error_manager.raise_unanticipated (
                                    'Error retrieving certicate type details.');
                        END;
                    END IF;
                END IF;

                --RAISE_ERROR(v_wef||' = '||v_wet);
                /*
                BEGIN
                select AGC_CODE,SCT_CT_SHT_DESC,AGC_CER_LOT_ID,AGC_CERT_YEAR
                into v_agc_code,v_sct_ct_sht_desc,v_agc_cer_lot_id,v_agc_cert_year
                from gin_subclass_cert_types, GIN_AGENT_CERTIFICATES
                where SCT_CT_CODE = AGC_CT_CODE
                and SCT_SCL_CODE = R.IPU_SEC_SCL_CODE
                and sct_covt_code =R.IPU_COVT_CODE
                AND SCT_CT_CODE = v_ct_code
                and AGC_AGNT_AGENT_CODE =R.POL_AGNT_AGENT_CODE
                AND (nvl(AGC_CERT_TO,0) - NVL(AGC_CERT_FROM,0) > 0 OR nvl(AGC_CERT_TO,0) - nvl(AGC_LAST_PRINTED_CERT,0)> 0)
                AND AGC_CURRENT_STOCK = 'Y';
                EXCEPTION
                WHEN OTHERS THEN
                    RAISE_ERROR('Error retrieving certicate type details.');
                END;*/

                --RAISE_ERROR(v_add_edit);
                IF NVL (v_add_edit, 'A') = 'A'
                THEN
                    BEGIN
                        SELECT COUNT (1)
                          INTO v_cnt
                          FROM gin_policy_certs
                         WHERE     polc_ipu_id = r.ipu_id
                               AND v_wef <= polc_wet
                               AND (   polc_wef BETWEEN r.ipu_eff_wef
                                                    AND r.ipu_eff_wet
                                    OR polc_wet BETWEEN r.ipu_eff_wef
                                                    AND r.ipu_eff_wet)
                               AND polc_status != 'C';
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            raise_error (
                                'Error checking for certificate duplicates..');
                    END;

                    IF NVL (v_cnt, 0) != 0
                    THEN
                        RETURN;
                    --                  raise_error
                    --                             (   'Must cancel all active certificates as at '
                    --                              || TO_CHAR (v_wef, 'DD/MON/RRRR')
                    --                              || ' before allocating another..'
                    --                             );
                    END IF;

                    BEGIN
                        v_uw_certs :=
                            gin_parameters_pkg.get_param_varchar ('UW_CERTS');
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            v_uw_certs := 'N';
                    END;

                    BEGIN
                        SELECT COUNT (1)
                          INTO v_loaded_cert
                          FROM gin_returned_certificates
                         WHERE     NVL (gnr_allocated, 'N') != 'Y'
                               AND gnr_risk_id = r.ipu_property_id
                               AND gnr_risk_note = r.ipu_risk_note;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            v_loaded_cert := 0;
                    END;

                    IF v_loaded_cert = 1
                    THEN
                        BEGIN
                            SELECT REGEXP_REPLACE (gnr_cert_no,
                                                   '[^0-9]+',
                                                   '')           gnr_cert_no,
                                   gnr_issue_date,
                                   gin_certificate_loading_pkg.get_cert_lot (
                                       REGEXP_REPLACE (gnr_cert_no,
                                                       '[^0-9]+',
                                                       ''),
                                       gnr_ct_code               /*v_ct_code*/
                                                  ,
                                       r.pol_agnt_agent_code)    polc_lot_id,
                                   gnr_ct_sht_desc,
                                   gnr_ct_code,
                                   DECODE (gnr_status, 'S', 'C', 'P')
                              INTO v_loadedcert_no,
                                   v_print_date,
                                   v_polc_lot_id,
                                   v_gnr_ct_sht_desc,
                                   v_gnr_ct_code,
                                   v_polc_print_status
                              FROM gin_returned_certificates
                             WHERE     NVL (gnr_allocated, 'N') != 'Y'
                                   AND gnr_risk_id = r.ipu_property_id
                                   AND gnr_risk_note = r.ipu_risk_note;

                            --                      v_polc_print_status:='P';
                            v_polc_loaded := 'Y';
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                NULL;
                        END;
                    END IF;

                    --raise_error('v_uw_certs='||v_uw_certs);
                    IF NVL (v_uw_certs, 'N') = 'Y'
                    THEN
                        BEGIN
                            v_cert_no :=
                                gin_sequences_pkg.get_cert_number_format (
                                    'C',
                                    r.ipu_sec_scl_code,
                                    r.pol_brn_code,
                                    r.pol_uw_year,
                                    r.pol_policy_status,
                                    r.ipu_covt_code);
                        --                  EXCEPTION
                        --                     WHEN OTHERS
                        --                     THEN
                        --                        raise_error
                        --                                 ('Error : Generating certificate number ...');
                        --NULL;
                        END;
                    END IF;

                    IF NVL (v_loaded_cert, 0) = 1
                    THEN
                        v_cert_no := v_loadedcert_no;
                    END IF;

                    v_pol_status := 'A';

                    BEGIN
                        SELECT certificate_no_seq.NEXTVAL
                          INTO v_polc_code
                          FROM DUAL;

                        --            RAISE_eRROR(' v_cert_no '||v_cert_no);
                        INSERT INTO gin_policy_certs (polc_issue_dt,
                                                      polc_pol_policy_no,
                                                      polc_pol_ren_endos_no,
                                                      polc_pol_batch_no,
                                                      polc_cer_cert_no,
                                                      polc_ct_code,
                                                      polc_agnt_agent_code,
                                                      polc_agnt_sht_desc,
                                                      polc_property_id,
                                                      polc_ipu_code,
                                                      polc_status,
                                                      polc_print_dt,
                                                      polc_reason_cancelled,
                                                      polc_cancel_dt,
                                                      polc_wef,
                                                      polc_wet,
                                                      polc_scl_code,
                                                      polc_lot_id,
                                                      polc_prefix,
                                                      pocl_postfix,
                                                      polc_cert_year,
                                                      polc_code,
                                                      polc_client_policy_no,
                                                      polc_ct_sht_desc,
                                                      polc_print_status,
                                                      polc_check_cert,
                                                      polc_check_cancel,
                                                      polc_ipu_id,
                                                      polc_prp_code,
                                                      pocl_covt_sht_desc,
                                                      polc_tonnage,
                                                      polc_passenger_no,
                                                      polc_alloc_by,
                                                      polc_return_date,
                                                      polc_return_prep_by,
                                                      polc_return_remarks,
                                                      polc_returned,
                                                      polc_signed_date,
                                                      polc_brn_code,
                                                      polc_signed,
                                                      polc_signed_by,
                                                      polc_agc_code,
                                                      polc_loaded)
                             VALUES (NVL (v_print_date, TRUNC (SYSDATE)),
                                     r.ipu_pol_policy_no,
                                     r.ipu_pol_ren_endos_no,
                                     r.ipu_pol_batch_no,
                                     v_cert_no,
                                     NVL (v_gnr_ct_code, v_ct_code),
                                     r.pol_agnt_agent_code,
                                     r.pol_agnt_sht_desc,
                                     r.ipu_property_id,
                                     r.ipu_code,
                                     v_pol_status,
                                     v_print_date,
                                     v_polc_reason_cancelled,
                                     NULL,
                                     v_wef,
                                     v_wet,
                                     r.ipu_sec_scl_code,
                                     v_polc_lot_id,
                                     NULL,
                                     NULL,
                                     NULL,
                                     v_polc_code,
                                     r.ipu_pol_policy_no,
                                     NVL (v_gnr_ct_sht_desc, v_ct_sht_desc),
                                     NVL (v_polc_print_status, 'R'),
                                     'Y',
                                     0,
                                     r.ipu_id,
                                     r.ipu_prp_code,
                                     r.ipu_covt_sht_desc,
                                     v_polc_tonnage,
                                     v_polc_passenger_no,
                                     v_user,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     r.pol_brn_code,
                                     'N',
                                     NULL,
                                     NULL,
                                     v_polc_loaded);
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            raise_error (
                                   'Error inserting certificate record..'
                                || r.ipu_property_id
                                || ';'
                                || r.ipu_risk_note);
                    END;

                    BEGIN
                        INSERT INTO gin_print_cert_queue (
                                        pcq_pol_policy_no,
                                        pcq_pol_ren_endos_no,
                                        pcq_pol_batch_no,
                                        pcq_ipu_code,
                                        pcq_ct_code,
                                        pcq_ct_sht_desc,
                                        pcq_ipu_property_id,
                                        pcq_date_time,
                                        pcq_agnt_agent_code,
                                        pcq_agnt_sht_desc,
                                        pcq_polc_code,
                                        pcq_client_policy_no,
                                        pcq_code,
                                        pcq_wet,
                                        pcq_status,
                                        pcq_client_name,
                                        pcq_issued_by,
                                        pcq_covt_sht_desc,
                                        pcq_brn_code,
                                        pcq_agc_code,
                                        pcq_cert_no,
                                        pcq_passenger_no,
                                        pcq_tonnage)
                             VALUES (r.ipu_pol_policy_no,
                                     r.ipu_pol_ren_endos_no,
                                     r.ipu_pol_batch_no,
                                     r.ipu_code,
                                     NVL (v_gnr_ct_code, v_ct_code),
                                     v_ct_sht_desc,
                                     r.ipu_property_id,
                                     v_wef,
                                     r.pol_agnt_agent_code,
                                     r.pol_agnt_sht_desc,
                                     v_polc_code,
                                     r.ipu_pol_policy_no,
                                     gin_pcq_code_seq.NEXTVAL,
                                     v_wet,
                                     'N',
                                     r.insured,
                                     v_comp_name,
                                     r.ipu_covt_sht_desc,
                                     r.pol_brn_code,
                                     NULL,
                                     v_cert_no,
                                     v_polc_passenger_no,
                                     v_polc_tonnage);

                        BEGIN
                            gin_stp_pkg.update_cert_details (
                                r.ipu_code,
                                v_polc_tonnage,
                                v_polc_passenger_no2);
                        --         RAISE_ERROR('IN  -----v_polc_passenger_no2 == '||v_polc_passenger_no2);
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                raise_error (
                                    'Error updating certificate details');
                        END;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            raise_error (
                                'Error inserting certificate in print queue.');
                    END;

                    IF NVL (v_loaded_cert, 0) = 1
                    THEN
                        BEGIN
                            gin_certificate_loading_pkg.update_cert_details (
                                r.ipu_property_id,
                                r.ipu_risk_note,
                                r.ipu_code);
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                NULL;
                        END;
                    END IF;

                    IF v_cert_no IS NOT NULL
                    THEN
                        UPDATE gin_insured_property_unds
                           SET ipu_cert_no = v_ct_type || v_cert_no
                         WHERE ipu_code = r.ipu_code;
                    END IF;

                    IF     r.pol_policy_status = 'EN'
                       AND (   r.ipu_code = r.ipu_prev_ipu_code
                            OR r.ipu_cover_suspended = 'R')
                    THEN
                        insert_certificate_charge (r.ipu_pol_policy_no,
                                                   r.ipu_pol_ren_endos_no,
                                                   r.ipu_pol_batch_no,
                                                   r.pol_pro_code,
                                                   r.pol_binder_policy);
                    END IF;
                ELSIF     NVL (v_add_edit, 'A') = 'E'
                      AND NVL (v_polc_status, 'A') = 'C'
                THEN
                    UPDATE gin_policy_certs
                       SET polc_status = v_polc_status,
                           polc_print_status = v_print_status
                     WHERE polc_code = v_polc_cod;
                END IF;
            END LOOP;
        ELSIF NVL (v_add_edit, 'A') = 'E'
        THEN
            BEGIN
                SELECT param_value
                  INTO v_cert_sht_period
                  FROM gin_parameters
                 WHERE param_name = 'CERT_SHT_PERIOD';
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    v_cert_sht_period := 0;
            END;

            IF NVL (v_cert_sht_period, 0) != 0
            THEN
                BEGIN
                    SELECT COUNT (usdocr_id)
                      INTO v_rqrd_docs
                      FROM gin_uw_doc_reqrd_submtd
                     WHERE     usdocr_ipu_code = v_ipu_code
                           AND usdocr_submited = 'N'
                           AND usdocr_docr_id IN
                                   (SELECT docr_id
                                      FROM gin_documents_reqrd
                                     WHERE     docr_mandtry = 'Y'
                                           AND docr_cert_doc = 'Y'
                                           AND docr_level = 'UW'
                                           AND docr_clp_code IN
                                                   (SELECT ipu_clp_code
                                                      FROM gin_policy_active_risk_vw
                                                           a,
                                                           gin_insured_property_unds
                                                           b
                                                     WHERE     a.ipu_code =
                                                               b.ipu_code
                                                           AND b.ipu_code =
                                                               v_ipu_code
                                                           AND ROWNUM = 1));
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        v_rqrd_docs := 0;
                END;

                IF     NVL (v_rqrd_docs, 0) > 0
                   AND ABS (v_wet_date - v_wef_date) > v_cert_sht_period
                THEN
                    --                     SELECT polc_wet
                    --                       INTO v_wet_date
                    --                       FROM gin_policy_certs
                    --                      WHERE polc_code = v_polc_cod;
                    raise_error (
                           'Cannot Issue certificate for a period of more than '
                        || v_cert_sht_period
                        || ' days without the mandatory documents!');
                END IF;
            END IF;

            SELECT ipu_eff_wet
              INTO v_ipu_eff_wet
              FROM gin_insured_property_unds
             WHERE ipu_code = v_ipu_code;

            IF v_wet_date > v_ipu_eff_wet
            THEN
                --                  SELECT polc_wet
                --                    INTO v_wet_date
                --                    FROM gin_policy_certs
                --                   WHERE polc_code = v_polc_cod;
                raise_error (
                    'You Cannot Have A Certificate For A Cover Period, Outside The Risk Cover');
            END IF;

            --raise_error(v_wef_date||'='||v_wet_date||'='||v_polc_cod);
            UPDATE gin_policy_certs
               SET polc_status = v_polc_status,
                   polc_wef = v_wef_date,
                   polc_wet = v_wet_date,
                   polc_print_status = v_print_status
             WHERE polc_code = v_polc_cod;

            UPDATE gin_print_cert_queue
               SET pcq_wet = NVL (v_wet_date, pcq_wet)
             WHERE pcq_polc_code = v_polc_cod;
        ELSIF NVL (v_add_edit, 'A') = 'D'
        THEN
            SELECT polc_cer_cert_no
              INTO v_cert_no
              FROM gin_policy_certs
             WHERE polc_code = v_polc_cod;

            IF NVL (v_cert_no, 'N') = 'N'
            THEN
                DELETE FROM gin_print_cert_queue
                      WHERE pcq_polc_code = v_polc_cod;

                DELETE FROM gin_policy_certs
                      WHERE polc_code = v_polc_cod;
            ELSE
                raise_error (
                    'Cannot delete Because A Certificate no. has already been allocated');
            END IF;
        END IF;
    END;