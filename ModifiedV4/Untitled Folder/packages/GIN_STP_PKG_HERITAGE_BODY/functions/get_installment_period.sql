function get_installment_period(v_installment_def in VARCHAR2, v_no_of_endos in NUMBER,v_value_type in VARCHAR2 default 'C') return  NUMBER
   is
   v_installment_perct number;
   begin
   ---raise_error('v_installment_def='||v_installment_def||'v_no_of_endos='||v_no_of_endos||'v_installment_perct='||v_installment_perct);
      IF v_value_type='C' THEN
       select column_value into v_installment_perct   from(
                    select rownum count,x.* from table(convertstringtoarray(v_installment_def))  x)a 
                      where a.count=v_no_of_endos;   
      ELSIF v_value_type='E' THEN
      select  SUM(column_value)  INTO v_installment_perct  from table(convertstringtoarray(v_installment_def)) 
                      WHERE ROWNUM<=v_no_of_endos;
      END IF;
    
   return v_installment_perct;
                     
   end;