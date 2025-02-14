PROCEDURE gin_ipu_prc (
   v_batch_no          IN       NUMBER,
   v_trans_type        IN       VARCHAR2,
   v_pol_add_edit      IN       VARCHAR2,
   v_ipu_data          IN       web_risk_tab,
   v_user              IN       VARCHAR2,
   v_new_ipu_code      OUT      NUMBER,
   v_renewal_area      IN       VARCHAR2,
   v_loaded            IN       VARCHAR2 DEFAULT 'N',
   v_ipu_ncd_cert_no   IN       VARCHAR2 DEFAULT NULL,
   v_del_sect          IN       VARCHAR2 DEFAULT NULL
)
IS
   v_cnt                       NUMBER;
   v_new_polin_code            NUMBER;
   v_uw_yr                     VARCHAR2 (1);
   v_stp_code                  NUMBER;
   v_wef_date                  DATE;
   v_wet_date                  DATE;
   v_cover_days                NUMBER;
   v_bind_code                 NUMBER;
   v_bind_name                 VARCHAR2 (100);
   v_cert_no                   VARCHAR2 (35);
   v_quz_sht_desc              VARCHAR2 (35);
   --v_count                                NUMBER;
   v_uw_trans                  VARCHAR2 (1);
   v_ren_cnt                   NUMBER;
   v_ipu_prev_status           VARCHAR2 (35);
   v_ipu_prorata               VARCHAR2 (2);
   v_cvt_install_type          gin_subclass_cover_types.sclcovt_install_type%TYPE;
   v_cvt_max_installs          gin_subclass_cover_types.sclcovt_max_installs%TYPE;
   v_cvt_pymt_install_pcts     gin_subclass_cover_types.sclcovt_pymt_install_pcts%TYPE;
   v_cvt_install_periods       gin_subclass_cover_types.sclcovt_install_periods%TYPE;
   v_pol_tot_instlmt           NUMBER;
   v_pymnt_tot_instlmt         NUMBER;
   v_install_pct               NUMBER;
   v_ipu_id                    NUMBER;
   v_cer_cnt                   NUMBER;
   v_ct_code                   NUMBER;
   v_error                     VARCHAR2 (200);
   v_cer_cnt                   NUMBER;
   v_ipu_id                    NUMBER;
   v_install_period            NUMBER;
   v_polc_code                 NUMBER;
   v_risk_pymt_install_pcts    VARCHAR2 (50);
   v_susp_reinst_type          VARCHAR2 (5);
   v_suspend_wef               DATE;
   v_suspend_wet               DATE;
   v_new_pol_wet               DATE;
   v_rsk_trans_type            VARCHAR2 (3);
   v_pol_instal_wet            DATE;
   v_wef                       DATE;
   v_prev_install_period       NUMBER;
   v_increment_by              NUMBER;
   v_increment                 VARCHAR2 (2);
   v_interface_type            VARCHAR2 (50);
   v_cnt1                      NUMBER;
    --  v_install_wef  DATE;
   --   v_install_wet  DATE;
   v_risk_id_format            VARCHAR2 (50);
   v_risk_id_format_param      VARCHAR2 (50);
   v_id_reg_no                 VARCHAR2 (50);
   v_clnt_pin_no               VARCHAR2 (50);
   v_ipu_covt_code             NUMBER;
   v_clnt_passport_no          VARCHAR2 (50);
   v_agent_code                NUMBER;
   v_agn_pin                   VARCHAR2 (50);
   v_max_exposure              NUMBER;
   v_pol_status                VARCHAR2 (10);
   v_enforce_covt_prem         VARCHAR2 (1);
   v_covt_code                 NUMBER;
   v_cvt_desc                  VARCHAR2 (10);
   v_cert_autogen              VARCHAR2 (1);
   v_autopopltsections_param   VARCHAR2 (1);
   v_agnt_agent_code           NUMBER;
   v_franch_agn_code number;
   v_franch_act_code number;
   v_loaded_cert number;
   v_scl_motor_verify VARCHAR2 (1);
   v_driver_name VARCHAR2 (100);
   v_enablebloomapi_funct      VARCHAR2 (1);
   v_bloomtrns_cnt             NUMBER;
   v_scl_desc      VARCHAR2 (100);
   v_arc_code             NUMBER;
   v_prev_ipu_property_id      VARCHAR2 (100);
   v_exist_active_cert         NUMBER;
   v_apcd_ipu_id                    NUMBER;
   v_as_uwyr                   NUMBER;
   v_pro_tuw_yr_applicable     VARCHAR2 (2);

   CURSOR pol_cur
   IS
      SELECT gin_policies.*, NVL (pro_expiry_period, 'Y') pro_expiry_period,
             
             NVL (pro_open_cover, 'N') pro_open_cover,
