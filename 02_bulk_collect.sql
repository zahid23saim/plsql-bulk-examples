-- 02_bulk_collect.sql
-- Fetch side only: pull rows in batches of 5000 with BULK COLLECT ... LIMIT
-- instead of one row per round trip. The LIMIT clause is the important part --
-- without it you load the whole result set into PGA at once, which does not
-- scale. This script only fetches (and counts) so you can see the read pattern
-- on its own; 03 adds the batched write.
--
-- Run 00_setup.sql first.

SET SERVEROUTPUT ON

DECLARE
  CURSOR c IS SELECT id, amount FROM staging_payments;

  TYPE t_ids  IS TABLE OF staging_payments.id%TYPE;
  TYPE t_amts IS TABLE OF staging_payments.amount%TYPE;

  v_ids     t_ids;
  v_amts    t_amts;
  v_batches PLS_INTEGER := 0;
  v_rows    PLS_INTEGER := 0;
BEGIN
  OPEN c;
  LOOP
    FETCH c BULK COLLECT INTO v_ids, v_amts LIMIT 5000;
    EXIT WHEN v_ids.COUNT = 0;      -- placed after the fetch so the last,
                                    -- partial batch is still processed
    v_batches := v_batches + 1;
    v_rows    := v_rows + v_ids.COUNT;
  END LOOP;
  CLOSE c;

  DBMS_OUTPUT.PUT_LINE('fetched ' || v_rows || ' rows in ' || v_batches || ' batches');
END;
/
