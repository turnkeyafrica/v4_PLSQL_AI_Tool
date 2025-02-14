FUNCTION get_current_instal_period (
      v_date             IN       DATE,
      v_pol_wef          IN       DATE,
      v_pol_wet          IN       DATE,
      v_pol_no_install   IN       NUMBER,
      v_wef              OUT      DATE,
      v_wet              OUT      DATE
   )
      RETURN NUMBER
   IS
      v_lapsed_mnth   NUMBER;
   BEGIN
      IF v_date NOT BETWEEN v_pol_wef AND v_pol_wet
      THEN
         raise_error (   'Date provided '
                      || v_date
                      || ' not between the policy cover period '
                      || v_pol_wef
                      || ' and '
                      || v_pol_wet
                     );
      END IF;

      v_lapsed_mnth := CEIL (MONTHS_BETWEEN (v_date, v_pol_wef));

      IF v_lapsed_mnth = 0
      THEN
         v_lapsed_mnth := 1;
      END IF;

      DBMS_OUTPUT.put_line (v_lapsed_mnth || '=' || v_pol_no_install);

      IF v_lapsed_mnth >= NVL (v_pol_no_install, 1)
      THEN
         IF v_pol_no_install = 1
         THEN
            v_wef := v_pol_wef;
            v_wet := v_pol_wet;
         ELSE
            v_wef := ADD_MONTHS (v_pol_wef, v_pol_no_install - 1) - 1;
            v_wet := v_pol_wet;
         END IF;

         v_wef := GREATEST (v_wef, v_date);
         RETURN (v_pol_no_install);
      ELSE
         IF v_pol_no_install = 1
         THEN
            v_wef := v_pol_wef;
            v_wet := v_pol_wet;
         ELSIF v_lapsed_mnth = 1
         THEN
            v_wef := v_pol_wef;
            v_wet := ADD_MONTHS (v_pol_wef, v_lapsed_mnth) - 1;
         ELSE
            v_wef := ADD_MONTHS (v_pol_wef, v_lapsed_mnth - 1);
            v_wet := ADD_MONTHS (v_pol_wef, v_lapsed_mnth) - 1;
         END IF;

         v_wef := GREATEST (v_wef, v_date);
         RETURN (v_lapsed_mnth);
      END IF;
   END;