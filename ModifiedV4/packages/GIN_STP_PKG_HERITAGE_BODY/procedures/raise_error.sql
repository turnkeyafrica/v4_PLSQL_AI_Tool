PROCEDURE raise_error   (v_msg IN VARCHAR2)
   IS
   BEGIN
      IF SQLCODE != 0
      THEN
         raise_application_error (-20015,
                                  v_msg || ' - ' || SQLERRM (SQLCODE));
      ELSE
         raise_application_error (-20015, v_msg);
      END IF;
   END raise_error;