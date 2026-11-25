DROP TABLE IF EXISTS events CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

CREATE TABLE customers (
    customer_id      BIGINT PRIMARY KEY,
    first_name       TEXT,
    last_name        TEXT,
    email            TEXT,
    signup_date      DATE,
    country          TEXT,
    marketing_opt_in BOOLEAN
);

CREATE TABLE products (
    product_id   BIGINT PRIMARY KEY,
    product_name TEXT,
    category     TEXT,
    unit_price   NUMERIC(10,2),
    active       BOOLEAN DEFAULT TRUE
);

CREATE TABLE orders (
    order_id    BIGINT PRIMARY KEY,
    customer_id BIGINT REFERENCES customers(customer_id),
    order_date  TIMESTAMP,
    status      TEXT,
    order_total NUMERIC(12,2)
);

CREATE TABLE order_items (
    order_item_id BIGINT PRIMARY KEY,
    order_id      BIGINT REFERENCES orders(order_id),
    product_id    BIGINT REFERENCES products(product_id),
    quantity      INT,
    unit_price    NUMERIC(10,2)
);

CREATE TABLE events (
    event_id    BIGINT,
    customer_id BIGINT,
    event_ts    TIMESTAMP,
    event_type  TEXT,
    product_id  BIGINT,
    session_id  TEXT
);

CREATE INDEX idx_customers_country ON customers(country);
