-- 00_setup.sql
-- Create the two tables the examples use and seed the staging table with
-- enough rows that the difference between row-by-row and bulk processing is
-- actually visible. Safe to re-run: it drops the tables first.

BEGIN
  FOR t IN (SELECT table_name FROM user_tables
            WHERE table_name IN ('STAGING_PAYMENTS', 'PAYMENTS')) LOOP
    EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' PURGE';
  END LOOP;
END;
/

CREATE TABLE staging_payments (
  id      NUMBER        NOT NULL,
  amount  NUMBER(12, 2) NOT NULL
);

CREATE TABLE payments (
  id         NUMBER        NOT NULL,
  amount     NUMBER(12, 2) NOT NULL,
  loaded_at  DATE          NOT NULL
);

-- Seed 200,000 staging rows with random valid amounts. (Script 04 creates its
-- own failures by narrowing the target column, so nothing bad is planted here.)
INSERT INTO staging_payments (id, amount)
SELECT LEVEL, ROUND(DBMS_RANDOM.VALUE(1, 100000), 2)
FROM   dual
CONNECT BY LEVEL <= 200000;

COMMIT;

SELECT COUNT(*) AS staging_rows FROM staging_payments;
