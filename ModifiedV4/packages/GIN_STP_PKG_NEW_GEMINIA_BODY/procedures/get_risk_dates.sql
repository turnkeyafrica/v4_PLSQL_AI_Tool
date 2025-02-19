PROCEDURE get_risk_dates (
        v_scl_code                 IN     NUMBER,
        v_covt_code                IN     NUMBER,
        v_pol_tot_instlmt          IN     NUMBER,
        v_pro_expiry_period        IN     VARCHAR2,
        v_pol_cover_from           IN     DATE,
        v_pol_cover_to             IN     DATE,
        v_increment                IN     VARCHAR2,
        v_increment_by             IN     NUMBER,
        v_susp_reinstate           IN     VARCHAR2,
        v_susp_reinst_type         IN     VARCHAR2,
        v_risk_pymt_install_pcts   IN OUT VARCHAR2,
        v_wef_date                 IN OUT DATE,
        v_wet_date                 IN OUT DATE,
        v_install_period           IN OUT NUMBER,
        v_cover_days               IN OUT NUMBER,
        v_susp_wef                 IN OUT DATE,
        v_susp_wet                 IN OUT DATE,
        v_new_pol_wet                 OUT DATE,
        v_pol_install_wet          IN OUT DATE,
        v_pol_loaded                      VARCHAR2 DEFAULT 'N',
        v_ipu_status               IN     VARCHAR2 DEFAULT NULL)
    IS
        v_cvt_install_type          gin_subclass_cover_types.sclcovt_install_type%TYPE;
        v_cvt_max_installs          gin_subclass_cover_types.sclcovt_max_installs%TYPE;
        v_cvt_pymt_install_pcts     gin_subclass_cover_types.sclcovt_pymt_install_pcts%TYPE;
        v_cvt_install_periods       gin_subclass_cover_types.sclcovt_install_periods%TYPE;
        v_install_pct               NUMBER;
        v_pymnt_tot_instlmt         NUMBER;
        v_suspend_days              NUMBER;
        v_install_days              NUMBER;
        v_max_installs              NUMBER;
        v_months_added              NUMBER;
        v_day                       NUMBER;
        v_month                     NUMBER;
        v_year                      NUMBER;
        v_mnth                      NUMBER;
        v_add_days                  NUMBER;
        v_reinsdayspremsubs_param   NUMBER;
    --v_pol_install_wet DATE;
    BEGIN
        --raise_error ('Error getting cover type details..');
        BEGIN
            SELECT sclcovt_install_type,
                   sclcovt_max_installs,
                   sclcovt_pymt_install_pcts,
                   sclcovt_install_periods
              INTO v_cvt_install_type,
                   v_cvt_max_installs,
                   v_cvt_pymt_install_pcts,
                   v_cvt_install_periods
              FROM gin_subclass_cover_types
             WHERE     sclcovt_covt_code = v_covt_code
                   AND sclcovt_scl_code = v_scl_code;
        EXCEPTION
            WHEN OTHERS
            THEN
                raise_error ('Error getting cover type details..');
        END;

        BEGIN
            v_reinsdayspremsubs_param :=
                gin_parameters_pkg.get_param_varchar (
                    'REINS_DAYS_PREM_SUBS%');
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                v_reinsdayspremsubs_param := 100;
            WHEN OTHERS
            THEN
                raise_when_others (
                    'Error fetching REINS_DAYS_PREM_SUBS parameter...');
        END;

        IF    NVL (v_cvt_install_type, 'NONE') NOT IN ('PYMT', 'CVRP')
           OR NVL (v_pol_tot_instlmt, 0) <= 1
        THEN
            v_wef_date := v_wef_date;
            v_wet_date := v_wet_date;
            v_pol_install_wet := v_wet_date;

            IF     v_susp_reinstate = 'Y'
               AND v_susp_reinst_type IN ('SUBS', 'DAYS')
            THEN
                IF NVL (v_reinsdayspremsubs_param, 100) != 100
                THEN
                    v_suspend_days :=
                        ROUND (
                              (v_susp_wet - v_susp_wef)
                            * v_reinsdayspremsubs_param
                            / 100);
                    v_install_days :=
                        LEAST (v_wet_date, v_susp_wet) - v_susp_wef;
                    v_wef_date := v_susp_wet;
                    v_wet_date := v_wet_date + NVL (v_suspend_days, 0);
                    v_new_pol_wet :=
                        NVL (v_wet_date,
                             v_pol_cover_to + NVL (v_install_days, 0));
                ELSE
                    v_suspend_days := v_susp_wet - v_susp_wef;
                    v_install_days :=
                        LEAST (v_wet_date, v_susp_wet) - v_susp_wef;
                    v_wef_date := v_susp_wet;
                    v_wet_date :=
                          GREATEST (v_susp_wet, v_wet_date)
                        + NVL (v_install_days, 0);
                    v_new_pol_wet := v_pol_cover_to + NVL (v_install_days, 0);
                END IF;
            END IF;
        ELSE
            IF     NVL (v_cvt_install_type, 'NONE') = 'PYMT'
               AND NVL (v_pol_tot_instlmt, 0) > 1
            THEN
                v_risk_pymt_install_pcts :=
                    NVL (v_risk_pymt_install_pcts, v_cvt_pymt_install_pcts);
                v_install_pct :=
                    get_instalment_pct (1,
                                        v_risk_pymt_install_pcts,
                                        v_pymnt_tot_instlmt);

                IF NVL (v_pymnt_tot_instlmt, 0) != NVL (v_pol_tot_instlmt, 0)
                THEN
                    raise_error (
                           'Specified installments '
                        || NVL (v_pol_tot_instlmt, 0)
                        || ' do not tally with the payments percentages given '
                        || v_risk_pymt_install_pcts);
                END IF;
            END IF;

            IF NVL (v_pol_tot_instlmt, 0) > NVL (v_cvt_max_installs, 12)
            THEN
                raise_error (
                       'Installments specified greater than allowed at cover types '
                    || NVL (v_cvt_max_installs, 12));
            ELSE
                IF NVL (v_cvt_install_periods, 'M') = 'A'
                THEN
                    raise_error (
                        'Annual cannot be extended beyond policy period..');
                ELSIF NVL (v_cvt_install_periods, 'M') = 'S'
                THEN
                    v_max_installs := 2;
                    v_months_added := 6;
                ELSIF NVL (v_cvt_install_periods, 'M') = 'Q'
                THEN
                    v_max_installs := 4;
                    v_months_added := 3;
                ELSE
                    v_max_installs := 12;
                    v_months_added := 1;
                END IF;

                IF v_increment = 'N'
                THEN
                    v_install_period := v_install_period;
                    v_wef_date := v_wef_date;
                ELSIF v_increment = 'Y'
                THEN
                    IF NVL (v_susp_reinstate, 'N') = 'Y'
                    THEN
                        raise_error (
                            'Risk has been suspended. Reinstate before Extending..');
                    END IF;

                    v_install_period := NVL (v_install_period, 1) + 1;

                    --22-FEB-13<=>21-MAR-13<=>4
                    -- RAISE_ERROR(v_wef_date||'<=>'||v_wet_date||'<=>'||v_install_period||'<=>'||v_increment_by);
                    IF NVL (v_increment_by, 1) = 0
                    THEN
                        v_wef_date := v_wef_date;
                    ELSIF NVL (v_increment_by, 1) = 1
                    THEN
                        v_wef_date := GREATEST ((v_wet_date + 1), v_wef_date);
                    ELSE
                        /*FOR y IN 1..v_increment_by LOOP
                            v_wef_date := ADD_MONTHS(v_wef_date,v_months_added);
                        END LOOP;*/
                        v_day := TO_NUMBER (TO_CHAR (v_wef_date, 'DD'));
                        v_month := TO_NUMBER (TO_CHAR (v_wef_date, 'MM'));
                        v_year := TO_NUMBER (TO_CHAR (v_wef_date, 'YYYY'));

                        FOR y IN 1 .. v_increment_by
                        LOOP
                            v_month := v_month + 1;

                            IF v_month > 12
                            THEN
                                v_month := v_month - 12;
                                v_year := v_year + 1;
                            END IF;
                        END LOOP;

                        IF v_month IN (2)
                        THEN
                            IF MOD (v_year, 4) = 0 AND v_day > 29
                            THEN
                                v_day := 29;
                            ELSE
                                v_day := 28;
                            END IF;
                        ELSIF     v_month IN (4,
                                              6,
                                              9,
                                              11)
                              AND v_day > 30
                        THEN
                            v_day := 30;
                        END IF;

                        v_wef_date :=
                            TO_DATE (
                                   TO_CHAR (v_day, '00')
                                || '/'
                                || TO_CHAR (v_month, '00')
                                || '/'
                                || TO_CHAR (v_year),
                                'DD/MM/YYYY');
                    END IF;

                    v_pol_install_wet :=
                        LEAST ((ADD_MONTHS (v_wef_date, 1) - 1),
                               v_pol_cover_to);
                --                END IF;
                ELSE
                    raise_error ('Action type not specified..');
                END IF;

                IF v_install_period <
                   LEAST (v_pol_tot_instlmt, v_max_installs)
                THEN
                    v_day := TO_NUMBER (TO_CHAR (v_wef_date, 'DD'));
                    v_month := TO_NUMBER (TO_CHAR (v_wef_date, 'MM'));
                    v_year := TO_NUMBER (TO_CHAR (v_wef_date, 'YYYY'));

                    FOR i IN v_month .. (v_month + v_months_added) - 1
                    LOOP
                        IF i > 12
                        THEN
                            v_mnth := i - 12;
                        ELSE
                            v_mnth := i;
                        END IF;

                        IF v_mnth = 2
                        THEN
                            IF MOD (v_year, 4) = 0
                            THEN
                                --v_add_days := NVL(v_add_days,0) + 29;
                                v_add_days := NVL (v_add_days, 0) + 28;
                            ELSE
                                --v_add_days := NVL(v_add_days,0) + 28;
                                v_add_days := NVL (v_add_days, 0) + 27;
                            END IF;
                        ELSIF v_mnth IN (4,
                                         6,
                                         9,
                                         11)
                        THEN
                            --v_add_days := NVL(v_add_days,0) + 30;
                            v_add_days := NVL (v_add_days, 0) + 29;
                        ELSE
                            --v_add_days := NVL(v_add_days,0) + 31;
                            v_add_days := NVL (v_add_days, 0) + 30;
                        --RAISE_ERROR(v_mnth||'='||v_year||'='||v_add_days||'='||v_months_added||'='||v_wef_date||'='||v_wet_date||'='||v_susp_reinst_type);
                        END IF;

                        DBMS_OUTPUT.put_line (
                            i || '=' || v_add_days || '=' || v_month);
                    END LOOP;

                    --RAISE_ERROR('v_ipu_status'||v_ipu_status||'v_susp_reinst_type='||v_susp_reinst_type||'='||v_wef_date||'='||v_wet_date||'='||v_day);
                    IF NVL (v_susp_reinst_type, 'XXX') != 'DAYS'
                    THEN
                        IF NVL (v_ipu_status, 'XXX') != 'SB'
                        THEN
                            IF v_day = 1
                            THEN
                                v_wet_date := LAST_DAY (v_wef_date);
                            ELSIF TO_NUMBER (TO_CHAR (v_wet_date, 'DD')) =
                                  TO_NUMBER (TO_CHAR (v_wef_date, 'DD')) - 1
                            THEN
                                IF v_mnth IN (1)
                                THEN
                                    IF MOD (v_year, 4) = 2
                                    THEN          --masinde intro if statement
                                        IF TO_NUMBER (
                                               TO_CHAR (v_wef_date, 'DD')) =
                                           29
                                        THEN
                                            v_wet_date :=
                                                ADD_MONTHS (
                                                    TO_DATE (v_wef_date),
                                                    1);
                                        ELSE
                                            v_wet_date :=
                                                ADD_MONTHS (
                                                    TO_DATE (v_wef_date),
                                                    1);
                                        ---1;
                                        --raise_Error('v_mnth1='||v_mnth||v_wef_date||'='||v_wet_date);
                                        END IF;
                                    ELSE
                                        v_wet_date :=
                                            ADD_MONTHS (TO_DATE (v_wef_date),
                                                        1);
                                    END IF;
                                --v_wet_date := ADD_MONTHS (TO_DATE (v_wef_date), 1);
                                ELSE
                                    v_wet_date := v_wef_date + v_add_days;
                                END IF;
                            --raise_Error('v_mnth='||v_mnth||v_wef_date||'='||v_wet_date);
                            ELSIF TO_NUMBER (
                                      TO_CHAR (LAST_DAY (v_wef_date), 'DD')) =
                                  30
                            THEN
                                -- RAISE_ERROR(v_wef_date||'='||v_wet_date||' '||v_mnth||' 2 '||v_add_days);
                                v_wet_date := v_wef_date + v_add_days;
                            ELSE
                                IF MOD (v_year, 4) = 0
                                THEN
                                    IF v_mnth IN (1) AND v_day > 29
                                    THEN
                                        v_wet_date :=
                                            ADD_MONTHS (TO_DATE (v_wef_date),
                                                        1);
                                    ELSE
                                        v_wet_date := v_wef_date + v_add_days;
                                    --ADD_MONTHS(v_wef_date,1)-1;
                                    END IF;
                                ELSE
                                    IF v_mnth IN (1) AND v_day > 28
                                    THEN
                                        v_wet_date :=
                                            ADD_MONTHS (TO_DATE (v_wef_date),
                                                        1);
                                    ELSE
                                        v_wet_date := v_wef_date + v_add_days;
                                    --ADD_MONTHS(v_wef_date,1)-1;
                                    END IF;
                                END IF;
                            END IF;
                        ELSE
                            --RAISE_ERROR(v_wef_date||'='||v_wet_date);
                            v_wef_date := v_wef_date;
                            v_wet_date := v_wet_date;
                        END IF;
                    ELSE
                        v_wef_date := v_wef_date;
                        v_wet_date := v_wet_date;
                    END IF;

                    IF NVL (v_pol_loaded, 'N') = 'Y'
                    THEN
                        v_pol_install_wet := v_wet_date;
                    ELSIF v_pol_install_wet IS NULL
                    THEN
                        v_pol_install_wet :=
                            LEAST (
                                (  ADD_MONTHS (
                                       v_pol_cover_from,
                                       v_months_added * v_install_period)
                                 - 1),
                                v_pol_cover_to);
                    END IF;
                ELSIF v_install_period =
                      LEAST (v_pol_tot_instlmt, v_max_installs)
                THEN
                    v_wet_date := v_pol_cover_to;
                    v_pol_install_wet := v_pol_cover_to;
                ELSIF     NVL (v_install_period, 0) >
                          LEAST (v_pol_tot_instlmt, v_max_installs)
                      AND NVL (v_pol_loaded, 'N') != 'Y'
                THEN
                    --   RAISE_ERROR(v_install_period||'='||v_pol_tot_instlmt||'='||v_max_installs);
                    raise_error (
                           'Installment periods cannot be greater than '
                        || LEAST (v_pol_tot_instlmt, v_max_installs)
                        || ' policy specified installments');
                END IF;

                --   RAISE_ERROR(v_susp_reinstate||'='||v_Susp_reinst_type||'='||v_wef_date||'='||v_wet_date||'='||v_susp_wef||'='||v_susp_wet||'='||v_pol_cover_from||'='||v_pol_cover_to||'='||v_pol_install_wet);
                IF     NVL (v_susp_reinstate, 'N') = 'Y'
                   AND NVL (v_susp_reinst_type, 'PREM') = 'DAYS'
                THEN
                    v_suspend_days := v_susp_wet - v_susp_wef;
                    v_install_days :=
                        LEAST (v_wet_date, v_susp_wet) - v_susp_wef;
                    v_wef_date := v_susp_wet;  --LEAST(v_wet_date,v_susp_wet);
                    v_wet_date :=
                          GREATEST (v_susp_wet, v_wet_date)
                        + NVL (v_install_days, 0);
                    v_new_pol_wet := v_pol_cover_to + NVL (v_install_days, 0);
                    v_pol_install_wet :=
                        v_pol_install_wet + NVL (v_install_days, 0);
                --  RAISE_ERROR(v_suspend_days||'='||v_install_days||'='||v_wet_date||'='||v_wef_date||'='||v_susp_wef||'='||v_pol_cover_to||'='||v_new_pol_wet);
                ELSIF     NVL (v_susp_reinstate, 'N') = 'Y'
                      AND NVL (v_susp_reinst_type, 'PREM') = 'SUBS'
                THEN
                    v_suspend_days := v_susp_wet - v_susp_wef;
                    v_install_days :=
                        LEAST (v_wet_date, v_susp_wet) - v_susp_wef;
                    v_pol_install_wet :=
                        v_pol_install_wet + NVL (v_install_days, 0);
                    v_wef_date := v_wef_date;
                    v_wet_date := v_susp_wef;
                    v_new_pol_wet := v_pol_cover_to + NVL (v_install_days, 0);
                --  RAISE_ERROR('SDYS='||v_suspend_days||'IDYS='||v_install_days||'WET='||v_wet_date||'WEF='||v_wef_date||'SWEF='||v_susp_wef||'PTO='||v_pol_cover_to||'NPWET='||v_new_pol_wet||'PIWT='||v_pol_install_wet);
                ELSIF     NVL (v_susp_reinstate, 'N') = 'Y'
                      AND NVL (v_susp_reinst_type, 'PREM') = 'PREM'
                THEN
                    v_wef_date := v_wef_date;
                    v_wet_date := v_wet_date;
                ELSE
                    --RAISE_ERROR(v_wef_date||'='||v_wet_date||'='||v_pol_install_wet);
                    IF NVL (v_pol_loaded, 'N') = 'Y'
                    THEN
                        v_wet_date :=
                            LEAST (v_wet_date,
                                   NVL (v_pol_install_wet, v_wet_date));
                    ELSE
                        v_wet_date := v_wet_date;
                    END IF;
                --  v_wet_date := LEAST(v_wet_date,NVL(v_pol_install_wet,v_wet_date));
                END IF;
            --RAISE_ERROR(v_wef_date||'='||v_wet_date||'='||v_pol_install_wet||'='||v_pol_cover_from||'='||v_months_added||'='||v_install_period||'='||v_pol_cover_to);
            END IF;                                                         --
        END IF;

        -- RAISE_ERROR(v_install_period||'='||v_wet_date||'='||v_months_added||' = '||v_increment||' ='||v_pol_cover_to);
        --RAISE_ERROR(v_wef_date||'='||v_wet_date||'='||v_pol_install_wet||'='||v_pol_cover_from||'='||v_months_added||'='||v_install_period||'='||v_pol_cover_to);
        v_cover_days := TO_NUMBER (v_wet_date - v_wef_date);

        --RAISE_ERROR(v_wef_date||'='||v_wet_date||'='||v_cover_days||'='||v_pro_expiry_period);
        IF NVL (v_pro_expiry_period, 'Y') = 'Y'
        THEN
            v_cover_days := v_cover_days + 1;
        END IF;
    --     RAISE_ERROR('v_new_pol_wet= '||v_new_pol_wet);
    END;