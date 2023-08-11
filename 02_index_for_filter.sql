-- Query to look up a single UID:
--
--   SELECT * FROM example WHERE UID = 'a';
--
-- This uses a table scan and incurs 4 row reads (1 for each row):
EXPLAIN QUERY PLAN
    SELECT * FROM example WHERE UID = 'a';
-- Result: "SCAN example"

-- Add this index:
DROP INDEX IF EXISTS example_uid;
CREATE UNIQUE INDEX example_uid
ON example (uid);

-- The query now uses the index and incurs 1 row read:
EXPLAIN QUERY PLAN
    SELECT * FROM example WHERE uid = 'a';
-- Result: "SEARCH example USING INDEX example_uid (uid=?)"
