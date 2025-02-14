FUNCTION contrad_trans_type (v_batch_no IN NUMBER)
        RETURN VARCHAR2
    IS
        v_pol_status   VARCHAR2 (10);
    BEGIN
        -- raise_error('nnn');
        SELECT DECODE (prev.pol_policy_status,
                       'EN', 'RC',
                       prev.pol_policy_status)
          INTO v_pol_status
          FROM gin_policies co, gin_policies prev
         WHERE     co.pol_prev_batch_no = prev.pol_batch_no
               AND co.pol_batch_no = v_batch_no;

        RETURN (v_pol_status);
    END;