-- Name: Akerke
-- Student ID: 24B031618

/* ============================================================================
   Part 1: CHECK Constraints
   Task 1.1: Basic CHECK Constraint - employees
   - age must be between 18 and 65
   - salary must be > 0
*/
DROP TABLE IF EXISTS employees CASCADE;
CREATE TABLE employees (
                           employee_id   integer PRIMARY KEY,
                           first_name    text,
                           last_name     text,
                           age           integer CHECK (age BETWEEN 18 AND 65),   -- ensures 18 <= age <= 65
                           salary        numeric CHECK (salary > 0)               -- salary must be > 0
);

-- Insert valid rows
INSERT INTO employees (employee_id, first_name, last_name, age, salary) VALUES
                                                                            (1, 'Alice', 'Ivanova', 28, 45000.00),
                                                                            (2, 'Boris', 'Petrov', 35, 60000.50);

-- Attempt to insert invalid rows (examples commented out)
-- Violates age CHECK (too young)
-- INSERT INTO employees (employee_id, first_name, last_name, age, salary) VALUES
-- (3, 'Young', 'Kid', 16, 20000);
-- ERROR: new row for relation "employees" violates check constraint "employees_age_check" (or similar)
-- Reason: age = 16 < 18

-- Violates salary CHECK (non-positive)
-- INSERT INTO employees (employee_id, first_name, last_name, age, salary) VALUES
-- (4, 'Zero', 'Salary', 30, 0);
-- ERROR: new row violates check constraint "employees_salary_check"
-- Reason: salary must be > 0

/* ============================================================================
   Task 1.2: Named CHECK Constraint - products_catalog
   - named constraint valid_discount
   - regular_price > 0
   - discount_price > 0
   - discount_price < regular_price
*/
DROP TABLE IF EXISTS products_catalog CASCADE;
CREATE TABLE products_catalog (
                                  product_id     integer PRIMARY KEY,
                                  product_name   text NOT NULL,
                                  regular_price  numeric NOT NULL,
                                  discount_price numeric NOT NULL,
                                  CONSTRAINT valid_discount CHECK (
                                      regular_price > 0
                                          AND discount_price > 0
                                          AND discount_price < regular_price
                                      )
);

-- Insert valid rows
INSERT INTO products_catalog (product_id, product_name, regular_price, discount_price) VALUES
                                                                                           (101, 'T-shirt', 20.00, 15.00),
                                                                                           (102, 'Mug', 10.50, 7.50);

-- Invalid inserts (commented)
-- Violates valid_discount: discount_price >= regular_price
-- INSERT INTO products_catalog (product_id, product_name, regular_price, discount_price) VALUES
-- (103, 'BadDeal', 25.00, 25.00);
-- ERROR: new row violates check constraint "valid_discount"
-- Reason: discount_price (25.00) is not less than regular_price (25.00)

-- Violates valid_discount: regular_price <= 0
-- INSERT INTO products_catalog (product_id, product_name, regular_price, discount_price) VALUES
-- (104, 'FreeItem', 0, 0);
-- Reason: regular_price must be > 0 and discount_price must be > 0

/* ============================================================================
   Task 1.3: Multiple Column CHECK - bookings
   - num_guests BETWEEN 1 AND 10
   - check_out_date > check_in_date
*/
DROP TABLE IF EXISTS bookings CASCADE;
CREATE TABLE bookings (
                          booking_id     integer PRIMARY KEY,
                          check_in_date  date NOT NULL,
                          check_out_date date NOT NULL,
                          num_guests     integer NOT NULL CHECK (num_guests BETWEEN 1 AND 10),
                          CHECK (check_out_date > check_in_date)  -- ensures checkout is after checkin
);

-- Insert valid rows
INSERT INTO bookings (booking_id, check_in_date, check_out_date, num_guests) VALUES
                                                                                 (201, '2025-10-01', '2025-10-05', 2),
                                                                                 (202, '2025-11-10', '2025-11-12', 1);

