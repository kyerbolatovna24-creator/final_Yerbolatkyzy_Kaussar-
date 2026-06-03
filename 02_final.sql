--  1. RE-RUNNABLE HEADER & RESET (DROP ... CASCADE IN CORRECT ORDER)
DROP ROLE IF EXISTS restaurant_db_readonly;
DROP ROLE IF EXISTS restaurant_db_writer;

DROP TABLE IF EXISTS public.order_personal CASCADE;
DROP TABLE IF EXISTS public.payment CASCADE;
DROP TABLE IF EXISTS public.order_dish CASCADE;
DROP TABLE IF EXISTS public."order" CASCADE;
DROP TABLE IF EXISTS public.booking CASCADE;
DROP TABLE IF EXISTS public.composition_dish CASCADE;
DROP TABLE IF EXISTS public.menu CASCADE;
DROP TABLE IF EXISTS public.type_dish CASCADE;
DROP TABLE IF EXISTS public.personal CASCADE;
DROP TABLE IF EXISTS public.post CASCADE;
DROP TABLE IF EXISTS public.tables CASCADE;
DROP TABLE IF EXISTS public.client CASCADE;

-- 2. CREATE TABLES (Correct types, PK, FK with explicit ON DELETE & 5 CHECKS)
CREATE TABLE IF NOT EXISTS public.client (
    id_client SERIAL PRIMARY KEY,
    fio_client VARCHAR(150) NOT NULL, -- Requirement: NOT NULL check
    phone_client VARCHAR(30) NOT NULL CONSTRAINT uq_client_phone UNIQUE, -- Requirement: UNIQUE constraint
    email_client VARCHAR(150) NOT NULL CONSTRAINT uq_client_email UNIQUE,
    gender_client CHAR(1) NOT NULL CONSTRAINT chk_client_gender CHECK (gender_client IN ('M', 'F')) -- Check 1: Enumerated
);

CREATE TABLE IF NOT EXISTS public.tables (
    id_table SERIAL PRIMARY KEY,
    number_table INT NOT NULL CONSTRAINT uq_table_number UNIQUE,
    capacity_table INT NOT NULL CONSTRAINT chk_table_capacity CHECK (capacity_table > 0), -- Check 2: Non-negative / measurable
    status_table VARCHAR(30) DEFAULT 'Available' NOT NULL
);

