-- 03_bulk_collect_forall.sql
-- Both sides together: BULK COLLECT to read in batches, FORALL to write each
-- batch in a single statement instead of looping in PL/SQL. This does exactly
-- what 01 does -- read staging rows, insert them into payments -- but with a
-- handful of context switches per batch instead of one per row. On a large
-- table this is routinely the difference between minutes and seconds.
--
-- Run 00_setup.sql first.  SET TIMING ON to compare against 01.

SET TIMING ON

DECLARE
  CURSOR c IS SELECT id, amount FROM staging_payments;

  TYPE t_ids  IS TABLE OF staging_payments.id%TYPE;
  TYPE t_amts IS TABLE OF staging_payments.amount%TYPE;

  v_ids  t_ids;
  v_amts t_amts;
BEGIN
  DELETE FROM payments;

  OPEN c;
  LOOP
    FETCH c BULK COLLECT INTO v_ids, v_amts LIMIT 5000;
    EXIT WHEN v_ids.COUNT = 0;

    FORALL i IN 1 .. v_ids.COUNT
      INSERT INTO payments (id, amount, loaded_at)
      VALUES (v_ids(i), v_amts(i), SYSDATE);

    COMMIT;   -- commit per batch, not per row
  END LOOP;
  CLOSE c;
END;
/

SELECT COUNT(*) AS payments_rows FROM payments;
