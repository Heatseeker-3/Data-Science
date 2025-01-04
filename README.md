 Data Warehouse Schema and Implementation

This document describes the schema and implementation of a data warehouse designed for sales analysis. The design follows a star schema model, utilizing a fact table and several dimension tables.

## 1. Schema Design

The schema follows a star design, consisting of:

*   **Fact Table:** `FACT_SALE`

    *   Captures transactional data, such as product sales, customer details, store information, and total sales.
    *   Includes foreign keys linking to all dimension tables.

*   **Dimension Tables:**

    *   `DIM_PRODUCT`: Stores product details like ID and name.
    *   `DIM_STORE`: Stores store-related data like store ID and name.
    *   `DIM_CUSTOMER`: Captures customer information like ID and name.
    *   `DIM_SUPPLIER`: Holds supplier information such as supplier ID and name.
    *   `DIM_DATE`: Maintains time-related attributes like year, quarter, and month.

## 2. Star Schema Table Descriptions

*   **Fact Table (`FACT_SALE`):**

    *   Tracks transactional details: sales, prices, and quantities.
    *   Links to dimensions via foreign keys for analysis.
    *   Key columns: `CUSTOMER_ID`, `STORE_ID`, `SUPPLIER_ID`, `PRODUCT_ID`, `T_DATE`, `TOTAL_SALE`, `PRICE`, `QUANTITY`.

*   **Dimension Tables:**

    *   `DIM_PRODUCT`: Stores static information about products.
    *   `DIM_STORE`: Holds metadata about stores (locations, IDs, etc.).
    *   `DIM_CUSTOMER`: Captures customer demographics or identifiers.
    *   `DIM_SUPPLIER`: Details supplier relationships and IDs.
    *   `DIM_DATE`: Provides time attributes for robust time-series analysis.

## 3. Procedure (INLJ)

The stored procedure automates:

*   **Data Load:**

    *   Batches transactions (e.g., 50 at a time) for efficient processing.
    *   Inserts new data into dimension tables if it doesn’t already exist.
    *   Populates the fact table only if no duplicates are detected.

*   **Master Data Handling:**

    *   Extracts master data (e.g., product and supplier information) for transactional processing.
    *   Checks for and prevents duplicate entries.

*   **Batch Processing:**

    *   Processes data incrementally to enhance performance and scalability.

## 4. Analytical Queries

These queries demonstrate the data warehouse's analytical capabilities:

*   **Top Products by Total Sales:**

    ```sql
    SELECT * FROM (
        SELECT f.product_id, p.product_name, SUM(f.total_sale) AS total_sale,
            RANK() OVER (ORDER BY SUM(f.total_sale) DESC) AS rank
        FROM fact_sale f
        JOIN dim_product p ON p.product_id = f.product_id
        GROUP BY f.product_id, p.product_name
    ) WHERE rank = 1;
    ```

*   **Top Suppliers in a Given Period:**

    ```sql
    SELECT * FROM (
        SELECT ds.supplier_id, ds.supplier_name, SUM(f.total_sale) AS total_sale,
            RANK() OVER (ORDER BY SUM(f.total_sale) DESC) AS rank
        FROM fact_sale f
        INNER JOIN dim_supplier ds ON f.supplier_id = ds.supplier_id
        INNER JOIN dim_date d ON f.t_date = d.t_date
        WHERE d.t_year = 2016 AND d.t_month = 8
        GROUP BY ds.supplier_id, ds.supplier_name
    ) WHERE rank <= 3;
    ```

*   **Quarterly Sales Report:**

    ```sql
    WITH reportQuarterSale AS (
        SELECT d.product_name, SUM(f.total_sale) AS total_sale, t.t_quarter
        FROM fact_sale f
        JOIN dim_product d ON f.product_id = d.product_id
        JOIN dim_date t ON t.t_date = f.t_date
        WHERE t.t_year = 2016
        GROUP BY d.product_name, t.t_quarter
    )
    SELECT product_name,
            SUM(CASE WHEN t_quarter = 1 THEN total_sale END) AS q1_2016,
            SUM(CASE WHEN t_quarter = 2 THEN total_sale END) AS q2_2016,
            SUM(CASE WHEN t_quarter = 3 THEN total_sale END) AS q3_2016,
            SUM(CASE WHEN t_quarter = 4 THEN total_sale END) AS q4_2016
    FROM reportQuarterSale
    GROUP BY product_name;
    ```

*   **Store Performance:**

    ```sql
    SELECT * FROM storeanalysis_mv;
    ```

## 5. Materialized Views

Materialized views optimize query performance:

*   **Base View:**

    *   Summarizes sales data at store and product levels.

    ```sql
    CREATE MATERIALIZED VIEW STOREANALYSIS_MV
    BUILD IMMEDIATE
    REFRESH COMPLETE
    ENABLE QUERY REWRITE
    AS
    SELECT f.store_id, f.product_id, SUM(f.total_sale) AS store_total
    FROM fact_sale f
    GROUP BY f.store_id, f.product_id;
    ```

*   **Using ROLLUP:**

    *   Adds hierarchical summaries (e.g., totals for all products at a store).

    ```sql
    GROUP BY ROLLUP (f.store_id, f.product_id);
    ```

*   **Using CUBE:**

    *   Provides multi-dimensional summaries (e.g., totals across all stores and products).

    ```sql
    GROUP BY CUBE (f.store_id, f.product_id);
    ```

## 6. Key Features

*   **Dimension Populating Automation:** Checks for and inserts missing data in dimensions.
*   **Fact Table Population:** Prevents duplication and calculates totals dynamically.
*   **Time-Series Analysis:** Uses `DIM_DATE` for year, quarter, month, and day-based analysis.
*   **Performance Optimization:** Indexed joins and materialized views improve query response times.
