FUNCTION get_prev_tran_type (v_batchno        IN     NUMBER,
                                 v_prevbatch_no      OUT VARCHAR2)
        RETURN VARCHAR2
    IS
        v_max_extensions   NUMBER := 1;
        v_batch_no         NUMBER := 2010533566;
        v_prev_batch_no    NUMBER;
        v_maxed            VARCHAR2 (1) := 'N';
        v_num              NUMBER;
        v_trans_type       VARCHAR2 (5);
        v_cover_days       NUMBER;

        FUNCTION get_prev_tran_type (v_batch_no        IN     NUMBER,
                                     v_prev_batch_no      OUT VARCHAR2)
            RETURN VARCHAR2
        IS
            v_retval   VARCHAR2 (5);
            v_btchno   NUMBER;
        BEGIN
            SELECT pol_policy_status, pol_prev_batch_no
              INTO v_retval, v_btchno
              FROM gin_policies
             WHERE pol_batch_no = v_batch_no;

            IF v_retval = 'CO'
            THEN
                SELECT pol_policy_status, pol_prev_batch_no
                  INTO v_retval, v_prev_batch_no
                  FROM gin_policies
                 WHERE pol_batch_no = v_btchno;
            ELSE
                v_prev_batch_no := v_btchno;
            END IF;

            RETURN (v_retval);
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                v_retval := 'NONE';
            WHEN OTHERS
            THEN
                raise_error ('Error getting previous transaction type..');
        END;