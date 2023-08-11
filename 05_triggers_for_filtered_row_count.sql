-- Query to find the total number of rows for a group:
--
--   SELECT count(uid) FROM example WHERE gid = 'g1';
--
-- This uses a table scan and incurs 4 row reads (1 for each row):
EXPLAIN QUERY PLAN
    SELECT count(uid) FROM example WHERE gid = 'g1';
-- Result: "SCAN example"

-- Add the following table and triggers together:
BEGIN TRANSACTION;

-- Table to hold unique gid counts in the example table:
DROP TABLE IF EXISTS example_gid_counts;
CREATE TABLE example_gid_counts (
    gid TEXT UNIQUE NOT NULL,
    row_count INTEGER NOT NULL
);

-- Query to populate the table with initial counts:
INSERT INTO example_gid_counts
    SELECT gid, count(gid) AS row_count
    FROM example
    GROUP BY gid;

-- Trigger to insert or increment the group row count when rows are inserted into example:
DROP TRIGGER IF EXISTS insert_row_count_group_example;
CREATE TRIGGER insert_row_count_group_example
AFTER INSERT ON example
FOR EACH ROW
BEGIN
    INSERT INTO example_gid_counts
    VALUES (NEW.gid, 1)
    ON CONFLICT (gid) DO
    UPDATE SET row_count = row_count + 1;
END;

-- Trigger to update group row counts when a row gid is changed:
DROP TRIGGER IF EXISTS update_row_count_group_example;
CREATE TRIGGER update_row_count_group_example
AFTER UPDATE ON example
FOR EACH ROW WHEN NEW.gid != OLD.gid
BEGIN
    UPDATE example_gid_counts
    SET row_count = row_count + 1
    WHERE gid = NEW.gid;
    UPDATE example_gid_counts
    SET row_count = row_count - 1
    WHERE gid = OLD.gid;
END;

-- Trigger to decrement the group row count when rows are deleted from example:
DROP TRIGGER IF EXISTS delete_row_count_group_example;
CREATE TRIGGER delete_row_count_group_example
AFTER DELETE ON example
FOR EACH ROW
BEGIN
    UPDATE example_gid_counts
    SET row_count = row_count - 1
    WHERE gid = OLD.gid;
    -- Also prune group rows when they reach 0
    DELETE FROM example_gid_counts
    WHERE gid = OLD.gid AND row_count = 0;
END;

COMMIT;

-- Now, this query counts numbers of uids per gid with just 1 row read:
EXPLAIN QUERY PLAN
    SELECT row_count FROM example_gid_counts WHERE gid = 'g1';
-- Result: "--SEARCH example_gid_counts USING INDEX sqlite_autoindex_example_gid_counts_1 (gid=?)"
