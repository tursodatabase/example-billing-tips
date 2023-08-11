-- Query to find the number of rows:
--
--   SELECT count(uid) FROM example;
--
-- This uses a table scan and incurs 4 row reads (1 for each row):
EXPLAIN QUERY PLAN
    SELECT count(*) FROM example;
-- Result: "SCAN example"

-- Add the following table and triggers together:
BEGIN TRANSACTION;

-- Table to hold row counts per table:
DROP TABLE IF EXISTS table_row_counts;
CREATE TABLE table_row_counts (
    table_name TEXT UNIQUE NOT NULL,
    row_count INTEGER NOT NULL
);

-- Query to populate the table with initial counts:
INSERT INTO table_row_counts
    SELECT "example" AS table_name, count(uid) AS row_count
    FROM example;

-- Trigger to increment the row count when rows are inserted into example:
DROP TRIGGER IF EXISTS insert_row_count_example;
CREATE TRIGGER insert_row_count_example
AFTER INSERT ON example
FOR EACH ROW
BEGIN
    UPDATE table_row_counts
    SET row_count = row_count + 1
    WHERE table_name = 'example';
END;

-- Trigger to decrement the row count when rows are deleted from example:
DROP TRIGGER IF EXISTS delete_row_count_example;
CREATE TRIGGER delete_row_count_example
AFTER DELETE ON example
FOR EACH ROW
BEGIN
    UPDATE table_row_counts
    SET row_count = row_count - 1
    WHERE table_name = 'example';
END;

COMMIT;

-- Now, this query finds the number of rows with just 1 read:
EXPLAIN QUERY PLAN
    SELECT row_count from table_row_counts WHERE table_name = 'example';
-- Result: "SEARCH table_row_counts USING INDEX sqlite_autoindex_table_row_counts_1 (table_name=?)"
