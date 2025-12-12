-- Creating tables ----------------------------

CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    iin CHAR(12) UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    status TEXT NOT NULL CHECK (status IN ('active', 'blocked', 'frozen')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    daily_limit_kzt NUMERIC(18,2) NOT NULL
);

CREATE TABLE accounts (
    account_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(customer_id),
    account_number TEXT UNIQUE NOT NULL,
    currency TEXT NOT NULL CHECK (currency IN ('KZT','USD','EUR','RUB')),
    balance NUMERIC(18,2) NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    opened_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    closed_at TIMESTAMPTZ
);

CREATE TABLE transactions (
    transaction_id SERIAL PRIMARY KEY,
    from_account_id INT REFERENCES accounts(account_id),
    to_account_id INT REFERENCES accounts(account_id),
    type TEXT NOT NULL CHECK (type IN ('transfer','deposit','withdrawal')),
    status TEXT NOT NULL CHECK (status IN ('pending','completed','failed','reversed')),
    amount NUMERIC(18,2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    description TEXT
);

CREATE TABLE exchange_rates (
    rate_id SERIAL PRIMARY KEY,
    from_currency TEXT NOT NULL,
    to_currency TEXT NOT NULL,
    rate NUMERIC(18,6) NOT NULL,
    valid_from TIMESTAMPTZ NOT NULL,
    valid_to TIMESTAMPTZ
);

CREATE TABLE audit_log (
  log_id SERIAL PRIMARY KEY,
  table_name TEXT NOT NULL,
  record_id INT,
  action TEXT NOT NULL CHECK (action IN ('INSERT','UPDATE','DELETE')),
  old_values JSONB,
  new_values JSONB,
  changed_by TEXT,
  changed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  ip_address INET
);

-- Inserting data --------------------------------------------

INSERT INTO customers(iin, full_name, phone, email, status, daily_limit_kzt) VALUES
('000000000001','Aruzhan A.','+77010000001','aruzhan@example.com','active', 1000000),
('000000000002','Bolat B.','+77010000002','bolat@example.com','active', 500000),
('000000000003','Timur I.','+77010000003','timur@example.com','active', 3000000),
('000000000004','Dana D.','+77010000004','dana@example.com','blocked', 200000),
('000000000005','Erlan E.','+77010000005','erlan@example.com','frozen', 2000000),
('000000000006','Andrey A.','+77010000006','andrey@example.com','frozen', 100000),
('000000000007','Nikita L.','+77010000007','nikita@example.com','blocked', 200000),
('000000000008','Erzhan U.','+77010000008','erzhan@example.com','active', 300000),
('000000000009','Dmitriy D.','+77010000009','dima@example.com','active', 2000000),
('000000000010','Arsen K.','+77010000010','arsen@example.com','frozen', 1000000);

INSERT INTO accounts (customer_id, account_number, currency, balance, is_active) VALUES
-- 1. Aruzhan A. (active)
(1, 'KZ-0001-KZT', 'KZT', 800000, TRUE),
(1, 'KZ-0001-USD', 'USD', 1500, TRUE),

-- 2. Bolat B. (active)
(2, 'KZ-0002-KZT', 'KZT', 300000, TRUE),

-- 3. Timur I. (active)
(3, 'KZ-0003-KZT', 'KZT', 2000000, TRUE),
(3, 'KZ-0003-EUR', 'EUR', 1200, TRUE),

-- 4. Dana D. (blocked)
(4, 'KZ-0004-KZT', 'KZT', 150000, TRUE),

-- 5. Erlan E. (frozen)
(5, 'KZ-0005-KZT', 'KZT', 1800000, TRUE),
(5, 'KZ-0005-USD', 'USD', 800, TRUE),

-- 6. Andrey A. (frozen)
(6, 'KZ-0006-KZT', 'KZT', 90000, TRUE),

-- 7. Nikita L. (blocked)
(7, 'KZ-0007-KZT', 'KZT', 160000, TRUE),

-- 8. Erzhan U. (active)
(8, 'KZ-0008-KZT', 'KZT', 250000, TRUE),

-- 9. Dmitriy D. (active)
(9, 'KZ-0009-KZT', 'KZT', 1700000, TRUE),
(9, 'KZ-0009-USD', 'USD', 2200, TRUE),

-- 10. Arsen K. (frozen)
(10,'KZ-0010-KZT', 'KZT', 950000, TRUE);

INSERT INTO exchange_rates(from_currency,to_currency,rate,valid_from,valid_to) 
VALUES
    ('KZT','KZT',1.0,        now() - interval '1 day', NULL),
    ('USD','KZT',500.000000, now() - interval '1 day', NULL),
    ('EUR','KZT',540.000000, now() - interval '1 day', NULL),
    ('RUB','KZT',5.200000,   now() - interval '1 day', NULL),

    ('KZT','USD',0.002000,   now() - interval '1 day', NULL),
    ('KZT','EUR',0.001852,   now() - interval '1 day', NULL),
    ('KZT','RUB',0.192308,   now() - interval '1 day', NULL);

INSERT INTO transactions
(from_account_id, to_account_id, type, status, amount, created_at, completed_at, description)
VALUES
-- 1
(1, 3, 'transfer', 'completed', 20000, now() - interval '3 hours', now() - interval '3 hours', 'Payment 1'),
-- 2
(3, 1, 'transfer', 'completed', 15000, now() - interval '2 hours 30 minutes', now() - interval '2 hours 30 minutes', 'Payment 2'),
-- 3
(2, 1, 'transfer', 'completed', 5000, now() - interval '2 hours', now() - interval '2 hours', 'Payment 3'),
-- 4
(1, 2, 'transfer', 'completed', 10000, now() - interval '1 hour 45 minutes', now() - interval '1 hour 45 minutes', 'Payment 4'),
-- 5
(4, 1, 'transfer', 'failed', 8000, now() - interval '1 hour 30 minutes', NULL, 'Blocked customer'),
-- 6
(5, 1, 'transfer', 'failed', 12000, now() - interval '1 hour 15 minutes', NULL, 'Frozen customer'),
-- 7
(3, 2, 'transfer', 'completed', 25000, now() - interval '1 hour', now() - interval '1 hour', 'Payment 5'),
-- 8
(8, 1, 'transfer', 'completed', 7000, now() - interval '45 minutes', now() - interval '45 minutes', 'Payment 6'),
-- 9
(9, 1, 'transfer', 'completed', 30000, now() - interval '30 minutes', now() - interval '30 minutes', 'Payment 7'),
-- 10
(2, 3, 'transfer', 'completed', 9000, now() - interval '15 minutes', now() - interval '15 minutes', 'Payment 8');

INSERT INTO audit_log
(table_name, record_id, action, old_values, new_values, changed_by, ip_address)
VALUES
-- 1
('transactions', 1, 'INSERT', NULL,
 to_jsonb((SELECT t FROM transactions t WHERE transaction_id = 1)),
 'system', inet '127.0.0.1'),

-- 2
('transactions', 2, 'INSERT', NULL,
 to_jsonb((SELECT t FROM transactions t WHERE transaction_id = 2)),
 'system', inet '127.0.0.1'),

-- 3
('transactions', 3, 'INSERT', NULL,
 to_jsonb((SELECT t FROM transactions t WHERE transaction_id = 3)),
 'system', inet '127.0.0.1'),

-- 4
('transactions', 4, 'INSERT', NULL,
 to_jsonb((SELECT t FROM transactions t WHERE transaction_id = 4)),
 'system', inet '127.0.0.1'),

-- 5
('transactions', 5, 'INSERT', NULL,
 to_jsonb((SELECT t FROM transactions t WHERE transaction_id = 5)),
 'system', inet '127.0.0.1'),

-- 6
('transactions', 6, 'INSERT', NULL,
 to_jsonb((SELECT t FROM transactions t WHERE transaction_id = 6)),
 'system', inet '127.0.0.1'),

-- 7
('transactions', 7, 'INSERT', NULL,
 to_jsonb((SELECT t FROM transactions t WHERE transaction_id = 7)),
 'system', inet '127.0.0.1'),

-- 8
('transactions', 8, 'INSERT', NULL,
 to_jsonb((SELECT t FROM transactions t WHERE transaction_id = 8)),
 'system', inet '127.0.0.1'),

-- 9
('transactions', 9, 'INSERT', NULL,
 to_jsonb((SELECT t FROM transactions t WHERE transaction_id = 9)),
 'system', inet '127.0.0.1'),

-- 10
('transactions', 10, 'INSERT', NULL,
 to_jsonb((SELECT t FROM transactions t WHERE transaction_id = 10)),
 'system', inet '127.0.0.1');

-- Task 1 --------------------------------------

CREATE FUNCTION process_transfer(
  p_from_account_number TEXT,
  p_to_account_number TEXT,
  p_amount NUMERIC,
  p_currency TEXT,
  p_description TEXT
) RETURNS JSONB AS $$
DECLARE
  v_from_acc accounts;
  v_to_acc accounts;
  v_sender customers;

  v_tx_id INT;

  v_rate_from NUMERIC(18,6);
  v_rate_to NUMERIC(18,6);

  v_amount_from_cur NUMERIC(18,2);
  v_amount_to_cur NUMERIC(18,2);

  v_transfer_kzt NUMERIC(18,2);
  v_today_kzt NUMERIC(18,2);

  v_now TIMESTAMPTZ := now();
BEGIN
  IF p_amount IS NULL OR p_amount <= 0 THEN
    INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, changed_by, ip_address)
    VALUES (
      'transactions', NULL, 'INSERT', NULL,
      jsonb_build_object(
        'event','transfer_attempt','status','failed','error_code','INVALID_AMOUNT',
        'from',p_from_account_number,'to',p_to_account_number,'amount',p_amount,'currency',p_currency,'description',p_description
      ),
      current_user, inet_client_addr()
    );
    RETURN jsonb_build_object('success', false, 'error_code', 'INVALID_AMOUNT', 'message', 'Amount must be greater than 0');
  END IF;

  SELECT * INTO v_from_acc
  FROM accounts
  WHERE account_number = p_from_account_number
  FOR UPDATE;

  SELECT * INTO v_to_acc
  FROM accounts
  WHERE account_number = p_to_account_number
  FOR UPDATE;

  IF v_from_acc.account_id IS NULL OR v_to_acc.account_id IS NULL THEN
    INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, changed_by, ip_address)
    VALUES (
      'transactions', NULL, 'INSERT', NULL,
      jsonb_build_object(
        'event','transfer_attempt','status','failed','error_code','ACCOUNT_NOT_FOUND',
        'from',p_from_account_number,'to',p_to_account_number
      ),
      current_user, inet_client_addr()
    );
    RETURN jsonb_build_object('success', false, 'error_code', 'ACCOUNT_NOT_FOUND', 'message', 'One or both accounts do not exist');
  END IF;

  IF v_from_acc.is_active IS FALSE OR v_to_acc.is_active IS FALSE THEN
    INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, changed_by, ip_address)
    VALUES (
      'transactions', NULL, 'INSERT', NULL,
      jsonb_build_object(
        'event','transfer_attempt','status','failed','error_code','ACCOUNT_INACTIVE',
        'from_account_id',v_from_acc.account_id,'to_account_id',v_to_acc.account_id
      ),
      current_user, inet_client_addr()
    );
    RETURN jsonb_build_object('success', false, 'error_code', 'ACCOUNT_INACTIVE', 'message', 'One or both accounts are inactive');
  END IF;

  SELECT * INTO v_sender
  FROM customers
  WHERE customer_id = v_from_acc.customer_id;

  IF v_sender.customer_id IS NULL THEN
    INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, changed_by, ip_address)
    VALUES (
      'transactions', NULL, 'INSERT', NULL,
      jsonb_build_object(
        'event','transfer_attempt','status','failed','error_code','SENDER_CUSTOMER_NOT_FOUND',
        'from_account_id',v_from_acc.account_id
      ),
      current_user, inet_client_addr()
    );
    RETURN jsonb_build_object('success', false, 'error_code', 'SENDER_CUSTOMER_NOT_FOUND', 'message', 'Sender customer not found');
  END IF;

  IF v_sender.status <> 'active' THEN
    INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, changed_by, ip_address)
    VALUES (
      'transactions', NULL, 'INSERT', NULL,
      jsonb_build_object(
        'event','transfer_attempt','status','failed','error_code','SENDER_NOT_ACTIVE',
        'customer_id',v_sender.customer_id,'customer_status',v_sender.status
      ),
      current_user, inet_client_addr()
    );
    RETURN jsonb_build_object('success', false, 'error_code', 'SENDER_NOT_ACTIVE', 'message', 'Sender customer is not active (blocked/frozen)');
  END IF;

  IF p_currency = v_from_acc.currency THEN
    v_amount_from_cur := round(p_amount, 2);
  ELSE
    SELECT rate INTO v_rate_from
    FROM exchange_rates
    WHERE from_currency = p_currency
      AND to_currency = v_from_acc.currency
      AND valid_from <= v_now
      AND (valid_to IS NULL OR valid_to >= v_now)
    ORDER BY valid_from DESC
    LIMIT 1;

    IF v_rate_from IS NULL THEN
      INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, changed_by, ip_address)
      VALUES (
        'transactions', NULL, 'INSERT', NULL,
        jsonb_build_object('event','transfer_attempt','status','failed','error_code','FX_RATE_NOT_FOUND',
                           'from_currency',p_currency,'to_currency',v_from_acc.currency),
        current_user, inet_client_addr()
      );
      RETURN jsonb_build_object('success', false, 'error_code', 'FX_RATE_NOT_FOUND', 'message', 'Exchange rate not found for input -> source currency');
    END IF;

    v_amount_from_cur := round(p_amount * v_rate_from, 2);
  END IF;

  IF p_currency = v_to_acc.currency THEN
    v_amount_to_cur := round(p_amount, 2);
  ELSE
    SELECT rate INTO v_rate_to
    FROM exchange_rates
    WHERE from_currency = p_currency
      AND to_currency = v_to_acc.currency
      AND valid_from <= v_now
      AND (valid_to IS NULL OR valid_to >= v_now)
    ORDER BY valid_from DESC
    LIMIT 1;

    IF v_rate_to IS NULL THEN
      INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, changed_by, ip_address)
      VALUES (
        'transactions', NULL, 'INSERT', NULL,
        jsonb_build_object('event','transfer_attempt','status','failed','error_code','FX_RATE_NOT_FOUND',
                           'from_currency',p_currency,'to_currency',v_to_acc.currency),
        current_user, inet_client_addr()
      );
      RETURN jsonb_build_object('success', false, 'error_code', 'FX_RATE_NOT_FOUND', 'message', 'Exchange rate not found for input -> destination currency');
    END IF;

    v_amount_to_cur := round(p_amount * v_rate_to, 2);
  END IF;

  IF v_from_acc.balance < v_amount_from_cur THEN
    INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, changed_by, ip_address)
    VALUES (
      'transactions', NULL, 'INSERT', NULL,
      jsonb_build_object('event','transfer_attempt','status','failed','error_code','INSUFFICIENT_FUNDS',
                         'from_account_id',v_from_acc.account_id,'balance',v_from_acc.balance,'required',v_amount_from_cur),
      current_user, inet_client_addr()
    );
    RETURN jsonb_build_object('success', false, 'error_code', 'INSUFFICIENT_FUNDS', 'message', 'Insufficient balance in source account');
  END IF;

  IF p_currency = 'KZT' THEN
    v_transfer_kzt := round(p_amount, 2);
  ELSE
    SELECT rate INTO v_rate_from
    FROM exchange_rates
    WHERE from_currency = p_currency
      AND to_currency = 'KZT'
      AND valid_from <= v_now
      AND (valid_to IS NULL OR valid_to >= v_now)
    ORDER BY valid_from DESC
    LIMIT 1;

    IF v_rate_from IS NULL THEN
      INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, changed_by, ip_address)
      VALUES (
        'transactions', NULL, 'INSERT', NULL,
        jsonb_build_object('event','transfer_attempt','status','failed','error_code','FX_RATE_NOT_FOUND',
                           'from_currency',p_currency,'to_currency','KZT'),
        current_user, inet_client_addr()
      );
      RETURN jsonb_build_object('success', false, 'error_code', 'FX_RATE_NOT_FOUND', 'message', 'Exchange rate not found for input -> KZT (limit check)');
    END IF;

    v_transfer_kzt := round(p_amount * v_rate_from, 2);
  END IF;

  SELECT COALESCE(SUM(
    CASE
      WHEN a.currency = 'KZT' THEN t.amount
      ELSE round(t.amount * (
        SELECT rate
        FROM exchange_rates r
        WHERE r.from_currency = a.currency
          AND r.to_currency   = 'KZT'
          AND r.valid_from <= t.created_at
          AND (r.valid_to IS NULL OR r.valid_to >= t.created_at)
        ORDER BY r.valid_from DESC
        LIMIT 1
      ), 2)
    END
  ), 0)
  INTO v_today_kzt
  FROM transactions t
  JOIN accounts a ON a.account_id = t.from_account_id
  WHERE a.customer_id = v_sender.customer_id
    AND t.type='transfer'
    AND t.status='completed'
    AND t.created_at::date = CURRENT_DATE;

  IF v_today_kzt + v_transfer_kzt > v_sender.daily_limit_kzt THEN
    INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, changed_by, ip_address)
    VALUES (
      'transactions', NULL, 'INSERT', NULL,
      jsonb_build_object('event','transfer_attempt','status','failed','error_code','DAILY_LIMIT_EXCEEDED',
                         'today_kzt',v_today_kzt,'transfer_kzt',v_transfer_kzt,'limit_kzt',v_sender.daily_limit_kzt),
      current_user, inet_client_addr()
    );
    RETURN jsonb_build_object('success', false, 'error_code', 'DAILY_LIMIT_EXCEEDED', 'message', 'Daily transaction limit exceeded');
  END IF;

  INSERT INTO transactions(from_account_id,to_account_id,type,status,amount,created_at,description)
  VALUES (v_from_acc.account_id, v_to_acc.account_id, 'transfer', 'pending', round(p_amount,2), v_now, p_description)
  RETURNING transaction_id INTO v_tx_id;

  BEGIN
    UPDATE accounts
    SET balance = balance - v_amount_from_cur
    WHERE account_id = v_from_acc.account_id;

    UPDATE accounts
    SET balance = balance + v_amount_to_cur
    WHERE account_id = v_to_acc.account_id;

    UPDATE transactions
    SET status='completed', completed_at=now()
    WHERE transaction_id = v_tx_id;

  EXCEPTION
    WHEN OTHERS THEN
      UPDATE transactions
      SET status='failed'
      WHERE transaction_id = v_tx_id;

      INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, changed_by, ip_address)
      VALUES (
        'transactions', v_tx_id, 'UPDATE', NULL,
        jsonb_build_object('event','transfer','status','failed','error_code','INTERNAL_ERROR','message',SQLERRM),
        current_user, inet_client_addr()
      );

      RETURN jsonb_build_object('success', false, 'error_code', 'INTERNAL_ERROR', 'message', SQLERRM, 'transaction_id', v_tx_id);
  END;

  INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, changed_by, ip_address)
  VALUES (
    'transactions', v_tx_id, 'UPDATE', NULL,
    jsonb_build_object(
      'event','transfer','status','completed',
      'from_account_id',v_from_acc.account_id,'to_account_id',v_to_acc.account_id,
      'amount',round(p_amount,2),'currency',p_currency
    ),
    current_user, inet_client_addr()
  );

  RETURN jsonb_build_object('success', true, 'error_code', NULL, 'message', 'Transfer completed', 'transaction_id', v_tx_id);
