PROCEDURE reinstate_section (
   v_pol_batch_no            NUMBER,
   v_ipu_code       IN       NUMBER,
   v_date                    DATE,
   v_user           IN       VARCHAR2,
   v_rein_amt       IN       NUMBER,
   v_dr_no          OUT      NUMBER
)
IS
   v_cnt              NUMBER;
   v_new_ipu_code     NUMBER;
   v_new_polin_code   NUMBER;
   v_exp_flag         VARCHAR2 (2);
   v_open_cover       VARCHAR2 (2);
   v_trans_no         NUMBER;
   v_end_no           VARCHAR2 (45);
   v_batchno          NUMBER;
   v_prev_batch_no    NUMBER;
   v_web_result       VARCHAR2 (50);
   vexceptions        VARCHAR2 (50);
   v_pol_rec          web_pol_tab    := web_pol_tab ();
   r_no               NUMBER;
   v_status           VARCHAR2 (100);

   CURSOR pol_cur
   IS
      SELECT *
        FROM gin_policies
       WHERE pol_batch_no = v_pol_batch_no;

   CURSOR new_pol_cur (v_batchno NUMBER)
   IS
      SELECT *
        FROM gin_policies
       WHERE pol_batch_no = v_batchno;

   CURSOR exceptions_cur (v_batchno NUMBER)
   IS
      SELECT *
        FROM gin_policy_exceptions
       WHERE gpe_pol_batch_no = v_batchno;

   v_pol_no           VARCHAR2 (40);
   v_new_pol_batch    NUMBER;
--AND NVL(PIL_EXPIRED,'N') = 'N';
 --AND PIL_SECT_CODE=v_sect_code;
