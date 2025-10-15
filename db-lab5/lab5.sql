-- Ivanov Timur 24B030257

-- Part 1
-- Task 1.1

CREATE TABLE employees (
    employee_id INT,
    first_name TEXT,
    last_name TEXT,
    age INT CHECK (age BETWEEN 18 AND 65),
    salary NUMERIC CHECK (salary > 0)
);

-- Task 1.2

CREATE TABLE products_catalog (
    product_id INT,
    product_name TEXT,
    regular_price NUMERIC,
    discount_price NUMERIC,
    CONSTRAINT valid_discount CHECK (
        regular_price > 0 AND
        discount_price > 0 AND
        discount_price < regular_price
    )
);

-- Task 1.3

CREATE TABLE bookings (
    booking_id INT,
    check_in_date DATE,
    check_out_date DATE,
    num_guests INT CHECK (num_guests BETWEEN 1 AND 10),
    CHECK (check_out_date > check_in_date)
);

-- Task 1.4

INSERT INTO employees VALUES (1, 'Timur', 'Ivanov', 19, 5000); -- Successful
INSERT INTO employees VALUES (2, 'Aibek', 'Kuralbayev', 30, 3000); -- Successful

INSERT INTO employees VALUES (3, 'Nikita', 'Li', 17, 1000); -- Failed
INSERT INTO employees VALUES (4, 'Alikhan', 'Askarov', 20, -100); -- Failed

INSERT INTO products_catalog VALUES (1, 'Laptop', 1500, 1200); -- Successful
INSERT INTO products_catalog VALUES (2, 'Phone', 1000, 800); -- Successful

INSERT INTO products_catalog VALUES (3, 'Headphones', 0, 100); -- Failed
INSERT INTO products_catalog VALUES (4, 'Monitor', 700, 900); -- Failed

INSERT INTO bookings VALUES (1, '2025-05-01', '2025-05-05', 2); -- Successful
INSERT INTO bookings VALUES (2, '2025-06-10', '2025-06-15', 4); -- Successful

INSERT INTO bookings VALUES (3, '2025-07-01', '2025-06-30', 3); -- Failed
INSERT INTO bookings VALUES (4, '2025-08-01', '2025-08-01', 0); -- Failed

-- Part 2
-- Task 2.1

CREATE TABLE customers (
    customer_id INT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);

-- Task 2.2

CREATE TABLE inventory (
    item_id INT NOT NULL,
    item_name TEXT NOT NULL,
    quantity INT NOT NULL CHECK (quantity >= 0),
    unit_price NUMERIC NOT NULL CHECK (unit_price > 0),
    last_updated TIMESTAMP NOT NULL
);

-- Task 2.3

INSERT INTO customers VALUES (1, 'a@example.com', '1234567', '2025-01-01'); -- Successful
INSERT INTO customers VALUES (2, 'b@example.com', NULL, '2025-02-01'); -- Successful

INSERT INTO customers VALUES (3, NULL, '999999', '2025-03-01'); -- Failed

INSERT INTO inventory VALUES (1, 'Mouse', 10, 15.5, NOW()); -- Successful
INSERT INTO inventory VALUES (2, 'Keyboard', 20, 25.5, NOW()); -- Successful

INSERT INTO inventory VALUES (3, 'Monitor', -1, 300, NOW()); -- Failed

-- Part 3
-- Task 3.1

CREATE TABLE users (
    user_id INT,
    username TEXT UNIQUE,
    email TEXT UNIQUE,
    created_at TIMESTAMP
);

-- Task 3.2

CREATE TABLE course_enrollments (
    enrollment_id INT,
    student_id INT,
    course_code TEXT,
    semester TEXT,
    UNIQUE (student_id, course_code, semester)
);

-- Task 3.3

ALTER TABLE users
ADD CONSTRAINT unique_username UNIQUE (username),
ADD CONSTRAINT unique_email UNIQUE (email);

INSERT INTO users VALUES (1, 'user1', 'u1@mail.com', NOW()); -- Successful
INSERT INTO users VALUES (2, 'user2', 'u2@mail.com', NOW()); -- Successful

INSERT INTO users VALUES (3, 'user1', 'u3@mail.com', NOW()); -- Failed

-- Part 4
-- Task 4.1

CREATE TABLE departments (
    dept_id INT PRIMARY KEY,
    dept_name TEXT NOT NULL,
    location TEXT
);

-- Task 4.2

INSERT INTO departments VALUES (1, 'HR', 'Almaty'); -- Successful
INSERT INTO departments VALUES (2, 'IT', 'Astana'); -- Successful
INSERT INTO departments VALUES (3, 'Finance', 'Shymkent'); -- Successful

INSERT INTO departments VALUES (1, 'Admin', 'Atyrau'); -- Failed
INSERT INTO departments VALUES (NULL, 'Legal', 'Almaty'); -- Failed

-- Task 4.3

CREATE TABLE student_courses (
    student_id INT,
    course_id INT,
    enrollment_date DATE,
    grade TEXT,
    PRIMARY KEY (student_id, course_id)
);

-- Part 5
-- Task 5.1

