PROCEDURE gin_tmplt_schedules (v_web_ipu_code   IN NUMBER,
                                   v_pro_code       IN NUMBER,
                                   v_new_ipu_code   IN NUMBER,
                                   v_property_id    IN VARCHAR2,
                                   v_risk_value     IN NUMBER,
                                   v_cover_type     IN VARCHAR2)
    IS
        v_cnt   NUMBER (4);

        CURSOR sched_cur IS
              SELECT clp_unwr_scr_code,
                     screen_name,
                     INITCAP (scl_sht_desc)     scl_sht_desc
                FROM gin_product_sub_classes, gin_screens, gin_sub_classes
               WHERE     clp_unwr_scr_code = screen_code
                     AND clp_scl_code = scl_code
                     AND clp_pro_code = v_pro_code
                     AND screen_name IS NOT NULL
            GROUP BY clp_unwr_scr_code, screen_name, scl_sht_desc;

        CURSOR rsks_cur IS
            SELECT mps_reg_no,
                   mps_make,
                   mps_cubic_capacity,
                   mps_yr_manft,
                   mps_carry_capacity,
                   mps_value,
                   mps_body_type,
                   mps_cover_type,
                   mps_covt_code,
                   mps_itemno,
                   mps_chasis_no,
                   mps_engine_no,
                   mps_color,
                   mps_logbook,
                   mps_acc_limit,
                   mps_itmno_code,
                   mps_waiver_1st_amt,
                   mps_car_hire
              FROM gin_web_motor_sch
             WHERE mps_ipu_code = v_web_ipu_code;
    BEGIN
        FOR rsks_cur_rec IN rsks_cur
        LOOP
            FOR sched_cur_rec IN sched_cur
            LOOP
                IF sched_cur_rec.screen_name = 'UMOTORP'
                THEN
                    BEGIN
                        SELECT COUNT (1)
                          INTO v_cnt
                          FROM gin_motor_private_sch
                         WHERE mps_ipu_code = TO_NUMBER (v_new_ipu_code);

                        raise_error ('SCHEDULE COUNT ' || v_cnt);
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            raise_error (
                                'Error securing whether Motor schedule exists..1');
                    END;

                    IF v_cnt != 0
                    THEN
                        UPDATE gin_motor_private_sch
                           SET mps_value = v_risk_value,
                               mps_body_type = rsks_cur_rec.mps_body_type,
                               mps_cover_type = v_cover_type
                         WHERE mps_ipu_code = v_new_ipu_code;
                    ELSE
                        BEGIN
                            INSERT INTO gin_motor_private_sch (
                                            mps_ipu_code,
                                            mps_reg_no,
                                            mps_make,
                                            mps_cubic_capacity,
                                            mps_yr_manft,
                                            mps_value,
                                            mps_body_type,
                                            mps_cover_type,
                                            mps_itemno)
                                     VALUES (
                                                v_new_ipu_code,
                                                v_property_id,
                                                rsks_cur_rec.mps_make,
                                                TO_NUMBER (
                                                    rsks_cur_rec.mps_cubic_capacity),
                                                TO_NUMBER (
                                                    rsks_cur_rec.mps_yr_manft),
                                                v_risk_value,
                                                rsks_cur_rec.mps_body_type,
                                                rsks_cur_rec.mps_cover_type,
                                                1);
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                raise_error (
                                       'Unable to populate vehicle details..1'
                                    || v_property_id);
                        END;
                    END IF;
                ELSIF sched_cur_rec.screen_name = 'UMOTCYC'
                THEN
                    BEGIN
                        SELECT COUNT (1)
                          INTO v_cnt
                          FROM gin_motor_cycle_sch
                         WHERE mcs_ipu_code = v_new_ipu_code;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            raise_error (
                                'Error securing whether Motor schedule exists..2');
                    END;

                    IF v_cnt != 0
                    THEN
                        UPDATE gin_motor_cycle_sch
                           SET mcs_value = v_risk_value,
                               mcs_body_type = rsks_cur_rec.mps_body_type,
                               mcs_covt_sht_desc =
                                   rsks_cur_rec.mps_cover_type,
                               mcs_covt_code = rsks_cur_rec.mps_covt_code
                         WHERE mcs_ipu_code = v_new_ipu_code;
                    ELSE
                        BEGIN
                            INSERT INTO gin_motor_cycle_sch (
                                            mcs_body_type,
                                            mcs_ipu_code,
                                            mcs_reg_no,
                                            mcs_make,
                                            mcs_cubic_capacity,
                                            mcs_yr_manft,
                                            mcs_value,
                                            mcs_covt_code,
                                            mcs_covt_sht_desc,
                                            mcs_itemno)
                                     VALUES (
                                                rsks_cur_rec.mps_body_type,
                                                v_new_ipu_code,
                                                v_property_id,
                                                rsks_cur_rec.mps_make,
                                                TO_NUMBER (
                                                    rsks_cur_rec.mps_cubic_capacity),
                                                TO_NUMBER (
                                                    rsks_cur_rec.mps_yr_manft),
                                                v_risk_value,
                                                rsks_cur_rec.mps_covt_code,
                                                rsks_cur_rec.mps_cover_type,
                                                1);
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                raise_error (
                                    'Unable to populate vehicle details..2');
                        END;
                    END IF;
                ELSIF sched_cur_rec.screen_name IN ('UMOTCOM', 'UMOTPSV')
                THEN
                    BEGIN
                        SELECT COUNT (1)
                          INTO v_cnt
                          FROM gin_motor_commercial_sch
                         WHERE mcoms_ipu_code = TO_NUMBER (v_new_ipu_code);
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            raise_error (
                                'Error securing whether Motor schedule exists..2');
                    END;

                    IF v_cnt != 0
                    THEN
                        UPDATE gin_motor_commercial_sch
                           SET mcoms_value = v_risk_value,
                               mcoms_body_type = rsks_cur_rec.mps_body_type,
                               mcoms_cover_type = rsks_cur_rec.mps_cover_type
                         WHERE mcoms_ipu_code = v_new_ipu_code;
                    ELSE
                        BEGIN
                            INSERT INTO gin_motor_commercial_sch (
                                            mcoms_ipu_code,
                                            mcoms_reg_no,
                                            mcoms_make,
                                            mcoms_body_type,
                                            mcoms_cubic_capacity,
                                            mcoms_yr_manft,
                                            mcoms_value,
                                            mcoms_cover_type,
                                            mcoms_item_no)
                                     VALUES (
                                                v_new_ipu_code,
                                                v_property_id,
                                                rsks_cur_rec.mps_make,
                                                rsks_cur_rec.mps_body_type,
                                                TO_NUMBER (
                                                    rsks_cur_rec.mps_cubic_capacity),
                                                TO_NUMBER (
                                                    rsks_cur_rec.mps_yr_manft),
                                                v_risk_value,
                                                rsks_cur_rec.mps_cover_type,
                                                1);
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                raise_error (
                                    'Unable to populate vehicle details..3');
                        END;
                    END IF;
                END IF;
            END LOOP;
        END LOOP;
    END;