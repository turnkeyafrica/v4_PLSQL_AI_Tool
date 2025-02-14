FUNCTION  get_policy_facre(v_batch_no in number) return NUMBER 
    IS
   
    v_count NUMBER;
BEGIN
        BEGIN

              SELECT COUNT (1)
              INTO v_count
              FROM gin_policies
             WHERE pol_policy_type = 'F' AND pol_batch_no = v_batch_no;
 
            RETURN UPPER(v_count);
        EXCEPTION
                WHEN OTHERS THEN 
                    RAISE_APPLICATION_ERROR(-20001,'This policy is not a Facre business....');
                
        END;