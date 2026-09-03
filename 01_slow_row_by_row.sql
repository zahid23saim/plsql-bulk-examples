-- 01_slow_row_by_row.sql
-- The naive version: a cursor FOR loop that inserts one row at a time.
-- It is correct and readable, and on a large table it is slow, because every
-- INSERT is a separate context switch between the PL/SQL and SQL engines.
--
-- Run 00_setup.sql first. Turn on timing to see the cost:  SET TIMING ON

SET TIMING ON

BEGIN
  DELETE FROM payments;

  FOR rec IN (SELECT id, amount FROM staging_payments) LOOP
    INSERT INTO payments (id, amount, loaded_at)
    VALUES (rec.id, rec.amount, SYSDATE);
  END LOOP;

  COMMIT;
END;
/

SELECT COUNT(*) AS payments_rows FROM payments;
