-- 04_save_exceptions.sql
-- A FORALL stops on the first error by default, so one bad row aborts the whole
-- batch. SAVE EXCEPTIONS lets the batch finish and collects the failures in
-- SQL%BULK_EXCEPTIONS, so you can log the bad rows by index and reason and still
-- load all the good ones.
--
-- To see it fire, this script shrinks the payments.amount column so a few large
-- staging amounts overflow it. Run 00_setup.sql first.

SET SERVEROUTPUT ON

-- Make some rows fail: narrow the target column so big amounts won't fit.
BEGIN
  EXECUTE IMMEDIATE 'DELETE FROM payments';
  EXECUTE IMMEDIATE 'ALTER TABLE payments MODIFY (amount NUMBER(6, 2))';  -- max 9999.99
END;
/

DECLARE
  CURSOR c IS SELECT id, amount FROM staging_payments;

  TYPE t_ids  IS TABLE OF staging_payments.id%TYPE;
  TYPE t_amts IS TABLE OF staging_payments.amount%TYPE;

  v_ids    t_ids;
  v_amts   t_amts;
  v_failed PLS_INTEGER := 0;

  dml_errors EXCEPTION;
  PRAGMA EXCEPTION_INIT(dml_errors, -24381);   -- raised when SAVE EXCEPTIONS caught errors
BEGIN
  OPEN c;
  LOOP
    FETCH c BULK COLLECT INTO v_ids, v_amts LIMIT 5000;
    EXIT WHEN v_ids.COUNT = 0;

    BEGIN
      FORALL i IN 1 .. v_ids.COUNT SAVE EXCEPTIONS
        INSERT INTO payments (id, amount, loaded_at)
        VALUES (v_ids(i), v_amts(i), SYSDATE);
    EXCEPTION
      WHEN dml_errors THEN
        FOR e IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
          v_failed := v_failed + 1;
          IF v_failed <= 5 THEN     -- show only the first few
            DBMS_OUTPUT.PUT_LINE(
              'batch row ' || SQL%BULK_EXCEPTIONS(e).ERROR_INDEX ||
              ' failed: ' || SQLERRM(-SQL%BULK_EXCEPTIONS(e).ERROR_CODE));
          END IF;
        END LOOP;
    END;

    COMMIT;
  END LOOP;
  CLOSE c;

  DBMS_OUTPUT.PUT_LINE('total failed rows: ' || v_failed);
END;
/

SELECT COUNT(*) AS loaded_ok FROM payments;

-- put the column back
ALTER TABLE payments MODIFY (amount NUMBER(12, 2));
