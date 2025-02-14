```sql
                                                NULL, --IPU_EXCESS_RATE,
                                                NULL, --IPU_EXCESS_TYPE,
                                                NULL, --IPU_EXCESS_RATE_TYPE,
                                                NULL, --IPU_EXCESS_MIN,
                                                NULL,  --IPU_EXCESS_MAX,
                                                NULL, --IPU_PREREQ_IPU_CODE,
                                                NULL,  --IPU_ESCALATION_RATE,
                                                NULL, --IPU_COMM_RATE,
                                                pol_cur_rec.pol_prev_batch_no, --IPU_PREV_BATCH_NO,
                                                NULL, --IPU_CUR_CODE,
                                                NULL, --IPU_RELR_CODE,
                                                NULL,  --IPU_RELR_SHT_DESC,
                                                NULL,  --IPU_POL_EST_MAX_LOSS,
                                                NULL,  --IPU_EFF_WEF,
                                                NULL,  --IPU_EFF_WET,
                                                NULL,  --IPU_RETRO_COVER,
                                                NULL,  --IPU_RETRO_WEF,
                                                v_ipu_data(i).ipu_covt_code, --IPU_COVT_CODE,
                                                NULL,
                                                --IPU_COVT_SHT_DESC,
                                                NULL, --IPU_SI_DIFF,
                                                NULL,   --IPU_TERR_CODE,
                                                NULL,   --IPU_TERR_DESC,
                                                NULL, --IPU_FROM_TIME,
                                                NULL,  --IPU_TO_TIME,
                                                NULL,  --IPU_MAR_CERT_NO,
                                                NULL, --IPU_COMP_RETENTION,
                                                NULL, --IPU_GROSS_COMP_RETENTION,
                                                NULL,  --IPU_COM_RETENTION_RATE,
                                                v_ipu_data(i).prp_code,
                                                 --IPU_PRP_CODE,
                                                NULL,  --IPU_TOT_ENDOS_PREM_DIF,
                                                NULL,  --IPU_TOT_GP,
                                                NULL, --IPU_TOT_VALUE,
                                                NULL, --IPU_RI_AGNT_COM_RATE,
                                                v_cover_days, --IPU_COVER_DAYS,
                                                NULL,   --IPU_BP,
                                                NULL,   --IPU_PREV_PREM,
                                                NULL,  --IPU_RI_AGNT_COMM_AMT,
                                                NULL,   --IPU_TOT_FAP,
                                                v_max_exposure, --IPU_MAX_EXPOSURE,
                                                'A',   --IPU_STATUS,
                                                v_uw_yr,
                                                NULL,   --IPU_TOT_FIRST_LOSS,
                                                NULL,   --IPU_ACCUMULATION_LIMIT,
                                                NVL(v_ipu_data(i).ipu_compute_max_exposure,'N'),  --IPU_COMPUTE_MAX_EXPOSURE,
                                                  NULL,
                                                 NULL,
                                                NULL,
                                                NULL,
                                                 NULL,
                                                 NULL,
                                                 NULL,
                                                NULL,
                                                 NULL,
                                                 NULL,
                                                  NULL,
                                                  NULL,
                                                  NULL,
                                                  NULL,
                                                  NULL,
                                                  NULL,
                                                 NULL,
                                                NULL, --IPU_FP,
                                                NULL, --IPU_CONVEYANCE_TYPE,
                                                NULL, --IPU_ENDOSE_FAP_OR_BC,
                                                 NULL,
                                                v_ipu_prev_status,
                                                v_ipu_ncd_cert_no,
                                                v_install_period,
                                                v_risk_pymt_install_pcts,
                                                v_susp_reinst_type,
                                                NULL,
                                                v_ipu_data(i).ipu_suspend_wef,
                                                v_ipu_data(i).ipu_suspend_wet,
                                                NULL,
                                                NULL,
                                                NULL,
                                                v_enforce_covt_prem,
                                                 NULL,
                                                NULL,
                                                 NULL,
                                                 NULL,
                                                NULL,
                                                 NULL,
                                                  NULL,
                                                 NULL,
                                                 NULL,
                                                 NULL,
                                                 v_ipu_data(i).ipu_risk_note,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                 NULL,
                                                NULL,
                                                  NULL,
                                                  NULL,
                                                  NULL
                                            );
                            
                            
                            
                           
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              raise_error('ERROR SAVING RISK DETAILS ..'||SQLERRM);
                        END;
                       
                         
                               
                                  IF NVL(v_autopopltsections_param,'Y') = 'Y'
                                 THEN
                                 BEGIN
                                   INSERT INTO gin_ipu_sections
                                  (ipus_ipu_code,
                                   ipus_section_code,
                                   ipus_mandatory,
                                   ipus_added_by,
                                   ipus_added_date)
                                 SELECT v_new_ipu_code,
                                        sec_code,
                                        'Y',
                                        v_user,
                                        SYSDATE
                                   FROM gin_sections
                                  WHERE sec_scl_code= v_ipu_data (i).ipu_scl_code
                                  AND sec_mandatory='Y';
                                   EXCEPTION
                                     WHEN OTHERS
                                     THEN
                                     raise_error('Error autopopulating sections.!');
                                  END;
                                 END IF;   
                                 
                                 IF NVL(v_auto_populate_limits,'Y') = 'Y'
                                 THEN
                                 BEGIN
                                   INSERT INTO GIN_IPU_LIMITS
                                  (IPUL_IPU_CODE,
                                   IPUL_LOA_CODE,
                                   IPUL_LIMIT,
                                   IPUL_ADDED_BY,
                                   IPUL_ADDED_DATE
                                   )
                                 SELECT v_new_ipu_code,
                                        LOA_CODE,
                                        LOA_DEFAULT_LIMIT,
                                        v_user,
                                        SYSDATE
                                   FROM GIN_LIMITS_OF_LIABILITY
                                  WHERE LOA_SCL_CODE =v_ipu_data (i).ipu_scl_code;
                                   EXCEPTION
                                     WHEN OTHERS
                                     THEN
                                     raise_error('Error autopopulating limits of liability.!');
                                  END;
                                 END IF;  
                       
                     END LOOP;
                ELSIF NVL (v_ipu_data (i).ipu_add_edit, 'A') = 'E'
                THEN
                     FOR pol_cur_rec IN pol_cur
                    LOOP
                           v_wef_date :=
                            NVL (v_ipu_data (i).ipu_wef,
                                 pol_cur_rec.pol_wef_dt);
                        v_wet_date :=
                            NVL (v_ipu_data (i).ipu_wet,
                                 pol_cur_rec.pol_wet_dt);
                                 
                              IF v_wef_date NOT BETWEEN pol_cur_rec.pol_policy_cover_from
                                              AND pol_cur_rec.pol_policy_cover_to
                        THEN
                            raise_error (
                                   'The Risk cover dates provided must be within the policy cover periods. '
                                || pol_cur_rec.pol_policy_cover_from
                                || ' TO '
                                || pol_cur_rec.pol_policy_cover_to);
                        END IF;

                        IF v_wet_date NOT BETWEEN pol_cur_rec.pol_policy_cover_from
                                              AND pol_cur_rec.pol_policy_cover_to
                        THEN
                            raise_error (
                                   'The Risk cover dates provided must be within the policy cover periods. '
                                || pol_cur_rec.pol_policy_cover_from
                                || ' TO '
                                || pol_cur_rec.pol_policy_cover_to);
                        END IF;
                         IF v_ipu_data (i).ipu_suspend_wef != NULL
                        THEN
                            IF v_ipu_data (i).ipu_suspend_wef NOT BETWEEN v_wef_date
                                                                      AND v_wet_date
                            THEN
                                raise_error (
                                    'Risk Suspend Wef Date must be between Risk Dates..');
                            END IF;
                        END IF;

                        IF v_ipu_data (i).ipu_suspend_wet != NULL
                        THEN
                            IF v_ipu_data (i).ipu_suspend_wet NOT BETWEEN v_wef_date
                                                                      AND v_wet_date
                            THEN
                                raise_error (
                                    'Risk Suspend Wet Date must be between Risk Dates..');
                            END IF;
                        END IF;

                        IF v_ipu_data (i).ipu_suspend_wet <
                           v_ipu_data (i).ipu_suspend_wef
                        THEN
                            raise_error (
                                'Risk Suspend Wet Date Cannot be less than Risk Suspend Wef Date..');
                        END IF;
                        
                        
                        
                    
                    
                        BEGIN
                                    UPDATE gin_insured_property_unds
                                        SET 
                                            ipu_item_desc= v_ipu_data (i).ipu_desc,
                                            ipu_wef= v_wef_date,
                                            ipu_wet=v_wet_date,
                                             ipu_earth_quake_cover=NULL,
                                            ipu_earth_quake_prem=NULL,
                                            ipu_location=v_ipu_data (i).ipu_location,
                                            ipu_sec_scl_code=v_ipu_data (i).ipu_scl_code,
                                            ipu_ncd_status=v_ipu_data (i).ipu_ncd_status,
                                            ipu_ncd_level=v_ipu_data (i).ipu_ncd_lvl,
                                            ipu_quz_code=v_ipu_data (i).ipu_quz_code,
                                            ipu_quz_sht_desc=v_quz_sht_desc,
                                            ipu_bind_code=v_bind_code,
                                             ipu_suspend_wef=v_ipu_data(i).ipu_suspend_wef,
                                            ipu_suspend_wet=v_ipu_data(i).ipu_suspend_wet,
                                            ipu_risk_note =  v_ipu_data(i).ipu_risk_note,
                                            ipu_covt_code=v_ipu_data(i).ipu_covt_code
                                      WHERE ipu_code=v_ipu_data (i).gis_ipu_code;
                                      
                                      
                                    EXCEPTION
                                       WHEN OTHERS
                                       THEN
                                        raise_error('ERROR UPDATING RISK DETAILS ..'||SQLERRM);
                                    END;
                                    
                                     IF NVL(v_autopopltsections_param,'Y') = 'Y'
                                 THEN
                                 BEGIN
                                    DELETE  FROM gin_ipu_sections  WHERE ipus_ipu_code = v_ipu_data (i).gis_ipu_code;
                                    
                                   INSERT INTO gin_ipu_sections
                                  (ipus_ipu_code,
                                   ipus_section_code,
                                   ipus_mandatory,
                                   ipus_added_by,
                                   ipus_added_date)
                                 SELECT v_ipu_data (i).gis_ipu_code,
                                        sec_code,
                                        'Y',
                                        v_user,
                                        SYSDATE
                                   FROM gin_sections
                                  WHERE sec_scl_code= v_ipu_data (i).ipu_scl_code
                                  AND sec_mandatory='Y';
                                   EXCEPTION
                                     WHEN OTHERS
                                     THEN
                                     raise_error('Error autopopulating sections.!');
                                  END;
                                 END IF;   
                                 
                                 
                                 
                                 IF NVL(v_auto_populate_limits,'Y') = 'Y'
                                 THEN
                                 BEGIN
                                  DELETE FROM GIN_IPU_LIMITS  WHERE IPUL_IPU_CODE= v_ipu_data (i).gis_ipu_code;
                                   INSERT INTO GIN_IPU_LIMITS
                                  (IPUL_IPU_CODE,
                                   IPUL_LOA_CODE,
                                   IPUL_LIMIT,
                                   IPUL_ADDED_BY,
                                   IPUL_ADDED_DATE
                                   )
                                 SELECT v_ipu_data (i).gis_ipu_code,
                                        LOA_CODE,
                                        LOA_DEFAULT_LIMIT,
                                        v_user,
                                        SYSDATE
                                   FROM GIN_LIMITS_OF_LIABILITY
                                  WHERE LOA_SCL_CODE =v_ipu_data (i).ipu_scl_code;
                                   EXCEPTION
                                     WHEN OTHERS
                                     THEN
                                     raise_error('Error autopopulating limits of liability.!');
                                  END;
                                 END IF;  
                    END LOOP;
                ELSIF NVL (v_ipu_data (i).ipu_add_edit, 'A') = 'D'
                THEN
                    BEGIN
                        DELETE FROM gin_insured_property_unds
                         WHERE ipu_code = v_ipu_data (i).gis_ipu_code;
                       
                     DELETE FROM gin_schedule_mapping
                        WHERE gsm_ipu_code = v_ipu_data(i).gis_ipu_code ;
                        
                     DELETE FROM gin_ipu_sections
                         WHERE ipus_ipu_code = v_ipu_data(i).gis_ipu_code ;
                         
                    DELETE  FROM GIN_IPU_LIMITS WHERE IPUL_IPU_CODE=v_ipu_data (i).gis_ipu_code;
                     
                     
                     
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            raise_error ('Error Deleting risk details');
                    END;
                END IF;
            END LOOP;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            raise_error ('Error saving/updating risk details ' || SQLERRM);
    END;
END;
/

```