PROCEDURE process_med_risk_prc (
      v_pol_batch_no   IN   NUMBER,
      v_comm_rate      IN   NUMBER,
      v_trans_type     IN   VARCHAR2,
      v_scl1           IN   VARCHAR2,
      v_scl2           IN   VARCHAR2,
      v_scl3           IN   VARCHAR2,
      v_scl4           IN   VARCHAR2,
      v_scl5           IN   VARCHAR2,
      v_scl6           IN   VARCHAR2,
      v_prem1          IN   NUMBER,
      v_prem2          IN   NUMBER,
      v_prem3          IN   NUMBER,
      v_prem4          IN   NUMBER,
      v_prem5          IN   NUMBER,
      v_prem6          IN   NUMBER
   )
   IS
      v_insert          BOOLEAN        := FALSE;
      v_scl_code        NUMBER;
      v_prem            NUMBER (23, 5);
      v_covt_type       VARCHAR2 (30);
      v_covt_code       NUMBER;
      v_si              NUMBER;
      v_rsk_rec         web_risk_tab   := web_risk_tab ();
      v_rsk_sect_data   web_sect_tab   := web_sect_tab ();
      r_no              NUMBER         := 0;
      v_med_scl         VARCHAR2 (10);
      v_scl_desc        VARCHAR2 (50);
      v_date_from       DATE;
      v_date_to         DATE;
      v_prp_code        NUMBER;
      v_med_policy_no   VARCHAR2 (30);
      v_bind_code       NUMBER;
      v_user            VARCHAR2 (30);
      v_new_ipu_code    NUMBER;
      v_sect_code       NUMBER;
   BEGIN
      FOR x IN 1 .. 6
      LOOP
         v_insert := FALSE;

         IF x = 1 AND v_scl1 IS NOT NULL AND NVL (v_prem1, 0) != 0
         THEN
            BEGIN
               SELECT scm_scl_code
                 INTO v_scl_code
                 FROM gin_subclass_mapping
                WHERE scm_mapped_code = v_scl1;
            EXCEPTION
               WHEN OTHERS
               THEN
                  raise_error (   'Error Fetching Sub Class Mapping For '
                               || v_scl1
                              );
            END;