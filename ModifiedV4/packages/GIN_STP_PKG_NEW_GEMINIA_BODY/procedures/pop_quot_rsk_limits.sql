PROCEDURE pop_quot_rsk_limits (v_qr_code     IN NUMBER,
                                   v_qp_code     IN NUMBER,
                                   v_quot_code   IN NUMBER,
                                   v_pro_code    IN NUMBER,
                                   v_scl_code    IN NUMBER,
                                   v_bind_code   IN NUMBER,
                                   v_cvt_code    IN NUMBER)
    IS
    BEGIN
        update_mandatory_sections (v_qr_code,
                                   v_scl_code,
                                   v_bind_code,
                                   v_cvt_code,
                                   NULL,
                                   'N',
                                   'Q');
    END;