END;
$$ LANGUAGE plpgsql;

-- Test cases --------------------------------

SELECT process_transfer('KZ-0001-KZT','KZ-0002-KZT', 5000, 'KZT', 'SUCCESS_KZT');
-- Success

SELECT process_transfer('KZ-0001-USD','KZ-0003-KZT', 10, 'USD', 'SUCCESS_FX_USD');
-- Success

SELECT process_transfer('NO-ACC','KZ-0002-KZT', 1000, 'KZT', 
    'FAIL_ACCOUNT_NOT_FOUND');
-- Fail: {"message": "One or both accounts do not exist", 
-- "success": false, "error_code": "ACCOUNT_NOT_FOUND"}

SELECT process_transfer('KZ-0004-KZT','KZ-0002-KZT', 1000, 'KZT',
    'FAIL_SENDER_BLOCKED');
-- Fail: {"message": "Sender customer is not active (blocked/frozen)",
-- "success": false, "error_code": "SENDER_NOT_ACTIVE"}

SELECT process_transfer('KZ-0005-KZT','KZ-0002-KZT', 1000, 'KZT',
    'FAIL_SENDER_FROZEN');
-- Fail: {"message": "Sender customer is not active (blocked/frozen)",
-- "success": false, "error_code": "SENDER_NOT_ACTIVE"}

