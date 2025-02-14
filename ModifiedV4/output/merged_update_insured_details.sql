```sql
PROCEDURE update_insured_details (v_polin_no IN NUMBER, v_pip_code IN NUMBER)
IS
BEGIN
  UPDATE gin_policy_insureds
  SET polin_interested_parties = NVL (v_pip_code, polin_interested_parties)
  WHERE polin_code = v_polin_no;
EXCEPTION
  WHEN OTHERS
  THEN
    raise_error ('error updating insured details....');
END;
```