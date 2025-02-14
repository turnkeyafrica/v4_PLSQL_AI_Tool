PROCEDURE delete_risk_section (v_pil_code IN NUMBER, v_batch_no IN NUMBER)
   IS
      v_pol_binder          VARCHAR2 (2);
      v_bindr_del_allowed   VARCHAR2 (10);
   -- REMEMBER TO HANLDE BINDERS. WE DONT DELETE BINDER SECTIONS SOLOMON 05/07/2010
   BEGIN
      --RAISE_ERROR('v_pil_code'||v_pil_code);
      BEGIN
         SELECT pol_binder_policy
           INTO v_pol_binder
           FROM gin_policies
          WHERE pol_batch_no = v_batch_no;
      EXCEPTION
         WHEN OTHERS
         THEN
            raise_error ('Error determining the policy binder..3..');
      END;

      IF NVL (v_pol_binder, 'N') = 'Y'
      THEN
         v_bindr_del_allowed :=
                     gin_parameters_pkg.get_param_varchar ('BINDER_SECT_DEL');
      END IF;

      IF    NVL (v_pol_binder, 'N') != 'Y'
         OR (    NVL (v_pol_binder, 'N') = 'Y'
             AND NVL (v_bindr_del_allowed, 'N') = 'Y'
            )
      THEN
         DELETE FROM gin_pol_med_fam_insured_limits
               WHERE pmfil_pil_code = v_pil_code;

         DELETE      gin_policy_insured_limits
               WHERE pil_code = v_pil_code;
      ELSE
         tqc_error_manager.raise_unanticipated
                           (text_in      => 'Deleting Binder Section not allowed.');
      END IF;
   END;