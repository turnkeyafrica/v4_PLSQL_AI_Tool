PROCEDURE pop_policy_perils (v_batch_no    IN NUMBER,
                                 v_pro_code    IN NUMBER,
                                 v_bind_code   IN NUMBER)
    IS
        v_bind_type   VARCHAR2 (1);
    BEGIN
        IF v_bind_code IS NULL
        THEN
            v_bind_type := 'M';
        ELSE
            BEGIN
                SELECT bind_type
                  INTO v_bind_type
                  FROM gin_binders
                 WHERE bind_code = v_bind_code;
            EXCEPTION
                WHEN OTHERS
                THEN
                    raise_error ('Error getting the binder type...');
            END;