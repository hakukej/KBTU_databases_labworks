CREATE TABLE accounts (
                          id SERIAL PRIMARY KEY,
                          name VARCHAR(100) NOT NULL,
                          balance DECIMAL(10, 2) DEFAULT 0.00
);
CREATE TABLE products (
                          id SERIAL PRIMARY KEY,
                          shop VARCHAR(100) NOT NULL,
                          product VARCHAR(100) NOT NULL,
                          price DECIMAL(10, 2) NOT NULL
);
-- Insert test data
INSERT INTO accounts (name, balance) VALUES
                                         ('Alice', 1000.00),
                                         ('Bob', 500.00),
                                         ('Wally', 750.00);
INSERT INTO products (shop, product, price) VALUES
                                                ('Joe''s Shop', 'Coke', 2.50),
                                                ('Joe''s Shop', 'Pepsi', 3.00);
--1
BEGIN;
UPDATE accounts SET balance = balance - 100.00
WHERE name = 'Alice';
UPDATE accounts SET balance = balance + 100.00
WHERE name = 'Bob';
COMMIT;

-- Answers:
-- a)
-- Alice: 1000 – 100 = 900
-- Bob: 500 + 100 = 600
-- b)
-- Both UPDATES are a single logical operation. If they are not combined into a transaction, the money could be lost.
-- c)
-- If the system crashes between UPDATES, Alice will lose the $100, and Bob will not receive it → integrity violation.

BEGIN;
UPDATE accounts SET balance = balance - 500 WHERE name = 'Alice';
SELECT * FROM accounts WHERE name = 'Alice';
ROLLBACK;
SELECT * FROM accounts WHERE name = 'Alice';
-- Answers:
-- a) After UPDATE but before ROLLBACK — 900 – 500 = 400
-- b) After ROLLBACK — returns the original value: 900
-- c) ROLLBACK is used when:
-- invalid input was entered
-- an error occurred
-- constraints are violated
-- only part of the changes need to be reverted
BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE name='Alice';
SAVEPOINT my_savepoint;
UPDATE accounts SET balance = balance + 100 WHERE name='Bob';
ROLLBACK TO my_savepoint;
UPDATE accounts SET balance = balance + 100 WHERE name='Wally';
COMMIT;
-- a)
-- Alice: 900 – 100 = 800
-- Bob: unchanged = 600
-- Wally: 750 + 100 = 850
-- b) Bob was updated between SAVEPOINT and ROLLBACK, but the transaction was rolled back to the savepoint -> his update is not included in the final result.
-- c) SAVEPOINT is useful when you need to roll back part of a transaction, not the entire transaction.
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT MAX(price), MIN(price) FROM products
WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2
SELECT MAX(price), MIN(price) FROM products
WHERE shop = 'Joe''s Shop';
COMMIT;

BEGIN;
INSERT INTO products (shop, product, price)
VALUES ('Joe''s Shop', 'Sprite', 4.00);
COMMIT;
-- Scenario A:
-- Terminal 1 first SELECT sees Coke, Pepsi
--     Terminal 2 deletes and inserts Fanta, commits
--     Terminal 1 second SELECT sees only Fanta
-- READ COMMITTED = sees new data after the second client commits
-- Scenario B: SERIALIZABLE
-- Terminal 1:
-- first SELECT Coke, Pepsi
-- second SELECT same
-- → SERIALIZABLE blocks "phantom changes" from other transactions
-- Answers:
-- a)
-- Before commit: Coke, Pepsi
-- After commit: Fanta only
-- b)
-- Terminal 1 sees the same initial data. Inserts/deletes from Terminal 2 are invisible.
-- c) READ COMMITTED, shows only committed changes
-- SERIALIZABLE, operates as if no other transactions exist
-- Terminal 1 doesn't see the new Sprite row.
-- REPEATABLE READ prevents new rows from appearing in repeated queries.
-- b)
-- Phantom read — when a repeated SELECT returns different rows (new rows are added).
-- c)
-- ONLY SERIALIZABLE prevents phantom reads.
BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2 to UPDATE but NOT commit
SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2 to ROLLBACK
SELECT * FROM products WHERE shop = 'Joe''s Shop';
COMMIT;
BEGIN;
UPDATE products SET price = 99.99
WHERE product = 'Fanta';
-- Wait here (don't commit yet)
-- Then:
ROLLBACK;
-- Answers:
-- a)
-- Yes, Terminal 1 sees the price as 99.99, even though it's not committed. This is dangerous because this data could be rolled back.
-- b)
-- Dirty read — when a transaction reads the uncommitted changes of another transaction.
-- c)
-- READ UNCOMMITTED can only be used for analytics, not for banks, stores, or reservations, as the data could be false.

--1ex
BEGIN;

SELECT balance INTO temp_balance FROM accounts WHERE name='Bob';

IF temp_balance >= 200 THEN
UPDATE accounts SET balance = balance - 200 WHERE name='Bob';
UPDATE accounts SET balance = balance + 200 WHERE name='Wally';
COMMIT;
ELSE
ROLLBACK;
END IF;
--2ex
BEGIN;

INSERT INTO products (shop, product, price)
VALUES ('Joe''s Shop', 'Tea', 1.50);
SAVEPOINT sp1;

UPDATE products SET price = 2.00 WHERE product='Tea';
SAVEPOINT sp2;

DELETE FROM products WHERE product='Tea';

ROLLBACK TO sp1;
COMMIT;
--3ex
-- READ UNCOMMITTED, both see the old balance, overdraft
-- READ COMMITTED, no dirty reads, but race conditions are possible
-- REPEATABLE READ, blocks repeated reads
-- SERIALIZABLE, one user will receive the "could not serialize access" error
--4ex
-- Without transactions:
-- Sally does a SELECT MAX
-- Joe deletes rows
-- Sally does a SELECT MIN,  possible error: MAX < MIN
-- With a transaction, the problem disappears.
-- 5. Questions for Self-Assessment
-- 1. Explain ACID with examples.
--     Atomicity - money transfer: either both UPDATE s or neither.
--     Consistency - the balance does not become negative.
--     Isolation - parallel transfers do not interfere with each other.
-- Durability - data is not lost after a commit.
-- 2. COMMIT vs. ROLLBACK
-- COMMIT saves changes.
-- ROLLBACK discards changes.
-- 3. SAVEPOINT vs. ROLLBACK
-- SAVEPOINT rolls back only part of the transaction.
-- 4. Compare all isolation levels
-- (done in the table above)
-- 5. Dirty read
-- Reading uncommitted data; allows READ UNCOMMITTED.
-- 6. Non-repeatable read
-- When a repeated SELECT returns changed values.
-- 7. Phantom read
-- New rows appear during a repeated SELECT; prevents SERIALIZABLE.
-- 8. Why choose READ COMMITTED?
-- It's fast and balanced: it prevents dirty reads, but it's not too expensive.
-- 9. How do transactions ensure consistency?
-- They guarantee that operations are executed completely, isolated, and atomically.
-- 10. What happens to uncommitted changes after a crash?
-- They are lost—thanks to logging.
-- 6. Conclusion
-- In this lab, I learned how SQL transactions ensure data integrity through ACID principles and how transaction control statements (BEGIN, COMMIT, ROLLBACK, SAVEPOINT) manage changes.
-- I explored different isolation levels and observed how they affect concurrent data access, preventing anomalies such as dirty reads, non-repeatable reads, and phantom reads.
-- This lab demonstrated the importance of transactions in multi-user environments and showed how proper isolation ensures correctness and reliability.
