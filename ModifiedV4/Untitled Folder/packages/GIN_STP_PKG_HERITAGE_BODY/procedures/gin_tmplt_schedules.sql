PROCEDURE gin_tmplt_schedules (
      v_web_ipu_code   IN   NUMBER,
      v_pro_code       IN   NUMBER,
      v_new_ipu_code   IN   NUMBER,
      v_property_id    IN   VARCHAR2,
      v_risk_value     IN   NUMBER,
      v_cover_type     IN   VARCHAR2
   )
   IS
      v_cnt   NUMBER (4);

      CURSOR sched_cur
      IS
         SELECT   clp_unwr_scr_code, screen_name,
                  INITCAP (scl_sht_desc) scl_sht_desc
             FROM gin_product_sub_classes, gin_screens, gin_sub_classes
            WHERE clp_unwr_scr_code = screen_code
              AND clp_scl_code = scl_code
              AND clp_pro_code = v_pro_code
              AND screen_name IS NOT NULL
         GROUP BY clp_unwr_scr_code, screen_name, scl_sht_desc;

      CURSOR rsks_cur
      IS
         SELECT mps_reg_no, mps_make, mps_cubic_capacity, mps_yr_manft,
                mps_carry_capacity, mps_value, mps_body_type, mps_cover_type,
                mps_covt_code, mps_itemno, mps_chasis_no, mps_engine_no,
                mps_color, mps_logbook, mps_acc_limit, mps_itmno_code,
                mps_waiver_1st_amt, mps_car_hire
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
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     raise_error
                           ('Error securing whether Motor schedule exists..1');
               END;