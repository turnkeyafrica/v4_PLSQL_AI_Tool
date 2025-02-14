PROCEDURE gen_pol_numbers (v_prod_code     IN     NUMBER,
                               v_brn_code      IN     NUMBER,
                               v_uw_yr         IN     NUMBER,
                               v_trans_code    IN     VARCHAR2,
                               v_policy_no     IN OUT VARCHAR2,
                               v_endos_no      IN OUT VARCHAR2,
                               v_batch_no      IN OUT NUMBER,
                               v_serial        IN     NUMBER,
                               v_policy_type   IN     VARCHAR2,
                               v_coinsurance   IN     VARCHAR2,
                               v_div_code      IN     VARCHAR2)
    IS
        v_pol_type           VARCHAR2 (5);
        v_seq                NUMBER;
        v_seqno              VARCHAR2 (35);
        v_brn_sht_length     NUMBER;
        v_src                VARCHAR2 (1);
        v_binderpols_param   VARCHAR2 (1) DEFAULT 'N';
    BEGIN
        BEGIN
            v_binderpols_param :=
                gin_parameters_pkg.get_param_varchar (
                    'NORMAL_BINDER_POLS_USESAME_SEQ');
        EXCEPTION
            WHEN OTHERS
            THEN
                v_binderpols_param := 'N';
        END;

        IF NVL (v_binderpols_param, 'N') != 'Y'
        THEN
            IF NVL (v_policy_type, 'N') = 'N'
            THEN
                v_pol_type := 'P';
            ELSIF NVL (v_policy_type, 'N') = 'B'
            THEN
                v_pol_type := 'B';
            ELSE
                v_pol_type := 'F';
            END IF;
        ELSE
            IF NVL (v_policy_type, 'N') IN ('N', 'B')
            THEN
                v_pol_type := 'P';
            ELSE
                v_pol_type := 'F';
            END IF;
        END IF;

        IF NVL (v_coinsurance, 'N') != 'Y'
        THEN
            v_src := 'N';
        ELSE
            v_src := 'Y';
        END IF;

        IF v_policy_no IS NULL
        THEN
            -- RAISE_ERROR('v_div_code='||v_div_code||'v_policy_no='||v_policy_no);
            v_policy_no :=
                gin_sequences_pkg.get_number_format (v_pol_type,
                                                     v_prod_code,
                                                     v_brn_code,
                                                     v_uw_yr,
                                                     v_trans_code,
                                                     v_serial,
                                                     v_src,             --'N',
                                                     v_policy_no,
                                                     NULL,
                                                     NULL,
                                                     v_div_code);
        END IF;

        IF v_endos_no IS NULL
        THEN
            v_endos_no :=
                gin_sequences_pkg.get_number_format ('E',
                                                     v_prod_code,
                                                     v_brn_code,
                                                     v_uw_yr,
                                                     v_trans_code,
                                                     NULL,
                                                     v_src,             --'N',
                                                     v_policy_no,
                                                     v_div_code);
        END IF;

        IF v_batch_no IS NULL
        THEN
            SELECT    TO_NUMBER (TO_CHAR (SYSDATE, 'YY'))
                   || gin_pol_batch_no_seq.NEXTVAL
              INTO v_batch_no
              FROM DUAL;
        END IF;

        BEGIN
            check_policy_unique (v_policy_no);
        EXCEPTION
            WHEN OTHERS
            THEN
                BEGIN
                    SELECT TO_NUMBER (
                               SUBSTR (
                                   v_policy_no,
                                   DECODE (
                                       gin_parameters_pkg.get_param_varchar (
                                           'POL_SERIAL_AT_END'),
                                       'N', DECODE (
                                                v_pol_type,
                                                'P', gin_parameters_pkg.get_param_varchar (
                                                         'POL_SERIAL_POS'),
                                                gin_parameters_pkg.get_param_varchar (
                                                    'POL_FAC_SERIAL_POS')),
                                         LENGTH (v_policy_no)
                                       - gin_parameters_pkg.get_param_varchar (
                                             'POLNOSRLENGTH')
                                       + 1),
                                   gin_parameters_pkg.get_param_varchar (
                                       'POLNOSRLENGTH')))
                      INTO v_seq
                      FROM DUAL;
                --            EXCEPTION
                --               WHEN OTHERS
                --               THEN
                --                  raise_error ('ERROR SELECTING USED SEQUENCE...');
                END;

                BEGIN
                    gin_sequences_pkg.update_used_sequence (v_pol_type,
                                                            v_prod_code,
                                                            v_brn_code,
                                                            v_uw_yr,
                                                            v_trans_code,
                                                            v_seq,
                                                            v_policy_no);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        -- introduced for monarch where branch id vary from 2 charaters to 3 characters posing a challenge
                        BEGIN
                            SELECT TO_NUMBER (
                                       SUBSTR (
                                           v_policy_no,
                                           DECODE (
                                               gin_parameters_pkg.get_param_varchar (
                                                   'POL_SERIAL_AT_END'),
                                               'N', DECODE (
                                                        DECODE (v_pol_type,
                                                                'N', 'P',
                                                                'F'),
                                                        'P', gin_parameters_pkg.get_param_varchar (
                                                                 'POL_SERIAL_POS'),
                                                        gin_parameters_pkg.get_param_varchar (
                                                            'POL_FAC_SERIAL_POS')),
                                                 LENGTH (v_policy_no)
                                               - gin_parameters_pkg.get_param_varchar (
                                                     'POLNOSRLENGTH')
                                               + 1),
                                           gin_parameters_pkg.get_param_varchar (
                                               'POLNOSRLENGTH')))
                              INTO v_seqno
                              FROM DUAL;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                raise_error (
                                    'ERROR SELECTING USED SEQUENCE...');
                        END;

                        BEGIN
                            SELECT LENGTH (brn_sht_desc)
                              INTO v_brn_sht_length
                              FROM tqc_branches
                             WHERE brn_code = v_brn_code;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                NULL;
                        END;

                        IF NVL (v_brn_sht_length, 0) = 2
                        THEN
                            BEGIN
                                v_seq := TO_NUMBER (v_seqno);
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    NULL;
                            END;
                        ELSIF NVL (v_brn_sht_length, 0) = 3
                        THEN
                            BEGIN
                                v_seq := TO_NUMBER (SUBSTR (v_seqno, 2));
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    NULL;
                            END;
                        ELSE
                            raise_error ('Error here....');
                        END IF;

                        BEGIN
                            gin_sequences_pkg.update_used_sequence (
                                v_pol_type,
                                v_prod_code,
                                v_brn_code,
                                v_uw_yr,
                                v_trans_code,
                                v_seq,
                                v_policy_no);
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                raise_error (
                                    'Error Updating Used Sequence...');
                        END;
                --RAISE_ERROR('ERROR UPDATING USED SEQUENCE...');
                END;

                raise_error (
                       'Error generating Policy number at step 1 v_seq=== '
                    || v_seq
                    || '  '
                    || v_policy_no);
        END;
    END;