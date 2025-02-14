PROCEDURE del_quot_prod (v_qp_code IN NUMBER)
   IS
      CURSOR qp_risks
      IS
         SELECT qr_code
           FROM gin_quot_risks
          WHERE qr_qp_code = v_qp_code;
   BEGIN
      FOR qpr IN qp_risks
      LOOP
         del_quot_risks (qpr.qr_code);
      END LOOP;

      DELETE      gin_quot_product_taxes
            WHERE qpt_qp_code = v_qp_code;

      DELETE      gin_quot_clauses
            WHERE qc_qp_code = v_qp_code;

      DELETE      gin_quot_products
            WHERE qp_code = v_qp_code;
   END;