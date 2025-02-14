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