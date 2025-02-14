PROCEDURE check_trans_made_ready (v_pol_batch_no IN NUMBER)
	IS
		v_pol_renewal_status       VARCHAR2 (5);
		v_pol_pro_code             NUMBER;
		v_count                    NUMBER;
		v_pol_pro_interface_type   VARCHAR2 (20);
	BEGIN
		SELECT pol_renewal_status, pol_pro_code, pol_pro_interface_type
		  INTO v_pol_renewal_status, v_pol_pro_code, v_pol_pro_interface_type
		  FROM gin_ren_policies
		 WHERE pol_batch_no = v_pol_batch_no;

		BEGIN
			SELECT COUNT (*)
			  INTO v_count
			  FROM gin_product_sub_classes, gin_sub_classes
			 WHERE     clp_scl_code = scl_code
				   AND scl_cla_code IN (30,
										32,
										31,
										12,
										13,36)
				   AND clp_pro_code = v_pol_pro_code;
		EXCEPTION
			WHEN OTHERS
			THEN
				v_count := 0;
		END;

		IF NVL (v_pol_pro_interface_type, 'XXXXX') NOT IN ('CASH')
		THEN
			IF NVL (v_count, 0) = 0
			THEN
				IF NVL (v_pol_renewal_status, 'S') != 'R'
				THEN
					RAISE_ERROR (
						   'Transaction is NOT made Ready.....');
				END IF;
			END IF;
		END IF;
	EXCEPTION
		WHEN OTHERS
		THEN
			raise_error (SQLERRM);
	END;