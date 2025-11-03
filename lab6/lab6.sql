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
SELECT e.emp_name, d.dept_name
FROM employees e CROSS JOIN departments d;
--alternatives
SELECT e.emp_name, d.dept_name
FROM employees e, departments d;

SELECT e.emp_name, d.dept_name
FROM employees e
         INNER JOIN departments d ON TRUE;

--2.3
SELECT e.emp_name, p.project_name
FROM employees e CROSS JOIN projects p;
--3.1
SELECT e.emp_name, d.dept_name, d.location
FROM employees e
         INNER JOIN departments d ON e.dept_id = d.dept_id;
--How many rows? 4 rows (John, Jane, Mike, Sarah).
--Why isn't Tom Brown included? His dept_id is NULL, and INNER JOIN only returns matching pairs—rows with NULL in the join column won't match the departments.
--3.2
SELECT emp_name, dept_name, location
FROM employees
         INNER JOIN departments USING (dept_id);
/*
 The difference in output is that USING (dept_id) combines columns with the same name into one column dept_id in the result
 (there won't be two separate columns e.dept_id and d.dept_id), while ON usually keeps both if you explicitly select e.dept_id, d.dept_id.
 */
--3.3
SELECT emp_name, dept_name, location
FROM employees
         NATURAL INNER JOIN departments;
--3.4
SELECT e.emp_name, d.dept_name, p.project_name
FROM employees e
         INNER JOIN departments d ON e.dept_id = d.dept_id
         INNER JOIN projects p ON d.dept_id = p.dept_id;
--4
SELECT e.emp_name, e.dept_id AS emp_dept, d.dept_id AS dept_dept, d.dept_name
FROM employees e
         LEFT JOIN departments d ON e.dept_id = d.dept_id;
--How is Tom Brown represented? Tom Brown's emp_dept is NULL, and the departments columns will be NULL (i.e., dept_dept and dept_name are NULL).
--4.2
SELECT emp_name, dept_id, dept_name
FROM employees
         LEFT JOIN departments USING (dept_id);
--4.3
SELECT e.emp_name, e.dept_id
FROM employees e
         LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.dept_id IS NULL;
--4.4
SELECT d.dept_name, COUNT(e.emp_id) AS employee_count
FROM departments d
         LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY employee_count DESC;
--5.1
SELECT e.emp_name, d.dept_name
FROM employees e
         RIGHT JOIN departments d ON e.dept_id = d.dept_id;
--5.2
SELECT e.emp_name, d.dept_name
FROM departments d
         LEFT JOIN employees e ON e.dept_id = d.dept_id;
--5.3
SELECT d.dept_name, d.location
FROM employees e
         RIGHT JOIN departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL;
--6
SELECT e.emp_name, e.dept_id AS emp_dept, d.dept_id AS dept_dept, d.dept_name
FROM employees e
         FULL JOIN departments d ON e.dept_id = d.dept_id;
/*
 Which NULLs are where?
NULLs on the left (i.e., e.* NULL) are records that exist in departments but have no employees -> dept 104 (Marketing).
NULLs on the right (i.e., d.* NULL) are records that exist in employees but have no department -> Tom Brown (emp_id=5).
 */
--6.2
SELECT d.dept_name, p.project_name, p.budget
FROM departments d
         FULL JOIN projects p ON d.dept_id = p.dept_id;
--6.3
SELECT
    CASE
        WHEN e.emp_id IS NULL THEN 'Department without employees'
        WHEN d.dept_id IS NULL THEN 'Employee without department'
        ELSE 'Matched'
        END AS record_status,
    e.emp_name,
    d.dept_name
FROM employees e
         FULL JOIN departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL OR d.dept_id IS NULL;
--7
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
         LEFT JOIN departments d ON e.dept_id = d.dept_id AND d.location = 'Building A';
--7.2
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
         LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';
/*
 Query1 (ON filter): returns ALL employees; those whose department is not in Building A will have d.* NULL.
Query2 (WHERE filter): returns only employees whose department is not NULL and whose location is 'Building A'.
 This means that Query2 can exclude rows that Query1 leaves with NULL in d.
 */
--7.3
/*
 When replacing LEFT JOIN with INNER JOIN, the result of both versions is the same:
 INNER JOIN already requires a match, and adding an additional condition either in ON or WHERE results in the same set of rows
 (filtering occurs before/after - but rows that do not satisfy the condition are removed anyway).
 */
--8.1
SELECT
    d.dept_name,
    e.emp_name,
    e.salary,
    p.project_name,
    p.budget
FROM departments d
         LEFT JOIN employees e ON d.dept_id = e.dept_id
         LEFT JOIN projects p ON d.dept_id = p.dept_id
ORDER BY d.dept_name, e.emp_name;
--8.2
ALTER TABLE employees ADD COLUMN manager_id INT;

UPDATE employees SET manager_id = 3 WHERE emp_id = 1;
UPDATE employees SET manager_id = 3 WHERE emp_id = 2;
UPDATE employees SET manager_id = NULL WHERE emp_id = 3;
UPDATE employees SET manager_id = 3 WHERE emp_id = 4;
UPDATE employees SET manager_id = 3 WHERE emp_id = 5;

SELECT
    e.emp_name AS employee,
    m.emp_name AS manager
FROM employees e
         LEFT JOIN employees m ON e.manager_id = m.emp_id;
--8.3
SELECT d.dept_name, AVG(e.salary) AS avg_salary
FROM departments d
         INNER JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
HAVING AVG(e.salary) > 50000;
/*
 Lab Questions - Short Answers
1. What's the difference between an INNER JOIN and a LEFT JOIN?
An INNER JOIN returns only rows that have a match in both tables.
A LEFT JOIN returns all rows from the left table and matching rows from the right; if there are no matches, the right columns will be NULL.
2. When is a CROSS JOIN used practically?
When you need to retrieve all combinations of two sets.
3. Why is the filter position (ON vs. WHERE) important for outer joins but not for an INNER JOIN?
An outer join first performs the ON join (taking into account the conditions in the ON join),
preserving rows from the left/right tables even if there are no matches; the WHERE join is performed afterward and can filter out rows with NULLs,
which changes the result. For an INNER JOIN, the ON or WHERE conditions yield the same result set because rows without matches are discarded.
4. What happens to SELECT COUNT(*) FROM table1 CROSS JOIN table2 if table1 = 5, table2 = 10?
5 × 10 = 50.
5. How does NATURAL JOIN determine the columns to join?
NATURAL JOIN automatically uses all columns with the same name in both tables as join conditions.
6. Risks of NATURAL JOIN?
Inattentively adding or removing a column can change the query's behavior (the join may suddenly contain or not contain new columns).
Unintentional joins are possible on columns that shouldn't be included in the join. Therefore, NATURAL JOIN is unsafe in large/changing schemas.
7. LEFT -> RIGHT transformation:
SELECT * FROM A LEFT JOIN B ON A.id = B.id is equivalent to:
SELECT * FROM B RIGHT JOIN A ON A.id = B.id;
8. When to use a FULL OUTER JOIN?
When you need to retrieve all rows from both tables and see which records have no matches (i.e., combine the LEFT and RIGHT results and show orphaned records).
This is useful for comparing datasets, deduplication, and finding orphaned records.
 */
