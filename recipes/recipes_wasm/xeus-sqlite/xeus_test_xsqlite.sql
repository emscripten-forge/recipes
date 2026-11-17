%CREATE test.db

-- SQL has no assert, so each check inserts a condition into a table with a CHECK constraint, which
-- fails if the condition is false. NOT NULL is needed as a CHECK constraint passes if it is NULL.
CREATE TEMP TABLE assertions (ok INTEGER NOT NULL CHECK (ok));

CREATE TABLE players (name TEXT, score INTEGER);
INSERT INTO players VALUES ('Alice', 10), ('Bob', 20), ('Carol', 30);
SELECT name, score FROM players ORDER BY score DESC;

INSERT INTO assertions VALUES ((SELECT COUNT(*) FROM players) = 3);
INSERT INTO assertions VALUES ((SELECT SUM(score) FROM players) = 60);
INSERT INTO assertions VALUES ((SELECT name FROM players ORDER BY score DESC LIMIT 1) = 'Carol');