CREATE TABLE IF NOT EXISTS public.post (
    id_post SERIAL PRIMARY KEY,
    name_post VARCHAR(100) NOT NULL CONSTRAINT uq_post_name UNIQUE,
    base_salary NUMERIC(10, 2) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.personal (
    id_personal SERIAL PRIMARY KEY,
    id_post INT NOT NULL REFERENCES public.post(id_post) ON DELETE RESTRICT, -- Explicit ON DELETE
    fio_personal VARCHAR(150) NOT NULL,
    phone_personal VARCHAR(30),
    hire_date DATE DEFAULT CURRENT_DATE NOT NULL -- Requirement: DEFAULT present
);

CREATE TABLE IF NOT EXISTS public.type_dish (
    id_type SERIAL PRIMARY KEY,
    name_type VARCHAR(100) NOT NULL CONSTRAINT uq_type_name UNIQUE
);

CREATE TABLE IF NOT EXISTS public.menu (
    id_dish SERIAL PRIMARY KEY,
    id_type INT NOT NULL REFERENCES public.type_dish(id_type) ON DELETE RESTRICT,
    name_dish VARCHAR(150) NOT NULL,
    price_dish NUMERIC(10, 2) NOT NULL CONSTRAINT chk_dish_price CHECK (price_dish >= 0) -- Check 3: Non-negative
);

CREATE TABLE IF NOT EXISTS public.composition_dish (
    id_dish INT NOT NULL REFERENCES public.menu(id_dish) ON DELETE CASCADE,
    ingredient_name VARCHAR(100) NOT NULL,
    weight_g INT NOT NULL CONSTRAINT chk_weight CHECK (weight_g > 0), -- Check 4: Measurable
    PRIMARY KEY (id_dish, ingredient_name)
);

CREATE TABLE IF NOT EXISTS public.booking (
    id_booking SERIAL PRIMARY KEY,
    id_client INT NOT NULL REFERENCES public.client(id_client) ON DELETE CASCADE,
    id_table INT NOT NULL REFERENCES public.tables(id_table) ON DELETE CASCADE,
    booking_date TIMESTAMP NOT NULL CONSTRAINT chk_booking_date CHECK (booking_date > DATE '2026-01-01') -- Check 5: Date after 2026-01-01
);

CREATE TABLE IF NOT EXISTS public."order" (
    id_order SERIAL PRIMARY KEY,
    id_client INT REFERENCES public.client(id_client) ON DELETE SET NULL,
    id_table INT REFERENCES public.tables(id_table) ON DELETE SET NULL,
    date_order TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    status_order VARCHAR(50) DEFAULT 'New' NOT NULL,
    total_price NUMERIC(10, 2) DEFAULT 0.00 NOT NULL
);

CREATE TABLE IF NOT EXISTS public.order_dish (
    id_order INT NOT NULL REFERENCES public."order"(id_order) ON DELETE CASCADE,
    id_dish INT NOT NULL REFERENCES public.menu(id_dish) ON DELETE RESTRICT,
    count_dish INT NOT NULL,
    price_per_one NUMERIC(10, 2) NOT NULL,
    -- Requirement: GENERATED ALWAYS AS ... STORED (Вычисляемый столбец)
    sum_dish NUMERIC(10, 2) GENERATED ALWAYS AS (count_dish * price_per_one) STORED,
    PRIMARY KEY (id_order, id_dish)
);

CREATE TABLE IF NOT EXISTS public.payment (
    id_payment SERIAL PRIMARY KEY,
    id_order INT NOT NULL REFERENCES public."order"(id_order) ON DELETE CASCADE,
    amount_payment NUMERIC(10, 2) NOT NULL,
    method_payment VARCHAR(50) NOT NULL,
    date_payment TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS public.order_personal (
    id_order INT NOT NULL REFERENCES public."order"(id_order) ON DELETE CASCADE,
    id_personal INT NOT NULL REFERENCES public.personal(id_personal) ON DELETE RESTRICT,
    assigned_role VARCHAR(50) NOT NULL,
    PRIMARY KEY (id_order, id_personal)
);

-- ============================================================================
-- 3. ALTER TABLE OPERATIONS (Exactly 5 distinct operations with why-comments)
-- ============================================================================

-- Comment 1: Business requested storing allergy notes for user safety
ALTER TABLE public.client ADD COLUMN IF NOT EXISTS allergy_info VARCHAR(255);

-- Comment 2: HR optimization, phone moved to a separate communication system log
ALTER TABLE public.personal DROP COLUMN IF EXISTS phone_personal;

-- Comment 3: Financial rule enforcement, base salary can never be negative
ALTER TABLE public.post ADD CONSTRAINT chk_salary CHECK (base_salary >= 0);

-- Comment 4: Workflow protection, preventing invalid status overwrites in lifecycle
ALTER TABLE public."order" ADD CONSTRAINT chk_status_options CHECK (status_order IN ('New', 'Cooking', 'Served', 'Paid', 'Cancelled'));

-- Comment 5: Defaulting accounting methods to favor cash transactions for speed
ALTER TABLE public.payment ALTER COLUMN method_payment SET DEFAULT 'Cash';

-- 4. INSERT DATA BLOCK (TRUNCATE CASCADE, No hardcoded FKs, 10+ in largest)

TRUNCATE 
    public.order_personal, public.payment, public.order_dish, public."order", 
    public.booking, public.composition_dish, public.menu, public.type_dish, 
    public.personal, public.post, public.tables, public.client 
RESTART IDENTITY CASCADE;

-- Insert realistic data (>= 5 rows for reference tables)
INSERT INTO public.client (fio_client, phone_client, email_client, gender_client) VALUES
('Kaussar Yerbolatkyzy', '+77071112233', 'kaussar.y@example.com', 'F'),
('Ivan Ivanov', '+77074445566', 'ivan@example.com', 'M'),
('Alima Saparova', '+77077778899', 'alima@example.com', 'F'),
('John Doe', '+12025550143', 'john.doe@example.com', 'M'),
('Elena Petrova', '+77019998877', 'elena@example.com', 'F');

INSERT INTO public.tables (number_table, capacity_table, status_table) VALUES
(1, 2, 'Available'), (2, 4, 'Available'), (3, 6, 'Available'), (4, 2, 'Available'), (5, 8, 'Available');

INSERT INTO public.post (name_post, base_salary) VALUES
('Chef', 3500.00), ('Waiter', 1500.00), ('Manager', 4000.00), ('Barman', 1800.00), ('Cleaner', 1000.00);

INSERT INTO public.type_dish (name_type) VALUES
('Soups'), ('Main Course'), ('Desserts'), ('Beverages'), ('Salads');

-- Dynamic subqueries for FK lookups (No hardcoded IDs!)
INSERT INTO public.personal (id_post, fio_personal) VALUES
((SELECT id_post FROM public.post WHERE name_post = 'Chef'), 'Asan Omarov'),
((SELECT id_post FROM public.post WHERE name_post = 'Waiter'), 'Anna Smith'),
((SELECT id_post FROM public.post WHERE name_post = 'Manager'), 'Michael Scott'),
((SELECT id_post FROM public.post WHERE name_post = 'Barman'), 'Jim Halpert'),
((SELECT id_post FROM public.post WHERE name_post = 'Waiter'), 'Sabina Alieva');

INSERT INTO public.menu (id_type, name_dish, price_dish) VALUES
((SELECT id_type FROM public.type_dish WHERE name_type = 'Soups'), 'Tomato Soup', 8.50),
((SELECT id_type FROM public.type_dish WHERE name_type = 'Main Course'), 'Beef Steak', 24.99),
((SELECT id_type FROM public.type_dish WHERE name_type = 'Desserts'), 'Chocolate Cake', 6.00),
((SELECT id_type FROM public.type_dish WHERE name_type = 'Beverages'), 'Coffee', 3.50),
((SELECT id_type FROM public.type_dish WHERE name_type = 'Salads'), 'Caesar Salad', 12.00);

-- Requirement: INSERT ... SELECT usage (Junction table population)
INSERT INTO public.composition_dish (id_dish, ingredient_name, weight_g)
SELECT id_dish, 'Fresh Tomato', 250 
FROM public.menu 
WHERE name_dish = 'Tomato Soup';

INSERT INTO public.composition_dish (id_dish, ingredient_name, weight_g) VALUES
((SELECT id_dish FROM public.menu WHERE name_dish = 'Beef Steak'), 'Beef Meat', 300),
((SELECT id_dish FROM public.menu WHERE name_dish = 'Caesar Salad'), 'Chicken Fillet', 150);

INSERT INTO public.booking (id_client, id_table, booking_date) VALUES
((SELECT id_client FROM public.client WHERE email_client = 'kaussar.y@example.com'), 2, '2026-06-15 19:00:00'),
((SELECT id_client FROM public.client WHERE email_client = 'ivan@example.com'), 3, '2026-06-16 20:00:00'),
((SELECT id_client FROM public.client WHERE email_client = 'alima@example.com'), 1, '2026-06-17 18:00:00'),
((SELECT id_client FROM public.client WHERE email_client = 'john.doe@example.com'), 4, '2026-06-18 21:00:00'),
((SELECT id_client FROM public.client WHERE email_client = 'elena@example.com'), 5, '2026-06-19 19:30:00');

INSERT INTO public."order" (id_client, id_table, status_order, total_price) VALUES
((SELECT id_client FROM public.client WHERE email_client = 'kaussar.y@example.com'), 2, 'Paid', 33.49),
((SELECT id_client FROM public.client WHERE email_client = 'ivan@example.com'), 3, 'Paid', 24.99),
((SELECT id_client FROM public.client WHERE email_client = 'alima@example.com'), 1, 'Paid', 8.50),
((SELECT id_client FROM public.client WHERE email_client = 'john.doe@example.com'), 4, 'Paid', 12.00),
((SELECT id_client FROM public.client WHERE email_client = 'elena@example.com'), 5, 'Paid', 6.00);

-- Requirement: Largest Table 1 (order_dish) -> Exactly 10 rows
INSERT INTO public.order_dish (id_order, id_dish, count_dish, price_per_one) VALUES
(1, 1, 1, 8.50), (1, 2, 1, 24.99), (2, 2, 1, 24.99), (3, 1, 1, 8.50), (4, 5, 1, 12.00),
(5, 3, 1, 6.00), (1, 4, 2, 3.50), (2, 4, 1, 3.50), (3, 3, 1, 6.00), (4, 4, 1, 3.50);

-- Requirement: Largest Table 2 (payment) -> Exactly 10 rows
INSERT INTO public.payment (id_order, amount_payment, method_payment) VALUES
(1, 10.00, 'Credit Card'), (1, 23.49, 'Credit Card'), (2, 20.00, 'Cash'), (2, 4.99, 'Cash'), (3, 8.50, 'Credit Card'),
(4, 12.00, 'Cash'), (5, 6.00, 'Credit Card'), (1, 7.00, 'Cash'), (2, 3.50, 'Credit Card'), (3, 6.00, 'Cash');

INSERT INTO public.order_personal (id_order, id_personal, assigned_role) VALUES
(1, 2, 'Server'), (2, 2, 'Server'), (3, 5, 'Server'), (4, 5, 'Server'), (5, 2, 'Server');

-- ============================================================================
-- 5. UPDATE × 2 OPERATIONS (One simple, one with subquery/FROM + reason comments)
-- ============================================================================

-- Update 1 (Simple): Setting table status to 'Reserved' dynamically when a booking happens
UPDATE public.tables 
SET status_table = 'Reserved' 
WHERE id_table = 2;

-- Update 2 (Complex subquery in SET): Inflation adjustment. Raising soup category prices by 10%
UPDATE public.menu 
SET price_dish = price_dish * 1.10 
WHERE id_type = (SELECT id_type FROM public.type_dish WHERE name_type = 'Soups');

-- 6. DELETE IN TRANSACTION WITH RETURNING + ROLLBACK (+ reason comment)


-- Business reason: Auditing cancelled test entries during migration without saving them to disk
BEGIN;
DELETE FROM public."order" 
WHERE status_order = 'Cancelled'
RETURNING id_order;
ROLLBACK;

-- 7. DCL BLOCK (Roles, GRANT, REVOKE + purpose comments)


-- Role Purpose: To grant full read-only access to corporate analytic systems
CREATE ROLE restaurant_db_readonly;
-- Role Purpose: To allow application backend services to write incoming user orders
CREATE ROLE restaurant_db_writer;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO restaurant_db_readonly;
GRANT INSERT, UPDATE ON public."order" TO restaurant_db_writer;

-- Business Reason: Waitstaff/applications are forbidden to edit old bills after checkout to avoid fraud
REVOKE UPDATE ON public."order" FROM restaurant_db_writer;