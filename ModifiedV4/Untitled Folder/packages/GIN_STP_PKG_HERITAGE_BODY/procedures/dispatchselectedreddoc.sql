PROCEDURE dispatchselectedreddoc (v_upd_code IN NUMBER)
   IS
   BEGIN
      UPDATE gin_uw_pol_docs
         SET upd_dispatched = 'Y'
       WHERE upd_code = v_upd_code;
   END;