--             NVL (pol_open_cover, 'N') pol_open_cover,
             NVL (pro_earthquake, 'N') pro_earthquake,
             NVL (pro_moto_verfy, 'N') pro_moto_verfy,
             NVL (pro_stp, 'N') pro_stp,A.AGN_ACT_CODE,B.AGN_ACT_CODE MKT,
			 pro_change_uw_on_ex
        FROM gin_policies, gin_products,tqc_agencies A ,tqc_agencies B
       WHERE pro_code = pol_pro_code 
        AND A.AGN_CODE(+)=POL_AGNT_AGENT_CODE
            AND POL_MKTR_AGN_CODE =B.AGN_CODE(+)
            AND pol_batch_no = v_batch_no;

   CURSOR pol_ren_cur
   IS
      SELECT gin_ren_policies.*,
             NVL (pro_expiry_period, 'Y') pro_expiry_period,
             
             --NVL (pro_open_cover, 'N') pro_open_cover
             NVL (pol_open_cover, 'N') pro_open_cover,
             NVL (pro_moto_verfy, 'N') pro_moto_verfy,
             NVL (pro_stp, 'N') pro_stp,
			 pro_change_uw_on_ex
        FROM gin_ren_policies, gin_products
       WHERE pro_code = pol_pro_code AND pol_batch_no = v_batch_no;
       
    CURSOR COMM (V_SCL_CODE NUMBER,V_ACT_CODE NUMBER ,V_BIND_CODE NUMBER, V_LTA_APP VARCHAR2,v_franch_agn_cd NUMBER) 
    IS 
    SELECT trans_code,comm_act_code,trnt_code,DECODE(DECODE(trnt_code,'LTA-U',BIND_LTA_TYPE,BIND_COMM_TYPE),'B',1,2) ORDER_TYPE 
    FROM GIN_TRANS_TYPE, GIN_TRANSACTION_TYPES,GIN_COMMISSIONS,GIN_BINDERS
    WHERE TRANS_CODE=TRNT_TRANS_CODE
    AND COMM_TRNT_CODE = TRNT_CODE 
    AND COMM_TRANS_CODE=TRANS_CODE
    AND COMM_BIND_CODE=BIND_CODE
    AND trnt_code  NOT IN DECODE(NVL(V_LTA_APP,'N'),'N','LTA-U','Y','ALL')
    and comm_trnt_code in decode(nvl(v_franch_agn_cd,0),0,'UC-U',comm_trnt_code) 
    AND  comm_trnt_code NOT IN decode(nvl(v_franch_agn_cd,0),0,'UNDIFINED','UC-U') 
    AND  comm_trnt_code NOT IN decode(nvl(v_franch_agn_cd,0),0,'UNDIFINED','LTA-U')    
    AND COMM_SCL_CODE= V_SCL_CODE
    AND COMM_ACT_CODE = V_ACT_CODE
    AND COMM_BIND_CODE =V_BIND_CODE
    UNION ALL
    SELECT trans_code,comm_act_code,trnt_code,DECODE(DECODE(trnt_code,'LTA-U',BIND_LTA_TYPE,BIND_COMM_TYPE),'B',1,2) ORDER_TYPE 
    FROM GIN_TRANS_TYPE, GIN_TRANSACTION_TYPES,GIN_COMMISSIONS,GIN_BINDERS
    WHERE TRANS_CODE=TRNT_TRANS_CODE
    AND COMM_TRNT_CODE = TRNT_CODE 
    AND COMM_TRANS_CODE=TRANS_CODE
    AND COMM_BIND_CODE=BIND_CODE
    AND trnt_code    IN DECODE(NVL(V_LTA_APP,'N'),'N','LTA-U','Y','ALL')
    and comm_trnt_code NOT  in decode(nvl(v_franch_agn_cd,0),0,'UC-U',comm_trnt_code) 
    AND  comm_trnt_code NOT IN decode(nvl(v_franch_agn_cd,0),0,'UNDIFINED','UC-U') 
    AND  comm_trnt_code NOT IN decode(nvl(v_franch_agn_cd,0),0,'UNDIFINED','LTA-U')    
    AND COMM_SCL_CODE= V_SCL_CODE
    AND COMM_ACT_CODE = V_ACT_CODE
    AND COMM_BIND_CODE =V_BIND_CODE;
BEGIN
   SELECT gin_stp_code_seq.NEXTVAL
     INTO v_stp_code
     FROM DUAL;

   IF v_ipu_data.COUNT = 0
   THEN
      raise_error ('No Risk data provided..');
   END IF;

   --FOR pol_cur_rec IN pol_cur
   --LOOP
   BEGIN
      SELECT param_value
        INTO v_autopopltsections_param
        FROM gin_parameters
       WHERE param_name = 'AUTO_POPLT_MAND_SECTIONS';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_autopopltsections_param := 'Y';
      WHEN OTHERS
      THEN
         v_autopopltsections_param := 'Y';
   END;
      BEGIN
         SELECT param_value
           INTO v_enablebloomapi_funct
           FROM gin_parameters
          WHERE param_name = 'ENABLE_BLOOMAPI_