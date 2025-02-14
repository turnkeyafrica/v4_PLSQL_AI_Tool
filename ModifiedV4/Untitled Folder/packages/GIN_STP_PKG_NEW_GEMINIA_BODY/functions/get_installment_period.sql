FUNCTION get_installment_period (
        v_installment_def   IN VARCHAR2,
        v_no_of_endos       IN NUMBER,
        v_value_type        IN VARCHAR2 DEFAULT 'C')
        RETURN NUMBER
    IS
        v_installment_perct   NUMBER;
    BEGIN
        ---raise_error('v_installment_def='||v_installment_def||'v_no_of_endos='||v_no_of_endos||'v_installment_perct='||v_installment_perct);
        IF v_value_type = 'C'
        THEN
            SELECT COLUMN_VALUE
              INTO v_installment_perct
              FROM (SELECT ROWNUM COUNT, x.*
                      FROM TABLE (convertstringtoarray (v_installment_def)) x)
                   a
             WHERE a.COUNT = v_no_of_endos;
        ELSIF v_value_type = 'E'
        THEN
            SELECT SUM (COLUMN_VALUE)
              INTO v_installment_perct
              FROM TABLE (convertstringtoarray (v_installment_def))
             WHERE ROWNUM <= v_no_of_endos;
        END IF;

        RETURN v_installment_perct;
    END;