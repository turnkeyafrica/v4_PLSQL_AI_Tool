```sql
PROCEDURE saveserviceproviderdetails (
    v_action                VARCHAR2,
    v_gsp_code              NUMBER,
    v_gsp_spr_code          NUMBER,
    v_gsp_spt_code       IN NUMBER,
    v_gsp_pol_batch_no   IN NUMBER
)
IS
BEGIN
    IF v_action = 'A' THEN
        BEGIN
            INSERT INTO gin_service_providers (
                gsp_code,
                gsp_spr_code,
                gsp_spt_code,
                gsp_pol_batch_no
            ) VALUES (
                gin_gsp_code_seq.NEXTVAL,
                v_gsp_spr_code,
                v_gsp_spt_code,
                v_gsp_pol_batch_no
            );
        EXCEPTION
            WHEN OTHERS THEN
                raise_error('Error inserting Service Provider Details...');
        END;
    ELSIF v_action = 'E' THEN
        BEGIN
            UPDATE gin_service_providers
            SET
                gsp_spr_code = v_gsp_spr_code,
                gsp_spt_code = v_gsp_spt_code,
                gsp_pol_batch_no = v_gsp_pol_batch_no
            WHERE
                gsp_code = v_gsp_code;
        EXCEPTION
            WHEN OTHERS THEN
                raise_error('Error updating Service Provider Details...');
        END;
    ELSIF v_action = 'D' THEN
        BEGIN
            DELETE FROM gin_service_providers
            WHERE
                gsp_code = v_gsp_code;
        EXCEPTION
            WHEN OTHERS THEN
                raise_error('Error deleting Service Provider Details...');
        END;
    ELSE
        BEGIN
            raise_error('invalid Action...');
        END;
    END IF;
END;
```