CREATE TABLE employees (
                           emp_id INT PRIMARY KEY,
                           emp_name VARCHAR(50),
                           dept_id INT,
                           salary DECIMAL(10,2)
);

CREATE TABLE departments (
                             dept_id INT PRIMARY KEY,
                             dept_name VARCHAR(50),
                             location VARCHAR(50)
);

CREATE TABLE projects (
                          project_id INT PRIMARY KEY,
                          project_name VARCHAR(50),
                          dept_id INT,
                          budget DECIMAL(10,2)
);

INSERT INTO employees (emp_id, emp_name, dept_id, salary) VALUES
                                                              (1, 'John Smith', 101, 50000),
                                                              (2, 'Jane Doe', 102, 60000),
                                                              (3, 'Mike Johnson', 101, 55000),
                                                              (4, 'Sarah Williams', 103, 65000),
                                                              (5, 'Tom Brown', NULL, 45000);

INSERT INTO departments (dept_id, dept_name, location) VALUES
                                                           (101, 'IT', 'Building A'),
                                                           (102, 'HR', 'Building B'),
                                                           (103, 'Finance', 'Building C'),
                                                           (104, 'Marketing', 'Building D');

INSERT INTO projects (project_id, project_name, dept_id, budget) VALUES
                                                                     (1, 'Website Redesign', 101, 100000),
                                                                     (2, 'Employee Training', 102, 50000),
                                                                     (3, 'Budget Analysis', 103, 75000),
                                                                     (4, 'Cloud Migration', 101, 150000),
                                                                     (5, 'AI Research', NULL, 200000);
--2.1
CREATE INDEX emp_salary_idx ON employees(salary);

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees';
--Answer: 2 indexes (PRIMARY KEY + emp_salary_idx)
--2.2
CREATE INDEX emp_dept_idx ON employees(dept_id);

SELECT * FROM employees WHERE dept_id = 101;
--Answer: Speeds up JOINs and filtering by dept_id.
--2.3
SELECT
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
--Answer: Visible: emp_salary_idx, emp_dept_idx
-- Automatic: employees_pkey
--3.1
CREATE INDEX emp_dept_salary_idx ON employees(dept_id, salary);

SELECT emp_name, salary
FROM employees
WHERE dept_id = 101 AND salary > 52000;
--Answer: No, a multicolumn index only works starting from the first column.
--3.2
CREATE INDEX emp_salary_dept_idx ON employees(salary, dept_id);

-- Query 1: Filters by dept_id first
SELECT * FROM employees WHERE dept_id = 102 AND salary > 50000;
-- Query 2: Filters by salary first
SELECT * FROM employees WHERE salary > 50000 AND dept_id = 102;
--Answer: Yes, the index uses columns strictly from left to right.
--4.1
ALTER TABLE employees ADD COLUMN email VARCHAR(100);
UPDATE employees SET email = 'john.smith@company.com' WHERE emp_id = 1;
UPDATE employees SET email = 'jane.doe@company.com' WHERE emp_id = 2;
UPDATE employees SET email = 'mike.johnson@company.com' WHERE emp_id = 3;
UPDATE employees SET email = 'sarah.williams@company.com' WHERE emp_id = 4;
UPDATE employees SET email = 'tom.brown@company.com' WHERE emp_id = 5;

CREATE UNIQUE INDEX emp_email_unique_idx ON employees(email);

INSERT INTO employees (emp_id, emp_name, dept_id, salary, email)
VALUES (6, 'New Employee', 101, 55000, 'john.smith@company.com');
--Answer: ERROR: duplicate key value violates unique constraint
--4.2
ALTER TABLE employees ADD COLUMN phone VARCHAR(20) UNIQUE;

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees' AND indexname LIKE '%phone%';
--Answer: Yes, an automatic B-tree index was created.
--5.1
CREATE INDEX emp_salary_desc_idx ON employees(salary DESC);

SELECT emp_name, salary
FROM employees
ORDER BY salary DESC;
--Answer: Allows an Index Scan without sorting.
--5.2
CREATE INDEX proj_budget_nulls_first_idx ON projects(budget NULLS FIRST);

SELECT project_name, budget
FROM projects
ORDER BY budget NULLS FIRST;
--6.1
CREATE INDEX emp_name_lower_idx ON employees(LOWER(emp_name));