-- Invalid inserts (commented)
-- Violates num_guests CHECK (0 guests)
-- INSERT INTO bookings (booking_id, check_in_date, check_out_date, num_guests) VALUES
-- (203, '2025-12-01', '2025-12-02', 0);
-- Reason: num_guests must be between 1 and 10

-- Violates date CHECK (checkout same day or before)
-- INSERT INTO bookings (booking_id, check_in_date, check_out_date, num_guests) VALUES
-- (204, '2025-12-05', '2025-12-05', 2);
-- Reason: check_out_date must be strictly after check_in_date

/* ============================================================================
   Part 2: NOT NULL Constraints
   Task 2.1: customers table
*/
DROP TABLE IF EXISTS customers CASCADE;
CREATE TABLE customers (
                           customer_id       integer NOT NULL PRIMARY KEY, -- NOT NULL & PK
                           email             text NOT NULL,               -- required
                           phone             text,                        -- nullable
                           registration_date date NOT NULL
);

-- Valid inserts
INSERT INTO customers (customer_id, email, phone, registration_date) VALUES
                                                                         (301, 'ak@example.com', '77001234567', '2025-01-10'),
                                                                         (302, 'bob@example.com', NULL, '2025-02-01');  -- phone NULL is allowed

-- Invalid attempts (commented)
-- Violates NOT NULL on email
-- INSERT INTO customers (customer_id, email, phone, registration_date) VALUES
-- (303, NULL, '77001112233', '2025-03-01');
-- Reason: email is NOT NULL

-- Violates NOT NULL on registration_date
-- INSERT INTO customers (customer_id, email, phone, registration_date) VALUES
-- (304, 'c@example.com', '77009998877', NULL);
-- Reason: registration_date is NOT NULL

/* ============================================================================
   Task 2.2: inventory with combined constraints
*/
DROP TABLE IF EXISTS inventory CASCADE;
CREATE TABLE inventory (
                           item_id      integer NOT NULL PRIMARY KEY,
                           item_name    text NOT NULL,
                           quantity     integer NOT NULL CHECK (quantity >= 0), -- non-negative quantity
                           unit_price   numeric NOT NULL CHECK (unit_price > 0), -- unit price > 0
                           last_updated timestamp NOT NULL
);

-- Valid inserts
INSERT INTO inventory (item_id, item_name, quantity, unit_price, last_updated) VALUES
                                                                                   (401, 'Notebook', 50, 2.50, '2025-09-01 10:00:00'),
                                                                                   (402, 'Pen', 200, 0.50, '2025-09-02 11:00:00');

-- Invalid inserts (commented)
-- Violates quantity CHECK (negative)
-- INSERT INTO inventory (item_id, item_name, quantity, unit_price, last_updated) VALUES
-- (403, 'Faulty', -5, 1.00, '2025-09-03 12:00:00');
-- Reason: quantity must be >= 0

-- Violates unit_price CHECK (zero or negative)
-- INSERT INTO inventory (item_id, item_name, quantity, unit_price, last_updated) VALUES
-- (404, 'FreeSample', 10, 0, '2025-09-04 12:00:00');
-- Reason: unit_price must be > 0

/* ============================================================================
   Task 2.3: Testing NOT NULL (examples above cover valid and invalid)
   - Inserted successful records for customers and inventory
   - Invalid attempts shown commented out with reasons
*/

/* ============================================================================
   Part 3: UNIQUE Constraints
   Task 3.1: Single-column UNIQUE - users
*/
DROP TABLE IF EXISTS users CASCADE;
CREATE TABLE users (
                       user_id    integer PRIMARY KEY,
                       username   text UNIQUE,   -- username must be unique
                       email      text UNIQUE,   -- email must be unique
                       created_at timestamp DEFAULT now()
);

-- Valid inserts
INSERT INTO users (user_id, username, email) VALUES
                                                 (501, 'ak123', 'ak@example.com'),
                                                 (502, 'boris', 'boris@example.com');

-- Invalid inserts (violating uniqueness) - commented
-- Violates UNIQUE on username
-- INSERT INTO users (user_id, username, email) VALUES
-- (503, 'ak123', 'other@example.com');
-- Reason: username 'ak123' already exists

