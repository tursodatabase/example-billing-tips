-- Query to find uid with the highest score:
--
--   SELECT uid, max(score) AS score FROM example;
--
-- This uses a table scan and incurs 4 row reads (1 for each row),
-- even though only 1 row is needed:
EXPLAIN QUERY PLAN
    SELECT uid, max(score) AS score FROM example;
-- Result: "SCAN example"

-- Add this index:
DROP INDEX IF EXISTS example_score;
CREATE INDEX example_score ON example (score);

-- The query now uses the index and incurs 1 row read:
EXPLAIN QUERY PLAN
    SELECT uid, max(score) AS score FROM example;
-- Result: "SEARCH example USING INDEX example_score"

-- The index also helps with min(score) and order with limit.
--
-- This query incurs 1 row read instead of 4:
EXPLAIN QUERY PLAN
    SELECT uid, min(score) AS score FROM example;
-- Result: "SEARCH example USING INDEX example_score"

-- And this query incurs 2 rows read instead of 4:
EXPLAIN QUERY PLAN
    SELECT uid, score FROM example ORDER BY score DESC LIMIT 2;
-- Result: "SCAN example USING INDEX example_score"
