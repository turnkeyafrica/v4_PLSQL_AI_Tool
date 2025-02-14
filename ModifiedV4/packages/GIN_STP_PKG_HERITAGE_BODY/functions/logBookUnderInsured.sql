FUNCTION logBookUnderInsured  (v_ipu_code IN NUMBER)
		RETURN VARCHAR2
	IS
		v_ipu_logbook_available       VARCHAR2 (5);
		v_ipu_lb_under_insured_name   VARCHAR2 (5);
		v_value                       VARCHAR2 (5) := 'N';
		v_scl_cla_code                NUMBER;
		v_ipu_sec_scl_code            NUMBER;
	BEGIN
		BEGIN
			SELECT ipu_logbook_available, ipu_lb_under_insured_name,ipu_sec_scl_code,scl_cla_code
			  INTO v_ipu_logbook_available, v_ipu_lb_under_insured_name,v_ipu_sec_scl_code,v_scl_cla_code
			  FROM gin_insured_property_unds,GIN_SUB_CLASSES
			 WHERE ipu_code = v_ipu_code
                AND ipu_sec_scl_code = scl_code;
		EXCEPTION
			WHEN OTHERS
			THEN
				raise_error (SQLERRM);
		END;

		IF v_scl_cla_code IN (70) AND v_ipu_sec_scl_code NOT IN (710,711,7802)
		THEN
			
			v_value := NVL(v_ipu_lb_under_insured_name,'N');
			
		END IF;


		RETURN v_value;
	END;