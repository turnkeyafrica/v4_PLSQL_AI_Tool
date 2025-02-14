```sql
PROCEDURE check_dup_certificates (
    v_polc_wef            gin_policy_certs.polc_wef%TYPE,
    v_polc_wet            gin_policy_certs.polc_wet%TYPE,
    v_polc_status         gin_policy_certs.polc_status%TYPE,
    v_polc_ipu_id         NUMBER,
    v_err           OUT   VARCHAR2,
    v_ipu_code            NUMBER DEFAULT NULL
)
IS
    v_dummy    NUMBER := 0;
    v_ipu_id   NUMBER;
BEGIN
    IF v_polc_ipu_id IS NULL AND v_ipu_code IS NOT NULL THEN
        BEGIN
            SELECT IPU_ID
            INTO v_ipu_id
            FROM GIN_INSURED_PROPERTY_UNDS
            WHERE IPU_CODE = v_ipu_code;
        EXCEPTION
            WHEN OTHERS THEN
                v_ipu_id := NULL;
        END;
    END IF;

    BEGIN
        SELECT COUNT (1)
        INTO v_dummy
        FROM gin_policy_certs
        WHERE NVL (polc_status, 'A') != 'C'
        AND TRUNC (polc_wet) >= TRUNC (v_polc_wef)
        AND polc_ipu_id = NVL (v_polc_ipu_id, v_ipu_id);
    EXCEPTION
        WHEN OTHERS THEN
            v_dummy := 0;
    END;

    IF NVL (v_dummy, 0) != 0 THEN
        v_err :=
            '2 You Cannot Define Another Certificate if The Previous One is Not Cancelled...';
        RETURN;
    END IF;

    BEGIN
        SELECT COUNT (1)
        INTO v_dummy
        FROM gin_aki_policy_cert_dtls, gin_insured_property_unds
        WHERE (NVL (apcd_cert_cancelled, 'N') != 'Y')
        AND TRUNC (apcd_wet) >= TRUNC (v_polc_wef)
        AND apcd_ipu_code = ipu_code
        AND ipu_id = NVL (v_polc_ipu_id, v_ipu_id);
    EXCEPTION
        WHEN OTHERS THEN
            v_dummy := 0;
    END;

    IF NVL (v_dummy, 0) != 0 THEN
        v_err :=
            '2 You Cannot Define Another Certificate if The Previous One(Digital) is Not Cancelled/Deleted...';
        RETURN;
    END IF;
END;

```