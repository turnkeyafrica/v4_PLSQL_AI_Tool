FUNCTION merge_ren_policies_text (
      v_pol_batch_no   IN   NUMBER,
      v_raw_txt        IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS
      v_text   VARCHAR2 (4000);
   BEGIN
      v_text :=
         tqc_memo_web_pkg.process_gis_pol_memo (v_pol_batch_no,
                                                NULL,
                                                NULL,
                                                v_raw_txt,
                                                'R'
                                               );
      RETURN (v_text);
   END;