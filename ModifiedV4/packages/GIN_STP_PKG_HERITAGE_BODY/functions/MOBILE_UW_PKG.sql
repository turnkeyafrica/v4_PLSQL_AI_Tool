FUNCTION MOBILE_UW_PKG ( v_pro_code IN NUMBER ,

v_client_name IN VARCHAR2 ,

v_tel IN VARCHAR2 ,

v_email IN VARCHAR2 ,

v_wef DATE ,

v_reg_id VARCHAR2 ,

v_make VARCHAR2 ,

v_covertype IN VARCHAR2 ,

v_suminsured NUMBER ) RETURN VARCHAR2 IS

v_pol_batch_no NUMBER ;

v_prp_code NUMBER ;

v_cnt NUMBER ;

Vpol_id NUMBER ;

v_rtntext VARCHAR2 ( 200 );

rsk_cnt NUMBER := 0 ;

sect_cnt NUMBER := 0 ;

v_pro_sht_desc varchar2 ( 25 );

v_pro_desc varchar2 ( 25 );

v_pro_renewable VARCHAR2 ( 15 );

v_wet date ;

v_cur_rate number ;

v_cur_code number ;

v_cur_symbol VARCHAR2 ( 15 );

v_brn_code number ;

v_brn_sht_desc VARCHAR2 ( 15 );

v_ipu_code NUMBER ;



v_scl_code NUMBER := 701 ;

v_scl_desc VARCHAR2 ( 15 ):= 'MOTOR PRIVATE' ;

v_bind_code NUMBER := 20072573 ;

v_bind_desc VARCHAR2 ( 25 ):= '701SIMPLE' ;

v_cvt_code NUMBER := 50 ;

v_cvt_desc VARCHAR2 ( 15 ):= 'COMP' ;

v_cert_type VARCHAR2 ( 15 ):= NULL;

v_sect_code NUMBER := 1142 ;

v_sect_desc varchar2 ( 15 ):= 'SECTION SI' ;



BEGIN

BEGIN

SELECT PRO_DESC , PRO_SHT_DESC , PRO_RENEWABLE

INTO v_pro_desc , v_pro_sht_desc , v_pro_renewable

FROM GIN_PRODUCTS

WHERE PRO_CODE = v_pro_code ;

EXCEPTION

WHEN OTHERS THEN

RAISE_ERROR ( 'Error getting product details..' );

END;

SELECT GIN_WEB_POLICIES_SEQ .NEXTVAL INTO Vpol_id FROM DUAL ;

v_wet := GET_WET_DATE ( v_pro_code , v_wef ) ;

v_cur_rate := NULL;

BEGIN

SELECT BRN_CODE , BRN_SHT_DESC

INTO v_brn_code , v_brn_sht_desc

FROM TQC_ORGANIZATIONS , TQC_BRANCHES , TQC_SYSTEMS

WHERE ORG_WEB_BRN_CODE = BRN_CODE

AND ORG_CODE = SYS_ORG_CODE

AND SYS_CODE = 37 ;

EXCEPTION

WHEN OTHERS THEN

RAISE_ERROR ( 'Error getting default branch.' );

END;

BEGIN

SELECT ORG_CUR_CODE , CUR_SYMBOL

INTO v_cur_code , v_cur_symbol

FROM TQC_ORGANIZATIONS , TQC_SYSTEMS , TQC_CURRENCIES

WHERE ORG_CODE = SYS_ORG_CODE

AND ORG_CUR_CODE = CUR_CODE

AND SYS_CODE = 37 ;

EXCEPTION

WHEN OTHERS THEN

RAISE_ERROR ( 'UNABLE TO RETRIEVE THE BASE CURRENCY' );

END;

IF v_cur_code IS NULL THEN

RAISE_ERROR ( 'THE BASE CURRENCY HAVE NOT BEEN DEDFINED. CANNOT PROCEED.' );

END IF;

v_cur_rate := 1 ; --Get_Exchange_Rate(v_cur_code, v_pol_Data(pcount).POL_CUR_CODE);

BEGIN

INSERT INTO GIN_WEB_POLICIES