CREATE TABLE employees_dept (
    emp_id INT PRIMARY KEY,
    emp_name TEXT NOT NULL,
    dept_id INT REFERENCES departments(dept_id),
    hire_date DATE
);

INSERT INTO employees_dept VALUES (1, 'Askar Askarov', 1, '2025-01-10'); -- Successful
INSERT INTO employees_dept VALUES (2, 'Alan Zhunisbayev', 2, '2025-02-12'); -- Successful

INSERT INTO employees_dept VALUES (3, 'Dmitriy Kim', 5, '2025-03-15'); -- Failed

-- Task 5.2

CREATE TABLE authors (
    author_id INT PRIMARY KEY,
    author_name TEXT NOT NULL,
    country TEXT
);

CREATE TABLE publishers (
    publisher_id INT PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city TEXT
);

CREATE TABLE books (
    book_id INT PRIMARY KEY,
    title TEXT NOT NULL,
    author_id INT REFERENCES authors(author_id),
    publisher_id INT REFERENCES publishers(publisher_id),
    publication_year INT,
    isbn TEXT UNIQUE
);

INSERT INTO authors VALUES (1, 'Stephen King', 'USA');
INSERT INTO authors VALUES (2, 'George Orwell', 'UK');

INSERT INTO publishers VALUES (1, 'Penguin', 'London');
INSERT INTO publishers VALUES (2, 'Random House', 'New York');

INSERT INTO books VALUES (1, '1984', 2, 1, 1949, '9780451524935');
INSERT INTO books VALUES (2, 'IT', 1, 2, 1986, '9781501142970');

-- Task 5.3

CREATE TABLE categories (
    category_id INT PRIMARY KEY,
    category_name TEXT NOT NULL
);

CREATE TABLE products_fk (
    product_id INT PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id INT REFERENCES categories(category_id) ON DELETE RESTRICT
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    order_date DATE NOT NULL
);

CREATE TABLE order_items (
    item_id INT PRIMARY KEY,
    order_id INT REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INT REFERENCES products_fk(product_id),
    quantity INT CHECK (quantity > 0)
);

-- Part 6
-- Task 6.1

CREATE TABLE customers_ecom (
    customer_id INT PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);

INSERT INTO customers_ecom VALUES (1, 'Timur Ivanov', 'tim@mail.com', '12345', '2025-01-01');
INSERT INTO customers_ecom VALUES (2, 'Aidos Zhanabekov', 'aidos@mail.com', '67890', '2025-02-01');
INSERT INTO customers_ecom VALUES (3, 'Aldiyar', 'aldik@mail.com', '99999', '2025-03-01');
INSERT INTO customers_ecom VALUES (4, 'Aruzhan', 'aru@mail.com', '77777', '2025-04-01');
INSERT INTO customers_ecom VALUES (5, 'Tamerlan', 'tamer@mail.com', '11111', '2025-05-01');

CREATE TABLE products_ecom (
    product_id INT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC CHECK (price >= 0),
    stock_quantity INT CHECK (stock_quantity >= 0)
);

INSERT INTO products_ecom VALUES (1, 'Laptop', 'Gaming laptop', 1500, 10);
INSERT INTO products_ecom VALUES (2, 'Phone', 'Smartphone', 800, 20);
INSERT INTO products_ecom VALUES (3, 'Headphones', 'Wireless headphones', 200, 15);
INSERT INTO products_ecom VALUES (4, 'Mouse', 'Wireless mouse', 50, 50);
INSERT INTO products_ecom VALUES (5, 'Keyboard', 'Mechanical keyboard', 120, 30);

CREATE TABLE orders_ecom (
    order_id INT PRIMARY KEY,
    customer_id INT REFERENCES customers_ecom(customer_id) ON DELETE CASCADE,
    order_date DATE NOT NULL,
    total_amount NUMERIC,
    status TEXT CHECK (status IN ('pending','processing','shipped','delivered','cancelled'))
);

INSERT INTO orders_ecom VALUES (1, 1, '2025-06-01', 2000, 'pending');
INSERT INTO orders_ecom VALUES (2, 2, '2025-06-05', 850, 'processing');
INSERT INTO orders_ecom VALUES (3, 3, '2025-06-10', 220, 'shipped');
INSERT INTO orders_ecom VALUES (4, 4, '2025-06-15', 170, 'delivered');
INSERT INTO orders_ecom VALUES (5, 5, '2025-06-20', 1600, 'cancelled');

CREATE TABLE order_details_ecom (
    order_detail_id INT PRIMARY KEY,
    order_id INT REFERENCES orders_ecom(order_id) ON DELETE CASCADE,
    product_id INT REFERENCES products_ecom(product_id),
    quantity INT CHECK (quantity > 0),
    unit_price NUMERIC
);

INSERT INTO order_details_ecom VALUES (1, 1, 1, 1, 1500);
INSERT INTO order_details_ecom VALUES (2, 1, 3, 1, 200);
INSERT INTO order_details_ecom VALUES (3, 2, 2, 1, 800);
INSERT INTO order_details_ecom VALUES (4, 3, 4, 2, 50);
INSERT INTO order_details_ecom VALUES (5, 5, 1, 1, 1500);