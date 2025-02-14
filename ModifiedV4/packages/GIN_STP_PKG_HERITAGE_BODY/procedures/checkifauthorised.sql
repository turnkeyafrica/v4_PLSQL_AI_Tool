PROCEDURE checkifauthorised (v_pol_batch_no IN NUMBER)
   IS
      v_cnt   NUMBER;
   BEGIN
      SELECT COUNT (1)
        INTO v_cnt
        FROM gin_uw_pol_docs
       WHERE upd_pol_batch_no = v_pol_batch_no AND upd_dispatched = 'N';

      IF NVL (v_cnt, 0) > 0
      THEN
         raise_error (   'You have not Authorised '
                      || ' '
                      || v_cnt
                      || ' '
                      || 'Documents'
                     );
      END IF;
   END;