PROCEDURE pop_quot_clauses (
      v_quot_code     IN   NUMBER,
      v_qp_pro_code   IN   NUMBER,
      v_all_prod      IN   BOOLEAN DEFAULT TRUE
   )
   IS
      CURSOR quot_pro
      IS
         SELECT *
           FROM gin_quot_products
          WHERE qp_quot_code = v_quot_code;

      CURSOR cur_clauses (v_pro_code IN NUMBER, v_qp_code IN NUMBER)
      IS
         SELECT cls_code, cls_sht_desc, clp_pro_code, cls_editable,
                sbcl_scl_code, cls_type, cls_heading
           FROM gin_clause, gin_product_sub_classes, gin_subcl_clauses
          WHERE clp_scl_code = sbcl_scl_code
            AND sbcl_cls_code = cls_code
            AND clp_pro_code = v_pro_code
            AND NVL (sbcl_cls_mandatory, 'N') = 'Y'
            AND cls_code NOT IN (
                     SELECT qc_cls_code
                       FROM gin_quot_clauses
                      WHERE qc_pro_code = v_pro_code
                            AND qc_qp_code = v_qp_code);

      v_clause   LONG;
   BEGIN
      FOR qp IN quot_pro
      LOOP
         IF v_all_prod OR qp.qp_pro_code = v_qp_pro_code
         THEN
            FOR cls IN cur_clauses (qp.qp_pro_code, qp.qp_code)
            LOOP
               BEGIN
                  INSERT INTO gin_quot_clauses
                              (qc_cls_code, qc_cls_sht_desc,
                               qc_pro_code, qc_quot_code,
                               qc_quot_no, qc_quot_revision_no,
                               qc_qp_code, qc_cls_editable,
                               qc_sbcl_scl_code, qc_cls_type, qrc_cls_type,
                               qc_cls_heading
                              )
                       VALUES (cls.cls_code, cls.cls_sht_desc,
                               cls.clp_pro_code, qp.qp_quot_code,
                               qp.qp_quot_no, qp.qp_quot_revision_no,
                               qp.qp_code, cls.cls_editable,
                               cls.sbcl_scl_code, cls.cls_type, NULL,
                               cls.cls_heading
                              );
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     raise_error ('Error inserting clauses..');
               END;