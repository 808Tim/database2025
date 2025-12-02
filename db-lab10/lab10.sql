-- Task 1

BEGIN;
UPDATE accounts SET balance = balance - 100.00 WHERE name='Alice';
UPDATE accounts SET balance = balance + 100.00 WHERE name='Bob';
COMMIT;

-- Answers Task 1:
-- a) Alice = 900, Bob = 600
-- b) Ensures atomicity: both operations succeed or fail together.
-- c) Without transaction, crash may leave inconsistent balances.

-- Task 2

BEGIN;
UPDATE accounts SET balance = balance - 500.00 WHERE name='Alice';
SELECT * FROM accounts WHERE name='Alice';
ROLLBACK;
SELECT * FROM accounts WHERE name='Alice';

-- Answers Task 2:
-- a) 500
-- b) 1000
-- c) Used to undo incorrect or unsafe operations.

-- Task 3

BEGIN;
UPDATE accounts SET balance = balance - 100.00 WHERE name='Alice';
SAVEPOINT sp1;
UPDATE accounts SET balance = balance + 100.00 WHERE name='Bob';
ROLLBACK TO sp1;
UPDATE accounts SET balance = balance + 100.00 WHERE name='Wally';
COMMIT;

-- Answers Task 3:
-- a) Alice = 900, Bob = 500, Wally = 850
-- b) Bob was credited temporarily but rolled back.
-- c) Savepoints allow partial rollback without restarting a transaction.

-- Task 4

BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT * FROM products WHERE shop='Joe''s Shop';
SELECT * FROM products WHERE shop='Joe''s Shop';
COMMIT;

-- Task 4
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT * FROM products WHERE shop='Joe''s Shop';
SELECT * FROM products WHERE shop='Joe''s Shop';
COMMIT;

-- Answers Task 4:
-- a) Before: Coke, Pepsi. After: Fanta.
-- b) Sees Coke and Pepsi both times.
-- c) READ COMMITTED reads newest committed data; SERIALIZABLE isolates fully.

-- Task 5

BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT MAX(price), MIN(price) FROM products WHERE shop='Joe''s Shop';
SELECT MAX(price), MIN(price) FROM products WHERE shop='Joe''s Shop';
COMMIT;

-- Answers Task 5:
-- a) No.
-- b) Phantom read = new rows appear between scans.
-- c) Prevented by SERIALIZABLE.

-- Task 6

BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT * FROM products WHERE shop='Joe''s Shop';
SELECT * FROM products WHERE shop='Joe''s Shop';
SELECT * FROM products WHERE shop='Joe''s Shop';
COMMIT;

-- Answers Task 6:
-- a) Yes; reads uncommitted data.
-- b) Dirty read = reading uncommitted changes.
-- c) Unsafe; should be avoided.

-- Independent Exercise 1

BEGIN;
DO $$
DECLARE bal DECIMAL;
BEGIN
    SELECT balance INTO bal FROM accounts WHERE name='Bob';
    IF bal >= 200 THEN
        UPDATE accounts SET balance = balance - 200 WHERE name='Bob';
        UPDATE accounts SET balance = balance + 200 WHERE name='Wally';
    ELSE
        RAISE NOTICE 'Insufficient funds';
        ROLLBACK;
        RETURN;
    END IF;
END $$;
COMMIT;

-- Answer IE1:
-- Transfer completes only if Bob has at least 200.

-- Independent Exercise 2

BEGIN;
INSERT INTO products (shop, product, price) VALUES ('Joe''s Shop','Choco',2.00);
SAVEPOINT sp1;
UPDATE products SET price=2.50 WHERE product='Choco';
SAVEPOINT sp2;
DELETE FROM products WHERE product='Choco';
ROLLBACK TO sp1;
COMMIT;

-- Answer IE2:
-- Final table contains: Choco with price 2.00.

-- Independent Exercise 3

-- Terminal 1 READ COMMITTED
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT balance FROM accounts WHERE name='Alice';
UPDATE accounts SET balance = balance - 800 WHERE name='Alice';
COMMIT;

-- Terminal 2 READ COMMITTED
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT balance FROM accounts WHERE name='Alice';
UPDATE accounts SET balance = balance - 800 WHERE name='Alice';
COMMIT;

-- Terminal 1 SERIALIZABLE
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT balance FROM accounts WHERE name='Alice';
UPDATE accounts SET balance = balance - 800 WHERE name='Alice';
COMMIT;

-- Terminal 2 SERIALIZABLE
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT balance FROM accounts WHERE name='Alice';
UPDATE accounts SET balance = balance - 800 WHERE name='Alice';
COMMIT;

-- Answer IE3:
-- READ COMMITTED: allows both withdrawals -> incorrect balance.
-- SERIALIZABLE: second transaction fails or must retry.


-- Independent Exercise 4

-- Sally first query:
SELECT MAX(price) FROM Sells WHERE shop='Joe''s Shop';

-- Joe modifies:
DELETE FROM Sells WHERE shop='Joe''s Shop' AND product='Coffee';
INSERT INTO Sells VALUES ('Joe''s Shop','Juice',0.50);

-- Sally second query:
SELECT MIN(price) FROM Sells WHERE shop='Joe''s Shop';

-- Correct version:
BEGIN;
SELECT MAX(price), MIN(price) FROM Sells WHERE shop='Joe''s Shop';
COMMIT;

-- Answer IE4:
-- Without transactions Sally may see MAX < MIN due to mixing states.
-- Transactions guarantee consistent snapshot.