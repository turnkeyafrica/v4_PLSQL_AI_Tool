```sql
PROCEDURE pop_sbu_dtls (
    v_pol_batch_no    IN   NUMBER,
    v_pol_unit_code        IN   VARCHAR2,
    v_pol_location_code      IN   VARCHAR2,
    v_pol_add_edit  IN   VARCHAR2
)
IS
    v_pdl_code   NUMBER;
    v_cnt        NUMBER;
BEGIN
    SELECT  TO_NUMBER (TO_CHAR (SYSDATE, 'YYYY')) || gin_pdl_code_seq.NEXTVAL
    INTO    v_pdl_code
    FROM    DUAL;

    IF NVL(v_pol_add_edit, 'E') = 'A' THEN
        BEGIN
            INSERT INTO gin_policy_sbu_dtls (
                pdl_code,
                pdl_pol_batch_no,
                pdl_unit_code,
                pdl_location_code,
                pdl_prepared_date
            ) VALUES (
                v_pdl_code,
                v_pol_batch_no,
                v_pol_unit_code,
                v_pol_location_code,
                TRUNC(SYSDATE)
            );
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
            WHEN OTHERS THEN
                raise_error('Error Creating Policy Other Details Record..');
        END;
    ELSE
        BEGIN
            SELECT COUNT(pdl_code)
            INTO   v_cnt
            FROM   gin_policy_sbu_dtls
            WHERE  pdl_pol_batch_no = v_pol_batch_no;
        EXCEPTION
            WHEN OTHERS THEN
                raise_error('Error checking if policy exists..');
        END;

        IF NVL(v_cnt, 0) = 0 THEN
            INSERT INTO gin_policy_sbu_dtls (
                pdl_code,
                pdl_pol_batch_no,
                pdl_unit_code,
                pdl_location_code,
                pdl_prepared_date
            ) VALUES (
                v_pdl_code,
                v_pol_batch_no,
                v_pol_unit_code,
                v_pol_location_code,
                TRUNC(SYSDATE)
            );
        ELSE
            UPDATE gin_policy_sbu_dtls
            SET    pdl_unit_code = NVL(v_pol_unit_code, pdl_unit_code),
                   pdl_location_code = NVL(v_pol_location_code, pdl_unit_code)
            WHERE  pdl_pol_batch_no = v_pol_batch_no;
        END IF;
    END IF;
END;

```