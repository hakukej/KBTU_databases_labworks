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
CREATE OR REPLACE VIEW employee_details AS
SELECT e.emp_id,
       e.emp_name,
       e.salary,
       d.dept_id,
       d.dept_name,
       d.location
FROM employees e
         JOIN departments d ON e.dept_id = d.dept_id;
--TEST
SELECT * FROM employee_details ORDER BY emp_id;
/*
 — How many rows are returned? — 4 rows (John Smith, Jane Doe, Mike Johnson, Sarah Williams).
— Why doesn't Tom Brown appear? — Because Tom Brown's dept_id is NULL, and employee_details
 uses an INNER JOIN with departments; rows without a corresponding entry in departments are filtered out.
 */
 --2.2
CREATE OR REPLACE VIEW dept_statistics AS
SELECT d.dept_id,
       d.dept_name,
       COUNT(e.emp_id) AS employee_count,
       ROUND(AVG(e.salary)::numeric, 2) AS average_salary,
       MAX(e.salary) AS max_salary,
       MIN(e.salary) AS min_salary
FROM departments d
         LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name;
--TEST
SELECT * FROM dept_statistics
ORDER BY employee_count DESC;
--2.3
CREATE OR REPLACE VIEW project_overview AS
SELECT p.project_id,
       p.project_name,
       p.budget,
       p.dept_id,
       d.dept_name,
       d.location,
       COALESCE(team.team_size, 0) AS team_size
FROM projects p
         LEFT JOIN departments d ON p.dept_id = d.dept_id
         LEFT JOIN (
    SELECT dept_id, COUNT(*) AS team_size
    FROM employees
    WHERE dept_id IS NOT NULL
    GROUP BY dept_id
) team ON p.dept_id = team.dept_id;
--TEST
SELECT * FROM project_overview ORDER BY project_id;
--2.4
CREATE OR REPLACE VIEW high_earners AS
SELECT e.emp_id, e.emp_name, e.salary, d.dept_name
FROM employees e
         LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 55000;
--TEST
SELECT * FROM high_earners ORDER BY emp_id;
/*
 What do you see? You'll see Jane Doe (60,000) and Sarah Williams (65,000).
 Mike Johnson has 55,000—he's not included because the condition is > 55,000.
 Tom Brown is missing (salary 45,000 and dept NULL).
 */
 --3.1
CREATE OR REPLACE VIEW employee_details AS
SELECT e.emp_id,
       e.emp_name,
       e.salary,
       d.dept_id,
       d.dept_name,
       d.location,
       CASE
           WHEN e.salary > 60000 THEN 'High'
           WHEN e.salary > 50000 THEN 'Medium'
           ELSE 'Standard'
           END AS salary_grade
FROM employees e
         JOIN departments d ON e.dept_id = d.dept_id;
--TEST
SELECT emp_name, salary, salary_grade
FROM employee_details
ORDER BY emp_id;
--3.2
ALTER VIEW high_earners RENAME TO top_performers;
-- TEST
SELECT * FROM top_performers;
--3.3
CREATE TEMPORARY VIEW temp_view AS
SELECT emp_id, emp_name, salary FROM employees WHERE salary < 50000;
-- TEST
SELECT * FROM temp_view;
-- DELETING
DROP VIEW IF EXISTS temp_view;
--4.1
CREATE OR REPLACE VIEW employee_salaries AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees;
--4.2
UPDATE employee_salaries
SET salary = 52000
WHERE emp_name = 'John Smith';
-- TEST
SELECT * FROM employees WHERE emp_name = 'John Smith';
/*
 Was the base table updated? Yes.
 Updating via the updatable view changes the underlying employees table:
 John Smith's salary will be 52,000.
 */
 --4.3
INSERT INTO employee_salaries (emp_id, emp_name, dept_id, salary)
VALUES (6, 'Alice Johnson', 102, 58000);
-- TEST
SELECT * FROM employees WHERE emp_id = 6;
/*
 Was the insert successful? — Yes, provided that emp_id = 6 is not occupied and
 the view is a simple projection view onto a single table.
 After the insert, the new record will appear in employees.
 */
 --4.4
CREATE OR REPLACE VIEW it_employees AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees
WHERE dept_id = 101
        WITH LOCAL CHECK OPTION;
