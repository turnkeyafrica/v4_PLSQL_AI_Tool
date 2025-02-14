FUNCTION check_unique_riskid_format (v_rskid          IN VARCHAR2,
                                         v_rskid_format   IN VARCHAR2)
        RETURN BOOLEAN
    IS
        -- rskid VARCHAR2(15):= 'KAC 789';
        val         VARCHAR2 (4000);
        -- v_format VARCHAR2(200):='[K&& ###&][&& ### &&][&& ####]';
        --v_rskid_format VARCHAR2(200):='[K&& ###&][&& ### &&][&& ####]';
        vchr        VARCHAR2 (15);
        vchr2       VARCHAR2 (15);
        fmt         VARCHAR2 (5);
        v_lenght    NUMBER;
        v_start     NUMBER;
        x           NUMBER;
        v_conform   BOOLEAN;

        TYPE v_fmts_tab IS TABLE OF VARCHAR2 (25)
            INDEX BY BINARY_INTEGER;

        v_fmts      v_fmts_tab;
    BEGIN
        -- RAISE_ERROR('v_rskid_format'||v_rskid_format);
        FOR i IN 1 .. LENGTH (v_rskid_format)
        LOOP
            vchr := SUBSTR (v_rskid_format, i, 1);
            v_lenght := NVL (v_lenght, 0) + 1;

            IF vchr = '['
            THEN
                v_start := i + 1;
                v_lenght := 0;
            ELSIF vchr = ']'
            THEN
                x := NVL (x, 0) + 1;
                vchr2 := SUBSTR (v_rskid_format, v_start, v_lenght - 1);

                FOR i IN 1 .. LENGTH (vchr2)
                LOOP
                    fmt := SUBSTR (vchr2, i, 1);

                    IF NOT (   (fmt IN ('#', '&', ' '))
                            OR (ASCII (fmt) BETWEEN 65 AND 90)
                            OR (ASCII (fmt) BETWEEN 48 AND 57))
                    THEN
                        DBMS_OUTPUT.put_line (fmt);
                        DBMS_OUTPUT.put_line (ASCII (fmt));
                        raise_error (
                               'Format '
                            || v_rskid_format
                            || ' not defined correctly.');
                    END IF;
                END LOOP;

                v_fmts (x) := vchr2;
            END IF;
        END LOOP;

        v_conform := FALSE;

        FOR i IN 1 .. v_fmts.COUNT
        LOOP
            IF     LENGTH (v_fmts (i)) > 0
               AND LENGTH (v_rskid) = LENGTH (v_fmts (i))
            THEN
                v_conform := TRUE;

                FOR y IN 1 .. LENGTH (v_rskid)
                LOOP
                    val := ASCII (SUBSTR (v_rskid, y, 1));
                    fmt := SUBSTR (v_fmts (i), y, 1);

                    IF    (fmt = '&' AND val NOT BETWEEN 65 AND 90)
                       OR (fmt = '#' AND val NOT BETWEEN 48 AND 57)
                       OR (fmt = '/' AND val NOT BETWEEN 48 AND 57)
                    THEN
                        v_conform := FALSE;
                    ELSIF     (   (ASCII (fmt) BETWEEN 65 AND 90)
                               OR (ASCII (fmt) BETWEEN 48 AND 57))
                          AND ASCII (fmt) != val
                    THEN
                        v_conform := FALSE;
                    END IF;
                END LOOP;
            END IF;

            EXIT WHEN v_conform;
        END LOOP;

        IF NOT v_conform
        THEN
            RETURN v_conform;
        --raise_error (   v_rskid
        --            || ' Does not conform to ANY Formats provided '
        --          || v_rskid_format
        --        );
        END IF;

        RETURN v_conform;
    END;