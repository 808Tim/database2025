-- Part 1
-- Create tables

CREATE TABLE departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location VARCHAR(50)
);

CREATE TABLE employees (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(100),
    dept_id INT,
    salary DECIMAL(10,2),
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

CREATE TABLE projects (
    proj_id INT PRIMARY KEY,
    proj_name VARCHAR(100),
    budget DECIMAL(12,2),
    dept_id INT,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

-- Insert sample data

INSERT INTO departments VALUES 
(101, 'IT', 'Building A'),
(102, 'HR', 'Building B'),
(103, 'Operations', 'Building C');

INSERT INTO employees VALUES
(1, 'John Smith', 101, 50000),
(2, 'Jane Doe', 101, 55000),
(3, 'Mike Johnson', 102, 48000),
(4, 'Sarah Williams', 102, 52000),
(5, 'Tom Brown', 103, 60000);

INSERT INTO projects VALUES
(201, 'Website Redesign', 75000, 101),
(202, 'Database Migration', 120000, 101),
(203, 'HR System Upgrade', 50000, 102);

-- Part 2
-- Task 2.1

CREATE INDEX emp_salary_idx ON employees(salary);

SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'employees';

-- Question:
-- How many indexes exist on the employees table? 
-- Answer:
-- 2 indexes at this stage:
-- 1) employees_pkey (created automatically for PRIMARY KEY emp_id)
-- 2) emp_salary_idx (created explicitly on salary).


-- Task 2.2

CREATE INDEX emp_dept_idx ON employees(dept_id);
SELECT * FROM employees WHERE dept_id = 101;

-- Question:
-- Why is it beneficial to index foreign key columns?
-- Answer:
-- Indexing foreign key columns speeds up:
-- JOIN operations with the referenced (parent) table,
-- lookups and filters by the foreign key value,
-- enforcement of referential integrity during UPDATE/DELETE
-- on the parent table.


-- Task 2.3

SELECT 
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- Question:
-- List all the indexes you see. Which ones were created automatically?
-- Answer:
-- Automatically created:
--   departments_pkey (PRIMARY KEY on departments.dept_id)
--   employees_pkey (PRIMARY KEY on employees.emp_id)
--   projects_pkey (PRIMARY KEY on projects.proj_id)
-- Explicitly created by us:
--   emp_salary_idx
--   emp_dept_idx

-- Part 3
-- Task 3.1

CREATE INDEX emp_dept_salary_idx ON employees(dept_id, salary);

SELECT emp_name, salary 
FROM employees 
WHERE dept_id = 101 AND salary > 52000;

-- Question:
-- Would this index be useful for a query that only filters by salary (without dept_id)?
-- Why or why not?
-- Answer:
-- It would not be very useful for a query that filters only by salary,
-- because the leading column of the index is dept_id.
-- The index is primarily effective for conditions that include dept_id
-- (optionally with additional conditions on salary).


-- Task 3.2

CREATE INDEX emp_salary_dept_idx ON employees(salary, dept_id);


SELECT * FROM employees WHERE dept_id = 102 AND salary > 50000;
SELECT * FROM employees WHERE salary > 50000 AND dept_id = 102;

-- Question:
-- Does the order of columns in a multicolumn index matter? Explain.
-- Answer:
-- Yes, order matters.
-- A multicolumn index is most efficient for conditions that start with
-- the leftmost columns of the index definition.
-- For emp_salary_dept_idx (salary, dept_id), filters that start with 
-- salary benefit more directly than those that only specify dept_id.


-- Part 4
-- Task 4.1

ALTER TABLE employees ADD COLUMN email VARCHAR(100);

UPDATE employees SET email = 'john.smith@company.com'  WHERE emp_id = 1;
UPDATE employees SET email = 'jane.doe@company.com'    WHERE emp_id = 2;
UPDATE employees SET email = 'mike.johnson@company.com' WHERE emp_id = 3;
UPDATE employees SET email = 'sarah.williams@company.com' WHERE emp_id = 4;
UPDATE employees SET email = 'tom.brown@company.com'   WHERE emp_id = 5;

CREATE UNIQUE INDEX emp_email_unique_idx ON employees(email);

INSERT INTO employees (emp_id, emp_name, dept_id, salary, email)
VALUES (6, 'New Employee', 101, 55000, 'john.smith@company.com');

-- Question:
-- What error message did you receive?
-- Answer:
-- ERROR: duplicate key value violates unique constraint "emp_email_unique_idx"
-- DETAIL: Key "(email)=(john.smith@company.com)" already exists.


-- Task 4.2

ALTER TABLE employees ADD COLUMN phone VARCHAR(20) UNIQUE;

SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'employees' AND indexname LIKE '%phone%';

-- Question:
-- Did PostgreSQL automatically create an index? What type of index?
-- Answer:
-- Yes. PostgreSQL automatically created a unique B-tree index
-- for the UNIQUE constraint on employees.phone (typically named employees_phone_key).

-- Part 5
-- Task 5.1

CREATE INDEX emp_salary_desc_idx ON employees(salary DESC);

SELECT emp_name, salary 
FROM employees 
ORDER BY salary DESC;

-- Question:
-- How does this index help with ORDER BY queries?
-- Answer:
-- PostgreSQL can use the emp_salary_desc_idx to read rows already
-- ordered by salary in descending order, avoiding an extra sort step
-- and improving performance for ORDER BY salary DESC.

-- Task 5.2

CREATE INDEX proj_budget_nulls_first_idx ON projects(budget NULLS FIRST);

