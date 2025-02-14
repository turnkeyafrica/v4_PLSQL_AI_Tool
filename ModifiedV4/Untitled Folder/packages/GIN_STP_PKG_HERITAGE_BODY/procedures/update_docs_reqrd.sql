PROCEDURE update_docs_reqrd (
      v_ipu_code       NUMBER,
      v_ipu_clp_code   NUMBER,
      v_user_name      VARCHAR,
      v_doc_level      VARCHAR
   )
   IS
      CURSOR v_docr
      IS
         SELECT docr_id, docr_sht_desc, docr_desc
           FROM gin_documents_reqrd
          WHERE docr_mandtry = 'Y'
            AND docr_level = v_doc_level
            AND docr_clp_code = v_ipu_clp_code
            AND docr_id NOT IN (SELECT usdocr_docr_id
                                  FROM gin_uw_doc_reqrd_submtd
                                 WHERE usdocr_ipu_code = v_ipu_code);
   BEGIN
      FOR v_docr_rec IN v_docr
      LOOP
         INSERT INTO gin_uw_doc_reqrd_submtd
                     (usdocr_code, usdocr_docr_id, usdocr_ipu_code,
                      usdocr_submited, usdocr_date_s, usdocr_user_receivd
                     )
              VALUES (usdocr_id_seq.NEXTVAL, v_docr_rec.docr_id, v_ipu_code,
                      'N', TRUNC (SYSDATE), v_user_name
                     );
      -- COMMIT;
      END LOOP;
   END update_docs_reqrd;