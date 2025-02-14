```sql
PROCEDURE get_policy_no (
    v_prod_code       IN       NUMBER,
    v_prod_sht_desc   IN       VARCHAR2,
    v_brn_code        IN       NUMBER,
    v_brn_sht_desc    IN       VARCHAR2,
    v_pol_binder      IN       VARCHAR2,
    v_pol_type        IN       VARCHAR2,
    v_policy_no       IN OUT   VARCHAR2,
    v_endos_no        IN OUT   VARCHAR2,
    v_batch_no        IN OUT   NUMBER
)
IS
    v_serial       VARCHAR2 (10);
    v_pol_prefix   VARCHAR2 (15);
BEGIN
    DBMS_OUTPUT.put_line ('GPOL' || 1);

    IF v_policy_no IS NULL
    THEN
        BEGIN
            SELECT pro_policy_prefix
              INTO v_pol_prefix
              FROM gin_products
             WHERE pro_code = v_prod_code;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               raise_error (   'The product '
                            || v_prod_sht_desc
                            || ' is not defined in the setup');
            WHEN OTHERS
            THEN
               raise_error (  'Unable to retrieve the policy prefix for the product '
                            || v_prod_sht_desc);
        END;

        IF v_pol_prefix IS NULL
        THEN
            raise_error (   'The policy prefix for the product '
                         || v_prod_sht_desc
                         || ' is not defined in the setup');
        END IF;

        BEGIN
            get_policy_seq (
                v_pol_prefix,
                v_brn_code,
                TO_NUMBER (TO_CHAR (TRUNC (SYSDATE), 'RRRR')),
                2,
                v_serial);
        EXCEPTION
            WHEN OTHERS
            THEN
               raise_error ('Unable to retrieve the policy number sequence');
        END;

        IF v_pol_binder = 'N'
        THEN
            IF v_pol_type = 'N'
            THEN
                v_policy_no :=
                       v_brn_sht_desc
                    || 'P'
                    || TO_CHAR (TRUNC (SYSDATE), 'YY')
                    || v_pol_prefix
                    || LPAD (v_serial, 6 - LENGTH (v_pol_prefix), 0);
            ELSE
                v_policy_no :=
                       v_brn_sht_desc
                    || 'P'
                    || TO_CHAR (TRUNC (SYSDATE), 'YY')
                    || 'R'
                    || v_pol_prefix
                    || LPAD (v_serial, 6 - LENGTH (v_pol_prefix), 0);
            END IF;
        ELSE
            v_policy_no :=
                   v_brn_sht_desc
                || 'P'
                || 'B'
                || TO_CHAR (TRUNC (SYSDATE), 'YY')
                || v_pol_prefix
                || LPAD (v_serial, 6 - LENGTH (v_pol_prefix), 0);
        END IF;
    END IF;

    DBMS_OUTPUT.put_line ('GPOL' || 2);

    IF v_endos_no IS NULL
    THEN
        IF v_pol_type = 'N'
        THEN
            v_endos_no :=
                  'E'
               || TO_CHAR (TRUNC (SYSDATE), 'YY')
               || v_pol_prefix
               || LPAD (v_serial, 6 - LENGTH (v_pol_prefix), '0')
               || v_brn_sht_desc;
        ELSE
            v_endos_no :=
                  'E'
               || TO_CHAR (TRUNC (SYSDATE), 'YY')
               || 'R'
               || v_pol_prefix
               || LPAD (v_serial, 6 - LENGTH (v_pol_prefix), '0')
               || v_brn_sht_desc;
        END IF;
    END IF;

    IF v_batch_no IS NULL
    THEN
        SELECT    TO_NUMBER (TO_CHAR (SYSDATE, 'YY'))
               || gin_pol_batch_no_seq.NEXTVAL
          INTO v_batch_no
          FROM DUAL;
    END IF;

    DBMS_OUTPUT.put_line ('GPOL' || 3);

    BEGIN
        check_policy_unique (v_policy_no);
    EXCEPTION
        WHEN OTHERS
        THEN
            raise_error ('Error generating Policy number ' || v_policy_no);
    END;

    DBMS_OUTPUT.put_line ('GPOL' || 4);
--v_policy_no := v_pol_policy_no;
--v_endos_no  := v_pol_endos_no;
--v_batch_no  := v_pol_batch_no;
END;

```