
CREATE SCHEMA IF NOT EXISTS restaurant_schema;

SET search_path TO restaurant_schema, public;

-- ===== PART 2: DROP TABLES IF EXISTS (FOR RERUNNABILITY) =====

DROP TABLE IF EXISTS restaurant_schema.order_items CASCADE;
DROP TABLE IF EXISTS restaurant_schema.orders CASCADE;
DROP TABLE IF EXISTS restaurant_schema.menu_items CASCADE;
DROP TABLE IF EXISTS restaurant_schema.categories CASCADE;
DROP TABLE IF EXISTS restaurant_schema.shifts CASCADE;
DROP TABLE IF EXISTS restaurant_schema.staff CASCADE;
DROP TABLE IF EXISTS restaurant_schema.tables CASCADE;

-- ===== PART 3: CREATE TABLES =====

CREATE TABLE IF NOT EXISTS restaurant_schema.tables (
    table_id SERIAL PRIMARY KEY,
    table_number INT NOT NULL UNIQUE,
    capacity INT NOT NULL,
    status VARCHAR(20) DEFAULT 'Available',
    is_window_seat BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS restaurant_schema.staff (
    staff_id SERIAL PRIMARY KEY,
    first_name VARCHAR(80) NOT NULL,
    last_name VARCHAR(80) NOT NULL,
    full_name VARCHAR(160) GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED,
    role VARCHAR(100) NOT NULL,
    phone VARCHAR(30) UNIQUE,
    salary NUMERIC(10,2) NOT NULL,
    hire_date DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS restaurant_schema.categories (
    category_id SERIAL PRIMARY KEY,
    name VARCHAR(80) NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE IF NOT EXISTS restaurant_schema.shifts (
    shift_id SERIAL PRIMARY KEY,
    staff_id INT NOT NULL REFERENCES restaurant_schema.staff(staff_id) ON DELETE CASCADE,
    shift_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    hours_worked NUMERIC(4,2) GENERATED ALWAYS AS (EXTRACT(EPOCH FROM (end_time - start_time))/3600.0) STORED
);

CREATE TABLE IF NOT EXISTS restaurant_schema.menu_items (
    item_id SERIAL PRIMARY KEY,
    category_id INT NOT NULL REFERENCES restaurant_schema.categories(category_id) ON DELETE RESTRICT,
    name VARCHAR(120) NOT NULL UNIQUE,
    price NUMERIC(10,2) NOT NULL,
    is_available BOOLEAN DEFAULT TRUE,
    calories INT
);

CREATE TABLE IF NOT EXISTS restaurant_schema.orders (
    order_id SERIAL PRIMARY KEY,
    table_id INT NOT NULL REFERENCES restaurant_schema.tables(table_id) ON DELETE RESTRICT,
    staff_id INT NOT NULL REFERENCES restaurant_schema.staff(staff_id) ON DELETE RESTRICT,
    ordered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'Pending',
    total_amount NUMERIC(10,2) DEFAULT 0.00
);

CREATE TABLE IF NOT EXISTS restaurant_schema.order_items (
    order_id INT NOT NULL REFERENCES restaurant_schema.orders(order_id) ON DELETE CASCADE,
    item_id INT NOT NULL REFERENCES restaurant_schema.menu_items(item_id) ON DELETE RESTRICT,
    quantity INT NOT NULL,
    unit_price NUMERIC(10,2) NOT NULL,
    line_total NUMERIC(10,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    PRIMARY KEY (order_id, item_id)
);

-- ===== PART 4: ALTER TABLE CONSTRAINTS & DEFAULTS =====

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_table_capacity') THEN
        ALTER TABLE restaurant_schema.tables DROP CONSTRAINT chk_table_capacity;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_table_status') THEN
        ALTER TABLE restaurant_schema.tables DROP CONSTRAINT chk_table_status;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_staff_hire_date') THEN
        ALTER TABLE restaurant_schema.staff DROP CONSTRAINT chk_staff_hire_date;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_staff_salary_positive') THEN
        ALTER TABLE restaurant_schema.staff DROP CONSTRAINT chk_staff_salary_positive;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_menu_item_price') THEN
        ALTER TABLE restaurant_schema.menu_items DROP CONSTRAINT chk_menu_item_price;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_menu_calories') THEN
        ALTER TABLE restaurant_schema.menu_items DROP CONSTRAINT chk_menu_calories;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_order_status') THEN
        ALTER TABLE restaurant_schema.orders DROP CONSTRAINT chk_order_status;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_order_items_quantity') THEN
        ALTER TABLE restaurant_schema.order_items DROP CONSTRAINT chk_order_items_quantity;
    END IF;
END $$;

ALTER TABLE restaurant_schema.tables ADD CONSTRAINT chk_table_capacity CHECK (capacity > 0);
ALTER TABLE restaurant_schema.tables ADD CONSTRAINT chk_table_status CHECK (status IN ('Available', 'Occupied', 'Reserved', 'Out of Service'));
ALTER TABLE restaurant_schema.staff ADD CONSTRAINT chk_staff_hire_date CHECK (hire_date > DATE '2026-01-01');
ALTER TABLE restaurant_schema.staff ADD CONSTRAINT chk_staff_salary_positive CHECK (salary >= 0);
ALTER TABLE restaurant_schema.menu_items ADD CONSTRAINT chk_menu_item_price CHECK (price >= 0);
ALTER TABLE restaurant_schema.menu_items ADD CONSTRAINT chk_menu_calories CHECK (calories IS NULL OR calories > 0);
ALTER TABLE restaurant_schema.orders ADD CONSTRAINT chk_order_status CHECK (status IN ('Pending', 'Served', 'Paid', 'Cancelled'));
ALTER TABLE restaurant_schema.order_items ADD CONSTRAINT chk_order_items_quantity CHECK (quantity > 0);

ALTER TABLE restaurant_schema.orders ALTER COLUMN status SET DEFAULT 'Pending';

-- ===== PART 5: DATA POPULATION (INSERT) =====

WITH new_tables AS (
    SELECT 101 AS table_number, 2 AS capacity, 'Available' AS status, true AS is_window_seat UNION ALL
    SELECT 102, 4, 'Available', false UNION ALL
    SELECT 103, 4, 'Available', true UNION ALL
    SELECT 104, 6, 'Available', false UNION ALL
    SELECT 105, 8, 'Available', true
), inserted_tables AS (
    INSERT INTO restaurant_schema.tables (table_number, capacity, status, is_window_seat)
    SELECT table_number, capacity, status, is_window_seat FROM new_tables nt
    WHERE NOT EXISTS (SELECT 1 FROM restaurant_schema.tables t WHERE t.table_number = nt.table_number)
    RETURNING table_id
) SELECT * FROM inserted_tables;

WITH new_staff AS (
    SELECT 'Kaussar' AS first_name, 'Yerbolatkyzy' AS last_name, 'Manager' AS role, '+77716689185' AS phone, 450000.00 AS salary, '2026-03-01'::date AS hire_date UNION ALL
    SELECT 'Arnur', 'Kamai', 'Bartender', '+77756892600', 230000.00, '2026-03-05' UNION ALL
    SELECT 'Aktoty', 'Shakhmet', 'Hostess', '+77780519378', 210000.00, '2026-03-10' UNION ALL
    SELECT 'Korkem', 'Igilik', 'Server', '+77752203269', 180000.00, '2026-03-12' UNION ALL
    SELECT 'Aisha', 'Zhumagali', 'Sous Chef', '+77714282008', 380000.00, '2026-03-15'
), inserted_staff AS (
    INSERT INTO restaurant_schema.staff (first_name, last_name, role, phone, salary, hire_date)
    SELECT first_name, last_name, role, phone, salary, hire_date FROM new_staff ns
    WHERE NOT EXISTS (SELECT 1 FROM restaurant_schema.staff s WHERE s.phone = ns.phone)
    RETURNING staff_id
) SELECT * FROM inserted_staff;

WITH new_shifts AS (
    SELECT (SELECT staff_id FROM restaurant_schema.staff WHERE phone = '+77716689185') AS staff_id, '2026-06-01'::date AS shift_date, '08:00:00'::time AS start_time, '16:00:00'::time AS end_time UNION ALL
    SELECT (SELECT staff_id FROM restaurant_schema.staff WHERE phone = '+77752203269'), '2026-06-01', '16:00:00', '00:00:00' UNION ALL
    SELECT (SELECT staff_id FROM restaurant_schema.staff WHERE phone = '+77756892600'), '2026-06-01', '18:00:00', '02:00:00' UNION ALL
    SELECT (SELECT staff_id FROM restaurant_schema.staff WHERE phone = '+77716689185'), '2026-06-02', '08:00:00', '16:00:00' UNION ALL
    SELECT (SELECT staff_id FROM restaurant_schema.staff WHERE phone = '+77752203269'), '2026-06-02', '16:00:00', '00:00:00'
), inserted_shifts AS (
    INSERT INTO restaurant_schema.shifts (staff_id, shift_date, start_time, end_time)
    SELECT staff_id, shift_date, start_time, end_time FROM new_shifts
    RETURNING shift_id
) SELECT * FROM inserted_shifts;

WITH new_categories AS (
    SELECT 'Appetizers' AS name, 'Light dishes to start' AS description UNION ALL
    SELECT 'Mains', 'Hearty and full main courses' UNION ALL
    SELECT 'Desserts', 'Sweet treats and cakes' UNION ALL
    SELECT 'Beverages', 'Hot and cold drinks' UNION ALL
    SELECT 'Sides', 'Extra accompaniments'
), inserted_categories AS (
    INSERT INTO restaurant_schema.categories (name, description)
    SELECT name, description FROM new_categories nc
    WHERE NOT EXISTS (SELECT 1 FROM restaurant_schema.categories c WHERE c.name = nc.name)
    RETURNING category_id
) SELECT * FROM inserted_categories;

WITH new_menu AS (
    SELECT (SELECT category_id FROM restaurant_schema.categories WHERE name = 'Appetizers') AS category_id, 'Beshbarmak Rolls' AS name, 2400.00 AS price, true AS is_available, 350 AS calories UNION ALL
    SELECT (SELECT category_id FROM restaurant_schema.categories WHERE name = 'Appetizers'), 'Garlic Bread', 1200.00, true, 280 UNION ALL
    SELECT (SELECT category_id FROM restaurant_schema.categories WHERE name = 'Mains'), 'Ribeye Steak', 8500.00, true, 820 UNION ALL
    SELECT (SELECT category_id FROM restaurant_schema.categories WHERE name = 'Mains'), 'Grilled Salmon', 6200.00, true, 540 UNION ALL
    SELECT (SELECT category_id FROM restaurant_schema.categories WHERE name = 'Mains'), 'Kazakh Beef Stew', 4800.00, true, 670 UNION ALL
    SELECT (SELECT category_id FROM restaurant_schema.categories WHERE name = 'Desserts'), 'Baursak Platter', 1800.00, true, 450 UNION ALL
    SELECT (SELECT category_id FROM restaurant_schema.categories WHERE name = 'Desserts'), 'Chocolate Lava Cake', 2200.00, true, 580 UNION ALL
    SELECT (SELECT category_id FROM restaurant_schema.categories WHERE name = 'Beverages'), 'Mint Lemonade', 1100.00, true, 120 UNION ALL
    SELECT (SELECT category_id FROM restaurant_schema.categories WHERE name = 'Beverages'), 'Shubat Brew', 1500.00, true, 160 UNION ALL
    SELECT (SELECT category_id FROM restaurant_schema.categories WHERE name = 'Sides'), 'Truffle Fries', 1600.00, true, 410
), inserted_menu AS (
    INSERT INTO restaurant_schema.menu_items (category_id, name, price, is_available, calories)
    SELECT category_id, name, price, is_available, calories FROM new_menu nm
    WHERE NOT EXISTS (SELECT 1 FROM restaurant_schema.menu_items m WHERE m.name = nm.name)
    RETURNING item_id
) SELECT * FROM inserted_menu;

WITH new_orders AS (
    SELECT (SELECT table_id FROM restaurant_schema.tables WHERE table_number = 101) AS table_id, (SELECT staff_id FROM restaurant_schema.staff WHERE phone = '+77716689185') AS staff_id, '2026-06-03 12:30:00'::timestamp AS ordered_at, 'Paid' AS status, 5200.00 AS total_amount UNION ALL
    SELECT (SELECT table_id FROM restaurant_schema.tables WHERE table_number = 102), (SELECT staff_id FROM restaurant_schema.staff WHERE phone = '+77716689185'), '2026-06-03 13:00:00', 'Paid', 10300.00 UNION ALL
    SELECT (SELECT table_id FROM restaurant_schema.tables WHERE table_number = 103), (SELECT staff_id FROM restaurant_schema.staff WHERE phone = '+77752203269'), '2026-06-03 18:15:00', 'Served', 14700.00 UNION ALL
    SELECT (SELECT table_id FROM restaurant_schema.tables WHERE table_number = 104), (SELECT staff_id FROM restaurant_schema.staff WHERE phone = '+77752203269'), '2026-06-03 19:00:00', 'Pending', 6200.00 UNION ALL
    SELECT (SELECT table_id FROM restaurant_schema.tables WHERE table_number = 105), (SELECT staff_id FROM restaurant_schema.staff WHERE phone = '+77756892600'), '2026-06-03 19:30:00', 'Cancelled', 1800.00 UNION ALL
    SELECT (SELECT table_id FROM restaurant_schema.tables WHERE table_number = 101) AS table_id, (SELECT staff_id FROM restaurant_schema.staff WHERE phone = '+77716689185') AS staff_id, '2026-06-03 20:00:00'::timestamp AS ordered_at, 'Paid' AS status, 3500.00 AS total_amount UNION ALL
    SELECT (SELECT table_id FROM restaurant_schema.tables WHERE table_number = 102), (SELECT staff_id FROM restaurant_schema.staff WHERE phone = '+77752203269'), '2026-06-03 20:15:00', 'Served', 8500.00 UNION ALL
    SELECT (SELECT table_id FROM restaurant_schema.tables WHERE table_number = 103), (SELECT staff_id FROM restaurant_schema.staff WHERE phone = '+77756892600'), '2026-06-03 21:00:00', 'Pending', 1100.00 UNION ALL
    SELECT (SELECT table_id FROM restaurant_schema.tables WHERE table_number = 104), (SELECT staff_id FROM restaurant_schema.staff WHERE phone = '+77716689185'), '2026-06-03 21:30:00', 'Paid', 2400.00 UNION ALL
    SELECT (SELECT table_id FROM restaurant_schema.tables WHERE table_number = 105), (SELECT staff_id FROM restaurant_schema.staff WHERE phone = '+77752203269'), '2026-06-03 22:00:00', 'Paid', 16200.00
), inserted_orders AS (
    INSERT INTO restaurant_schema.orders (table_id, staff_id, ordered_at, status, total_amount)
    SELECT table_id, staff_id, ordered_at, status, total_amount FROM new_orders
    RETURNING order_id
) SELECT * FROM inserted_orders;

INSERT INTO restaurant_schema.order_items (order_id, item_id, quantity, unit_price)
SELECT o.order_id, m.item_id, 2, m.price
FROM restaurant_schema.orders o
CROSS JOIN restaurant_schema.menu_items m
WHERE o.status = 'Pending' AND m.name = 'Beshbarmak Rolls'
ON CONFLICT DO NOTHING;

INSERT INTO restaurant_schema.order_items (order_id, item_id, quantity, unit_price) VALUES 
(1, (SELECT item_id FROM restaurant_schema.menu_items WHERE name = 'Baursak Platter'), 1, 1800.00),
(1, (SELECT item_id FROM restaurant_schema.menu_items WHERE name = 'Shubat Brew'), 2, 1500.00),
(2, (SELECT item_id FROM restaurant_schema.menu_items WHERE name = 'Ribeye Steak'), 1, 8500.00),
(2, (SELECT item_id FROM restaurant_schema.menu_items WHERE name = 'Mint Lemonade'), 1, 1100.00),
(3, (SELECT item_id FROM restaurant_schema.menu_items WHERE name = 'Grilled Salmon'), 2, 6200.00),
(3, (SELECT item_id FROM restaurant_schema.menu_items WHERE name = 'Chocolate Lava Cake'), 1, 2200.00)
ON CONFLICT DO NOTHING;

-- ===== PART 6: DATA UPDATES & TRANSACTIONS =====

UPDATE restaurant_schema.menu_items SET is_available = FALSE WHERE name = 'Shubat Brew';

UPDATE restaurant_schema.orders o
SET total_amount = COALESCE((
    SELECT SUM(oi.line_total) 
    FROM restaurant_schema.order_items oi 
    WHERE oi.order_id = o.order_id
), 0.00)
WHERE o.status != 'Paid';

BEGIN;
DELETE FROM restaurant_schema.orders WHERE status = 'Cancelled';
COMMIT;

-- ===== PART 7: FUNCTIONS & VIEWS =====

CREATE OR REPLACE FUNCTION restaurant_schema.update_menu_column(
    p_item_id INT,
    upd_column_name TEXT,
    new_value TEXT
)
RETURNS VOID AS $$
DECLARE affected_rows INT;
BEGIN
    IF NOT EXISTS (
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_schema = 'restaurant_schema'
          AND table_name = 'menu_items'
          AND column_name = upd_column_name
    ) THEN
        RAISE NOTICE 'Column "%" does not exist in table "menu_items".', upd_column_name;
        RETURN;
    END IF;
	
    EXECUTE format('UPDATE restaurant_schema.menu_items SET %I = $1 WHERE item_id = $2', upd_column_name)
    USING new_value, p_item_id;
	
    GET DIAGNOSTICS affected_rows = ROW_COUNT;

    IF affected_rows = 0 THEN
        RAISE NOTICE 'No row found with item_id = %', p_item_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE VIEW restaurant_schema.analytics_recent_quarter AS
SELECT 
    o.order_id,
    o.ordered_at,
    EXTRACT(QUARTER FROM o.ordered_at) AS quarter,
    t.table_number,
    s.full_name AS staff_name,
    m.name AS item_name,
    c.name AS category_name,
    oi.quantity,
    oi.line_total
FROM 
    restaurant_schema.orders o
LEFT JOIN 
    restaurant_schema.tables t ON o.table_id = t.table_id
LEFT JOIN 
    restaurant_schema.staff s ON o.staff_id = s.staff_id
LEFT JOIN 
    restaurant_schema.order_items oi ON o.order_id = oi.order_id
LEFT JOIN 
    restaurant_schema.menu_items m ON oi.item_id = m.item_id
LEFT JOIN 
    restaurant_schema.categories c ON m.category_id = c.category_id
WHERE 
    EXTRACT(YEAR FROM o.ordered_at) = EXTRACT(YEAR FROM CURRENT_DATE) AND
    EXTRACT(QUARTER FROM o.ordered_at) = EXTRACT(QUARTER FROM CURRENT_DATE);

-- ===== PART 8: ROLES & SECURITY (GRANT) =====

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'restaurant_readonly') THEN
        DROP ROLE restaurant_readonly;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'restaurant_writer') THEN
        DROP ROLE restaurant_writer;
    END IF;
END $$;

CREATE ROLE restaurant_readonly LOGIN PASSWORD 'readonly_password';
CREATE ROLE restaurant_writer LOGIN PASSWORD 'writer_password';

GRANT CONNECT ON DATABASE restaurant_db TO restaurant_readonly;
GRANT USAGE ON SCHEMA restaurant_schema TO restaurant_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA restaurant_schema TO restaurant_readonly;

GRANT CONNECT ON DATABASE restaurant_db TO restaurant_writer;
GRANT USAGE ON SCHEMA restaurant_schema TO restaurant_writer;
GRANT INSERT, UPDATE ON restaurant_schema.menu_items TO restaurant_writer;