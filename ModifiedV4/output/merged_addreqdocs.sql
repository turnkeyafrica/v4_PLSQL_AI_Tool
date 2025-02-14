```sql
PROCEDURE addreqdocs (v_pol_batch_no IN NUMBER, v_trans_type IN VARCHAR2)
IS
    v_cnt   NUMBER;

    CURSOR dispatchdocs IS
        SELECT *
        FROM gin_dispatch_docs
        WHERE dd_doc_lvl = v_trans_type;
BEGIN
    SELECT COUNT (1)
    INTO v_cnt
    FROM gin_uw_pol_docs
    WHERE upd_pol_batch_no = v_pol_batch_no;

    IF NVL (v_cnt, 0) > 0
    THEN
        FOR dispatchdocs_rec IN dispatchdocs
        LOOP
            INSERT INTO gin_uw_pol_docs (upd_code,
                                        upd_dd_code,
                                        upd_dispatched,
                                        upd_pol_batch_no)
                VALUES (gin_upd_code_seq.NEXTVAL,
                        dispatchdocs_rec.dd_code,
                        'N',
                        v_pol_batch_no);
        END LOOP;
    END IF;
END;

```