SELECT process_transfer('KZ-0002-KZT','KZ-0001-KZT', 
    999999999, 'KZT', 'FAIL_INSUFFICIENT_FUNDS');
-- Fail: {"message": "Insufficient balance in source account", 
-- "success": false, "error_code": "INSUFFICIENT_FUNDS"}

SELECT process_transfer('KZ-0002-KZT','KZ-0001-KZT', 600000, 'KZT', 
    'FAIL_DAILY_LIMIT');
-- Fail: {"message": "Insufficient balance in source account", 
-- "success": false, "error_code": "INSUFFICIENT_FUNDS"}

SELECT process_transfer('KZ-0001-KZT','KZ-0002-KZT', -10, 'KZT', 
    'FAIL_INVALID_AMOUNT');
-- Fail: {"message": "Amount must be greater than 0", 
-- "success": false, "error_code": "INVALID_AMOUNT"}

SELECT process_transfer('KZ-0001-KZT','KZ-0002-KZT', 100, 'GBP',
    'FAIL_FX_RATE_NOT_FOUND');
-- Fail: {"message": "Exchange rate not found for input -> source currency",
-- "success": false, "error_code": "FX_RATE_NOT_FOUND"}

SELECT process_transfer('KZ-0003-KZT','KZ-0001-KZT', 25000, 'KZT', 'SUCCESS_SECOND');
-- Success