SELECT proj_name, budget 
FROM projects 
ORDER BY budget NULLS FIRST;

-- Part 6
-- Task 6.1

CREATE INDEX emp_name_lower_idx ON employees(LOWER(emp_name));

SELECT * FROM employees WHERE LOWER(emp_name) = 'john smith';

-- Question:
-- Without this index, how would PostgreSQL search for names case-insensitively?
-- Answer:
-- Without this expression index, PostgreSQL would perform a sequential scan
-- over the employees table and apply LOWER(emp_name) to every row to compare
-- with the given value.

-- Task 6.2

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

-- Part 7
-- Task 7.1

ALTER INDEX emp_salary_idx RENAME TO employees_salary_index;

SELECT indexname FROM pg_indexes WHERE tablename = 'employees';


-- Task 7.2

DROP INDEX emp_salary_dept_idx;

-- Question:
-- Why might you want to drop an index?
-- Answer:
-- Because every index:
-- consumes disk space;
-- slows down INSERT/UPDATE/DELETE operations;
-- may never be used by queries.
-- Dropping unused or redundant indexes reduces overhead.

-- Task 7.3

REINDEX INDEX employees_salary_index;

-- Question:
-- When is REINDEX useful?
-- Answer:
-- REINDEX is useful:
-- After bulk INSERT operations,
-- When an index becomes bloated or fragmented,
-- After major data modifications,
-- In some cases after database upgrades or corruption issues.

-- Part 8
-- Task 8.1

SELECT e.emp_name, e.salary, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 50000
ORDER BY e.salary DESC;

CREATE INDEX emp_salary_filter_idx ON employees(salary) WHERE salary > 50000;

-- Task 8.2

CREATE INDEX proj_high_budget_idx ON projects(budget) 
WHERE budget > 80000;

SELECT proj_name, budget 
FROM projects 
WHERE budget > 80000;

-- Question:
-- What's the advantage of a partial index compared to a regular index?
-- Answer:
-- A partial index:
-- is smaller (only stores rows that match the WHERE condition);
-- uses less disk space;
-- can be faster to scan for queries that use the same condition;
-- reduces maintenance overhead compared to a full-table index.

-- Task 8.3

EXPLAIN SELECT * FROM employees WHERE salary > 52000;

-- Question:
-- Does the output show an "Index Scan" or a "Seq Scan" (Sequential Scan)?
-- What does this tell you?
-- Answer:
-- If EXPLAIN shows "Index Scan", PostgreSQL is using an index
-- to satisfy the condition (e.g. on salary).
-- If it shows "Seq Scan", PostgreSQL is scanning the whole table,
-- which usually means it decided the index is not beneficial
-- (for example on very small tables or when many rows match).

-- Part 9
-- Task 9.1

CREATE INDEX dept_name_hash_idx ON departments USING HASH (dept_name);

SELECT * FROM departments WHERE dept_name = 'IT';

-- Question:
-- When should you use a HASH index instead of a B-tree index?
-- Answer:
-- HASH indexes are suitable for simple equality comparisons
-- on columns where
-- only equality is needed (no range searches)
-- and exact matches are frequent.
-- B-tree is more general and usually preferred, but HASH can be
-- useful for specific equality-heavy workloads.

-- Task 9.2

CREATE INDEX proj_name_btree_idx ON projects(proj_name);
CREATE INDEX proj_name_hash_idx ON projects USING HASH (proj_name);

SELECT * FROM projects WHERE proj_name = 'Website Redesign';
SELECT * FROM projects WHERE proj_name > 'Database';

-- Part 10
-- Task 10.1

SELECT 
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexname::regclass)) AS index_size
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- Question:
-- Which index is the largest? Why?
-- Answer:
-- The largest index will typically be:
-- on the table with the most rows,
-- and/or containing multiple columns or expression data.
-- In this lab, indexes on employees (e.g. multicolumn or expression indexes) 
-- are expected to be larger than those on smaller tables.
-- The exact result should be checked from the query output.

-- Task 10.2

DROP INDEX IF EXISTS proj_name_hash_idx;

-- Task 10.3

CREATE VIEW index_documentation AS
SELECT 
    tablename,
    indexname,
    indexdef,
    'Improves salary-based queries' AS purpose
FROM pg_indexes
WHERE schemaname = 'public' 
  AND indexname LIKE '%salary%';

SELECT * FROM index_documentation;

-- Summary questions:

-- 1. What is the default index type in PostgreSQL?
-- Answer:
-- B-tree is the default index type in PostgreSQL.

-- 2. Name three scenarios where you should create an index:
-- Answer:
-- A column is frequently used in WHERE conditions.
-- A column is used in JOIN conditions (foreign keys, primary keys).
-- A column is often used in ORDER BY or GROUP BY clauses.

-- 3. Name two scenarios where you should NOT create an index:
-- Answer:
-- On columns that are rarely used in search conditions or joins.
-- On columns that are updated extremely frequently (to avoid overhead).

-- 4. What happens to indexes when you INSERT, UPDATE, or DELETE data?
-- Answer:
-- PostgreSQL must update all relevant indexes:
-- INSERT: new index entries are added.
-- UPDATE: affected index entries may be modified.
-- DELETE: index entries for deleted rows are removed.
-- This extra work is why many indexes can slow down write operations.

-- 5. How can you check if a query is using an index?
-- Answer:
-- Use EXPLAIN or EXPLAIN ANALYZE before the query.
-- If the plan shows "Index Scan" (or "Bitmap Index Scan"),
-- the index is being used. If it shows "Seq Scan", it is not.