-- Violates UNIQUE on email
-- INSERT INTO users (user_id, username, email) VALUES
-- (504, 'newuser', 'ak@example.com');
-- Reason: email 'ak@example.com' already exists

/* ============================================================================
   Task 3.2: Multi-Column UNIQUE - course_enrollments
   Unique(student_id, course_code, semester)
*/
DROP TABLE IF EXISTS course_enrollments CASCADE;
CREATE TABLE course_enrollments (
                                    enrollment_id serial PRIMARY KEY,
                                    student_id    integer NOT NULL,
                                    course_code   text NOT NULL,
                                    semester      text NOT NULL,
                                    enrolled_on   date DEFAULT CURRENT_DATE,
                                    UNIQUE (student_id, course_code, semester)  -- prevents duplicate enrollment same term
);

-- Valid inserts
INSERT INTO course_enrollments (student_id, course_code, semester) VALUES
                                                                       (701, 'CS101', '2025-Fall'),
                                                                       (701, 'CS102', '2025-Fall');

-- Invalid insert (commented)
-- Duplicate triple (student_id, course_code, semester)
-- INSERT INTO course_enrollments (student_id, course_code, semester) VALUES
-- (701, 'CS101', '2025-Fall');
-- Reason: this combination already exists

/* ============================================================================
   Task 3.3: Named UNIQUE Constraints - modify users table to include named constraints
*/
DROP TABLE IF EXISTS users_named CASCADE;
CREATE TABLE users_named (
                             user_id    integer PRIMARY KEY,
                             username   text NOT NULL,
                             email      text NOT NULL,
                             created_at timestamp DEFAULT now(),
                             CONSTRAINT unique_username UNIQUE (username),
                             CONSTRAINT unique_email UNIQUE (email)
);

-- Valid inserts
INSERT INTO users_named (user_id, username, email) VALUES
                                                       (601, 'alex', 'alex@example.com'),
                                                       (602, 'maria', 'maria@example.com');

-- Invalid attempts (commented)
-- Duplicate username
-- INSERT INTO users_named (user_id, username, email) VALUES
-- (603, 'alex', 'alex2@example.com');
-- Reason: constraint unique_username violated

-- Duplicate email
-- INSERT INTO users_named (user_id, username, email) VALUES
-- (604, 'alex2', 'alex@example.com');
-- Reason: constraint unique_email violated

/* ============================================================================
   Part 4: PRIMARY KEY Constraints
   Task 4.1: departments
*/
DROP TABLE IF EXISTS departments CASCADE;
CREATE TABLE departments (
                             dept_id  integer PRIMARY KEY,  -- single-column primary key
                             dept_name text NOT NULL,
                             location  text
);

-- Insert departments (valid)
INSERT INTO departments (dept_id, dept_name, location) VALUES
                                                           (801, 'HR', 'Almaty'),
                                                           (802, 'Engineering', 'Nur-Sultan'),
                                                           (803, 'Sales', 'Shymkent');

-- Invalid attempts (commented)
-- Duplicate dept_id
-- INSERT INTO departments (dept_id, dept_name, location) VALUES
-- (801, 'DuplicateHR', 'Almaty');
-- Reason: violates PRIMARY KEY unique constraint

-- NULL dept_id (commented)
-- INSERT INTO departments (dept_id, dept_name, location) VALUES
-- (NULL, 'NoID', 'Nowhere');
-- Reason: PRIMARY KEY column cannot be NULL

/* ============================================================================
   Task 4.2: Composite Primary Key - student_courses
   PRIMARY KEY (student_id, course_id)
*/
DROP TABLE IF EXISTS student_courses CASCADE;
CREATE TABLE student_courses (
                                 student_id      integer NOT NULL,
                                 course_id       integer NOT NULL,
                                 enrollment_date date,
                                 grade           text,
                                 PRIMARY KEY (student_id, course_id)  -- composite primary key
);

-- Valid inserts
INSERT INTO student_courses (student_id, course_id, enrollment_date, grade) VALUES
                                                                                (901, 1001, '2025-02-01', 'A'),
                                                                                (902, 1002, '2025-03-01', 'B');