SELECT transaction_id, status, amount, created_at
FROM transactions
ORDER BY transaction_id DESC
LIMIT 10;

SELECT *
FROM audit_log
ORDER BY changed_at DESC
LIMIT 10;

-- Task 2 ---------------------------------------------

-- View 1 -----------------------------------------------

CREATE VIEW customer_balance_summary AS
WITH account_balances AS (
    SELECT
        c.customer_id,
        c.full_name,
        c.daily_limit_kzt,
        a.account_id,
        a.account_number,
        a.currency,
        a.balance,
        CASE
            WHEN a.currency = 'KZT' THEN a.balance
            ELSE a.balance * (
                SELECT r.rate
                FROM exchange_rates r
                WHERE r.from_currency = a.currency
                  AND r.to_currency = 'KZT'
                  AND r.valid_from <= now()
                  AND (r.valid_to IS NULL OR r.valid_to >= now())
                ORDER BY r.valid_from DESC
                LIMIT 1
            )
        END AS balance_kzt
    FROM customers c
    JOIN accounts a ON a.customer_id = c.customer_id
),
total_per_customer AS (
    SELECT
        customer_id,
        SUM(balance_kzt) AS total_balance_kzt
    FROM account_balances
    GROUP BY customer_id
),
today_usage AS (
    SELECT
        c.customer_id,
        COALESCE(SUM(
            CASE
                WHEN a.currency = 'KZT' THEN t.amount
                ELSE t.amount * (
                    SELECT r.rate
                    FROM exchange_rates r
                    WHERE r.from_currency = a.currency
                      AND r.to_currency = 'KZT'
                      AND r.valid_from <= t.created_at
                      AND (r.valid_to IS NULL OR r.valid_to >= t.created_at)
                    ORDER BY r.valid_from DESC
                    LIMIT 1
                )
            END
        ), 0) AS today_spent_kzt
    FROM customers c
    JOIN accounts a ON a.customer_id = c.customer_id
    LEFT JOIN transactions t
      ON t.from_account_id = a.account_id
     AND t.status = 'completed'
     AND t.created_at::date = CURRENT_DATE
    GROUP BY c.customer_id
)
SELECT
    ab.customer_id,
    ab.full_name,
    ab.account_number,
    ab.currency,
    ab.balance,
    tpc.total_balance_kzt,
    ab.daily_limit_kzt,
    tu.today_spent_kzt,
    ROUND(100.0 * tu.today_spent_kzt / ab.daily_limit_kzt, 2) AS daily_limit_utilization_pct,
    RANK() OVER (ORDER BY tpc.total_balance_kzt DESC) AS balance_rank
