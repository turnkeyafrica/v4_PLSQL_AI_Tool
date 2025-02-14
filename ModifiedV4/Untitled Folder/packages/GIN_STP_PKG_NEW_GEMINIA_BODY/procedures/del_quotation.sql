PROCEDURE del_quotation (v_quot_code IN NUMBER)
    IS
        CURSOR quot_prods IS
            SELECT qp_code
              FROM gin_quot_products
             WHERE qp_quot_code = v_quot_code;
    BEGIN
        FOR qps IN quot_prods
        LOOP
            del_quot_prod (qps.qp_code);
        END LOOP;

        DELETE gin_policy_exceptions
         WHERE gpe_quot_code = v_quot_code;

        DELETE gin_quotations
         WHERE quot_code = v_quot_code;
    END;