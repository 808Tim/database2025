-- Part A
-- Task 1

CREATE TABLE employees (
    emp_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    department VARCHAR(50) DEFAULT 'General',
    salary INTEGER,
    hire_date DATE,
    status VARCHAR(20) DEFAULT 'Active'
);

CREATE TABLE departments (
    dept_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    dept_name VARCHAR(50) UNIQUE NOT NULL,
    budget INTEGER NOT NULL,
    manager_id INTEGER
);

CREATE TABLE projects (
    project_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    project_name VARCHAR(100) NOT NULL,
    dept_id INTEGER REFERENCES departments(dept_id) ON DELETE SET NULL,
    start_date DATE,
    end_date DATE,
    budget INTEGER
);

-- Sample Data

INSERT INTO departments (dept_name, budget, manager_id) VALUES
('IT', 120000, NULL),
('Sales', 90000, NULL),
('HR', 80000, NULL),
('Finance', 150000, NULL),
('R&D', 200000, NULL);

INSERT INTO employees (first_name, last_name, department, salary, hire_date, status) VALUES
('Aida', 'Sultan', 'IT', 70000, DATE '2019-06-01', 'Active'),
('Dias', 'Karim', 'Sales', 55000, DATE '2021-03-15', 'Active'),
('Mira', 'Zhaksy', 'HR', 48000, DATE '2022-11-10', 'Active'),
('Alina', 'Sapar', 'IT', 82000, DATE '2018-05-20', 'Active'),
('Nurs', 'Ulan', 'Finance', 95000, DATE '2017-01-10', 'Active'),
('Emir', 'Emir', 'General', 42000, DATE '2024-02-01', 'Inactive'),
('Aruzhan','Tulep', NULL, NULL, NULL, 'Active');

INSERT INTO projects (project_name, dept_id, start_date, end_date, budget) VALUES
('ERP Upgrade', (SELECT dept_id FROM departments WHERE dept_name='IT'), DATE '2023-01-01', DATE '2023-12-31',  60000),
('Sales Revamp', (SELECT dept_id FROM departments WHERE dept_name='Sales'), DATE '2024-01-01', DATE '2024-09-30',  45000),
('HR Portal', (SELECT dept_id FROM departments WHERE dept_name='HR'), DATE '2022-06-01', DATE '2022-12-01',  30000),
('Risk Engine', (SELECT dept_id FROM departments WHERE dept_name='Finance'), DATE '2021-02-01', DATE '2021-10-01',  80000),
('AI Lab', (SELECT dept_id FROM departments WHERE dept_name='R&D'), DATE '2025-01-01', DATE '2025-12-31', 120000);

-- Part B
-- Task 2

INSERT INTO employees (first_name, last_name, department)
VALUES ('Timur', 'Akyl', 'IT');

-- Task 3

INSERT INTO employees (first_name, last_name, department, salary, status)
VALUES ('Dana', 'Rai', 'Sales', DEFAULT, DEFAULT);

-- Task 4

INSERT INTO departments (dept_name, budget, manager_id) VALUES
('Logistics', 70000, NULL),
('Support', 60000, NULL),
('Legal', 110000, NULL);

-- Task 5

INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Erik', 'Seid', 'HR', CAST(50000 * 1.1 AS INTEGER), CURRENT_DATE, 'Active');

-- Task 6

CREATE TEMP TABLE temp_employees AS
SELECT * FROM employees WHERE department = 'IT';

-- Part C
-- Task 7

UPDATE employees
SET salary = CASE WHEN salary IS NOT NULL THEN CAST(salary * 1.10 AS INTEGER) ELSE NULL END;

-- Task 8

UPDATE employees
SET status = 'Senior'
WHERE salary > 60000
  AND hire_date < DATE '2020-01-01';

-- Task 9

UPDATE employees
SET department = CASE
    WHEN salary > 80000 THEN 'Management'
    WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
    ELSE 'Junior'