( POL_ID , POL_POLICY_NO , POL_AGNT_CODE , POL_WEF_DT , POL_WET_DT , POL_CUR_CODE , POL_CUR_SYMBOL ,

POL_CUR_RATE , POL_PRP_CODE , POL_PRP_SHT_DESC , POL_PRO_CODE , POL_YOUR_REF , POL_PRO_SHT_DESC ,

POL_RENEWABLE , POL_SHORT_PERIOD , POL_ADD_EDIT , POL_BATCH_NO , POL_TRANS_TYPE , POL_GIS_POLICY_NO ,

POL_ENDOS_EFF_DATE , POL_EXTEND_TO_DATE , POL_BRN_CODE , POL_BRN_SHT_DESC , POL_COINSURANCE ,

POL_COINSURE_LEADER , POL_BINDER_POLICY , POL_COINSURANCE_SHARE , POL_RI_AGENT_COMM_RATE ,

POL_RI_AGNT_SHT_DESC , POL_RI_AGNT_AGENT_CODE , POL_BIND_CODE , POL_POLICY_TYPE ,

POL_COMMISSION_ALLOWED , POL_AGNT_SHT_DESC , POL_AGNT_AGENT_CODE , POL_PIP_CODE ,

POL_PIP_PF_CODE , POL_COMMENTS , POL_INTERNAL_COMMENTS , POL_EXIPRY_DATE , POL_STATUS ,

PRO_DESC , POL_QUOT_DATE )

VALUES

( Vpol_id ,NULL, 0 , v_wef , v_wet , v_cur_code , v_cur_symbol ,

v_cur_rate , NULL, NULL, v_pro_code , 'MOBILE' , v_pro_sht_desc ,

v_pro_renewable , 'N' , 'A' , NULL, 'NB' , NULL,

v_wef , NULL, v_brn_code , v_brn_sht_desc , 'N' ,

'N' , 'N' , 100 , 0 ,

NULL, NULL, v_bind_code , 'N' ,

'Y' , 'DIRECT' , 0 , NULL,

NULL, 'MOBILE' , NULL, NULL, NULL,

v_pro_desc , null);

EXCEPTION

WHEN OTHERS THEN

RAISE_ERROR ( 'Error creating policy record..' );

END;

BEGIN

SELECT INSURED_PROPERTY_CODE .NEXTVAL INTO v_ipu_code FROM DUAL ;



INSERT INTO GIN_WEB_RISKS

( IPU_CODE , IPU_PROPERTY_ID , IPU_DESC , IPU_SCL_CODE , IPU_SCL_DESC , IPU_CVT_CODE ,

IPU_CVT_DESC , IPU_BIND_CODE , IPU_BIND_DESC ,

IPU_POL_ID , GIS_IPU_CODE , IPU_POLIN_CODE , IPU_PRP_CODE , IPU_ADD_EDIT ,

IPU_RISK_ADDRESS , IPU_RISK_DETAILS , IPU_PRORATA , IPU_NCD_STATUS ,

IPU_NCD_LVL , IPU_QUZ_CODE , IPU_RELR_CODE , IPU_RELR_SHT_DESC , IPU_RETRO_COVER ,

IPU_RETRO_WEF , IPU_TERR_CODE , IPU_TERR_DESC , IPU_RC_CODE , IPU_RC_SHT_DESC ,

IPU_FREE_LIMIT , IPU_SURVEY_DATE , IPU_WEF , IPU_WET , IPU_OVERRIDE_PREMIUM ,

IPU_CERT_TYPE , IPU_CERT_WEF , IPU_CERT_WET , IPU_PRO_CODE , IPU_PRO_SHT_DESC ,

IPU_PRP_SHT_DESC , IPU_PRO_DESC )

VALUES

( v_ipu_code , v_reg_id , v_make , v_scl_code , v_scl_desc , v_cvt_code ,

v_cvt_desc , v_bind_code , v_bind_desc ,

Vpol_id , NULL, NULL, NULL, 'A' ,

NULL, NULL, 'P' , NULL,

NULL, NULL, NULL, NULL, NULL,

NULL, NULL, NULL, NULL, NULL,

NULL, NULL, v_wef , v_wet , NULL,

v_cert_type , v_wef , v_wet , v_pro_code , v_pro_sht_desc ,

NULL, v_pro_desc );

