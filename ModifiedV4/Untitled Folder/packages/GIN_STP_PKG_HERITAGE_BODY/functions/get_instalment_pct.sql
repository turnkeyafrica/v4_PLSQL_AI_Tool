FUNCTION get_instalment_pct (
      v_install_no      IN       NUMBER,
      v_comp_installs   IN       VARCHAR2,
      v_tot_instals     OUT      NUMBER
   )
      RETURN NUMBER
   IS
      v_str       VARCHAR2 (50);
      v_val       NUMBER;
      v_tot_val   NUMBER;
      --v_tot_instals number;
      vchr        VARCHAR2 (2);
      v_ret       NUMBER;
   BEGIN
      IF v_comp_installs IS NULL
      THEN
         raise_error ('Installments percentages not defined..');
      END IF;

      IF NVL (v_install_no, 0) <= 0
      THEN
         raise_error
            ('Installment number not provided to determine payment percentage '
            );
      END IF;

      v_str := v_comp_installs;

      FOR i IN 1 .. LENGTH (v_comp_installs)
      LOOP
         vchr := SUBSTR (v_comp_installs, i, 1);

         IF vchr = ':'
         THEN
            v_tot_instals := NVL (v_tot_instals, 0) + 1;
         END IF;
      END LOOP;

      v_tot_instals := NVL (v_tot_instals, 0) + 1;

      --    DBMS_OUTPUT.PUT_LINE(v_tot_instals);
      IF v_tot_instals = 0
      THEN
         raise_error (   '1The percentages specified in setups '
                      || v_comp_installs
                      || ' is malformed'
                     );
      ELSIF v_tot_instals < v_install_no
      THEN
         raise_error (   'The percentages specified in setups '
                      || v_comp_installs
                      || ' do not cater for '
                      || v_install_no
                      || ' installments'
                     );
      END IF;

      FOR i IN 1 .. v_tot_instals
      LOOP
         --     DBMS_OUTPUT.PUT_LINE(v_str||'='||I||'='||v_tot_instals);
         IF    INSTR (v_str, ':') != 0
            OR (INSTR (v_str, ':') = 0 AND i = v_tot_instals)
         THEN
            BEGIN
               IF INSTR (v_str, ':') != 0
               THEN
                  v_val := SUBSTR (v_str, 1, INSTR (v_str, ':') - 1);
               ELSE
                  v_val := SUBSTR (v_str, 1);
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  raise_error
                      (   'Error processing percentages specified in setups '
                       || v_comp_installs
                      );
            END;