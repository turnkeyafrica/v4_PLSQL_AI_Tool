FUNCTION get_prev_tran_type (
         v_batch_no        IN       NUMBER,
         v_prev_batch_no   OUT      VARCHAR2
      )
         RETURN VARCHAR2
      IS
         v_retval   VARCHAR2 (5);
         v_btchno   NUMBER;
      BEGIN
         SELECT pol_policy_status, pol_prev_batch_no
           INTO v_retval, v_btchno
           FROM gin_policies
          WHERE pol_batch_no = v_batch_no;

         IF v_retval = 'CO'
         THEN
            SELECT pol_policy_status, pol_prev_batch_no
              INTO v_retval, v_prev_batch_no
              FROM gin_policies
             WHERE pol_batch_no = v_btchno;
         ELSE
            v_prev_batch_no := v_btchno;
         END IF;

         RETURN (v_retval);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_retval := 'NONE';
         WHEN OTHERS
         THEN
            raise_error ('Error getting previous transaction type..');
      END;
   BEGIN
      BEGIN
         SELECT ROUND (pol_policy_cover_to - pol_policy_cover_from)
           INTO v_cover_days
           FROM gin_policies
          WHERE pol_batch_no = v_prevbatch_no;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            NULL;
         WHEN OTHERS
         THEN
            NULL;
      END;

      v_max_extensions :=
         NVL (gin_parameters_pkg.get_param_varchar ('MAX_NO_OF_EXTENSION'), 0);
      --v_prev_batch_no :=v_batch_no;
      v_maxed := 'N';

      FOR i IN 1 .. v_max_extensions
      LOOP
         v_trans_type := get_prev_tran_type (v_batch_no, v_prev_batch_no);
         DBMS_OUTPUT.put_line (   v_num
                               || '='
                               || v_batch_no
                               || '='
                               || v_prev_batch_no
                               || '='
                               || v_trans_type
                              );
         EXIT WHEN v_trans_type != 'EX';
         v_batch_no := v_prev_batch_no;
         v_num := NVL (v_num, 0) + 1;
      END LOOP;

      IF NVL (v_num, 0) >= v_max_extensions OR v_cover_days > 365
      THEN
         v_maxed := 'Y';
      END IF;

      DBMS_OUTPUT.put_line (v_maxed);
      RETURN v_maxed;
   END;