FUNCTION merge_claims_text (v_claim IN VARCHAR2, v_raw_txt IN VARCHAR2)
        RETURN VARCHAR2
    IS
        v_text   VARCHAR2 (4000);
    BEGIN
        --RAISE_ERROR('v_claim '||v_claim||'Raw Text '||v_raw_txt);
        v_text :=
            tqc_memo_web_pkg.process_gis_pol_memo (NULL,
                                                   v_claim,
                                                   NULL,
                                                   v_raw_txt,
                                                   'C');
        RETURN (v_text);
    END;