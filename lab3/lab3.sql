CREATE TABLE IF NOT EXISTS departments (
                                           dept_id SERIAL PRIMARY KEY,
                                           dept_name VARCHAR(100) NOT NULL UNIQUE,
                                           budget INTEGER DEFAULT 0,
                                           manager_id INTEGER
);

CREATE TABLE IF NOT EXISTS employees (
                                         emp_id SERIAL PRIMARY KEY,
                                         first_name VARCHAR(50) NOT NULL,
                                         last_name VARCHAR(50) NOT NULL,
                                         department INTEGER REFERENCES departments(dept_id),
                                         salary INTEGER,
                                         hire_date DATE,
                                         status VARCHAR(20) DEFAULT 'Active'
);

CREATE TABLE IF NOT EXISTS projects (
                                        project_id SERIAL PRIMARY KEY,
                                        project_name VARCHAR(150) NOT NULL,
                                        dept_id INTEGER REFERENCES departments(dept_id),
                                        start_date DATE,
                                        end_date DATE,
                                        budget INTEGER
);

INSERT INTO departments (dept_name, budget, manager_id)
VALUES
    ('IT', 120000, NULL),
    ('Sales', 80000, NULL),
    ('HR', 50000, NULL)
ON CONFLICT (dept_name) DO NOTHING;
-- Part B
-- 2. INSERT with column specification
INSERT INTO employees (first_name, last_name, department)
VALUES ('Alice', 'Smith', (SELECT dept_id FROM departments WHERE dept_name = 'IT'));

-- 3. INSERT with DEFAULT values
INSERT INTO employees (first_name, last_name, department, hire_date)
VALUES ('Bob', 'Johnson', (SELECT dept_id FROM departments WHERE dept_name = 'Sales'), CURRENT_DATE);

-- 4. INSERT multiple rows in single statement
INSERT INTO departments (dept_name, budget, manager_id)
VALUES
    ('R&D', 150000, NULL),
    ('Support', 40000, NULL),
    ('Marketing', 70000, NULL)
ON CONFLICT (dept_name) DO NOTHING;

-- 5. INSERT with expressions
INSERT INTO employees (first_name, last_name, department, hire_date, salary)
VALUES ('Carol', 'Taylor', (SELECT dept_id FROM departments WHERE dept_name = 'R&D'),
        CURRENT_DATE, ROUND(50000 * 1.1)::INTEGER);

-- 6. INSERT from SELECT (subquery)
CREATE TEMP TABLE IF NOT EXISTS temp_employees AS
SELECT * FROM employees WHERE 1=0;  -- create empty with same structure

INSERT INTO temp_employees
SELECT * FROM employees WHERE department = (SELECT dept_id FROM departments WHERE dept_name = 'IT');

-- Part C: Complex UPDATE Operations

INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES
    ('David', 'Brown', (SELECT dept_id FROM departments WHERE dept_name='IT'), 75000, '2018-06-15', 'Active'),
    ('Eva', 'Green', (SELECT dept_id FROM departments WHERE dept_name='Sales'), 45000, '2021-03-10', 'Active'),
    ('Frank', 'White', NULL, 35000, '2024-02-01', 'Active'),
    ('Grace', 'Black', (SELECT dept_id FROM departments WHERE dept_name='HR'), 90000, '2015-11-01', 'Active'),
    ('Henry', 'King', (SELECT dept_id FROM departments WHERE dept_name='Sales'), 65000, '2019-09-05', 'Active');

-- 7. UPDATE with arithmetic expressions
UPDATE employees
SET salary = ROUND(COALESCE(salary,0) * 1.10)::INTEGER
WHERE salary IS NOT NULL;
-- 8. UPDATE with WHERE clause and multiple conditions
UPDATE employees
SET status = 'Senior'
WHERE salary > 60000
  AND hire_date < DATE '2020-01-01';

-- 9. UPDATE using CASE expression
UPDATE employees
SET department = CASE
                     WHEN salary > 80000 THEN (SELECT dept_id FROM departments WHERE dept_name = 'R&D')  -- Management -> R&D
                     WHEN salary BETWEEN 50000 AND 80000 THEN (SELECT dept_id FROM departments WHERE dept_name = 'Sales')  -- Senior -> Sales
                     ELSE (SELECT dept_id FROM departments WHERE dept_name = 'Support')  -- Junior -> Support
    END
WHERE salary IS NOT NULL;

-- 10. UPDATE with DEFAULT
UPDATE employees SET status = 'Inactive' WHERE first_name = 'Frank' AND last_name = 'White';
UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

-- 11. UPDATE with subquery
UPDATE departments d
SET budget = CEIL( (SELECT AVG(e.salary) FROM employees e WHERE e.department = d.dept_id) * 1.20 )::INTEGER
WHERE EXISTS (SELECT 1 FROM employees e WHERE e.department = d.dept_id AND e.salary IS NOT NULL);

-- 12. UPDATE multiple columns
UPDATE employees
SET salary = ROUND(salary * 1.15)::INTEGER,
    status = 'Promoted'
WHERE department = (SELECT dept_id FROM departments WHERE dept_name = 'Sales');

-- Part D: Advanced DELETE Operations

-- 13. DELETE with simple WHERE condition
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Ivy', 'Gray', (SELECT dept_id FROM departments WHERE dept_name='Support'), 30000, '2022-05-01', 'Terminated');