-- INSERT INTO it_employees (emp_id, emp_name, dept_id, salary)
-- VALUES (7, 'Bob Wilson', 103, 60000);
-- ERROR:  new row violates check option for view "it_employees"
/*
 Because WITH LOCAL CHECK OPTION prevents inserting/updating rows through
 the view that don't meet its condition (dept_id = 101).
 This protects the view from inserting rows into it that don't meet the condition.
 */
--5.1
CREATE MATERIALIZED VIEW dept_summary_mv AS
SELECT d.dept_id,
       d.dept_name,
       COALESCE(COUNT(e.emp_id), 0) AS total_employees,
       COALESCE(SUM(e.salary), 0) AS total_salaries,
       COALESCE(COUNT(p.project_id) FILTER (WHERE p.project_id IS NOT NULL), 0) AS total_projects,
       COALESCE(SUM(p.budget), 0) AS total_project_budget
FROM departments d
         LEFT JOIN employees e ON d.dept_id = e.dept_id
         LEFT JOIN projects p ON d.dept_id = p.dept_id
GROUP BY d.dept_id, d.dept_name
WITH DATA;
--TEST
SELECT * FROM dept_summary_mv ORDER BY total_employees DESC;
--5.2
INSERT INTO employees (emp_id, emp_name, dept_id, salary)
VALUES (8, 'Charlie Brown', 101, 54000);
-- BEFORE refreshing
SELECT * FROM dept_summary_mv WHERE dept_id = 101;
-- refresh
REFRESH MATERIALIZED VIEW dept_summary_mv;
-- AFTER refreshing
SELECT * FROM dept_summary_mv WHERE dept_id = 101;
--Difference: Before REFRESH, the mat. view will contain old aggregates (total_employees=2).
-- After REFRESH, the data will be updated (total_employees=3, total_salaries=159000, etc.).
--5.3
CREATE UNIQUE INDEX ON dept_summary_mv (dept_id);
--refresh
REFRESH MATERIALIZED VIEW CONCURRENTLY dept_summary_mv;
--Advantage of CONCURRENTLY: Allows other sessions to read the materialized
-- view during the update (minimizes read locks).
-- Disadvantage:
-- The operation may require more resources and cannot be used within a transaction.
--5.4
CREATE MATERIALIZED VIEW project_stats_mv AS
SELECT p.project_id, p.project_name, p.budget, d.dept_name,
       COALESCE(team.team_size, 0) AS team_size
FROM projects p
         LEFT JOIN departments d ON p.dept_id = d.dept_id
         LEFT JOIN (
    SELECT dept_id, COUNT(*) AS team_size
    FROM employees
    WHERE dept_id IS NOT NULL
    GROUP BY dept_id
) team ON p.dept_id = team.dept_id
WITH NO DATA;
--SELECT * FROM project_stats_mv;
--error: empty result
--fixing:
REFRESH MATERIALIZED VIEW project_stats_mv;
--6.1
-- without login
CREATE ROLE analyst;
-- with login
CREATE ROLE data_viewer LOGIN PASSWORD 'viewer123';
CREATE ROLE report_user LOGIN PASSWORD 'report456';
--test
SELECT rolname FROM pg_roles WHERE rolname NOT LIKE 'pg_%';
--6.2
CREATE ROLE db_creator LOGIN PASSWORD 'creator789' CREATEDB;
CREATE ROLE user_manager LOGIN PASSWORD 'manager101' CREATEROLE;
CREATE ROLE admin_user LOGIN PASSWORD 'admin999' SUPERUSER;
--6.3
-- analyst: SELECT
GRANT SELECT ON employees, departments, projects TO analyst;
-- data_viewer: ALL PRIVILEGES на view employee_details
GRANT ALL PRIVILEGES ON employee_details TO data_viewer;
-- report_user: SELECT и INSERT на employees
GRANT SELECT, INSERT ON employees TO report_user;
--6.4
-- groups
CREATE ROLE hr_team;
CREATE ROLE finance_team;
CREATE ROLE it_team;
-- users
CREATE ROLE hr_user1 LOGIN PASSWORD 'hr001';
CREATE ROLE hr_user2 LOGIN PASSWORD 'hr002';
CREATE ROLE finance_user1 LOGIN PASSWORD 'fin001';

GRANT hr_team TO hr_user1;
GRANT hr_team TO hr_user2;
GRANT finance_team TO finance_user1;

GRANT SELECT, UPDATE ON employees TO hr_team;
GRANT SELECT ON dept_statistics TO finance_team;
--6.5
REVOKE UPDATE ON employees FROM hr_team;

