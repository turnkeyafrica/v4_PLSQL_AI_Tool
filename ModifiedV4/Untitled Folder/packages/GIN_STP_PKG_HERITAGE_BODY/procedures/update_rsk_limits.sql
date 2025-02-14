PROCEDURE update_rsk_limits (
      v_new_ipu_code                IN   NUMBER,
      v_scl_code                    IN   NUMBER,
      v_bind_code                   IN   NUMBER,
      v_sect_code                   IN   NUMBER,
      v_limit                       IN   NUMBER,
      v_row                         IN   NUMBER,
      v_add_edit                    IN   VARCHAR2,
      v_rsk_sect_data               IN   web_sect_tab,
      v_pil_multiplier_rate         IN   NUMBER DEFAULT NULL,
      v_pil_multiplier_div_factor   IN   NUMBER DEFAULT NULL,
      v_trans_type                  IN   VARCHAR2 DEFAULT NULL
   )
   IS
   BEGIN
      --raise_error('v_trans_type '||v_trans_type);
      IF v_trans_type = 'RN'
      THEN
         IF NVL (v_add_edit, 'A') = 'E'
         THEN
            BEGIN
               -- RAISE_ERROR('SUCCESS'||v_new_ipu_code);
                 -- RAISE_ERROR('FREE LIMIT '||v_new_ipu_code||';'||v_rsk_sect_data (1).pil_code||';'||v_rsk_sect_data (1).pil_prem_rate);
               UPDATE gin_ren_policy_insured_limits
                  SET
                      --PIL_SECT_CODE=v_sect_code, PIL_SECT_SHT_DESC=v_sect_sht_desc,
                      pil_limit_amt = v_rsk_sect_data (1).pil_limit_amt,
                      pil_prem_rate = v_rsk_sect_data (1).pil_prem_rate,
--                PIL_SECT_TYPE=v_sect_type,
--                PIL_MIN_PREMIUM=NVL(v_rsk_sect_data(1).PIL_MIN_PREMIUM,v_prr_prem_minimum_amt),
--                PIL_RATE_TYPE=v_prr_rate_type,
--                PIL_RATE_DESC=v_prr_rate_desc,
--                PIL_RATE_DIV_FACT=NVL(v_rsk_sect_data(1).PIL_RATE_DIV_FACT,v_prr_division_factor),
--                PIL_MULTIPLIER_RATE=NVL(v_rsk_sect_data(1).PIL_MULTIPLIER_RATE,v_prr_multiplier_rate),
--                PIL_MULTIPLIER_DIV_FACTOR=NVL(v_rsk_sect_data(1).PIL_MULTIPLIER_DIV_FACTOR,v_prr_multplier_div_fact),
                      pil_row_num = v_rsk_sect_data (1).pil_row_num,
--                PIL_COMPUTE =NVL(v_rsk_sect_data(1).PIL_COMPUTE,'Y'),
--                PIL_DESC=NVL(v_rsk_sect_data(1).PIL_DESC, v_sect_desc),
--                PIL_DUAL_BASIS=NVL(v_rsk_sect_data(1).PIL_DUAL_BASIS,'N'),
                      pil_calc_group =
                                   NVL (v_rsk_sect_data (1).pil_calc_group, 1),
                      pil_multiplier_rate = v_pil_multiplier_rate,
                      pil_multiplier_div_factor = v_pil_multiplier_div_factor
--                PIL_PREM_AMT = (v_rsk_sect_data(1).PIL_PREM_AMT),
--                PIL_COMMENT = v_rsk_sect_data(1).PIL_COMMENT,
--                PIL_DECLARATION_SECTION=NVL(v_rsk_sect_data(1).PIL_DECLARATION_SECTION,'N'),
--                PIL_FREE_LIMIT_AMT=v_rsk_sect_data(1).PIL_FREE_LIMIT_AMT,
--                PIL_LIMIT_PRD=v_rsk_sect_data(1).PIL_LIMIT_PRD,
--                PIL_PRORATA_FULL = NVL(v_rsk_sect_data(1).PIL_PRORATA_FULL, PIL_PRORATA_FULL),
--                PIL_SI_LIMIT_TYPE =NVL(v_rsk_sect_data(1).PIL_SI_LIMIT_TYPE, PIL_SI_LIMIT_TYPE),
--                PIL_SI_RATE  =NVL(v_rsk_sect_data(1).PIL_SI_RATE, PIL_SI_RATE),
--                PIL_COVER_TYPE =NVL(v_rsk_sect_data(1).PIL_COVER_TYPE, PIL_COVER_TYPE)
               WHERE  pil_ipu_code = v_new_ipu_code
                  AND pil_code = v_rsk_sect_data (1).pil_code;
            EXCEPTION
               WHEN OTHERS
               THEN
                  raise_error ('Error updating risk sections..');
            END;