-- Attempt to insert duplicate composite PK (commented)
-- INSERT INTO student_courses (student_id, course_id, enrollment_date, grade) VALUES
-- (901, 1001, '2025-04-01', 'A-');
-- Reason: PRIMARY KEY (901,1001) already exists


-- Task 4.3: Comparison Exercise (documented as comments)
-- A PRIMARY KEY is a combination of UNIQUE and NOT NULL properties.
-- This means that each record must have a unique and non-null value in this column.
-- Unlike UNIQUE, a PRIMARY KEY does not allow NULL values.
-- A table can have only one PRIMARY KEY,
-- but it may include multiple UNIQUE constraints.

-- • Single-column PRIMARY KEY:
--   Used when one column is sufficient to uniquely identify each record.
--   Example: dept_id in the departments table.

-- • Composite PRIMARY KEY:
--   Used when a record’s uniqueness depends on a combination of multiple columns.
--   Example: (student_id, course_id) in the student_courses table.

-- The PRIMARY KEY serves as the main identifier of each row,
-- which is why a table can only have one of them.
-- However, you can define multiple UNIQUE constraints
-- to ensure uniqueness in other important columns (such as email or username).


/* ============================================================================
   Part 5: FOREIGN KEY Constraints
   Task 5.1: Basic Foreign Key - employees_dept referencing departments
*/
DROP TABLE IF EXISTS employees_dept CASCADE;
CREATE TABLE employees_dept (
                                emp_id   integer PRIMARY KEY,
                                emp_name text NOT NULL,
                                dept_id  integer REFERENCES departments(dept_id), -- FK to departments
                                hire_date date
);

-- Insert employees with valid dept_id
INSERT INTO employees_dept (emp_id, emp_name, dept_id, hire_date) VALUES
                                                                      (1001, 'Anton', 801, '2024-05-01'),
                                                                      (1002, 'Dilara', 802, '2023-08-15');

-- Invalid insert: non-existent dept_id (commented)
-- INSERT INTO employees_dept (emp_id, emp_name, dept_id, hire_date) VALUES
-- (1003, 'Ghost', 999, '2025-01-01');
-- ERROR: insert or update on table "employees_dept" violates foreign key constraint
-- Reason: dept_id 999 doesn't exist in departments

/* ============================================================================
   Task 5.2: Library schema with multiple foreign keys
*/
DROP TABLE IF EXISTS books CASCADE;
DROP TABLE IF EXISTS authors CASCADE;
DROP TABLE IF EXISTS publishers CASCADE;

CREATE TABLE authors (
                         author_id   integer PRIMARY KEY,
                         author_name text NOT NULL,
                         country     text
);

CREATE TABLE publishers (
                            publisher_id   integer PRIMARY KEY,
                            publisher_name text NOT NULL,
                            city           text
);

CREATE TABLE books (
                       book_id          integer PRIMARY KEY,
                       title            text NOT NULL,
                       author_id        integer REFERENCES authors(author_id),
                       publisher_id     integer REFERENCES publishers(publisher_id),
                       publication_year integer,
                       isbn             text UNIQUE
);

-- Insert sample authors
INSERT INTO authors (author_id, author_name, country) VALUES
                                                          (1101, 'Gabriel Garcia Marquez', 'Colombia'),
                                                          (1102, 'Jane Austen', 'UK'),
                                                          (1103, 'Fyodor Dostoevsky', 'Russia');

-- Insert sample publishers
INSERT INTO publishers (publisher_id, publisher_name, city) VALUES
                                                                (1201, 'Penguin Books', 'London'),
                                                                (1202, 'Vintage', 'New York'),
                                                                (1203, 'KazakhPress', 'Almaty');

-- Insert sample books
INSERT INTO books (book_id, title, author_id, publisher_id, publication_year, isbn) VALUES
                                                                                        (1301, 'One Hundred Years of Solitude', 1101, 1201, 1967, 'ISBN-0001-1111'),
                                                                                        (1302, 'Pride and Prejudice', 1102, 1201, 1813, 'ISBN-0002-2222'),
                                                                                        (1303, 'Crime and Punishment', 1103, 1202, 1866, 'ISBN-0003-3333');