FROM account_balances ab
JOIN total_per_customer tpc ON tpc.customer_id = ab.customer_id
JOIN today_usage tu ON tu.customer_id = ab.customer_id;

-- View 2 ------------------------------------------

CREATE VIEW daily_transaction_report AS
WITH daily_agg AS (
    SELECT
        created_at::date AS tx_date,
        type,
        SUM(amount) AS total_volume,
        COUNT(*) AS tx_count,
        AVG(amount) AS avg_amount
    FROM transactions
    WHERE status = 'completed'
    GROUP BY created_at::date, type
)
SELECT
    tx_date,
    type,
    total_volume,
    tx_count,
    avg_amount,
    SUM(total_volume) OVER (ORDER BY tx_date) AS running_total_volume,
    ROUND(
        100.0 * (total_volume - LAG(total_volume) OVER (ORDER BY tx_date))
        / NULLIF(LAG(total_volume) OVER (ORDER BY tx_date), 0), 2
    ) AS day_over_day_growth_pct
FROM daily_agg
ORDER BY tx_date;

-- View 3 -----------------------------------------

CREATE VIEW suspicious_activity_view
WITH (security_barrier = true)
AS
WITH base AS (
    SELECT
        t.transaction_id,
        t.from_account_id,
        a.customer_id,
        t.amount,
        t.created_at,
        CASE
            WHEN a.currency = 'KZT' THEN t.amount
            ELSE t.amount * (
                SELECT r.rate
                FROM exchange_rates r
                WHERE r.from_currency = a.currency
                  AND r.to_currency = 'KZT'
                  AND r.valid_from <= t.created_at
                  AND (r.valid_to IS NULL OR r.valid_to >= t.created_at)
                ORDER BY r.valid_from DESC
                LIMIT 1
            )
        END AS amount_kzt
    FROM transactions t
    JOIN accounts a ON a.account_id = t.from_account_id
    WHERE t.status = 'completed'
),
hourly_freq AS (
    SELECT
        customer_id,
        date_trunc('hour', created_at) AS hour_bucket,
        COUNT(*) AS tx_count
    FROM base
    GROUP BY customer_id, hour_bucket
),
rapid_seq AS (
    SELECT
        transaction_id
    FROM (
        SELECT
            transaction_id,
            from_account_id,
            created_at,
            LAG(created_at) OVER (
                PARTITION BY from_account_id
                ORDER BY created_at
            ) AS prev_time
        FROM transactions
        WHERE status = 'completed'
    ) s
    WHERE prev_time IS NOT NULL
      AND created_at - prev_time < INTERVAL '1 minute'
)
SELECT
    b.transaction_id,
    b.customer_id,
    b.from_account_id,
    b.amount,
    b.amount_kzt,
    b.created_at,
    (b.amount_kzt > 5000000) AS is_large_transfer,
    (hf.tx_count > 10) AS is_high_frequency,
    (b.transaction_id IN (SELECT transaction_id FROM rapid_seq)) AS is_rapid_sequence
