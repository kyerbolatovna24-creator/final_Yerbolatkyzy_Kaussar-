# 🍽️ Restaurant Management Database System

A complete PostgreSQL database solution designed to manage a restaurant's daily operations. This system handles seating tables, staff records, work shifts, menu items, customer orders, and sales tracking.

---

## 🗺️ Domain & Schema Description

* **Database Name:** `restaurant_db`
* **Schema Name:** `restaurant_schema`

### Key Architectural Decisions
1. **Third Normal Form (3NF) Compliance:** All tables are structured to eliminate redundancy. For example, in the `staff` table, all descriptive fields depend strictly on the primary key `staff_id`, removing all transitive dependencies.
2. **Many-to-Many (M:N) Resolution:** The relationship between `orders` and `menu_items` is managed via the **`order_items`** junction table. This tracking table features a composite primary key `(order_id, item_id)` to handle quantities per item effortlessly.
3. **Automated Mathematical Precision:** * Decimal values for `hours_worked` in `shifts` are calculated automatically from system timestamps.
   * Row line items (`line_total`) in `order_items` use exact math values (`NUMERIC`) instead of inaccurate float calculations to guarantee financial precision down to the cent.
4. **Data Integrity Constraints:** The schema enforces five types of custom constraints (non-negativity for cash values, range bounds for table sizes, and date barriers ensuring all system inputs are logged after `2026-01-01`).

---

## 🚀 How to Run the Script in DBeaver

### Prerequisites
* **PostgreSQL Server** (v12 or higher recommended)
* **DBeaver Community/Enterprise Edition**

### Execution Steps
1. Open DBeaver and connect to your PostgreSQL database server.
2. Open the script file **`02_final3.sql`** (`File` -> `Open File...`).
3. Make sure your active connection dropdown at the top right of the script editor points to your PostgreSQL server.
4. Execute the full script by clicking the **Execute SQL Script** button on the left toolbar (or press **Alt + X** / **Fn + Alt + X**).
5. **Re-runnability Verification:** Click the Execute button a second time immediately. The script cleans old tables using conditional drops (`DROP TABLE IF EXISTS ... CASCADE`) and conditional data population checks (`WHERE NOT EXISTS`), running successfully with zero errors.

---

## 📂 Repository Contents

* `01_conceptual_erd.png` - The Conceptual Entity-Relationship Diagram outlining high-level business entities and connections.
* `_01_model-Logical Model (2).png` - The detailed Logical Database Model showing data types, primary/foreign keys, and constraints.
* `02_final3.sql` - The complete execution script containing DDL structures, constraints, dynamic data population, automated views, and role configurations.
* `README.md` - Documentation of the project domain and setup instructions.