-- Attempt to insert book with non-existent author/publisher (commented)
-- INSERT INTO books (book_id, title, author_id, publisher_id, publication_year, isbn) VALUES
-- (1304, 'Unknown', 1999, 2999, 2020, 'ISBN-0004-4444');
-- Reason: foreign key violation if author_id or publisher_id not present

/* ============================================================================
   Task 5.3: ON DELETE behaviors demonstration
   - categories (PK)
   - products_fk references categories ON DELETE RESTRICT
   - orders (PK)
   - order_items references orders ON DELETE CASCADE
*/
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products_fk CASCADE;
DROP TABLE IF EXISTS categories CASCADE;

CREATE TABLE categories (
                            category_id   integer PRIMARY KEY,
                            category_name text NOT NULL
);

CREATE TABLE products_fk (
                             product_id   integer PRIMARY KEY,
                             product_name text NOT NULL,
                             category_id  integer REFERENCES categories(category_id) ON DELETE RESTRICT
    -- ON DELETE RESTRICT: cannot delete category if products exist referencing it
);

CREATE TABLE orders (
                        order_id  integer PRIMARY KEY,
                        order_date date NOT NULL
);

CREATE TABLE order_items (
                             item_id   integer PRIMARY KEY,
                             order_id  integer REFERENCES orders(order_id) ON DELETE CASCADE,
                             product_id integer REFERENCES products_fk(product_id),
                             quantity  integer CHECK (quantity > 0)
    -- ON DELETE CASCADE: deleting orders will delete related order_items
);

-- Insert categories and products
INSERT INTO categories (category_id, category_name) VALUES
                                                        (1401, 'Electronics'),
                                                        (1402, 'Books');

INSERT INTO products_fk (product_id, product_name, category_id) VALUES
                                                                    (1501, 'Smartphone', 1401),
                                                                    (1502, 'Laptop', 1401),
                                                                    (1503, 'Novel', 1402);

-- Insert an order and items
INSERT INTO orders (order_id, order_date) VALUES
                                              (1601, '2025-10-10'),
                                              (1602, '2025-10-12');

INSERT INTO order_items (item_id, order_id, product_id, quantity) VALUES
                                                                      (1701, 1601, 1501, 1),
                                                                      (1702, 1601, 1503, 2),
                                                                      (1703, 1602, 1502, 1);

-- Tests for ON DELETE behaviors (examples described as comments)
-- 1) Try to delete a category that has products (should fail due to RESTRICT):
-- DELETE FROM categories WHERE category_id = 1401;
-- Result: ERROR - update or delete on table "categories" violates foreign key constraint
-- Reason: products_fk.category_id references categories(1401) with ON DELETE RESTRICT

-- 2) Delete an order and observe order_items deletion (CASCADE):
-- Before: SELECT * FROM order_items WHERE order_id = 1601; -- returns items 1701,1702
-- Execute: DELETE FROM orders WHERE order_id = 1601;
-- After: SELECT * FROM order_items WHERE order_id = 1601; -- returns 0 rows (items removed)
-- Reason: ON DELETE CASCADE removes order_items referencing deleted order row

-- 3) Deleting a product referenced in order_items without specifying ON DELETE:
-- DELETE FROM products_fk WHERE product_id = 1503;
-- If order_items exist referencing 1503, this will fail due to FK constraint (no ON DELETE set)
-- Reason: default is NO ACTION/RESTRICT behavior when not specified

/* ============================================================================
   Part 6: Practical Application - E-commerce Database Design
   Requirements implemented below:
   - customers, products, orders, order_details
   - primary keys, foreign keys with ON DELETE behaviors
   - CHECKs for non-negative price/stock, allowed order statuses, positive order_details quantity
   - UNIQUE constraint on customer email
   - NOT NULL where appropriate
*/

-- Clean up if exists
DROP TABLE IF EXISTS order_details CASCADE;
DROP TABLE IF EXISTS orders_ecom CASCADE;
DROP TABLE IF EXISTS products CASCADE;
-- customers may exist already; drop if so
DROP TABLE IF EXISTS customers_ecom CASCADE;