SELECT * FROM employees WHERE LOWER(emp_name) = 'john smith';
--Answer: With a full table scan (Seq Scan).
--6.2
ALTER TABLE employees ADD COLUMN hire_date DATE;
UPDATE employees SET hire_date = '2020-01-15' WHERE emp_id = 1;
UPDATE employees SET hire_date = '2019-06-20' WHERE emp_id = 2;
UPDATE employees SET hire_date = '2021-03-10' WHERE emp_id = 3;
UPDATE employees SET hire_date = '2020-11-05' WHERE emp_id = 4;
UPDATE employees SET hire_date = '2018-08-25' WHERE emp_id = 5;

CREATE INDEX emp_hire_year_idx ON employees(EXTRACT(YEAR FROM hire_date));

SELECT emp_name, hire_date
FROM employees
WHERE EXTRACT(YEAR FROM hire_date) = 2020;
--7.1
ALTER INDEX emp_salary_idx RENAME TO employees_salary_index;

SELECT indexname FROM pg_indexes WHERE tablename = 'employees';
--7.2
DROP INDEX emp_salary_dept_idx;
--Answer: It slows down writes and takes up space.
--7.3
REINDEX INDEX employees_salary_index;
--8.1
SELECT e.emp_name, e.salary, d.dept_name
FROM employees e
         JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 50000
ORDER BY e.salary DESC;

CREATE INDEX emp_salary_filter_idx ON employees(salary) WHERE salary > 50000;
--8.2
CREATE INDEX proj_high_budget_idx ON projects(budget)
    WHERE budget > 80000;

SELECT project_name, budget
FROM projects
WHERE budget > 80000;
--Answer: Smaller size -> faster.
--8.3
EXPLAIN SELECT * FROM employees WHERE salary > 52000;
--Answer: If Index Scan -> the index is used.
--If Seq Scan -> the index is NOT used.
--9.1
CREATE INDEX dept_name_hash_idx ON departments USING HASH (dept_name);

SELECT * FROM departments WHERE dept_name = 'IT';
--Answer: Only for equality =, when there are no ranges.
--9.2
CREATE INDEX proj_name_btree_idx ON projects(project_name);

CREATE INDEX proj_name_hash_idx ON projects USING HASH (project_name);

SELECT * FROM projects WHERE project_name = 'Website Redesign';
SELECT * FROM projects WHERE project_name > 'Database';
--10.1
SELECT
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexname::regclass)) as index_size
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
--Answer: Largest - the index on the largest column (usually proj_name_btree_idx).
--Because the string is long.
--10.2
DROP INDEX IF EXISTS proj_name_hash_idx;
--10.3
CREATE VIEW index_documentation AS
SELECT
    tablename,
    indexname,
    indexdef,
    'Improves salary-based queries' as purpose
FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname LIKE '%salary%';
--Answers:
-- 1. Default index type?
-- B-tree
-- 2. When to create an index (3 cases)?
-- WHERE
-- JOIN
-- ORDER BY
-- 3. When NOT to create an index (2 cases)?
-- On small tables
-- On highly volatile columns
-- 4. What happens during INSERT/UPDATE/DELETE?
-- The index is updated → writes are slower.
-- 5. How to check if an index is being used?
-- EXPLAIN
--Additional:
--1
CREATE INDEX emp_hire_month_idx
    ON employees (EXTRACT(MONTH FROM hire_date));
--2
CREATE UNIQUE INDEX emp_dept_email_unique_idx
    ON employees (dept_id, email);
--3
EXPLAIN ANALYZE
SELECT emp_id, emp_name, salary
FROM employees
WHERE dept_id = 101 AND LOWER(emp_name) = 'john smith';

CREATE INDEX emp_dept_idx ON employees(dept_id);
CREATE INDEX emp_name_lower_idx ON employees(LOWER(emp_name));

EXPLAIN ANALYZE
SELECT emp_id, emp_name, salary
FROM employees
WHERE dept_id = 101 AND LOWER(emp_name) = 'john smith';

--4
CREATE INDEX emp_covering_idx
    ON employees (dept_id, salary)
    INCLUDE (emp_id, emp_name);