DELETE FROM employees
WHERE status = 'Terminated';

-- 14. DELETE with complex WHERE clause
DELETE FROM employees
WHERE salary < 40000
  AND hire_date > DATE '2023-01-01'
  AND department IS NULL;

-- 15. DELETE with subquery
DELETE FROM departments
WHERE dept_id NOT IN (SELECT DISTINCT department FROM employees WHERE department IS NOT NULL);

-- 16. DELETE with RETURNING clause
INSERT INTO projects (project_name, dept_id, start_date, end_date, budget)
VALUES
    ('Old Project A', (SELECT dept_id FROM departments LIMIT 1), '2019-01-01', '2022-12-31', 30000),
    ('Old Project B', (SELECT dept_id FROM departments LIMIT 1 OFFSET 1), '2018-05-01', '2022-06-30', 25000),
    ('Active Project X', (SELECT dept_id FROM departments LIMIT 1 OFFSET 2), '2024-01-01', '2025-12-31', 80000);

DELETE FROM projects
WHERE end_date < DATE '2023-01-01'
RETURNING *;

-- Part E: Operations with NULL Values

-- 17. INSERT with NULL values
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Jack', 'Null', NULL, NULL, CURRENT_DATE, 'Active');

-- 18. UPDATE NULL handling
UPDATE employees
SET department = (SELECT dept_id FROM departments WHERE dept_name = 'Support')
WHERE department IS NULL;

-- 19. DELETE with NULL conditions
DELETE FROM employees
WHERE salary IS NULL OR department IS NULL;

-- Part F: RETURNING Clause Operations

-- 20. INSERT with RETURNING
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Karen', 'Young', (SELECT dept_id FROM departments WHERE dept_name = 'Marketing'), 52000, CURRENT_DATE)
RETURNING emp_id, (first_name || ' ' || last_name) AS full_name;

-- 21. UPDATE with RETURNING
WITH updated AS (
    SELECT emp_id, salary AS old_salary
    FROM employees
    WHERE department = (SELECT dept_id FROM departments WHERE dept_name = 'IT')
)
UPDATE employees e
SET salary = e.salary + 5000
FROM updated u
WHERE e.emp_id = u.emp_id
RETURNING e.emp_id, u.old_salary, e.salary AS new_salary;

-- 22. DELETE with RETURNING all columns
DELETE FROM employees
WHERE hire_date < DATE '2020-01-01'
RETURNING *;

-- Part G: Advanced DML Patterns

-- 23. Conditional INSERT (only if not exists)
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
SELECT 'Liam', 'Stone', (SELECT dept_id FROM departments WHERE dept_name='Support'), 48000, CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM employees WHERE first_name = 'Liam' AND last_name = 'Stone'
);

-- 24. UPDATE with JOIN logic using subqueries
UPDATE employees e
SET salary = CASE
                 WHEN d.budget > 100000 THEN ROUND(e.salary * 1.10)::INTEGER
                 ELSE ROUND(e.salary * 1.05)::INTEGER
    END
FROM departments d
WHERE e.department = d.dept_id
  AND e.salary IS NOT NULL;

-- 25. Bulk operations
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES
    ('Mona','Lee',(SELECT dept_id FROM departments WHERE dept_name='Marketing'), 40000, CURRENT_DATE),
    ('Nate','Wong',(SELECT dept_id FROM departments WHERE dept_name='Marketing'), 41000, CURRENT_DATE),
    ('Olga','Perez',(SELECT dept_id FROM departments WHERE dept_name='Marketing'), 42000, CURRENT_DATE),
    ('Paul','Khan',(SELECT dept_id FROM departments WHERE dept_name='Marketing'), 43000, CURRENT_DATE),
    ('Quinn','Ibrahim',(SELECT dept_id FROM departments WHERE dept_name='Marketing'), 44000, CURRENT_DATE)
RETURNING emp_id;

UPDATE employees
SET salary = ROUND(salary * 1.10)::INTEGER
WHERE department = (SELECT dept_id FROM departments WHERE dept_name = 'Marketing');

-- 26. Data migration simulation
CREATE TABLE IF NOT EXISTS employee_archive (
                                                emp_id INTEGER PRIMARY KEY,
                                                first_name VARCHAR(50),
                                                last_name VARCHAR(50),
                                                department INTEGER,
                                                salary INTEGER,
                                                hire_date DATE,
                                                status VARCHAR(20),
                                                archived_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO employee_archive (emp_id, first_name, last_name, department, salary, hire_date, status)
SELECT emp_id, first_name, last_name, department, salary, hire_date, status
FROM employees
WHERE status = 'Inactive'
ON CONFLICT (emp_id) DO NOTHING;

DELETE FROM employees
WHERE status = 'Inactive';

-- 27. Complex business logic
UPDATE projects p
SET end_date = p.end_date + INTERVAL '30 days'
WHERE p.budget > 50000
  AND EXISTS (
    SELECT 1
    FROM departments d
    WHERE d.dept_id = p.dept_id
      AND (SELECT COUNT(*) FROM employees e WHERE e.department = d.dept_id) > 3
);


-- Show employees
SELECT * FROM employees ORDER BY emp_id;

-- Show departments
SELECT * FROM departments ORDER BY dept_id;

-- Show projects
SELECT * FROM projects ORDER BY project_id;
-- Show archive
SELECT * FROM employee_archive ORDER BY archived_at DESC;