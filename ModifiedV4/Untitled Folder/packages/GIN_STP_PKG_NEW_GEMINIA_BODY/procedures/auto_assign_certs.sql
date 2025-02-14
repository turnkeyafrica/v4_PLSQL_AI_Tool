PROCEDURE auto_assign_certs (
        v_ipu_code            IN NUMBER,
        v_wef_date            IN DATE,
        v_wet_date            IN DATE,
        v_polc_passenger_no   IN NUMBER,
        v_pol_add_edit           VARCHAR2,
        v_tonnage                VARCHAR2 DEFAULT NULL)
    IS
        v_add_edit              VARCHAR2 (1);
        v_ct_code               NUMBER;
        v_ipu_id                NUMBER;
        v_cer_cnt               NUMBER;
        v_error                 VARCHAR2 (200);
        v_scl_code              NUMBER;
        v_covt_code             NUMBER;
        v_curr_cert_wet         DATE;
        v_cover_suspended       VARCHAR2 (3);
        v_polc_tonnage          NUMBER;
        v_polc_pll              NUMBER;
        v_depend                VARCHAR (1);
        v_pass                  NUMBER;
        v_pro_code              NUMBER;
        v_scr_name              VARCHAR2 (50);
        v_pol_regional_endors   VARCHAR (1);
    /*v_pol_regional_endors flag introduced to manage regional certificates GIS-12169*/
    BEGIN
        BEGIN
            SELECT DISTINCT pol_pro_code, pol_regional_endors
              INTO v_pro_code, v_pol_regional_endors
              FROM gin_policies, gin_insured_property_unds
             WHERE pol_batch_no = ipu_pol_batch_no AND ipu_code = v_ipu_code;
        EXCEPTION
            WHEN OTHERS
            THEN
                raise_error ('Error getting risk product details...');
        END;