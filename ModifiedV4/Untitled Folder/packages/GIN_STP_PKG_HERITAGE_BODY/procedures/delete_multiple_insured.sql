PROCEDURE delete_multiple_insured (
      v_polin_code     IN   NUMBER,
      v_pol_batch_no   IN   NUMBER,
      v_pro_code       IN   NUMBER
   )
   IS
      v_cnt             NUMBER;
      v_auths           VARCHAR2 (100);
      -- v_polin_code NUMBER;
      v_err_pos         VARCHAR2 (100);
      v_cert_ipu_code   NUMBER;
      v_errmsg          VARCHAR2 (200);

      CURSOR insured_ref
      IS
         SELECT *
           FROM gin_insured_property_unds
          WHERE ipu_polin_code = v_polin_code;
   BEGIN
      FOR x IN insured_ref
      LOOP
         del_ipu_details (v_pol_batch_no, x.ipu_code, v_pro_code);
      END LOOP;

      DELETE      gin_policy_insureds
            WHERE polin_code = v_polin_code;
   EXCEPTION
      WHEN OTHERS
      THEN
         raise_error ('deleting Insured details failed');
   END;