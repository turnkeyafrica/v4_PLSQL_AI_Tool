PROCEDURE populate_pol_risk_services (
   v_ipu_code       IN   NUMBER,
   v_pol_batch_no   IN   NUMBER,
   v_rss_code       IN   NUMBER,
   v_rs_code        IN   NUMBER,
   v_policy_no      IN   VARCHAR2,
   v_endors_no      IN   VARCHAR2
)
IS
   v_cnt    NUMBER;
   v_end_no VARCHAR2(50);
BEGIN
   IF v_endors_no = NULL
   THEN
   SELECT pol_ren_endos_no 
     INTO v_end_no 
     FROM gin_policies 
    WHERE pol_batch_no = v_pol_batch_no;   
   END IF;
   
   BEGIN
      SELECT COUNT (*)
        INTO v_cnt
        FROM gin_policy_risk_services
       WHERE prs_ipu_code = v_ipu_code
         AND prs_rss_code = v_rss_code;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_cnt := 0;
   END;