BEGIN
   -- RAISE_APPLICATION_ERROR(-20001,'HERE');
   SELECT COUNT (1)
     INTO v_cnt
     FROM gin_policies
    WHERE pol_policy_no = (SELECT pol_policy_no
                             FROM gin_policies
                            WHERE pol_batch_no = v_pol_batch_no)
      AND pol_authosrised = 'N';

   SELECT pol_batch_no
     INTO v_prev_batch_no
     FROM gin_policies
    WHERE pol_policy_no = (SELECT pol_policy_no
                             FROM gin_policies
                            WHERE pol_batch_no = v_pol_batch_no)
      AND pol_current_status = 'A';

   IF v_prev_batch_no IS NULL
   THEN
      raise_error ('An error Occured while reinstating .the policy..');
   END IF;

   IF NVL (v_cnt, 0) > 0
   THEN
      raise_error
         ('There are unauthorised transactions on this policy,Reinstatement could not be completed'
         );
   END IF;

   FOR pol IN pol_cur
   LOOP
      r_no := 1;
      v_pol_rec := web_pol_tab ();
      v_pol_rec.EXTEND (r_no);
      v_pol_rec (r_no) :=
         web_pol_rec (NULL,
                      NULL,                                     --POL_ENDOS_NO
                      v_prev_batch_no,
                      NULL,                          -- POL_AGNT_AGENT_CODE -,
                      NULL,                    --          POL_AGNT_SHT_DESC ,
                      NULL,                        --          POL_BIND_CODE ,
                      NULL,                           --          POL_WEF_DT ,
                      NULL,                           --          POL_WET_DT ,
                      NULL,                           --          POL_STATUS ,
                      NULL,                         --          POL_CUR_CODE ,
                      NULL,                      --          POL_POLICY_TYPE ,
                      NULL,                         --          POL_BRN_CODE ,
                      NULL,                         --          POL_CUR_RATE ,
                      NULL,                      --          POL_COINSURANCE ,
                      NULL,                  --          POL_COINSURE_LEADER ,
                      NULL,                       --          POL_CUR_SYMBOL ,
                      NULL,                     --          POL_BRN_SHT_DESC ,
                      NULL,                         --          POL_PRP_CODE ,
                      NULL,                     --          POL_PRP_SHT_DESC ,
                      NULL,                         --          POL_PRO_CODE ,
                      NULL,                         --          POL_YOUR_REF ,
                      NULL,         --          POL_PROP_HOLDING_CO_PRP_CODE ,
                      NULL,                  --          POL_OTH_INT_PARTIES ,
                      NULL,                     --          POL_PRO_SHT_DESC ,
                      NULL,                    --          POL_BINDER_POLICY ,
                      NULL,                --          POL_COINSURANCE_SHARE ,
                      NULL,               --          POL_RI_AGENT_COMM_RATE ,
                      NULL,                 --          POL_RI_AGNT_SHT_DESC ,
                      NULL,               --          POL_RI_AGNT_AGENT_CODE ,
                      NULL,                       --          POL_POLICY_DOC ,
                      NULL,               --          POL_COMMISSION_ALLOWED ,
                      NULL,                        --          POL_RENEWABLE ,
                      NULL,                      --          POL_SHORT_PERIOD,
                      'EN',
                      NULL,                      --          POL_ACTION_TYPE ,
                      pol.pol_policy_no,       --          POL_GIS_POLICY_NO ,
                      SYSDATE,
                      NULL,                            -- POL_EXTEND_TO_DATE ,
                      'A',
                      NULL,                 --          POL_INTERNAL_COMMENTS,
                      NULL,                       --          POL_INTRO_CODE ,
                      NULL,                           --          POL_SOURCE ,
                      NULL,               --          POL_CHEQUE_REQUISITION ,
                      NULL,                         --          POL_COIN_FEE ,
                      NULL,                        --          POL_BDIV_CODE ,
                      NULL,                   --          POL_CURR_RATE_TYPE ,
                      NULL,                        --          POL_PMOD_CODE ,
                      NULL,                        --          POL_SERIAL_NO ,
                      NULL,                       --          POL_COIN_GROSS ,
                      NULL,                     --          POL_SUB_AGN_CODE ,
                      NULL,                --          POL_SUB_AGNT_SHT_DESC ,
                      NULL,             --          POL_CLIENT_POLICY_NUMBER ,
                      NULL,                         --          POL_AGA_CODE ,
                      NULL,                        --          POL_CLNA_CODE ,
                      NULL,                     --          POL_SUB_AGA_CODE ,
                      NULL,             --          POL_COIN_LEADER_COMBINED ,
                      NULL,                 --          POL_DECLARATION_TYPE ,
                      NULL,                  --          POL_MED_POLICY_TYPE ,
                      NULL,                  --          POL_FREQ_OF_PAYMENT ,
                      NULL,                    --          POL_FEE_ADMISSIBLE,
                      NULL,                       --          QUOT_CLNT_TYPE ,
                      NULL,                         --          QUOT_PRS_CODE,
                      NULL,                    --          POL_MKTR_AGN_CODE ,
                      'N',
                      NULL,                               --POL_OLD_BATCH_NO ,
                      NULL,                                --POL_POP_TAXES   ,
                      'N',
                      NULL,                           --          POL_LOADED ,
                      NULL,                          --          POL_COMMENTS,
                      NULL,            --          POL_BUSSINESS_GROWTH_TYPE ,
                      NULL,                        --          POL_SUBAGENT  ,
                      NULL,                  --          POL_IPF_NOF_INSTALS ,
                      NULL,                         --          POL_COAGENT  ,
                      NULL,                 --          POL_COAGENT_MAIN_PCT ,
                      NULL,                   --          POL_AGN_DISCOUNTED ,
                      NULL,                   --          POL_AGN_DISC_TYPE  ,
                      NULL,                     --          POL_AGN_DISCOUNT ,
                      NULL,                    --          POL_PIP_PF_CODE   ,
                      NULL,                   --          POL_NO_INSTALLMENT ,
                      NULL,
                      NULL,               --          POL_IPF_DOWN_PYMT_TYPE ,
                      NULL,                --          POL_IPF_DOWN_PYMT_AMT ,
                      NULL,                  --          POL_IPF_INTEREST_RATE
                      NULL,
                      NULL,
                      NULL,
                      NULL,                                  --POL OPEN POLICY
                      NULL,
                      NULL,
                      NULL,
                      NULL,                              --POL_INTERFACE_TYPE,
                      NULL,                      --POL_CHECKOFF_AGNT_SHT_DESC,
                      NULL,                          --POL_CHECKOFF_AGNT_CODE,
                      NULL,                          --POL_PYMT_FACI_AGNT_CODE
                      NULL,                                --POL_OLD_POLICY_NO
                      NULL,                                    --POL_OLD_AGENT
                      NULL,                                  --POL_INSTLMT_DAY
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
                      pol.pol_admin_fee_allowed,
                      pol.pol_cashback_appl,
                      pol.pol_uw_only,
                      pol.pol_debiting_type
                     );
   END LOOP;

   BEGIN
      gin_policies_prc (v_pol_no, v_pol_rec, NULL, v_new_pol_batch, v_user);

      UPDATE gin_policies
         SET pol_commission_allowed = 'N'
       WHERE pol_batch_no = v_new_pol_batch;

--         FOR i IN new_pol_cur (v_new_pol_batch)
--         LOOP
--            BEGIN
--               pop_taxes (i.pol_policy_no,
--                          i.pol_ren_endos_no,
--                          v_new_pol_batch,
--                          i.pol_pro_code,
--                          i.pol_binder_policy,
--                          'RE'
--                         );
--            EXCEPTION
--               WHEN OTHERS
--               THEN
--                  raise_error ('ERROR POPULATING TAXES..');
--            END;