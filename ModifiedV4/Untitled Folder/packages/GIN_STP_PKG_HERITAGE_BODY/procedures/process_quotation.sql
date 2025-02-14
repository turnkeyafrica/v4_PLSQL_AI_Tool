PROCEDURE process_quotation (
         vpol_id      IN       NUMBER,
         v_quo_code   IN OUT   NUMBER,
         v_quo_no     IN OUT   VARCHAR2
      )
      IS
         v_exp_flag         VARCHAR2 (2);
         v_open_cover       VARCHAR2 (2);
         v_user             VARCHAR2 (35)
               := pkg_global_vars.get_pvarchar2 ('PKG_GLOBAL_VARS.PVG_USERNAME');
         v_row              NUMBER        := 0;
         v_wet_date         DATE;
         v_pol_renewal_dt   DATE;
         v_cur_rate         NUMBER;
         v_cur_code         NUMBER;
         v_cur_symbol       VARCHAR2 (15);
         v_pro_sht_desc     VARCHAR2 (25);
         v_pol_uwyr         NUMBER;
         v_qno              NUMBER;
         v_qp_code          NUMBER;
         v_qr_code          NUMBER;
         v_prp_sht_desc     VARCHAR2 (35);
         v_brn_code         NUMBER;
         v_bind_code        NUMBER;
         v_bind_name        VARCHAR2 (35);
         v_rsk_sect_data    rsk_sect_tab;

         CURSOR pol_cur
         IS
            SELECT *
              FROM gin_web_policies, gin_web_risks
             WHERE pol_id = vpol_id AND ipu_pol_id = pol_id;

         CURSOR risk_cur
         IS
            SELECT *
              FROM gin_web_risks
             WHERE ipu_pol_id = vpol_id;

         CURSOR sect_cur (v_ipu_code IN NUMBER)
         IS
            SELECT *
              FROM gin_web_risk_sections
             WHERE pil_ipu_code = v_ipu_code;
      BEGIN
         DBMS_OUTPUT.put_line (5555555);
         DBMS_OUTPUT.put_line (2);

         FOR pol_rec IN pol_cur
         LOOP
            IF pol_rec.ipu_pro_code IS NULL
            THEN
               raise_error ('SELECT THE POLICY PRODUCT ...');
            END IF;

            IF pol_rec.pol_wef_dt IS NULL
            THEN
               raise_error ('PROVIDE THE COVER FROM DATE ...');
            END IF;

            DBMS_OUTPUT.put_line (21);
            v_wet_date := pol_rec.pol_wet_dt;

            IF v_wet_date IS NULL
            THEN
               v_wet_date :=
                         get_wet_date (pol_rec.pol_pro_code, pol_rec.pol_wef_dt);
            END IF;

            DBMS_OUTPUT.put_line (22);

            IF v_wet_date IS NULL
            THEN
               raise_error ('PROVIDE THE COVER TO DATE ...');
            END IF;

            DBMS_OUTPUT.put_line (23);

            IF     NVL (pol_rec.pol_binder_policy, 'N') = 'Y'
               AND pol_rec.pol_bind_code IS NULL
            THEN
               raise_error ('YOU HAVE NOT DEFINED THE BORDEREAUX CODE ..');
            END IF;

            DBMS_OUTPUT.put_line (pol_rec.pol_wef_dt);
            DBMS_OUTPUT.put_line (TO_CHAR (pol_rec.pol_wef_dt));
            DBMS_OUTPUT.put_line (TO_NUMBER (TO_CHAR (pol_rec.pol_wef_dt, 'RRRR'))
                                 );
            v_pol_uwyr := TO_NUMBER (TO_CHAR (pol_rec.pol_wef_dt, 'RRRR'));
   --         IF pol_rec.POL_UW_YEAR IS NULL OR pol_rec.POL_UW_YEAR = 0 THEN
   --             RAISE_ERROR('THE UNDERWRITING YEAR MUST BE A VALID YEAR...');
   --         END IF;
            DBMS_OUTPUT.put_line (25);
            v_pol_renewal_dt :=
                              get_renewal_date (pol_rec.pol_pro_code, v_wet_date);

            IF NVL (pol_rec.pol_add_edit, 'A') = 'A'
            THEN
               BEGIN
                  SELECT TO_NUMBER (   TO_CHAR (SYSDATE, 'RRRR')
                                    || gin_quot_code_seq.NEXTVAL
                                   )
                    INTO v_quo_code
                    FROM DUAL;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     raise_error
                        ('Unable to generate new quotation sequence GIN_QUOT_CODE_SEQ.NEXTVAL, ...'
                        );
               END;