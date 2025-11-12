-- Part 2
-- Task 2.1

CREATE VIEW employee_details AS
SELECT e.emp_id,
       e.emp_name,
       e.salary,
       d.dept_name,
       d.location
FROM employees e
JOIN departments d ON d.dept_id = e.dept_id;

-- Task 2.2

CREATE VIEW dept_statistics AS
SELECT d.dept_id,
       d.dept_name,
       COALESCE(COUNT(e.emp_id), 0) AS employee_count,
       ROUND(AVG(e.salary)::numeric, 2) AS avg_salary,
       MAX(e.salary) AS max_salary,
       MIN(e.salary) AS min_salary
FROM departments d
LEFT JOIN employees e ON e.dept_id = d.dept_id
GROUP BY d.dept_id, d.dept_name;

-- Task 2.3

CREATE VIEW project_overview AS
SELECT p.project_id,
       p.project_name,
       p.budget,
       d.dept_name,
       d.location,
       COALESCE(ds.employee_count, 0) AS team_size
FROM projects p
JOIN departments d ON d.dept_id = p.dept_id
LEFT JOIN (
    SELECT e.dept_id, COUNT(*) AS employee_count
    FROM employees e
    GROUP BY e.dept_id
) ds ON ds.dept_id = d.dept_id;

-- Task 2.4

CREATE VIEW high_earners AS
SELECT e.emp_name,
       e.salary,
       d.dept_name
FROM employees e
JOIN departments d ON d.dept_id = e.dept_id
WHERE e.salary > 55000;

-- Part 3
-- Task 3.1

REPLACE VIEW employee_details AS
SELECT e.emp_id,
       e.emp_name,
       e.salary,
       d.dept_name,
       d.location,
       CASE
         WHEN e.salary > 60000 THEN 'High'
         WHEN e.salary > 50000 THEN 'Medium'
         ELSE 'Standard'
       END AS salary_grade
FROM employees e
JOIN departments d ON d.dept_id = e.dept_id;

-- Task 3.2

ALTER VIEW high_earners RENAME TO top_performers;

-- Task 3.3

CREATE VIEW temp_view AS
SELECT emp_id, emp_name, salary
FROM employees
WHERE salary < 50000;

DROP VIEW temp_view;

-- Part 4
-- Task 4.1

CREATE VIEW employee_salaries AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees;

-- Task 4.2

UPDATE employee_salaries
SET salary = 52000
WHERE emp_name = 'John Smith'

-- Task 4.3

INSERT INTO employee_salaries (emp_id, emp_name, dept_id, salary)
VALUES (6, 'Alice Johnson', 102, 58000);

-- Task 4.4

DROP VIEW IF EXISTS it_employees;
CREATE VIEW it_employees AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees
WHERE dept_id = 101
WITH LOCAL CHECK OPTION;

-- Part 5
-- Task 5.1

CREATE MATERIALIZED VIEW dept_summary_mv AS
SELECT d.dept_id,
       d.dept_name,
       COALESCE(COUNT(e.emp_id), 0) AS total_employees,
       COALESCE(SUM(e.salary), 0) AS total_salaries,
       COALESCE(COUNT(DISTINCT p.project_id), 0) AS total_projects,
       COALESCE(SUM(p.budget), 0) AS total_project_budget
FROM departments d
LEFT JOIN employees e ON e.dept_id = d.dept_id
LEFT JOIN projects  p ON p.dept_id = d.dept_id
GROUP BY d.dept_id, d.dept_name
WITH DATA;

-- Task 5.2

INSERT INTO employees (emp_id, emp_name, dept_id, salary)
VALUES (8, 'Charlie Brown', 101, 54000);

-- Before update

SELECT * FROM dept_summary_mv WHERE dept_id = 101;

-- After update

REFRESH MATERIALIZED VIEW dept_summary_mv;
SELECT * FROM dept_summary_mv WHERE dept_id = 101;

-- Task 5.3

CREATE UNIQUE INDEX idx_dept_summary_mv_dept_id
ON dept_summary_mv(dept_id);

REFRESH MATERIALIZED VIEW CONCURRENTLY dept_summary_mv;

-- Task 5.4

CREATE MATERIALIZED VIEW project_stats_mv AS
SELECT 
    p.project_name,
    p.budget,
    d.dept_name,
    COUNT(e.emp_id) AS assigned_employees
FROM projects p
JOIN departments d ON d.dept_id = p.dept_id
LEFT JOIN employees e ON e.dept_id = d.dept_id
GROUP BY p.project_name, p.budget, d.dept_name
WITH NO DATA;