EXCEPTION

WHEN OTHERS THEN

RAISE_ERROR ( 'Error creating risk details..' );

END;

BEGIN

INSERT INTO GIN_WEB_RISK_SECTIONS

( PIL_CODE , PIL_IPU_CODE , PIL_SECT_CODE , PIL_SECT_SHT_DESC , PIL_ROW_NUM ,

PIL_CALC_GROUP , PIL_LIMIT_AMT )

VALUES

( GIN_WEB_PIL_CODE_SEQ .NEXTVAL, v_ipu_code , v_sect_code , v_sect_desc , 1 , 1 , v_suminsured );

EXCEPTION

WHEN OTHERS THEN

RAISE_ERROR ( 'Error insert section records..' );

END;

BEGIN

SELECT TO_NUMBER(TO_CHAR(SYSDATE, 'YY' )) ||TQC_CLNT_CODE_SEQ .NEXTVAL INTO v_prp_code FROM DUAL ;

INSERT INTO TQC_CLIENTS

( CLNT_CODE , CLNT_PIN ,

CLNT_SHT_DESC , CLNT_POSTAL_ADDRS ,

--PRP_COUNTRY,

CLNT_OTHER_NAMES ,

CLNT_NAME , CLNT_ID_REG_NO ,

CLNT_WEF , -- PRP_DONE_BY,

--PRP_TOWN,

CLNT_ZIP_CODE ,

CLNT_TEL , CLNT_TEL2 , CLNT_FAX ,

CLNT_EMAIL_ADDRS )

VALUES( v_prp_code ,NULL,

SUBSTR( v_client_name , 1 , 7 ) ||v_prp_code ,NULL,

-- NVL(PSC_COUNTRY,'KENYA'),

NULL,

v_client_name ,NULL,

TRUNC(SYSDATE), --v_user,

--PSC_TOWN,

NULL,

V_TEL , NULL, NULL,

v_email );



UPDATE GIN_WEB_POLICIES SET POL_PRP_CODE = v_prp_code WHERE POL_ID = Vpol_id ;

UPDATE GIN_WEB_RISKS SET IPU_PRP_CODE = v_prp_code WHERE IPU_POL_ID = Vpol_id ;

COMMIT;



EXCEPTION

WHEN OTHERS THEN

RAISE_ERROR ( 'Error creating the client..' );

END;

BEGIN

Gin_Stp_Pkg . PROCESS_POLICY ( Vpol_id ,

'WEB' ,

v_pol_batch_no );

EXCEPTION

WHEN OTHERS THEN

RAISE_ERROR ( 'Error creating policy..' );

END ;



BEGIN

SELECT 'Insured: ' ||v_client_name|| chr( 13 ) ||

'Vehicle: ' ||v_make|| ' - ' ||v_reg_id|| chr( 13 ) ||

'Sum Assured: ' ||v_suminsured|| chr( 13 ) ||

'Premium: ' || POL_TOT_ENDOS_DIFF_AMT || chr( 13 ) ||

'Please MPESA to account 678999 and forward the confirmation SMS to *1233*4566#'

INTO v_rtntext

FROM GIN_POLICIES

WHERE POL_BATCH_NO = v_pol_batch_no ;

EXCEPTION

WHEN OTHERS THEN

RAISE_ERROR ( 'Error composing SMS message' );

END;





BEGIN

DELETE GIN_WEB_POLICIES WHERE POL_ID = Vpol_id ;

DELETE GIN_WEB_RISKS WHERE IPU_POL_ID = Vpol_id ;

DELETE GIN_WEB_RISK_SECTIONS WHERE PIL_IPU_CODE IN (SELECT IPU_CODE FROM GIN_WEB_RISKS WHERE IPU_POL_ID = Vpol_id );

DELETE TQC_WEB_CLIENTS WHERE WCLNT_POL_ID = Vpol_id ;

NULL;

EXCEPTION

WHEN OTHERS THEN

RAISE_ERROR ( 'Error deleting temporary data..' );

END;

COMMIT;

--v_rtntext := 'DONE';

RETURN( v_rtntext );



END MOBILE_UW_PKG ; */