-- customers table (email unique)
CREATE TABLE customers_ecom (
                                customer_id       integer PRIMARY KEY,
                                name              text NOT NULL,
                                email             text NOT NULL UNIQUE,  -- unique email
                                phone             text,
                                registration_date date NOT NULL
);

-- products table
CREATE TABLE products (
                          product_id     integer PRIMARY KEY,
                          name           text NOT NULL,
                          description    text,
                          price          numeric NOT NULL CHECK (price >= 0),        -- non-negative price
                          stock_quantity integer NOT NULL CHECK (stock_quantity >= 0) -- non-negative stock
);

-- orders table
CREATE TABLE orders_ecom (
                             order_id     integer PRIMARY KEY,
                             customer_id  integer REFERENCES customers_ecom(customer_id) ON DELETE SET NULL,
                             order_date   date NOT NULL,
                             total_amount numeric NOT NULL CHECK (total_amount >= 0),
                             status       text NOT NULL,
                             CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled'))
    -- ON DELETE SET NULL: if customer removed, preserve order but set customer_id NULL
);

-- order_details table
CREATE TABLE order_details (
                               order_detail_id integer PRIMARY KEY,
                               order_id        integer REFERENCES orders_ecom(order_id) ON DELETE CASCADE,
                               product_id      integer REFERENCES products(product_id),
                               quantity        integer NOT NULL CHECK (quantity > 0),
                               unit_price      numeric NOT NULL CHECK (unit_price >= 0)
    -- ON DELETE CASCADE on order: deleting order removes its details
);

-- Insert at least 5 sample records per table (customers, products, orders, order_details)
-- Customers (5)
INSERT INTO customers_ecom (customer_id, name, email, phone, registration_date) VALUES
                                                                                    (2001, 'Akerke', 'akerke@student.edu', '77005551122', '2024-09-01'),
                                                                                    (2002, 'Nursultan', 'nursultan@example.com', '77006662233', '2024-09-10'),
                                                                                    (2003, 'Dana', 'dana@example.com', NULL, '2024-10-05'),
                                                                                    (2004, 'Alim', 'alim@example.com', '77007773344', '2025-01-20'),
                                                                                    (2005, 'Saniya', 'saniya@example.com', '77008884455', '2025-03-03');

-- Products (5)
INSERT INTO products (product_id, name, description, price, stock_quantity) VALUES
                                                                                (3001, 'Wireless Mouse', 'Comfortable wireless mouse', 15.99, 120),
                                                                                (3002, 'Mechanical Keyboard', 'RGB mechanical keyboard', 79.50, 40),
                                                                                (3003, 'USB-C Charger', 'Fast charger 30W', 19.00, 80),
                                                                                (3004, 'Laptop Stand', 'Adjustable aluminum stand', 25.00, 25),
                                                                                (3005, 'Notebook', 'A5 spiral notebook', 2.50, 500);

-- Orders (5)
INSERT INTO orders_ecom (order_id, customer_id, order_date, total_amount, status) VALUES
                                                                                      (4001, 2001, '2025-10-01', 95.49, 'pending'),
                                                                                      (4002, 2002, '2025-09-15', 25.00, 'processing'),
                                                                                      (4003, 2003, '2025-08-20', 19.00, 'shipped'),
                                                                                      (4004, 2004, '2025-07-02', 104.99, 'delivered'),
                                                                                      (4005, 2005, '2025-06-18', 5.00, 'cancelled');

-- Order_details (at least 5 records; can be multiple per order)
INSERT INTO order_details (order_detail_id, order_id, product_id, quantity, unit_price) VALUES
                                                                                            (5001, 4001, 3002, 1, 79.50),  -- mechanical keyboard
                                                                                            (5002, 4001, 3005, 4, 2.50),   -- notebooks
                                                                                            (5003, 4002, 3004, 1, 25.00),  -- laptop stand
                                                                                            (5004, 4003, 3003, 1, 19.00),  -- charger
                                                                                            (5005, 4004, 3001, 1, 15.99);
