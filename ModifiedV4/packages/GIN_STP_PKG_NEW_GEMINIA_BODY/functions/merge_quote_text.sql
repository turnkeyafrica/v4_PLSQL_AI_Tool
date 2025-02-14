FUNCTION merge_quote_text (v_quote_code IN NUMBER, v_raw_txt IN VARCHAR2)
        RETURN VARCHAR2
    IS
        v_text   VARCHAR2 (4000);
    BEGIN
        v_text :=
            tqc_memo_web_pkg.process_gis_pol_memo (v_quote_code,
                                                   NULL,
                                                   NULL,
                                                   v_raw_txt,
                                                   'Q');
        RETURN (v_text);
    END;