FROM base b
LEFT JOIN hourly_freq hf
    ON hf.customer_id = b.customer_id
    AND hf.hour_bucket = date_trunc('hour', b.created_at);

-- Task 3 -------------------------------

CREATE INDEX idx_customers_iin_btree
ON customers USING btree (iin);

CREATE INDEX idx_accounts_active_partial
ON accounts (account_number)
WHERE is_active = true;

CREATE INDEX idx_customers_email_lower_expr
ON customers (LOWER(email));

CREATE INDEX idx_audit_log_jsonb_gin
ON audit_log USING gin (new_values);

CREATE INDEX idx_transactions_from_created_composite
ON transactions (from_account_id, created_at);

CREATE INDEX idx_accounts_currency_hash
ON accounts USING hash (currency);

CREATE INDEX idx_transactions_frequent_covering
ON transactions (from_account_id, created_at)
INCLUDE (status, type, amount, to_account_id);

-- Test --------------------------------

EXPLAIN ANALYZE
SELECT *
FROM audit_log
WHERE new_values @> '{"status":"failed"}'::jsonb;
-- Seq Scan -> Seq Scan
-- Before: Planning Time: 0.108 ms --- Execution Time: 0.071 ms
-- After: Planning Time: 0.122 ms --- Execution Time: 0.048 ms

EXPLAIN ANALYZE
SELECT *
FROM customers
WHERE LOWER(email) = LOWER('aruzhan@example.com');
-- Seq Scan -> Seq Scan
-- Before: Planning Time: 1.264 ms --- Execution Time: 0.052 ms
-- After: Planning Time: 0.367 ms --- Execution Time: 0.094 ms