END;

-- Task 10

UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

-- Task 11

UPDATE departments d
SET budget = CAST( (SELECT COALESCE(AVG(e.salary), 0) * 1.20 FROM employees e WHERE e.department = d.dept_name) AS INTEGER);

-- Task 12

UPDATE employees
SET salary = CASE WHEN salary IS NOT NULL THEN CAST(salary * 1.15 AS INTEGER) ELSE NULL END,
    status = 'Promoted'
WHERE department = 'Sales';

-- Part D
-- Task 13

DELETE FROM employees
WHERE status = 'Terminated';

-- Task 14

DELETE FROM employees
WHERE salary < 40000
  AND hire_date > DATE '2023-01-01'
  AND department IS NULL;

-- Task 15

DELETE FROM departments d
WHERE d.dept_name NOT IN (
    SELECT DISTINCT e.department
    FROM employees e
    WHERE e.department IS NOT NULL
);

-- Task 16

DELETE FROM projects
WHERE end_date < DATE '2023-01-01'
RETURNING *;



-- Part E
-- Task 17

INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Nulla', 'Void', NULL, NULL, NULL, 'Active');

-- Task 18

UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

-- Task 19

DELETE FROM employees
WHERE salary IS NULL OR department IS NULL;

-- Part F
-- Task 20

WITH ins AS (
  INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
  VALUES ('Bella','Khan','IT', 60000, CURRENT_DATE, 'Active')
  RETURNING emp_id, first_name || ' ' || last_name AS full_name
)
SELECT * FROM ins;

-- Task 21

UPDATE employees
SET salary = salary + 5000
WHERE department = 'IT'
RETURNING emp_id, salary - 5000 AS old_salary, salary AS new_salary;

-- Task 22

DELETE FROM employees
WHERE hire_date < DATE '2020-01-01'
RETURNING *;

-- Part G
-- Task 23

INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
SELECT 'Osman', 'Ait', 'Finance', 72000, CURRENT_DATE, 'Active'
WHERE NOT EXISTS (
    SELECT 1 FROM employees WHERE first_name='Osman' AND last_name='Ait'
);

-- Task 24

UPDATE employees e
SET salary = CASE
    WHEN (SELECT budget FROM departments d WHERE d.dept_name = e.department) > 100000
         THEN CAST(e.salary * 1.10 AS INTEGER)
    ELSE CAST(e.salary * 1.05 AS INTEGER)
END
WHERE e.salary IS NOT NULL;

-- Task 25

WITH inserted AS (
    INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
    VALUES
      ('Aruz', 'Bek', 'Sales', 50000, CURRENT_DATE, 'Active'),
      ('Lina', 'Omar', 'Sales', 52000, CURRENT_DATE, 'Active'),
      ('Peter','Jin',  'IT',    65000, CURRENT_DATE, 'Active'),
      ('Ilia', 'Kim',  'HR',    47000, CURRENT_DATE, 'Active'),
      ('Aida', 'Nur',  'Finance',73000, CURRENT_DATE, 'Active')
    RETURNING emp_id
)
UPDATE employees e
SET salary = CAST(e.salary * 1.10 AS INTEGER)
WHERE e.emp_id IN (SELECT emp_id FROM inserted);

-- Task 26

DROP TABLE IF EXISTS employee_archive;
CREATE TABLE employee_archive AS
SELECT * FROM employees WHERE false;

INSERT INTO employee_archive SELECT * FROM employees WHERE status = 'Inactive';
DELETE FROM employees WHERE status = 'Inactive';

-- Task 27

UPDATE projects p
SET end_date = COALESCE(p.end_date, CURRENT_DATE) + INTERVAL '30 days'
WHERE p.budget > 50000
  AND (
        SELECT COUNT(*)
        FROM employees e
        JOIN departments d ON d.dept_name = e.department
        WHERE d.dept_id = p.dept_id
      ) > 3;
