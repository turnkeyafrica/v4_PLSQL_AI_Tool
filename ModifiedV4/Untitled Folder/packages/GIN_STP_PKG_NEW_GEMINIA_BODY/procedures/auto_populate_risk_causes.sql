PROCEDURE auto_populate_risk_causes (v_ipu_code IN NUMBER)
    IS
        CURSOR risksrec IS
            SELECT ipu_sec_scl_code,
                   ipu_pol_policy_no,
                   ipu_pol_ren_endos_no,
                   ipu_pol_batch_no
              FROM gin_insured_property_unds, gin_policies
             WHERE ipu_code = v_ipu_code AND pol_batch_no = ipu_pol_batch_no;

        CURSOR clauses (v_scl_code IN NUMBER)
        IS
              SELECT sbcl_cls_code,
                     cls_sht_desc,
                     cls_heading,
                     sbcl_scl_code,
                     scl_desc,
                     cls_type,
                     DECODE (cls_type,
                             'CL', 'Clause',
                             'WR', 'Warranty',
                             'SC', 'Special Conditions')    type_desc,
                     cls_wording,
                     cls_editable
                FROM gin_sub_classes,
                     gin_clause,
                     gin_subcl_clauses,
                     gin_scl_cvt_mand_clauses
               WHERE     sbcl_cls_code = cls_code
                     AND scvtmc_cls_sht_desc = sbcl_cls_sht_desc
                     AND sbcl_scl_code = scl_code
                     AND scl_wet IS NULL
                     AND scvmtc_cls_mandatory = 'Y'
                     AND scvtmc_scl_code = v_scl_code
                     AND scvtmc_sclcovt_code IN
                             (SELECT ipu_covt_code
                                FROM gin_insured_property_unds
                               WHERE IPU_CODE = v_ipu_code)
                     AND sbcl_cls_code NOT IN
                             (SELECT pocl_sbcl_cls_code
                                FROM gin_policy_clauses
                               WHERE pocl_ipu_code = v_ipu_code)
            ORDER BY sbcl_cls_code;
    BEGIN
        FOR risk IN risksrec
        LOOP
            BEGIN
                FOR cls IN clauses (risk.ipu_sec_scl_code)
                LOOP
                    BEGIN
                        INSERT INTO gin_policy_clauses (
                                        pocl_sbcl_cls_code,
                                        pocl_sbcl_scl_code,
                                        pocl_cls_sht_desc,
                                        pocl_pol_policy_no,
                                        pocl_pol_ren_endos_no,
                                        pocl_pol_batch_no,
                                        pocl_ipu_code,
                                        plcl_cls_type,
                                        pocl_clause,
                                        pocl_cls_editable,
                                        pocl_new,
                                        pocl_heading)
                             VALUES (cls.sbcl_cls_code,
                                     cls.sbcl_scl_code,
                                     cls.cls_sht_desc,
                                     risk.ipu_pol_policy_no,
                                     risk.ipu_pol_ren_endos_no,
                                     risk.ipu_pol_batch_no,
                                     v_ipu_code,
                                     cls.cls_type,
                                     cls.cls_wording,
                                     cls.cls_editable,
                                     'N',
                                     cls.cls_heading);
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            ROLLBACK;
                            raise_error (
                                '  Error creating risk clauses record. Contact the system administrator...');
                    END;