EXPLAIN ANALYZE
SELECT *
FROM accounts
WHERE is_active = true
AND account_number = 'KZ-0001-KZT';
-- Seq Scan -> Seq Scan
-- Before: Planning Time: 0.569 ms --- Execution Time: 0.047 ms
-- After: Planning Time: 0.642 ms --- Execution Time: 0.042 ms

EXPLAIN ANALYZE
SELECT transaction_id, created_at, amount
FROM transactions
WHERE from_account_id = 1
  AND created_at >= now() - interval '30 days'
ORDER BY created_at DESC
LIMIT 50;
-- Seq Scan -> Seq Scan
-- Before: Planning Time: 0.165 ms --- Execution Time: 0.098 ms
-- After: Planning Time: 0.212 ms --- Execution Time: 0.072 ms

EXPLAIN ANALYZE
SELECT *
FROM accounts
WHERE currency = 'KZT';
-- Seq Scan -> Seq Scan
-- Before: Planning Time: 0.170 ms --- Execution Time: 0.120 ms
-- After: Planning Time: 0.125 ms --- Execution Time: 0.045 ms

-- Task 4

CREATE TABLE IF NOT EXISTS salary_batch_log (
  batch_id SERIAL PRIMARY KEY,
  company_account_id INT NOT NULL REFERENCES accounts(account_id),
  successful_count INT NOT NULL,
  failed_count INT NOT NULL,
  failed_details JSONB NOT NULL,
  total_amount_kzt NUMERIC(18,2) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Conversion function -------------------------

CREATE FUNCTION fx_convert(
  p_amount NUMERIC,
  p_from_currency TEXT,
  p_to_currency TEXT,
  p_at_time TIMESTAMPTZ
) RETURNS NUMERIC AS $$
DECLARE
  v_rate NUMERIC;
BEGIN
  IF p_from_currency = p_to_currency THEN
    RETURN ROUND(p_amount, 2);
  END IF;

  SELECT rate
  INTO v_rate
  FROM exchange_rates
  WHERE from_currency = p_from_currency
    AND to_currency   = p_to_currency
    AND valid_from <= p_at_time
    AND (valid_to IS NULL OR valid_to >= p_at_time)
  ORDER BY valid_from DESC
  LIMIT 1;

  IF v_rate IS NULL THEN
    RAISE EXCEPTION 'FX rate not found: % -> %', p_from_currency, p_to_currency;
  END IF;

  RETURN ROUND(p_amount * v_rate, 2);
END;
$$ LANGUAGE plpgsql;

--------------------------------------

CREATE FUNCTION process_salary_batch(
  p_company_account_number TEXT,
  p_payments JSONB
) RETURNS JSONB AS $$
DECLARE
  v_company_acc accounts;
  v_company_lock BIGINT;

  v_total_kzt NUMERIC(18,2) := 0;
  v_success INT := 0;
  v_fail INT := 0;
  v_failed_details JSONB := '[]'::jsonb;

  rec JSONB;
  v_iin TEXT;
  v_amount NUMERIC(18,2);
  v_desc TEXT;

  v_recipient_customer_id INT;
  v_recipient_acc_id INT;

  v_success_total_kzt NUMERIC(18,2);
  v_debit_company_cur NUMERIC(18,2);

  v_now TIMESTAMPTZ := now();
BEGIN
  IF jsonb_typeof(p_payments) <> 'array' THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'INVALID_PAYMENTS_JSON', 'message', 'payments must be JSONB array');
  END IF;

  SELECT * INTO v_company_acc
  FROM accounts
  WHERE account_number = p_company_account_number
  FOR UPDATE;

  IF v_company_acc.account_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'COMPANY_ACCOUNT_NOT_FOUND', 'message', 'Company account not found');
  END IF;

  IF v_company_acc.is_active IS FALSE THEN
    RETURN jsonb_build_object('success', false, 'error_code', 'COMPANY_ACCOUNT_INACTIVE', 'message', 'Company account inactive');
  END IF;

  v_company_lock := hashtext(p_company_account_number);
  PERFORM pg_advisory_lock(v_company_lock);

  FOR rec IN SELECT * FROM jsonb_array_elements(p_payments)
  LOOP
    v_amount := NULLIF(rec->>'amount','')::numeric;

    IF v_amount IS NULL OR v_amount <= 0 THEN
      v_fail := v_fail + 1;
      v_failed_details := v_failed_details || jsonb_build_object(
        'iin', rec->>'iin',
        'amount', rec->>'amount',
        'error_code', 'INVALID_AMOUNT',
        'message', 'Amount must be > 0'
      );
    ELSE
      v_total_kzt := v_total_kzt + v_amount;
    END IF;
  END LOOP;

  IF fx_convert(v_company_acc.balance, v_company_acc.currency, 'KZT', v_now) < v_total_kzt THEN
    PERFORM pg_advisory_unlock(v_company_lock);
    RETURN jsonb_build_object('success', false, 'error_code', 'COMPANY_INSUFFICIENT_FUNDS', 'message', 'Not enough balance for total batch');
  END IF;

  CREATE TEMP TABLE tmp_salary_accum (
    recipient_account_id INT PRIMARY KEY,
    amount_kzt NUMERIC(18,2) NOT NULL
  ) ON COMMIT DROP;

  FOR rec IN SELECT * FROM jsonb_array_elements(p_payments)
  LOOP
    v_iin  := rec->>'iin';
    v_amount := NULLIF(rec->>'amount','')::numeric;
    v_desc := rec->>'description';

    IF v_amount IS NULL OR v_amount <= 0 THEN
      CONTINUE;
    END IF;

    BEGIN
      SELECT customer_id INTO v_recipient_customer_id
      FROM customers
      WHERE iin = v_iin;

      IF v_recipient_customer_id IS NULL THEN
        RAISE EXCEPTION 'Recipient not found' USING ERRCODE='PSB01';
      END IF;

      IF (SELECT status FROM customers WHERE customer_id = v_recipient_customer_id) <> 'active' THEN
        RAISE EXCEPTION 'Recipient not active' USING ERRCODE='PSB02';
      END IF;

      SELECT account_id INTO v_recipient_acc_id
      FROM accounts
      WHERE customer_id = v_recipient_customer_id
        AND currency = 'KZT'
        AND is_active = true
      LIMIT 1;

      IF v_recipient_acc_id IS NULL THEN
        RAISE EXCEPTION 'Recipient KZT account not found' USING ERRCODE='PSB03';
      END IF;

      INSERT INTO tmp_salary_accum(recipient_account_id, amount_kzt)
      VALUES (v_recipient_acc_id, v_amount)
      ON CONFLICT (recipient_account_id)
      DO UPDATE SET amount_kzt = tmp_salary_accum.amount_kzt + EXCLUDED.amount_kzt;

      INSERT INTO transactions(from_account_id, to_account_id, type, status, amount, created_at, description)
      VALUES (v_company_acc.account_id, v_recipient_acc_id, 'transfer', 'pending', v_amount, v_now, v_desc);

      v_success := v_success + 1;

    EXCEPTION
      WHEN OTHERS THEN
        v_fail := v_fail + 1;
        v_failed_details := v_failed_details || jsonb_build_object(
          'iin', v_iin,
          'amount', v_amount,
          'error_code', SQLSTATE,
          'message', SQLERRM
        );
    END;
  END LOOP;

  SELECT COALESCE(SUM(amount_kzt),0) INTO v_success_total_kzt
  FROM tmp_salary_accum;

  v_debit_company_cur := fx_convert(v_success_total_kzt, 'KZT', v_company_acc.currency, v_now);

  UPDATE accounts
  SET balance = balance - v_debit_company_cur
  WHERE account_id = v_company_acc.account_id;

  UPDATE accounts a
  SET balance = a.balance + t.amount_kzt
  FROM tmp_salary_accum t
  WHERE a.account_id = t.recipient_account_id;

  UPDATE transactions tr
  SET status = 'completed',
      completed_at = v_now
  FROM tmp_salary_accum t
  WHERE tr.status = 'pending'
    AND tr.from_account_id = v_company_acc.account_id
    AND tr.to_account_id = t.recipient_account_id
    AND tr.created_at = v_now;

  INSERT INTO salary_batch_log(company_account_id, successful_count, failed_count, failed_details, total_amount_kzt)
  VALUES (v_company_acc.account_id, v_success, v_fail, v_failed_details, v_total_kzt);

  PERFORM pg_advisory_unlock(v_company_lock);

  RETURN jsonb_build_object(
    'success', true,
    'successful_count', v_success,
    'failed_count', v_fail,
    'failed_details', v_failed_details
  );
