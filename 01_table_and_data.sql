-- Table and data for all of the examples in this repo

DROP TABLE IF EXISTS example;
CREATE TABLE example (
    uid TEXT NOT NULL,
    gid TEXT NOT NULL,
    score INTEGER NOT NULL
);
INSERT INTO example VALUES ('a', 'g1', 10);
INSERT INTO example VALUES ('b', 'g1', 15);
INSERT INTO example VALUES ('c', 'g2', 5);
INSERT INTO example VALUES ('d', 'g2', 10);
