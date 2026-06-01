# Restaurant Management System 🍽️
**Final Project for Databases Course** **Student:** Kaussar Yerbolatkyzy  
**Target DB:** PostgreSQL  

---

## 1. Domain Description (Пәндік аймақты сипаттау)
This project implements a relational database structure for a **Restaurant Management System**. The system is designed to automate and track core restaurant operations, ensuring smooth workflow management across several departments.

### Key Entities & Business Flow:
* **Clients & Bookings:** Customers (`client`) can reserve specific dining tables (`tables`) for a particular date and time via the `booking` table.
* **Menu & Dishes:** The kitchen management includes categorization of dishes (`type_dish`), individual menu offerings (`menu`), and the detailed ingredient tracking (`composition_dish`).
* **Orders & Service:** When a customer dines, an `order` is created. Waitstaff and kitchen personnel (`personal`, categorized by their specific `post`) are assigned to orders through `order_personal`. Individual items in each order are tracked in `order_dish`.
* **Billing:** Every finalized order goes through the financial logging system via the `payment` table.

---

## 2. Database Architecture (3NF Justification)
The database layout strictly conforms to the **Third Normal Form (3NF)** to ensure zero data redundancy and maximum data integrity:
1.  **1NF:** All attributes contain atomic values, and there are no repeating groups.
2.  **2NF:** The database is in 1NF, and all non-prime attributes are fully functionally dependent on the primary key (Composite keys in junction tables like `order_dish` and `composition_dish` are fully mapped).
3.  **3NF:** There are no transitive dependencies. For instance, employee salary and position titles are isolated into the `post` lookup table rather than being duplicated in the `personal` table.

---

## 3. Script Structure & Specifications
The accompanying SQL script (`02_final.sql`) is fully automated, idempotent, and designed to run cleanly multiple times.

### Included Features:
* **Robust DDL:** Built using strict constraints (`NOT NULL`, `UNIQUE`, `CHECK`), explicit foreign key cascade operations (`ON DELETE CASCADE / RESTRICT / SET NULL`), and a deterministic table-dropping order.
* **Schema Enhancements:** Implements 5 distinct `ALTER TABLE` procedures updating data types, applying domain constraints, and adding columns.
* **Advanced Features:** Implements a calculated field (`sum_dish`) using the `GENERATED ALWAYS AS ... STORED` engine.
* **Data Quality:** populates 12 tables with at least 5 rows of realistic data (and exactly 10 rows for high-volume operational tables), using safe dynamic `SELECT` lookups for Foreign Keys.
* **DCL Security:** Introduces role-based access control (`restaurant_db_readonly` and `restaurant_db_writer`) utilizing granular object privileges.

---

## 4. How to Run the Script (Нұсқаулық)

To deploy the database setup seamlessly, follow these steps in your database client (e.g., **DBeaver** or **pgAdmin**):

1.  **Open Connection:** Connect to your target database instance (e.g., your local PostgreSQL server).
2.  **Load Script:** Open the `02_final.sql` file in your SQL Editor.
3.  **Execute the Script:**
    * On **Windows:** Press `Alt + X` (or click the *Execute SQL Script* icon on the left toolbar) to run the entire document.
    * On **macOS:** Press `Option + X` (or use the *Execute SQL Script* button).
4.  **Verify Deployment:** Go to the Database Navigator, right-click on the **`public`** schema under your active database, and select **Refresh (F5)**. You will see all 12 interconnected tables fully populated and ready.
