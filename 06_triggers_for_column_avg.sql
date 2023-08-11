-- Query to find the average value of a column:
--
--   SELECT avg(score) FROM example;
--
-- This uses a table scan and incurs 4 row reads (1 for each row):
EXPLAIN QUERY PLAN
    SELECT avg(score) FROM example;
-- Result: "SCAN example"

-- Add the following table and triggers together:
BEGIN TRANSACTION;

-- Table to hold running stats:
DROP TABLE IF EXISTS example_score_avg;
CREATE TABLE example_score_avg (
    avg REAL NOT NULL,
    sum INTEGER NOT NULL,
    count INTEGER NOT NULL
);

-- Trigger to ensure that example_score_avg only contains 1 row:
DROP TRIGGER IF EXISTS example_score_avg_one_row;
CREATE TRIGGER example_score_avg_one_row
BEFORE INSERT ON example_score_avg
WHEN (SELECT count(*) FROM example_score_avg) >= 1
BEGIN
    SELECT RAISE(FAIL, 'example_score_avg may contain only one row');
END;

-- Query to populate the table with initial average:
INSERT INTO example_score_avg
    SELECT avg(score) AS avg, sum(score) as sum, count(score) as count
    FROM example;

-- Trigger to update average when rows are inserted into example:
DROP TRIGGER IF EXISTS insert_avg_example;
CREATE TRIGGER insert_avg_example
AFTER INSERT ON example
FOR EACH ROW
BEGIN
    UPDATE example_score_avg
    SET
        sum = sum + NEW.score,
        count = count + 1,
        avg = CAST((sum + NEW.score) as REAL) / CAST((count + 1) as REAL);
END;

-- Trigger to update average when rows are updated in example:
DROP TRIGGER IF EXISTS update_avg_example;
CREATE TRIGGER update_avg_example
AFTER UPDATE ON example
FOR EACH ROW WHEN NEW.score != OLD.score
BEGIN
    UPDATE example_score_avg
    SET
        sum = sum + NEW.score - OLD.score,
        avg = CAST((sum + NEW.score - OLD.score) as REAL) / CAST(count as REAL);
END;

-- Trigger to update average when rows are deleted from example:
DROP TRIGGER IF EXISTS delete_avg_example;
CREATE TRIGGER delete_avg_example
AFTER DELETE ON example
FOR EACH ROW
BEGIN
    UPDATE example_score_avg
    SET
        sum = sum - OLD.score,
        count = count - 1,
        avg = CAST((sum - OLD.score) as REAL) / CAST((count - 1) as REAL);
END;

COMMIT;

-- Now, this query gets the average score with just 1 row read
-- (since there is only ever 1 row in the table):
EXPLAIN QUERY PLAN
    SELECT avg FROM example_score_avg;


-- You can use the following commands to verify that the averages are staying up to date.
-- They should generate the exact same result:
-- SELECT avg FROM example_score_avg;
-- SELECT avg(score) AS avg FROM example;