REVOKE hr_team FROM hr_user2;

REVOKE ALL PRIVILEGES ON employee_details FROM data_viewer;
--6.6
ALTER ROLE analyst WITH LOGIN PASSWORD 'analyst123';

ALTER ROLE user_manager WITH SUPERUSER;

ALTER ROLE analyst WITH PASSWORD NULL;

ALTER ROLE data_viewer WITH CONNECTION LIMIT 5;
--7.1
CREATE ROLE read_only;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO read_only;

CREATE ROLE junior_analyst LOGIN PASSWORD 'junior123';
CREATE ROLE senior_analyst LOGIN PASSWORD 'senior123';

GRANT read_only TO junior_analyst;
GRANT read_only TO senior_analyst;

GRANT INSERT, UPDATE ON employees TO senior_analyst;
--7.2
CREATE ROLE project_manager LOGIN PASSWORD 'pm123';

ALTER TABLE projects OWNER TO project_manager;
ALTER VIEW dept_statistics OWNER TO project_manager;

SELECT tablename, tableowner
FROM pg_tables
WHERE schemaname = 'public';
--7.3
CREATE ROLE temp_owner LOGIN PASSWORD 'temp123';

CREATE TABLE temp_table (id INT);

ALTER TABLE temp_table OWNER TO temp_owner;

REASSIGN OWNED BY temp_owner TO postgres;

DROP OWNED BY temp_owner;

DROP ROLE temp_owner;
--7.4
CREATE OR REPLACE VIEW hr_employee_view AS
SELECT * FROM employees WHERE dept_id = 102;

GRANT SELECT ON hr_employee_view TO hr_team;

CREATE OR REPLACE VIEW finance_employee_view AS
SELECT emp_id, emp_name, salary FROM employees;

GRANT SELECT ON finance_employee_view TO finance_team;
--8.1
CREATE OR REPLACE VIEW dept_dashboard AS
SELECT d.dept_id,
       d.dept_name,
       d.location,
       COUNT(e.emp_id) AS employee_count,
       ROUND(COALESCE(AVG(e.salary),0)::numeric, 2) AS avg_salary,
       COUNT(p.project_id) AS active_projects,
       COALESCE(SUM(p.budget),0) AS total_project_budget,
       ROUND(
               CASE WHEN COUNT(e.emp_id) = 0 THEN 0
                    ELSE COALESCE(SUM(p.budget),0) / NULLIF(COUNT(e.emp_id),0)
                   END
                   ::numeric, 2) AS budget_per_employee
FROM departments d
         LEFT JOIN employees e ON d.dept_id = e.dept_id
         LEFT JOIN projects p ON d.dept_id = p.dept_id
GROUP BY d.dept_id, d.dept_name, d.location;
--test
SELECT * FROM dept_dashboard ORDER BY dept_id;
--8.2
ALTER TABLE projects ADD COLUMN created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

CREATE OR REPLACE VIEW high_budget_projects AS
SELECT p.project_id,
       p.project_name,
       p.budget,
       d.dept_name,
       p.created_date,
       CASE
           WHEN p.budget > 150000 THEN 'Critical Review Required'
           WHEN p.budget > 100000 THEN 'Management Approval Needed'
           ELSE 'Standard Process'
           END AS approval_status
FROM projects p
         LEFT JOIN departments d ON p.dept_id = d.dept_id
WHERE p.budget > 75000;
--test
SELECT * FROM high_budget_projects ORDER BY budget DESC;
--8.3
CREATE ROLE viewer_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO viewer_role;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO viewer_role;

CREATE ROLE entry_role;
GRANT viewer_role TO entry_role;
GRANT INSERT ON employees, projects TO entry_role;

CREATE ROLE analyst_role;
GRANT entry_role TO analyst_role;
GRANT UPDATE ON employees, projects TO analyst_role;

CREATE ROLE manager_role;
GRANT analyst_role TO manager_role;
GRANT DELETE ON employees, projects TO manager_role;

CREATE ROLE alice LOGIN PASSWORD 'alice123';
CREATE ROLE bob LOGIN PASSWORD 'bob123';
CREATE ROLE charlie LOGIN PASSWORD 'charlie123';

GRANT viewer_role TO alice;
GRANT analyst_role TO bob;
GRANT manager_role TO charlie;
