PROCEDURE populate_endos_rsk_dtls (
        v_old_batch_no       IN     NUMBER,
        v_trans_type         IN     VARCHAR2,
        v_new_batch_no       IN     NUMBER,
        v_old_ipu_code       IN     NUMBER,
        v_ipu_add_edit       IN     VARCHAR2,
        v_new_ipu_code          OUT NUMBER,
        v_action_type        IN     VARCHAR2,
        --S Suspend, C Cancel RT Reinstate R Revise
        v_del_date           IN     DATE DEFAULT NULL,
        v_susp_reinst_type   IN     VARCHAR2 DEFAULT 'PREM',
        -- Reinstate by refund premium (PREM) or Extending days (DAYS)
        v_rcpt_amt           IN     NUMBER DEFAULT NULL,
        -- cash basis