PROCEDURE del_pol_cover_type_clauses (v_batch_no IN NUMBER,v_covt_code IN NUMBER)
   IS
   BEGIN 
   --raise_error(v_batch_no||'='||v_covt_code);
        DELETE gin_policy_lvl_clauses
        WHERE plcl_pol_batch_no = v_batch_no
        AND plcl_sbcl_cls_code IN (SELECT scvtmc_cls_code
                                  FROM gin_scl_cvt_mand_clauses
                                  WHERE scvtmc_sclcovt_code=v_covt_code) ; 
                                  
        DELETE gin_policy_subclass_clauses
        WHERE poscl_pol_batch_no = v_batch_no
        AND poscl_cls_code IN (SELECT scvtmc_cls_code
                                 FROM gin_scl_cvt_mand_clauses
                                WHERE scvtmc_sclcovt_code = v_covt_code);                           
        
   END;