END;
$$ LANGUAGE plpgsql;

CREATE MATERIALIZED VIEW salary_batch_summary AS
SELECT
  l.batch_id,
  a.account_number AS company_account_number,
  l.total_amount_kzt,
  l.successful_count,
  l.failed_count,
  l.created_at
FROM salary_batch_log l
JOIN accounts a ON a.account_id = l.company_account_id
ORDER BY l.created_at DESC;

-- Test -----------------------------------

SELECT process_salary_batch(
  'KZ-0003-KZT',
  '[
    {"iin":"000000000001","amount":50000,"description":"Salary A"},
    {"iin":"000000000002","amount":70000,"description":"Salary B"},
    {"iin":"000000000099","amount":10000,"description":"Unknown iin"},
    {"iin":"000000000003","amount":-5,"description":"Bad amount"}
  ]'::jsonb
);

-- Result:
-- {"success": true,
-- "failed_count": 2,
-- "failed_details":
-- [{"iin": "000000000003",
-- "amount": "-5", "message":
-- "Amount must be > 0",
-- "error_code": "INVALID_AMOUNT"},
-- {"iin": "000000000099",
-- "amount": 10000.00,
-- "message": "Recipient not found",
-- "error_code": "PSB01"}],
-- "successful_count": 2}

REFRESH MATERIALIZED VIEW salary_batch_summary;
SELECT * FROM salary_batch_summary;