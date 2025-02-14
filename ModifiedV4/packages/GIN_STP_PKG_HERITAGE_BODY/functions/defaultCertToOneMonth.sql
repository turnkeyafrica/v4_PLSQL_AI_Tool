FUNCTION defaultCertToOneMonth (v_ipu_code IN NUMBER)
		RETURN VARCHAR2
	IS
		v_ipu_logbook_available       VARCHAR2 (5);
		v_ipu_lb_under_insured_name   VARCHAR2 (5);
		v_value                       VARCHAR2 (5) := 'N';
		v_s_logbook_no                VARCHAR2 (500);
		v_scl_cla_code                NUMBER;
		v_ipu_sec_scl_code            NUMBER;
	BEGIN
		BEGIN
			SELECT ipu_logbook_available, ipu_lb_under_insured_name
			  INTO v_ipu_logbook_available, v_ipu_lb_under_insured_name
			  FROM gin_insured_property_unds
			 WHERE ipu_code = v_ipu_code;
		EXCEPTION
			WHEN OTHERS
			THEN
				raise_error (SQLERRM);
		END;

		BEGIN
			SELECT mcoms_logbook_no, scl_cla_code,ipu_sec_scl_code
			  INTO v_s_logbook_no, v_scl_cla_code,v_ipu_sec_scl_code
			  FROM (SELECT mcoms_logbook_no, scl_cla_code,ipu_sec_scl_code
					  FROM gin_motor_commercial_sch,
						   gin_insured_property_unds,
						   GIN_SUB_CLASSES
					 WHERE     MCOMS_IPU_CODE = IPU_CODE
						   AND MCOMS_IPU_CODE = v_ipu_code
						   AND ipu_sec_scl_code = scl_code
					UNION
					SELECT mps_logbook_no, scl_cla_code,ipu_sec_scl_code
					  FROM gin_motor_private_sch,
						   gin_insured_property_unds,
						   GIN_SUB_CLASSES
					 WHERE     MPS_IPU_CODE = v_ipu_code
						   AND MPS_IPU_CODE = IPU_CODE
						   AND ipu_sec_scl_code = scl_code
					UNION   
					SELECT nvl(mcs_logbook_no,mcs_logbook)mcs_logbook_no , scl_cla_code,ipu_sec_scl_code
						   FROM gin_motor_cycle_sch,
						   gin_insured_property_unds,
						   GIN_SUB_CLASSES
						WHERE MCS_IPU_CODE =v_ipu_code
						AND  MCS_IPU_CODE = IPU_CODE
						   AND ipu_sec_scl_code = scl_code);
		EXCEPTION
			WHEN OTHERS
			THEN
				raise_error (SQLERRM);
		END;

		IF v_scl_cla_code IN (70) AND v_ipu_sec_scl_code NOT IN (710,711,7802)
		THEN
			IF v_ipu_logbook_available = 'N' OR v_ipu_lb_under_insured_name = 'N'
			THEN
				v_value := 'Y';
			ELSIF v_s_logbook_no IS NULL
			THEN
				v_value := 'Y';
			END IF;
		END IF;


		RETURN v_value;
	END;