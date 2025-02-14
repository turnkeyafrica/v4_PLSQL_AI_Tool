PROCEDURE update_risk_remarks (v_polrs_code     IN     NUMBER,
                                   v_action         IN     VARCHAR2,
                                   v_pol_batch_no   IN     NUMBER,
                                   v_ipu_code       IN     NUMBER,
                                   v_polrs_sch      IN     LONG,
                                   v_err               OUT VARCHAR2)
    IS
        v_new_polrs_code   NUMBER;
    BEGIN
        IF v_action = 'A'
        THEN
            BEGIN
                SELECT gin_polrs_code_seq.NEXTVAL
                  INTO v_new_polrs_code
                  FROM DUAL;

                INSERT INTO gin_policy_risk_schedules (polrs_code,
                                                       polrs_ipu_code,
                                                       polrs_pol_batch_no,
                                                       polrs_schedule)
                     VALUES (v_new_polrs_code,
                             v_ipu_code,
                             v_pol_batch_no,
                             v_polrs_sch);
            EXCEPTION
                WHEN OTHERS
                THEN
                    v_err := 'error inserting risk remark....';
                    RETURN;
            END;
        ELSIF v_action = 'E'
        THEN
            BEGIN
                UPDATE gin_policy_risk_schedules
                   SET polrs_schedule = v_polrs_sch
                 WHERE polrs_code = v_polrs_code;
            EXCEPTION
                WHEN OTHERS
                THEN
                    v_err := 'error updating risk remark....';
                    RETURN;
            END;
        ELSIF v_action = 'D'
        THEN
            BEGIN
                DELETE FROM gin_policy_risk_schedules
                      WHERE polrs_code = v_polrs_code;
            EXCEPTION
                WHEN OTHERS
                THEN
                    v_err := 'error updating risk remark....';
                    RETURN;
            END;
        ELSE
            BEGIN
                v_err := 'error determing action....';
                RETURN;
            END;
        END IF;
    END;