-- Part 6
-- Task 6.1

CREATE ROLE analyst;
CREATE ROLE data_viewer WITH LOGIN PASSWORD 'viewer123';
CREATE ROLE report_user WITH LOGIN PASSWORD 'report456';

-- Task 6.2

CREATE ROLE user_manager LOGIN createrole PASSWORD 'manager101';
CREATE ROLE db_creator LOGIN createdb PASSWORD 'creator789';
CREATE ROLE admin_user LOGIN superuser PASSWORD 'admin999';

-- Task 6.3

GRANT SELECT ON employees, departments, projects TO analyst;
GRANT ALL PRIVILEGES ON TABLE employee_details TO data_viewer;
GRANT SELECT, INSERT ON employees TO report_user;

-- Task 6.4

CREATE ROLE hr_team;
CREATE ROLE finance_team;
CREATE ROLE it_team;

CREATE ROLE hr_user1 LOGIN PASSWORD 'hr001';
CREATE ROLE hr_user2 LOGIN PASSWORD 'hr002';
CREATE ROLE finance_user1 LOGIN PASSWORD 'fin001';


GRANT hr_team TO hr_user1, hr_user2;
GRANT finance_team TO finance_user1;

GRANT SELECT, UPDATE ON employees TO hr_team;
GRANT SELECT ON dept_statistics TO finance_team;

-- Task 6.5

REVOKE UPDATE ON employees FROM hr_team;
REVOKE hr_team FROM hr_user2;
REVOKE ALL PRIVILEGES ON TABLE employee_details FROM data_viewer;

-- Task 6.6

ALTER ROLE analyst LOGIN PASSWORD 'analyst123';
ALTER ROLE user_manager SUPERUSER;
ALTER ROLE analyst PASSWORD NULL;
ALTER ROLE data_viewer CONNECTION LIMIT 5;

-- Part 7
-- Task 7.1

CREATE ROLE read_only;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO read_only;

CREATE ROLE junior_analyst LOGIN PASSWORD 'junior123';
CREATE ROLE senior_analyst LOGIN PASSWORD 'senior123';

GRANT read_only TO junior_analyst, senior_analyst;
GRANT INSERT, UPDATE ON employees TO senior_analyst;

-- Task 7.2

CREATE ROLE project_manager LOGIN PASSWORD 'pm123';

ALTER VIEW dept_statistics OWNER TO project_manager;
ALTER TABLE projects OWNER TO project_manager;

-- Task 7.3

CREATE ROLE temp_owner LOGIN;

CREATE TABLE temp_table (id INT);

ALTER TABLE temp_table OWNER TO temp_owner;

REASSIGN OWNED BY temp_owner TO postgres;
DROP OWNED BY temp_owner;
DROP ROLE temp_owner;

-- Task 7.4

CREATE VIEW hr_employee_view AS
SELECT *
FROM employees
WHERE dept_id = 102;

GRANT SELECT ON hr_employee_view TO hr_team;

CREATE VIEW finance_employee_view AS
SELECT emp_id, emp_name, salary
FROM employees;

GRANT SELECT ON finance_employee_view TO finance_team;

-- Part 8
-- Task 8.1

CREATE VIEW dept_dashboard AS
SELECT 
    d.dept_id,
    d.dept_name,
    d.location,
    COUNT(e.emp_id) AS employee_count,
    ROUND(AVG(e.salary), 2) AS avg_salary,
    COUNT(p.project_id) AS active_projects,
    SUM(p.budget) AS total_project_budget,
    ROUND(SUM(p.budget) / NULLIF(COUNT(e.emp_id), 0), 2) AS budget_per_employee
FROM departments d
LEFT JOIN employees e ON e.dept_id = d.dept_id
LEFT JOIN projects p  ON p.dept_id = d.dept_id
GROUP BY d.dept_id, d.dept_name, d.location;

-- Task 8.2

ALTER TABLE projects ADD COLUMN created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

CREATE VIEW high_budget_projects AS
SELECT p.project_name,
       p.budget,
       d.dept_name,
       p.created_date,
       CASE
         WHEN p.budget > 150000 THEN 'Critical Review Required'
         WHEN p.budget > 100000 THEN 'Management Approval Needed'
         ELSE 'Standard Process'
       END AS approval_status
FROM projects p
JOIN departments d ON d.dept_id = p.dept_id
WHERE p.budget > 75000;

-- Task 8.3

CREATE ROLE viewer_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public to viewer_role;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public to viewer_role;

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

GRANT viewer_role  TO alice;
GRANT analyst_role TO bob;
GRANT manager_role TO charlie;